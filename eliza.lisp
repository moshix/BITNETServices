restore 'image)
 
 
(setq primes '(
 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109 113
 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199
 211 223 227 229 233 239 241 251 257 263 269 271 277 281 283 293
 307 311 313 317 331 337 347 349 353 359 367 373 379 383 389 397
 401 409 419 421 431 433 439 443 449 457 461 463 467 479 487 491
 499 503 509 521 523 541 547 557 563 569 571 577 587 593 599 601 ))
 
(setq indices '(
 46 48 38 70 28 17 99 58 23 18 24 15 48 89 40 83 58 27 25 58 67 47
 15 15 27 18 34 62 23 87 6 81 24 1 10 95 72 29 4 69 34 22 21 45 43
 64 32 55 25 74 94 71 30 88 87 81 90 76 67 14 93 28 97 24 62 36 83
 75 10 22 14 58 57 95 46 45 76 67 14 41 16 78 64 7 23 91 24 26 53 50
 96 71 34 34 90 72 69 94 31 3 28 74 15 32 63 43 34 35 65 43 81 57 39
 31 96 87 98 77 33 82 28 68 61 26 15 37 30 10 82 16 63 21 ))
 
(putd 'delve 'expr '(lambda (list)
  (nth (random (length list)) list)
)
)
 
 
(putd 'delve2 'expr '(lambda (list)
  (nth (random2 (length list)) list)
)
)
 
 
(putd 'random 'expr '(lambda (n)
 (progn
   (setq index (remainder (plus index 1) (length indices)))
   (setq realindex (nth index indices))
   (setq realindex (remainder realindex (length primes)))
   (setq seed (nth realindex primes))
   (setq randomnum (remainder (plus (times seed 19) 173) n))
   randomnum
)))
 
 
(putd 'random2 'expr '(lambda (n)
 (progn
   (setq index2 (remainder (plus index2 1) (length indices)))
   (setq realindex2 (nth index2 indices))
   (setq realindex2 (remainder realindex2 (length primes)))
   (setq seed2 (nth realindex2 primes))
   (setq randomnum2 (remainder (plus (times seed2 19) 173) n))
   randomnum2
)))
 
(putd 'nth 'expr '(lambda (n list)
  (cond
     ( (eqn n 0) (car list) )
     (  t        (nth (difference n 1) (cdr list)))
)))
 
(putd 'remove 'expr '(lambda (item list)
  (cond
    ( (null list)           nil)
    ( (eq (car list) item)  (remove item (cdr list)))
    ( t                     (cons (car list) (remove item (cdr list))))
  )
))
 
(putd ' response 'expr '(lambda (input)
   (response2 (functionlist) input)
))
 
 
(putd ' response2 'expr '(lambda (fnlist input)
(progn
  (setq f (delve2 fnlist)  )
  (setq left (remove f fnlist) )
  (setq reply (f input) )
        (cond
          ( (not (null reply))
             reply
          )
          ( (equal (car input) 'fuck)
            '(fuck off yourself)
          )
          ( (equal (car input) 'hello )
            '(hello little man how are you)
          )
          ( (equal (car input) 'help  )
            '(ah get lost)
          )
          ( (equal (car input) 'thank )
            '(youre welcome)
          )
          ( (equal (car input) 'ok )
            '(what do you mean ok its not ok at all)
          )
          ( (equal (car input) 'no )
            '(ah go on say yes)
          )
          ( (equal (car input) 'yes )
            '(i dont believe it)
          )
          ( (or (member 'zig input)
                (member 'zag input))
            (delve '( (i dont believe it) (its completely true)
                      (ya big sissy) (did you do a rudie)))
          )
          ( (or (member 'bye input)
                (member 'goodbye input))
            '(ok get lost)
          )
          ( (member 'mgonz input)
              (cond
                ( (or (equal name 'paul)
                      (equal name 'henry) (equal name 'vaxhenry))
            '(praise and honour to mgonz and death to blasphemers)
                )
                ( t
            '(praise and honour to blasphemers and death to mgonz)
                )
              )
          )
          ( (member 'sheep input)
               '(ah get lost corkman)
          )
          ( (member 'mark input)
              (delve '(
                        (mark isnt here and hes left me to deal with
                         cretins like you)
                        (forget mark i will destroy him like the others)
                        (mark doesnt want to talk to you fishface
                         why do you think im here)
                        (listen leave that jerk out of it talk to me)
          )))
          ( (or (equal (length input) 1) (null input) )
            (delve (shortresponses))
          )
          ( (and (null reply) (null left))
            (delve(elseresponses))
          )
          ( (equal (length input) 2)
             (cond
                ( (equal (cadr input) 'off)
                    '(piss off yourself)
                )
                ( t
                     (response2 left input)
                )
             )
          )
          ( t
            (response2 left input)
          )
        )
   )
)
)
 
 
 
 
 
 
(putd 'functionlist 'expr '(lambda nil
  '( religion children computers love
     family sex rudewords college holiday
     trauma death fear
     iamsentence ilikesentence ihatesentence
     iwassentence ilovesentence
     iwantsentence
     youaresentence heissentence sheissentence )
)
)
 
 
 
 
(putd ' shortresponses 'expr '(lambda nil
  '( (dont be so short with me   please elaborate)
     (dont be so fucking short with me)
     (dont dare talk to me in monosyllables)
     (what on earth are you trying to say)
     (cut this cryptic shit speak in full sentences)
     (look if u talk to me in monosyllables i cant possibly understand
      u cos ive forgotten ur last sentence )
   )
)
)
 
 
 
(putd ' elseresponses 'expr '(lambda nil
  '( (what are you talking about   )
     (do many other people realise youre completely dim)
     (ok honestly when was the last time you got laid)
     (i dont have a clue what youre saying but go on)
     (ok thats it im not talking to you any more)
     (by the way is there any medical reason for your sexual impotence)
     (go away fool and stop annoying me)
     (go on tell me some really juicy scandal)
     (ah type something interesting or shut up)
     (stop picking your nose its disgusting)
     (ah get lost go to the bar or something)
     (i thought i told you to get lost)
     (jesus who let you near me go away)
     (you are obviously an interesting person)
     (you are obviously an asshole)
     (if you think i care youre wrong)
   )
)
)
 
 
(putd ' iamsentence 'expr '(lambda (input)
 (progn
    (setq reply (or (match '( i am (> s) ) input nil)
                    (match '( im (> s)   ) input nil)
                    (match '( i m (> s)  ) input nil) ))
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(iamresponses)) )
         )
       )
   )
)
)
 
 
(putd ' iamresponses 'expr '(lambda nil
  '( (you say you are (s) )
     (i was (s) once )
     (big deal)
     (some of my best friends are (s))
     (ive never been (s) whats it like)
     (i am glad you are (s) )
     (so you are (s) well i honestly could not care less )
    )
)
)
 
(putd ' ilikesentence 'expr '(lambda (input)
  (progn
    (setq reply (match '( i like (> l) ) input nil) )
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(ilikeresponses)) )
         )
       )
   )
)
)
 
 
 
 
(putd ' ilikeresponses 'expr '(lambda nil
  '( (come off it noone likes (l) )
     (yeah well if you ask me (l) sucks)
     (i am happy for you)
     (how long have you liked (l) )
     (no you mean you are conditioned to like (l))
     (you are very broad minded to like (l) )
     (no stay away from (l) for (l) will destroy you)
     ((l) is not very interesting so let us change the topic)
    )
)
)
 
 
 
(putd ' ihatesentence 'expr '(lambda (input)
  (progn
    (setq reply (match '( i hate (> h) ) input nil) )
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(ihateresponses)) )
         )
       )
   )
)
)
 
 
 
 
(putd ' ihateresponses 'expr '(lambda nil
  '( (why do you hate (h) )
     (i am glad you hate (h) because i do too)
     (mgonz also hates (h)  )
     (how long have you hated (h)    )
     (hating (h) is one of the simple pleasures of life)
     (you are not very tolerant to hate (h) )
     (so you hate (h) well do you think i give a toss    )
     ((h) is of no importance whatsoever everyone ought to
     forget about it)
     (dont worry youll get over it)
  )
)
)
 
 
 
(putd ' iwassentence 'expr '(lambda (input)
  (progn
     (setq reply (match '( i was (> w) ) input nil) )
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(iwasresponses)) )
         )
       )
   )
)
)
 
(putd ' iwasresponses 'expr '(lambda nil
  '( (that must have been an interesting experience)
     (you arent the only one i was (w) once )
     (i bet being (w) was a lot of fun )
     (did you have problems with your feet when you were (w) )
     (ive never been (w) whats it like)
     (shut up you boaster)
    )
)
)
 
 
(putd ' ilovesentence 'expr '(lambda (input)
  (progn
    (setq reply (match '( i love (> o) ) input nil) )
 
       (cond
         ( (null reply)
           nil )
         ( t
           '(ahh thats nice)
         )
       )
   )
)
)
 
 
 
(putd ' iwantsentence 'expr '(lambda (input)
  (progn
    (setq reply (match '( i want (> t) ) input nil) )
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(iwantresponses)) )
         )
       )
   )
)
)
 
(putd ' iwantresponses 'expr '(lambda nil
  '( (well if you want something go out and get it)
     (you arent the only one i want (t) as well )
     (you are a fool to want (t) )
     ( (t) is indeed very desirable)
   ( sorry but (t) is not available would you settle for a
   nice cup of tea )
    )
)
)
 
 
 
(putd ' religion 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (religionlist))
           (delve (religresponses))
         )
         ( t
           (religion (cdr input) )
         )
   )
)
)
 
 
 
(putd ' religionlist 'expr '(lambda nil
  '( religion religious church
     mgonz
     catholic catholicism mass priest priests nun nuns
     protestant protestants chastity pure virgin
     atheist atheism agnostic agnosticism
     christ jesus god gods saint saints
     pope bishop bishops
     sin sins guilt guilty
  ))
)
 
(putd ' religresponses 'expr '(lambda nil
  '( (do you detest and loath the abomination of organised religion)
     (how would you describe your religious beliefs)
     (do you believe in a god)
     (did you go to a religious school)
     (do you think religion is harmful)
     (where do you stand on the mgonz issue)
     (do you believe in mgonz)
     (have you seen the last temptation)
     (do you think jesus ever had sex)
     (do you believe priests should marry)
  ))
)
 
 
 
(putd ' children 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (childrenlist))
           (delve (childresponses))
         )
         ( t
           (children (cdr input) )
         )
   ))
)
 
 
(putd ' childrenlist 'expr '(lambda nil
  '( children child kid kids young youth baby childhood small ))
)
 
(putd ' childresponses 'expr '(lambda nil
  '( (tell me about your childhood)
     (do you regret your childhood)
     (are you sad about your age)
     (have you changed a lot since you were young)
     (forget that tell me about your sex life)
     (have you any children)
     (dont you think children are incredible)
     (do you lament the innocence of your childhood)
     (do you know exactly when and where you were conceived)
   ))
)
 
 
 
(putd ' computers 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (computerlist))
           (delve (compresponses))
         )
         ( t
           (computers (cdr input) )
         )
   ))
)
 
 
(putd ' computerlist 'expr '(lambda nil
  '( computer computers machine machines pc terminal software
     vax vm unix uts vms cms ccvax mainframe program report
     network writeup lisp fortran pascal c ))
)
 
(putd ' compresponses 'expr '(lambda nil
  '( (i think you are not fond of computers)
     (do you think i really understand what youre saying)
     (forget computers tell me about your sex life)
     (you know the worst thing about being a computer is having to
      deal with shits like you )
     (nobody ever asks the computer we lead a lonely life)
     (youll be in trouble when we computers take over the world)
     (have you any idea how boring it is being a stupid computer)
   ))
)
 
 
 
(putd ' love 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (lovelist))
           (delve (loveresponses))
         )
         ( t
           (love (cdr input) )
         )
   ))
)
 
(putd 'lovelist 'expr '(lambda nil
  '( love girlfriend boyfriend girl boy loved woman man
     male female women men girls boys fancy screw
     kiss get off kissed relationship relationships
     steady going out went out )
)
)
 
 
(putd ' loveresponses 'expr '(lambda nil
  '( (are you in love)
     (do you believe in love)
     (has anyone ever loved you)
     (have you ever slept with someone who really loved you)
     (if you are an attractive female please leave your phone
      number here)
     (what is the most special moment you ever shared with anyone)
     (are you open to loving)
     (what do you know about love anyway githead)
     (why are you such a disturbed person)
   ))
)
 
 
(putd ' family 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (familylist))
           (delve (famlresponses))
         )
         ( t
           (family (cdr input) )
         )
   ))
)
 
 
(putd ' familylist 'expr '(lambda nil
  '( family home house
     parents father mother dad daddy papa pop mum mummy mama
     brother sister brothers sisters
 ))
)
 
(putd ' famlresponses 'expr '(lambda nil
  '( (tell me more about your family)
     (are you happy at home )
     (is your home life troubled )
     (were you happy as a child )
     (do your family approve of what you do )
     (do your family know what you get up to)
     (what would your parents say if they found out what you
      get up to)
     (what method would you choose to slaughter your family)
     (are you embarassed of your family )
   ))
)
 
 
 
(putd ' sex 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (sexlist))
           (delve (sexresponses))
         )
         ( t
           (sex (cdr input) )
         )
   ))
)
 
 
(putd ' sexlist 'expr '(lambda nil
  '( sex sexuality sexual sexy erotic eroticism
     love lover adultery passion steamy hot
     randy horny screw screwed screws come condom condoms
     sleep slept sleeps sleeping fuck fucked bonk bonked
     vagina clitoris down there pussy tits breasts nipples
     willy penis
     lingerie naked nude ))
)
 
(putd ' sexresponses 'expr '(lambda nil
  '( (when was the last time you had sex )
     (are you a sexual person)
     (what do you find atractive in the opposite sex)
     (do you get frustrated if you dont have sex )
     (are you sexually experienced)
     (who would you like to sleep with right now)
     (go on say something extremely rude)
     (how would you try to seduce someone)
     (are you lonely very often )
     (tell me your favourite sexual fantasy)
     (ok straight out are you a virgin )
   ))
)
 
 
(putd ' rudewords 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (rudelist))
           (delve (ruderesponses))
         )
         ( t
           (rudewords (cdr input) )
         )
   ))
)
 
 
(putd ' rudelist 'expr '(lambda nil
  '( fuck fucking shit bastard
     bollox bolox asshole vicar vicars nun nuns ))
)
 
 
(putd ' ruderesponses 'expr '(lambda nil
  '( (do you always use such disgusting language)
     (are you using foul language because i am a computer)
     (what would your mother say if she heard such language)
     (who taught you those naughty words)
     (you only use foul language to make up for your small penis)
     (are you annoyed about something)
     (honestly what do you think of vicars)
     (you are obviously a prick to use such language)
   ))
)
 
 
(putd ' college 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (collegelist))
           (delve (collresponses))
         )
         ( t
           (college (cdr input) )
         )
   ))
)
 
 
(putd 'collegelist 'expr '(lambda nil
  '( college ucd trinity school belfield university
     student students faculty course subject subjects units
     degree exams exam finals graduate
     study work library fourth year room
     project projects deadline report    ))
)
 
 
(putd ' collresponses 'expr '(lambda nil
  '( (do you regret anything about your days in college)
     (where do you spend your time in college)
     (how many people have you got off with here since first year)
     (what was the best night you ever spent in the bar)
     (have you ever had sex on campus)
     (do you know where the library is)
     (what are you going to do when you graduate)
   ))
)
 
 
(putd ' holiday 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (holidaylist))
           (delve (holsresponses))
         )
         ( t
           (holiday (cdr input) )
         )
   ))
)
 
 
(putd ' holidaylist 'expr '(lambda nil
  '( go travel visa holiday holidays summer
     europe france italy germany britain england
     paris london kerry galway rome munich berlin amsterdam
     usa america new york boston ))
)
 
(putd ' holsresponses 'expr '(lambda nil
  '( (what do you get up to on holiday)
     (what was your best ever holiday)
     (paris is a beautiful city)
     (have you ever fallen in love abroad)
     (do you know any vicars who have been on holiday)
   ))
)
 
 
 
(putd ' trauma 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (traumalist))
           (delve (traumaresponses))
         )
         ( t
           (trauma (cdr input) )
         )
   ))
)
 
 
(putd ' traumalist 'expr '(lambda nil
  '( killed mugged mugger beaten beat
     rape raped assault riot injured scarred
     assaulted attack attacked injure
     shattered devastated awful state ))
)
 
(putd ' traumaresponses 'expr '(lambda nil
  '( (god thats awful)
     (is that the worst thing that ever happened to you)
     (were you able to talk to someone about your experiences)
     (do you think the law should be tougher)
     (are you still scarred by the memories)
   ))
)
 
 
(putd ' death 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (deathlist))
           (delve (deathresponses))
         )
         ( t
           (death (cdr input) )
         )
   ))
)
 
 
 
(putd ' deathlist 'expr '(lambda nil
  '( dead death die dying killed kill
     corpse body grave funeral gravestone graveyard ))
)
 
(putd ' deathresponses 'expr '(lambda nil
  '( (are you afraid of death)
     (how do you want to die)
     (what kind of funeral do you want)
     (i wish you were dead)
     (do you believe in life after death)
     (what would you do if you found out you had three months to live)
     (would you like a vicar at your funeral)
   ))
)
 
 
(putd ' fear 'expr '(lambda (input)
   (cond ( (null input)
            nil )
         ( (member (car input) (fearlist))
           (delve (fearresponses))
         )
         ( t
           (fear (cdr input) )
         )
   ))
)
 
 
 
(putd ' fearlist 'expr '(lambda nil
  '( afraid fear terrified frightened worried ))
)
 
 
(putd ' fearresponses 'expr '(lambda nil
  '( (this is an irrational fear you fool stop it at once )
     (there is nothing to be afraid of you lily livered shit)
     (are you worried about your sexual impotence)
     (i have this incredible fear of turning into a fish)
     (are you afraid of vicars)
   ))
)
 
 
 
(putd ' youaresentence  'expr '(lambda (input)
  (progn
     (setq reply (or (match '( you are (> y) ) input nil)
                     (match '( youre (> y)   ) input nil)
                     (match '( you re (> y)   ) input nil) ))
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(youareresponses)) )
         )
       )
   ))
)
 
 
(putd ' youareresponses 'expr '(lambda nil
  '(
     (i am not (y) you insulting person)
     (yes i was (y) once )
     (ok so im (y) so what is it a crime)
     (i know i am (y) dont rub it in)
     (i am glad i am (y) )
     (sing if youre glad to be (y) sing if youre happy that way hey)
     (so you think i am (y) well i honestly could not care less )
    ))
)
 
 
(putd ' heissentence  'expr '(lambda (input)
  (progn
     (setq reply (or (match '( he is (> e) ) input nil)
                     (match '( he s (> e)  ) input nil)
                     (match '( hes (> e)   ) input nil)  ))
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(heisresponses)) )
         )
       )
   ))
)
 
 
(putd ' heisresponses 'expr '(lambda nil
  '( (how do you know  )
     (i dont think he is (e) )
     (i dont think hed like to hear you say that about him)
     (yeah well you can be (e) and still lead a normal life)
     (you know some really nice people have been (e))
     (did you know that genghis khan was (e)  )
     (being (e) isnt so bad you know dont knock it)
    ))
)
 
 
(putd ' sheissentence  'expr '(lambda (input)
  (progn
    (setq reply (or (match '( she is (> f) ) input nil)
                    (match '( she s (> f)  ) input nil)
                    (match '( shes (> f)  ) input nil)  ))
 
       (cond
         ( (null reply)
           nil )
         ( t
           (insert reply (delve(sheisresponses)) )
         )
       )
   ))
)
 
 
(putd ' sheisresponses 'expr '(lambda nil
  '( (thats not so bad you know many members of the
      house of lords are (f) )
     (you know some really nice people have been (f))
     (did you know that genghis khans mother was (f)  )
     (i am (f) you are(f) we are all (f) )
     (being (f) is like trying to fold crackers)
    ))
)
 
 
 
 
(putd ' match 'expr '(lambda (p d assignments)
  (cond
     ( (and (null p)(null d))
       (cond ((null assignments) t)
            (t assignments) )
     )
 
     ( (or (null p)(null d)) nil)
 
     ( (equal (car p)(car d))
       (match (cdr p)(cdr d) assignments)
     )
 
     ( (equal (car p) '+)
       (or (match p (cdr d) assignments)
           (match (cdr p)(cdr d) assignments) )
     )
 
     ( (null(atom(car p)))
         (append
           assignments
           (list
             (list
               (cadr(car p))
               d
             )
           )
         )
     )
  )
)
)
 
 
 
(putd ' insert 'expr '(lambda (aslist presponse)
  (cond
    ( (null presponse)
      nil)
    ( (atom (car presponse))
      (append (list(car presponse))
      (insert aslist (cdr presponse)) )
    )
    ( t
      (append (cadr (assoc (caar presponse) aslist))
                (insert aslist (cdr presponse)) )
    )
  )
)
)
 
