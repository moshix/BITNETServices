/*********************************************************************/
/*                                                                   */
/*       PAROUTE EXEC       (Version 1.0, Date 94/06/30)             */
/*                                                                   */
/*   **** COPYRIGHT  UCI Nijmegen, The Netherlands  1994 ****        */
/*                                                                   */
/*********************************************************************/
version = '1.0 ; 94/06/30'
say 'PAROUTE EXEC version' version
Address Command
 
batch_fn   = 'PAROUTE'
batch_ft   = 'BATCH'
batch_fm   = 'A'
netinit_ft = 'NETINIT'
netinit_fm = 'A'
mnf_fn = 'BITEARN'
mnf_ft = 'NODES'
 
'MAKEBUF'
'LISTFILE' mnf_fn mnf_ft '* (STACK NOH'
If rc ^= 0 then Do
   say 'File' mnf_fn mnf_ft 'not found.'
   'DROPBUF'
   Exit 28
end
Parse Pull . . mnf_fm .
'DROPBUF'
 
Parse Upper Arg nodes
 
'SET CMSTYPE HT'
'ERASE' batch_fn batch_ft batch_fm
'SET CMSTYPE RT'
 
Do While nodes ^= ''
   Parse Var nodes node nodes
   'EXECIO 1 DISKW' batch_fn batch_ft batch_fm '(STR :node.'node
   'EXECIO 1 DISKW' batch_fn batch_ft batch_fm '(STR :file.'node'.'netinit_ft'.'netinit_fm
End
 
'FINIS' batch_fn batch_ft batch_fm
 
'PAROUTE -b 'batch_fn'.'batch_ft'.'batch_fm '-e' userid() mnf_fn'.'mnf_ft'.'mnf_fm
 
Exit rc
