***********************************************************************
*                                                                     *
*       CHKSUM ASSEMBLE   (Version 1.0, Date 86/06/20)                *
*                                                                     *
*     by: Berthold Pasch, IBM Scientific Center Heidelberg            *
*                                                                     *
*This Program is designed to run on systems with IBM/370 architecture.*
*                                                                     *
*       ***** C o p y r i g h t   by  IBM Germany, 1986 *****         *
*                                                                     *
* This program was written for and may be used free of charge in EARN,*
* BITNET and other non-profit scientific networks.                    *
* (EARN is the European Academic and Research Network, BITNET is the  *
*  american counterpart of EARN).                                     *
*                                                                     *
***********************************************************************
*
* CHKSUM Routine
*
* This routine builds a 16-bit checksum from data passed as an argument
* and combines it with another checksum which is also provided as an
* argument. The resulting new checksum is returned to the caller.
* The data of which the checksum is to be built may be of any length
* and may consist of any EBCDIC character. However, leading and
* trailing blanks are ignored. For further details on how the checksum
* is generated see the heading of the checksum subroutine below.
*
* Interfaces are provided for:
*   a) Command calls from CMS commandline or any exec or program,
*   b) Calls from a linked-to module (e.g. ASSEMBLER, PASCAL, etc.)
* Interface properties are described in the headers of the correspon-
* ding interface code below. There is one common entry and exit point
* for all types of interfaces.
*
* Ensure that CHKSUM MODULE is generated with the following options:
*
*    LOAD CHKSUM (RLD
*    GENMOD (NOSTR
*
* This provides for the relocatability which is required for a nucleus
* extension.
*
         SPACE 1
CHKSUM   CSECT
         STM   14,12,12(13)        Save caller's registers
         BALR  12,0                Establish R12 as base register
         USING *,12
*      Determine which form of parameter list was passed.
         CLM   1,B'1000',=X'00'    If no indicator set in R1 then
         BE    LINKCALL               go to link call interface
         CLM   1,B'1000',=X'01'    If normal extended p-list then
         BE    CMDCALL                go to command call interface
         CLM   1,B'1000',=X'0B'    If normal extended p-list then
         BE    CMDCALL                go to command call interface
         L     15,=F'-1001'        Else Set return code -1
RETURN   DS    0H
         L     14,12(13)           Restore caller's registers except
         LM    0,12,20(13)              register 15
         BR    14                  Return to caller
         EJECT
*
* LINKCALL: handle requests from linked-to modules
*
*----------------------------------------------------------------------
*
* Assembler programs must call CHKSUM as follows:
*
*        LA    R1,PARMLIST     See below
*        LA    R13,SAVEAREA    Standard save area (18 fullwords)
*        L     R15,=V(CHKSUM)  Address of entry point of CHKSUM rtne.
*        BALR  R14,R15
*
* PARMLIST must have the following format:
*
*        DC    A(OSUMFLD)  -------> OSUMFLD  DC   H'0',H'oldsum'
*        DC    A(DATAFLD)  -------> DATAFLD  DC   H'dl',C'data_string'
*        DC    A(NSUMFLD)  -------> NSUMFLD  DC   H'0',H'newsum'
*
*
*        oldsum is the previous chksum that is to be combined with the
*               chksum of 'data'.
*        dl     is the length of the data_string.
*        data_string  is the datastring of which a checksum is to be
*               built. Leading and trailing blanks are ignored.
*
* The result 'newsum' is returned in the 16 low order bits of the
* NSUMFLD.
*
* The following return codes may be set in R15:
*
*            -1001       unknown call type, parmlist cannot be handled
*            -1002       arguments are missing
*
*----------------------------------------------------------------------
*
* PASCALVS programs may call CHKSUM as an external procedure.
* The following definitions might be used in PASCAL:
*
*    Var oldsum, newsum, i, n : integer;
*        data                 : string(255);
*
*    Procedure Chksum(const osum:integer; const dstring:string(255);
*                     var nsum:integer); Fortran;
*
*    Begin
*    ...
*    newsum := 0;
*    For i := 1 to n Do
*      Begin
*        oldsum := newsum;
*        data   := 'assign the data to be checksummed'
*        Chksum(oldsum,data,newsum);
*      End
*    ...
*    Writeln(newsum)
*    ...
*  End.
*
*----------------------------------------------------------------------
         SPACE 1
LINKCALL DS    0H
         L     15,=F'-1002'   Preset result -1002: args missing
         CLC   1(3,1),=XL3'00' If no pointer to 'oldsum'
         BE    RETURN            then return
         CLI   0(1),X'00'      If end of list
         BNE   RETURN            then return
         CLC   5(3,1),=XL3'00' If no pointer to 'data'
         BE    RETURN            then return
         CLI   4(1),X'00'      If end of list
         BNE   RETURN            then return
         CLC   9(3,1),=XL3'00' If no pointer to 'newsum'
         BE    RETURN            then return
         L     3,4(1)         Get address of datafield
         LH    5,0(3)         Get length of data
         LA    3,2(3)         Point to data_string
         LTR   5,5            If no data
         BZ    RETURN            then return
         L     10,0(1)        Get pointer to 'oldsum'
         L     11,8(1)        Get pointer to 'newsum'
         LA    4,0(3,5)       Point behind end of data_string
         BAL   14,STRIP       Strip off blanks
         LTR   5,5            If nothing left
         BNP   RETURN            then return
*      Now calculate the checksum
         BAL   14,GETCKSUM    Convert data_string to checksum
         L     2,0(10)        Get oldsum
         N     2,=F'65535'    Strip off superfluous bits
         XR    5,2            Combine checksum with oldsum
         ST    5,0(11)        Store as newsum
         XR    15,15          Zero return code
         B     RETURN
         EJECT
*
* CMDCALL: handle extended p-list
*
* CHKSUM must be called as a CMS command:
*
*        CHKSUM oldsum data_string
*
*        oldsum is the previous chksum that is to be combined with the
*               chksum of 'data'. 'oldsum' must be a decimal number in
*               EBCDIC code in the range from 0 to 65535.
*        data_string  is the datastring of which a checksum is to be
*               built. Leading and trailing blanks are ignored.
*
* The result 'newsum' is returned as the return code of the command.
* It will be in the range from 0 to 65535.
* The following return codes may be set:
*
*             0 - 65535  the new checksum
*            -1001       unknown call type, parmlist cannot be handled
*            -1002       arguments are missing
*            -1003       'oldsum' is invalid
*
* The extended p-list passed to CHKSUM has the following format:
*
* R0 ----> A(cmdstart) -----> C'CHKSUM '
*          A(argstart) -----> C'--oldsum-- --data--'
*          A(argend)   ---------------------------->|
*
         SPACE 1
CMDCALL  DS    0H             Command Call interface
*      Locate and separate the arguments
         L     15,=F'-1002'   preset result -1002: args missing
         LR    10,0           Get P-list address to work with
         L     3,4(10)        Get address of begin of arguments
         L     4,8(10)        Get address of end of arguments
         CR    4,3            If no args
         BNH   RETURN            then return
         BAL   14,STRIP       Strip off blanks
         LTR   5,5            If nothing left
         BNP   RETURN            then return
         BCTR  5,0            length-1
         EX    5,BLNKTRT      Find the end of 'oldsum'
         BC    8+2,RETURN     If no 'data_string' follows then return
         LA    4,0(1)         Get end of 'oldsum'
*      Verify and convert 'oldsum'
         L     15,=F'-1003'   Preset result -1003: 'oldsum' invalid
         BAL   14,OLDSUM      Check the oldsum and convert it to binary
         B     RETURN         If 'oldsum' not ok then return (error)
         LR    11,5           Save binary 'oldsum'
*      Handle data string
         L     15,=F'-1002'   Preset result -1002 : args missing
         LR    3,4            Point to 'data_string'
         L     4,8(10)        Point to end of 'data_string'
         CR    4,3            If no 'data_string'
         BNH   RETURN            then return
         BAL   14,STRIP       Strip leading and trailing blanks
         LTR   5,5            If length is zero
         BNP   RETURN            then return
*      Now calculate the checksum
         BAL   14,GETCKSUM    Convert data_string to checksum
         XR    5,11           Combine with oldsum
         LR    15,5           Return 'newsum' as a return code
         B     RETURN
         EJECT
*
* Check and convert 'oldsum' from decimal to 16-bit binary
*
* R3 --->oldsum
* R4 --------->|
* R5 returns binary value of oldsum
*
* Return +0 : error
* Return +4 : oldsum ok and converted.
*
         SPACE 1
OLDSUM   DS    0H
         LR    5,4            get end of string
         SR    5,3            get length
         BCTR  5,0            length-1
         EX    5,NNUMTRT      if 'oldsum' ^= numeric
         BCR   4+2,14            then return (error)
         EX    5,OSUMPK       convert 'oldsum' to hex
         CVB   5,OSUMPKF
         C     5,=F'65535'    if 'oldsum' to high
         BHR   14                then return (error)
         B     4(14)
         SPACE 1
OSUMPK   PACK  OSUMPKF,0(0,3)
OSUMPKF  DS    D'0'
         SPACE 2
*
* Strip blanks
*
*   Input:  r3 --->    data string
*           r4 ----------------------->|
*   Output: r3 --->data string
*           r4 -------------->|
*           r5 = length of 'data string'
* Register 6 and 7 are used as work registers. R14 = return address.
*
         SPACE 1
*      1st: skip leading blanks
STRIP    XR    5,5
STRIPLP1 LR    6,4
         SR    6,3            Calc length of data string
         BNPR  14             If no data then return
         BCTR  6,0            length-1
         C     6,=F'255'
         BNH   *+8
         LA    6,255
         EX    6,NBLNKTRT     Find nonblank character
         BC    4+2,STRPELP1      and leave loop if found
         LA    3,1(6,3)       Point to next block of data
         B     STRIPLP1       Repeat until non-blank or end of argument
         SPACE 1
STRPELP1 LA    3,0(1)         Point to first non-blank character found
         SPACE 1
*      2nd: strip trailing blanks
STRIPLP2 BCTR  4,0            Move end pointer back one
         CLI   0(4),X'40'     If there is a blank then
         BE    STRIPLP2          repeat until a non-blank is found
         LA    4,1(4)         Point behind last non-blank character
         SPACE 1
*      Now: r3 --->data string
*           r4 -------------->|
         LR    5,4
         SR    5,3            Set length of string
         BR    14
         EJECT
*
* Checksum calculation
*
* Input to this subroutine is a character string pointed to by R3,
* R4 points behind the last character of the string:
*      r3 --->data string
*      r4 -------------->|
* The calculated checksum is returned in R5.
* The return address is in R14.
*
* The input string is processed in 16-bit words from left to right.
* Zero bits are appended at the end if necessary to obtain a last word
* word with 16 bits.
* These words are combined in 'exclusive or' fashion to build the check
* sum. Before doing the XOR the next word is rotated left by a number
* which is determined by the 4 low order bits of the checksum built up
* so far. This makes the algorithm more sensitive to word exchanges in
* the input string.
* The resulting checksum is contained in the low order 16 bits of R5.
*
* String: "ABCDE"                  R5 = 0000 0000 0000 0000
*          |||||                                       ||||
*          |||||                                       ++++-------+
*          |||||                                         rotate 0 |
*          ++----------------------->   1100 0001 1100 0010   <---+
*            |||                                 V
*            |||                        1100 0001 1100 0010
*            |||                             XOR with
*            |||                   R5 = 0000 0000 0000 0000
*            |||                                 V
*            |||                   R5 = 1100 0001 1100 0010
*            |||                                       ||||
*            |||                                       ++++-------+
*            |||                                         rotate 2 |
*            ++--------------------->   1100 0011 1100 0100   <---+
*              |                                 V
*              |                        0000 1111 0001 0011
*              |                             XOR with
*              |                   R5 = 1100 0001 1100 0010
*              |                                 V
*              |                   R5 = 1100 1110 1101 0001
*              |                                       ||||
*              |                                       ++++-------+
*              |                                         rotate 1 |
*              +-------------------->   1100 0101 0000 0000   <---+
*                                                V
*                                       1000 1010 0000 0001
*                                            XOR with
*                                  R5 = 1100 1110 1101 0001
*                                                V
* Checksum of string "ABCDE" --->  R5 = 0100 0100 1101 0000
*
* Registers 6, 7, 8 are used as work registers. Their contents
* after return from this subroutine is unpredictable.
*
         SPACE 1
GETCKSUM DS    0H
         XR    5,5       Zero the result checksum value
         BCTR  4,0       Point back to last caharacter
CHKSUMLP XR    6,6
         XR    7,7
         CR    3,4       If end of string
         BHR   14           then return
         BE    *+12      If one character left then skip
         ICM   7,B'1100',0(3)      Get 2 string characters (16 bits)
         B     *+8                 Skip
         ICM   7,B'1000',0(3)      Get last string character (8 bits)
*                                      (next 8 bits are zero in R7)
         LA    8,15
         NR    8,5       Get 4 low order bits of chksum for rotate
         SLDL  6,0(8)    Rotate new word
         SRL   7,16
         OR    7,6
         XR    5,7       XOR chksum and rotated word
         LA    3,2(3)    Point to next word of string
         B     CHKSUMLP  Go handle next word
         EJECT
BLNKTRT  TRT   0(0,3),BLNKTBL
BLNKTBL  DC    256X'00'
         ORG   BLNKTBL+C' '
         DC    C' '
         ORG
NBLNKTRT TRT   0(0,3),NBLNKTBL
NBLNKTBL DC    256X'01'
         ORG   NBLNKTBL+C' '
         DC    X'00'
         ORG
NUMTRT   TRT   0(0,3),NUMTBL
NUMTBL   DC    256X'00'
         ORG   NUMTBL+C'0'
         DC    C'0123456789'
         ORG
NNUMTRT  TRT   0(0,3),NNUMTBL
NNUMTBL  DC    256X'01'
         ORG   NNUMTBL+C'0'
         DC    10X'00'
         ORG
         EJECT
         LTORG
         END
