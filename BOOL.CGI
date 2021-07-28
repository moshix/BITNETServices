/* COPYRIGHT 2021 BY MOSHIX
 *
 *
 *        Name: BOOK RETURNS OR AND XOR VALUES DECIMAL, HEX OR BIN
 *
 *
 *        Author: moshix
 *        Date: 2021-JUL-27 RAB, CROATIA
 *
 *
 */

'OUTPUT' "<html>"
Address "COMMAND" 'GLOBALV SELECT HTTPD GET VRM'
'OUTPUT' "<!CMS HTTPD" vrm "BOOL CGI>"

/*  eliminate piggy-backed CP command trojans  */
'ADDPIPE *.INPUT: | SPLIT AT' '001500'x '| *.INPUT:'
If rc ¬= 0 Then Exit rc

'PEEKTO RECORD'
If rc ¬= 0 Then record = ""
Parse Upper Var record arg1 arg2 .

Select  /*  arg1  */

    When Abbrev("OR",arg1,2)  Then    call exe_or(arg1)
    When Abbrev("AND",arg1,3) Then    call exec_and(arg1)
    When Abbrev("XOR",arg1,3) Then    call exec_xor(arg1)

    Otherwise                         CALL nonsense("NON EXISTING BOOLEAN")

    End  /*  Select  arg1  */

'OUTPUT' "<pre>"
'OUTPUT' "</pre>"
'OUTPUT' "</html>"

Exit

 exe_or:
  parse upper arg INPUT
  SELECT

    when left(INPUT,1) = "D" then do  /* WE GOT A DECIMAL NUMBER */
         count=LENGTH(INPUT) - 1
         cont1 = RIGHT(INPUT,count)   /* now we have the supposed number */
         if DATATYPE(cont1,'N') /= 1 then call nonsense("CONTENT NOT A VALID NUMB
         cont1hex = C2X(cont1)        /*we got a valid number, convert to hex */
         cont1bin = X2B(cont1)        /* convert to binary */
         result = BITOR(cont1bin,cont1bin)
         resultstr = B2X(result)      /* convert back to string */
         'OUTPUT' resultstr
       end

  OTHERWISE
     CALL nonsense("WRONG FORMAT")
  END

 return 0

 nonsense:
   parge UPPER ARG VALUE
   'OUTPUT' "EITHER NONSENSE REQUEST OR "VALUE
 return 0
