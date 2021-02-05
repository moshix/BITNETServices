/* --------------------------------------------------------------------
 * ELIZA User's input and construct Reply
 * --------------------------------------------------------------------
 */
Eliza:
  parse upper arg question
  if elizaActive<>'ACTIVE' then call ElizaInit
  yrquestion=cleanse(question)
  if yrquestion=-8 then return -8
  if yrquestion=lastquestion then do
     return _response "You keep repeating yourself..."
  end
/* .... Find Keyword .... */
  foundkeyword=''
  do k=1 to keywords.0
     ppos=pos(keywords.k,yrquestion)
     if ppos=0 then iterate
     foundkeyword=keywords.k
     leave
  end
  conjustr=''
  if foundkeyword='' then k=36
     else conjustr=conjugate(yrquestion,foundkeyword,ppos)
return reply(k,foundkeyword,conjustr)
/* --------------------------------------------------------------------
 * Construct Reply
 * --------------------------------------------------------------------
 */
reply:
  parse arg k,foundkw,constr
  if foundkw='' then return "YOU WILL HAVE TO ELABORATE MORE FOR ME TO HELP YOU"
  xr=r.k
  foundanswer = answers.xr
  r.k=r.k+1
  if r.k>n.k then r.k=s.k
  lastquestion=yrquestion
  if right(foundanswer,1)="*" then  ,
     return space(substr(foundanswer,1,length(foundanswer)-1)' 'conjustr,1)
return foundanswer
/* --------------------------------------------------------------------
 * Cleanse Question, remove punctuation marks
 * --------------------------------------------------------------------
 */
cleanse:
  yrquestion=translate(arg(1),'','.,;:?!')
  if pos('shut',yrquestion)>0 then return -8
return yrquestion
/* --------------------------------------------------------------------
 * TAKE PART OF STRING AND CONJUGATE IT
 * --------------------------------------------------------------------
 */
conjugate:
  parse arg yrquestion,foundkeyword,l
  conjustr=" "right(yrquestion,length(yrquestion)-length(foundkeyword)-l+1)" "
  do l=1 to words(conjustr)
     wrd=word(conjustr,l)
     do x=1 to conjugations.0/2
        if wrd=wordin.x then conjustr=wordreplace(wordout.x,conjustr,l)
     end
  end
return space(conjustr,1)
/* --------------------------------------------------------------------
 * WordReplace(newword,string,wordnumber-toreplace)
 * --------------------------------------------------------------------
 */
wordreplace:
  parse arg _r,_s,_w
  _p=wordindex(_s,_w)
  if _p<1 then return _s
return substr(_s,1,_p-1)_r' 'substr(_s,_p+wordlength(_s,_w)+1)
/* --------------------------------------------------------------------
 * Load Tables
 * --------------------------------------------------------------------
 */
loadTable:
  keywords.0=49
  keywords.1 ="CAN YOU"
  keywords.2 ="CAN I"
  keywords.3 ="YOU ARE"
  keywords.4 ="YOU'RE"
  keywords.5 ="I DON'T"
  keywords.6 ="I FEEL"
  keywords.7 ="WHY DON'T YOU"
  keywords.8 ="WHY CAN'T I"
  keywords.9 ="ARE YOU"
  keywords.10="I CAN'T"
  keywords.11="I AM"
  keywords.12="I'M"
  keywords.13="YOU"
  keywords.14="I WANT"
  keywords.15="WHAT"
  keywords.16="HOW"
  keywords.17="WHO"
  keywords.18="WHERE"
  keywords.19="WHEN"
  keywords.20="WHEN"
  keywords.21="WHY"
  keywords.22="NAME"
  keywords.23="CAUSE"
  keywords.24="SORRY"
  keywords.25="DREAM"
  keywords.26="HELLO"
  keywords.27="HI"
  keywords.28="MAYBE"
  keywords.29="YOUR"
  keywords.30="ALWAYS"
  keywords.31="THINK"
  keywords.32="ALIKE"
  keywords.33="YES"
  keywords.34="FRIEND"
  keywords.35="DATA"
  keywords.36="COMPUTER"
  keywords.37="CORONA"
  keywords.38="COVID"
  keywords.39="FACEBOOK"
  keywords.40="TWITTER"
  keywords.41="SOCIAL"
  keywords.42="EMAIL"
  keywords.43="PHONE"
  keywords.44="TWEET"
  keywords.45="WHATSAPP"
  keywords.46="WORK"
  keywords.47="HOME"
  keywords.48="WIFE"
  keywords.49="HUSBAND"

  conjugations.0=18
  conjugations.1 ="ARE"
  conjugations.2 ="AM"
  conjugations.3 ="WERE"
  conjugations.4 ="WAS"
  conjugations.5 ="YOU"
  conjugations.6 ="I"
  conjugations.7 ="YOUR"
  conjugations.8 ="MY"
  conjugations.9 ="I'VE"
  conjugations.10="YOU'VE"
  conjugations.11="YOU'VE"
  conjugations.12="ME"
  conjugations.13="YOU"
  conjugations.14="YY'ALL"
  conjugations.15="THEY"
  conjugations.16="WE"
  conjugations.17="ME"
  conjugations.18="YOU"

  answers.0 = 112
  answers.1 ="DON'T YOU BELIEVE THAT I CAN*"
  answers.2 ="PERHAPS YOU WOULD LIKE TO BE LIKE ME*"
  answers.3 ="YOU WANT ME TO BE ABLE TO*"
  answers.4 ="PERHAPS YOU DON'T WANT TO*"
  answers.5 ="DO YOU WANT TO BE ABLE TO*"
  answers.6 ="WHAT MAKES YOU THINK I AM*"
  answers.7 ="DOES IT PLEASE YOU TO BELIEVE I AM*"
  answers.8 ="PERHAPS YOU WOULD LIKE TO BE*"
  answers.9 ="DO YOU SOMETIMES WISH YOU WERE*"
  answers.10="DON'T YOU REALLY*"
  answers.11="WHY DON'T YOU*"
  answers.12="DO YOU WISH TO BE ABLE TO*"
  answers.13="DOES THAT TROUBLE YOU*"
  answers.14="DO YOU OFTEN FEEL*"
  answers.15="DO YOU OFTEN FEEL*"
  answers.16="DO YOU ENJOY FEELING*"
  answers.17="DO YOU REALLY BELIEVE I DON'T*"
  answers.18="PERHAPS IN GOOD TIME I WILL*"
  answers.19="DO YOU WANT ME TO*"
  answers.20="DO YOU THINK YOU SHOULD BE ABLE TO*"
  answers.21="WHY CAN'T YOU*"
  answers.22="WHY ARE YOU INTERESTED IN WHETHER OR NOT I AM*"
  answers.23="WOULD YOU PREFER IF I WERE NOT*"
  answers.24="PERHAPS IN YOUR FANTASIES I AM*"
  answers.25="HOW DO YOU KNOW YOU CAN'T*"
  answers.26="HAVE YOU TRIED?"
  answers.27="PERHAPS YOU CAN NOW*"
  answers.28="DID YOU COME TO ME BECAUSE YOU ARE*"
  answers.29="HOW LONG HAVE YOU BEEN*"
  answers.30="DO YOU BELIEVE IT IS NORMAL TO BE*"
  answers.31="DO YOU ENJOY BEING*"
  answers.32="WE WERE DISCUSSING YOU--NOT ME."
  answers.33="OH, I*"
  answers.34="YOU'RE NOT REALLY TALKING ABOUT ME, ARE YOU?"
  answers.35="WHAT WOULD IT MEAN TO YOU IF YOU GOT*"
  answers.36="WHY DO YOU WANT*"
  answers.37="SUPPOSE YOU SOON GOT*"
  answers.38="WHAT IF YOU NEVER GOT*"
  answers.39="I SOMETIMES ALSO WANT*"
  answers.40="WHY DO YOU ASK?"
  answers.41="DOES THAT QUESTION INTEREST YOU?"
  answers.42="WHAT ANSWER WOULD PLEASE YOU THE MOST?"
  answers.43="WHAT DO YOU THINK?"
  answers.44="ARE SUCH QUESTIONS ON YOUR MIND OFTEN?"
  answers.45="WHAT IS IT THAT YOU REALLY WANT TO KNOW?"
  answers.46="HAVE YOU ASKED ANYONE ELSE?"
  answers.47="HAVE YOU ASKED SUCH QUESTIONS BEFORE?"
  answers.48="WHAT ELSE COMES TO MIND WHEN YOU ASK THAT?"
  answers.49="NAMES DON'T INTEREST ME."
  answers.50="I DON'T CARE ABOUT NAMES --PLEASE GO ON."
  answers.51="IS THAT THE REAL REASON?"
  answers.52="DON'T ANY OTHER REASONS COME TO MIND?"
  answers.53="DOES THAT REASON EXPLAIN ANYTHING ELSE?"
  answers.54="WHAT OTHER REASONS MIGHT THERE BE?"
  answers.55="PLEASE DON'T APOLOGIZE!"
  answers.56="APOLOGIES ARE NOT NECESSARY."
  answers.57="WHAT FEELINGS DO YOU HAVE WHEN YOU APOLOGIZE?"
  answers.58="DON'T BE SO DEFENSIVE!"
  answers.59="WHAT DOES THAT DREAM SUGGEST TO YOU?"
  answers.60="DO YOU DREAM OFTEN?"
  answers.61="WHAT PERSONS APPEAR IN YOUR DREAMS?"
  answers.62="ARE YOU DISTURBED BY YOUR DREAMS?"
  answers.63="HOW DO YOU DO ...PLEASE STATE YOUR PROBLEM."
  answers.64="YOU DON'T SEEM QUITE CERTAIN."
  answers.65="WHY THE UNCERTAIN TONE?"
  answers.66="CAN'T YOU BE MORE POSITIVE?"
  answers.67="YOU AREN'T SURE?"
  answers.68="DON'T YOU KNOW?"
  answers.69="ARE YOU SAYING NO JUST TO BE NEGATIVE?"
  answers.70="YOU ARE BEING A BIT NEGATIVE."
  answers.71="WHY NOT?"
  answers.72="ARE YOU SURE?"
  answers.73="WHY NO?"
  answers.74="WHY ARE YOU CONCERNED ABOUT MY*"
  answers.75="WHAT ABOUT YOUR OWN*"
  answers.76="CAN YOU THINK OF A SPECIFIC EXAMPLE?"
  answers.77="WHEN?"
  answers.78="WHAT ARE YOU THINKING OF?"
  answers.79="REALLY, ALWAYS?"
  answers.80="DO YOU REALLY THINK SO?"
  answers.81="BUT YOU ARE NOT SURE YOU*"
  answers.82="DO YOU DOUBT YOU*"
  answers.83="IN WHAT WAY?"
  answers.84="WHAT RESEMBLANCE DO YOU SEE?"
  answers.85="WHAT DOES THE SIMILARITY SUGGEST TO YOU?"
  answers.86="WHAT OTHER CONNECTIONS DO YOU SEE?"
  answers.87="COULD THERE REALLY BE SOME CONNECTION?"
  answers.88="HOW?"
  answers.89="YOU SEEM QUITE POSITIVE."
  answers.90="ARE YOU SURE?"
  answers.91="I SEE."
  answers.92="I UNDERSTAND."
  answers.93="WHY DO YOU BRING UP THE TOPIC OF FRIENDS?"
  answers.94="DO YOUR FRIENDS WORRY YOU?"
  answers.95="DO YOUR FRIENDS PICK ON YOU?"
  answers.96="ARE YOU SURE YOU HAVE ANY FRIENDS?"
  answers.97="DO YOU IMPOSE ON YOUR FRIENDS?"
  answers.98="PERHAPS YOUR LOVE FOR FRIENDS WORRIES YOU."
  answers.99="DO COMPUTERS WORRY YOU?"
  answers.100 ="ARE YOU TALKING ABOUT ME IN PARTICULAR?"
  answers.101 ="ARE YOU FRIGHTENED BY MACHINES?"
  answers.102 ="WHY DO YOU MENTION COMPUTERS?"
  answers.103 ="WHAT DO YOU THINK MACHINES HAVE TO DO WITH YOUR PROBLEM?"
  answers.104 ="DON'T YOU THINK COMPUTERS CAN HELP PEOPLE?"
  answers.105 ="WHAT IS IT ABOUT MACHINES THAT WORRIES YOU?"
  answers.106 ="SAY, DO YOU HAVE ANY PSYCHOLOGICAL PROBLEMS?"
  answers.107 ="WHAT DOES THAT SUGGEST TO YOU?"
  answers.108 ="I SEE."
  answers.109 ="I'M NOT SURE I UNDERSTAND YOU FULLY."
  answers.110 ="COME COME ELUCIDATE YOUR THOUGHTS."
  answers.111 ="CAN YOU ELABORATE ON THAT?"
  answers.112 ="THAT IS QUITE INTERESTING."
  refs='1 3 4 2 6 4 6 4 10 4 14 3 17 3 20 2 22 3 25 3 '
  refs=refs' 28 4 28 4 32 3 35 5 40 9 40 9 40 9 40 9 40 9 40 9'
  refs=refs' 49 2 51 4 55 4 59 4 63 1 63 1 64 5 69 5 74 2 76 4'
  refs=refs' 80 3 83 7 90 3 93 6 99 7 106 6 '
RETURN
/* --------------------------------------------------------------------
 * Init Eliza
 * --------------------------------------------------------------------
 */
Elizainit:
  call loadTable
  elizaActive='ACTIVE'
  SAY "**************************"
  SAY "ELIZA"
  SAY "**************************"
  say "HI! I'M ELIZA. WHAT'S YOUR PROBLEM?"
  y=0
  do x = 1 to conjugations.0/2
     y=y+1
     wordin.x=conjugations.y
     y=y+1
     wordout.x=conjugations.y
  end
  y=0
  do x=1 to words(refs)/2
     y=y+1
     s.x=word(refs,y)
     y=y+1
     l=word(refs,y)
     r.x=s.x
     n.x=s.x+l-1
  end
return
