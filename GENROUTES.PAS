(**********************************************************************)00001000
(*                                                                    *)00002000
(*   Program to generate optimized routing tables for the             *)00003000
(*   EARN network.                                                    *)00004000
(*                                                                    *)00005000
(*   Author: Roland Wolf & Udo Meyer (MEYER@DEARN)                    *)00006000
(*           Gesellschaft fuer Schwerionenforschung mbH               *)00007000
(*           6100 Darmstadt 11                                        *)00008000
(*                                                                    *)00009000
(*   Copyright: IBM Deutschland                                       *)00010000
(*                                                                    *)00011000
(*                                                                    *)00012000
(*   85/04/17 Complete rewritten version of the old GENROUTS program  *)00013000
(*   85/05/02 Info file included                                R. W. *)00014000
(*   85/06/21 Generate also NOS and UNIX routing tables         R. W. *)00015000
(*   85/06/26 Error in the ALIAS NODENUM corrected              R. W. *)00016000
(*   85/10/30 Some improvements (larger PEND numbers) linkchk   R. W. *)00017000
(*   85/11/06 Some corrections for JES2                         R. W. *)00018000
(*   85/11/19 Generation of a plot file possible                R. W. *)00019000
(*   86/01/14 Errors for UREP corrected                         R. W. *)00020000
(*   86/05/28 RSCS/V2 and CTC connections included              U. M. *)00021000
(*   86/08/09 All LINK (local) statements as comment, check of  U. M. *)00022000
(*            nodes file added                                  U. M. *)00023000
(*   87/02/27 Parameter <nodialog>, new JES2 release, JES2 node U. M. *)00024000
(*            number offset, generation of XMAILER NAMES file,  U. M. *)00025000
(*            info file with specified tag                      U. M. *)00026000
(*   87/03/24 Corrections for JES2, XMAILER, INFO               U. M. *)00027000
(*   87/04/08 Truncation error with long mailer-ids fixed.      B. P. *)00028000
(*   87/04/09 Uppercasing netsoft now done correctly in MVS versP. S. *)00029000
(*   87/04/10 Error in JES2 v2 offset handling removed          D. S. *)00030000
(*            Uppercasing netsoft now done correctly in VM vers.P. S. *)00031000
(*   87/04/15 Errors corrected:                                 U. M. *)00032000
(*            Run with parameter TSO                            U. M. *)00033000
(*            NOS table, adjacent nodes                         U. M. *)00034000
(*   87/06/11 Node number limit increased to 4000               U. M. *)00035000
(*            JES2 max range for local node numbers: 300        U. M. *)00036000
(*            Adjtypes (speed) treatment corrected              U. M. *)00037000
(*   87/07/08 Node number limit dropped                         U. M. *)00038000
(*            JES2 local range limit dropped                    U. M. *)00039000
(*            JES2 table sorted by node numbers (option)        U. M. *)00040000
(*   88/05/20 LINKIGN tag supported                             U. M. *)00041000
(*            routing optimization algorithm changed            U. M. *)00042000
(*            eadjacent string increased                        U. M. *)00043000
(*   88/06/08 Error creating multiple NETINIT files corrected   U. M. *)00044000
(*   88/11/05 CMS command function (7)                          U. G. *)00045000
(*   88/11/10 eadjacents length  changed to 400                 U. G. *)00046000
(*   89/04/05 comment-char changed for JNET ('/.' -> '!')       U. G. *)00047000
(*   89/04/20 jes2_sort answer (trailing blanks removed)        U. G. *)00048000
(*   89/04/20 resistence for CTC changed from 0 to 1            M. G. *)00049000
(*   89/04/20 info-file output abend                            U. G. *)00050000
(*   89/05/03 handling of :via without :adj                     M. G. *)00051000
(*   89/09/12 better handling for NETSERV                       U. G. *)00052000
(*                                                                    *)00053000
(*   Abbreviations: R. W.  Roland Wolf                                *)00054000
(*                  U. M.  Udo Meyer                                  *)00055000
(*                  B. P.  Bert Pasch                                 *)00056000
(*                  P. S.  Peter Sylvester                            *)00057000
(*                  D. S.  Doron Shikmoni                             *)00058000
(*                  U. G.  Ulrich Giese                               *)00059000
(*                  M. G.  Michael Gettes                             *)00060000
(*                                                                    *)00061000
(**********************************************************************)00062000
program genrouts                                                        00063000
   (nodesfil,netfile,infofile,plotfile,xmailfil);                       00064000
(*                                                                    *)00065000
(*   nodesfil:    NODES file with tags and all information about the  *)00066000
(*                EARN nodes                                          *)00067000
(*   netfile:     OUTPUT file for the routing table                   *)00068000
(*   infofile:    OUTPUT file with information about the nodes        *)00069000
(*   plotfile:    OUTPUT file with plot instructions                  *)00070000
(*   xmailfil:    XMAILER NAMES file for VM(CUCCA) MAILER             *)00071000
(*                                                                    *)00072000
(**********************************************************************)00073000
%page                                                                   00074000
(*                                                                    *)00075000
type lpointer    = @typlink;                                            00076000
type npointer    = @typnode;                                            00077000
typnode    = record                    (********* node **********     *)00078000
              name    : alfa;          (*        nodename       *     *)00079000
              number  : integer;       (* node number for JES2  *     *)00080000
              nnstart : integer;       (* first node number     *     *)00081000
              country : string(8);     (*        country        *   | *)00082000
              gmtoff  : integer;       (*  GMT offset           *   | *)00083000
              institute : string(40);  (*        institute      *   | *)00084000
              syst    : string(20);    (*        OP system      *   | *)00085000
              contact : string(60);    (*  contact person       *   | *)00086000
              soft    : packed array(.1..4.) of char;  (* software  | *)00087000
              softrel : string(2);     (*  software release     *   | *)00088000
              next    : npointer;      (* --> to next node      *---+ *)00089000
              numnex  : npointer;      (* --> to next nodenumber*---> *)00090000
              linklist: lpointer;      (* --> to list of links  *----+*)00091000
              actlink : lpointer;      (* --> actual link point * |  |*)00092000
              via     : npointer;      (* --> prev. node in net *-+| |*)00093000
              vialink : npointer;      (* --> link routed throu *--+ |*)00094000
              distance: integer;       (* dist. from local node *    |*)00095000
              resist  : integer;       (* weight for distance   *    |*)00096000
              sumnum  : integer;       (* sum of node numbers   *    |*)00097000
              ok      : boolean;       (* ind. node is OK now   *    |*)00098000
              link_ok : boolean;       (* ind. link is OK       *    |*)00099000
              level   : integer;       (* level in plot         *    |*)00100000
              member  : integer;       (* plot variable         *    |*)00101000
              connect : integer;       (* for plot              *    |*)00102000
              xmailer : string(255);   (* XMAILER NAMES entry   *    |*)00103000
              linkign : string(255);   (* links to be ignored   *    |*)00104000
             end;                      (*************************<-+ |*)00105000
(*                                                                 | |*)00106000
typlink    = record                    (********* link *********   | |*)00107000
              name    : alfa;          (*        linkname      *<----+*)00108000
              speed   : integer;       (* speed of the line    *   |  *)00109000
              ptolink : npointer;      (* --> node connected   *---+  *)00110000
              next    : lpointer;      (* --> to next link     *--+   *)00111000
             end;                      (************************  |   *)00112000
(*                                                                V   *)00113000
type entries = record                  (***** NODE entry **************)00114000
              enodename : string(8);   (* node name                   *)00115000
              ealianame : string(255); (* alias nodename              *)00116000
              ecountry  : string(8);   (* country of the node         *)00117000
              enodenum  : string(4);   (* JES2 Node Number            *)00118000
              ennstart  : integer;     (* JES2 Node Number start      *)00119000
              ealianum  : string(4);   (* number for the alias node   *)00120000
              elocation : string(50);  (* address of the node         *)00121000
              esyst     : string(20);  (* operating system            *)00122000
              econtact  : string(60);  (* contact person              *)00123000
              esoftware : string(4);   (* software of the node        *)00124000
              esoftrel  : string(2);   (* software release            *)00125000
              eadjacents: string(400); (* list of the next EARN nodes *)00126000
              evia      : string(8);   (* next node to CUNY           *)00127000
              espeed    : string(255); (* speed of the line           *)00128000
              elinkign  : string(255); (* links to be ignored         *)00129000
              egmtoff   : integer;     (* GMT offset                  *)00130000
              emailer   : string(34);  (* MAILER entry                *)00131000
              emsoftw   : string(34);  (* complete software tag       *)00132000
              ereqrel   : string(8);   (* required GENROUTS release   *)00133000
              enet      : string(8);   (* network entry               *)00134000
             end;                      (*******************************)00135000
%page                                                                   00136000
var  code          : integer;          (* what to do 1,2,3,4,5        *)00137000
     date          : alfa;             (* the current date            *)00138000
     dialog        : boolean;          (* false if run as BATCH JOB   *)00139000
     dummyvia      : npointer;         (* dummy node for via pointer  *)00140000
     endstring     : boolean;          (* flags the end of a string   *)00141000
     entry         : entries;          (* contains the node entries   *)00142000
     filcheck      : integer;          (* check of nodes file         *)00143000
     formopt       : integer;          (* sort criteria for nodes     *)00144000
     formopt2      : integer;          (* form of info file           *)00145000
     gen_rel       : string(8);        (* current GENROUTS release    *)00146000
     hug_offset    : integer;                                           00147000
     hug_soft      : packed array (.1..4.) of char;                     00148000
     hug_softrel   : packed array (.1..2.) of char;                     00149000
     info          : string(64);       (* update information for rout *)00150000
     infofile      : text;             (* file with info about nodes  *)00151000
     inforeq       : boolean;          (* request for a info file     *)00152000
     ix            : integer;          (* auxilary                    *)00153000
     iy            : integer;          (* auxilary                    *)00154000
     jes2_sort     : integer;          (* how to sort JES2 tables     *)00155000
     key           : string(6);        (* indicates start of a nodesec*)00156000
     level         : integer;          (* distance to local node      *)00157000
     line          : string(400);      (* input line                  *)00158000
     linjesx       : integer;          (* number of lines             *)00159000
     link          : lpointer;         (* points to a link entry      *)00160000
     linkign_1     : string(17);       (* link to be ignored          *)00161000
     linkign_2     : string(17);       (* link to be ignored          *)00162000
     linklink      : lpointer;         (* points to the list of links *)00163000
     linknode      : npointer;         (* points to a link-node       *)00164000
     links_ok      : boolean;          (* if all links are OK         *)00165000
     links_id      : string(8);        (* nodes file update state     *)00166000
     local_node    : npointer;         (* netinits are gen for this n *)00167000
     locountry     : string(3);        (* country initial             *)00168000
     locount       : alfa;             (* same but other type         *)00169000
     maxdist       : integer;          (* maximum distance from local *)00170000
     maxname       : string(8);        (* node with maximum distance  *)00171000
     maxnum        : integer;          (* maximum assigned node num   *)00172000
     namen         : alfa;             (* aux nodename                *)00173000
     ndnamen       : alfa;             (* input nodename              *)00174000
     netfile       : text;             (* output file                 *)00175000
     newop         : boolean;          (* true if TSOLNK is available *)00176000
     node          : npointer;         (* pointer to a node           *)00177000
     nodeid        : alfa;             (* aux nodename                *)00178000
     nodesfil      : text;             (* inputfile                   *)00179000
     nummer        : integer;          (* aux node number             *)00180000
     numjes2       : integer;          (* number of JES2 nodes        *)00181000
     numjes3       : integer;          (* number of JES3 nodes        *)00182000
     numjnet       : integer;          (* number of JNET nodes        *)00183000
     numnje        : integer;          (* number of NJE nodes         *)00184000
     numrscs       : integer;          (* number of RSCS nodes        *)00185000
     numnos        : integer;          (* number of NOS nodes         *)00186000
     numurep       : integer;          (* number of UREP nodes        *)00187000
     numnodes      : integer;          (* number of all  nodes        *)00188000
     numstr        : string(4);        (* number as a string          *)00189000
     oldline       : string(400);      (* last input line             *)00190000
     oldnum        : integer;          (* number for not yet numb nod *)00191000
     outline       : string(255);      (* output line                 *)00192000
     orignode      : npointer;         (* points to a node            *)00193000
     pendstart     : integer;          (* start number for PEND nodes *)00194000
     plotfile      : text;             (* plot file                   *)00195000
     plotreq       : boolean;          (* request for a plot file     *)00196000
     pos           : integer;          (* position for tokening       *)00197000
     posi          : integer;          (* position for tokening       *)00198000
     pred_link     : lpointer;         (* last link                   *)00199000
     pred_node     : npointer;         (* last node                   *)00200000
     protocol      : alfa;             (* line protocol type          *)00201000
     resistence    : integer;          (* weighted distance of a node *)00202000
     resmod        : alpha;            (* filemode                    *)00203000
     restyp        : alpha;            (* filetype                    *)00204000
     result        : alpha;            (* filename and others         *)00205000
     softw         : packed array(.1..4.) of char; (*                 *)00206000
     speedline     : string(255);      (* speeds of the adjacent nodes*)00207000
     startnode     : npointer;         (* points to the dummy node    *)00208000
     tag           : string(12);       (* "tag" of an entry           *)00209000
     tag_found     : boolean;          (* indicates "tag found"       *)00210000
     tagend        : integer;          (* marks end of tag            *)00211000
     tag_num       : integer;          (* tag choice for INFO file    *)00212000
     tagstart      : integer;          (* marks start of tag          *)00213000
     tagval        : string(255);      (* value of the tag            *)00214000
     tagvalend     : integer;          (* marks end of that value     *)00215000
     testkey       : string(6);        (* to compare with tag :node.  *)00216000
     tsoname       : string(30);       (* TSO data set name           *)00217000
     time          : alfa;             (* current time                *)00218000
     ttyin         : text;             (* terminal input              *)00219000
     ttyout        : text;             (* terminal output             *)00220000
     vers_id       : string(8);        (* nodes file update state     *)00221000
     vmcms         : boolean;          (* true if CMS, false if TSO   *)00222000
     xmailerreq    : boolean;          (* request for XMAILER NAMES   *)00223000
     xmailfil      : text;             (* XMAILER NAMES file          *)00224000
     label           again;            (* ask what to do              *)00225000
     label           nextno;           (* next node                   *)00226000
     label           terminate;        (* terminate the program       *)00227000
     procedure cms(const s : string; var rc : integer); external;       00228000
%page                                                                   00229000
(**********************************************************************)00230000
(*                                                                    *)00231000
(*   This procedure converts a character (alfa) word to uppercase     *)00232000
(*                                                                    *)00233000
(**********************************************************************)00234000
procedure convert(var wort : alfa);   (* translate to uppercase *)      00235000
var ix : integer;                                                       00236000
begin                                                                   00237000
for ix := 1 to 8 do                                                     00238000
 begin                                                                  00239000
  case ord(wort(.ix.)) of                                               00240000
  129..137,145..153,162..169 : wort(.ix.) := chr(ord(wort(.ix.))+64);   00241000
  otherwise;                                                            00242000
 end;                                                                   00243000
 end;                                                                   00244000
end;                                                    (* of convert *)00245000
%page                                                                   00246000
(**********************************************************************)00247000
(*                                                                    *)00248000
(*   This procedure converts a character (alpha) word to uppercase    *)00249000
(*                                                                    *)00250000
(**********************************************************************)00251000
procedure convert_alpha(var wort : alpha);  (* translate to uppercase *)00252000
var ix : integer;                                                       00253000
begin                                                                   00254000
for ix := 1 to 16 do                                                    00255000
 begin                                                                  00256000
  case ord(wort(.ix.)) of                                               00257000
  129..137,145..153,162..169 : wort(.ix.) := chr(ord(wort(.ix.))+64);   00258000
  otherwise;                                                            00259000
 end;                                                                   00260000
 end;                                                                   00261000
end;                                              (* of convert_alpha *)00262000
%page                                                                   00263000
(**********************************************************************)00264000
(*                                                                    *)00265000
(*   This procedure prints a number with leading zeros                *)00266000
(*                                                                    *)00267000
(**********************************************************************)00268000
%page                                                                   00269000
procedure printnum( num : integer);                                     00270000
begin                                                                   00271000
  case num of                                                           00272000
       0..9: write(netfile,'000',num:1);                                00273000
     10..99: write(netfile,'00',num:2);                                 00274000
   100..999: write(netfile,'0',num:3);                                  00275000
   otherwise write(netfile,num:4);                                      00276000
  end;                                                                  00277000
end;                                                   (* of printnum *)00278000
(**********************************************************************)00279000
(*                                                                    *)00280000
(*   This procedure initializes the node variables                    *)00281000
(*   This initialization was requested becaus uninitialized variables *)00282000
(*   caused problems at some installations                            *)00283000
(*                                                                    *)00284000
(**********************************************************************)00285000
procedure initial(var initnode : npointer);                             00286000
begin                                                                   00287000
   initnode@.name      := '        ';                                   00288000
   initnode@.number    := 0;                                            00289000
   initnode@.nnstart   := 1;                                            00290000
   initnode@.country   := '';                                           00291000
   initnode@.gmtoff    := 0;                                            00292000
   initnode@.institute := '';                                           00293000
   initnode@.syst      := '';                                           00294000
   initnode@.contact   := '';                                           00295000
   initnode@.soft      := '    ';                                       00296000
   initnode@.softrel   := '  ';                                         00297000
   initnode@.next      := nil;                                          00298000
   initnode@.numnex    := nil;                                          00299000
   initnode@.actlink   := nil;                                          00300000
   initnode@.via       := nil;                                          00301000
   initnode@.vialink   := nil;                                          00302000
   initnode@.linkign   := '';                                           00303000
   initnode@.distance  := 0;                                            00304000
   initnode@.resist    := 0;                                            00305000
   initnode@.sumnum    := 0;                                            00306000
   initnode@.ok        := false;                                        00307000
   initnode@.link_ok   := false;                                        00308000
   initnode@.level     := 0;                                            00309000
   initnode@.member    := 0;                                            00310000
   initnode@.connect   := 0;                                            00311000
   initnode@.xmailer   := '';                                           00312000
end;  (* of initial *)                                                  00313000
%page                                                                   00314000
(**********************************************************************)00315000
(*                                                                    *)00316000
(*   This procedure executes a TSO command or program                 *)00317000
(*                                                                    *)00318000
(**********************************************************************)00319000
procedure tsocmd( prog_cmd  : integer;    cmdstr : string(255);         00320000
                  var rcode : integer);                                 00321000
type pa4   = packed array (.1..4.) of char;                             00322000
     pa80  = packed array (.1..255.) of char;                           00323000
procedure tsolnk( var parm1 : pa4;                                      00324000
                  var parm2 : pa80;                                     00325000
                  var parm3 : integer;                                  00326000
                  var parm4 : integer;                                  00327000
                  var parm5 : integer;                                  00328000
                  var parm6 : integer); FORTRAN;                        00329000
var parm1    : pa4;                                                     00330000
    parm2    : pa80;                                                    00331000
    parm3    : integer;                                                 00332000
    parm4    : integer;                                                 00333000
    parm5    : integer;                                                 00334000
    parm6    : integer;                                                 00335000
begin                                                                   00336000
   rcode := 99;                                                         00337000
   if (prog_cmd ^= 1) and (prog_cmd ^= 2) then return;                  00338000
   parm1(.1.) := chr(0);                                                00339000
   parm1(.2.) := chr(0);                                                00340000
   parm1(.3.) := chr(0);                                                00341000
   parm1(.4.) := chr(prog_cmd);                                         00342000
   parm2      := cmdstr;                                                00343000
   parm3      := length(cmdstr);                                        00344000
   parm4      := 0;                                                     00345000
   parm5      := 0;                                                     00346000
   parm6      := 0;                                                     00347000
   tsolnk(parm1,parm2,parm3,parm4,parm5,parm6);                         00348000
   rcode := parm4;                                                      00349000
end;   (* of tsocmd  *)                                                 00350000
%page                                                                   00351000
(**********************************************************************)00352000
(*                                                                    *)00353000
(*   This procedure searches for a node entry 'namen'                 *)00354000
(*                                                                    *)00355000
(**********************************************************************)00356000
procedure search( ptr : npointer; namen : alfa;                         00357000
                  var  runptr : npointer; var pred_node : npointer);    00358000
begin                                                                   00359000
(*           search for the node with the name 'namen'                *)00360000
runptr    := ptr;                                                       00361000
pred_node := ptr;                                                       00362000
repeat                                                                  00363000
    if runptr@.name = namen then leave      (*  we found it           *)00364000
    else if runptr@.name > namen then                                   00365000
         begin                  (* we are too far in the alphabet !!! *)00366000
            runptr    := nil;               (* initiate termination   *)00367000
         end else                                                       00368000
         begin                                                          00369000
            pred_node := runptr;                                        00370000
            runptr    := runptr@.next;      (* try the next one       *)00371000
         end;                                                           00372000
until runptr = nil                                                      00373000
end;  (* of search *)                                                   00374000
%page                                                                   00375000
(**********************************************************************)00376000
(*                                                                    *)00377000
(*   This procedure searches for a link entry                         *)00378000
(*                                                                    *)00379000
(**********************************************************************)00380000
procedure linksearch( lptr : lpointer; namen : alfa;                    00381000
                  var  runlink : lpointer; var pred_link : lpointer);   00382000
begin                                                                   00383000
(*           search for the link that points to 'namen'               *)00384000
runlink   := lptr;                                                      00385000
pred_link := nil;                                                       00386000
if runlink@.name > namen then begin                                     00387000
                        runlink := nil; return end;                     00388000
repeat                                                                  00389000
    if runlink@.name = namen then leave     (*  we found it           *)00390000
    else if runlink@.name > namen then                                  00391000
         begin                  (* we are too far in the alphabet !!! *)00392000
            runlink   := nil;               (* initiate termination   *)00393000
         end else                                                       00394000
         begin                                                          00395000
            pred_link := runlink;                                       00396000
            runlink   := runlink@.next;     (* try the next one       *)00397000
         end;                                                           00398000
until runlink = nil                                                     00399000
end;  (* of linksearch *)                                               00400000
%page                                                                   00401000
(**********************************************************************)00402000
(*                                                                    *)00403000
(*   This procedure decodes the complete node entry                   *)00404000
(*                                                                    *)00405000
(**********************************************************************)00406000
procedure decode;                                                       00407000
var actpos  : integer;                                                  00408000
    cconv   : alfa;                                                     00409000
    str_1   : string(255);                                              00410000
    label     eofchk;                                                   00411000
(*                                                                    *)00412000
procedure build_xmailer;       (* builds the mailer entry for XMAILER *)00413000
var m_pos  : integer;                                                   00414000
    m_id   : string(24);                                                00415000
    m_exit : string(16);                                                00416000
begin                                                                   00417000
with entry do begin                                                     00418000
  m_pos := index(emailer,' ');                                          00419000
  if m_pos > 0 then begin                                               00420000
     m_id  := substr(emailer,1,m_pos);                                  00421000
     if index(emailer,'BITNET')   > 0 then m_exit := 'BITNET 2'         00422000
        else                                                            00423000
     if index(emailer,'BSMTP')    > 0 then m_exit := 'BSMTP 3'          00424000
        else                                                            00425000
     if index(emailer,'LOCAL')    > 0 then m_exit := 'LOCAL 1'          00426000
        else                                                            00427000
     if index(emailer,'NOMAIL')   > 0 then m_exit := 'NOMAIL 2'         00428000
        else                                                            00429000
     if index(emailer,'INTERNET') > 0 then m_exit := 'INTERNET 1'       00430000
        else                                                            00431000
     if index(emailer,'RSMAIL')   > 0 then m_exit := 'RSMAIL 1'         00432000
        else                                                            00433000
     if index(emailer,'DEFRT')    > 0 then                              00434000
        if index(emailer,'TRUNC') > 0 then m_exit := 'DEFRT 1 TRUNCATE' 00435000
                                      else m_exit := 'DEFRT 1'          00436000
        else                                                            00437000
     m_exit := '';                                                      00438000
     emailer := trim(m_id)||' '||trim(m_exit);                          00439000
  end;                                                                  00440000
end;                                                                    00441000
end;                                    (* of procedure build_xmailer *)00442000
(*                                                                    *)00443000
procedure build_netsoft;        (* builds the networking software tag *)00444000
var   str_h1  : string(255);                                            00445000
      str_h2  : string(255);                                            00446000
begin                                                                   00447000
with entry do begin                                                     00448000
   str_h1  := trim(tagval);                                             00449000
   emsoftw := str_h1;                                                   00450000
   str_h2  := '';                                                       00451000
   posi := 1;                                                           00452000
   repeat                                                               00453000
      cconv := substr(str_h1,posi,                                      00454000
                      min((length(str_h1)-posi+1),8));                  00455000
      convert(cconv);                                                   00456000
      str_h2 := str_h2||str(cconv);                                     00457000
      posi := posi + 8;                                                 00458000
   until posi > length(str_h1);                                         00459000
   str_h2 := trim(str_h2);                                              00460000
   if index(str_h2,'RSCS') > 0 then begin                               00461000
      esoftware  := 'RSCS';                                             00462000
      if index(str_h2,'V2') > 0 then esoftrel := 'V2';                  00463000
   end else                                                             00464000
   if index(str_h2,'JES2') > 0 then begin                               00465000
      esoftware  := 'JES2';                                             00466000
      if ((index(str_h2,'1.3.6') > 0) |                                 00467000
          (index(str_h2,'2.1.5') > 0) |                                 00468000
          (index(str_h2,'2.2.0') > 0)) then esoftrel := 'V2';           00469000
   end else                                                             00470000
   if index(str_h2,'JES3') > 0 then esoftware := 'JES3'                 00471000
   else                                                                 00472000
   if index(str_h2,'JNET') > 0 then esoftware := 'JNET'                 00473000
   else                                                                 00474000
   if index(str_h2,'NJE') > 0  then esoftware := 'NJE '                 00475000
   else                                                                 00476000
   if index(str_h2,'UREP') > 0 then esoftware := 'UREP'                 00477000
   else                                                                 00478000
   if index(str_h2,'TIEL') > 0 then esoftware := 'TIEL'                 00479000
   else                                                                 00480000
   if index(str_h2,'INTE') > 0 then esoftware := 'INTE'                 00481000
   else                                                                 00482000
   esoftware  := substr(str_h2,1,min(length(str_h2),4));                00483000
end;                                                                    00484000
end;                                    (* of procedure build_netsoft *)00485000
(*                                                                    *)00486000
procedure namecheck;           (* checks names for comment characters *)00487000
var compos  : integer;                                                  00488000
begin                                                                   00489000
  with entry do begin                                                   00490000
     compos := max(index(enodename,'/'),                                00491000
                   index(enodename,'*'),                                00492000
                   index(enodename,'.'));                               00493000
     if compos > 0 then begin                                           00494000
        writeln(ttyout,'=Err=> WARNING: Invalid nodename '              00495000
                      ,enodename,' found in nodes file');               00496000
        goto terminate;                                                 00497000
     end;                                                               00498000
  end;                                                                  00499000
end;                                        (* of procedure namecheck *)00500000
(*                                                                    *)00501000
begin                                                                   00502000
with entry do begin         (* in 'entry' we store all the variables *) 00503000
   enodename  := '';                                                    00504000
   ealianame  := '';                                                    00505000
   ecountry   := '';                                                    00506000
   enodenum   := '';                                                    00507000
   ennstart   := 1;                                                     00508000
   ealianum   := '';                                                    00509000
   elocation  := '';                                                    00510000
   esyst      := '';                                                    00511000
   econtact   := '';                                                    00512000
   esoftware  := '';                                                    00513000
   esoftrel   := 'V1';                                                  00514000
   eadjacents := '';                                                    00515000
   elinkign   := '';                                                    00516000
   espeed     := '';                                                    00517000
   evia       := '';                                                    00518000
   egmtoff    := 0;                                                     00519000
   emailer    := '';                                                    00520000
   enet       := '';                                                    00521000
   ereqrel    := '';                                                    00522000
end;                                                                    00523000
testkey := '';                                                          00524000
if oldline = '' then begin         (* did we already read the line ? *) 00525000
  readln(nodesfil,key:6,line);     (* if 'not' then read tag and rest*) 00526000
  posi := index(line,' ');         (* ...find the end of the nodename*) 00527000
  readstr(line,nodeid:posi,line);  (* ...and read the nodename       *) 00528000
end else begin                                                          00529000
  readstr(oldline,key:6,line);     (* if we already read the line ...*) 00530000
  posi := index(line,' ');         (* do the same                    *) 00531000
  readstr(line,nodeid:posi,line);                                       00532000
end;                                                                    00533000
                                   (*                                *) 00534000
repeat                             (* decode a node entry            *) 00535000
tagvalend:= 2;                                                          00536000
%page                                                                   00537000
   repeat                          (* decode a line                  *) 00538000
     if line = '' then leave;                                           00539000
     if tagvalend = 2 then         (* decode ':tag.tagvalue'         *) 00540000
     tagstart := index(substr(line,1,length(line)),':')                 00541000
     else                                                               00542000
     tagstart := index(substr(line,tagvalend-1,length(line)             00543000
                 - tagvalend + 2),' :') + tagvalend - 1;                00544000
     tagend   := index(substr(line,tagstart,length(line)                00545000
                 - tagstart + 1),'.') + tagstart - 1;                   00546000
     tagvalend:= index(substr(line,tagend  ,length(line)                00547000
                 - tagend   + 1),' :') + tagend;                        00548000
     if tagvalend = tagend then tagvalend := length(line) + 1;          00549000
     tag    := substr(line,tagstart+1,tagend-tagstart-1);               00550000
     tagval := substr(line,tagend+1,tagvalend-tagend-1);                00551000
                                   (* OK, we have 'tag' and 'tagval' *) 00552000
     with entry do                 (* now, which tag is it ?         *) 00553000
        if tag = 'nodenum'  then begin                                  00554000
               enodenum   := trim(tagval);                              00555000
               if (enodenum='PEND') then enodenum:='';                  00556000
               end else                                                 00557000
        if tag = 'country'  then ecountry   := trim(tagval)        else 00558000
        if tag = 'alias'    then ealianame  := trim(tagval)        else 00559000
        if tag = 'aliasnum' then ealianum   := trim(tagval)        else 00560000
        if tag = 'via'      then evia       := trim(tagval)        else 00561000
        if tag = 'linkign'  then elinkign   := trim(tagval)        else 00562000
        if tag = 'genrouts' then begin                                  00563000
           ereqrel := trim(tagval);                                     00564000
           if ereqrel > gen_rel then begin                              00565000
              writeln(ttyout,'=Err=> The input nodes dataset '||        00566000
                             'requires GENROUTS release >= ',ereqrel);  00567000
              goto terminate;                                           00568000
           end;                                                         00569000
        end else                                                        00570000
        if tag = 'mailer'   then begin                                  00571000
           emailer := trim(tagval);                                     00572000
           if length(emailer) > 0 then build_xmailer;                   00573000
        end else                                                        00574000
        if tag = 'net'      then enet       := trim(tagval)        else 00575000
        if tag = 'gmtoff'   then readstr(tagval,egmtoff)           else 00576000
        if tag = 'abbr'     then                                        00577000
               elocation  := trim(substr(tagval,1,                      00578000
                                        min(length(tagval),50)))   else 00579000
        if tag = 'system'   then                                        00580000
               esyst      := trim(substr(tagval,1,                      00581000
                                        min(length(tagval),20)))   else 00582000
        if tag = 'contact'  then                                        00583000
               econtact   := trim(substr(tagval,1,                      00584000
                                        min(length(tagval),60)))   else 00585000
        if (tag = 'site') and (elocation = '')     then                 00586000
               elocation  := trim(substr(tagval,1,                      00587000
                                        min(length(tagval),50)))   else 00588000
        if (tag = 'netsoft') or (tag = 'swnet') then build_netsoft else 00589000
        if ((substr(tag,1,min(length(tag),3)) = 'inf') &                00590000
           (substr(tag,1,min(length(tag),6)) ^= 'inform')) then begin   00591000
           if length(tagval) > 4 then begin                             00592000
              actpos := 1;                                              00593000
              repeat                                                    00594000
                 cconv := substr(tagval,actpos,                         00595000
                                 min(length(tagval)-actpos,8));         00596000
                 convert(cconv);                                        00597000
                 str_1 := str(cconv);                                   00598000
                 posi := index(str_1,'JES2-');                          00599000
                 if posi > 0 then begin                                 00600000
                    posi := posi + actpos -1;                           00601000
                    str_1 := substr(tagval,posi+5,                      00602000
                                    length(tagval)-posi-4);             00603000
                    pos := index(str_1,' ');                            00604000
                    if (pos = 0) then pos := (length(str_1) + 1);       00605000
                    readstr(substr(str_1,1,pos-1),ennstart);            00606000
                    actpos := length(tagval);                           00607000
                 end;                                                   00608000
                 actpos := actpos + 4;                                  00609000
              until actpos > length(tagval);                            00610000
           end;                                                         00611000
               end else                                                 00612000
        if length(tag) > 8 then begin                                   00613000
           if substr(tag,1,8) = 'adjnodes' then                         00614000
                         eadjacents := eadjacents||' '||tagval;         00615000
           if substr(tag,1,8) = 'adjtypes' then                         00616000
              if    espeed    = ''         then                         00617000
                    espeed   := tagval                                  00618000
              else  espeed   := trim(espeed)||' '||tagval;              00619000
               end else                                                 00620000
        enodename  := str(nodeid);                                      00621000
        if substr(str(nodeid),1,4) = 'VERS' then                        00622000
              vers_id := str(nodeid) else                               00623000
        if substr(str(nodeid),1,5) = 'LINKS' then                       00624000
              links_id := str(nodeid);                                  00625000
                                   (*                                 *)00626000
    until tagvalend = length(line) + 1;                                 00627000
(*                                                                    *)00628000
    eofchk:                                                             00629000
    if eof(nodesfil) then                                               00630000
       begin                                                            00631000
         testkey := '';                                                 00632000
         leave;                                                         00633000
       end;                                                             00634000
    readln(nodesfil,line);                                              00635000
    if line = '' then goto eofchk;                                      00636000
    readstr(line,testkey:6);                                            00637000
    if (testkey=':node.') then                                          00638000
    begin oldline := line;                                              00639000
          leave; end;                                                   00640000
until testkey = '';                                                     00641000
namecheck;                                                              00642000
end;  (* of decode *)                                                   00643000
%page                                                                   00644000
(**********************************************************************)00645000
(*                                                                    *)00646000
(*   This procedure initiates the setting of the via variables        *)00647000
(*                                                                    *)00648000
(**********************************************************************)00649000
procedure initvia;                                                      00650000
(**********************************************************************)00651000
(*                                                                    *)00652000
(*   This procedure optimizes the routings by setting the 'distance'  *)00653000
(*   and 'resistence' variables for each node                         *)00654000
(*                                                                    *)00655000
(**********************************************************************)00656000
procedure setlevel( level : integer; actnode : npointer;                00657000
                    loclink : npointer; nodesum : integer);             00658000
var resistence : integer;                                               00659000
    linknode   : npointer;                                              00660000
    ign_flag   : boolean;                                               00661000
begin                                                                   00662000
  level := level + 10;                                                  00663000
  ign_flag := false;                                                    00664000
  actnode@.actlink := actnode@.linklist;                                00665000
  repeat                                    (* linknode points to the *)00666000
    linknode := actnode@.actlink@.ptolink;  (* link of actnode        *)00667000
    linkign_1 := trim(str(actnode@.name))||'-';                         00668000
    linkign_1 := linkign_1||trim(str(linknode@.name));                  00669000
    linkign_2 := trim(str(linknode@.name))||'-';                        00670000
    linkign_2 := linkign_2||trim(str(actnode@.name));                   00671000
    if ((index(local_node@.linkign,linkign_1) > 0) |                    00672000
      (index(local_node@.linkign,linkign_2) > 0)) then ign_flag := true;00673000
    resistence := actnode@.resist + actnode@.actlink@.speed;            00674000
    if ((resistence < linknode@.resist) &   (* weight for the distance*)00675000
        (linknode@.distance > 10) &         (* to the local node      *)00676000
        (^ign_flag)) then begin                                         00677000
         linknode@.distance := level;                                   00678000
         linknode@.resist   := resistence;                              00679000
         linknode@.via      := actnode;                                 00680000
         linknode@.vialink  := loclink;                                 00681000
         if (linknode@.sumnum > (linknode@.number+nodesum+10000)) then  00682000
         linknode@.sumnum   := linknode@.number + nodesum + 10000;      00683000
                                            (* goto the next level !  *)00684000
         setlevel(level,linknode,loclink,linknode@.sumnum);             00685000
       end else ign_flag := false;                                      00686000
    actnode@.actlink := actnode@.actlink@.next;                         00687000
  until actnode@.actlink = nil;                                         00688000
end;                                                                    00689000
%page                                                                   00690000
(**********************************************************************)00691000
(*                                                                    *)00692000
(*   This procedure sets the distance variables relative to the local *)00693000
(*   node back to the default values                                  *)00694000
(*                                                                    *)00695000
(**********************************************************************)00696000
procedure clearlevel;                                                   00697000
var linknode : npointer;                                                00698000
begin                                                                   00699000
linknode := startnode@.next;                                            00700000
repeat                                                                  00701000
   linknode@.resist   := 9999;                                          00702000
   linknode@.distance := 9999;                                          00703000
   linknode@.sumnum   := 1000000000;                                    00704000
   linknode@.via      := nil;                                           00705000
   linknode@.vialink  := nil;                                           00706000
   linknode@.ok       := false;                                         00707000
   linknode           := linknode@.next;                                00708000
until linknode = nil;                                                   00709000
end;                                                                    00710000
%page                                                                   00711000
(**********************************************************************)00712000
(*                                                                    *)00713000
(*   This procedure checks wether the via pointer are set for each    *)00714000
(*   node - detection of errors in nodes file.                        *)00715000
(*                                                                    *)00716000
(**********************************************************************)00717000
procedure viacheck;                                                     00718000
begin                                                                   00719000
node := startnode@.next;                                                00720000
filcheck := 0;                                                          00721000
repeat                                               (* for each node *)00722000
   if node@.via = nil then                                              00723000
   begin                                                                00724000
      writeln(ttyout,'=Err=> No via pointer set for node '              00725000
              ,node@.name:8,'.');                                       00726000
      filcheck := filcheck + 1;                                         00727000
   end;                                                                 00728000
   if (maxdist < node@.distance) then begin                             00729000
      maxdist := max(maxdist,node@.distance);                           00730000
      maxname := str(node@.name);                                       00731000
   end;                                                                 00732000
   node := node@.next;                                                  00733000
until node = nil;                                                       00734000
if filcheck >= 1 then                                                   00735000
begin                                                                   00736000
   writeln(ttyout,'=Err=> ',filcheck:4,' nodes not connected to '       00737000
           ,local_node@.name:8,'.');                                    00738000
   writeln(ttyout,'=Err=> Check nodes file.');                          00739000
   goto terminate;                                                      00740000
end;                                                                    00741000
end;                                                                    00742000
%page                                                                   00743000
(**********************************************************************)00744000
(*                                                                    *)00745000
(*   This procedure sets the vialink pointers                         *)00746000
(*                                                                    *)00747000
(**********************************************************************)00748000
procedure setvia( vnode : npointer; var vianode : npointer);            00749000
var checkres : integer;                                                 00750000
    ign_flag : boolean;                                                 00751000
begin                                                                   00752000
if vnode@.ok = true then                  (* we had this node already *)00753000
begin                                                                   00754000
   vianode := vnode@.vialink;                                           00755000
   return;                                                              00756000
end;                                                                    00757000
vnode@.actlink := vnode@.linklist;                                      00758000
resistence     := vnode@.resist;                                        00759000
repeat                           (* search the link to the local node *)00760000
   linknode := vnode@.actlink@.ptolink;                                 00761000
   linkign_1 := trim(str(vnode@.name))||'-';                            00762000
   linkign_1 := linkign_1||trim(str(linknode@.name));                   00763000
   linkign_2 := trim(str(linknode@.name))||'-';                         00764000
   linkign_2 := linkign_2||trim(str(vnode@.name));                      00765000
   if ((index(local_node@.linkign,linkign_1) > 0) |                     00766000
       (index(local_node@.linkign,linkign_2) > 0))                      00767000
       then ign_flag := true                                            00768000
       else ign_flag := false;                                          00769000
   if ^ign_flag then begin                                              00770000
      checkres := linknode@.resist + vnode@.actlink@.speed;             00771000
      if checkres < resistence then        (* which link has the      *)00772000
      begin                                (* smallest resistence to  *)00773000
         resistence := checkres;           (* the local node          *)00774000
         vnode@.via := linknode;           (* set pointer to this node*)00775000
      end else                                                          00776000
      if checkres = resistence then        (* two equal links !       *)00777000
      begin                                (* decide by the sum of    *)00778000
         if linknode@.sumnum < vnode@.via@.sumnum     (* node numbers *)00779000
          then vnode@.via := linknode;     (* reset the pointer       *)00780000
      end;                                                              00781000
   end;                                                                 00782000
   vnode@.actlink := vnode@.actlink@.next;                              00783000
until vnode@.actlink = nil;                                             00784000
(*                    now we have the correct link to the next node   *)00785000
if vnode@.via@.distance = 10 then   (* we are down at the link of the *)00786000
     vianode := vnode@.via          (* local node                     *)00787000
else setvia(vnode@.via,vianode);                                        00788000
vnode@.vialink := vianode;          (* set pointer to link of loc node*)00789000
vnode@.ok := true;                                                      00790000
end;                                           (* of procedure setvia *)00791000
%page                                                                   00792000
(*                                                                    *)00793000
(*               start of initvia                                     *)00794000
(*                                                                    *)00795000
begin                                                                   00796000
  clearlevel;                                                           00797000
  local_node@.resist   := 0;                                            00798000
  local_node@.distance := 0;                                            00799000
  local_node@.sumnum   := local_node@.number;                           00800000
  level := 10;                     (* set the pointer to the node with*)00801000
  local_node@.actlink := local_node@.linklist;   (* --> to link-list  *)00802000
  local_node@.via     := dummyvia;                                      00803000
  local_node@.vialink := dummyvia;                                      00804000
  repeat                                                                00805000
      linknode           := local_node@.actlink@.ptolink;               00806000
      resistence         := local_node@.actlink@.speed;                 00807000
      linknode@.distance := level;                                      00808000
      linknode@.resist   := resistence;                                 00809000
      linknode@.via      := local_node;                                 00810000
      linknode@.vialink  := dummyvia;                                   00811000
      linknode@.sumnum   := local_node@.number + linknode@.number+10000;00812000
                                   (* set levels of the other nodes  *) 00813000
      setlevel(level,linknode,linknode,linknode@.sumnum);               00814000
      local_node@.actlink := local_node@.actlink@.next;                 00815000
  until local_node@.actlink = nil;                                      00816000
  viacheck;                                                             00817000
(*   now make sure that a routing generated at one node to another  *)  00818000
(*   is the same if the program is run at the other node            *)  00819000
(*   The decision in made for equal distances acording the smaller  *)  00820000
(*   sum of node numbers along the line                             *)  00821000
(*   Set the via and vialink variables !                            *)  00822000
  node := startnode@.next;                                              00823000
  repeat                                           (* for each node *)  00824000
   if (node@.distance <= 10) or (node@.ok = true) then                  00825000
      begin                                                             00826000
        node := node@.next;                                             00827000
        continue;                                                       00828000
      end;                                                              00829000
   setvia(node,node@.vialink);                                          00830000
   node@.ok := true;                                                    00831000
   node := node@.next;                                                  00832000
  until node = nil;                                                     00833000
end;    (*  of initvia   *)                                             00834000
%page                                                                   00835000
(**********************************************************************)00836000
(*                                                                    *)00837000
(*   This procedure generates the routing tables for RSCS             *)00838000
(*                                                                    *)00839000
(**********************************************************************)00840000
procedure rscsinit;                                                     00841000
var runptr : npointer;                                                  00842000
    gmto   : integer;                                                   00843000
procedure printroute;            (* proc to print a routing statement *)00844000
begin                                                                   00845000
  writeln(netfile,' ROUTE ',runptr@.name:8,                             00846000
               ' ',runptr@.vialink@.name:8,                             00847000
               ' ',round(runptr@.distance/10-1):2,                      00848000
               ' ',runptr@.country:-3,                                  00849000
               ' ',runptr@.institute);                                  00850000
end;                                                                    00851000
begin                                                                   00852000
(*               print the heading                                   *) 00853000
writeln(netfile,'***',                                                  00854000
'******************************************************************');  00855000
if local_node@.soft = 'RSCS' then                                       00856000
writeln(netfile,'*   ',local_node@.soft,'/',local_node@.softrel,        00857000
                ' ROUTING STATEMENTS FOR NODE '                         00858000
                ,local_node@.name:-8,'                    *')           00859000
else                                                                    00860000
writeln(netfile,'*   RSCS ROUTING STATEMENTS FOR NODE '                 00861000
                ,local_node@.name:-8,'                       *');       00862000
writeln(netfile,'*':-68,'*');                                           00863000
writeln(netfile,'*   Nodes file update level:    EARN   - '             00864000
                ,vers_id:-8,'                   *');                    00865000
writeln(netfile,'*                               BITNET - '             00866000
                ,links_id:-8,'                   *');                   00867000
writeln(netfile,'*':-68,'*');                                           00868000
writeln(netfile,'*   Generation date:  ',date,'   ',time,               00869000
                '                           *');                        00870000
writeln(netfile,'*':-68,'*');                                           00871000
writeln(netfile,'*   ',info:-64,'*');                                   00872000
writeln(netfile,'*':-68,'*');                                           00873000
writeln(netfile,'***',                                                  00874000
'******************************************************************');  00875000
writeln(netfile,'*  ',                                                  00876000
'                 RSCS LOCAL NODE SPECIFICATION                   *');  00877000
writeln(netfile,'***',                                                  00878000
'******************************************************************');  00879000
writeln(netfile,'*  ',                                                  00880000
'            LOCAL      GMT                                       *');  00881000
writeln(netfile,'*  ',                                                  00882000
'           NODE-ID    OFFSET                                     *');  00883000
writeln(netfile,'*  ',                                                  00884000
'           --------  --------                                    *');  00885000
gmto := local_node@.gmtoff;                                             00886000
if gmto <= 0 then gmto := abs(gmto)  else gmto := 25 - gmto;            00887000
writeln(netfile,'*  ',                                                  00888000
' LOCAL     ',local_node@.name:8,'     ',gmto:2,'   ');                 00889000
writeln(netfile,'***',                                                  00890000
'******************************************************************');  00891000
%page                                                                   00892000
if local_node@.soft = 'RSCS' then                                       00893000
   writeln(netfile,'*                    RSCS/',local_node@.softrel,    00894000
                   ' LINK SPECIFICATIONS                    *')         00895000
else                                                                    00896000
   writeln(netfile,'*                    RSCS',                         00897000
                   ' LINK SPECIFICATIONS                       *');     00898000
writeln(netfile,'***',                                                  00899000
'******************************************************************');  00900000
if (local_node@.softrel = 'V1') then begin                              00901000
writeln(netfile,'*  ',                                                  00902000
'                   LINE      VIRTUAL  TIME  TASK  SPOOL  KEEP    *');  00903000
writeln(netfile,'*  ',                                                  00904000
'         LINK-ID   DRIVER    ADDRESS  ZONE  ID    CLASS  SLOTS   *');  00905000
writeln(netfile,'*  ',                                                  00906000
'         --------  --------  -------  ----  ----  -----  -----   *');  00907000
                                end else begin                          00908000
writeln(netfile,'*  ',                                                  00909000
'                  LINE    VIRT  TIME  SPOOL  KEEP                *');  00910000
writeln(netfile,'*  ',                                                  00911000
'        LINK-ID   DRIVER  ADDR  ZONE  CLASS  SLOTS  QUEUE  DP    *');  00912000
writeln(netfile,'*  ',                                                  00913000
'        --------  ------  ----  ----  -----  -----  -----  --    *');  00914000
                                end;                                    00915000
              (*        first the links !                             *)00916000
local_node@.actlink := local_node@.linklist;                            00917000
repeat                                                                  00918000
  runptr := local_node@.actlink@.ptolink;                               00919000
  if ((((runptr@.soft = 'RSCS') & (runptr@.softrel ^= 'V2')) or         00920000
  (runptr@.soft = 'JNET')) or (runptr@.soft = 'UREP')) then             00921000
      protocol := 'DMTVMB'                                              00922000
    else                                                                00923000
  if ((runptr@.soft = 'TIEL') or (runptr@.soft = 'INTE')) then          00924000
      protocol := 'DMTSML'                                              00925000
    else                                                                00926000
      protocol := 'DMTNJI';                                             00927000
  gmto := runptr@.gmtoff;                                               00928000
  if gmto <= 0 then gmto := abs(gmto)  else gmto := 25 - gmto;          00929000
  if (local_node@.softrel = 'V1') then                                  00930000
     writeln(netfile,'*   LINK    ',runptr@.name:8,'  ',                00931000
     protocol:8,'    xxx     ',gmto:2,'   XXXX    *      2')            00932000
                                  else                                  00933000
     writeln(netfile,'*  ',                                             00934000
     'LINK    ',runptr@.name:8,'  NJE     xxx    ',gmto:2,              00935000
     '     X      *     PRI   *');                                      00936000
local_node@.actlink := local_node@.actlink@.next;                       00937000
until local_node@.actlink = nil;                                        00938000
%page                                                                   00939000
(*      now the routings: first the national nodes!                   *)00940000
writeln(netfile,'***',                                                  00941000
'******************************************************************');  00942000
writeln(netfile,'*  ',                                                  00943000
'                   RSCS ROUTE SPECIFICATIONS                     *');  00944000
writeln(netfile,'***',                                                  00945000
'******************************************************************');  00946000
writeln(netfile,'*  ',                                                  00947000
'                   Interm.                                       *');  00948000
writeln(netfile,'*  ',                                                  00949000
'    Node     Vianode   | Country                                 *');  00950000
writeln(netfile,'*  ',                                                  00951000
'    |        |     nodes |   Institute/Location                  *');  00952000
writeln(netfile,'*--',                                                  00953000
'----|--------|---------|-|---|-----------------------------------*');  00954000
runptr := startnode@.next;                                              00955000
repeat                  (* routing statements for the version entries *)00956000
   if ((substr(str(runptr@.name),1,4) = 'VERS') |                       00957000
       (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;      00958000
   runptr := runptr@.next;                                              00959000
until runptr = nil;                                                     00960000
runptr := startnode@.next;                                              00961000
repeat                       (* routing statements for national nodes *)00962000
   if (runptr@.country = local_node@.country) and                       00963000
      (runptr@.distance > 10) then                                      00964000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      00965000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     00966000
   runptr := runptr@.next;                                              00967000
until runptr = nil;                                                     00968000
runptr := startnode@.next;                                              00969000
repeat              (* routing statements for the international nodes *)00970000
   if (runptr@.country ^= local_node@.country) and                      00971000
      (runptr@.distance > 10) then                                      00972000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      00973000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     00974000
   runptr := runptr@.next;                                              00975000
until runptr = nil;                                                     00976000
end; (********************** of rscsinit ****************************)  00977000
%page                                                                   00978000
(**********************************************************************)00979000
(*                                                                    *)00980000
(*   This procedure generates the routing tables for JES3             *)00981000
(*                                                                    *)00982000
(**********************************************************************)00983000
procedure jes3init;                                                     00984000
var runptr : npointer;                                                  00985000
procedure printroute;            (* proc to print a routing statement *)00986000
begin                                                                   00987000
  ix := length(trim(str(runptr@.name)));                                00988000
  writeln(netfile,'*           ',runptr@.name,' (',                     00989000
          round(runptr@.distance/10-1):2,') = ',                        00990000
          runptr@.country:-3,' ',runptr@.institute);                    00991000
  writeln(netfile,'NJERMT,NAME=',runptr@.name:ix,                       00992000
                  ',MAXLINE=0,PATH=',runptr@.vialink@.name:8);          00993000
end;                                                                    00994000
begin                                                                   00995000
(*               print the heading                                   *) 00996000
writeln(netfile,'***',                                                  00997000
'******************************************************************');  00998000
writeln(netfile,'*   ',local_node@.soft:4,                              00999000
                ' ROUTING STATEMENTS FOR NODE '                         01000000
                ,local_node@.name:8,'                       *');        01001000
writeln(netfile,'*':-68,'*');                                           01002000
writeln(netfile,'*   Nodes file update level:    EARN   - '             01003000
                ,vers_id:-8,'                   *');                    01004000
writeln(netfile,'*                               BITNET - '             01005000
                ,links_id:-8,'                   *');                   01006000
writeln(netfile,'*':-68,'*');                                           01007000
writeln(netfile,'*   Generation date:  ',date,'   ',time,               01008000
                '                           *');                        01009000
writeln(netfile,'*':-68,'*');                                           01010000
writeln(netfile,'*   ',info:-64,'*');                                   01011000
writeln(netfile,'*':-68,'*');                                           01012000
writeln(netfile,'***',                                                  01013000
'******************************************************************');  01014000
writeln(netfile,'*  ',                                                  01015000
'                 JES3 LOCAL NODE SPECIFICATION                   *');  01016000
writeln(netfile,'***',                                                  01017000
'******************************************************************');  01018000
ix := length(trim(str(local_node@.name)));                              01019000
writeln(netfile,'* NJECONS');                                           01020000
writeln(netfile,'* CONSOLE,JNAME=NETWORK,TYPE=NJE');                    01021000
writeln(netfile,'* NJERMT,NAME=',local_node@.name:ix,',MAXLINE=0,',     01022000
                'HOME=YES');                                            01023000
writeln(netfile,'***',                                                  01024000
'******************************************************************');  01025000
%page                                                                   01026000
writeln(netfile,'*  ',                                                  01027000
'                   JES3 LINK SPECIFICATIONS                      *');  01028000
writeln(netfile,'***',                                                  01029000
'******************************************************************');  01030000
              (*        first the links !                             *)01031000
linjesx   := 0;                                                         01032000
local_node@.actlink := local_node@.linklist;                            01033000
repeat                                                                  01034000
  runptr := local_node@.actlink@.ptolink;                               01035000
  ix := length(trim(str(runptr@.name)));                                01036000
  linjesx := linjesx + 1;                                               01037000
  write(netfile,'* NJERMT,NAME=',runptr@.name:ix,',LINE=NJE');          01038000
  case linjesx of                                                       01039000
     0..9:   writeln(netfile,'00',linjesx:1,',AUTO=YES,RDLY=02');       01040000
   10..99:   writeln(netfile,'0',linjesx:2,',AUTO=YES,RDLY=02');        01041000
   otherwise writeln(netfile,linjesx:3,',AUTO=YES,RDLY=02');            01042000
  end;                                                                  01043000
local_node@.actlink := local_node@.actlink@.next;                       01044000
until local_node@.actlink = nil;                                        01045000
%page                                                                   01046000
(*      now the routings: first the national nodes!                   *)01047000
writeln(netfile,'***',                                                  01048000
'******************************************************************');  01049000
writeln(netfile,'*  ',                                                  01050000
'                   JES3 ROUTE SPECIFICATIONS                     *');  01051000
writeln(netfile,'***',                                                  01052000
'******************************************************************');  01053000
writeln(netfile,'*  ',                                                  01054000
'                Interm.                                          *');  01055000
writeln(netfile,'*  ',                                                  01056000
'         Node     ( |)   Country                                 *');  01057000
writeln(netfile,'*  ',                                                  01058000
'         |        nodes  |   Institute/Location                  *');  01059000
writeln(netfile,'*--',                                                  01060000
'---------|----------|----|---|-----------------------------------*');  01061000
runptr := startnode@.next;                                              01062000
repeat                  (* routing statements for the version entries *)01063000
   if ((substr(str(runptr@.name),1,4) = 'VERS') |                       01064000
       (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;      01065000
   runptr := runptr@.next;                                              01066000
until runptr = nil;                                                     01067000
runptr := startnode@.next;                                              01068000
repeat                       (* routing statements for national nodes *)01069000
   if (runptr@.country = local_node@.country) and                       01070000
      (runptr@.distance > 10) then                                      01071000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01072000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01073000
   runptr := runptr@.next;                                              01074000
until runptr = nil;                                                     01075000
runptr := startnode@.next;                                              01076000
repeat              (* routing statements for the international nodes *)01077000
   if (runptr@.country ^= local_node@.country) and                      01078000
      (runptr@.distance > 10) then                                      01079000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01080000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01081000
   runptr := runptr@.next;                                              01082000
until runptr = nil;                                                     01083000
end; (********************** of jes3init ****************************)  01084000
%page                                                                   01085000
(**********************************************************************)01086000
(*                                                                    *)01087000
(*   These procedures generate the routing tables for JES2            *)01088000
(*                                                                    *)01089000
(**********************************************************************)01090000
(*   First the old JES2 Release (  <  2.1.5 / 1.3.6 )                 *)01091000
(**********************************************************************)01092000
procedure jes2_v1_init;                                                 01093000
var runptr : npointer;                                                  01094000
    nnplus : integer;                                                   01095000
    nodnum : integer;                                                   01096000
procedure printroute;            (* proc to print a routing statement *)01097000
begin                                                                   01098000
  ix := length(trim(str(runptr@.name)));                                01099000
  write(netfile,'*     ');                            (* start line 1 *)01100000
  writeln(netfile,'     ',                                              01101000
      round(runptr@.distance/10-1):2,'  ',                              01102000
      runptr@.country:-3,' ',runptr@.institute:-40,' -> ',              01103000
      runptr@.vialink@.name);                                (* end 1 *)01104000
  write(netfile,'N');                                 (* start line 2 *)01105000
  nodnum := runptr@.number + nnplus;                                    01106000
  printnum(nodnum);                                                     01107000
  write(netfile,' NAME=',runptr@.name:ix);                              01108000
  writeln(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA'); (* e 2 *)01109000
  write(netfile,'CONNECT NODEA=');                    (* start line 3 *)01110000
  printnum(nodnum);                                                     01111000
  write(netfile,',MEMBA=1,NODEB=');                                     01112000
  nodnum := runptr@.via@.number + nnplus;                               01113000
  printnum(nodnum);                                                     01114000
  writeln(netfile,',MEMBB=1,REST=2',                                    01115000
                  '  --con.-> ',runptr@.via@.name);     (* end line 3 *)01116000
end;                                                                    01117000
begin                                                                   01118000
nnplus := local_node@.nnstart - 1;                                      01119000
(*               print the heading                                   *) 01120000
outline := '********************************************************'|| 01121000
           '*************';                                             01122000
writeln(netfile,'*',outline,'*');                                       01123000
writeln(netfile,'*   ',local_node@.soft:4,                              01124000
                ' ROUTING STATEMENTS FOR NODE '                         01125000
                 ,local_node@.name:8,'                         *');     01126000
writeln(netfile,'*':-70,'*');                                           01127000
if nnplus > 0 then                                                      01128000
   writeln(netfile,'*   Node numbers starting with number '             01129000
                   ,local_node@.nnstart:-4,'*':29) else                 01130000
   writeln(netfile,'*   No local range preserved for node numbers':-70  01131000
                   ,'*');                                               01132000
writeln(netfile,'*   PENDing nodes starting at number  '                01133000
                   ,pendstart:-4,'*':29);                               01134000
writeln(netfile,'*   Maximum assigned node number :    '                01135000
                   ,maxnum + nnplus:-4,'*':29);                         01136000
writeln(netfile,'*':-70,'*');                                           01137000
writeln(netfile,'*   Nodes file update level:    EARN   - '             01138000
                ,vers_id:-8,'                     *');                  01139000
writeln(netfile,'*                               BITNET - '             01140000
                ,links_id:-8,'                     *');                 01141000
writeln(netfile,'*':-70,'*');                                           01142000
writeln(netfile,'*   Generation date:  ',date,'   ',time,               01143000
                '                             *');                      01144000
writeln(netfile,'*':-70,'*');                                           01145000
writeln(netfile,'*   ',info:-64,'  *');                                 01146000
writeln(netfile,'*':-70,'*');                                           01147000
writeln(netfile,'*',outline,'*');                                       01148000
writeln(netfile,'*       ',                                             01149000
'             JES2 LOCAL NODE SPECIFICATION                    *');     01150000
writeln(netfile,'*',outline,'*');                                       01151000
ix   := 0;                        (*  how many links do we have ?  *)   01152000
link := local_node@.linklist;                                           01153000
repeat                                                                  01154000
   ix   := ix + 1;                                                      01155000
   link := link@.next;                                                  01156000
until link = nil;                                                       01157000
nodnum := local_node@.number + nnplus;                                  01158000
writeln(netfile,'*&OWNNODE=',nodnum:-4);                                01159000
writeln(netfile,'*&NUMNODE=',maxnum + nnplus:-4);                       01160000
writeln(netfile,'*&NETLNES=',ix:-4);                                    01161000
ix := length(trim(str(local_node@.name)));                              01162000
write(netfile,'*N');                                                    01163000
     printnum(nodnum);                                                  01164000
     write(netfile,' NAME=',local_node@.name:ix);                       01165000
     writeln(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA');       01166000
%page                                                                   01167000
writeln(netfile,'*',outline,'*');                                       01168000
writeln(netfile,'*       ',                                             01169000
'               JES2 LINK SPECIFICATIONS                       *');     01170000
writeln(netfile,'*',outline,'*');                                       01171000
                                                 (*  first the links  *)01172000
local_node@.actlink := local_node@.linklist;                            01173000
repeat                                                                  01174000
   runptr := local_node@.actlink@.ptolink;                              01175000
   ix := length(trim(str(runptr@.name)));                               01176000
   write(netfile,'*     ');                                             01177000
   writeln(netfile,'         ',runptr@.country:-3,                      01178000
                   ' ',runptr@.institute);                              01179000
   write(netfile,'*N');                                                 01180000
   nodnum := runptr@.number + nnplus;                                   01181000
   printnum(nodnum);                                                    01182000
   write(netfile,' NAME=',runptr@.name:ix);                             01183000
   writeln(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA');         01184000
   write(netfile,'*CONNECT NODEA=');                                    01185000
   printnum(nodnum);                                                    01186000
   write(netfile,',MEMBA=1,NODEB=');                                    01187000
   nodnum := runptr@.via@.number + nnplus;                              01188000
   printnum(nodnum);                                                    01189000
   writeln(netfile,',MEMBB=1,REST=2 --con.-> ',local_node@.name);       01190000
   local_node@.actlink := local_node@.actlink@.next;                    01191000
until local_node@.actlink = nil;                                        01192000
%page                                                                   01193000
                      (* now the routings: first the description part *)01194000
writeln(netfile,'*',outline,'*');                                       01195000
writeln(netfile,'*       ',                                             01196000
'               JES2 ROUTE SPECIFICATIONS                      *');     01197000
writeln(netfile,'*',outline,'*');                                       01198000
writeln(netfile,'*     In',                                             01199000
'term.nodes                                             Vialink ');     01200000
writeln(netfile,'*Number ',                                             01201000
'    |  Country                                         |       ');     01202000
writeln(netfile,'*|    No',                                             01203000
'de  |  |   Institute/Location                          Vianode ');     01204000
writeln(netfile,'*|----|-',                                             01205000
'----|--|---|-------------------------------------------|-------');     01206000
if jes2_sort = 1 then begin                    (* sort alphabetically *)01207000
   runptr := startnode@.next;                                           01208000
   repeat               (* routing statements for the version entries *)01209000
      if ((substr(str(runptr@.name),1,4) = 'VERS') |                    01210000
          (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;   01211000
      runptr := runptr@.next;                                           01212000
   until runptr = nil;                                                  01213000
   runptr := startnode@.next;                                           01214000
   repeat                    (* routing statements for national nodes *)01215000
      if (runptr@.country = local_node@.country) and                    01216000
         (runptr@.distance > 10) then                                   01217000
      if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                   01218000
          (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;  01219000
      runptr := runptr@.next;                                           01220000
   until runptr = nil;                                                  01221000
   runptr := startnode@.next;                                           01222000
   repeat           (* routing statements for the international nodes *)01223000
      if (runptr@.country ^= local_node@.country) and                   01224000
         (runptr@.distance > 10) then                                   01225000
      if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                   01226000
          (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;  01227000
      runptr := runptr@.next;                                           01228000
   until runptr = nil;                                                  01229000
end else begin                                (* sort by node numbers *)01230000
   runptr := startnode@.numnex;                                         01231000
   repeat                                                               01232000
      if (runptr@.distance > 10) then printroute;                       01233000
      runptr := runptr@.numnex;                                         01234000
   until runptr = nil;                                                  01235000
end;                                                                    01236000
end;                                               (* of jes2_v1_init *)01237000
%page                                                                   01238000
(**********************************************************************)01239000
(*   Now the table for JES2 Release 2.1.5 / 1.3.6                     *)01240000
(**********************************************************************)01241000
procedure jes2_v2_init;                                                 01242000
var runptr : npointer;                                                  01243000
    nnplus : integer;                                                   01244000
    nodnum : integer;                                                   01245000
procedure printroute;            (* proc to print a routing statement *)01246000
begin                                                                   01247000
  write(netfile,'/*':-11);                            (* start line 1 *)01248000
  writeln(netfile,round(runptr@.distance/10-1):2,'  ',                  01249000
                  runptr@.country:-3,' ',                               01250000
                  runptr@.institute:-37,' -> ',                         01251000
                  runptr@.vialink@.name:8,'*/':3);           (* end 1 *)01252000
  ix := length(trim(str(runptr@.name)));                                01253000
  write(netfile,'N');                                 (* start line 2 *)01254000
  nodnum := runptr@.number + nnplus;                                    01255000
  printnum(nodnum);                                                     01256000
  write(netfile,' NAME=',runptr@.name:ix);                              01257000
  writeln(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA'); (* e 2 *)01258000
  write(netfile,'CONNECT NODEA=');                    (* start line 3 *)01259000
  printnum(nodnum);                                                     01260000
  write(netfile,',MEMBA=1,NODEB=');                                     01261000
  nodnum := runptr@.via@.number + nnplus;                               01262000
  printnum(nodnum);                (* Fixed 9 Apr 87 - Doron Shikmoni *)01263000
  write(netfile,',MEMBB=1,REST=2');                                     01264000
  writeln(netfile,'/* -> ':8,runptr@.via@.name:8,' */');     (* end 3 *)01265000
end;                                                                    01266000
begin                                                                   01267000
nnplus := local_node@.nnstart - 1;                                      01268000
(*               print the heading                                   *) 01269000
outline := '********************************************************'|| 01270000
           '*************';                                             01271000
%page                                                                   01272000
writeln(netfile,'/',outline,'/');                                       01273000
writeln(netfile,'/*  ',local_node@.soft:4,                              01274000
                ' 1.3.6/2.1.5 INITIALIZATION STATEMENTS FOR NODE '      01275000
                ,local_node@.name:8,'     */');                         01276000
writeln(netfile,'/*':-69,'*/');                                         01277000
if nnplus > 0 then                                                      01278000
   writeln(netfile,'/*  Node numbers starting with number '             01279000
                   ,local_node@.nnstart:-4,'*/':29) else                01280000
   writeln(netfile,'/*  No local range preserved for node numbers':-69  01281000
                  ,'*/');                                               01282000
writeln(netfile,'/*  PENDing nodes starting at number: '                01283000
                   ,pendstart:-4,'*/':29);                              01284000
writeln(netfile,'/*  Maximum assigned node number:     '                01285000
                   ,maxnum + nnplus:-4,'*/':29);                        01286000
writeln(netfile,'/*':-69,'*/');                                         01287000
writeln(netfile,'/*  Nodes file update level:    EARN   - '             01288000
                ,vers_id:-8,'                    */');                  01289000
writeln(netfile,'/*                              BITNET - '             01290000
                ,links_id:-8,'                    */');                 01291000
writeln(netfile,'/*':-69,'*/');                                         01292000
writeln(netfile,'/*  Generation date:  ',date,'   ',time,               01293000
                '                            */');                      01294000
writeln(netfile,'/*':-69,'*/');                                         01295000
writeln(netfile,'/*  ',info:-64,' */');                                 01296000
writeln(netfile,'/*':-69,'*/');                                         01297000
writeln(netfile,'/',outline,'/');                                       01298000
writeln(netfile,'/*      ',                                             01299000
'             JES2 LOCAL NODE SPECIFICATION                   */');     01300000
writeln(netfile,'/',outline,'/');                                       01301000
writeln(netfile,'/*':-24,'Comment           Previous syntax */':47);    01302000
writeln(netfile,'/*NJEDEF   NODENUM=',maxnum + nnplus:-4,',',           01303000
                'Max. Number of Nodes     &NUMNODE */':47);             01304000
writeln(netfile,'/*         RESTMAX=3999,',                             01305000
                'Max. Resistance Toler.   &MAXREST */':47);             01306000
nodnum := local_node@.number + nnplus;                                  01307000
if nodnum < 10 then ix := 1                                             01308000
   else if nodnum < 100 then ix := 2                                    01309000
   else if nodnum < 1000 then ix := 3                                   01310000
   else ix := 4;                                                        01311000
iy := 71 - 20 - ix;                                                     01312000
writeln(netfile,'/*         OWNNODE=',nodnum:ix,',',                    01313000
                'This Nodes Number        &OWNNODE */':iy);             01314000
ix   := 0;                        (*  how many links do we have ?  *)   01315000
link := local_node@.linklist;                                           01316000
repeat                                                                  01317000
   ix   := ix + 1;                                                      01318000
   link := link@.next;                                                  01319000
until link = nil;                                                       01320000
writeln(netfile,'/*         LINENUM=',ix:-4,                            01321000
                'Num. of Lines for NJE    &NETLNES */':48);             01322000
ix := length(trim(str(local_node@.name)));                              01323000
iy := 18 - ix;                                                          01324000
write(netfile,'/*N');                                                   01325000
   printnum(nodnum);                                                    01326000
   write(netfile,' NAME=',local_node@.name:ix);                         01327000
   write(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA');           01328000
   writeln(netfile,'*/':iy);                                            01329000
%page                                                                   01330000
writeln(netfile,'/',outline,'/');                                       01331000
writeln(netfile,'/*      ',                                             01332000
'               JES2 LINK SPECIFICATIONS                      */');     01333000
writeln(netfile,'/',outline,'/');                                       01334000
                                                 (*  first the links  *)01335000
local_node@.actlink := local_node@.linklist;                            01336000
repeat                                                                  01337000
  runptr := local_node@.actlink@.ptolink;                               01338000
  write(netfile,'/*':-15,runptr@.country:-3);                           01339000
     write(netfile,' ',runptr@.institute:-32);                          01340000
     write(netfile,' -con.-> ',local_node@.name:-8);                    01341000
     writeln(netfile,'*/':3);                                           01342000
  ix := length(trim(str(runptr@.name)));                                01343000
  iy := 18 - ix;                                                        01344000
  write(netfile,'/*N');                                                 01345000
     nodnum := runptr@.number + nnplus;                                 01346000
     printnum(nodnum);                                                  01347000
     write(netfile,' NAME=',runptr@.name:ix);                           01348000
     write(netfile,',NONETATH,NODEVATH,NOJOBATH,NOSYSATH,SNA');         01349000
     writeln(netfile,'*/':iy);                                          01350000
  write(netfile,'/*CONNECT NODEA=');                                    01351000
     printnum(nodnum);                                                  01352000
     write(netfile,',MEMBA=1,NODEB=');                                  01353000
     nodnum := runptr@.via@.number + nnplus;                            01354000
     printnum(nodnum);                                                  01355000
     write(netfile,',MEMBB=1,REST=2');                                  01356000
     writeln(netfile,'*/':17);                                          01357000
  local_node@.actlink := local_node@.actlink@.next;                     01358000
until local_node@.actlink = nil;                                        01359000
%page                                                                   01360000
                     (*  now the routings: first the description part *)01361000
writeln(netfile,'/',outline,'/');                                       01362000
writeln(netfile,'/*':-23,'JES2 ROUTE SPECIFICATIONS','*/':23);          01363000
writeln(netfile,'/',outline,'/');                                       01364000
writeln(netfile,'/*    Interm.Nodes',' ':42,'Vialink  */');             01365000
writeln(netfile,'/*Number',                                             01366000
'    |  Country                                      |        */');     01367000
writeln(netfile,'/*|   No',                                             01368000
'de  |  |   Institute/Location                       Vianode  */');     01369000
writeln(netfile,'/*|---|-',                                             01370000
'----|--|---|----------------------------------------|--------*/');     01371000
if jes2_sort = 1 then begin                    (* sort alphabetically *)01372000
 runptr := startnode@.next;                                             01373000
 repeat               (* routing statements for the version entries *)  01374000
    if ((substr(str(runptr@.name),1,4) = 'VERS') |                      01375000
        (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;     01376000
    runptr := runptr@.next;                                             01377000
 until runptr = nil;                                                    01378000
 runptr := startnode@.next;                                             01379000
 repeat                    (* routing statements for national nodes *)  01380000
    if (runptr@.country = local_node@.country) and                      01381000
       (runptr@.distance > 10) then                                     01382000
    if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                     01383000
        (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;    01384000
    runptr := runptr@.next;                                             01385000
 until runptr = nil;                                                    01386000
 runptr := startnode@.next;                                             01387000
 repeat           (* routing statements for the international nodes *)  01388000
    if (runptr@.country ^= local_node@.country) and                     01389000
       (runptr@.distance > 10) then                                     01390000
    if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                     01391000
        (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;    01392000
    runptr := runptr@.next;                                             01393000
 until runptr = nil;                                                    01394000
end else begin                                (* sort by node numbers *)01395000
   runptr := startnode@.numnex;                                         01396000
   repeat                                                               01397000
      if (runptr@.distance > 10) then printroute;                       01398000
      runptr := runptr@.numnex;                                         01399000
   until runptr = nil;                                                  01400000
end;                                                                    01401000
end;                                               (* of jes2_v2_init *)01402000
%page                                                                   01403000
(**********************************************************************)01404000
(*                                                                    *)01405000
(*   This procedure generates the routing tables for JNET             *)01406000
(*                                                                    *)01407000
(**********************************************************************)01408000
procedure jnetinit;                                                     01409000
var runptr : npointer;                                                  01410000
procedure printroute;            (* proc to print a routing statement *)01411000
begin                                                                   01412000
  writeln(netfile,'DEFINE ',runptr@.name:8,                             01413000
                  ' /ROUTE=',runptr@.vialink@.name:8,                   01414000
                  ' !(',round(runptr@.distance/10-1):2,                 01415000
                  ') ',runptr@.country:-2,                              01416000
                  ',',runptr@.institute:-30)                            01417000
end;                                                                    01418000
begin                                                                   01419000
(*               print the heading                                   *) 01420000
writeln(netfile,'!**',                                                  01421000
'******************************************************************');  01422000
writeln(netfile,'!   ',local_node@.soft:4,                              01423000
                ' ROUTING STATEMENTS FOR NODE '                         01424000
                ,local_node@.name:8,'                       *');        01425000
writeln(netfile,'! ':-68,'*');                                          01426000
writeln(netfile,'!   Nodes file update level:    EARN   - '             01427000
                ,vers_id:-8,'                   *');                    01428000
writeln(netfile,'!                               BITNET - '             01429000
                ,links_id:-8,'                   *');                   01430000
writeln(netfile,'! ':-68,'*');                                          01431000
writeln(netfile,'!   Generation date:  ',date,'   ',time,               01432000
                '                           *');                        01433000
writeln(netfile,'! ':-68,'*');                                          01434000
writeln(netfile,'!   ',info:-64,'*');                                   01435000
writeln(netfile,'! ':-68,'*');                                          01436000
writeln(netfile,'!**',                                                  01437000
'******************************************************************');  01438000
writeln(netfile,'!  ',                                                  01439000
'                 JNET LOCAL NODE SPECIFICATION                   *');  01440000
writeln(netfile,'!**',                                                  01441000
'******************************************************************');  01442000
writeln(netfile,'!  DEFINE ',local_node@.name:8,' /HOST',               01443000
                ' /DAEMON=DAE /TIMEZONE=N');                            01444000
writeln(netfile,'!**',                                                  01445000
'******************************************************************');  01446000
writeln(netfile,'!  ',                                                  01447000
'                   JNET LINK SPECIFICATIONS                      *');  01448000
writeln(netfile,'!**',                                                  01449000
'******************************************************************');  01450000
              (*        first the links !                             *)01451000
local_node@.actlink := local_node@.linklist;                            01452000
repeat                                                                  01453000
  runptr := local_node@.actlink@.ptolink;                               01454000
  writeln(netfile,'!  DEFINE ',runptr@.name:8,                          01455000
         ' /LINK /DAEMON=BISS /LINE=BTA0:');                            01456000
local_node@.actlink := local_node@.actlink@.next;                       01457000
until local_node@.actlink = nil;                                        01458000
%page                                                                   01459000
(*      now the routings: first the national nodes!                   *)01460000
writeln(netfile,'!**',                                                  01461000
'******************************************************************');  01462000
writeln(netfile,'!  ',                                                  01463000
'                   JNET ROUTE SPECIFICATIONS                     *');  01464000
writeln(netfile,'!**',                                                  01465000
'******************************************************************');  01466000
writeln(netfile,'!  ',                                                  01467000
'                             Interm.                             *');  01468000
writeln(netfile,'!  ',                                                  01469000
'                               (|) Country                       *');  01470000
writeln(netfile,'!  ',                                                  01471000
'    Node         Vianode      Nodes|  Institute/Location         *');  01472000
writeln(netfile,'!--',                                                  01473000
'----|---------------|-----------|--|--|--------------------------*');  01474000
runptr := startnode@.next;                                              01475000
repeat                  (* routing statements for the version entries *)01476000
   if ((substr(str(runptr@.name),1,4) = 'VERS') |                       01477000
       (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;      01478000
   runptr := runptr@.next;                                              01479000
until runptr = nil;                                                     01480000
runptr := startnode@.next;                                              01481000
repeat                       (* routing statements for national nodes *)01482000
   if (runptr@.country = local_node@.country) and                       01483000
      (runptr@.distance > 10) then                                      01484000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01485000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01486000
   runptr := runptr@.next;                                              01487000
until runptr = nil;                                                     01488000
runptr := startnode@.next;                                              01489000
repeat              (* routing statements for the international nodes *)01490000
   if (runptr@.country ^= local_node@.country) and                      01491000
      (runptr@.distance > 10) then                                      01492000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01493000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01494000
   runptr := runptr@.next;                                              01495000
until runptr = nil;                                                     01496000
end; (********************** of jnetinit ****************************)  01497000
%page                                                                   01498000
(**********************************************************************)01499000
(*                                                                    *)01500000
(*   This procedure generates the routing tables for NOS operating    *)01501000
(*   systems (TIELINE and INTERCOM)                                   *)01502000
(*                                                                    *)01503000
(**********************************************************************)01504000
procedure tielinit;                                                     01505000
var runptr : npointer;                                                  01506000
    rhdc   : string(5);                                                 01507000
procedure printroute;            (* proc to print a routing statement *)01508000
begin                                                                   01509000
  writeln(netfile,'  ',runptr@.name:8,' DO BEGIN,TORSCS,',              01510000
                  'MAILLIB,FILE,SITE,USER,FMT,',rhdc,'  ',              01511000
                   runptr@.institute:-18);                              01512000
end;                                                                    01513000
begin                                                                   01514000
               (* there is a small difference in the routing tables  *) 01515000
if local_node@.soft = 'TIEL' then rhdc := 'RH=1.';                      01516000
if local_node@.soft = 'INTE' then rhdc := 'DC.';                        01517000
(*               print the heading                                   *) 01518000
writeln(netfile,'***',                                                  01519000
'******************************************************************');  01520000
writeln(netfile,'*   NOS-',local_node@.soft:4,                          01521000
                ' ROUTING STATEMENTS FOR NODE '                         01522000
                ,local_node@.name:8,'                   *');            01523000
writeln(netfile,'*':-68,'*');                                           01524000
writeln(netfile,'*   Nodes file update level:    EARN   - '             01525000
                ,vers_id:-8,'                   *');                    01526000
writeln(netfile,'*                               BITNET - '             01527000
                ,links_id:-8,'                   *');                   01528000
writeln(netfile,'*':-68,'*');                                           01529000
writeln(netfile,'*   Generation date:  ',date,'   ',time,               01530000
                '                           *');                        01531000
writeln(netfile,'*':-68,'*');                                           01532000
writeln(netfile,'*   ',info:-64,'*');                                   01533000
writeln(netfile,'*':-68,'*');                                           01534000
writeln(netfile,'***',                                                  01535000
'******************************************************************');  01536000
writeln(netfile,'*  ',                                                  01537000
'                 NOS  LOCAL NODE SPECIFICATION                   *');  01538000
writeln(netfile,'***',                                                  01539000
'******************************************************************');  01540000
writeln(netfile,'* ',local_node@.name:8);                               01541000
writeln(netfile,'* ARPA   DO BEGIN,TOARPA,MAILLIB,FILE,');              01542000
writeln(netfile,'* ARPA   DO $SITE$,');                                 01543000
writeln(netfile,'* ARPA   DO $USER$,');                                 01544000
writeln(netfile,'* ARPA   DO FMT,',rhdc);                               01545000
writeln(netfile,'* CSNET  DO BEGIN,TOCSNET,MAILLIB,FILE,');             01546000
writeln(netfile,'* CSNET  DO $SITE$,');                                 01547000
writeln(netfile,'* CSNET  DO $USER$,');                                 01548000
writeln(netfile,'* CSNET  DO FMT,',rhdc);                               01549000
writeln(netfile,'* ',local_node@.name:8,                                01550000
        ' DO BEGIN,LOCAL,MAILLIB,FILE,SITE,USER,FROM,FAT.');            01551000
writeln(netfile,'* LOCAL   ',                                           01552000
        ' DO BEGIN,LOCAL,MAILLIB,FILE,SITE,USER,FROM,FAT.');            01553000
writeln(netfile,'***',                                                  01554000
'******************************************************************');  01555000
writeln(netfile,'*  ',                                                  01556000
'                   NOS  ROUTE SPECIFICATIONS                     *');  01557000
writeln(netfile,'***',                                                  01558000
'******************************************************************');  01559000
runptr := startnode@.next;                                              01560000
repeat                  (* routing statements for the version entries *)01561000
   if ((substr(str(runptr@.name),1,4) = 'VERS') |                       01562000
       (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;      01563000
   runptr := runptr@.next;                                              01564000
until runptr = nil;                                                     01565000
runptr := startnode@.next;                                              01566000
repeat                       (* routing statements for national nodes *)01567000
   if (runptr@.country = local_node@.country) and                       01568000
      (runptr@.distance >= 10) then                                     01569000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01570000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01571000
   runptr := runptr@.next;                                              01572000
until runptr = nil;                                                     01573000
runptr := startnode@.next;                                              01574000
repeat              (* routing statements for the international nodes *)01575000
   if (runptr@.country ^= local_node@.country) and                      01576000
      (runptr@.distance > 10) then                                      01577000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01578000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01579000
   runptr := runptr@.next;                                              01580000
until runptr = nil;                                                     01581000
end; (********************** of tielinit ****************************)  01582000
%page                                                                   01583000
(**********************************************************************)01584000
(*                                                                    *)01585000
(*   This procedure generates the routing tables for UREP (UNIX)      *)01586000
(*                                                                    *)01587000
(**********************************************************************)01588000
procedure urepinit;                                                     01589000
var runptr : npointer; insti : string(40);                              01590000
procedure printroute;            (* proc to print a routing statement *)01591000
begin                                                                   01592000
  insti := '';                                                          01593000
  insti := runptr@.institute;                                           01594000
  while index(insti,' ') > 0 do                                         01595000
        insti(.index(insti,' ').) := '_';                               01596000
  writeln(netfile,runptr@.name:8,'  ',                                  01597000
                  runptr@.vialink@.name,'  ',insti);                    01598000
end;                                                                    01599000
begin                                                                   01600000
(*               print the heading                                   *) 01601000
writeln(netfile,'***',                                                  01602000
'******************************************************************');  01603000
writeln(netfile,'*   ',local_node@.soft:4,                              01604000
                ' ROUTING STATEMENTS FOR NODE '                         01605000
                ,local_node@.name:8,'                       *');        01606000
writeln(netfile,'*':-68,'*');                                           01607000
writeln(netfile,'*   Nodes file update level:    EARN   - '             01608000
                ,vers_id:-8,'                   *');                    01609000
writeln(netfile,'*                               BITNET - '             01610000
                ,links_id:-8,'                   *');                   01611000
writeln(netfile,'*':-68,'*');                                           01612000
writeln(netfile,'*   Generation date:  ',date,'   ',time,               01613000
                '                           *');                        01614000
writeln(netfile,'*':-68,'*');                                           01615000
writeln(netfile,'*   ',info:-64,'*');                                   01616000
writeln(netfile,'*':-68,'*');                                           01617000
writeln(netfile,'***',                                                  01618000
'******************************************************************');  01619000
writeln(netfile,'*  ',                                                  01620000
'                 UREP LOCAL NODE SPECIFICATION                   *');  01621000
writeln(netfile,'***',                                                  01622000
'******************************************************************');  01623000
writeln(netfile,'* ',local_node@.name:8);                               01624000
writeln(netfile,'***',                                                  01625000
'******************************************************************');  01626000
writeln(netfile,'*  ',                                                  01627000
'                   UREP LINK SPECIFICATIONS                      *');  01628000
writeln(netfile,'***',                                                  01629000
'******************************************************************');  01630000
local_node@.actlink := local_node@.linklist;                            01631000
repeat                                                                  01632000
  runptr := local_node@.actlink@.ptolink;                               01633000
  writeln(netfile,'* ',runptr@.name:8);                                 01634000
  local_node@.actlink := local_node@.actlink@.next;                     01635000
until local_node@.actlink = nil;                                        01636000
writeln(netfile,'***',                                                  01637000
'******************************************************************');  01638000
writeln(netfile,'*  ',                                                  01639000
'                   UREP ROUTE SPECIFICATIONS                     *');  01640000
writeln(netfile,'***',                                                  01641000
'******************************************************************');  01642000
runptr := startnode@.next;                                              01643000
repeat                  (* routing statements for the version entries *)01644000
   if ((substr(str(runptr@.name),1,4) = 'VERS') |                       01645000
       (substr(str(runptr@.name),1,5) = 'LINKS')) then printroute;      01646000
   runptr := runptr@.next;                                              01647000
until runptr = nil;                                                     01648000
runptr := startnode@.next;                                              01649000
repeat                       (* routing statements for national nodes *)01650000
   if (runptr@.country = local_node@.country) and                       01651000
      (runptr@.distance > 10) then                                      01652000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01653000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01654000
   runptr := runptr@.next;                                              01655000
until runptr = nil;                                                     01656000
runptr := startnode@.next;                                              01657000
repeat              (* routing statements for the international nodes *)01658000
   if (runptr@.country ^= local_node@.country) and                      01659000
      (runptr@.distance > 10) then                                      01660000
   if ((substr(str(runptr@.name),1,4) ^= 'VERS') &                      01661000
       (substr(str(runptr@.name),1,5) ^= 'LINKS')) then printroute;     01662000
   runptr := runptr@.next;                                              01663000
until runptr = nil;                                                     01664000
end; (********************** of urepinit ****************************)  01665000
%page                                                                   01666000
procedure earnplot;                                                     01667000
var                                                                     01668000
     hoehe         : integer;                                           01669000
     breite        : integer;                                           01670000
     brt           : integer;                                           01671000
     hoh           : integer;                                           01672000
     ebene         : array(.1..100.) of integer;                        01673000
     haflin        : string(40);                                        01674000
     locat         : string(40);                                        01675000
     nn            : integer;                                           01676000
     mm            : integer;                                           01677000
     ll            : integer;                                           01678000
     kk            : integer;                                           01679000
     maxmem        : integer;                                           01680000
     nummer        : integer;                                           01681000
     size          : real;                                              01682000
     tokloc        : array(.1..12.) of string(20);                      01683000
     xko           : real;                                              01684000
     yko           : real;                                              01685000
     xkoc          : real;                                              01686000
     ykoc          : real;                                              01687000
     ymax          : real;                                              01688000
     laufptr       : npointer;                                          01689000
procedure verteile;                                                     01690000
var lin : integer;                                                      01691000
procedure verteilenbr( node : npointer;  namen : alfa;                  01692000
                                   lastname : alfa);                    01693000
var runptr : lpointer;                                                  01694000
label        nextchk;                                                   01695000
begin                                                                   01696000
runptr := node@.linklist;                                               01697000
repeat                                                                  01698000
  nextchk:                                                              01699000
  if (runptr@.name = lastname) or                                       01700000
     (runptr@.ptolink@.via ^= node) then begin                          01701000
        runptr := runptr@.next;                                         01702000
        if runptr = nil then return;                                    01703000
        goto nextchk;                                                   01704000
     end;                                                               01705000
  if runptr@.ptolink@.linklist@.name = 'A' then                         01706000
     begin                                                              01707000
       writeln(plotfile,'* Warning: no node entry found for ',          01708000
                       runptr@.ptolink@.name);                          01709000
       return                                                           01710000
     end;                                                               01711000
  runptr@.ptolink@.connect := node@.member;                             01712000
  runptr@.ptolink@.level   := node@.level + 1;                          01713000
  ebene(.runptr@.ptolink@.level.) := ebene(.runptr@.ptolink@.level.)+1; 01714000
  runptr@.ptolink@.member := ebene(.runptr@.ptolink@.level.);           01715000
  verteilenbr(runptr@.ptolink,namen,node@.name);                        01716000
  runptr := runptr@.next;                                               01717000
until runptr = nil;                                                     01718000
end;                                                                    01719000
begin                                                                   01720000
laufptr := local_node@.linklist@.ptolink;                               01721000
pred_link := local_node@.linklist;                                      01722000
local_node@.connect := 0;                                               01723000
local_node@.level   := 1;                                               01724000
local_node@.member  := 1;                                               01725000
ebene(.1.)          := 1;                                               01726000
repeat                                                                  01727000
  if laufptr@.linklist@.name = 'A' then                                 01728000
     begin                                                              01729000
       writeln(plotfile,'* Warning: no node entry found for ',          01730000
                      laufptr@.name);                                   01731000
       return                                                           01732000
     end else                                                           01733000
     begin                                                              01734000
       laufptr@.level := 2;                                             01735000
       ebene(.laufptr@.level.) := ebene(.laufptr@.level.) + 1;          01736000
       laufptr@.member := ebene(.laufptr@.level.);                      01737000
       laufptr@.connect := 1;                                           01738000
     end;                                                               01739000
  verteilenbr(laufptr,laufptr@.name,local_node@.name);                  01740000
  if pred_link@.next = nil then leave;                                  01741000
  laufptr := pred_link@.next@.ptolink;                                  01742000
  pred_link := pred_link@.next;                                         01743000
until pred_link = nil;                                                  01744000
end;                                                                    01745000
begin             (* of EARNPLOT  *)                                    01746000
maxmem := 0;                                                            01747000
for nummer := 1 to 100 do                                               01748000
ebene(.nummer.) := 0;                                                   01749000
verteile;                                                               01750000
laufptr := startnode@.next;                                             01751000
rewrite(plotfile);                                                      01752000
  writeln(ttyout,'/* This program produces GNOM plot statements to ');  01753000
  writeln(ttyout,'/* plot the complete network with its connections.'); 01754000
  writeln(ttyout,'/* If you do not have GNOM it will be easy to    ');  01755000
  writeln(ttyout,'/* read in this file and create your own plot file.');01756000
  writeln(ttyout,'/* There are only two commands used:             ');  01757000
  writeln(ttyout,'/* * LINE fromXcoord#fromYcoord,toXcoord#toYcoord');  01758000
  writeln(ttyout,'/* * TEXT Xcoord#Ycoord;''Text'';size#0;linestyle;',  01759000
                 '''CENTER''');                                         01760000
  writeln(ttyout,'/* The coordinates refer to the center of Text   ');  01761000
  writeln(ttyout,'                                                 ');  01762000
  writeln(ttyout,'Enter HIGHT,WIDTH,HIGHTBOX,WIDTHBOX/2 sizes: (INT)'); 01763000
  writeln(ttyout,'(a good choice is: 50 11 7 5 for 2000 X 850 mm)  ');  01764000
  readln(ttyin,hoehe,breite,hoh,brt);                                   01765000
  if ^dialog then writeln(ttyout,'=Lst=> ',hoehe,breite,hoh,brt);       01766000
ymax   := 0;                                                            01767000
maxmem := 0;                                                            01768000
for nummer := 1 to 100 do                                               01769000
maxmem := max(maxmem,ebene(.nummer.));                                  01770000
repeat                                                                  01771000
  yko := -hoehe * laufptr@.level;                                       01772000
  xko := breite * (laufptr@.member-0.5)*maxmem/ebene(.laufptr@.level.); 01773000
  if local_node = laufptr then                                          01774000
  writeln(plotfile,'* TEXT ',xko:6:2,'#',yko+hoehe*2:6:2,';',           01775000
    '''EARN - BITNET Netzwerk'';9#0;13;''CENTER''');                    01776000
  writeln(plotfile,'* LINE ',xko-brt:5:1,'#',yko:5:1,',',               01777000
          xko+brt:5:1,'#',yko:5:1);                                     01778000
  writeln(plotfile,'* LINE ',                                           01779000
          xko+brt:5:1,'#',yko:5:1,',',xko+brt:5:1,'#',yko+hoh:5:1);     01780000
  writeln(plotfile,'* LINE ',xko+brt:5:1,'#',yko+hoh:5:1,',',           01781000
          xko-brt:5:1,'#',yko+hoh:5:1);                                 01782000
  writeln(plotfile,'* LINE ',                                           01783000
          xko-brt:5:1,'#',yko+hoh:5:1,',',xko-brt:5:1,'#',yko:5:1);     01784000
  writeln(plotfile,'* TEXT ',xko:6:2,'#',yko+hoh*0.66:6:2,';''',        01785000
    trim(str(laufptr@.name)),''';',2*brt/10:5:2,'#0;13;''CENTER''');    01786000
  ymax := max(abs(yko),ymax);                                           01787000
  for nn := 1 to 12 do tokloc(.nn.) := '';                              01788000
  ix := 1;                                                              01789000
  nn := 0;                                                              01790000
  ll := length(laufptr@.institute);                                     01791000
  haflin := '';                                                         01792000
  repeat                                                                01793000
  token(ix,laufptr@.institute,result);                                  01794000
  haflin := trim(str(result));                                          01795000
  if ( ( ((haflin^='')  and (haflin^='.'))    and                       01796000
         ((haflin^=',') and (haflin^='''')) ) and                       01797000
       ( ((haflin^='-') and (haflin^='/'))    and                       01798000
         ((haflin^='(') and (haflin^=')')) )) then                      01799000
    begin                                                               01800000
      nn := nn + 1;                                                     01801000
      tokloc(.nn.) := haflin;                                           01802000
     end;                                                               01803000
  until (ix >= ll) or (nn >= 12);                                       01804000
  ix := 40;                                                             01805000
  haflin := '';                                                         01806000
  for mm := 1 to nn do                                                  01807000
   begin                                                                01808000
    if ix > abs(length(haflin||' '||tokloc(.mm.))-15) then              01809000
       begin                                                            01810000
         if haflin = '' then haflin := tokloc(.mm.) else                01811000
         haflin := haflin||' '||tokloc(.mm.);                           01812000
         ix := abs(length(haflin)-15);                                  01813000
       end else                                                         01814000
         leave;                                                         01815000
   end;                                                                 01816000
  if haflin = '' then haflin := '.';                                    01817000
  size := 2*brt*0.9/40.0;                                               01818000
   writeln(plotfile,'* TEXT ',xko:6:2,'#',yko+hoh*0.33:6:2,';''',       01819000
     haflin,''';',size:4:2,'#0;13;''CENTER''');                         01820000
  kk := ix + 15;                                                        01821000
  ix := 40;                                                             01822000
  ll := mm;                                                             01823000
  haflin := '';                                                         01824000
  for mm := ll to nn do                                                 01825000
   begin                                                                01826000
    if ix > abs(length(haflin||' '||tokloc(.mm.))-kk) then              01827000
       begin                                                            01828000
         if haflin = '' then haflin := tokloc(.mm.) else                01829000
         haflin := haflin||' '||tokloc(.mm.);                           01830000
         ix := abs(length(haflin)-kk);                                  01831000
       end else                                                         01832000
         leave;                                                         01833000
   end;                                                                 01834000
  if haflin = '' then haflin := '.';                                    01835000
  size := 2*brt*0.9/40.0;                                               01836000
   writeln(plotfile,'* TEXT ',xko:6:2,'#',yko+hoh*0.16:6:2,';''',       01837000
     haflin,''';',size:4:2,'#0;13;''CENTER''');                         01838000
  ykoc := laufptr@.level - 1;                                           01839000
  if ykoc > 0 then                                                      01840000
  begin                                                                 01841000
  yko  := yko + hoh;                                                    01842000
  xkoc := breite * (laufptr@.connect-0.5)*maxmem /                      01843000
                                            ebene(.laufptr@.level-1.);  01844000
  ykoc := -hoehe * ykoc;                                                01845000
  writeln(plotfile,'* LINE ',xkoc:6:2,'#',ykoc:6:2,',',                 01846000
                               xko:6:2,'#',yko:6:2);                    01847000
  end;                                                                  01848000
  laufptr := laufptr@.next;                                             01849000
until laufptr = nil;                                                    01850000
writeln(plotfile,'* TEXT 0#',-ymax:6:2,';',                             01851000
    '''Stand: ',date,'  (MEYER@DEARN)'';1#0;13;''CENTER''');            01852000
end;                                                                    01853000
%page                                                                   01854000
(**********************************************************************)01855000
(*                                                                    *)01856000
(*   This procedure print an INFO file                                *)01857000
(*                                                                    *)01858000
(**********************************************************************)01859000
procedure infoprint;                                                    01860000
var runptr : npointer;    n_between : real;                             01861000
procedure iprintnum( num : integer);                                    01862000
begin                                                                   01863000
  case num of                                                           01864000
       0..9: write(infofile,'000',num:1);                               01865000
     10..99: write(infofile,'00',num:2);                                01866000
   100..999: write(infofile,'0',num:3);                                 01867000
   otherwise write(infofile,num:4);                                     01868000
  end;                                                                  01869000
end;                                                  (* of iprintnum *)01870000
begin                                                                   01871000
numjes2 := 0;                                                           01872000
numjes3 := 0;                                                           01873000
numjnet := 0;                                                           01874000
numnje  := 0;                                                           01875000
numnos  := 0;                                                           01876000
numrscs := 0;                                                           01877000
numurep := 0;                                                           01878000
numnodes:= 0;                                                           01879000
(*               print the heading                                   *) 01880000
writeln(infofile,' List of nodes.');                                    01881000
writeln(infofile,' Generated for ',local_node@.name,' at ',date);       01882000
writeln(infofile,' Nodes file update level:    EARN   - ',vers_id:-8);  01883000
writeln(infofile,'                             BITNET - ',links_id:-8); 01884000
writestr(info,info:-64);                                                01885000
writeln(infofile,' ',info);                                             01886000
writeln(infofile,' ***********',                                        01887000
'******************************************************************');  01888000
if formopt2 = 2 then begin                                              01889000
  if formopt = 1 then                                                   01890000
     write(infofile,' Nodeid   Num.');                                  01891000
  if formopt = 2 then                                                   01892000
     write(infofile,' Num. Nodeid  ');                                  01893000
  writeln(infofile,' Country     Institute             ',               01894000
          '  Softw. System');                                           01895000
  write(infofile,'               ');                                    01896000
  writeln(infofile,'Connected to    (Num) via node      ',              01897000
                   '(dist. to local)');                                 01898000
  write(infofile,'               ');                                    01899000
  writeln(infofile,'Contact person (name, address and phone number)');  01900000
end else begin                                                          01901000
  writeln(ttyout,'=Inp=> Choose tag of node entries out of');           01902000
  writeln(ttyout,'          Institute name         :1');                01903000
  writeln(ttyout,'          EARN/BITNET contact    :2');                01904000
  writeln(ttyout,'          GMT offset             :3');                01905000
  writeln(ttyout,'          Networking software    :4');                01906000
  writeln(ttyout,'          Distance to local node :5');                01907000
  writeln(ttyout,'=Inp=> Enter tag number:');                           01908000
  readln(ttyin,tag_num);                                                01909000
  if ^dialog then writeln(ttyout,'=Lst=> ',tag_num);                    01910000
  case tag_num of                                                       01911000
     1: writeln(infofile,' Nodeid   Institute');                        01912000
     2: writeln(infofile,' Nodeid   EARN/BITNET contact');              01913000
     3: writeln(infofile,' Nodeid   GMT offset');                       01914000
     4: writeln(infofile,' Nodeid   Networking software');              01915000
     5: writeln(infofile,' Nodeid   Distance to local node');           01916000
     otherwise;                                                         01917000
  end;                                                                  01918000
end;                                                                    01919000
writeln(infofile,' -----------',                                        01920000
  '------------------------------------------------------------------');01921000
                    runptr := startnode@.next;    (* sort names      *) 01922000
if formopt = 2 then runptr := startnode@.numnex;  (* or numbers      *) 01923000
repeat                                                                  01924000
   if (runptr@.country = locountry) or (code = 3) then begin            01925000
      if formopt2 = 2 then begin                                        01926000
         numnodes             := numnodes + 1;                          01927000
         if runptr@.soft = 'JES2' then numjes2 := numjes2 + 1;          01928000
         if runptr@.soft = 'JES3' then numjes3 := numjes3 + 1;          01929000
         if runptr@.soft = 'JNET' then numjnet := numjnet + 1;          01930000
         if runptr@.soft = 'NJE ' then numnje  := numnje  + 1;          01931000
         if ((runptr@.soft = 'INTE') | (runptr@.soft = 'TIEL'))         01932000
                                  then numnos  := numnos  + 1;          01933000
         if runptr@.soft = 'RSCS' then numrscs := numrscs + 1;          01934000
         if runptr@.soft = 'UREP' then numurep := numurep + 1;          01935000
         write(infofile,' ');                                           01936000
         case formopt of                                                01937000
         1: begin                                                       01938000
              write(infofile,runptr@.name,' ');                         01939000
              iprintnum(runptr@.number);                                01940000
            end;                                                        01941000
         2: begin                                                       01942000
              iprintnum(runptr@.number);                                01943000
              write(infofile,' ',runptr@.name);                         01944000
            end;                                                        01945000
         otherwise;                                                     01946000
         end;                                                           01947000
         writeln(infofile,' ',runptr@.country:-3,' ',                   01948000
               runptr@.institute:-32,'(',runptr@.soft:-4,') ',          01949000
               runptr@.syst);                                           01950000
         n_between := runptr@.distance/10.0-1.0;                        01951000
         if n_between < 0.0 then n_between := 0.0;                      01952000
         writeln(infofile,'               ',                            01953000
                 'Con. to ',runptr@.via@.name,' ',                      01954000
                 runptr@.via@.number:4,' via ',                         01955000
                 runptr@.vialink@.name,'  (',                           01956000
                 round(n_between):2,' interm.nodes)');                  01957000
         writeln(infofile,'               ',                            01958000
                 'Cont ',runptr@.contact);                              01959000
         writeln(infofile);                                             01960000
      end else begin                                                    01961000
         case tag_num of                                                01962000
           1: writeln(infofile,' ',runptr@.name,'  ',runptr@.institute);01963000
           2: writeln(infofile,' ',runptr@.name,'  ',runptr@.contact);  01964000
           3: writeln(infofile,' ',runptr@.name,'  ',runptr@.gmtoff);   01965000
           4: writeln(infofile,' ',runptr@.name,'  ',runptr@.soft);     01966000
           5: begin                                                     01967000
                 n_between := runptr@.distance/10.0-1.0;                01968000
                 if n_between < 0.0 then n_between := 0.0;              01969000
                 writeln(infofile,' ',runptr@.name,'  ',                01970000
                                  round(n_between):2);                  01971000
              end;                                                      01972000
           otherwise;                                                   01973000
         end;                                                           01974000
      end;                                                              01975000
   end;                                                                 01976000
   if formopt = 1 then runptr := runptr@.next                           01977000
   else                runptr := runptr@.numnex;                        01978000
until runptr = nil;                                                     01979000
writeln(infofile,' ***********',                                        01980000
'******************************************************************');  01981000
if formopt2 = 2 then begin                                              01982000
   writeln(infofile);                                                   01983000
   writeln(infofile,' Total number of nodes: ',numnodes:-3);            01984000
   writeln(infofile,' Networking software:  RSCS: ',                    01985000
           numrscs:-3,'  JES2: ',numjes2:-3,'  JES3: ',numjes3:-3,      01986000
           '  JNET: ',numjnet:-3);                                      01987000
   writeln(infofile,'                  ...NJE...: ',                    01988000
           numnje:-3,'   NOS: ',numnos:-3,'  UREP: ',numurep:-3,        01989000
           ' other: '                                                   01990000
   ,numnodes-numrscs-numjes2-numjes3-numjnet-numnje-numnos-numurep:-3); 01991000
end;                                                                    01992000
end; (********************** of infoprint ***************************)  01993000
%page                                                                   01994000
(**********************************************************************)01995000
(*                                                                    *)01996000
(*   This procedure prints the XMAILER NAMES file                     *)01997000
(*                                                                    *)01998000
(**********************************************************************)01999000
procedure xmailerpr;                                                    02000000
var runptr : npointer;                                                  02001000
begin                                                                   02002000
  runptr := startnode@.next;                                            02003000
  repeat                                                                02004000
     if runptr@.xmailer ^= 'alias' then begin                           02005000
        writeln(xmailfil,runptr@.xmailer);                              02006000
     end;                                                               02007000
     runptr := runptr@.next                                             02008000
  until runptr = nil;                                                   02009000
end; (********************** of xmailerpr ***************************)  02010000
%page                                                                   02011000
(**********************************************************************)02012000
(*                                                                    *)02013000
(*   This procedure generates a pointer structure of the network      *)02014000
(*                                                                    *)02015000
(**********************************************************************)02016000
procedure gen_net;                                                      02017000
var alias_flag : boolean;                                               02018000
    run_num    : integer;                                               02019000
label           weiter;                (*                             *)02020000
label           alias;                 (*                             *)02021000
begin                                                                   02022000
datetime(date,time);                                                    02023000
new(node);   initial(node);            (* create a dummy for via and  *)02024000
node@.name   := '        ';            (* vialink                     *)02025000
dummyvia     := node;                                                   02026000
new(node);   initial(node);        (* first we generate a dummy node  *)02027000
node@.name     := 'A';                                                  02028000
node@.soft     := 'DUMY';                                               02029000
node@.softrel  := 'V1';                                                 02030000
node@.next     := nil;                                                  02031000
node@.number   := 0;                                                    02032000
node@.linklist := nil;                                                  02033000
node@.link_ok  := true;                                                 02034000
startnode    := node;                                                   02035000
pred_node    := node;                                                   02036000
numnodes:= 0;                                                           02037000
reset(nodesfil);                           (* now read the nodes file *)02038000
oldline := '';                                                          02039000
testkey := ':node.';                                                    02040000
alias_flag := false;                                                    02041000
while testkey = ':node.' do begin                                       02042000
  decode;                                                               02043000
  alias:                           (* if we have an 'alias' node !    *)02044000
                                   (* skip if it is not a real node ! *)02045000
  if (entry.enodenum = 'NONE') then goto weiter;                        02046000
  if (entry.evia = '') and (entry.eadjacents = '') then goto weiter;    02047000
  if (index(entry.enodename,'-') > 0) then                              02048000
     writeln(ttyout,'=Err=> WARNING: Invalid Nodename: '                02049000
                   ,entry.enodename);                                   02050000
                                   (* make a cheque                   *)02051000
  if ^(key = ':node.') then begin                                       02052000
     writeln(ttyout,'=Err=> Error in interpreting NODESFILE');          02053000
     return;                                                            02054000
  end;                                                                  02055000
  nodeid   := entry.enodename;                                          02056000
  if entry.enodenum = '' then begin          (* no node number ?      *)02057000
     nummer := oldnum;                       (* generate one !        *)02058000
     oldnum := oldnum - 1;                                              02059000
  end else begin                             (* or compute it from    *)02060000
     numstr := entry.enodenum;               (* the string            *)02061000
     numstr := trim(numstr);                                            02062000
     ix := 0;                                                           02063000
     nummer := 0;                                                       02064000
     repeat                                                             02065000
        ix := ix + 1;                                                   02066000
        nummer := 10*nummer +                                           02067000
                  (index('0123456789',substr(numstr,ix,1))-1);          02068000
     until ix = length(numstr);                                         02069000
                                             (* valid node number ?   *)02070000
     if (nummer <= 0) then begin                                        02071000
        writeln(ttyout,'=Err=> WARNING: Invalid Nodenumber '            02072000
                      ,nummer:-4,' found for node ',entry.enodename);   02073000
        writeln(ttyout,'       Nodenumber will be processed '           02074000
                     ||' like PENDing');                                02075000
        nummer := oldnum;                    (* generate node number  *)02076000
        oldnum := oldnum - 1;                                           02077000
     end;                                                               02078000
  end;                                                                  02079000
  maxnum := max(maxnum,nummer);                                         02080000
                                             (* search for the node   *)02081000
  search(startnode,nodeid,node,pred_node);                              02082000
  if node = nil then begin                   (* do we have an entry ? *)02083000
     new(node);                              (* No! --> create one    *)02084000
     initial(node);                                                     02085000
     numnodes:= numnodes + 1;                                           02086000
     if (numnodes mod 200) = 0 then writeln(ttyout,                     02087000
         '=Run=> ',numnodes:6,' nodes processed...');                   02088000
     node@.next      := pred_node@.next;                                02089000
     pred_node@.next := node;                                           02090000
     node@.name      := nodeid;                                         02091000
     new(link);                                                         02092000
     link@.name      := 'A';                                            02093000
     link@.next      := nil;                                            02094000
     link@.ptolink   := nil;                                            02095000
     link@.speed     := 0;                                              02096000
     node@.linklist  := link                                            02097000
  end;                                                                  02098000
  node@.number    := nummer;                                            02099000
  node@.nnstart   := entry.ennstart;                                    02100000
  node@.soft      := entry.esoftware;                                   02101000
  node@.softrel   := entry.esoftrel;                                    02102000
  node@.country   := entry.ecountry;                                    02103000
  node@.gmtoff    := entry.egmtoff;                                     02104000
  node@.linkign   := entry.elinkign;                                    02105000
  if length(entry.elocation) >= 40 then                                 02106000
     node@.institute := substr(entry.elocation,1,40)                    02107000
                                   else                                 02108000
     node@.institute := entry.elocation;                                02109000
  node@.syst      := entry.esyst;                                       02110000
  node@.contact   := entry.econtact;                                    02111000
  if alias_flag then                                                    02112000
     node@.xmailer := 'alias'                                           02113000
                else                                                    02114000
  if entry.ealianame = '' then                                          02115000
     node@.xmailer   := ':nick.'||trim(entry.enodename)||               02116000
                        ' :alias.'||trim(entry.enodename)||             02117000
                        ' :net.'||entry.enet||                          02118000
                        ' :mailer.'||entry.emailer||                    02119000
                        ' :netsoft.'||entry.emsoftw                     02120000
                          else                                          02121000
     node@.xmailer   := ':nick.'||trim(entry.enodename)||               02122000
                        ' :alias.'||entry.ealianame||                   02123000
                        ' :net.'||entry.enet||                          02124000
                        ' :mailer.'||entry.emailer||                    02125000
                        ' :netsoft.'||entry.emsoftw;                    02126000
  node@.link_ok   := true;                                              02127000
  orignode        := node;                                              02128000
  speedline       := entry.espeed;                                      02129000
  line            := entry.eadjacents;                                  02130000
(*MG*)  If (entry.evia <> '') & (Str(entry.evia) <> 'ROOT') Then Begin  02131000
(*MG*)     WriteStr(speedline,'9L ',entry.espeed);                      02132000
(*MG*)     WriteStr(line,entry.evia,' ',entry.eadjacents);              02133000
(*MG*)     entry.evia := ''                                             02134000
(*MG*)     end;                                                         02135000
  run_num := 1;                                                         02136000
  repeat                                                                02137000
                                        (*                            *)02138000
                                        (*                            *)02139000
     if line = 'ROOT' then goto weiter;        (* ROOT is a dummy     *)02140000
%page                                                                   02141000
(*        decode the string with the adjacent nodes                   *)02142000
     pos       := 1;                                                    02143000
     endstring := false;                                                02144000
     link      := node@.linklist;                                       02145000
     repeat                                                             02146000
        if pos > length(line) then leave;                               02147000
        token(pos,line,result);                                         02148000
        readstr(str(result),nodeid);                                    02149000
        if run_num = 1 then begin      (* which speed has the link ?  *)02150000
           posi      := 1;                                              02151000
           token(posi,speedline,result);                                02152000
           posi      := index(speedline,' ');                           02153000
           if posi > 0 then begin                                       02154000
              while (speedline(.posi.) = ' ') &                         02155000
                    (posi < length(speedline)) do posi := posi + 1;     02156000
              speedline := substr(speedline,posi,                       02157000
                                  length(speedline)-posi+1);            02158000
           end else speedline := '';                                    02159000
           ix := index('CZ9421',substr(str(result),1,1));               02160000
(*MG*)     if ix = 0 then ix := 70;                                     02161000
           if ix = 1 then ix := 1;                                      02162000
           if ix = 2 then ix := 10;                                     02163000
           if ix = 3 then ix := 70;                                     02164000
           if ix = 4 then ix := 140;                                    02165000
           if ix = 5 then ix := 280;                                    02166000
           if ix = 6 then ix := 560;                                    02167000
        end;                           (* of run_num = 1              *)02168000
        node := orignode;                                               02169000
                                       (* is the link defined ?       *)02170000
        linksearch(node@.linklist,nodeid,link,pred_link);               02171000
        if link = nil then link := node@.linklist;                      02172000
        if (link@.name^=nodeid) and (link@.name^='A') then begin        02173000
           new(link);                  (* if not create one           *)02174000
           if pred_link = nil then begin                                02175000
              link@.next      := node@.linklist;                        02176000
              node@.linklist  := link                                   02177000
           end else begin                                               02178000
              link@.next      := pred_link@.next;                       02179000
              pred_link@.next := link                                   02180000
           end;                                                         02181000
        end;                                                            02182000
        link@.name   := nodeid;                                         02183000
        link@.speed  := ix;                                             02184000
        link@.ptolink:= nil;                                            02185000
                                       (* is the node defined ?      *) 02186000
        search(startnode,nodeid,link@.ptolink,pred_node);               02187000
        if link@.ptolink = nil then begin                               02188000
           new(node);                                                   02189000
           initial(node);                                               02190000
           numnodes:= numnodes + 1;                                     02191000
           if (numnodes mod 200) = 0 then writeln(ttyout,               02192000
               '=Run=> ',numnodes:6,' nodes processed...');             02193000
           node@.next      := pred_node@.next;                          02194000
           pred_node@.next := node;                                     02195000
           link@.ptolink   := node;                                     02196000
           node@.name      := nodeid;                                   02197000
           new(linklink);                                               02198000
           linklink@.name  := 'A';                                      02199000
           linklink@.next  := nil;                                      02200000
           linklink@.ptolink:= nil;                                     02201000
           linklink@.speed  := 0;                                       02202000
           node@.linklist    := linklink                                02203000
        end;                                                            02204000
%page                                                                   02205000
(*         if the nodesfil works with the VIA tag, we must            *)02206000
(*         also generate an entry in the link list of the other node  *)02207000
        node := link@.ptolink;                                          02208000
        linksearch(node@.linklist,orignode@.name,                       02209000
                   linklink,pred_link);                                 02210000
        if linklink = nil then begin                                    02211000
           linklink := node@.linklist;                                  02212000
           if linklink@.name = 'A' then begin                           02213000
              linklink@.name    := orignode@.name;                      02214000
              linklink@.ptolink := orignode;                            02215000
           end else begin                                               02216000
              new(linklink);                                            02217000
              if pred_link = nil then begin                             02218000
                 linklink@.next := node@.linklist;                      02219000
                 node@.linklist := linklink                             02220000
              end else begin                                            02221000
                 linklink@.next    := pred_link@.next;                  02222000
                 pred_link@.next   := linklink                          02223000
              end;                                                      02224000
              linklink@.name    := orignode@.name;                      02225000
              linklink@.ptolink := orignode;                            02226000
              ix := max(linklink@.speed,link@.speed);                   02227000
              link@.speed       := ix;                                  02228000
              linklink@.speed   := ix;                                  02229000
           end;                                                         02230000
        end;                                                            02231000
        if nodeid = ' ' then endstring := true;                         02232000
     until endstring;                                                   02233000
     line := entry.evia;                                                02234000
     run_num := run_num + 1;                                            02235000
  until run_num > 2;                                                    02236000
(*                                                                    *)02237000
(*    do we have "alias" nodenames?                                   *)02238000
  if ((entry.ealianame ^= '') and                                       02239000
      (entry.ealianame ^= entry.enodename)) and                         02240000
      (entry.ealianum  ^= '')                                           02241000
  then begin                                                            02242000
     nodeid := entry.ealianame;                                         02243000
     entry.evia      := entry.enodename;                                02244000
     entry.eadjacents:= '';                                             02245000
     entry.enodename := entry.ealianame;                                02246000
     entry.ealianame := '';                                             02247000
     if entry.ealianum = 'PEND' then                                    02248000
     entry.enodenum  := '' else                                         02249000
     entry.enodenum  := entry.ealianum;                                 02250000
     alias_flag := true;                                                02251000
     goto alias;                                                        02252000
  end;                                                                  02253000
  weiter:                                                               02254000
  alias_flag := false;                                                  02255000
end;                                                                    02256000
writeln(ttyout,'=Run=> The nodes file contains ',numnodes:6,' nodes.'); 02257000
end;                                          (* of procedure gen_net *)02258000
%page                                                                   02259000
(**********************************************************************)02260000
(*                                                                    *)02261000
(*   Check the connection for all nodes                               *)02262000
(*                                                                    *)02263000
(**********************************************************************)02264000
procedure check_net;                                                    02265000
begin                                                                   02266000
links_ok := true;                                                       02267000
node := startnode;                                                      02268000
repeat                                                                  02269000
   if ^node@.link_ok then begin                                         02270000
      writeln(ttyout,'=Err=> Unconnected node: ',node@.name);           02271000
      links_ok := false;                                                02272000
   end;                                                                 02273000
   node := node@.next;                                                  02274000
until node = nil;                                                       02275000
if ^links_ok then goto terminate;                                       02276000
end;                                        (* of procedure check_net *)02277000
%page                                                                   02278000
(**********************************************************************)02279000
(*                                                                    *)02280000
(*   Generate node numbers not yet numbered (PENDing) nodes           *)02281000
(*                                                                    *)02282000
(**********************************************************************)02283000
procedure gen_nodnum;                                                   02284000
begin                                                                   02285000
pendstart := maxnum + 1;                                                02286000
node := startnode;                                                      02287000
repeat                                                                  02288000
   if node@.number < 0 then begin                                       02289000
      node@.number :=  pendstart - node@.number - 1;                    02290000
      maxnum := max(maxnum,node@.number);                               02291000
   end;                                                                 02292000
   node := node@.next;                                                  02293000
until node = nil;                                                       02294000
end;                                       (* of procedure gen_nodnum *)02295000
%page                                                                   02296000
(**********************************************************************)02297000
(*                                                                    *)02298000
(*   Set pointers for sorting by node numbers                         *)02299000
(*                                                                    *)02300000
(**********************************************************************)02301000
procedure sort_nodnum;                                                  02302000
var runptr : npointer;                                                  02303000
begin                                                                   02304000
startnode@.numnex := nil;                                               02305000
runptr := startnode@.next;                                              02306000
repeat                      (* for each node do ...                   *)02307000
  node := startnode;                                                    02308000
  repeat                                                                02309000
    if node@.number > runptr@.number then leave;                        02310000
    pred_node := node;                                                  02311000
    node      := node@.numnex;                                          02312000
  until node = nil;                                                     02313000
  runptr@.numnex := pred_node@.numnex;                                  02314000
  pred_node@.numnex := runptr;                                          02315000
  runptr         := runptr@.next;                                       02316000
until runptr = nil;                                                     02317000
end;                                      (* of procedure sort_nodnum *)02318000
%page                                                                   02319000
(**********************************************************************)02320000
(*                                                                    *)02321000
(*   Initialization of some variables                                 *)02322000
(*                                                                    *)02323000
(**********************************************************************)02324000
procedure initmain;                                                     02325000
begin                                                                   02326000
gen_rel  := '89/10/04';                                                 02327000
code     := 1;                                                          02328000
links_id := 'notfound';                                                 02329000
maxdist  := 0;                                                          02330000
maxname  := 'DUMMY';                                                    02331000
maxnum   := 0;                                                          02332000
nummer   := 0;                                                          02333000
numjes2  := 0;                                                          02334000
numjes3  := 0;                                                          02335000
numjnet  := 0;                                                          02336000
numnje   := 0;                                                          02337000
numnos   := 0;                                                          02338000
numrscs  := 0;                                                          02339000
numurep  := 0;                                                          02340000
numnodes := 0;                                                          02341000
oldnum   := -1;                                                         02342000
oldline  := '';                                                         02343000
result   := '';                                                         02344000
restyp   := 'NETINIT';                                                  02345000
resmod   := '';                                                         02346000
vers_id := 'notfound';                                                  02347000
plotreq  := false;                                                      02348000
vmcms    := true;                                                       02349000
newop    := true;                                                       02350000
if index(parms,'TSO') > 0 then begin                                    02351000
  vmcms := false;                                                       02352000
  if index(parms,'TSONEW') = 0 then newop := false;                     02353000
end;                                                                    02354000
dialog   := true;                                                       02355000
if (index(parms,'NODIALOG') > 0) then dialog := false;                  02356000
if dialog then begin                                                    02357000
  termin(ttyin);                                                        02358000
  termout(ttyout);                                                      02359000
end else if vmcms then begin                                            02360000
  cms('FILEDEF TTYOUT DISK GENROUTS RUNLIST (RECFM V)',ix);             02361000
  rewrite(ttyout);                                                      02362000
  cms('STATE GENROUTS DATA',ix);                                        02363000
  if ix^=0 then begin                                                   02364000
    writeln(ttyout,'=Err=> Input dataset GENROUTS DATA not found');     02365000
    goto terminate;                                                     02366000
  end;                                                                  02367000
  cms('FILEDEF TTYIN DISK GENROUTS DATA',ix);                           02368000
  reset(ttyin);                                                         02369000
end else if newop then begin                                            02370000
  tsocmd(1,'DEL GENROUTS.RUNLIST',ix);                                  02371000
  tsocmd(1,'ALLOC F(TTYOUT) DA(GENROUTS.RUNLIST) REUSE '                02372000
          ||'NEW SPACE(10,10) RELEASE TRACKS DSORG(PS) '                02373000
          ||'LRECL(136) RECFM(V B) BLKSIZE(4084) CATALOG',ix);          02374000
  rewrite(ttyout);                                                      02375000
  tsocmd(1,'ALLOC F(TTYIN) DA(GENROUTS.DATA) SHR REUSE',ix);            02376000
  if ix^=0 then begin                                                   02377000
    writeln(ttyout,'=Err=> Allocation error for GENROUTS.DATA');        02378000
    goto terminate;                                                     02379000
  end;                                                                  02380000
  reset(ttyin);                                                         02381000
  end;                                                                  02382000
end;                                         (* of procedure initmain *)02383000
%page                                                                   02384000
(**********************************************************************)02385000
(*                                                                    *)02386000
(*   Informations about the program                                   *)02387000
(*                                                                    *)02388000
(**********************************************************************)02389000
procedure infomain;                                                     02390000
begin                                                                   02391000
writeln(ttyout,'##################################################',    02392000
               '##########################');                           02393000
writeln(ttyout,'# This is GENROUTS.                               ',    02394000
               '        Release ',gen_rel:8,' #');                      02395000
writeln(ttyout,'#':-75,'#');                                            02396000
writeln(ttyout,'# The program generates the routing tables (init. ',    02397000
               'parameters) for the EARN #');                           02398000
writeln(ttyout,'# network.  RSCS, JES2, JES3, JNET, UREP and NOS (',    02399000
               'TIELINE, INTERCOM 5) are #');                           02400000
writeln(ttyout,'# supported. The necessary information is read fro',    02401000
               'm the NODES file.        #');                           02402000
writeln(ttyout,'#':-75,'#');                                            02403000
writeln(ttyout,'# Please report problems to                       ',    02404000
               '                         #');                           02405000
writeln(ttyout,'# Ulrich Giese, URC Nijmegen (NL),  <U001213@HNYKU',    02406000
               'N11.BITNET>              #');                           02407000
writeln(ttyout,'# ------------------------------------------------',    02408000
               '------------------------ #');                           02409000
writeln(ttyout,'# News with the last release:':-75,'#');                02410000
writeln(ttyout,'# - better handling for NETSERV                   ',    02411000
               '                         #');                           02412000
writeln(ttyout,'# - updated release level                         ',    02413000
               '                         #');                           02414000
writeln(ttyout,'##################################################',    02415000
               '##########################');                           02416000
writeln(ttyout,' ');                                                    02417000
end;                                         (* of procedure infomain *)02418000
%page                                                                   02419000
(**********************************************************************)02420000
(*                                                                    *)02421000
(*   Prompt for the input dataset                                     *)02422000
(*                                                                    *)02423000
(**********************************************************************)02424000
procedure input_pr;                                                     02425000
begin                                                                   02426000
if vmcms then                                                           02427000
     writeln(ttyout,'=Inp=> Enter fn ft <fm> of the NODES file ',       02428000
                    '(Default: BITEARN NODES *) :')                     02429000
else writeln(ttyout,'=Inp=> Enter data set name of the NODES file ',    02430000
                    '(Default: BITEARN.NODES) :');                      02431000
readln(ttyin,line);                                                     02432000
if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));               02433000
if vmcms then begin                                                     02434000
   ix := 1;                                                             02435000
   token(ix,line,result);                                               02436000
   token(ix,line,restyp);                                               02437000
   if result = '' then result := 'BITEARN';                             02438000
   if restyp = '' then restyp := 'NODES';                               02439000
   if (ix=(length(line)+1)) or (ix = 0) then                            02440000
      resmod := '*' else token(ix,line,resmod);                         02441000
   cms('STATE '||str(result)||str(restyp)||str(resmod),ix);             02442000
   if ix^=0 then begin                                                  02443000
     writeln(ttyout,'=Err=> Input dataset '||                           02444000
                     compress(str(result)||str(restyp)||str(resmod))    02445000
                  ||' not found');                                      02446000
     goto terminate;                                                    02447000
   end;                                                                 02448000
   cms('FILEDEF NODESFIL DISK '||str(result)||str(restyp)               02449000
               ||str(resmod),ix);                                       02450000
end else begin                                                          02451000
   if line = '' then line := 'BITEARN.NODES';                           02452000
   tsocmd(1,'ALLOC F(NODESFIL) DA('||trim(line)||') SHR REUSE',ix);     02453000
   if ix^=0 then begin                                                  02454000
      writeln(ttyout,'=Err=> Allocation error for DA: ',trim(line));    02455000
      return;                                                           02456000
   end;                                                                 02457000
end;                                                                    02458000
end;                                         (* of procedure input_pr *)02459000
%page                                                                   02460000
(**********************************************************************)02461000
(*                                                                    *)02462000
(*   Option choice                                                    *)02463000
(*                                                                    *)02464000
(**********************************************************************)02465000
procedure options;                                                      02466000
begin                                                                   02467000
  writeln(ttyout);                                                      02468000
  writeln(ttyout,'=Opt=> Valid options are ...');                       02469000
  writeln(ttyout,'=Opt=> 1: Generates a routing table for a specified ',02470000
                 'node');                                               02471000
  writeln(ttyout,'=Opt=> 2: Generates routing tables for all nodes ',   02472000
                 'of a country');                                       02473000
  writeln(ttyout,'=Opt=> 3: Generates an information file with all ',   02474000
                 'nodes');                                              02475000
  writeln(ttyout,'=Opt=> 4: Generates an information file with all ',   02476000
                 'nodes of a country');                                 02477000
  writeln(ttyout,'=Opt=> 5: Generates a plot file');                    02478000
  writeln(ttyout,'=Opt=> 6: Generates XMAILER NAMES file');             02479000
  writeln(ttyout,'=Opt=> 7: Executes a CMS command');                   02480000
  writeln(ttyout,'=Opt=> 0: Terminates GENROUTS');                      02481000
end;                                          (* of procedure options *)02482000
%page                                                                   02483000
(*hug******************************************************************)02484000
(*hug                                                                 *)02485000
(*hug* get nodename & netsoft & netsoftrelease & offset on one line   *)02486000
(*hug*                                                                *)02487000
(*hug******************************************************************)02488000
(*hug*) procedure get_node_name;                                        02489000
(*hug*) var hug      : alpha;                                           02490000
(*hug*) begin                                                           02491000
(*hug*)    readln (ttyin,line);                                         02492000
(*hug*)    hug_offset := 0;                                             02493000
(*hug*)    ix := 1;                                                     02494000
(*hug*)                                                                 02495000
(*hug*)    token (ix,line,hug);                                         02496000
(*hug*)    ndnamen  := substr(str(hug),1,8);                            02497000
(*hug*)                                                                 02498000
(*hug*)    token (ix,line,hug); convert_alpha (hug);                    02499000
(*hug*)    hug_soft := substr(str(hug),1,4);                            02500000
(*hug*)                                                                 02501000
(*hug*)    token (ix,line,hug); convert_alpha (hug);                    02502000
(*hug*)    hug_softrel := substr(str(hug),1,2);                         02503000
(*hug*)                                                                 02504000
(*hug*)    token (ix,line,hug);                                         02505000
(*hug*)    if hug(.1.) ^= ' ' then                                      02506000
(*hug*)       begin                                                     02507000
(*hug*)       readstr(str(hug),hug_offset); hug_offset := hug_offset+1  02508000
(*hug*)       end;                                                      02509000
(*hug*)                                                                 02510000
(*hug*)    end ; (*get_node_name*)                                      02511000
%page                                                                   02512000
(**********************************************************************)02513000
(*                                                                    *)02514000
(*   Code selection 1                                                 *)02515000
(*                                                                    *)02516000
(**********************************************************************)02517000
procedure code_1;                                                       02518000
var rc : integer;                                                       02519000
begin                                                                   02520000
   case code of                                                         02521000
     1:   begin                                                         02522000
            writeln(ttyout,'=Inp=> Specify nodeid:');                   02523000
(*hug*)     get_node_name;                                              02524000
            if ^dialog then writeln(ttyout,'=Lst=> ',ndnamen);          02525000
            convert(ndnamen);                                           02526000
            inforeq := false;                                           02527000
          end;                                                          02528000
     2:   begin                                                         02529000
            writeln(ttyout,'=Inp=> Specify country id:');               02530000
            readln(ttyin,locount);                                      02531000
            if ^dialog then writeln(ttyout,'=Lst=> ',locount);          02532000
            convert(locount);                                           02533000
            locountry := trim(str(locount));                            02534000
            inforeq := false;                                           02535000
          end;                                                          02536000
     3:   begin                                                         02537000
            inforeq := true;                                            02538000
          end;                                                          02539000
     4:   begin                                                         02540000
            writeln(ttyout,'=Inp=> Specify country id:');               02541000
            readln(ttyin,locount);                                      02542000
            if ^dialog then writeln(ttyout,'=Lst=> ',locount);          02543000
            convert(locount);                                           02544000
            locountry := trim(str(locount));                            02545000
            inforeq := true;                                            02546000
          end;                                                          02547000
     5:   begin                                                         02548000
            plotreq := true;                                            02549000
          end;                                                          02550000
     6:   begin                                                         02551000
            xmailerreq := true;                                         02552000
          end;                                                          02553000
     7:   begin                                                         02554000
            if vmcms then                                               02555000
               begin                                                    02556000
               writeln (ttyout,'=Inp=> Enter a CMS command:');          02557000
               readln (ttyin,line);                                     02558000
               cms (line,rc);                                           02559000
               writeln (ttyout,'=Lst=>',line:-120);                     02560000
               write   (ttyout,'=Lst=> Command executed with RC=',rc);  02561000
               writeln (ttyout,' (120 chars displayed)')                02562000
               end                                                      02563000
            end;                                                        02564000
     0:   goto terminate;                                               02565000
     otherwise goto again;                                              02566000
   end;                                                                 02567000
end;                                           (* of procedure code_1 *)02568000
%page                                                                   02569000
(**********************************************************************)02570000
(*                                                                    *)02571000
(*   Code selection 2                                                 *)02572000
(*                                                                    *)02573000
(**********************************************************************)02574000
procedure code_2;                                                       02575000
begin                                                                   02576000
case code of                                                            02577000
 1,2:  begin                                                            02578000
         if vmcms then                                                  02579000
         writeln(ttyout,'=Inp=> Enter ft <fm> for the routing table(s)',02580000
                        ' (Default: NETINIT A):')                       02581000
         else                                                           02582000
         writeln(ttyout,'=Inp=> Enter qualifier for the routing ',      02583000
                        'table(s) (Default: NETINIT):');                02584000
         readln(ttyin,line);                                            02585000
         if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));      02586000
         resmod := '';                                                  02587000
         ix := 1;                                                       02588000
         token(ix,line,restyp);                                         02589000
         token(ix,line,resmod);                                         02590000
         if restyp = '' then restyp := 'NETINIT';                       02591000
         if resmod = '' then resmod := 'A';                             02592000
         readstr(str(restyp),nodeid); (* nodeid is only *)              02593000
         convert(nodeid);             (* an aux variabl *)              02594000
         restyp := str(nodeid);       (* to match type  *)              02595000
         readstr(str(resmod),nodeid); (* for concersion *)              02596000
         convert(nodeid);                                               02597000
         resmod := str(nodeid);                                         02598000
         writeln(ttyout,'=Inp=> Enter additional informations '         02599000
                      ||'or just press <ENTER>:');                      02600000
         readln(ttyin,info);                                            02601000
         if ^dialog then writeln(ttyout,'=Lst=> ',info);                02602000
       end;                                                             02603000
 3,4:  begin                                                            02604000
         writeln(ttyout,'=Inp=> Enter local nodeid (for the calc. of ', 02605000
                        'the number of intermed. nodes):');             02606000
         readln(ttyin,ndnamen);                                         02607000
         if ^dialog then writeln(ttyout,'=Lst=> ',ndnamen);             02608000
         convert(ndnamen);                                              02609000
         writeln(ttyout,'=Inp=> Specify output options:');              02610000
         namen := 'INFO';                                               02611000
         if newop then begin                                            02612000
           if vmcms then                                                02613000
             if code = 3 then                                           02614000
               writeln(ttyout,'=Inp=> Enter fn ft <fm> of the output ', 02615000
                              'file (Default: EARN INFO A):')           02616000
               else writeln(ttyout,'=Inp=> Enter fn ft <fm> of the ',   02617000
                  'output file (Default: '||locountry||'-EARN INFO A):')02618000
           else                                                         02619000
             if code = 3 then                                           02620000
                writeln(ttyout,'=Inp=> Enter data set name of the ',    02621000
                               'output file (Default: EARN.INFO):')     02622000
             else writeln(ttyout,'=Inp=> Enter data set name of the ',  02623000
                   'output file (Default: '||locountry||'-EARN.INFO):');02624000
           readln(ttyin,line);                                          02625000
           if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));    02626000
           if vmcms then begin                                          02627000
              ix := 1;                                                  02628000
              token(ix,line,result);                                    02629000
              token(ix,line,restyp);                                    02630000
              if result = '' then                                       02631000
                if code = 3 then result := 'EARN'                       02632000
                            else result := locountry||'-EARN';          02633000
              if restyp = '' then restyp := 'INFO';                     02634000
              if (ix=(length(line)+1)) or (ix = 0) then                 02635000
                 resmod := 'A' else token(ix,line,resmod);              02636000
           end else begin                                               02637000
              line := trim(line);                                       02638000
              if line = '' then                                         02639000
                 if code = 3 then line := 'EARN.INFO'                   02640000
                             else line := locountry||'-EARN.INFO';      02641000
              tsoname := line;                                          02642000
           end;                                                         02643000
         end;                                                           02644000
         writeln(ttyout,                                                02645000
                '=Inp=> Sort NODENAMES   (alphabetic order): 1');       02646000
         writeln(ttyout,                                                02647000
                '=Inp=> Sort NODENUMBERS (JES2 numbers)    : 2');       02648000
         readln(ttyin,formopt);                                         02649000
         if ^dialog then writeln(ttyout,'=Lst=> ',formopt:1);           02650000
         if (formopt ^= 1) and (formopt ^=2) then formopt := 1;         02651000
         writeln(ttyout,                                                02652000
                '=Inp=> Select one tag (1) or long form (2):');         02653000
         readln(ttyin,formopt2);                                        02654000
         if ^dialog then writeln(ttyout,'=Lst=> ',formopt2:1);          02655000
         if (formopt2 ^= 1) and (formopt2 ^=2) then formopt2 := 1;      02656000
       end;                                                             02657000
  5:   begin                                                            02658000
         writeln(ttyout,'=Inp=> Enter local nodeid:');                  02659000
         readln(ttyin,ndnamen);                                         02660000
         if ^dialog then writeln(ttyout,'=Lst=> ',ndnamen);             02661000
         convert(ndnamen);                                              02662000
         writeln(ttyout,'=Inp=> Specify output options:');              02663000
         namen := 'EARNPLOT';                                           02664000
         if newop then begin                                            02665000
           if vmcms then writeln(ttyout,                                02666000
              '=Inp=> Enter fn ft <fm> of the output file ',            02667000
              '(Default: EARNPLOT DATA A):')                            02668000
           else writeln(ttyout,                                         02669000
              '=Inp=> Enter data set name of the output ',              02670000
              'file (Default: EARNPLOT.DATA):');                        02671000
           readln(ttyin,line);                                          02672000
           if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));    02673000
           if vmcms then begin                                          02674000
              ix := 1;                                                  02675000
              token(ix,line,result);                                    02676000
              token(ix,line,restyp);                                    02677000
              if result = '' then result := 'EARNPLOT';                 02678000
              if restyp = '' then restyp := 'DATA';                     02679000
              if (ix=(length(line)+1)) or (ix = 0) then                 02680000
                 resmod := 'A' else token(ix,line,resmod);              02681000
           end else begin                                               02682000
              line := trim(line);                                       02683000
              if line = '' then line := 'EARNPLOT.DATA';                02684000
              tsoname := line;                                          02685000
           end;                                                         02686000
         end;                                                           02687000
       end;                                                             02688000
  6:   ;                                                                02689000
  0:   goto terminate;                                                  02690000
  otherwise goto again;                                                 02691000
end;                                                                    02692000
end;                                           (* of procedure code_2 *)02693000
%page                                                                   02694000
(**********************************************************************)02695000
(*                                                                    *)02696000
(*   Code selection 3                                                 *)02697000
(*                                                                    *)02698000
(**********************************************************************)02699000
procedure code_3;                                                       02700000
begin                                                                   02701000
case code of                                                            02702000
1,3,5: begin                                                            02703000
       search(startnode,ndnamen,local_node,pred_node);                  02704000
       if local_node = nil then begin                                   02705000
          writeln(ttyout,'=Err=> Nodeid ',ndnamen,' not found.');       02706000
          goto again;                                                   02707000
       end;                                                             02708000
       if local_node@.xmailer = 'alias' then begin                      02709000
          writeln(ttyout,'=Run=> Nodeid ',ndnamen,' is an alias and ',  02710000
                         'will be treated as a separate');              02711000
          writeln(ttyout,'       node linked to the true node.');       02712000
          writeln(ttyout,'       Enter true nodename for correct',      02713000
                         'routing table.');                             02714000
       end;                                                             02715000
     end;                                                               02716000
  2: begin                                                              02717000
       local_node := startnode;                                         02718000
       repeat                             (* search for the node with *)02719000
          local_node := local_node@.next; (* the correct country id   *)02720000
          if local_node = nil then leave;                               02721000
          if local_node@.country = locountry then                       02722000
(*hug*)      begin                                                      02723000
(*hug*)      hug_soft   := '    '; hug_softrel := '  ';                 02724000
(*hug*)      hug_offset := 1;                                           02725000
             leave;                                                     02726000
(*hug*)      end;                                                       02727000
       until local_node = nil;                                          02728000
       if local_node = nil then begin     (* if there is none         *)02729000
          writeln(ttyout,'=Err=> No node with id ',locountry,' found.');02730000
          goto again;                                                   02731000
       end;                                                             02732000
     end;                                                               02733000
  4: begin                                                              02734000
       local_node := startnode;                                         02735000
       repeat                             (* search for  a  node with *)02736000
          local_node := local_node@.next; (* the correct country id   *)02737000
          if local_node = nil then leave;                               02738000
          if local_node@.country = locountry then leave;                02739000
       until local_node = nil;                                          02740000
       if local_node = nil then begin     (* if there is none         *)02741000
          writeln(ttyout,'=Err=> No node with id ',locountry,' found.');02742000
          goto again;                                                   02743000
       end;                                                             02744000
       search(startnode,ndnamen,local_node,pred_node);                  02745000
       if local_node = nil then begin                                   02746000
          writeln(ttyout,'=Err=> Nodeid ',ndnamen,' not found.');       02747000
          goto again;                                                   02748000
       end;                                                             02749000
     end;                                                               02750000
  6:   ;                                                                02751000
  otherwise;                                                            02752000
end;                                                                    02753000
end;                                           (* of procedure code_3 *)02754000
%page                                                                   02755000
(**********************************************************************)02756000
(*                                                                    *)02757000
(*   Initialize generation of INFO file                               *)02758000
(*                                                                    *)02759000
(**********************************************************************)02760000
procedure callinf;                                                      02761000
begin                                                                   02762000
   if vmcms then                                                        02763000
        writeln(ttyout,'=Run=> Generating info file ',                  02764000
          compress(str(result)||' '||str(restyp)||' '||str(resmod)))    02765000
   else writeln(ttyout,'=Run=> Generating info file ',                  02766000
                        compress(tsoname));                             02767000
   if newop then                                                        02768000
      if vmcms then                                                     02769000
         cms('FILEDEF INFOFILE DISK '||str(result)||' '                 02770000
             ||str(restyp)||' '||str(resmod)||' (RECFM V)',ix)          02771000
      else begin                                                        02772000
         tsocmd(1,'DEL '||tsoname,ix);                                  02773000
         tsocmd(1,'ALLOC F(INFOFILE) DA('||tsoname||') REUSE '          02774000
                ||'NEW SPACE(10,10) RELEASE TRACKS DSORG(PS) '          02775000
                ||'LRECL(80) RECFM(F B) BLKSIZE(4000) CATALOG',ix);     02776000
      end;                                                              02777000
   rewrite(infofile);                                                   02778000
   infoprint;                                                           02779000
   if newop then                                                        02780000
   if vmcms then cms('FILEDEF INFOFILE CLEAR',ix)                       02781000
   else begin                                                           02782000
        close(infofile);                                                02783000
        tsocmd(1,'FREE F(INFOFILE)',ix);                                02784000
   end                                                                  02785000
end;                                          (* of procedure callinf *)02786000
%page                                                                   02787000
(**********************************************************************)02788000
(*                                                                    *)02789000
(*   Initialize generation of XMAILER NAMES file                      *)02790000
(*                                                                    *)02791000
(**********************************************************************)02792000
procedure callxmailer;                                                  02793000
var m_fm : string(1);                                                   02794000
begin                                                                   02795000
   if vmcms then                                                        02796000
   writeln(ttyout,'=Run=> Generating XMAILER NAMES file')               02797000
          else                                                          02798000
   writeln(ttyout,'=Run=> Generating XMAILER.NAMES file');              02799000
   if newop then                                                        02800000
   if vmcms then begin                                                  02801000
      writeln(ttyout,'=Inp=> Enter fm for XMAILER NAMES file',          02802000
                        ' (Default fm: A):');                           02803000
      readln(ttyin,line);                                               02804000
      if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));         02805000
      if str(line) = '' then m_fm := 'A'                                02806000
                        else m_fm := substr(ltrim(line),1,1);           02807000
      cms('FILEDEF XMAILFIL DISK XMAILER NAMES '||m_fm||                02808000
          ' (RECFM V)',ix)                                              02809000
   end else begin                                                       02810000
        tsocmd(1,'DEL XMAILER.NAMES',ix);                               02811000
        tsocmd(1,'ALLOC F(XMAILFIL) DA(XMAILER.NAMES) REUSE '           02812000
               ||'NEW SPACE(10,10) RELEASE TRACKS DSORG(PS) '           02813000
               ||'LRECL(136) RECFM(V B) BLKSIZE(4048) CATALOG',ix);     02814000
        end;                                                            02815000
   rewrite(xmailfil);                                                   02816000
   xmailerpr;                                                           02817000
   if newop then                                                        02818000
   if vmcms then cms('FILEDEF XMAILFIL CLEAR',ix)                       02819000
   else begin                                                           02820000
        close(xmailfil);                                                02821000
        tsocmd(1,'FREE F(XMAILFIL)',ix);                                02822000
   end                                                                  02823000
end;                                      (* of procedure callxmailer *)02824000
%page                                                                   02825000
(**********************************************************************)02826000
(*                                                                    *)02827000
(*   Initialize generation of NETINIT files                           *)02828000
(*                                                                    *)02829000
(**********************************************************************)02830000
procedure callnetinit;                                                  02831000
var  new_nn       : integer;                                            02832000
     save_soft    : packed array (.1..4.) of char;                      02833000
     save_softrel : string(2);                                          02834000
     save_nnstart : integer;                                            02835000
begin                                                                   02836000
  if vmcms then writeln(ttyout,                                         02837000
     '=Run=> Generating netinit parameters: ',                          02838000
    compress(str(local_node@.name)||' '||str(restyp)||' '||str(resmod)))02839000
  else writeln(ttyout,                                                  02840000
     '=Run=> Generating netinit parameters: '                           02841000
     ,trim(str(local_node@.name)),'.',restyp);                          02842000
  if newop then                                                         02843000
     if vmcms then                                                      02844000
        cms('FILEDEF NETFILE DISK '||str(local_node@.name)||' '         02845000
           ||str(restyp)||' '||str(resmod)||' (RECFM V)',ix)            02846000
     else begin                                                         02847000
        tsocmd(1,'DEL '||trim(str(local_node@.name))                    02848000
               ||'.'||trim(str(restyp)),ix);                            02849000
        tsocmd(1,'ALLOC F(NETFILE) DA('||trim(str(local_node@.name))    02850000
               ||'.'||trim(str(restyp))||') REUSE '                     02851000
               ||'NEW SPACE(10,10) RELEASE TRACKS DSORG(PS) '           02852000
               ||'LRECL(80) RECFM(F B) BLKSIZE(4000) CATALOG',ix);      02853000
     end;                                                               02854000
     rewrite(netfile);                                                  02855000
(*hug*)                                                                 02856000
(*hug*) save_soft    := local_node@.soft ;                              02857000
(*hug*) save_softrel := local_node@.softrel ;                           02858000
(*hug*) save_nnstart := local_node@.nnstart ;                           02859000
(*hug*)                                                                 02860000
(*hug*) if hug_soft ^= '    '  then                                     02861000
(*hug*)    begin                                                        02862000
(*hug*)    local_node@.soft := hug_soft;                                02863000
(*hug*)    if hug_softrel ^= '  ' then                                  02864000
(*hug*)       local_node@.softrel := str(hug_softrel) ;                 02865000
(*hug*)    end;                                                         02866000
(*hug*)                                                                 02867000
(*hug*)    writeln(ttyout,'                                      ',     02868000
(*hug*)                   'Software :',local_node@.soft,'; ',           02869000
(*hug*)                   'Release :',local_node@.softrel);             02870000
(*hug*)                                                                 02871000
     softw := local_node@.soft;                                         02872000
     if (softw = 'JNET') then jnetinit                                  02873000
     else                                                               02874000
     if softw = 'JES3' then jes3init                                    02875000
     else                                                               02876000
     if (softw = 'JES2') then begin                                     02877000
(*hug*) if hug_offset > 1 then                                          02878000
(*hug*)    local_node@.nnstart := hug_offset                            02879000
        else                                                            02880000
           begin                                                        02881000
           writeln(ttyout,'=Run=> Node numbers starting with ',         02882000
                   local_node@.nnstart:3);                              02883000
           writeln(ttyout,'=Inp=> Do you want to change this value ?'|| 02884000
                          ' (Y/N) :');                                  02885000
           readln(ttyin,line);                                          02886000
           if ^dialog then writeln(ttyout,'=Lst=> ',compress(line));    02887000
           if ((index(line,'y') > 0 ) |                                 02888000
               (index(line,'Y') > 0 )) then begin                       02889000
              writeln(ttyout,'=Inp=> Enter new starting number :');     02890000
              readln(ttyin,local_node@.nnstart);                        02891000
              if ^dialog then writeln(ttyout,'=Lst=> ',                 02892000
                                              local_node@.nnstart:4);   02893000
           if (local_node@.nnstart < 1) then begin                      02894000
              local_node@.nnstart := 1;                                 02895000
              writeln(ttyout,'=Inf=> Start node number has'||           02896000
                             ' been set to 1');                         02897000
              end;                                                      02898000
           end;                                                         02899000
        end;                                                            02900000
        writeln(ttyout,'=Inp=> Sort table alphabetically (1) ',         02901000
                       'or by node number (2) ?');                      02902000
        writeln(ttyout,'       Enter number of option:');               02903000
        readln(ttyin,line);                                             02904000
        if ^dialog then writeln(ttyout,'=Lst=> ',line:1);               02905000
        jes2_sort := max(index('12',trim(ltrim(line))),1);              02906000
        if jes2_sort = 1 then                                           02907000
           writeln (ttyout,'=Run=> Sorting by node name')               02908000
        else                                                            02909000
           writeln (ttyout,'=Run=> Sorting by node number');            02910000
        if local_node@.softrel = 'V1' then jes2_v1_init                 02911000
                                      else jes2_v2_init;                02912000
     end                                                                02913000
     else                                                               02914000
     if (index(str(softw),'NJE') > 0) then jes2_v1_init                 02915000
     else                                                               02916000
     if (softw = 'UREP') then urepinit                                  02917000
     else                                                               02918000
     if (softw = 'TIEL') or (softw = 'INTE') then tielinit              02919000
     else begin                                                         02920000
      if softw ^= 'RSCS' then begin                                     02921000
       writeln(ttyout,'=Run=> Unknown networking software ',softw:4,    02922000
                      ' found for local node ',local_node@.name:8,'.'); 02923000
       writeln(ttyout,'=Run=> Valid netsoft tags in nodes file are :'); 02924000
       writeln(ttyout,'=Run=>   RSCS <V2>, JES2 <2.1.5/1.3.6/2.2.0>',   02925000
                      'or ...NJE... , JES3... ,');                      02926000
       writeln(ttyout,'=Run=>   JNET... ,UREP... , TIEL... or INTE...', 02927000
                      '(for NOS TIELINE/INTERCOM 5)');                  02928000
       writeln(ttyout,'=Run=> RSCS routing table will be created.');    02929000
       end;                                                             02930000
      rscsinit;                                                         02931000
      end;                                                              02932000
    close(netfile);                                                     02933000
(*hug*)                                                                 02934000
(*hug*) local_node@.soft    := save_soft;                               02935000
(*hug*) local_node@.softrel := save_softrel;                            02936000
(*hug*) local_node@.nnstart := save_nnstart;                            02937000
(*hug*)                                                                 02938000
end;                                      (* of procedure callnetinit *)02939000
%page                                                                   02940000
(**********************************************************************)02941000
(*                                                                    *)02942000
(*   Initialize generation of PLOT file                               *)02943000
(*                                                                    *)02944000
(**********************************************************************)02945000
procedure callplot;                                                     02946000
begin                                                                   02947000
   if vmcms then                                                        02948000
   writeln(ttyout,'=Run=> Generating plot file ',                       02949000
      compress(str(result)||' '||str(restyp)||' '||str(resmod)))  else  02950000
   writeln(ttyout,'=Run=> Generating plot file ',                       02951000
                   compress(tsoname));                                  02952000
   if newop then                                                        02953000
   if vmcms then                                                        02954000
   cms('FILEDEF PLOTFILE DISK '||str(result)||' '                       02955000
        ||str(restyp)||' '||str(resmod)||' (RECFM V)',ix)               02956000
   else begin                                                           02957000
        tsocmd(1,'DEL '||tsoname,ix);                                   02958000
        tsocmd(1,'ALLOC F(PLOTFILE) DA('||tsoname||') REUSE '           02959000
               ||'NEW SPACE(10,10) RELEASE TRACKS DSORG(PS) '           02960000
               ||'LRECL(80) RECFM(F B) BLKSIZE(4000) CATALOG',ix);      02961000
        end;                                                            02962000
   rewrite(plotfile);                                                   02963000
   earnplot;                                                            02964000
   if newop then                                                        02965000
   if vmcms then cms('FILEDEF PLOTFILE CLEAR',ix)                       02966000
   else begin                                                           02967000
        close(plotfile);                                                02968000
        tsocmd(1,'FREE F(PLOTFILE)',ix);                                02969000
   end                                                                  02970000
end;                                         (* of procedure callplot *)02971000
%page                                                                   02972000
(**********************************************************************)02973000
(* ****************************************************************** *)02974000
(* *                                                                * *)02975000
(* *              This is the main program of GENROUTS              * *)02976000
(* *                                                                * *)02977000
(* ****************************************************************** *)02978000
(**********************************************************************)02979000
begin                                                                   02980000
initmain;                                                               02981000
infomain;                                                               02982000
if newop then input_pr;                   (* prompt for input dataset *)02983000
                                   (*                                 *)02984000
writeln(ttyout,'=Run=> Construction of the network begins.');           02985000
gen_net;                           (* set pointer-structure of the net*)02986000
check_net;                                   (* check the connections *)02987000
gen_nodnum;                        (* generate node numbers if PENDing*)02988000
sort_nodnum;                       (* set pointers for sorting by num *)02989000
(*                                                                    *)02990000
writeln(ttyout,'=Run=> Construction of the network complete.');         02991000
again:                                                                  02992000
if newop then begin                                                     02993000
  options;                                                              02994000
  writeln(ttyout,'=Inp=> Enter number of option:');                     02995000
  readln(ttyin,line);                                                   02996000
  if ^dialog then writeln(ttyout,'=Lst=> ',line:1);                     02997000
  if vmcms then                                                         02998000
     code := index('01234567',trim(ltrim(line))) - 1                    02999000
  else                                                                  03000000
     code := index('0123456',trim(ltrim(line))) - 1;                    03001000
end;                                                                    03002000
(*                                                                    *)03003000
code_1;                                                                 03004000
(*                                                                    *)03005000
code_2;                                                                 03006000
(*                                                                    *)03007000
nextno:                                                                 03008000
(*                                                                    *)03009000
code_3;                                                                 03010000
(*                                                                    *)03011000
repeat                                                                  03012000
                       (* initialize the setting of the via variables *)03013000
  if xmailerreq = false then initvia;                                   03014000
(*                                                                    *)03015000
(**********************************************************************)03016000
(*                                                                    *)03017000
(*   Print of the info file                                           *)03018000
(*                                                                    *)03019000
(**********************************************************************)03020000
  if inforeq then begin      (* Print the info file                   *)03021000
     callinf;                                                           03022000
     if ^newop then goto terminate;                                     03023000
     inforeq := false;                                                  03024000
     goto again;                                                        03025000
  end;                                                                  03026000
(**********************************************************************)03027000
(*                                                                    *)03028000
(*   Print of the XMAILER NAMES file                                  *)03029000
(*                                                                    *)03030000
(**********************************************************************)03031000
  if xmailerreq then begin      (* Print the XMAILER NAMES file       *)03032000
     callxmailer;                                                       03033000
     if ^newop then goto terminate;                                     03034000
     xmailerreq := false;                                               03035000
     goto again;                                                        03036000
  end;                                                                  03037000
(**********************************************************************)03038000
(*                                                                    *)03039000
(*   Print of the plot file                                           *)03040000
(*                                                                    *)03041000
(**********************************************************************)03042000
  if plotreq then begin      (* Print the plot file                   *)03043000
     callplot;                                                          03044000
     if ^newop then goto terminate;                                     03045000
     plotreq := false;                                                  03046000
     goto again;                                                        03047000
  end;                                                                  03048000
(*                                                                    *)03049000
%page                                                                   03050000
(**********************************************************************)03051000
(*                                                                    *)03052000
(*   Now generate the routing tables !                                *)03053000
(*                                                                    *)03054000
(**********************************************************************)03055000
  callnetinit;                                                          03056000
  if newop then                                                         03057000
     if vmcms then cms('FILEDEF NETFILE CLEAR',ix)                      03058000
     else begin                                                         03059000
        close(netfile);                                                 03060000
        tsocmd(1,'FREE F(NETFILE)',ix);                                 03061000
     end;                                                               03062000
  if ^newop then begin                 (* in TSO we have to stop!     *)03063000
       writeln(ttyout);                                                 03064000
       writeln(ttyout,'=Run=> Valid options are ...');                  03065000
       writeln(ttyout,'=Run=> 1: Generates an information file with ',  03066000
                      'all nodes');                                     03067000
       writeln(ttyout,'=Run=> 2: Generates an information file with ',  03068000
                      'all nodes of a country');                        03069000
       writeln(ttyout,'=Run=> 3: Terminates');                          03070000
       writeln(ttyout,'=Inp=> Enter number of option :');               03071000
       readln(ttyin,code);                                              03072000
       if ^dialog then writeln(ttyout,'=Lst=> ',code:1);                03073000
       code := code + 2;                                                03074000
       if code = 5 then code := 0;                                      03075000
       goto again;                                                      03076000
     end;                                                               03077000
  if code = 1 then leave;              (* ok we had only one node, if *)03078000
                                       (* not take the next one       *)03079000
  repeat                               (* search for the next node    *)03080000
     local_node := local_node@.next;   (* with the correct country id *)03081000
     if local_node = nil then leave;                                    03082000
     if local_node@.country = locountry then                            03083000
(*hug*) begin                                                           03084000
(*hug*) hug_soft := '    '; hug_softrel := '  '; hug_offset := 1;       03085000
        leave;                                                          03086000
(*hug*) end;                                                            03087000
  until local_node = nil;                                               03088000
until local_node = nil;                                                 03089000
case code of                                                            03090000
  1: begin                                                              03091000
        writeln(ttyout,'=Inp=> Specify next nodeid or press <ENTER>:'); 03092000
(*hug*) get_node_name;                                                  03093000
        if ^dialog then writeln(ttyout,'=Lst=> ',ndnamen);              03094000
        convert(ndnamen);                                               03095000
        if ndnamen ^= '        ' then goto nextno                       03096000
        else goto again;                                                03097000
     end;                                                               03098000
  2: begin                                                              03099000
        writeln(ttyout,'=Inp=> Specify next country id or press ',      03100000
                       '<ENTER>:');                                     03101000
        readln(ttyin,locount);                                          03102000
        if ^dialog then writeln(ttyout,'=Lst=> ',locount);              03103000
        convert(locount);                                               03104000
        locountry := trim(str(locount));                                03105000
        if locount ^= '        ' then goto nextno                       03106000
        else goto again;                                                03107000
     end;                                                               03108000
  otherwise goto again;                                                 03109000
end;                                                                    03110000
terminate: writeln(ttyout);                                             03111000
writeln(ttyout,'=Fin=> GENROUTS ended, all work done. Poohhh...');      03112000
if newop then                                                           03113000
   if vmcms then cms('FILEDEF NODESFIL CLEAR',ix)                       03114000
   else begin                                                           03115000
      close(nodesfil);                                                  03116000
      tsocmd(1,'FREE F(NODESFIL)',ix);                                  03117000
   end;                                                                 03118000
end.                                                                    03119000
