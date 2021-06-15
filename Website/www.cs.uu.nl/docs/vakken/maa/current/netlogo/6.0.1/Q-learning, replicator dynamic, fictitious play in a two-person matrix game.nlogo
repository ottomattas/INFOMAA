breed [players player]

extensions [ shell ]

globals [
  dimension            ; derived from either generated matrix or user-given matrix
  actions              ; e.g., [0 1 2 3]
  rounds               ; number of rounds played
  action-patches       ; those patches that correspond to matrix entries; they contain information
  label-patches        ; those patches that correspond to matrix entries; they contain information
  equilibria           ; list of Nash equilibria found
  current-equilibrium  ; the equilibrium we look at
]


patches-own [           ; only relevant to action patches
  RL-frequency          ; divided by number of rounds played
  RL-action-count       ; number of times played
  RL-action-count-geom  ; divided by number of rounds played
  FP-frequency
  FP-action-count       ;
  FP-action-count-geom

  NR-frequency
  NR-action-count       ;
  NR-action-count-geom

  RD-proportion
]

players-own [
  opponent                   ; the other player (turtle 0 or turtle 1)
  payoff-matrix              ; the player's payoff matrix
  patch-matrix               ; matrix of patches in a form that corresponds to the player's payoff matrix

  RL-current-action          ; action played this round
  RL-action-counts           ; vector of (absolute) frequencies each action is played
  RL-action-frequencies      ; vector of action counts divided through number of rounds
  RL-action-counts-geom      ; vector of frequencies each action is played (geometric update)

  FP-current-action
  FP-action-counts
  FP-action-frequencies
  FP-action-counts-geom

  NR-current-action
  NR-action-counts
  NR-action-frequencies
  NR-action-counts-geom

  RL-cumulative-rewards      ; vector of past rewards per action (cumulative update)
  RL-average-rewards         ; vector of past rewards per action (plain average)
  RL-geometric-rewards       ; vector of past rewards per action (geometric update)
  RL-predicted-rewards       ; vector of predicted rewards per action, computer through empirical frequencies

  RD-proportions             ; vector of proportions in the replicator equation

  strategy

]

;----------------------------------------------------------------------------------
;
;    SETUP
;
;----------------------------------------------------------------------------------

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  create-players 2 [ set hidden? true set color white ]
  ask players [ set opponent one-of other players ]

  let sub-game-type substring game-type 0 6

  output-print "Searching for equilibria ..."
  while [ (equilibria = 0) or
          (sub-game-type = "random" and exact-nr-of-equilibria > 0 and length equilibria != exact-nr-of-equilibria) or
          (sub-game-type = "random" and length equilibria < minimum-nr-of-equilibria) or
          (game-type = "random-fully-pure"  and not all-true? map [ i -> pure?  i ] equilibria) or
          (game-type = "random-one-pure"    and  1 != n-true? map [ i -> pure?  i ] equilibria) or
          (game-type = "random-fully-mixed" and not all-true? map [ i -> mixed? i ] equilibria)
     ] [
    ask players [
      set payoff-matrix run-result (word "matrix-" game-type)
    ]
    if symmetric? [ ask player 0 [ set payoff-matrix [ payoff-matrix] of player 1 ] ]
    set dimension length [ payoff-matrix ] of one-of players
    set actions n-values dimension [ i -> i ]
    set equilibria compute-equilibria

    output-print (word length equilibria " equilibria, " n-true? map [ i -> pure?  i ] equilibria " pure")

    if abort-setup [ stop ]

  ]

  clear-output
  ; show matrix in output pane and on patches
  repeat dimension [ output-type "-----------" ] output-type "\n"
  foreach actions [ a ->
    foreach actions [ b ->
      let payoff-row item b (item a [ payoff-matrix ] of player 0)
      let payoff-col item a (item b [ payoff-matrix ] of player 1)
      output-type (word pad-left payoff-row 4 "," pad-left payoff-col 4 " |")
      ask patch b (0 - a) [ set plabel (word payoff-row ", " payoff-col) ]
    ]
    output-type "\n"
  ]
  repeat dimension [ output-type "-----------" ] output-type "\n"

  print-equilibria

  ask patches [ set pcolor 101 ] ; (pxcor + pycor) mod 2 ]
  set action-patches patches with [ -1 < pxcor and pxcor < dimension and (0 - dimension) < pycor and pycor < 1 ]
  set label-patches patches with [ (pxcor < 0 and pycor <= 0) or (pxcor >= 0 and pycor > 0) ]
  ask label-patches [ set plabel-color red ]
  ask player 0 [ set patch-matrix map [ i -> sort action-patches with [ pycor = 0 - i ] ] actions ]
  ask player 1 [ set patch-matrix map [ i -> sort action-patches with [ pxcor =     i ] ] actions ]
  ask patch -1 5 [ set plabel "actions" ]
  ask patch -1 4 [ set plabel "predicted rewards" ]
  ask patch -1 3 [ set plabel "empirical rewards" ]
  ask patch -1 2 [ set plabel "action frequencies" ]
  ask patch -1 1 [ set plabel "geometric frequencies" ]
  foreach actions [ i ->
    ask patch -5 (0 - i) [ set plabel i ]
    ask patch  i      5  [ set plabel i ]
  ]
  ask one-of players [
    setxy -.5 max-pycor + .4999 pd setxy -.5 min-pycor - .5 pu
    setxy min-pxcor - .5 .5 pd setxy max-pxcor + .4999 .5 pu
  ]

  reset
end

to reset
  ; fake values to display start situation
  set rounds dimension
  ask patches [ set RL-action-count 0 ]
  ask players [
    set RL-action-counts n-values dimension [ 1 ]
    set RL-action-counts-geom n-values dimension [ 0.1 ]
    set RL-geometric-rewards  map [ i -> mean i ] payoff-matrix
    set RL-predicted-rewards  map [ i -> mean i ] payoff-matrix
  ]
  color-margins
  ; correct values
  set rounds 0
  ask action-patches [
    set RL-action-count 0
    set RL-action-count-geom 0
    set FP-action-count 0
    set FP-action-count-geom 0
  ]
  ask players [
    set RL-action-counts      n-values dimension [ 0 ]
    set RL-action-counts-geom n-values dimension [ 0 ]
    set RL-geometric-rewards  n-values dimension [ 0 ]
    set RL-cumulative-rewards n-values dimension [ 0 ]
    set RL-predicted-rewards  n-values dimension [ 0 ]
    set FP-action-counts      n-values dimension [ 0 ]
    set FP-action-frequencies n-values dimension [ 0 ]
    set FP-action-counts-geom n-values dimension [ 0 ]
    set NR-action-counts      n-values dimension [ 0 ]
    set NR-action-frequencies n-values dimension [ 0 ]
    set NR-action-counts-geom n-values dimension [ 0 ]
    set RD-proportions        random-proportion dimension
  ]
end

;----------------------------------------------------------------------------------
;
;    PLAY
;
;----------------------------------------------------------------------------------

to go
  set rounds rounds + 1

  ; let players choose action
  ask players [
    set RL-current-action ifelse-value (random-float 1.0 < exploration-rate) [ one-of actions ] [ arg-max RL-geometric-rewards ]

    let FP-expected-payoffs matrix-product payoff-matrix [ FP-action-frequencies ] of opponent
    set FP-current-action arg-max FP-expected-payoffs

    let RD-scores matrix-product payoff-matrix [ RD-proportions ] of opponent
    let RD-average-score dot-product RD-proportions RD-scores
    set RD-proportions (map [ [i j ] -> i * (replicator-rate + j) / (replicator-rate + RD-average-score) ] RD-proportions RD-scores)
  ]

  ; update player frequencies
  ask players [
    set RL-action-counts replace-item RL-current-action RL-action-counts (item RL-current-action RL-action-counts + 1)
    set RL-action-frequencies map [ i -> i / rounds ] RL-action-counts

    set RL-action-counts-geom map [ i -> (1.0 - learning-rate) * i ] RL-action-counts-geom
    set RL-action-counts-geom replace-item RL-current-action RL-action-counts-geom  (item RL-current-action RL-action-counts-geom + learning-rate / (1 - learning-rate))

    let RL-immediate-reward item ([ RL-current-action ] of opponent) (item RL-current-action payoff-matrix)
    set RL-cumulative-rewards replace-item RL-current-action RL-cumulative-rewards (item RL-current-action RL-cumulative-rewards + RL-immediate-reward)
    set RL-geometric-rewards replace-item RL-current-action RL-geometric-rewards ((1.0 - learning-rate) * item RL-current-action RL-geometric-rewards + learning-rate * RL-immediate-reward)
  ; set RL-predicted-rewards (map [ dot-product ?1 ?2 ] payoff-matrix map [ map [ [ RL-frequency ] of ? ] ? ] patch-matrix)
    set RL-predicted-rewards map [ i -> dot-product i map [ j -> j / rounds ] [ RL-action-counts ] of opponent ] payoff-matrix
    set RL-average-rewards map [ i -> i / rounds ] RL-cumulative-rewards

    set FP-action-counts replace-item FP-current-action FP-action-counts (item FP-current-action FP-action-counts + 1)
    set FP-action-frequencies map [ i -> i / rounds ] FP-action-counts
    set FP-action-counts-geom map [ i -> (1.0 - learning-rate) * i ] FP-action-counts-geom
    set FP-action-counts-geom replace-item FP-current-action FP-action-counts-geom (item FP-current-action FP-action-counts-geom + learning-rate * dimension)
  ]

  ; update patch frequencies
  ask patch [ RL-current-action ] of player 1 (0 - [ RL-current-action ] of player 0) [
    set RL-action-count RL-action-count + 1
    set RL-action-count-geom RL-action-count-geom + learning-rate / (1 - learning-rate)
  ]
  ask patch [ FP-current-action ] of player 1 (0 - [ FP-current-action ] of player 0) [
    set FP-action-count FP-action-count + 1
    set FP-action-count-geom FP-action-count-geom + learning-rate / (1 - learning-rate)
  ]

  ask action-patches [
    set RL-frequency RL-action-count / rounds
    set RL-action-count-geom (1 - learning-rate) * RL-action-count-geom
    set FP-frequency FP-action-count / rounds
    set FP-action-count-geom (1 - learning-rate) * FP-action-count-geom
    set RD-proportion (item (0 - pycor) [ RD-proportions ] of player 0 *
                       item      pxcor  [ RD-proportions ] of player 1)

    set pcolor rgb (255 * RL-frequency) (255 * RD-proportion) (255 * FP-frequency)
  ]

  color-margins
  tick
end

;------------------------------------------------------------------------------------------

to color-margins
  ask players [
    if-else who mod 2 = 0 [
      foreach actions [i ->
        ask patch -4 (0 - i) [ color-reward     [ item i RL-predicted-rewards  ] of myself ]
        ask patch -3 (0 - i) [ color-reward     [ item i RL-geometric-rewards  ] of myself ]
        ask patch -2 (0 - i) [ color-frequency  [ item i RL-action-counts      ] of myself / rounds ]
        ask patch -1 (0 - i) [ color-frequency  [ item i RL-action-counts-geom ] of myself ]
      ]
    ] [
      foreach actions [i ->
        ask patch  i      4  [ color-reward     [ item i RL-predicted-rewards  ] of myself ]
        ask patch  i      3  [ color-reward     [ item i RL-geometric-rewards  ] of myself ]
        ask patch  i      2  [ color-frequency  [ item i RL-action-counts      ] of myself / rounds ]
        ask patch  i      1  [ color-frequency  [ item i RL-action-counts-geom ] of myself ]
      ]
    ]
  ]
end

to color-frequency [ freq ]
  set plabel precision freq 2
  set pcolor scale-color white freq 0 1
end

to color-reward [ reward ]
  set plabel precision reward 1
  set pcolor scale-color white reward 0 max-payoff
end

;----------------------------------------------------------------------------------
;
;    COMPUTE NASH EQUILIBRIA
;
;----------------------------------------------------------------------------------

to-report compute-equilibria
  ; prepare input for gambit
  let gambit-input (word "NFG 1 R \"\" { \"1\" \"2\" } { " dimension " " dimension " }")
  foreach actions [ a ->
    foreach actions [ b ->
      set gambit-input (word gambit-input " "
        item a (item b [payoff-matrix] of turtle 0) " " item b (item a [payoff-matrix] of turtle 1))
    ]
  ]
  shell:setenv "GAMBIT_INPUT" gambit-input ; no newlines; don't know how to put multiple lines into an env. variable
  let gambit-output (shell:exec "cmd" "/c" "echo" "%GAMBIT_INPUT%" "|" "C:/Program Files (x86)/Gambit/gambit-enummixed" "-q")

  if member? "not recognized" gambit-output [
    user-message gambit-output
    report false
  ]

  let gambit-equilibria split-string but-last gambit-output "\n"   ; list of "NE,1/2,0,1/2,0,5/91,0,45/91,41/91"
  let gambit-profiles map [ i -> split-string i "," ] gambit-equilibria ; list of [NE 1/2 0 1/2 0 5/91 0 45/91 41/91]
  report map [ i -> strategy-profile i ] gambit-profiles
end

to-report strategy-profile [ gambit-profile ] ; [NE 1/2 0 1/2 0 5/91 0 45/91 41/91]
 report map [ i -> sublist gambit-profile i (i + dimension) ] (list 1 (1 + dimension)) ; [[1/2 0 1/2 0] [5/91 0 45/91 41/91]]
end

to print-equilibria
  foreach n-values length equilibria [ i -> i ] [ i ->
    let equilibrium item i equilibria
    let equilibrium-type ifelse-value (pure? equilibrium) [ "pure" ] [ "mixed" ]
    output-print equilibrium
    let numeric-equilibrium convert-to-numbers equilibrium

    if equilibrium-type = "pure" [
      let px      position 1 (item 1 numeric-equilibrium)
      let py (0 - position 1 (item 0 numeric-equilibrium))
      ask one-of players [
        setxy px - .5 py + .5 pd
        setxy px + .5 py + .5
        setxy px + .5 py - .5
        setxy px - .5 py - .5
        setxy px - .5 py + .5 pu
      ]
    ]

    output-print (word "\nEquilibrium " (i + 1) " (" equilibrium-type "):")

    foreach [0 1] [ j ->
      ask player j [
        let payoff dot-product item who numeric-equilibrium map [ dot-product item [ who ] of opponent numeric-equilibrium j ] payoff-matrix
        output-print (word (item j ["Row" "Col"]) ": " item who equilibrium " -> " as-fraction payoff)
      ]
    ]

  ]
  set current-equilibrium length equilibria - 1
end

to-report pure? [ equilibrium ]
  report all-true? map [ i -> all-true?  map [ j -> string-represents-integer? j ] i ] equilibrium
end

to-report mixed? [ equilibrium ]
  report all-true? map [ i -> some-true? map [ j -> not string-represents-integer? j ] i ] equilibrium
end

to-report integer? [ x ]
  report x = int x
end

to-report string-represents-integer? [ s ]
  report ifelse-value (false = position "/" s) [ true ] [ false ]
end

to-report all-true? [ l ]
  report reduce and l
end

to-report n-true? [ l ]
  report length filter [ i -> i = true ] l
end

to-report some-true? [ l ]
  report reduce or l
end

to display-equilibrium [ equilibrium ]
  let numeric-equilibrium convert-to-numbers equilibrium
  ask action-patches [
    let freq item (0 - pycor) item 0 numeric-equilibrium * item pxcor item 1 numeric-equilibrium
  ; set plabel precision freq 2
    set pcolor scale-color cyan freq 0 1
  ]
end

to walk-equilibria
  set current-equilibrium current-equilibrium + 1
  if current-equilibrium = length equilibria [ set current-equilibrium 0 ]
  display-equilibrium item current-equilibrium equilibria
end

to walk-back
  set current-equilibrium current-equilibrium - 1
  if current-equilibrium < 0 [ set current-equilibrium length equilibria - 1 ]
  display-equilibrium item current-equilibrium equilibria
end

to pin
  ask player 0 [ set RD-proportions binomial-distribution (dimension - 1) (0 - round mouse-ycor) ]
  ask player 1 [ set RD-proportions binomial-distribution (dimension - 1)            mouse-xcor  ]
end

;------------------------------------------------------------------------------------------

to-report arg-max [ l ]               ; l = [7 2 9 9 5]
  let maximum max l                   ; 9
  report one-of filter [ i -> item i l = maximum ] actions ; 2 of 3
end

to-report arg-max-discrete [ l ]      ; l = [7 2 9 9 5]
  report replace-item (arg-max l) n-values dimension [ 0 ] 1
end

to-report arg-max-mixed [ l ]         ; l = [7 2 9 9 5]
  let maximum max l                   ; 9
  let chi map [ i -> ifelse-value (i = maximum) [ 1 ] [ 0 ] ] l ; [0 0 1 1 0]
  let factor 1 / sum chi
  report map [ i -> factor * i ] chi       ; [0 0 .5 .5 0]
end

to-report hadamard-product [ l1 l2 ] ; hadamard-product [a1 a2 a3] [b1 b2 b3] = [a1*b1 a2*b2 a3*b3]
  report (map [ [i j] -> i * j ] l1 l2)
end

to-report dot-product [ l1 l2 ]
  report sum hadamard-product l1 l2
end

to-report matrix-product [ matrix vector ]
  report map [ i -> dot-product i vector ] matrix
end

to-report safe-division [ x y ]
  if y = 0 [ report random 10 ]
  report x / y
end

;------------------------------------------------------------------------------------------

to-report binomial [ n k ]
  if     k > n [ report 1E99 ]
  if     k = 0 [ report 1 ]
  if 2 * k > n [ report binomial n (n - k) ]
  report n / k * binomial (n - 1) (k - 1)
end

to-report binomial-density [ n k p ]
  report (binomial n k) * p ^ k * (1 - p) ^ (n - k)
end

to-report binomial-distribution [ n mu ]
  let p mu / n
  report n-values (n + 1) [ i -> binomial-density n i p ]
end

to-report hypergeometric-density [ cap-n cap-k n k ]
  report (binomial cap-k k) * (binomial (cap-n - cap-k) (n - k)) / (binomial cap-n n)
end

to-report hypergeometric-distribution [ cap-n mu n ] ; mu = n K / N ;mu N = K n; K = mu N / n
  let cap-k mu * cap-n / n
  report n-values (n + 1) [ i -> hypergeometric-density cap-n cap-k n i ]
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

to-report project-on-simplex [ l ] ; make it sum to 1
  let s sum l
  report map [ i -> i / s ] l
end

;------------------------------------------------------------------------------------------

to-report transpose [ matrix ]
  let ids n-values (length first matrix) [ i -> i ]
  report map [ i -> n-th-column i matrix ] ids
end

to-report n-th-column [ n matrix ]
  report map [ i -> item n i ] matrix
end

;------------------------------------------------------------------------------------------

to-report convert-to-numbers [ s ]
  if is-string? s [
    let k position "/" s
    report run-result ifelse-value (is-number? k) [ replace-item k s " / " ] [ s ]
  ]
  report map [ i -> convert-to-numbers i ] s
end

to-report pad-left [ s n ]
  set s (word s)
  report (word join-string n-values (n - length s) [ " " ] "" s)
end

to-report join-string [ l c ]
  report reduce [ [result-so-far next-item] -> (word result-so-far c next-item) ] l
end

to-report split-string [w s]
  let i position s w
  if not is-number? i [ report ifelse-value (w = "") [ [] ] [ (list w) ] ]
  report fput (substring w 0 i) split-string substring w (i + length s) length w s
end

to-report as-fraction [ n ]
  report simplify float-to-fraction n 1E-10
end

to-report simplify [ frac ]
  let n item 0 frac
  let d item 1 frac
  let i floor (n / d)
  let r n - i * d
  let x ifelse-value (i     = 0) [ "" ] [ i ]
  let y ifelse-value (i * r = 0) [ "" ] [ "+" ]
  let z ifelse-value (    r = 0) [ "" ] [ (word r "/" d) ]
  report (word x y z)
end

to-report float-to-fraction [x err]
  let n floor x
  set x x - n
  if x < err [ report (list n 1) ]
  if 1 - err < x [ report (list (n + 1) 1) ]

  ; The lower fraction is 0/1
  let lower-n 0 let lower-d 1
  ; The upper fraction is 1/1
  let upper-n 1 let upper-d 1
  loop [
    ; The middle fraction is (lower-n + upper-n) / (lower-d + upper-d)
    let middle-n lower-n + upper-n
    let middle-d lower-d + upper-d
    ; if x + err < middle
    if-else middle-d * (x + err) < middle-n [
      ; middle is our new upper
      set upper-n middle-n
      set upper-d middle-d
    ] [
    ; else if middle < x - err
    if-else middle-n < (x - err) * middle-d [
      ; middle is our new lower
      set lower-n middle-n
      set lower-d middle-d
    ] [
      report (list (n * middle-d + middle-n) middle-d)
    ]
    ]
  ]
end

; --------------------------------------------------------------------

to-report matrix-random set dimension nr-of-actions report n-values dimension [ n-values dimension [ random (1 + max-payoff) ] ] end
to-report matrix-random-fully-pure report matrix-random end
to-report matrix-random-one-pure report matrix-random end
to-report matrix-random-fully-mixed report matrix-random end
;to-report matrix-by-input report run-result ifelse-value (who = 0) [ payoffs-row ] [ payoffs-col ] end
to-report matrix-Shapley report [[1 1 9] [8 2 2] [3 7 3]] end
to-report matrix-rock-paper-scissors report [[1 2 0] [0 1 2] [2 0 1]] end
to-report matrix-rock-paper-scissors-5 report [[2 3 4 0 1] [1 2 3 4 0] [0 1 2 3 4] [4 0 1 2 3] [3 4 0 1 2]] end
to-report matrix-rock-paper-5-permuted report [[0 1 2 3 4] [4 0 1 2 3] [3 4 0 1 2] [2 3 4 0 1] [1 2 3 4 0]] end
to-report matrix-prisoner report [[3 0] [5 1]] end
to-report matrix-hawk-dove report [[0 3] [1 2]] end
to-report matrix-coordination report [[1 0 0] [0 2 0] [0 0 20]] end
to-report matrix-sqrt-2 report ifelse-value (who = 0) [ (list [1 0] (list 0 sqrt 2)) ] [ (list (list sqrt 2 0) [0 1]) ] end
to-report matrix-BoS report ifelse-value (who = 0) [ [[1 0] [0 2]] ] [ [[2 0] [0 1]] ] end
to-report matrix-matching-pennies report ifelse-value (who = 0) [ [[1 0] [0 1]] ] [ [[0 1] [1 0]] ] end
to-report matrix-matching-pennies_ report ifelse-value (who = 0) [ [[9 1] [2 9]] ] [ [[3 8] [8 4]] ] end
to-report matrix-complex-5x5+0-9=16 report ifelse-value (who = 0) [ [[2 1 4 0 6] [3 6 6 8 6] [7 5 4 0 5] [7 7 2 2 6] [1 2 7 6 0]] ]
                                                               [ [[0 0 8 6 1] [3 0 8 5 0] [1 4 6 6 7] [4 5 5 4 2] [1 1 2 7 5]] ] end

; set matrix (list (list 10 0 penalty) (list 0 2 0) (list penalty 0 10)) ; penalty game
; set matrix (list (list 11 -30 0) (list -30 7 6) (list 0 0 5)) ; climbing game

; the idea was that of action order is irrelevant, we might just as well sort rows by their mean payoff (this function not used)
to-report sort-matrix [ matrix ]
  report sort-by [ [i j] -> mean i < mean j ] matrix
end
@#$#@#$#@
GRAPHICS-WINDOW
208
10
696
499
-1
-1
40.0
1
14
1
1
1
0
0
0
1
-5
6
-6
5
0
0
1
ticks
30.0

OUTPUT
700
10
1174
656
10

BUTTON
13
10
76
43
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

SLIDER
34
162
206
195
nr-of-actions
nr-of-actions
0
10
5.0
1
1
NIL
HORIZONTAL

CHOOSER
13
45
206
90
game-type
game-type
"random" "random-fully-pure" "random-one-pure" "random-fully-mixed" "coordination" "Shapley" "rock-paper-scissors" "rock-paper-scissors-5" "rock-paper-5-permuted" "matching-pennies" "complex-5x5+0-9=16"
9

BUTTON
143
10
206
43
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
34
127
206
160
max-payoff
max-payoff
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
34
288
206
321
exploration-rate
exploration-rate
0
0.2
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
34
323
206
356
learning-rate
learning-rate
0
0.1
0.005
0.001
1
NIL
HORIZONTAL

BUTTON
78
10
141
43
NIL
reset
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

SLIDER
34
358
206
391
replicator-rate
replicator-rate
0
1000
150.0
10
1
NIL
HORIZONTAL

BUTTON
112
414
206
447
NIL
walk-equilibria
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

MONITOR
97
449
206
494
current-equilibrium
current-equilibrium + 1
0
1
11

TEXTBOX
66
396
204
424
Walk through Nash equilibria\n
11
0.0
1

BUTTON
24
414
110
447
NIL
walk-back
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

TEXTBOX
1185
10
1335
94
Red: Q-learning\nGreen: Replicator dynamic\nBlue: fictitious play\nYellow: Q-learning and RD\nMagenta: Q-learning and PF\nCyan: RD and FP
11
0.0
1

SLIDER
34
197
206
230
minimum-nr-of-equilibria
minimum-nr-of-equilibria
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
34
232
206
265
exact-nr-of-equilibria
exact-nr-of-equilibria
0
20
0.0
1
1
NIL
HORIZONTAL

SWITCH
9
92
99
125
abort-setup
abort-setup
1
1
-1000

SWITCH
101
92
206
125
symmetric?
symmetric?
1
1
-1000

TEXTBOX
125
271
210
289
Run parameters
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

open circle
true
0
Polygon -7500403 true true 300 150 295 189 280 225 256 256 225 280 189 295 150 300 111 295 75 280 44 256 20 225 5 189 0 150 5 111 20 75 44 44 75 20 111 5 150 0 189 5 225 20 256 44 280 75 295 111 300 150 270 150 266 119 254 90 235 65 210 46 181 34 150 30 119 34 90 46 65 65 46 90 34 119 30 150 34 181 46 210 65 235 90 254 119 266 150 270 181 266 210 254 235 235 254 210 266 181 270 150

open circle 2
true
0
Polygon -7500403 true true 300 150 295 189 280 225 256 256 225 280 189 295 150 300 111 295 75 280 44 256 20 225 5 189 0 150 5 111 20 75 44 44 75 20 111 5 150 0 189 5 225 20 256 44 280 75 295 111 300 150 290 150 285 114 271 80 249 51 220 29 186 15 150 10 114 15 80 29 51 51 29 80 15 114 10 150 15 186 29 220 51 249 80 271 114 285 150 290 186 285 220 271 249 249 271 220 285 186 290 150

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
