/***********************************************************************/
/*                                                                     */
/*       UPDNODES EXEC     (Version : see below)                       */
/*                                                                     */
/*     by: Berthold Pasch, IBM Scientific Center Heidelberg            */
/*                                                                     */
/*     This Exec is designed to run on VM/SP Release 3 and up.         */
/*                                                                     */
/*     **** C O P Y R I G H T   IBM Germany  1986 ****                 */
/*                                                                     */
/*  This Exec was written for and may be used free of charge in EARN,  */
/*  BITNET and other non-profit scientific networks.                   */
/*  (EARN is the European Academic and Research Network, BITNET is the */
/*   american counterpart of EARN).                                    */
/*                                                                     */
/***********************************************************************/
/*  History of changes:                                                */
/*                                                                     */
/*  89/11/02 Version 1.1  Changed by H.U.Giese for compilability with  */
/*                        REXX Compiler.                               */
/*                        Changed by B.Pasch to set the date of the    */
/*                        updated nodes file equal to the date of the  */
/*                        update file. This facilitates the use of a   */
/*                        pre-generated index.                         */
/*  90/03/27 Version 1.2  Changed by B.Pasch: Corrected problem with   */
/*                        blank space in disk labels.                  */
/*  91/09/19 Version 1.3  call to NETCNTRY EXEC deleted         *Giese**/
/***********************************************************************/
Do 0
HELPMSG:
/***********************************************************************/
Say "UPDNODES   Merges a NODUPD file into an old version NODES file to build"
Say "           a new version of the NODES file."
Say " "
Say "Command format :"
Say " "
Say "UPDNODES  updfile < oldfile < newfile >> < ( options >"
Say " "
Say "          updfile  is 'filename filetype filemode' of the update file to be"
Say "                   used. At least 'filename' must be specified. 'filetype' and"
Say "                   'filemode' may be omitted (or periods may be used as place-"
Say "                   holders) in which case 'filetype filemode' defaults to"
Say "                   '"upft upfm"'."
Say "                   Use of '*' is allowed in any place. The first file matching"
Say "                   such a generic file-id will be used as 'updfile'."
Say " "
Say "          oldfile  is 'filename filetype filemode' of the old nodes file."
Say "                   If 'oldfile' is omitted it defaults to '"mnfn mnft mnfm"'."
Say "                   Specification of '*' is allowed in any place. The first file"
Say "                   matching such a generic file-id will be used as 'oldfile'."
Say " "
Say "          newfile  is 'filename filetype filemode' of the new nodes file which"
Say "                   is to contain the merged result. An '=' sign may be speci-"
Say "                   fied for 'filename', 'filetype' and/or 'filemode' in which"
Say "                   case the corresponding value of 'oldfile' will be used."
Say "                   If 'newfile' is omitted the output will replace 'oldfile' if"
Say "                   the REP option is specified."
Say " "
Say "          options  may be specified as follows:"
Say "          -------"
Say "                   REPlace          to replace an existing 'newfile'."
Say "                   Type             to list the performed actions on your"
Say "                                    terminal."
Say "                   NOType           to suppress typing (NOType is default)."
Say "                                    Only error messages will appear on the"
Say "                                    terminal."
/***********************************************************************/
Return
End
 
/* Specify default values */
upft = 'NODUPD'
upfm = '*'
mnfn = 'BITEARN'
mnft = 'NODES'
mnfm = '*'
wkfn = 'UPDNODES'
wkft = 'SYSUT1'
repopt = 0
type = ''
 
updnodes_version = '1.3  (91/09/19)'
Say 'UPDNODES version' updnodes_version
 
/* First of all: Select COMMAND environment for better performance */
Address COMMAND
 
/* Commence parameter verification  */
Arg ufn uft ufm ofn oft ofm nfn nft nfm '(' options ')'
If ufn='?' | ufn = '' then Do
   Call Helpmsg
   If ufn='?' then Call Comexit , 0
   Call Comexit , 24              /* Exit from EXEC                 */
End                               /* End of help info                  */
 
/* Determine fileid of update file */
If uft='' | uft='.' then uft = upft
If ufm='' | ufm='.' then ufm = upfm
'MAKEBUF'; bufno=rc
  'LISTFILE 'ufn uft ufm' (DATE NOHEADER FIFO'
  If rc=28 then Call Comexit , 28, ,
     'File 'ufn uft ufm' not found.'
  If rc^=0 then Call Comexit , rc, ,
     'LISTFILE error with 'ufn uft ufm'. RC='rc'.'
  Pull ufn uft ufm . . . . udt utm .
'DROPBUF'
updfile = ufn uft ufm
Parse Var udt mm'/'dd'/'yy
udt = yy || right(mm,2,0) || dd
Parse Var utm hh':'mm':'ss
utm = hh || mm || ss
 
/* Determine fileid of old nodes file */
If ofn='' | ofn='.' then ofn = mnfn
If oft='' | oft='.' then oft = mnft
If ofm='' | ofm='.' then ofm = mnfm
'MAKEBUF'
  'LISTFILE 'ofn oft ofm' (ALL NOHEADER FIFO'
  If rc=28 then Call Comexit , 28, ,
     'File 'ofn oft ofm' not found.'
  If rc^=0 then Call Comexit , rc, ,
     'LISTFILE error with 'ofn oft ofm'. RC='rc'.'
  Pull ofn oft ofm . . . nblks .
  'QUERY DISK 'substr(ofm,1,1)' (LIFO'
  Parse Pull 7 . . . . . blksz .
  reqspace = nblks * blksz * 1.1 % 1
'DROPBUF'
oldfile = ofn oft ofm
 
/* Determine fileid of new nodes file */
If nfn='' | nfn='.' | nfn='=' then nfn = ofn
If nft='' | nft='.' | nft='=' then nft = oft
If nfm='' | nfm='.' | nfm='=' then nfm = left(ofm,1)
If nfn='*' | nft='*' | nfm='*' then Call Comexit , 24, ,
   'Invalid file-id for ''newfile'': "'nfn nft nfm'".'
'STATE 'nfn nft nfm
If rc^=0 & rc^=28 then Call Comexit , rc, ,
   'STATE error with 'nfn nft nfm'. RC='rc'.'
newexist=rc
newfile = nfn nft nfm
 
wrkfile = wkfn wkft nfm
'STATE' wrkfile
If rc=0 then 'ERASE' wrkfile
 
/* Determine if outdisk is in write mode */
'MAKEBUF'
'QUERY DISK' substr(nfm,1,1) '(LIFO '
Parse Pull 7 . . wrmode . . blksz rest
freeblks = word(rest,words(rest)-1)
'DROPBUF'
If wrmode ^= 'R/W' then Call Comexit , 36, ,
   'Disk 'nfm' for ''newfile'' is not in read/write mode.'
reqblks = ( reqspace + blksz - 1 ) % blksz
If freeblks < reqblks then Do
  Say 'Estimated space requirement for output file is',
      ((reqspace + 1023) % 1024) 'k-Bytes.'
  Say 'Available space on disk 'left(nfm,1)' might not be sufficent.'
  Say 'Do you wish to continue? (Yes/No):'
  Parse Upper External resp .
  If ^abbrev('YES',resp,1) then Call Comexit , 16
End
 
/* Check options */
Do n=1 while options^=''
  Parse Var options option options
  Select
    When abbrev('REPLACE',option,3) then repopt = 1
    When abbrev('TYPE',option,1) then type = 'SERMON'
    When abbrev('NOTYPE',option,3) then type = ''
    Otherwise Call Comexit , 24, ,
         'Invalid option detected: 'option'.'
  End /* Select */
End n
 
If repopt=0 & newexist^=28 then Call Comexit , 28, ,
   '''Newfile'': "'newfile'" exists already.'
 
'FILEDEF DELTA DISK 'updfile
'FILEDEF OLD   DISK 'oldfile
'FILEDEF NEW   DISK 'wrkfile
'FILEDEF SYSPRINT TERMINAL (LOWCASE'
 
'UPDNODES' type
 
If rc=0 then Do
  If newexist=0 then 'ERASE 'newfile
  'RENAME 'wrkfile newfile
  'LSVSDATE 'newfile udt utm
  Call Comexit 'UONT', 0
End
Else Call Comexit 'UONT', rc, 'UPDNODES error. RC='rc'.'
 
Exit 9999
 
/* Common exit routine */
/* Call Comexit action, exitcode < , msg1 < , msg2 , ... > > */
/*      action: u = dealloc updfile, o = dealloc oldfile     */
/*              n = dealloc newfile, t = dealloc sysprint    */
/*              w = erase wrkfile                            */
Comexit:
  Arg action, exitcode, .
  'DROPBUF' bufno
  If pos('U',action)^=0 then 'FILEDEF DELTA CLEAR'
  If pos('O',action)^=0 then 'FILEDEF OLD   CLEAR'
  If pos('N',action)^=0 then 'FILEDEF NEW   CLEAR'
  If pos('T',action)^=0 then 'FILEDEF SYSPRINT CLEAR'
  If pos('W',action)^=0 then 'ERASE' wrkfile
  Do nmsg=3 for arg()-2
    Say arg(nmsg)
  End
  Exit exitcode
 
