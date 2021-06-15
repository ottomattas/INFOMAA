extensions [ shell ]

globals [
  attributes strategies best-counter-strategies colors deterministic? indices
  payoff-matrix
  score-matrix
  proportion
  proportion-old
  proportion-scenario
  score
  stop-light
  ; if restarts, rounds or noise sliders have changed, recompute score-table
  restarts-old rounds-old noise-old
  scenario
]

;----------------------------------------------------------------------------------
;
;    SETUP AND RELATED
;
;----------------------------------------------------------------------------------

to setup
  ca
  set attributes [                  ; third attribute indicates whether deterministic

    ["cooperate-always"     green     true ]
    ["defect-always"        red       true ]
    ["TFT"                  violet    true ] ; echo opponent, start cooperating
    ["unforgiving"          blue      true ] ; cooperate util opponents defects; then defect forever
    ["Pavlov"               brown     true ] ; win-stay; loose-shift = play C if both concur in previous
    ["majority"             pink      true ] ; takes whole history in account; echo majority action of opponent
    ["eatherly"             102       false] ; cooperate with probability proportional to cooperation-rate of op
    ["random-50%"           gray      false] ; cooperate with probability 0.5ponent
    ["Joss-5%"              orange    false] ; tit-for-tat, but defect randomly 5% of the time
    ["Zukhev-5%"            magenta   false] ; Pavlov, but defect randomly 5% of the time
    ;---------------------------------
    ["Pavlov-extended"      43        false] ; ??
    ["forgiving-tft"        13        false] ; like tit-for-tat, but occasionally forgiving
    ["TF2-tats"             23        true ] ; only defect when oponent defects twice in a row
    ["suspicious-tft"       blue      true ] ; TFT starts defecting
    ["tits-for-tat-5"       orange    true ] ; defect if opponent defected in last 5 rounds
    ["tit-for-N-tats"       blue      true ] ; only defect when oponent defects N times in a row

    ["alpha"                red       true]  ; first two rounds signal CC, then respond to A, B and C with C, D and C, resp.
    ["beta"                 brown     true]  ; first two rounds signal CD, then respond to A, B and C with C, C and D, resp.
    ["gamma"                blue      true]  ; first two rounds signal CC, then respond to A, B and C with D, C and C, resp.

  ]

  set attributes ifelse-value (choose-contenders = "a-select") [
    n-of-preserve-first nr-of-contenders attributes
  ] [
    sublist attributes 0 min (list nr-of-contenders length attributes)
  ]

  set strategies     map [ ?1 -> item 0 ?1 ] attributes ; strip strategies from color table
  set colors         map [ ?1 -> item 1 ?1 ] attributes ; strip colors     from color table
  set deterministic? map [ ?1 -> item 2 ?1 ] attributes ; whether strategy is deterministic

  set indices        n-values length strategies [ ?1 -> ?1 ]

  resize-world -4 (length strategies + 2) (0 - (length strategies + 2)) 1
  initialise-run
end

to initialise-run
  reset-ticks
  clear-all-plots
  clear-output
  output-print (word
    "There are "  length strategies " strategies:\n\n* " reduce [ [?1 ?2] -> (word ?1 ",\n* " ?2) ] strategies ".\n\n"
    "First row: score of " item 0 strategies " against\neach other individual strategy in " restarts " encounters\nof " rounds " rounds.\n"
    "Second row: score of " item 1 strategies " against\neach other individual strategy in " restarts " encounters\nof " rounds " rounds.  And so on.\n\n"
    "- Green is average score.\n"
    "- Orange is score weighed by proportions.\n"
    "- Blue represents initial proportions.\n"
    "- Pink represents running proportions. (Same"
    "\n  as what is plotted).\n\n"
    "Due to noise (every player does a " (noise * 100)  "%\nrandom move), scores may vary.\n\n"
    "& Starred strategies are stochastic (have a\n"
    "  random element)\n"
    "& Gray squares denote best (row) counter-\n"
    "  strateg{y|ies} to column strategy."
  )
  foreach indices [ ?1 ->
    create-temporary-plot-pen item ?1 strategies
    set-plot-pen-color item ?1 colors
  ]
  set proportion initial-proportion
  if length proportion != length strategies [
    user-message (word "Number of proportions " (length proportion) " doesn't match number of strategies " (length strategies) ".\nChange initialisation-method or user-proportion.")
    stop
  ]
  set proportion-old n-values length strategies [ 0 ]
  draw-proportion 0 cyan ; initial proportions replicator
  draw-proportion 1 pink ; running proprotions replicator
  define-stop-light
  set-stop-light black
  reset-ticks
  ;
  compute-and-display-scores
  set score multiply score-matrix proportion
  draw-score      1 orange ; score weighed by proportions
  repeat stop-every-k-steps - 2 [ go ]
end

to-report initial-proportion
  if initialisation-method = "custom" [
    report run-result user-proportion
  ]
  if initialisation-method = "random" [
    report random-proportion length strategies
  ]
  if initialisation-method = "uniform" [
    report uniform length strategies
  ]
  if initialisation-method = "biased" [
    report biased length strategies strategy-to-bias bias
  ]
  if initialisation-method = "random-biased" [
    report biased length strategies (one-of indices) bias
  ]
  if initialisation-method = "scenario" and is-list? proportion-scenario and length proportion-scenario = length strategies [
      report proportion-scenario
  ]
  user-message "Unknown initialisation method"
end

;----------------------------------------------------------------------------------
;
;    MAIN LOOP
;
;----------------------------------------------------------------------------------

to go
  do-plots
  iterate
  tick
  if stop? [
    print-ranking
    stop
  ]
end

to iterate
  set score multiply score-matrix proportion
  set score list-plus score n-values length strategies [ birth-rate ]
  set proportion project-on-simplex hadamard proportion score
end

to do-plots
  draw-proportion 1 pink
  draw-score      1 orange
  foreach indices [ ?1 ->
    set-current-plot-pen item ?1 strategies
    plot item ?1 proportion
  ]
end

to-report stop?
  if stop-at-convergence and convergence?         [ report true ]
  if stop-every-k-steps > 0 and ticks mod stop-every-k-steps = 0  [ report true ]
  if restart-after > 0 and ticks >= restart-after [ report true ]
  set proportion-old proportion
  report false
end

to-report convergence?
  report sum (map [ [?1 ?2] -> (?1 - ?2) ^ 2 ] proportion proportion-old) < 1.0E-20
end

to print-ranking
  let filtered-indices filter [ ?1 -> item ?1 proportion >= 0.005 ] indices
  let ranked-indices sort-by [ [?1 ?2] -> item ?1 proportion > item ?2 proportion ] filtered-indices
  let ranking map [ ?1 -> (word (round (100 * item ?1 proportion)) "% " item ?1 strategies) ] ranked-indices
  let ranking-in-print reduce [ [?1 ?2] -> (word ?1 ",\n then: " ?2) ] ranking
  let message ifelse-value convergence? [ " due to convergence.\n" ] [ ".  Ranking so far:\n" ]
  output-print (word "Stopped at step " ticks message "First: " ranking-in-print ".")
  set-stop-light ifelse-value convergence? [ red ] [ orange ]
end

;----------------------------------------------------------------------------------
;
;    SCORE TABLE
;
;----------------------------------------------------------------------------------

to compute-and-display-scores
  if restarts = restarts-old and rounds = rounds-old and noise = noise-old [ stop ]
  set restarts-old restarts
  set rounds-old   rounds
  set noise-old    noise
  compute-score-matrix
  display-score-matrix
end

; record payoffs on both sides, so after 100 restarts each algorithm has 200 total payoffs
to compute-score-matrix
  ; address like: item my-action (item my-action payoff-matrix), so my-action goes first.
  ; e.g., if I cooperate (0) and you defect (1), that's item 1 of item 0, and we arrive at CD-payoff-sucker
  set payoff-matrix (list (list CC-payoff-reward CD-payoff-sucker) (list DC-payoff-temptation DD-payoff-punishment))
  ; results from both parties are used
  let double-score-matrix map [ ?1 -> double-score-row-for ?1 ] strategies
  set score-matrix scalar-times-matrix 0.5 matrix-plus (filter-from-matrix            double-score-matrix  0)
                                                       (filter-from-matrix (transpose double-score-matrix) 1)
  ; determine best counter-strategies per strategy (may be more than one)
  set best-counter-strategies map [ ?1 -> arg-max ?1 ] transpose score-matrix
end

to-report double-score-row-for [ x ]
  report map [ ?1 -> double-score-entry-for x ?1 ] strategies
end

to-report double-score-entry-for [ x y ]
  let double-score-entries n-values restarts [ double-scores-for x y ]
  ; if we get [[5 9] [3 11] ... ]
  report (list mean filter-from-list double-score-entries 0 mean filter-from-list double-score-entries 1)
  ; we return [4 10]
end

to-report double-scores-for [ x y ]
  let my-total-payoff  0
  let yo-total-payoff  0 ; yo = your
  let my-history      [] ; histories are involved, so no functional programming this time
  let yo-history      []
  repeat rounds [
    let my-action       play x my-history yo-history
    let yo-action       play y yo-history my-history
    let my-payoff       item yo-action (item my-action payoff-matrix)
    let yo-payoff       item my-action (item yo-action payoff-matrix)
    set my-total-payoff my-total-payoff + my-payoff
    set yo-total-payoff yo-total-payoff + yo-payoff
    set my-history      fput my-action my-history ; most recent actions go first
    set yo-history      fput yo-action yo-history
  ]
  report (list (my-total-payoff  / rounds) (yo-total-payoff / rounds))
end

to-report play [ some-strategy my-history your-history ]
  report ifelse-value (random-float 1.0 < noise) [
    random 2 ] [ runresult (word some-strategy " my-history your-history") ]
end

to display-score-matrix
  foreach indices [ ?1 ->
    let strategy-1 ?1
    ask patch -1 (0 - strategy-1) [
      set plabel strategy-string strategy-1
      set plabel-color yellow
    ]
    ask patch strategy-1 1 [
      set plabel chop item strategy-1 strategies
      set plabel-color yellow
    ]
    foreach indices [ ??1 ->
      let strategy-2 ??1
      ask patch strategy-2 (0 - strategy-1) [
        set plabel precision item strategy-2 (item strategy-1 score-matrix) 1
        let one-of-best-counter-strategies member? strategy-1 item strategy-2 best-counter-strategies
        if one-of-best-counter-strategies [ set pcolor 2 ] ;sprout 1 [ set shape "max" set color white ] ]
      ]
    ]
    ask patch (length strategies) (0 - strategy-1) [
      set plabel precision mean item strategy-1 score-matrix 1
      set plabel-color lime
    ]
  ]
end

; i -> (D) TFT
to-report strategy-string [ i ]
  let det ifelse-value (item i deterministic?) [ " " ] [ "*" ]
  report (word item i strategies det)
end

to draw-proportion [ row colour ]
  foreach indices [ ?1 ->
    ask patch ?1 (0 - (length strategies + row))  [
      set plabel precision item ?1 proportion 1
      set plabel-color colour
    ]
  ]
end

to draw-score [ column colour ]
  foreach indices [ ?1 ->
    ask patch (length strategies + column) (0 - ?1) [
      set plabel precision (item ?1 score) 1
      set plabel-color colour
    ]
  ]
end

;----------------------------------------------------------------------------------
;
;    MISCELLANEOUS
;
;----------------------------------------------------------------------------------

to print-scores
  type "<TABLE border=\"1\" cellpadding=\"3\" cellspacing=\"2\" style=\"font-size: 80%\">\n"
  type "   <TR align=\"center\" valign=\"bottom\">\n      <TH></TH>\n"
  foreach indices [ ?1 -> let i1 ?1 let s1 item i1 strategies
    type (word "      <TH>" s1 "</TH>\n")
  ]
  type "      <TH></TH>\n   </TR>\n"
  foreach indices [ ?1 ->
    let i1 ?1
    let s1 item i1 strategies
    type "   <TR valign=\"top\">\n"
    type (word "      <TH align=\"right\">" s1 "</TH>\n")
    foreach indices [ ??1 ->
      let i2 ??1
      let entry item i2 item i1 score-matrix
      let font-color ifelse-value (noise = 0 and item i1 deterministic? and item i2 deterministic?) [ "#000000" ] [ "#CC0000" ]
      type (word "      <TD><FONT style=\"color: " font-color "\">" precision entry 2 "</FONT></TD>\n")
    ]
    type (word "      <TD><FONT style=\"color: #CC0000\">" precision mean item i1 score-matrix 2 "</FONT></TD>\n")
    type "   </TR>\n"
  ]
  type "</TABLE>\n"
end

to checker
  ask patches [ set pcolor (pxcor + pycor) mod 2 ]
end

to-report sign [ x ]
  if x > 0 [ report  1 ]
  if x < 0 [ report -1 ]
  report 0
end

to-report arg-max [ l ]               ; l = [7 2 9 9 5]
  let maximum max l                   ; 9
  report filter [ ?1 -> item ?1 l = maximum ] indices ; 2 of 3
end

;----------------------------------------------------------------------------------
;
;    STOP LIGHT
;
;----------------------------------------------------------------------------------

to define-stop-light
  set stop-light patches with [
    -4 < pxcor and pxcor < -2 and
    (0 - (length strategies + 2)) < pycor and pycor < (0 - (length strategies))
  ]
end

to set-stop-light [ colour ]
  ask stop-light [ set pcolor colour ]
end

to compute-equilibria
  let gambit-input (word "NFG 1 R \"\" { \"1\" \"2\" } { " length strategies " " length strategies " } ")
  foreach indices [ ?1 -> let a ?1
    foreach indices [ ??1 -> let b ??1
      set gambit-input (word gambit-input " "
        item a (item b score-matrix) " " item b (item a score-matrix))
    ]
  ]
  shell:setenv "GAMBIT_INPUT" gambit-input ; no newlines; don't know how to put multiple lines into an env. variable
  let gambit-output (shell:exec "cmd" "/c" "echo" "%GAMBIT_INPUT%" "|" "C:/Program Files (x86)/Gambit/gambit-enummixed" "-q" "-d2") ;
  let equilibria split-string but-last gambit-output "\n"
  ;print what gambit said
  clear-output
  ;output-print (word "Equilibria:\n" gambit-output)
  output-print (word "There are " length equilibria " Nash equilibria.\n")
  output-print "         strategy: Str1 | Str2 | Prop"
  output-print (word "===============================|")
  foreach equilibria [ ?1 ->
    let equilibrium but-first split-string ?1 ","
    let strategy_row sublist equilibrium 0                     length strategies
    let strategy_col sublist equilibrium length strategies (2 * length strategies)
    foreach indices [ ??1 ->
      output-print (word pad-left item ??1 strategies 17 ": " convert item ??1 strategy_row " | "
                    convert item ??1 strategy_col " | " convert item ??1 proportion)
    ]
  output-print (word "===============================|")
  ]
end

;----------------------------------------------------------------------------------
;
;    LISTS AND MATRICES
;
;----------------------------------------------------------------------------------

to-report transpose [ matrix ]
  let ids n-values (length first matrix) [ ?1 -> ?1 ]
  report map [ ?1 -> n-th-column ?1 matrix ] ids
end

to-report n-th-column [ n matrix ]
  report map [ ?1 -> item n ?1 ] matrix
end

to-report filter-from-matrix [ m k ]     ; matrix entries are lists of the same length
  report map [ ?1 -> filter-from-list ?1 k ] m  ; get item k of every such list
end

to-report filter-from-list [ l k ]       ; list entries are lists of the same length
  report map [ ?1 -> item k ?1 ] l              ; get item k of every such list
end

to-report matrix-plus [m1 m2]
  report (map [ [?1 ?2] -> list-plus ?1 ?2 ] m1 m2)
end

to-report list-plus [l1 l2]
  report (map [ [?1 ?2] -> ?1 + ?2 ] l1 l2)
end

to-report scalar-times-matrix [c m]
  report map [ ?1 -> map [ ??1 -> c * ??1 ] ?1 ] m
end

to-report n-of-preserve-first [ n l ] ; works like n-of but preserves first
  if length l < 3 [ report l ]
  report fput first l n-of (n - 1) but-first l
end

;----------------------------------------------------------------------------------
;
;    STRINGS
;
;----------------------------------------------------------------------------------

to-report join-string [ l c ]
  report reduce [ [?1 ?2] -> (word ?1 c ?2) ] l
end

to-report split-string [ w s ]
  let i position s w
  if not is-number? i [ report ifelse-value (w = "") [ [] ] [ (list w) ] ]
  report fput (substring w 0 i) split-string substring w (i + length s) length w s
end

to-report pad-left [ s n ]
  set s (word s)
  report (word join-string n-values (n - length s) [ " " ] "" s)
end

to-report convert [ x ]
  if is-number? x and x > 1E-10 [ report precision x 2 ]
  if is-string? x and run-result x > 0 [ report x ]
  report "----"
end

to-report chop [ s ]
  let n 3
  ;set n n - sign occurrences "m" s
  ;set n n + occurrences "i" s
  ;set n n + occurrences "l" s
  report substring s 0 min (list n length s)
end

to-report occurrences [ c s ]
  let k 0 ; ugly but works
  foreach n-values length s [ ?1 -> ?1 ] [ ?1 -> if item ?1 s = c [ set k k + 1 ] ]
  report k
end

;----------------------------------------------------------------------------------
;
;    LINEAR ALGEBRA
;
;----------------------------------------------------------------------------------

to-report hadamard [ l1 l2 ] ; hadamard [a1 a2 a3] [b1 b2 b3] = [a1*b1 a2*b2 a3*b3]
  report (map [ [?1 ?2] -> ?1 * ?2 ] l1 l2)
end

to-report dot-product [ l1 l2 ] ; a.k.a. scalar product, inwendig product
  report sum hadamard l1 l2
end

to-report multiply [ matrix vector ] ; left must be matrix right must be vector (i.e, not a general definition)
  report map [ ?1 -> dot-product ?1 vector ] matrix
end

;----------------------------------------------------------------------------------
;
;    THINGS THAT HAPPEN ON THE N-1 SIMPLEX
;
;----------------------------------------------------------------------------------

to-report uniform [ n ]
  report n-values n [ 1 / n ]
end

; To generate n random numbers that sum to one uniformly, one can not generate n random numbers and
; project-on-simplex them.  Instead draw n times Gamma(1) distributed and then project-on-simplex.  The resulting
; vector is Dirichlet(1,1,1) distributed--and that is uniform.
; http://stats.stackexchange.com/questions/14059/generate-uniformly-distributed-weights-that-sum-to-unity
to-report random-proportion [ n ]
  report project-on-simplex n-values n [ 0 - ln random-float 1 ]
end

to-report biased [n k p]
  let others map [ ?1 -> (1 - p) * ?1 ] random-proportion ((length strategies) - 1)
  report (sentence (sublist others 0 k) (list p) (sublist others k length others))
end

to-report project-on-simplex [ l ] ; make it sum to 1
  let s sum l
  report map [ ?1 -> ?1 / s ] l
end

;----------------------------------------------------------------------------------
;
;    SCENARIOS
;
;----------------------------------------------------------------------------------

to run-scenario
  ; choose-contenders, nr-of-contenders, restarts, rounds, noise, proportion, iterations

  set CC-payoff-reward     3 ; make sure that proper payoffs are used
  set CD-payoff-sucker     0
  set DC-payoff-temptation 5
  set DD-payoff-punishment 1

  set choose-contenders    item 0 scenario
  set nr-of-contenders     item 1 scenario
  set restarts             item 2 scenario
  set rounds               item 3 scenario
  set noise                item 4 scenario

  compute-and-display-scores

  set proportion-scenario  item 5 scenario
  set stop-every-k-steps   item 6 scenario
  set restart-after        0
  set stop-at-convergence  true

  let prev initialisation-method
  set initialisation-method "scenario"
  initialise-run
  set initialisation-method prev
  loop [
    do-plots
    iterate
    tick
    if stop? [
      print-ranking
      stop
    ]
  ]
end

;----------------------------------------------------------------------------------
;
;    STRATEGIES
;
;----------------------------------------------------------------------------------

to-report cooperate-always [ my-history your-history ]
  report 0
end

to-report defect-always [ my-history your-history ]
  report 1
end

to-report random-50% [ my-history your-history ]
  report random 2
end

to-report unforgiving [ my-history your-history ] ; also: Friedman, or: grim trigger
  if member? 1 your-history [ report 1 ]
  report 0
end

to-report TFT [ my-history your-history ]
  if length your-history < 1 [ report 0 ]
  report first your-history
end

to-report suspicious-tft [ my-history your-history ]
  if length your-history < 1 [ report 1 ]
  report first your-history
end

to-report TF2-tats [ my-history your-history ]
  if length your-history < 2 [ report 0 ]
  if member? 0 sublist your-history 0 1 [ report 0 ]
  report 1
end

to-report tits-for-tat-5 [ my-history your-history ]
  if empty? your-history [ report 0 ]
  if member? 1 sublist your-history 0 min (list 4 (length your-history - 1)) [ report 1 ]
  report 0
end

to-report forgiving-tft [ my-history your-history ]
  if length your-history < 1 [ report 0 ]
  if first your-history = 0 or random-float 1.0 < 0.05 [ report 0 ] ; forgive sometimes
  report 1
end

to-report majority [ my-history your-history ] ; = ficititious play?
  if length your-history < 1 [ report 0 ]
  report round mean your-history
end

to-report eatherly [ my-history your-history ] ; = ficititious play?
  if length your-history < 1 [ report 0 ]
  let probability-you-defect sum your-history / length your-history
  report ifelse-value (random-float 1.0 < probability-you-defect) [ 1 ] [ 0 ]
end

to-report Joss-5% [ my-history your-history ]
  if random-float 1.0 < 0.05 [ report 1 ] ; like tit-for-tat, defect 5% of the time
  ; else TFT
  if length your-history < 1 [ report 0 ]
  report first your-history
end

to-report Pavlov [ my-history your-history ]
  ; win-stay, lose-shift; win-stay, lose-switch;
  ; Pavlov does what he did if he wasn't punished, but does what he didn't do when he was punished.
  ; Wissel van strategie als je gestraft wordt.
  ; Wissel van strategie als de tegenstander in de vorige ronde verzaakte.
  ; Werk samen als en slechts als zowel jij als de tegenstander in de vorige ronde dezelfde strategie hanteerden.
  ; CC -> C; CD -> D; DC -> D; DD -> C
  ;  3 -> C;  0 -> D;  5 -> D;  1 -> C
  ;  3 -> -;  0 -> x;  5 -> -;  1 -> x
  if length my-history = 0 [ report 0 ]
  if first your-history = first my-history [ report 0 ]
  report 1
end

to-report Pavlov-extended [ my-history your-history ]
  ; win-stay, lose-shift; win-stay, lose-switch;
  ; Pavlov does what he did if he wasn't punished, but does what he didn't do when he was punished.
  ; Wissel van strategie als je gestraft wordt.
  ; Wissel van strategie als de tegenstander in de vorige ronde verzaakte.
  ; Werk samen als en slechts als zowel jij als de tegenstander in de vorige ronde dezelfde strategie hanteerden.
  ; CC -> C; CD -> D; DC -> D; DD -> C
  ;  3 -> C;  0 -> D;  5 -> D;  1 -> C
  ;  3 -> -;  0 -> x;  5 -> -;  1 -> x
  if length my-history < 2 [ report 0 ]
  let realised-payoff mean (map [ [?1 ?2] -> item ?2 item ?1 payoff-matrix ] sublist my-history 0 1 sublist your-history 0 1)
  let action first my-history
  if realised-payoff < 2.5 [ set action 1 - action ]
  report action
end

to-report Zukhev-5% [ my-history your-history ]
  if random-float 1.0 < 0.05 [ report 1 ] ; like Pavlov, but defect 5% of the time
  if length my-history = 0 [ report 0 ]
  if first your-history = first my-history [ report 0 ]
  report 1
end

to-report tit-for-N-tats [ my-history your-history ]
  let k 2
  if length your-history < k [ report 0 ]
  if member? 0 sublist your-history 0 k [ report 0 ]
  report 1
end

; routine to define roof-tile play, e.g., CCCDDCCCCCCDDCCCCCCDDCCCCCCDDCCCCCCDDCCCCCCDDCCCCCCDDCCCCCCDD
; notice there is a transient period which is essential
to-report play-C? [ transient len-C len-D current-round ]
; if current-round <= transient [ report true ]
  let s floor ((current-round - transient - 1) / (len-C + len-D))
  report current-round <= transient + s * (len-C + len-D) + len-C
end

to-report C/D [ len-C len-D current-round ]
; if current-round <= transient [ report true ]
  let s floor ((current-round - 1) / (len-C + len-D))
  report ifelse-value (current-round <= s * (len-C + len-D) + len-C) [ 0 ] [ 1 ]
end

; a: cc  a - b d - c
; b: cd  a - c c - d
; c: dd  b - c d - c

;(3, 1): cc + 2dc + 2dd
;cdddd
;cccdd

;(2, 2): cc / dd
;cd
;cd

to-report alpha [ my-history your-history ]
  let k length your-history
  if k < 2 [ report 0 ] ; use first two moves to signal that your are A
  let sum-of-first-two-moves-of-your-history sum sublist your-history (k - 2) k
  if sum-of-first-two-moves-of-your-history = 0 [ report C/D 1 1 k ] ; A - A : C - C
  if sum-of-first-two-moves-of-your-history = 1 [ report C/D 1 4 k ] ; A - B : D - C
  if sum-of-first-two-moves-of-your-history = 2 [ report C/D 3 2 k ] ; A - C : C - D
end

to-report beta [ my-history your-history ]
  let k length your-history
  if k < 2 [ report k ] ; use first two move to signal that your are B
  let sum-of-first-two-moves-of-your-history sum sublist your-history (k - 2) k
  if sum-of-first-two-moves-of-your-history = 0 [ report C/D 3 2 k ] ; B - A : C - D
  if sum-of-first-two-moves-of-your-history = 1 [ report C/D 1 1 k ] ; B - B : C - C
  if sum-of-first-two-moves-of-your-history = 2 [ report C/D 1 4 k ] ; B - C : D - C
end

to-report gamma [ my-history your-history ]
  let k length your-history
  if k < 2 [ report 1 ] ; use first two moves to signal that your are C
  let sum-of-first-two-moves-of-your-history sum sublist your-history (k - 2) k
  if sum-of-first-two-moves-of-your-history = 0 [ report C/D 1 4 k ] ; C - A : D - C
  if sum-of-first-two-moves-of-your-history = 1 [ report C/D 3 2 k ] ; C - B : C - D
  if sum-of-first-two-moves-of-your-history = 2 [ report C/D 1 1 k ] ; C - C : C - C
end
@#$#@#$#@
GRAPHICS-WINDOW
219
10
547
243
-1
-1
32.0
1
12
1
1
1
0
1
1
1
-4
5
-5
1
1
1
1
ticks
30.0

BUTTON
154
10
217
55
NIL
setup
NIL
1
T
OBSERVER
NIL
X
NIL
NIL
1

BUTTON
89
546
152
579
step
go
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
154
546
217
579
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
45
151
217
184
rounds
rounds
0
1000
200.0
10
1
NIL
HORIZONTAL

SLIDER
45
116
217
149
restarts
restarts
0
500
20.0
5
1
NIL
HORIZONTAL

SLIDER
45
186
217
219
noise
noise
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1157
62
1329
95
CC-payoff-reward
CC-payoff-reward
-10
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
1157
97
1329
130
CD-payoff-sucker
CD-payoff-sucker
-10
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
1157
132
1329
165
DC-payoff-temptation
DC-payoff-temptation
-10
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
1157
167
1329
200
DD-payoff-punishment
DD-payoff-punishment
-10
10
1.0
1
1
NIL
HORIZONTAL

PLOT
219
491
1013
649
Proportions
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"cooperate-always" 1.0 0 -10899396 true "" ""

OUTPUT
775
10
1155
489
12

BUTTON
24
547
87
580
reset
initialise-run
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

SWITCH
45
616
217
649
stop-at-convergence
stop-at-convergence
1
1
-1000

SLIDER
45
57
217
90
nr-of-contenders
nr-of-contenders
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
45
581
217
614
stop-every-k-steps
stop-every-k-steps
0
1E4
200.0
1E2
1
NIL
HORIZONTAL

CHOOSER
45
10
152
55
choose-contenders
choose-contenders
"in-order" "a-select"
0

TEXTBOX
66
98
219
126
parameters for the score table
11
0.0
1

TEXTBOX
131
530
235
548
run the replicator
11
0.0
1

BUTTON
1157
202
1293
235
NIL
compute-equilibria
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

CHOOSER
45
290
217
335
initialisation-method
initialisation-method
"custom" "random" "uniform" "biased" "random-biased" "scenario"
1

INPUTBOX
45
337
217
397
user-proportion
[.9 0.05 0.05]
1
0
String (reporter)

SLIDER
45
399
217
432
strategy-to-bias
strategy-to-bias
0
50
2.0
1
1
NIL
HORIZONTAL

SLIDER
45
433
217
466
bias
bias
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
1157
27
1329
60
restart-after
restart-after
0
1E4
0.0
1E2
1
NIL
HORIZONTAL

TEXTBOX
1162
10
1312
28
Payoffs
11
0.0
1

TEXTBOX
71
230
220
286
------------------------------------\n       REPLICATOR DYNAMIC\n------------------------------------\n                set start proportion
11
0.0
1

SLIDER
45
491
217
524
birth-rate
birth-rate
0
100
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
74
473
224
491
parameters for the replicator
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

max
false
0
Line -7500403 true 45 45 45 105
Line -7500403 true 75 75 45 45
Line -7500403 true 75 75 105 45
Line -7500403 true 105 105 105 45
Line -7500403 true 120 105 150 45
Line -7500403 true 180 105 150 45
Line -7500403 true 195 45 240 105
Line -7500403 true 195 105 240 45
Line -7500403 true 135 75 165 75

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

up-and-down
false
0
Line -7500403 true 150 135 150 45
Line -7500403 true 120 90 150 45
Line -7500403 true 180 90 150 45

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
