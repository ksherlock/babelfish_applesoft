#pragma noroot

/*
 * Structure for holding the length of the token
 * and a pointer to the token (a cstring)
 *
 * this is in C because it is MUCH easier to do the data storage this way.
 * MUCH easier.
 *
 */
struct info
{
	unsigned long length;	/* by being a long, */
	char *token;		/* indexing the array = multiplying by 8 */
};                              /* simple! */

/*
 * Macro for extracting the length of a string and
 * storing a pointer to it.
 *
 * sizeof(string) includes the trailing NULL character,
 * so subtracting 1 accounts for that
 */
#define LIST(x)			\
	{			\
		sizeof(x) - 1,	\
		x		\
	}


/*
 * Here it is - all the tokens !
 *
 */
struct info TOKENS[] =
{
/* $80 */
	LIST(" END "),
	LIST(" FOR "),
	LIST(" NEXT "),
	LIST(" DATA "),
	LIST(" INPUT "),
	LIST(" DEL "),
	LIST(" DIM "),
	LIST(" READ "),
	LIST(" GR "),
	LIST(" TEXT "),
	LIST(" PR# "),
	LIST(" IN# "),
	LIST(" CALL "),
	LIST(" PLOT "),
	LIST(" HLIN "),
	LIST(" VLIN "),
/* $90 */
	LIST(" HGR2 "),
	LIST(" HGR "),
	LIST(" HCOLOR= "),
	LIST(" HPLOT "),
	LIST(" DRAW "),
	LIST(" XDRAW "),
	LIST(" HTAB "),
	LIST(" HOME "),
	LIST(" ROT= "),
	LIST(" SCALE= "),
	LIST(" SHLOAD "),
	LIST(" TRACE "),
	LIST(" NOTRACE "),
	LIST(" NORMAL "),
	LIST(" INVERSE "), 
	LIST(" FLASH "), 
/* $A0 */
	LIST(" COLOR= "), 
	LIST(" POP "),
	LIST(" VTAB "),
	LIST(" HIMEM: "),
	LIST(" LOMEM: "),
	LIST(" ONERR "),
	LIST(" RESUME "),
	LIST(" RECALL "),
	LIST(" STORE "),
	LIST(" SPEED= "),
	LIST(" LET "),
	LIST(" GOTO "),
	LIST(" RUN "),
	LIST(" IF "),
	LIST(" RESTORE "),
	LIST(" & "),
/* $B0 */
	LIST(" GOSUB "),
	LIST(" RETURN "),
	LIST(" REM "),
	LIST(" STOP "),
	LIST(" ON "),
	LIST(" WAIT "),
	LIST(" LIST "),
	LIST(" SAVE "),
	LIST(" DEF "),
	LIST(" POKE "),
	LIST(" PRINT "),
	LIST(" CONT "),
	LIST(" LIST "),
	LIST(" CLEAR "),
	LIST(" GET "),
	LIST(" NEW "),
/* $C0 */
	LIST(" TAB( "),
	LIST(" TO "),
	LIST(" FN "),
	LIST(" SPC( "),
	LIST(" THEN "),
	LIST(" AT "),
	LIST(" NOT "),
	LIST(" STEP "),
	LIST(" + "),
	LIST(" - "),
	LIST(" * "),
	LIST(" / "),
	LIST(" ^ "),
	LIST(" AND "),
	LIST(" OR "),
	LIST(" > "),
/* $D0 */
	LIST(" = "),
	LIST(" < "),
	LIST(" SGN "),
	LIST(" INT "),
	LIST(" ABS "),
	LIST(" USR "),
	LIST(" FRE "),
	LIST(" SCRN( "),
	LIST(" PDL "),
	LIST(" POS "),
	LIST(" SQR "),
	LIST(" RND "),
	LIST(" LOG "),
	LIST(" EXP "),
	LIST(" COS "),
	LIST(" SIN "),
/* $E0 */
	LIST(" TAN "),
	LIST(" ATN "),
	LIST(" PEEK "),
	LIST(" LEN "),
	LIST(" STR$ "),
	LIST(" VAL "),
	LIST(" ASC "),
	LIST(" CHR$ "),
	LIST(" LEFT$ "),
	LIST(" RIGHT$ "),
	LIST(" MID$ "),
/* $EB */
	LIST(" ???? "),		/* these aren't used by AppleSoft */
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
	LIST(" ???? "),
};                    
