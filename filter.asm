
;
; BabelFish AppleSoft Translator
;
; by Kelvin W Sherlock September 1998
;
;

offset_fType	gequ 16
offset_eof	gequ 18
offset_aType	gequ 44

BAS_FTYPE	gequ $FC
BAS_ATYPE	gequ $0801

; SFFilter
;
; in stack:
;
; (3) |rtl
;     |----
; (4) |DirEntryRecPtr
;     |----
; (2) |returnval
;     |----
;     |.........

; out stack:
;
;   |returnval
;   |----
;   |.........


;
; Returns 0 if it's not an Applesoft File, or 4 if it is.
;

SFFilter START

_d	equ 1
_rtlb	equ 3
DirPtr	equ 7
retval	equ 11

	phb		;even up the stack
	phd
	tsc
	tcd

	stz <retval	;; assume no

;
; Check the FileType
;
	ldy #offset_fType
	lda [<DirPtr],y
	cmp #BAS_FTYPE
	bne exit

;
; Check the size (s/b < 65,536 bytes
;
	ldy #offset_eof+2
	lda [<DirPtr],y
	bne exit

;
; Make sure it HAS a size (must be >2 :-)
;
	dey
	dey
	lda [<DirPtr],y
	cmp #3
	bcc exit

;
; Check the auxtype
;
	ldy #offset_aType+2
	lda [<DirPtr],y
	cmp #^BAS_ATYPE
	bne exit
	dey
	dey
	lda [<DirPtr],y
	cmp #BAS_ATYPE
	bne exit
	
	lda #4	
	sta <retval	;; I handle it

exit	pld

	pla
	sta 3,s
	pla
	sta 3,s

	plb
	rtl

	END
