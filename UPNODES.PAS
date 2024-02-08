PROGRAM updnodes(oldbase,delta,newbase,sysprint);
(*- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -*)
(*                                                                   *)
(*COPYRIGHT:                                                         *)
(*           Gesellschaft fuer Mathematik und Datenverarbeitung mbH  *)
(*           Institut fuer informationstechnische Infrastrukturen    *)
(*           Bereich Bonn                                            *)
(*           D-5300 Bonn 2                                           *)
(*                                                                   *)
(*     This program is written to support the EARN network, it may   *)
(*   be used and copied freely in the network and any other non      *)
(*   commercial network as long as this header remains intact.       *)
(*   The program may NOT be used to support any military activities  *)
(*   in any way.                                                     *)
(*                                                                   *)
(*DISCLAIMER:                                                        *)
(*     Although the program has been tested by the author and other  *)
(*   people, no warranty is made by the author or by GMD about       *)
(*   correct function of the program. The author or GMD cannot be    *)
(*   held for any damage the program may cause.                      *)
(*                                                                   *)
(*     Maintenance or developments may or may not be available. No   *)
(*   promise of such support or enhancement can be deduced anyhow.   *)
(*                                                                   *)
(*                                                                   *)
(*NAME:                                                              *)
(*                                                                   *)
(*       U P D N O D E S                                             *)
(*                                                                   *)
(*                                                                   *)
(*                                                                   *)
(*FUNCTION/OPERATION:  Most of the following is stolen from B. Pasch *)
(*                                                                   *)
(* UPDNODES is a tool for the EARN node management.                  *)
(*                                                                   *)
(* GENODUPD at a central site to build an update file, and           *)
(* UPDNODES to apply the updates to the old version nodes file at    *)
(*          various sites in the network.                            *)
(*                                                                   *)
(* Processing is as follows (see also examples below):               *)
(*                                                                   *)
(* 1) At a central site a new nodes file is built using already      *)
(*    available programs.  An old version of the nodes file is also  *)
(*    available.  Both versions contain checksums in their entries   *)
(*    and both do also contain a VERSyymm entry which describes the  *)
(*    version of its file.  The version entries must contain         *)
(*    checksums for themselves and a total checksum for the entire   *)
(*    file they belong to.                                           *)
(*                                                                   *)
(* 2) GENODUPD is used to build the 'delta' file VERSyymm UPDNOD by  *)
(*    comparing the old and new version nodes file and writing the   *)
(*    differences into the 'delta' file:                             *)
(*                                                                   *)
(*    a) An UPDNODES statement that requires a certain level of the  *)
(*       UPDNODES program.                                           *)
(*    b) The version number of the new file (name of version entry)  *)
(*       is placed into a NEWVERSION or NEWBASE statement generated  *)
(*       by GENODUPD. The version numbers found in the update        *)
(*       history of the old file are used to define the              *)
(*       prerequisites for the update.                               *)
(*    c) A DEL statement for the old VERSyymm entry is written.      *)
(*    d) A new VERSyymm entry with the new version number is built   *)
(*       and written as an ADD request. This VERSyymm entry contains *)
(*       a checksum for itself (:cks tag) plus a total checksum      *)
(*       (:totcks tag) for the entire new nodes file. It contains    *)
(*       also an updated history.                                    *)
(*    e) The old and new nodes file are compared, entry by entry,    *)
(*       and if a difference is found appropriate update information *)
(*       is written into the update file. The VERSyymm entries in    *)
(*       old and new file are ignored in this compare process.       *)
(*                                                                   *)
(*       ADD statements plus the complete information about an entry *)
(*           are written for new nodes.                              *)
(*       REP statements with only the changed tags are written for   *)
(*           nodes which have been updated.                          *)
(*       DEL statements with the node tag only, are written for      *)
(*           deleted entries.                                        *)
(*       The ADD and REP statements contain also the new checksum    *)
(*       value for the corresponding entry.                          *)
(*                                                                   *)
(* 3) The update file is shipped to all locations which have a need  *)
(*    for it.                                                        *)
(*                                                                   *)
(* 4) These sites use the UPDNODES program to apply the updates to   *)
(*    their copy of the old version nodes file.                      *)
(*                                                                   *)
(* 5) When the UPDNODES program is run it performs the following:    *)
(*                                                                   *)
(*    a) Reads any "prologue" statements: Currently only UPDNODES    *)
(*       is supported. The program checks whether it runs at least   *)
(*       at the requested maintenance level. This feature is not     *)
(*       available in version 1.2. PLease ensure that your UPDNODES  *)
(*       programs runs at least at level 1.3.                        *)
(*    a) Reads the NEWVERSION or NEWBASE control statement in the    *)
(*       update file. Compares the prerequisites defined in this     *)
(*       statement with the information found in the VERSyymm entry  *)
(*       of the old nodes file (update history). If the              *)
(*       prerequisites are not fulfilled the update is terminated.   *)
(*                                                                   *)
(*       Note: In the current version of UPDNODES this is not done.  *)
(*       The initial action(s) up to the first DEL/ADD for the       *)
(*       version entry are ignored.                                  *)
(*       Instead of that it is assumed that the first two node       *)
(*       entry may be VERSnnnn and/or LINKSnnn.                      *)
(*                                                                   *)
(*    b) Reads the entire old nodes file and does a checksum         *)
(*       verification on all entries (including the VERSyymm entry   *)
(*       which is also check- sum protected). It builds also a total *)
(*       checksum over all entries and compares this value with the  *)
(*       one saved in the VERSyymm entry.  If there is an error in   *)
(*       the checksum verification the update is cancelled.          *)
(*    c) Adds and deletes complete entries as specified in the       *)
(*       update file.  For replace requests: adds, replaces or       *)
(*       deletes the individual tags specified with the REP request. *)
(*       The version entry is placed at the beginning of the file.   *)
(*       Note: In the current version of UPDNODES b) and c) are done *)
(*       in one pass. If the program finds a wrong checksum, the     *)
(*       program warns about that, and continues. The new entry will *)
(*       contain the computed checksum.                              *)
(*                                                                   *)
(*    d) Verifies in the newly established file the checksum of each *)
(*       entry as well as the total checksum to ensure that the      *)
(*       update was ok and no unallowed modifications were made to   *)
(*       the update file.                                            *)
(*                                                                   *)
(* For the format of version entries and update statements see the   *)
(* following examples.                                               *)
(*                                                                   *)
(* Example:                                                          *)
(*                                                                   *)
(* 'old' contains:                                                   *)
(* ---------------                                                   *)
(*  :node.VERS8603 ......                                            *)
(*      :remark1.BASE(8601) 86/01/14 12:47:15                        *)
(*      :remark2.VERSION(8602) PRE(8601) 86/02/09 17:18:09           *)
(*      :remark3.VERSION(8603) PRE(8601 8602) 86/03/11 11:27:18      *)
(*      :cks.11111 :totcks.22222                                     *)
(*  :node.nodename ----- (normal node entries) ----- :cks.nnnnn      *)
(*                                                                   *)
(* 'new' contains:                                                   *)
(* ---------------                                                   *)
(*  :node.VERS8604 ......                                            *)
(*      :cks.33333 :totcks.44444                                     *)
(*  :node.nodename ----- (normal node entries) ----- :cks.nnnnn      *)
(*                                                                   *)
(* After running GENODUPD with option NEWVERS 'delta' will contain:  *)
(* ----------------------------------------------------------------  *)
(*  UPDNODES(1.3)                                                    *)
(*  NEWVERSION(8604) PRE(8601 8602 8603)                             *)
(*  DEL VERS8603                                                     *)
(*  ADD VERS8604 ......                                              *)
(*      :remark1.BASE(8601) 86/01/14 12:47:15                        *)
(*      :remark2.VERSION(8602) PRE(8601) 86/02/09 17:18:09           *)
(*      :remark3.VERSION(8603) PRE(8601 8602) 86/03/11 11:27:18      *)
(*      :remark4.VERSION(8604) PRE(8601 8602 8603) 86/04/11 12:43:17 *)
(*      :cks.55555 :totcks.44444                                     *)
(*  ADD nodename ---  (for new nodes in 'new') --- :cks.nnnnn        *)
(*  REP nodename ---  (for changed nodes in 'new') --- :cks.nnnnn    *)
(*  DEL nodename      (for nodes missing in 'new')                   *)
(*                                                                   *)
(* After running UPDNODES with 'delta' against 'old' (VERS8603)      *)
(* to create a 'new' file, 'new' will contain:                       *)
(* ------------------------------------------                        *)
(*  :node.VERS8604 ......                                            *)
(*      :remark1.BASE(8601) 86/01/14 12:47:15                        *)
(*      :remark2.VERSION(8602) PRE(8601) 86/02/09 17:18:09           *)
(*      :remark3.VERSION(8603) PRE(8601 8602) 86/03/11 11:27:18      *)
(*      :remark4.VERSION(8604) PRE(8601 8602 8603) 86/04/11 12:43:17 *)
(*      :cks.55555 :totcks.44444                                     *)
(*  :node.nodename ----- (normal node entries) ----- :cks.nnnnn      *)
(*                                                                   *)
(* Next month this 'new' will be used as 'old' and so on.            *)
(*                                                                   *)
(* If GENODUPD is called with option NEWBASE 'delta' will contain:   *)
(* ---------------------------------------------------------------   *)
(*  UPDNODES(1.3)                                                    *)
(*  NEWBASE(8604) PRE(8601 8602 8603)                                *)
(*  DEL VERS8603                                                     *)
(*  ADD VERS8604 ......                                              *)
(*          :remark1.BASE(8604) 86/04/11 12:43:17                    *)
(*          :cks.66666 :totcks.44444                                 *)
(*  ADD nodename ---  (for new nodes in 'newfile') --- :cks.nnnnn    *)
(*  REP nodename ---  (for changed nodes in 'newfile') --- :cks.nnnnn*)
(*  DEL nodename        (for nodes missing in 'newfile')             *)
(*                                                                   *)
(* After running UPDNODES with this 'delta', 'new' will contain:     *)
(* -------------------------------------------------------------     *)
(*  :node.VERS8604 ......                                            *)
(*      :remark1.BASE(8604) 86/04/11 12:43:17                        *)
(*      :cks.66666 :totcks.44444                                     *)
(*  :node.nodename --- (normal node entries) --- :cks.nnnnn          *)
(*                                                                   *)
(*                                                                   *)
(*                                                                   *)
(* Description of the update statements in the 'delta' file:         *)
(* ---------------------------------------------------------         *)
(*                                                                   *)
(* The ADD statements will always contain a full entry, i.e. all     *)
(* tags which got data assigned plus the checksum tag for this       *)
(* entry.                                                            *)
(*                                                                   *)
(* The REP statements in the 'delta' file will not contain the full  *)
(* entry which is to be replaced but will contain only the tags      *)
(* which changed.  New tags and changed tags will be placed together *)
(* with their corresponding data in the REP statement. Deleted       *)
(* tags will be represented by a tagname without data (null-string). *)
(* There will also be a checksum tag with the checksum for the       *)
(* replaced entry.                                                   *)
(*                                                                   *)
(* The DEL statements require nothing but the nodename.              *)
(*                                                                   *)
(* Note: The :node. tag identifier does not appear in the update     *)
(*    statements.  The nodename is always the first word after       *)
(*    ADD, REP or DEL.  This allows to use the update file also      *)
(*    if the nodename is identified by some other tag (e.g. :nick.). *)
(*                                                                   *)
(* Checksums:                                                        *)
(* ---------                                                         *)
(*                                                                   *)
(* Since this update concept is sensitive to unallowed modifications *)
(* in the old nodes file and in the update file, the entries in the  *)
(* file must be checked before and after the updates are applied in  *)
(* order to detect such modifications. For this purpose a checksum   *)
(* per entry and a total checksum are maintained in the file and new *)
(* checksums are delivered with the update file.                     *)
(*                                                                   *)
(* The checksum per entry includes the nodename and all tags of this *)
(* entry except the checksum tag (:cks tag).  The checksum of each   *)
(* tag is calculated individually.  It includes tagname and          *)
(* tagvalue, e.g. ':site.Univ. of Heidelberg', except for the        *)
(* nodename where only the tagdata is checksummed but not the tag    *)
(* identifier (:node.). All blanks in the tagdata are counted.       *)
(* Trailing blanks are ignored.                                      *)
(*                                                                   *)
(* The checksum is built after an algorithm which ensures that data  *)
(* modifications, bit errors and exchange of characters or words     *)
(* is detected with a high probablity (we use a 16 bit checksum,     *)
(* probability of undetected error = 1/65535). The checksum of the   *)
(* complete entry is then built by combining the checksums of each   *)
(* tag via Exclusive Or.  The result is converted to decimal         *)
(* (0-65535) and stored in the :cks tag.                             *)
(*                                                                   *)
(* The total checksum is built by calculating the checksum of only   *)
(* the nodename of each entry (without the tag identifier :node.)    *)
(* and combining them all via Exclusive Or. The decimal equivalent   *)
(* of this total checksum is stored in the :totcks tag of the        *)
(* version entry.                                                    *)
(*                                                                   *)
(* Note the :cks and :totcks tags are never included in checksum     *)
(* construction.                                                     *)
(*                                                                   *)
(*                                                                   *)
(*                                                                   *)
(*                                                                   *)
(*ENTRY POINTS:                                                      *)
(*       UPDNODES                                                    *)
(*       The program can be called as a CMS command processor (VM),  *)
(*       or as an MVS-"main-program".                                *)
(*                                                                   *)
(*                                                                   *)
(*INPUT:                                                             *)
(*       The program accepts "invocation parameters":                *)
(*       In CMS the parameters as specified as positional parameters *)
(*       in the command invocation, under MVS the parameters         *)
(*       are specified in the OS parameter list.                     *)
(*                                                                   *)
(*       The value controls the level of information produced on     *)
(*       FILE SYSPRINT:                                              *)
(*                                                                   *)
(*       Default processing is that error messages will be written   *)
(*       on SYSPRINT.                                                *)
(*                                                                   *)
(*       QUIET                                                       *)
(*           Do not produce any output on SYSPRINT.                  *)
(*                                                                   *)
(*       SERMON                                                      *)
(*           Create a detailed processing log                        *)
(*                                                                   *)
(*                                                                   *)
(*       (I'm still working on some parameters to control the        *)
(*       amount of work done by the program. Any comments are        *)
(*       welcome.)                                                   *)
(*                                                                   *)
(*OUTPUT:                                                            *)
(*       If running in "quiet" mode no extra output (except to       *)
(*       file NEW, of course) is procuded. If running in "sermon"    *)
(*       mode, a log of all actions is created on file SYSPRINT,     *)
(*       if not running in "quiet" mode, error messages are          *)
(*       written to file SYSPRINT.                                   *)
(*                                                                   *)
(*DD-STATEMENTS/DATA SETS:                                           *)
(*       OLD     : contains the old data base                        *)
(*       NEW     : will contain the new data base                    *)
(*       DELTA   : contains the update requests                      *)
(*                                                                   *)
(*                                                                   *)
(*NORMAL EXIT:                                                       *)
(*       Standard PASCAL Return                                      *)
(*                                                                   *)
(*                                                                   *)
(*ERROR EXIT:                                                        *)
(*       NONE                                                        *)
(*                                                                   *)
(*                                                                   *)
(*RETURN CODES:                                                      *)
(*       0     Function successful                                   *)
(*       1     Delta empty                                           *)
(*       2     Invalid total checksum                                *)
(*       3     Invalid checksum in major                             *)
(*       4     Major tag not at beginning                            *)
(*       5     Minor identical to major                              *)
(*       6     Value missing for action                              *)
(*       7     No major in data base                                 *)
(*       8     Major tag too long                                    *)
(*       9     Old base out of sort order                            *)
(*      10     Delta out of sort order                               *)
(*      11     Action invalid                                        *)
(*      12     Invalid delta start                                   *)
(*      13     Updnodes not smart enough                             *)
(*                                                                   *)
(*                                                                   *)
(*EXTERNAL ROUTINES:                                                 *)
(*       CHKSUM       A program to generate checksums                *)
(*                                                                   *)
(*                                                                   *)
(*RELATED PROGRAMS:                                                  *)
(*       GENODUPD     A program that creates a delta file            *)
(*                                                                   *)
(*                                                                   *)
(*STORAGE:                                                           *)
(*       PROGRAM:  70K                                               *)
(*       DYNAMIC:  Not calculated                                    *)
(*                                                                   *)
(*                                                                   *)
(*LOAD MODULE CREATION:                                              *)
(*     SOURCE LANGUAGE      :  PASCAL/VS                             *)
(*     COMPILE LIBRARIES    :  None                                  *)
(*     COMPILE PARAMETERS   :                                        *)
(*                                                                   *)
(*                                                                   *)
(*     DESTINATION LIBRARIES:  The program is available from NETSERV *)
(*                             as UPDNODES MODULE (CMS-version)      *)
(*                             or UPDNODES OBJ    (MVS-version).     *)
(*                                                                   *)
(*     GENERATING DECK      :  The program is generated using the    *)
(*                             PASCALVS and PASCMOD execs/clists     *)
(*                                                                   *)
(*                                                                   *)
(*STATUS:                                                            *)
(*         CHANGE LEVEL - 1.0  June 1986                             *)
(*                        1.1  Some uninitialized variable )-: 860814*)
(*                        1.2  Enhanced "error recovery"       860816*)
(*                        1.3  Error when adding HIGH nodes    870515*)
(*                             Small enhancements                    *)
(*                                                                   *)
(*                                                                   *)
(*NOTES:    The following "invocation tools" are available from      *)
(*          NETSERV:                                                 *)
(*                                                                   *)
(*          UPDNODES EXEC : A CMS REXX program                       *)
(*          For MVS no tools are available. The number of            *)
(*          required actions is trivial compared to the possible     *)
(*          variations to do that: It seems superfluous to the       *)
(*          author of UPDNODES to write a CLIST, a JCL-PROC that     *)
(*          contains a set of variables for all DD-statements.       *)
(*          Default reactions to error return codes are also         *)
(*          trivial. Another reason not to "support" MVS is the      *)
(*          note at the end of paragraph "INPUT".                    *)
(*                                                                   *)
(*          The CMS-EXEC is only one hint of how to invoke the       *)
(*          program, too, taken from a NETSERV internal procedure.   *)
(*                                                                   *)
(*          Caution: When you RECEIVE the UPDNODES OBJ file          *)
(*          with TSO/E, don't forget to specify a parameter that     *)
(*          matches the maximum BLKSIZE for the MVS linkage editor.  *)
(*          (3120 is the value, isn't it.)                           *)
(*                                                                   *)
(*          NETSERV does not send a BLKSIZE NETDATA tag in the       *)
(*          file and the TSO/E RECEIVE default is a bad value.       *)
(*                                                                   *)
(*                                                                   *)
(*AUTHOR:   Peter Sylvester <GRZ027@DBNGMD21>                        *)
(*          Gesellschaft fuer Mathematik und Datenverarbeitung mbH   *)
(*          Riemenschneiderstrasse 11                                *)
(*          D-5300 Bonn 2                                            *)
(*          Federal Republic of Germany                              *)
(*                                                                   *)
(*                                                                   *)
(*- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- -*)
%page ;
(*********************************************************************)
(*                                                                   *)
(*   environment definitions                                         *)
(*                                                                   *)
(*********************************************************************)
STATIC copyright : STRING(255) ;
VALUE copyright :=
      'Copyright GMD Bonn 1986, 1987 all rights reserved';
STATIC name_version_date : STRING(255) ;
VALUE name_version_date := 'UPDNODES Version 1.3-15MAY87';
STATIC this_updnodes : STRING(3) ;
VALUE  this_updnodes := '1.3';
 
CONST function_successful             =  0;
      delta_empty                     =  1;
      invalid_total_checksum          =  2;
      invalid_checksum_in_major       =  3;
      major_tag_not_at_beginning      =  4;
      minor_identical_to_major        =  5;
      value_missing_for_action        =  6;
      no_major_in_data_base           =  7;
      major_tag_too_long              =  8;
      old_base_out_of_sort_order      =  9;
      delta_out_of_sort_order         = 10;
      action_invalid                  = 11;
      invalid_delta_start             = 12;
      updnodes_not_smart_enough       = 13;
 
VAR highest_retcode :INTEGER ;
    maximum_retcode :INTEGER ;
VAR  sysprint : TEXT ;
 
VAR  sermon:      BOOLEAN ;
     quiet:       BOOLEAN ;
     trace:       BOOLEAN ;
     infolinemax: INTEGER ;
 
 
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE initializes processing parameters.               *)
(*                                                                   *)
(*   Note: This is still temporary.                                  *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE init_environment;
BEGIN
   infolinemax := 240;     (* due to some reason that only Bert knows*)
                      (* change it to 1 if you want one tag per line *)
   trace       := FALSE; (* (PARMS = 'TRACE') *)  ;
   sermon      := trace | (PARMS = 'SERMON') ;
   quiet       := (PARMS = 'QUIET')  ;
   highest_retcode := 0;
   maximum_retcode := 999 ;
END (* init_environment *);
 
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE logs the highest error code and sets it into     *)
(*   the external environment.                                       *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE set_retcode;
BEGIN
   IF (^quiet & (sermon | (highest_retcode > 0))) THEN
   BEGIN
      IF highest_retcode = 0 THEN
         Writeln(sysprint,'  :No errors found')
      ELSE
         Writeln(sysprint,highest_retcode:2,' was highest error code');
   END ;
   retcode(highest_retcode);
END ;
 
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE logs a line if SERMON is active                  *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE sermon_line(line:STRING(255));
BEGIN
   IF sermon THEN Writeln(sysprint,'  :'||line) ;
END (* sermon_line *);
 
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE logs an error line (and may abort program)       *)
(*                                                                   *)
(*********************************************************************)
LABEL abort_updnodes ;
 
PROCEDURE showerror(line:STRING(255);rc:INTEGER);
BEGIN
   IF ^quiet THEN
      IF rc = 0 THEN Writeln(sysprint,'  :'||line)
      ELSE Writeln(sysprint,rc:2,':'||line);
   IF rc > highest_retcode THEN
      highest_retcode := rc ;
   IF Rc >= maximum_retcode THEN GOTO abort_updnodes
END;
 
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE is not used at all.                              *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE traceline(line:STRING(255));
BEGIN
   IF trace THEN Writeln(sysprint,'***'||line)
END;
(*********************************************************************)
(*                                                                   *)
(*   This FUNCTION returns a string of at least 10 characters.       *)
(*                                                                   *)
(*********************************************************************)
FUNCTION tn( name   : STRING(64) ) : STRING(64) ;
BEGIN
   IF length(name) >= 10 THEN tn := name
   ELSE tn := SUBSTR(name||'          ',1,10) ;
END (* tn *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The data base contains a two level chain of data.               *)
(*                                                                   *)
(*********************************************************************)
TYPE
 
   major_pointer = -> major ;
   minor_pointer = -> minor ;
   major    = RECORD
              next        : major_pointer ;
              name        : STRING(64) ;     (* major tag name       *)
              first       : minor_pointer ;  (* first minor tag      *)
              checksum    : INTEGER
              END ;
   minor    = RECORD
              next        : minor_pointer;
              name        : STRING(12);      (* tag                  *)
              minvalue    : STRINGPTR        (* value                *)
              END ;
 
VAR major_tag : STRING(64) ;
    major_tag_length : INTEGER;
 
%page ;
(*********************************************************************)
(*                                                                   *)
(*   This FUNCTION searches for a minor entry with name              *)
(*   IF it doe not exist, a new entry is inserted appended.          *)
(*                                                                   *)
(*   Note: minors are NOT in alphabetic order for now.               *)
(*                                                                   *)
(*********************************************************************)
FUNCTION misearch( inlist : major_pointer;
                   name   : STRING(12) ;
                   minvalue : STRING(255)
                 ) : minor_pointer ;
VAR
   min    : minor_pointer;
   pred   : minor_pointer;
BEGIN
   min       := inlist@.first ;
   pred      := nil;
   WHILE (min ^= nil)
       & (min@.name ^= name)  DO
   BEGIN
         pred      := min;            (* keep that in mind           *)
         min       := min@.next;      (* try the next one            *)
   END;
   IF min = nil THEN
   BEGIN                              (* create new element in chain *)
      new(min) ;
      min@.name      := name;
      min@.next      := nil ;
      IF pred ^= nil THEN BEGIN
         min@.next      := pred@.next ;
         pred@.next := min ;
      END ELSE BEGIN
         min@.next := inlist@.first ;
         inlist@.first := min ;
      END ;
   END                                (* existing: forget value      *)
   ELSE BEGIN
      dispose(min@.minvalue);
   END ;
 
   new(min@.minvalue,length(minvalue)); (* allocate storage and      *)
   min@.minvalue@ := minvalue ;       (* set new value               *)
 
   misearch       := min ;
END (* misearch *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(* This FUNCTION deletes a minor entry and returns the next element  *)
(*                                                                   *)
(*********************************************************************)
 
FUNCTION mindel (min : minor_pointer ): minor_pointer;
BEGIN
   mindel := min@.next ;
   dispose(min@.minvalue);      (* dispose the value first     *)
   dispose(min)                 (* and then the element        *)
END (* of mindel *) ;
 
(*********************************************************************)
(*                                                                   *)
(*   This FUNCTION tries to find a minor with name and pattern       *)
(*                                                                   *)
(*   IF pattern is '' no value match is necessary. This is not       *)
(*   a restriction because the data base NEVER contains empty tags.  *)
(*                                                                   *)
(*********************************************************************)
FUNCTION minfind( inlist : major_pointer;
                  name   : STRING(12);
                  pattern: STRING(255)
                ) : minor_pointer;
VAR
   min    : minor_pointer;
BEGIN
   minfind        := nil;
   IF inlist ^= nil THEN BEGIN
      min       := inlist@.first ;
      WHILE min ^= nil DO
      IF trim(min@.name) = trim(name) THEN BEGIN (* name found *)
         IF (pattern = '') |
            (trim(min@.minvalue@) = trim(pattern))
         THEN minfind := min ;         (* return min entry           *)
         LEAVE
      END ELSE  min := min@.next;      (* try the next one           *)
   END
END (* minfind *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   This FUNCTION searches for a major entry with name.             *)
(*   IF it doesn't exist, a new entry is inserted in alphabetic order*)
(*                                                                   *)
(*********************************************************************)
FUNCTION masearch( VAR inlist : major_pointer;
                       name   : STRING(64)
                 ) : major_pointer ;
VAR
   maj    : major_pointer;
   pred   : major_pointer;
BEGIN
   maj       := inlist;
   pred      :=   nil;
   WHILE maj ^= nil DO
      IF maj@.name = name THEN LEAVE  (* ok, have it                 *)
      ELSE IF maj@.name > name THEN
         maj := nil                   (* too far in the alphabet ==> *)
      ELSE BEGIN
         pred      := maj ;
         maj       := maj@.next ;       (* try the next one          *)
      END;
   IF maj = NIL THEN
   BEGIN                              (* create new element in chain *)
      new(maj);
      maj@.name      := name;
      maj@.first     := nil;
      maj@.checksum  := -1;
      IF pred ^= nil THEN BEGIN
         maj@.next := pred@.next ;
         pred@.next := maj ;
      END ELSE BEGIN
         maj@.next := inlist ;
         inlist := maj ;
      END ;
   END ;
   masearch := maj ;
END (* masearch *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE deletes a major entry IF it exists (or the first *)
(*   in list IF name = ''                                            *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE majdel( VAR inlist : major_pointer;
                  name   : STRING(12)
                 );
VAR
   maj    : major_pointer;
   pred   : major_pointer;
   min    : minor_pointer;
BEGIN
   maj       := inlist ;
   pred      := nil;
   IF name ^= '' THEN
   WHILE (maj ^= nil)
       & (maj@.name ^= name) DO
   BEGIN                              (* too far in the alphabet ==> *)
      pred      := maj;               (* keep that in mind           *)
      maj       := maj@.next;         (* try the next one            *)
   END;
   IF maj ^= nil THEN
   BEGIN
      IF pred ^= nil THEN
         pred@.next := maj@.next      (* unchain in list             *)
      ELSE IF inlist ^= nil THEN
         inlist := inlist@.next ;     (* or unchain first (IF any)   *)
 
      min := maj@.first;              (* dispose chain               *)
      WHILE min ^= nil DO
         min := mindel(min);
      dispose(maj);                   (* and then the entry itself   *)
   END
 
END (* majdel *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE computes a checksum.                             *)
(*                                                                   *)
(*   oldsum and newsum can be the same variable.                     *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE chksum(const osum:INTEGER;
                 const dSTRING:STRING(255);
                 var nsum:INTEGER); fortran;
 
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE validates one major entry and compares  *)
(*   the checksum.                                                   *)
(*                                                                   *)
(*   Note: A new checksum is assigned IF it does not yet exist.      *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE val_maj(maj : major_pointer ;(* major entry to be validated*)
              ofbase:STRING(255);      (* text to describe the data  *)
              VAR totalsum: INTEGER    (* an overall checksum        *)
                 );
VAR
   min : minor_pointer ;
   checksum: INTEGER ;
   tag     : STRING(255) ;
BEGIN
   IF maj = Nil THEN RETURN;
                                       (* Primary tag included in sum*)
   tag := ':'||major_tag||'.'||maj@.name||' ' ;
   chksum(totalsum,maj@.name,totalsum);
 
   chksum(0,maj@.name,checksum);
 
   min := maj@.first ;                 (* start with first tag       *)
   WHILE min ^= nil DO                 (* loop thru all minor tags   *)
   BEGIN
      IF min@.name ^= 'cks' THEN BEGIN (* checksum key not included  *)
         IF (min@.name ^= 'totcks')&
            (min@.minvalue@ ^= '')THEN BEGIN (* ignore empty keys    *)
 
            tag := ':'||min@.name||'.'||min@.minvalue@||' ';
            chksum(checksum,tag,checksum);
         END
      END
      ELSE IF (*maj@.checksum = -1*)
              (ltrim(min@.minvalue@) ^= 'NOCKS') THEN
                                       (* extract previous sum       *)
         Readstr(min@.minvalue@,maj@.checksum) ;
      min := min@.next
   END ;
                                       (* see what we have, report   *)
   IF maj@.checksum ^= checksum THEN
   BEGIN
      IF maj@.checksum ^= -1 THEN
      BEGIN
         Writestr(tag,maj@.checksum:-5);
         showerror('Checksum '||tag
               ||' for entry '||maj@.name||' '||ofbase
               ||' is incorrect,',
               invalid_checksum_in_major);
      END ;
      Writestr(tag,checksum:-5);
      showerror('new checksum '||ltrim(tag)
      ||' assigned for entry '||maj@.name||' '||ofbase,0)
   END ;
   maj@.checksum := checksum;          (* assign new checksum        *)
END (* val_maj *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following procedure validates the total check sum against   *)
(*   the totalcks field in the version entry.                        *)
(*                                                                   *)
(*   Note: A new checksum is assigned IF it does not yet exist.      *)
(*   Currently this CANNOT be used because the new version entry     *)
(*   is already written out (one pass only!!!)                       *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE valtotal(versionp:major_pointer;
                   checksum:INTEGER;
                   ofbase:STRING(255));
VAR
   min      : minor_pointer ;
   totalsum : INTEGER ;
   cks      : STRING(5);
   cks2     : STRING(5);
BEGIN
   IF versionp = NIL THEN RETURN ;
   min := minfind(versionp,'totcks','');
   IF (min ^= NIL) & (ltrim(min@.minvalue@) ^= 'NOCKS') THEN
   BEGIN
      Readstr(min@.minvalue@,totalsum) ;
      IF (totalsum ^= checksum) THEN
      BEGIN
         Writestr(cks,checksum:-5);
         Writestr(cks2,totalsum:-5);
         showerror('Total checksum '||ofbase||' '||cks2||
                 ' is incorrect, computed value is: '||cks,
                 invalid_total_checksum);
      END
   END ELSE BEGIN
      Writestr(cks,checksum:-5);
      showerror('Total checksum '||ofbase||' is: '||cks,0);
                                                (* just inform *)
   END ;
END (* valtotal *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE creates an entry in the new network file*)
(*                                                                   *)
(*   It is assumed that a tag with value is never longer than the    *)
(*   output line length.                                             *)
(*   An cks tag will be added if there was no previous one.          *)
(*   The checksum written is always the computed one.                *)
(*   It is assumed the output file is already reset.                 *)
(*                                                                   *)
(*********************************************************************)
VAR
   newbase   : TEXT     ;        (* output file                 *)
 
PROCEDURE show_maj(maj : major_pointer);
VAR
   min     : minor_pointer ;
   line    : STRING(255) ;
   tag     : STRING(255) ;
   checksum_needed : BOOLEAN;
BEGIN
   checksum_needed := TRUE;              (* still need checksum      *)
   IF maj = nil THEN RETURN;
   line := ':'||major_tag||'.'
              ||maj@.name;               (* init line with major tag *)
   min := maj@.first ;                   (* start with first minor   *)
   WHILE min ^= nil DO                   (* loop thru all tags       *)
   BEGIN
      IF min@.minvalue@ ^= '' THEN       (* empty tags not shown     *)
      BEGIN
         IF min@.name = 'cks' THEN
         BEGIN
            Writestr(tag,' :cks.',maj@.checksum:-5);
            tag:=trim(tag);
            checksum_needed := FALSE     (* Don't show it twice      *)
         END ELSE
                                         (* create tag image         *)
            tag := ' :'||min@.name||'.'||min@.minvalue@;
 
         IF length(line) + length(tag) >= infolinemax THEN
         BEGIN                           (* doesn't fit in line      *)
            Writeln(newbase,line) ;      (* dump previous tags first *)
            line := '    ' ;             (* init new line            *)
         END ;
         line :=  line||tag ;            (* append tag to line       *)
      END ;
      min := min@.next                   (* try next tag             *)
   END ;
                                         (* add a cks if needed      *)
   IF checksum_needed THEN
   BEGIN
      Writestr(tag,' :cks.',maj@.checksum:-5); tag:=trim(tag);
      IF length(line) + length(tag) >= infolinemax THEN
      BEGIN
         Writeln(newbase,line) ;         (* checksum needs some place*)
         line := '    ';
      END ;
   END
   ELSE tag := '';
 
   Writeln(newbase,line,tag) ;           (* last line and end        *)
(* sermon_line('Entry '||tn(maj@.name),1,8)||' done'); *)
END (* show_maj *) ;
(*********************************************************************)
(*                                                                   *)
(*   This PROCEDURE reports the status of a major                    *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE report_maj(maj:major_pointer;message:STRING(255));
BEGIN
   IF maj ^= Nil THEN
      sermon_line('Entry '||tn(maj@.name)||' '||message);
END (* report_maj *);
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION parses a line and merges minor entries.  *)
(*   Most of the code has been stolen from Roland Wolf's             *)
(*   GENROUTS program.                                               *)
(*                                                                   *)
(*********************************************************************)
FUNCTION parselin(VAR line : STRING(255);maj : major_pointer):BOOLEAN;
VAR
     tag           : STRING(255);      (* "tag" of an entry          *)
     tagend        : INTEGER;          (* marks END of tag           *)
     tagstart      : INTEGER;          (* marks start of tag         *)
     tagval        : STRING(255);      (* value of the tag           *)
     tagvalend     : INTEGER;          (* marks END of that value    *)
     min           : minor_pointer;
BEGIN
  tagvalend:= 2;
  parselin := True;
  REPEAT                           (* parse a line                   *)
    IF line = '' THEN LEAVE;
    IF tagvalend = 2 THEN          (* parse ':tag.tagvalue'          *)
       tagstart := index(substr(line,1,length(line)),':')
    ELSE
       tagstart := index(substr(line,tagvalend-1,length(line)
                 - tagvalend + 2),' :') + tagvalend - 1;
    tagend   := index(substr(line,tagstart,length(line)
                - tagstart + 1),'.') + tagstart - 1;
    tagvalend:= index(substr(line,tagend  ,length(line)
                 - tagend   + 1),' :') + tagend;
    IF tagvalend = tagend THEN tagvalend := length(line) + 1;
 
    tag    := substr(line,tagstart+1,tagend-tagstart-1);
    IF tagend = length(line) THEN tagval := '' ELSE
    tagval := substr(line,tagend+1,tagvalend-tagend-1);
                                   (* OK, we have 'tag' and 'tagval' *)
 
    tagval := trim(tagval) ;
    IF tag = major_tag THEN
    BEGIN
       parselin := False;
       RETURN;
    END ;
    min := misearch(maj,tag,tagval);
  UNTIL tagvalend = length(line) + 1;
  line := ''
END (* parselin *) ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following routines support parsing the base file.           *)
(*                                                                   *)
(*********************************************************************)
VAR
   oldbase : TEXT ;            (* inputfile                          *)
   baseline : STRING(255) ;
 
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION checks for a major tag.                  *)
(*   It is aclled only at "line start".                              *)
(*                                                                   *)
(*********************************************************************)
FUNCTION havenick(line:STRING(255)):BOOLEAN;
BEGIN
havenick:=(length(line) >= major_tag_length+2)
        & (substr(line,1,1) = ':')
        & (substr(line,2,major_tag_length) = major_tag)
        & ((substr(line,2+major_tag_length,1) = '.')
          |(substr(line,2+major_tag_length,1) = ' '))
END (*have nick*) ;
 
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE read a line from the base.              *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE getbase;
BEGIN
   IF NOT Eof(oldbase) THEN Readln(oldbase,baseline);
   baseline := trim(ltrim(baseline))
END ;
 
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION merges all minor tags                    *)
(*   into a data base entry. In fact the "merge" may just an addition*)
(*   because only new entries are added. BUT: if the base would      *)
(*   contain DUPLICATE minor tags the last one would be used.        *)
(*                                                                   *)
(*********************************************************************)
 
FUNCTION mrgebase(maj:major_pointer):BOOLEAN;
VAR lineok: BOOLEAN;
BEGIN
   lineok:= parselin(baseline,maj) ;
   WHILE (lineok & NOT Eof(oldbase)) DO
   BEGIN
      getbase;
      IF havenick(baseline) THEN LEAVE ;
      lineok:= parselin(baseline,maj) ;
   END ;
   IF ^lineok THEN
      showerror('Major tag not at beginning of line in old base',
              major_tag_not_at_beginning);
   mrgebase:=lineok ;
END (*mrgebase*);
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE skips minor tags from the base file     *)
(*   up to the next major.                                           *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE skipbase;
BEGIN
   WHILE (NOT Eof(oldbase) & NOT havenick(baseline)) DO
      getbase;
END (* skipbase *);
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE skips over a major tag in the base file.*)
(*   We already know that there is a major tag (node|nick). This     *)
(*   is skipped ande the value is extracted.                         *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE initbase(VAR basenode: STRING(64));
BEGIN
   IF (basenode = '') THEN
   BEGIN
      IF length(baseline) <= major_tag_length+2
      THEN basenode := '' ELSE
      BEGIN
         baseline :=
         ltrim(substr(baseline,
                       major_tag_length+3,
                      length(baseline)-major_tag_length-2))
               ||' ';
         Readstr(baseline,basenode:index(baseline,' ')-1,baseline)
      END
   END
END (*initbase*);
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following routines support parsing the delta file.          *)
(*                                                                   *)
(*********************************************************************)
VAR
   delta : TEXT ;              (* update file                        *)
   dltaline : STRING(255) ;
 
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION checks whether we have a new action.     *)
(*   It is called only on "line start".                              *)
(*   Currently only the entry actions are known here.                *)
(*   Other actions (NEWBASE etc) are unknown. They are not used      *)
(*   right now.                                                      *)
(*                                                                   *)
(*********************************************************************)
FUNCTION haveact(line:STRING(255)):BOOLEAN;
BEGIN
haveact:=(length(line) >= 4) &
        ((substr(line,1,4) = 'DEL ')
        |(substr(line,1,4) = 'REP ')
        |(substr(line,1,4) = 'ADD '))
END (* have act *) ;
 
FUNCTION have_updnodes(line:STRING(255)):BOOLEAN;
BEGIN
have_updnodes:=(length(line) >= 11) &
        (substr(line,1,9) = 'UPDNODES(')
END (* have updnodes *) ;
 
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE reads a line from the delta file        *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE getdelta;
BEGIN
   IF ^Eof(delta) THEN Readln(delta,dltaline);
      dltaline := trim(ltrim(dltaline))
END (*getdelta*);
 
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION merges minor tags from the delta file    *)
(*   into a data base entry.                                         *)
(*                                                                   *)
(*********************************************************************)
FUNCTION mrgedlta(maj:major_pointer):BOOLEAN;
VAR lineok: BOOLEAN;
BEGIN
   lineok:=parselin(dltaline,maj) ;
   WHILE (lineok & NOT Eof(delta)) DO
   BEGIN
      getdelta;
      IF haveact(dltaline) THEN LEAVE ;
      lineok:=parselin(dltaline,maj) ;
   END ;
   IF ^lineok THEN
   showerror('Minor tag in delta identical to major tag '||major_tag,
              minor_identical_to_major);
   mrgedlta:=lineok
END (*mrgedlta*);
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE skips minor tags from the delta file    *)
(*   up to the next action.                                          *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE skipdlta;
BEGIN
   WHILE (NOT Eof(delta) & NOT haveact(dltaline)) DO
      getdelta;
END (*skipdlta*);
(*********************************************************************)
(*                                                                   *)
(*   The following FUNCTION skips over the major tag that MUST       *)
(*   follow after an action: "action :majortagname. tagvalue"        *)
(*                                                                   *)
(*********************************************************************)
FUNCTION initdlta(VAR dltanode: STRING(64);
                  VAR action  : STRING(20)
                 ):BOOLEAN;
VAR
   action_length : INTEGER ;
BEGIN
   initdlta := TRUE ;
   IF (dltanode = '') & (dltaline^='') THEN
   BEGIN
      action_length := index(dltaline,' ');
      action := substr(dltaline,1,action_length-1);
      (* after a valid action there is always an entry spec *)
      dltaline := ltrim(substr(dltaline,action_length+1,
                               length(dltaline)-action_length));
      IF dltaline ^= '' THEN
      BEGIN
         dltaline := dltaline||' ';
         Readstr(dltaline,dltanode:index(dltaline,' ')-1,dltaline);
      END ELSE BEGIN
         showerror('Value missing for action '||action,
                   value_missing_for_action);
         initdlta := FALSE ;
      END
   END
END (* initdlta *);
%page ;
(*********************************************************************)
(*                                                                   *)
(*   The following PROCEDURE merges a network data base file         *)
(*   with an update file and creates a new network file.             *)
(*                                                                   *)
(*   Actually this *IS* the main program.                            *)
(*                                                                   *)
(*********************************************************************)
PROCEDURE mergenet ;
LABEL leave_it;
VAR
   basevers_deleted : BOOLEAN ;
   basevers : major_pointer ;
   dltavers : major_pointer ;
   baselink : major_pointer ;
   dltalink : major_pointer ;
   basenode          : STRING(64) ;
   dltanode          : STRING(64) ;
   previous_basenode : STRING(64) ;
   previous_dltanode : STRING(64) ;
   old_checksum : INTEGER ;
   new_checksum : INTEGER ;
   action   : STRING(20);
 
   active_major : major_pointer ;
   active_minor : minor_pointer ;
STATIC
   of_new_base: STRING(255) ;
   of_old_base: STRING(255) ;
VALUE
   of_new_base := 'of new base';
   of_old_base := 'of old base';
BEGIN
(*********************************************************************)
(*                                                                   *)
(*   Initialize all files.                                           *)
(*   Verify old base and delta file.                                 *)
(*                                                                   *)
(*********************************************************************)
   Rewrite(newbase,'DDNAME=NEW');
(*********************************************************************)
(*                                                                   *)
(* Try initialize DELTA: Must be non empty, and contain at least     *)
(* one action ADD REP DEL.                                           *)
(*                                                                   *)
(*********************************************************************)
 
   Reset(delta);
                                            (* Verify delta start    *)
   IF Eof(delta) THEN
      showerror('Delta empty',delta_empty) ;
(* ELSE
   sermon_line('Note: NEWBASE, NEWVERSION actions are ignored.')*) ;
 
                             (* process initial actions              *)
                             (* I still don't like NEWVERSION etc.   *)
   WHILE (NOT Eof(delta) & NOT haveact(dltaline)) DO
   BEGIN
      IF have_updnodes(dltaline) THEN
      BEGIN
         dltaline:=
            Ltrim(trim(substr(dltaline,10,length(dltaline)-10)));
         IF ((dltaline ^= '') & (dltaline > this_updnodes)) THEN
         BEGIN
            showerror('This UPDNODES is not smart enough, '
               ||' this delta file requires at least version:'
               ||dltaline,
                 updnodes_not_smart_enough);
            goto leave_it;
         END
      END ;
      getdelta
   END ;
 
   IF Eof(delta) THEN
     showerror('Delta does not contain any known ACTION.',delta_empty);
 
   dltanode := '';
   dltavers:= nil;
   dltalink:= nil;
   action  := '';
 
(*********************************************************************)
(*                                                                   *)
(* Try initialize BASE: Must be non empty, and the first tag will be *)
(* used as major tag (which must always occur at the beginning of    *)
(* a new line in base.                                               *)
(*                                                                   *)
(*********************************************************************)
 
   Reset(oldbase,'DDNAME=OLD');
   getbase;
   IF (length(baseline) < 3)
     |(substr(baseline,1,1) ^= ':')
     |(substr(baseline,2,1)  = '.')
     |(substr(baseline,2,1)  = ' ') THEN
   BEGIN
      showerror('No major in data base',
                no_major_in_data_base);
      GOTO leave_it
   END ;
 
   major_tag_length := index(baseline,'.');
   IF major_tag_length = 0 THEN
   BEGIN
      major_tag_length := index(baseline,' ');
      IF major_tag_length = 0 THEN
         major_tag_length := length(baseline)+1
   END ;
   IF major_tag_length > 64+2 THEN
   BEGIN
      showerror('Major tag too long',
                major_tag_too_long);
      GOTO leave_it
   END ;
   major_tag_length := major_tag_length - 2;
   major_tag:=substr(baseline,2,major_tag_length);
 
   basenode := '';
   old_checksum := 0 ;
   basevers:= nil;
   baselink:= nil;
 
 
 
%page ;
(*********************************************************************)
(*                                                                   *)
(*   process version and links entry first, they are not in          *)
(*   alphabetic order.                                               *)
(*                                                                   *)
(*   Try get VERSION and LINKS entry from OLDBASE                    *)
(*   VERSnnnn must always be present (not checked)                   *)
(*   LINKSnnn entry may be missing.                                  *)
(*                                                                   *)
(*********************************************************************)
 
   new_checksum := 0 ;
   initbase(basenode);
   IF basenode ^= '' THEN BEGIN
      basevers := masearch(basevers,basenode);
      IF ^mrgebase(basevers) THEN GOTO leave_it;
      val_maj(basevers,of_old_base,old_checksum) ;
      basenode := '';
 
      initbase(basenode);
      IF (basenode ^= '') & (substr(basenode,1,4) = 'LINK')
      THEN BEGIN
         baselink := masearch(baselink,basenode);
         IF ^mrgebase(baselink) THEN GOTO leave_it;
         val_maj(baselink,of_old_base,old_checksum) ;
         basenode := '';
         initbase(basenode);
      END ;
   END ;
(*********************************************************************)
(*                                                                   *)
(*   process version and links entry first, they are not in          *)
(*   alphabetic order.                                               *)
(*                                                                   *)
(*********************************************************************)
   basevers_deleted := FALSE;
   WHILE (initdlta(dltanode,action))        (* try parse next action *)
       & (dltanode^='')                     (* more input?           *)
       & ((dltavers=nil)
         |(dltalink=nil)
         |(NOT basevers_deleted)
         |(baselink^=nil))                  (* prefix not yet done   *)
   DO
   BEGIN
       IF (length(dltanode) < 4) |
       ( (substr(dltanode,1,4) ^= 'LINK')
       & (substr(dltanode,1,4) ^= 'VERS'))
      THEN LEAVE ;
%page ;
(*********************************************************************)
(*                                                                   *)
(*   Process a delete action for LINKSnnn or VERSnnnn                *)
(*   Note: The base entry is NOT deleted, it will be used later to   *)
(*   compare the total checksum.                                     *)
(*                                                                   *)
(*********************************************************************)
      IF action = 'DEL' THEN
      BEGIN
         IF (NOT basevers_deleted) & (basevers@.name=dltanode) THEN
         BEGIN
            IF ^mrgedlta(basevers) THEN GOTO leave_it;
            report_maj(basevers,'deleted') ;
            basevers_deleted := TRUE
 
         END ELSE IF (baselink^=nil) & (baselink@.name=dltanode) THEN
         BEGIN
            IF ^mrgedlta(baselink) THEN GOTO leave_it;
            report_maj(baselink,'deleted') ;
            majdel(baselink,'')
 
         END ELSE BEGIN
            showerror('Old base out of sort order',
                      old_base_out_of_sort_order);
            GOTO leave_it
         END ;
         dltanode := '';
      END
(*********************************************************************)
(*                                                                   *)
(*   Process a REP action for LINKSnnn or VERSnnnn                   *)
(*   Note: We still need the total checksum entry from the old base  *)
(*   therefore a temporary entry is created.                         *)
(*                                                                   *)
(*********************************************************************)
      ELSE IF action = 'REP' THEN
      BEGIN
         IF (NOT basevers_deleted) & (basevers@.name=dltanode) THEN
         BEGIN
            dltavers := basevers ;
            basevers := nil;
            basevers := masearch(basevers,dltanode);
            active_minor := minfind(dltavers,'totcks','');
            active_minor :=
               misearch(basevers,'totcks',active_minor@.minvalue@);
            IF ^mrgedlta(dltavers) THEN GOTO leave_it;
            val_maj(dltavers,of_new_base,new_checksum) ;
            report_maj(dltavers,'updated')
         END ELSE IF (baselink^=nil) & (baselink@.name=dltanode) THEN
         BEGIN
            dltalink := baselink ;
            baselink := nil;
            IF ^mrgedlta(dltalink) THEN GOTO leave_it;
            val_maj(dltalink,of_new_base,new_checksum) ;
            report_maj(dltalink,'updated')
         END ELSE BEGIN
            showerror('Old base out of sort order',
                      old_base_out_of_sort_order);
            GOTO leave_it
         END ;
         dltanode := '';
      END
(*********************************************************************)
(*                                                                   *)
(*   Process an ADD action for LINKSnnn or VERSnnnn                  *)
(*   Note: The actions must occur AFTER the DELETE actions for the   *)
(*   old entries.                                                    *)
(*                                                                   *)
(*********************************************************************)
 
      ELSE IF action = 'ADD' THEN
      BEGIN
         IF (substr(dltanode,1,4)='VERS')
          & (basevers_deleted) & (dltavers=nil) THEN
         BEGIN
            dltavers := masearch(dltavers,dltanode);
            IF ^mrgedlta(dltavers) THEN GOTO leave_it;
            val_maj(dltavers,of_new_base,new_checksum) ;
            report_maj(dltavers,'added')
         END
         ELSE IF (substr(dltanode,1,4)='LINK')
              & (baselink=nil) & (dltalink=nil) THEN
         BEGIN
            dltalink := masearch(dltalink,dltanode);
            IF ^mrgedlta(dltalink) THEN GOTO leave_it;
            val_maj(dltalink,of_new_base,new_checksum) ;
            report_maj(dltalink,'added')
         END
         ELSE BEGIN
            showerror('Invalid delta start',
                      invalid_delta_start);
            GOTO leave_it
         END ;
         dltanode := '';
      END
%page;
(*********************************************************************)
(*                                                                   *)
(*   SNO actions for VERSnnnn and LINKSnnn.                          *)
(*                                                                   *)
(*********************************************************************)
       ELSE BEGIN
          showerror('action' ||action||
                    ' invalid in delta prefix '||tn(dltanode),
                     action_invalid);
          GOTO leave_it
       END ;
    END ;
 
(*********************************************************************)
(*                                                                   *)
(*   After the "prolog" now show the VERSnnnn entry and              *)
(*   the LINKSnnn entry.                                             *)
(*   IF no delta vers/link show old base entries instead             *)
(*                                                                   *)
(*********************************************************************)
 
   IF dltavers = nil THEN
   BEGIN
      val_maj(basevers,of_new_base,new_checksum) ;
      report_maj(basevers,'unchanged');
      show_maj(basevers)
   END
   ELSE show_maj(dltavers);
 
   IF dltalink = nil THEN
   BEGIN
      val_maj(baselink,of_new_base,new_checksum) ;
      report_maj(baselink,'unchanged');
      show_maj(baselink) ;
   END
   ELSE show_maj(dltalink);
%page ;
(*********************************************************************)
(*                                                                   *)
(*   now we process normal entries                                   *)
(*                                                                   *)
(*********************************************************************)
   previous_basenode := '';
   previous_dltanode := '';
   active_major := nil ;
   REPEAT
(*********************************************************************)
(*                                                                   *)
(*   extract node name of a new base entry and action/nodename from  *)
(*   delta IF a new entry is to be processed. initdlta returns       *)
(*   FALSE IF there is no :node. tag behind action.                  *)
(*                                                                   *)
(*********************************************************************)
 
      IF (dltanode = '') |
         ((basenode ^= '') & (dltanode > basenode)) THEN
(*********************************************************************)
(*                                                                   *)
(*       A base node is pending                                      *)
(*                                                                   *)
(*********************************************************************)
      BEGIN
         IF previous_basenode >= basenode THEN
            showerror('Entry '||tn(basenode)
            ||' in old base is out of sort order, previous entry was: '
            ||previous_basenode,
            old_base_out_of_sort_order)
         ELSE BEGIN
            active_major := masearch(active_major,basenode);
            IF ^mrgebase(active_major) THEN GOTO leave_it;
            val_maj(active_major,of_old_base,old_checksum);
            val_maj(active_major,of_new_base,new_checksum);
            show_maj(active_major);
            report_maj(active_major,'unchanged')
         END ;
         majdel(active_major,'');
         previous_basenode := basenode ;
         basenode := '';
         skipbase ;
      END
      ELSE IF (basenode = '') | (dltanode < basenode) THEN
(*********************************************************************)
(*                                                                   *)
(*       A delta node is pending                                     *)
(*                                                                   *)
(*********************************************************************)
      BEGIN
         IF previous_dltanode >= dltanode THEN
            showerror('Entry '||tn(dltanode)
            ||' in delta is out of sort order, previous entry was: '
            ||previous_dltanode,
              delta_out_of_sort_order) ;
         IF action = 'ADD' THEN
         BEGIN
            active_major := masearch(active_major,dltanode);
            IF ^mrgedlta(active_major) THEN GOTO leave_it;
            val_maj(active_major,of_new_base,new_checksum);
            show_maj(active_major);
            report_maj(active_major,'added')
         END ELSE
            showerror('Entry '||tn(dltanode)||
                      'does not exist, action '||action||' ignored',
                     action_invalid);
         majdel(active_major,'');
         previous_dltanode := dltanode ;
         dltanode := '';
         skipdlta ;
      END
      ELSE BEGIN
%page ;
(*********************************************************************)
(*                                                                   *)
(*       base and delta equal                                        *)
(*                                                                   *)
(*********************************************************************)
         IF previous_basenode >= basenode THEN
            showerror('Entry '||tn(basenode)
            ||' in old base is out of sort order, previous entry was: '
            ||previous_basenode,
            old_base_out_of_sort_order)
         ELSE IF previous_dltanode >= dltanode THEN
            showerror('Entry '||tn(dltanode)
            ||' in delta is out of sort order, previous entry was: '
            ||previous_dltanode,
              delta_out_of_sort_order)
         ELSE IF action = 'ADD' THEN
            showerror('Entry '||tn(basenode)
                    ||' already exists, action ADD ignored',
                    action_invalid)
         ELSE BEGIN
            active_major := masearch(active_major,basenode);
            IF ^mrgebase(active_major) THEN GOTO leave_it;
            val_maj(active_major,of_old_base,old_checksum);
            IF ^mrgedlta(active_major) THEN GOTO leave_it;
            IF action = 'REP' THEN BEGIN
               val_maj(active_major,of_new_base,new_checksum);
               show_maj(active_major);
               report_maj(active_major,'updated')
            END ELSE IF action = 'DEL' THEN
               report_maj(active_major,'deleted')
         END ;
         majdel(active_major,'');
         previous_basenode := basenode ;
         basenode := '';
         skipbase ;
         previous_dltanode := dltanode ;
         dltanode := '';
         skipdlta ;
      END ;
(*********************************************************************)
(*                                                                   *)
(*   try get next entries from delta and/or oldbase                  *)
(*                                                                   *)
(*********************************************************************)
      initbase(basenode);
   UNTIL (NOT initdlta(dltanode,action))|
        ((basenode = '') & (dltanode = ''));
 
(*********************************************************************)
(*                                                                   *)
(*   finally, validate total checksum and Close all files.           *)
(*                                                                   *)
(*********************************************************************)
 
   valtotal(basevers,old_checksum,'of old base');
   valtotal(dltavers,new_checksum,'of new base');
 
   Writeln(newbase,'') ;                       (* GENROUTS needs that*)
leave_it:
   Close(delta);
   Close(oldbase);
   Close(newbase);
END (* mergenet *);
%page ;
(*********************************************************************)
(*                                                                   *)
(*   At the end the main program, believe it, that's all.            *)
(*                                                                   *)
(*********************************************************************)
BEGIN
   init_environment ;
   sermon_line(name_version_date||' started');
   mergenet ;
abort_updnodes:
   set_retcode ;
   sermon_line(name_version_date||' ended');
END (* updnodes *)
