;
; AppleSoft BASIC BabelFish importer 1.0
; by Kelvin Sherlock
;
; For educational purposes only
;
;
	case off
	mcopy init.mac

         copy 13:Ainclude:e16.gsos
	copy bfish.equ

BAS_FTYPE	gequ $FC
BAS_ATYPE	gequ $0801

SHASTON_ID	gequ $fffe


;
; This is the entry point.
;

init	START

	using global

	phb
	phk
	plb

;
; Get my memory manager ID
;
	pha
	_MMStartUp
	pla
	sta MyID

;
; convert it to english & tack on to the end of my request name
;
	pha		;; MyID
	pea MyName|-16
	pea MyName+28
	pea 4
	_Int2Hex


;
; Accept Requests
;
	pea MyName|-16
	pea MyName
	lda MyID
	pha
	pea RequestH|-16
	pea RequestH
	_AcceptRequests

;
; leave (for now)
;
	plb
	rtl

init	END


global	DATA

MyName	pstr "Babelfish~Kelvin~ASoftTransXXXX"
BName	pstr "Seven Hills~Babelfish~"

CalcStr	pstr "Calculating Space Requirements"
TokeStr	pstr "Detokenizing file"
DoneStr	pstr "Done!"

InRec	ds 4

OutRec	ds 4		;; space for BFProgress

MyID	ds 2

Active	ds 2
Done	ds 2

FileHandle	ds 4

;
; Text Record
;

Text_pCount	dc i2'10'
Text_ActionCode ds 2
Text_ResponseCode ds 2
Text_Length	ds 4
Text_Ptr		ds 4
Text_Hnd		ds 4
Text_FamilyID	dc i2'SHASTON_ID'
Text_FontSize	dc i2'8'
Text_FontStyle	dc i2'0'
Text_ForeColor	dc i2'0'
Text_BackColor	dc i2'$ffff'

OpenDCB	anop
OpenDCB_pcount		dc i2'15'
OpenDCB_refNum		ds 2
OpenDCB_pathName	dc i4'0'
OpenDCB_requestAccess	ds 2
OpenDCB_resourceNumber	dc i2'0'
OpenDCB_access		ds 2
OpenDCB_fileType	ds 2
OpenDCB_auxtype	ds 4
OpenDCB_storageType	ds 2
OpenDCB_createDateTime	ds 8
OpenDCB_modDateTime	ds 8
OpenDCB_optionList	ds 4
OpenDCB_dataEOF	ds 4
OpenDCB_blocksUsed	ds 4
OpenDCB_resourceEOF	ds 4
OpenDCB_resourceBlocks	ds 4

;
; for reading/writing data
;
IODCB	anop
IODCB_pcount		dc i2'5'
IODCB_refNum		ds 2
IODCB_dataBuffer	ds 4
IODCB_requestCount	ds 4
IODCB_transferCount	ds 4
IODCB_cachePriority	dc i4'0'


CloseDCB		dc i2'1'
CloseDCB_refnum	ds 2



global	END

;
; Request Handler (called by application via bfish via toolbox)
;
;   in stack           out stack
; |------------       |-----------
; | result            | result 0 = not accepted, $8000 = accepted
; |------------       |-----------
; | request
; |------------
; |
; | DataIn
; |
; |------------
; |
; | DataOut
; |
; |------------
; |
; | rtl
; |------------


RequestH	START

	using Global

result	equ 17
reqCode	equ 15
dataIn	equ 11
dataOut	equ 7
_rtlb	equ 3
_d	equ 1



	phb

	phk
	plb
	phd
	tsc
	tcd

;
; this should be zeroed already, but better safe than sorry
;

	stz <result

;
; Check what sort of request it is
;
	lda <reqCode

	cmp #TrStartUp
	bne n1

	lda #$8000	; yes, I'll handle it
	sta <result

	ldy #2
	lda [<DataIn],y
	pha
	lda [<DataIn]
	pha
	jsr DoStartUp
	ldy #2
	sta [DataOut],y	; error to bfish

	bra exit


n1	anop
	cmp #TrShutDown
	bne n2

	lda #$8000	; yes, I'll accept it
	sta <result

	jsr DoShutDown
	ldy #2
	sta [DataOut],y

	bra exit
	

n2	anop
	cmp #TrRead
	bne exit

	lda #$8000	; yes, I'll accept it
	sta <result

	ldax <DataIn
	stax InRec

	ldy #2
	lda [<DataIn],y
	pha
	lda [<DataIn]
	pha
	jsr DoRead
	ldy #2
	sta [DataOut],y


exit	anop

	pld		;restore the old dpage

	pla		; move rtlb
	sta 9,s
	pla
	sta 9,s

	pla
	pla
	pla
	
	plb
	rtl


RequestH	END



;
; Startup procedure
;
; returns a = 0 on success, a = errno on failure
DoStartUp	START

	using Global

_d	equ 1
_rts	equ 3
xPtr	equ 5

	phd
	tsc
	tcd

	stz Active
	stz Done

	stz FileHandle
	stz FileHandle+2


;
; Tell the reciever that we will export as text
;
;
	lda #bffText
	ldy #offset_DataKinds
	sta [xPtr],y


;
; Open the file
;
	lda #readEnable
	sta OpenDCB_requestAccess

	ldy #offset_FilePathPtr+2
	lda [xPtr],y
	sta OpenDCB_pathName+2
	dey
	dey
	lda [xPtr],y
	sta OpenDCB_pathName

	_OpenGS OpenDCB
	bcc *+5
	brl exit	;;return GSOS error

	lda OpenDCB_refNum
	sta CloseDCB_refNum
	sta IODCB_refNum


	lda OpenDCB_fileType
	cmp #BAS_FTYPE
	
	bne wrong_type

	lda OpenDCB_auxType
	cmp #BAS_ATYPE

	beq right_type
	                      
wrong_type	anop

	_CloseGS CloseDCB

	lda #bfBadFileErr
	ldy #offset_Status
	sta [xPtr],y
	lda #$ffff
	brl exit

right_type	anop

;
; AppleSoft files BETTER be < 65,535 bytes long!
;
	lda OpenDCB_dataEOF+2
	bne wrong_type


;
; Set the thermometer values
;
	lda #2
	ldy #offset_FullTherm
	sta [xPtr],y

	lda #0
	ldy #offset_CurrentTherm
	sta [xPtr],y

;
; set the Data Record Ptr
;
	ldy #offset_DataRecordPtr
	lda #Text_pCount
	sta [xPtr],y
	iny
	iny
	lda #^Text_pCount
	sta [xPtr],y

;
; initialize the text record
;
	lda #0
	sta Text_Ptr
	sta Text_Ptr+2

	sta Text_Length
	sta Text_Length+2
	
	sta Text_Hnd
	sta Text_Hnd+2

	sta Text_ForeColor	;;black = 0

	lda #10	;; # of parms
	sta Text_pCount

	lda #SHASTON_ID
	sta Text_FamilyID

	lda #8
	sta Text_FontSize

	lda #$ffff
	sta Text_BackColor
	
;
; GetSettings
;
	lda #1
	sta Text_ActionCode


exl	inc Active
	lda #0

exit	anop
	pld

	ply		;return address

	plx		;args on the stack
	plx

	phy		;restore the return address
	rts

	END

;
; DoShutDown - prepare to go away
;
; returns a = 0 on success, a = errno on failure (yeah, right)
DoShutDown	START

	using Global

	lda Active
	beq exit

	_CloseGS CloseDCB


exit	lda #0
	rts	

	END

;
; DoRead - the meat & potatoes
;
; returns a = 0 on success, a = errno on failure

DoRead	START

	using Global


_d	equ 1
FilePtr	equ 3		; locals
OutPtr	equ 7
Length	equ 11
pstrPtr	equ 15
_rts	equ 19
xPtr	equ 21	; passed on stack


;
; Create some local vars
;
	tsc
	sec
	sbc #16
	tcs

	phd
	tsc
	tcd


;
; Done is our status so I know what I'm doing  :)
;
; 0 = get defaults from application
; 1 = detokenize the file
; 2 = all done

	lda Done
	bne part2

;
; Get defaults for the text record from the application
;
	lda #1	;request defaults
	sta Text_ActionCode
	lda #bfContinue
	ldy #offset_Status
	sta [xPtr],y

	inc Done
	lda #0
	brl exit

part2	cmp #1
	beq convert

; ok, were done, so say so & exit

	lda #bfDone
	ldy #offset_Status
	sta [xPtr],y

	lda #0
	brl exit


convert	anop

	stz Text_ActionCode


;
; File was opened w/ startup
; Now, read the file
;

	ldax OpenDCB_dataEOF
	stax IODCB_requestCount
	stax <Length


;
; Allocate 4 extra bytes, so I can fill them in w/ 0s to be safe
;
	clc
	adc #4
	bcc f2
	inx
f2	anop

	pha		;;space
	pha
	phxa		;;size
	lda MyID
	pha		;;MemID
	pea $c008	;;attr: locked, fixed, no spec.
	pea 0		;;location
	pea 0		
	_NewHandle
	tay
	plax
	stax <FilePtr
	stax FileHandle

	bcc read_it

	phy		;;save error
	ldy #offset_Status
	lda #bfMemErr
	sta [xPtr],y

	pla		;;error code from toolbox
	brl exit	

read_it	anop

;
; deref the handle
;
	ldy #2
	lda [FilePtr],y
	tax
	lda [FilePtr]
	stax <FilePtr
	stax IODCB_dataBuffer

	_ReadGS IODCB
	bcc been_read

	pha	;store error

;
; Deallocate the memory
;
	ldax FileHandle
	phxa
	_DisposeHandle

	ldy #offset_Status
	lda #bfReadErr
	sta [xPtr],y
	
	pla		;;restore
	brl exit

;
; The file has now been read into memory
;
;

been_read	anop

;
; Tack 4 0s at the end of the memory.  This guarantees
; that I won't overrun the buffer into infinity if it's a
; corruptes file or not even an applesoft file
;
	pei FilePtr+2
	pei FilePtr
	lda OpenDCB_dataEOF
	jsr Append0


;
; make it show my message
;
	ldy #offset_ProgressAction
	lda #1+2+4+8
	sta [xptr],y

	ldy #offset_MiscFlags
	lda #1+2+4
	sta [xptr],y


	ldy #offset_MsgPtr+2
	lda #^CalcStr
	sta [xPtr],y
	dey
	dey
	lda #CalcStr
	sta [xPtr],y
	
	pea BFProgress	;reqcode
	pea $8001	;sendtoname+stopafterone
	pea BName|-16	;target	
	pea BName
	ldax InRec
	phxa
	pea OutRec|-16	;out
	pea OutRec
	_SendRequest

	

;
; Calculate the length of the file
;

	pei FilePtr+2
	pei FilePtr
	jsr CalcLength
	stax <Length
	stax Length2

;
; Add space to include "\nSAVE xxxxx"
;

	lda #6	;; length of "\nSAVE "
	clc
	adc Length2
	sta Length2
	bcc a_a
	inc Length2+2

a_a	ldy #offset_FileNamePtr	;;pstring ptr
	lda [xPtr],y
	sta <pStrPtr
	iny
	iny
	lda [xPtr],y
	sta <pStrPtr+2

	lda [<pStrPtr]	;;pstring

	and #$00ff
	clc
	adc Length2
	sta Length2
	bcc a_b
	inc Length2+2

a_b	anop
	
;
; Store the length of data I'm returning
;

	ldax Length2
	stax Text_Length



;
; allocate memory to return the text in
;
	pha
	pha

	ldax Length2
	phxa
	lda MyID
	pha
	pea $c008
	pea 0
	pea 0

	_NewHandle
	tay
	plax
	stax <OutPtr

	bcc p1

	phy

	lda #bfMemErr
	ldy #offset_Status
	sta [xPtr],y

	ldax FileHandle
	phxa
	_DisposeHandle

	pla
	brl exit


p1	anop

;
; Store the Handle
;

	
	stax Text_Hnd

;
; Deref Handle->Ptr
;

	ldy #2
	lda [OutPtr],y
	tax
	lda [OutPtr]

	stax <OutPtr

;
; store the ptr to return
;

	stax Text_Ptr

;
; update the thermometer
;
	lda #1
	ldy #offset_CurrentTherm
	sta [xPtr],y

	ldy #offset_ProgressAction
	lda #1+2+4+8
	sta [xptr],y

	ldy #offset_MiscFlags
	lda #1+2+4
	sta [xptr],y

	ldy #offset_MsgPtr+2
	lda #^TokeStr
	sta [xPtr],y
	dey
	dey
	lda #TokeStr
	sta [xPtr],y
	
	pea BFProgress	;reqcode
	pea $8001	;sendtoname+stopafterone
	pea BName|-16	;target	
	pea BName
	ldax InRec
	phxa
	pea OutRec|-16	;out
	pea OutRec
	_SendRequest


;
; detokenize the file
;
	pei <FilePtr+2
	pei <FilePtr
	pei <OutPtr+2
	pei <OutPtr

	jsr ConvertFile

	ldax FileHandle
	phxa
	_DisposeHandle

;
; Now tack on "\nSAVE filename"
;
;

;
; 1) Set OutPtr to the end of the text
;
	lda <Length
	clc
	adc <OutPtr
	sta <OutPtr
	lda <Length+2
	adc <OutPtr+2
	sta <OutPtr+2

;
; 2) Tack on "\nSAVE "
;

	lda #$0d+256*'S'	;;'\rS'
	sta [<OutPtr]
	ldy #2
	lda #'VA'
	sta [<OutPtr],y
	iny
	iny
	lda #' E'
	sta [<OutPtr],y

	lda #5
	clc
	adc <OutPtr
	sta <OutPtr
	bcc a_c
	inc <OutPtr+2
;
; 3) Add on the name itself
;	

a_c	anop	                  


	lda #0
	short m

	lda [<pStrPtr]	;;pstring
	tay		;;length of pstring
lp	anop	
	lda [<pStrPtr],y
	sta [<OutPtr],y
	dey
	bne lp

a_d	anop
	long m


exit_ok	anop

;
; update the thermometer
;
	lda #2
	ldy #offset_CurrentTherm
	sta [xPtr],y

	ldy #offset_ProgressAction
	lda #1+2+4+8
	sta [xptr],y

	ldy #offset_MiscFlags
	lda #1+2+4
	sta [xptr],y

	ldy #offset_MsgPtr+2
	lda #^DoneStr
	sta [xPtr],y
	dey
	dey
	lda #DoneStr
	sta [xPtr],y

	pea BFProgress	;reqcode
	pea $8001	;sendtoname+stopafterone
	pea BName|-16	;target	
	pea BName
	ldax InRec
	phxa
	pea OutRec|-16	;out
	pea OutRec
	_SendRequest


	lda #bfContinue
	ldy #offset_Status
	sta [xPtr],y
	lda #0

	inc Done


exit	anop

	pld

	tax		;;save
	tsc
	clc
	adc #16
	tcs
	txa		;;restore
	
	ply		;;_rts

	plx		;;passed parameter
	plx

	phy		; y = return address

	rts

Length2	ds 4


DoRead	END




;
; int IntLength
;
; determines how much space an integer would take up as a string,
; including a trailing space
;
;
; in:	a = the number
; out:	a = the length of a string that could represent it


IntLength	START

	phx		;save

	ldx #1
	cmp #10
	bcc done
	inx
	cmp #100
	bcc done
	inx
	cmp #1000
	bcc done
	inx
	cmp #10000
	bcc done
	inx

done	txa
	inc a
	plx
	rts

IntLength	END


;
; Calculate the length of an AppleSoft file
;
;
; in: (stack) Ptr to the applesoft file
; out: (a:x) length of file
;      (a = low word, x = hi word)

;
; {word word {bytes}* 0x00}*
;

; FYI, an applesoft file looks like:
; WORD - offset to next line, 0 if EOF
; WORD - line #
; variable # of bytes - if > $7f, is a token,
; byte 0 - eol

CalcLength	START

_d	equ 1
size	equ 3
_rts	equ 7
Ptr	equ 9


	pha
	pha
	phd
	tsc
	tcd
	
	stz <size
	stz <size+2

	ldy #0

;
; ofset to next line, or 0 if done
;
m_loop	lda [Ptr],y
	bne *+5
	brl done

	iny
	iny
;
; line #
;
	lda [Ptr],y
	jsr IntLength	;;calc size

	clc
	adc <size
	sta <size
	bcc foo
	inc <size+2

foo	iny
	iny

s_loop	lda [Ptr],y

	iny

	and #$00ff
	beq next
	cmp #$80
	bcs _tok
	
;
; characters $01-$1f are special for bablefish, so must be ignored
; if in an applesoft file
;
	cmp #$20
	bcc s_loop


	inc <size
	bne s_loop
	inc <size+2
	bra s_loop

;
; add space for a carriage return
;
next	anop		;;eol
	inc <size
	bne m_loop
	inc <size+2
	bra m_loop

;
; Calculate the size of the token from a look-up table
;
;
_tok	anop

	sec
	sbc #$80

	asl a		;; x2
	asl a		;; x4
	asl a		;; x8

	tax
	lda TOKENS,x	;;size of the token

	clc
	adc <size
	sta <size
	bcc s_loop
	inc <size+2
	bra s_loop

done	anop

	ldax <size
	stax <Ptr
	pld
	ply
	ply
	ply

	plax

	phy
	rts

	END


;
; Convert file - detokenize a memory location into another memorry location
;
;
ConvertFile START

_d	equ 1
_rts	equ 3
Data	equ 5
File	equ 9


	phd
	tsc
	tcd
	

	ldy #0

;
; ofset to next line, or 0 if done
;
m_loop	lda [File],y
	bne *+5
	brl done

	iny
	iny
;
; line #
;
	phy		;;save

	lda [File],y

	pei Data+2
	pei Data

	jsr IntCvt

	plx		;even up the stack
	plx

	ply		;;restore

	lda [File],y
	jsr IntLength

	clc
	adc <Data
	sta <Data
	bcc foo
	inc <Data+2

foo	iny
	iny

s_loop	lda [File],y

	iny

	and #$00ff
	beq next
	cmp #$80
	bcs _tok

;
; characters $01-$1f are special for bablefish, so must be ignored
; if in an applesoft file
;
	cmp #$20
	bcc s_loop


;
; Character can be added as-is
;
	short m
	sta [Data]
	long m
	inc <Data
	bne s_loop
	inc <Data+2
	bra s_loop

;
; add a carriage return
;
next	anop		;;eol

	short m
	lda #$0D
	sta [Data]
	long m
	inc <Data
	bne m_loop
	inc <Data+2
	bra m_loop

;
; Add the size of the token from a look-up table
;
;
_tok	anop

	sec
	sbc #$80

	asl a		;; x2
	asl a		;; x4
	asl a		;; x8

	tax

	phy		;;save

	lda TOKENS+6,x
	pha

	lda TOKENS+4,x	;;ptr to the token
	pha

	pei Data+2
	pei Data
	jsr CopyT
	plx
	plx
	plx
	plx

	ply		;;restore

	clc
	adc <Data
	sta <Data
	bcc s_loop
	inc <Data+2
	bra s_loop


done	anop

	pld

	ply		;;return address

	pla
	pla
	pla
	pla

	phy
	rts

	END

;
; in A: the number
; stack: ptr to where to place it
;
; STACK UNCHANGED
IntCvt	START

_d	equ 1
_rts	equ 3
Ptr	equ 5
	

	tay	
	phd
	tsc
	tcd

	tya
	pea $ffff	;;marker
;
;	a = the number
;
l1	jsr div_10
	pha		; remainder
	tya
	bne l1

	ldy #0
	lda #0

	short m

l2	pla
	bmi ex1	;; found marker?
	clc
	adc #'0'
	sta [Ptr],y
	pla		;; s/b 0
	iny
	bra l2

ex1	pla		;;even up stack

	lda #' '
	sta [Ptr],y
	
	long m

	pld
	rts

	END


;entrance
;	a = value to divide
;
;exit
;	a = modulo
;	y = quotient

div_10	START
	ldy #0
div_loop	anop
	cmp #10
	bcc done_div
;	sec		; redundant!
	sbc #10
	iny
	bra div_loop
done_div rts
	END


;
; Copy a cstring from src->destination, NOT including the NULL char
;
CopyT	START

_d	equ 1
_rts	equ 3
dest	equ 5
src	equ 9

	phd
	tsc
	tcd		

	ldy #0

	short m

loop	lda [src],y
	beq done
	sta [dest],y
	iny
	bra loop

done	anop
	long m
	tya
	pld
	rts

	END


;
; Tack 4 0 bytes to the end of a ptr
; a = length of the ptr
; stack (4 bytes) = ptr itself.
Append0	START

_d	equ 1
_rts	equ 3
Ptr	equ 5


	tax	;;save

	phd
	tsc
	tcd

	txa	;;restore


	clc
	adc <Ptr
	sta <Ptr
	lda #0	
	adc <Ptr+2
	sta <Ptr+2

	lda #0
	sta [Ptr]
	ldy #2
	sta [Ptr],y


	pld
	pla
	plx
	plx
	pha
	rts

	END
