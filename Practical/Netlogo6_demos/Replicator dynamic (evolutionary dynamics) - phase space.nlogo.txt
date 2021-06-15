extensions [ shell ]

globals [ sqrt-3 species current-fitness-matrix indicate-speed?-old restart? ]

breed [ frame-drawers frame-drawer ]
breed [ equilibria-indicators equilibria-indicator ]

breed [ riders rider ]
riders-own [
  my-initial-proportion ; proportion to retrun to if restart
  my-proportion         ; actual proportion
  my-proportion-old     ; previous proportion (initially 'nobody')
  speed
]

to setup
  ca
  ;
  set sqrt-3 sqrt 3
  ask patches [ set pcolor white ]
  set species n-values nr-of-species [ ?1 -> ?1 ] ; 0, 1, 2, ..., n-1
  create-all-riders
  set-matrix-and-compute-equilibria
  color-all-turtles ; this includes the equilibria-indicators
  ;
  create-frame-drawers 0 [ setxy 0 (max-pxcor + 1) set color black set pen-size 3 pd set hidden? true ]
  draw-frame
  ;
  set restart? false
  reset-ticks
  repeat do-already-N-ticks [ go ]
end

to create-all-riders
  foreach n-values (nr-of-riders-per-edge + 1) [ ?1 -> ?1 ] [ ?1 ->
    let p-0 ?1
    foreach n-values (nr-of-riders-per-edge + 1 - p-0) [ ??1 -> ??1 ] [ ??1 ->
      let p-1 ??1
      create-riders 1 [
        set pen-size 2
        let begin-0 p-0 / nr-of-riders-per-edge
        let begin-1 p-1 / nr-of-riders-per-edge
        set my-initial-proportion initial-proportion begin-0 begin-1
        set-or-return-to-initial-proportion
      ]
    ]
  ]
end

to restart
  set restart? true
end

to draw-frame
  ask frame-drawers [
    setxy 0 (max-pxcor + 1) set heading 150
    repeat 3 [ fd (max-pxcor + 1) * sqrt-3 rt 120 ]
  ]
end

to color-all-turtles
  ask riders [
    if-else indicate-speed? [
      set size 0.8 set shape "default white black" set color black     pen-down
    ] [
      set size 0.4 set shape "circle"              set color random 30 pen-up
    ]
  ]
  ask equilibria-indicators [ set color ifelse-value indicate-speed? [ black ] [ red ] ]
  clear-drawing ; remove tracks of other colors
end

to set-or-return-to-initial-proportion
  set my-proportion-old nobody
  set my-proportion my-initial-proportion
  pen-up
  transport-to-new-location
  set speed 0
  pen-down
end

to set-repli-proportion
  set my-proportion-old my-proportion
  set my-proportion normalise map [ ?1 -> (item ?1 my-proportion) * (1 + beta + score ?1) ] species
  if mutation-factor > 0 [ set my-proportion mutate my-proportion ]
  set my-proportion bump-up-the-negative my-proportion ; replicator should map positive on positive; unfortunately that's not happening due to rounding errors
  transport-to-new-location
end

to go
  if indicate-speed? != indicate-speed?-old [
    color-all-turtles
    set indicate-speed?-old indicate-speed?
  ]
  ask riders [
    if-else restart? or random-float 1.0 < probability-to-restart [ set-or-return-to-initial-proportion ] [ set-repli-proportion ]
  ]
  draw-frame
  tick
  set restart? false
  if restart-after-N-ticks != 0 and ticks > restart-after-N-ticks [ set restart? true reset-ticks ]
end

to color-by-speed
  if my-proportion-old = nobody [ set size 0.8 set shape "default white black" stop ]
  set speed euclidian-distance my-proportion-old my-proportion
  let h (170 + speed-color-shift * 255 * speed) mod 256 ; 170 = blue
  let s  200
  let b (100 + speed-color-shift * 100 * speed) mod 256 ; 170 = blue
  set color __hsb-old h s b
  set shape ifelse-value (not plot-stationary-points or speed > epsilon-for-stationary or any-better-stationary-in-neighbourhood?) [ "default white black" ] [ "circle" ]
end

to-report any-better-stationary-in-neighbourhood?
  report any? other riders in-radius (max-pxcor * stationary-neighbourhood) with [ speed < [ speed ] of myself ]
end

to transport-to-new-location
  let x item 0 my-proportion
  let y item 1 my-proportion
  let triangle-x 0.5 * sqrt-3 * (y - x)  ; convert (x, y) with x + y <= 1 to ternary plot
  let triangle-y 1.0 - 1.5 * x - 1.5 * y
  if my-proportion-old != nobody [
    facexy (max-pxcor + 1) * triangle-x (max-pxcor + 1) * triangle-y
  ]
  if indicate-speed? [ color-by-speed ]
  setxy (max-pxcor + 1) * triangle-x (max-pxcor + 1) * triangle-y
; set size 0.99 * size
end

to-report random-proportion
  ; https://stats.stackexchange.com/questions/14059/generate-uniformly-distributed-weights-that-sum-to-unity
  report normalise n-values nr-of-species [ 0 - ln (random-float 1.0) ] ; [ x0, x1, ..., x(n-1) ] sum to 1.0
end

to-report initial-proportion [ p-0 p-1 ] ; random my-proportion with first two coordinates already chosen
  let prop n-values (nr-of-species - 2) [ 0 - ln (random-float 1.0) ] ; choose rest randomly
  let the-sum sum prop
  set prop map [ ?1 -> (1 - p-0 - p-1) / the-sum * ?1 ] prop ; make sure the rest sums up to 1 - p-0 - p-1
  report fput p-0 (fput p-1 prop)
end

; ----------------------------------------------------------------------------------------------------------

to-report random-matrix
  report n-values nr-of-species [ n-values nr-of-species [ lowest-payoff + random (highest-payoff + 1) ] ]
end

to-report interesting-1-matrix
  set nr-of-species 3
  report [[1 3 1] [1 2 3] [4 1 3]]
end

to-report interesting-2-matrix
  set nr-of-species 3
  report [[2 1 3] [3 1 0] [2 2 2]]
end

to-report interesting-3-matrix
  set nr-of-species 7
  report [[1 1 3 4 4 2 2] [2 1 1 3 1 2 2] [4 2 2 2 3 4 3] ; a 7x7 matrix
    [1 3 3 4 2 2 3] [1 1 2 4 3 4 3] [3 1 2 3 3 2 1] [2 1 4 2 1 2 1]]
end

to-report interesting-4-matrix
  set nr-of-species 3
  report [[0 3 8] [6 10 0] [4 10 1]]

end

to-report interesting-5-matrix
  set nr-of-species 3
  report [[6 1 6] [4 10 1] [8 5 1]]
end

to-report rock-paper-scissors-matrix
  set nr-of-species 3
  report (list (list 1 (2 + rps-parameter) 0) (list 0 1 (2 + rps-parameter)) (list (2 + rps-parameter)  0 1))
end

to-report Shapley-matrix
  set nr-of-species 3
  report [[0 1 -1] [-1 0 1] [1 -1 0]]
end

to-report shaked-Shapley-matrix
  set nr-of-species 3
; anti:  [[0 0 1] [1 0 0] [0 1 0]]
; clock: [[0 1 0] [0 0 1] [1 0 0]]
  let l []
  let a random 2
  let b a + random 2
  let c b + random 2
  set l lput (list (b + rr) (c + rr) (a + rr)) l
  set l lput (list (a + rr) (b + rr) (c + rr)) l
  set l lput (list (c + rr) (a + rr) (b + rr)) l
  report l
end

to-report rr
  report 0
  report (-1 + random 3) / 2
end

to-report NE-but-not-stable-matrix
  set nr-of-species 3
  report [[0 1 0] [0 0 2] [0 0 1]]
end

to-report ASS-but-not-ES-matrix ; Excercise 7.4.5 Hofbauer & Sigmund
  set nr-of-species 3
  report [[0 2 0] [2 0 2] [1 1 1]]
end

to-report invasion-matrix ; Excercise 7.4.6 Hofbauer & Sigmund
  set nr-of-species 3
  report [[0 3 1] [3 0 1] [1 1 1]]
end

to-report Cooperation-defection-TFT-matrix
  set nr-of-species 3
  report [[3 0 3] [5 1 1] [3 1 3]]
end

to-report custom-matrix
  let my-matrix read-from-string custom-fitness-matrix
  if not is-list? my-matrix or not empty? filter [ ?1 -> not is-list? ?1 ] my-matrix [
    user-message "Custom fitness-matrix must be a list of lists."
  ]
  set nr-of-species length my-matrix
  report my-matrix
end

;
to-report score [ i ]
  let pure-score sum map [ ?1 -> (item ?1 my-proportion) * (item ?1 (item i current-fitness-matrix)) ] species
  report ifelse-value (perturb-factor > 0) [ perturb pure-score ] [ pure-score ]
end

; mutate list
to-report mutate [ l ]
  let the-mean mean l
  report map [ ?1 -> ?1 + the-mean * random-float mutation-factor ] l
end

; make list sum to one while respecting my-proportion
to-report normalise [ l ]
  let the-sum sum l
  report map [ ?1 -> ?1 / the-sum ] l
end

to-report bump-up-the-negative [ l ] ; replicator should map positive on positive; unfortunately that's not happening due to rounding errors
  report map [ ?1 -> ifelse-value (?1 >= 0) [ ?1 ] [ 0 ] ] l
end

to-report uniform-list [ n ]
  report n-values n [ 1 / n ]
end

; Gaussian deviation; make sure that the result is positive
to-report perturb [ x ]
  report max (list 0 random-normal x perturb-factor)
end

to increase-perturbation
  set perturb-factor precision (perturb-factor + 0.01) 4
end

to decrease-perturbation
  set perturb-factor precision (perturb-factor - 0.01) 4
end

to-report euclidian-distance [ u v ]
  report reduce [ [?1 ?2] -> ?1 + ?2 ] (map [ [?1 ?2] -> (?1 - ?2) ^ 2 ] u v)
end

to-report max-distance [ u v ]
  report reduce [ [?1 ?2] -> max (list ?1 ?2) ] (map [ [?1 ?2] -> abs (?1 - ?2) ] u v)
end

to dump [ id ]
  ; (shell:fork "del" "/Q" "c:/temp/img/*.*")
  export-view (word "C:/Onderwijs/MAL/slides/img_old/ReplicatorPhase_" id ".png")
end

to correct
  ask min-one-of riders with [ shape ="circle" ] [ distancexy mouse-xcor mouse-ycor ] [
    setxy mouse-xcor mouse-ycor
    display
  ]
end

;-------------------------------------------

to set-matrix-and-compute-equilibria
  set current-fitness-matrix run-result (word fitness-matrix "-matrix")
  compute-equilibria
  compute-dominated-strategies
end

to compute-equilibria
  let dimension length current-fitness-matrix
  let gambit-input (word "NFG 1 R \"\" { \"1\" \"2\" } { " dimension " " dimension " }")
  foreach n-values dimension [ i -> i ] [ a ->
    foreach n-values dimension [ i -> i ] [ b ->
      set gambit-input (word gambit-input " "
        item a (item b current-fitness-matrix) " " item b (item a current-fitness-matrix))
    ]
  ]
  shell:setenv "GAMBIT_INPUT" gambit-input ; no newlines; don't know how to put multiple lines into an env. variable
  let gambit-output (shell:exec "cmd" "/c" "echo" "%GAMBIT_INPUT%" "|" "C:/Program Files (x86)/Gambit/gambit-enummixed.exe" "-q") ;
  ;print what gambit said
  ;output-print (word "Input:\n" gambit-input)
  output-print (word "Equilibria:\n" gambit-output)
  let equilibria []
  foreach split-string but-last gambit-output "\n" [ ?1 ->
    let equilibrium split-string but-last ?1 ","
    let equilibrium-type ifelse-value (position "/" ?1 = false) [ "pure " ] [ "mixed" ]
    let equilibrium-strategies map [ j -> sublist equilibrium (1 + j * dimension) (1 + (j + 1) * dimension) ] [ 0 1 ]
    let equilibrium-symmetric ifelse-value (equal-lists? item 0 equilibrium-strategies item 1 equilibrium-strategies) [ "symmetric" ] [ "asymmetric" ]
    set equilibria lput (list equilibrium-type equilibrium-symmetric equilibrium-strategies) equilibria
  ]
  let equilibria-symmetric filter [ ?1 -> item 1 ?1 = "symmetric" ] equilibria
  output-print (word "There is/are " length equilibria " equilibria, " length equilibria-symmetric " symmetric.\n")
  foreach equilibria-symmetric [ ?1 ->
    output-print ?1
    create-equilibria-indicators 1 [
      set shape "open circle 2"
      set size 3
      set color black
      let x to-decimal item 0 item 0 item 2 ?1
      let y to-decimal item 1 item 0 item 2 ?1

  let triangle-x 0.5 * sqrt-3 * (y - x)  ; convert (x, y) with x + y <= 1 to ternary plot
  let triangle-y 1.0 - 1.5 * x - 1.5 * y ;
      setxy (max-pxcor + 1) * triangle-x (max-pxcor + 1) * triangle-y
    ]
  ]
end

to-report equal-lists? [l1 l2]
  (foreach l1 l2 [ [?1 ?2] -> if ?1 != ?2 [ report false ] ]) report true
end

to-report split-string [w s]
  let i position s w
  if not is-number? i [ report ifelse-value (w = "") [ [] ] [ (list w) ] ]
  report fput (substring w 0 i) split-string substring w (i + length s) length w s
end

to-report to-decimal [ s ]
  let i position "/" s
  if not is-number? i [ report run-result s ]
  report run-result replace-item i s " / "
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
    ; if x + error < middle
    if-else middle-d * (x + err) < middle-n [
      ; middle is our new upper
      set upper-n middle-n
      set upper-d middle-d
    ] [
    ; else if middle < x - error
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

;----------------------------------------------------------------

to compute-dominated-strategies
  output-print "\nDominated strategies:"
  iterated-elimination-by-domination current-fitness-matrix "strict"
  iterated-elimination-by-domination current-fitness-matrix "weak"
end

to iterated-elimination-by-domination [ m how ]
  let n 1E9
  while [ length m < n ] [
    set n length m
    set m single-elimination-by-domination m how
  ]
end

to-report single-elimination-by-domination [ m how ]
  output-print (word "given: " m)
  foreach n-values length m [ ?1 -> ?1 ] [ ?1 ->
    let i ?1
    foreach n-values length m [ ??1 -> ??1 ] [ ??1 ->
      let j ??1
      if i != j and dominates item j m item i m how [
        output-print (word "row " j " " how "ly dominates row " i)
        report remove-item i map [ ???1 -> remove-item i ???1 ] m
      ]
    ]
  ]
  output-print (word "no further " how " domination\n")
  report m
end

to-report dominates [ major minor how ]
  (foreach minor major [ [?1 ?2] ->
      if ?1 >= ?2 [
        if-else how = "strict" [ report false ] [
          if ?1 > ?2  [ report false ]
        ]
      ]
  ])
  report true
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
943
669
-1
-1
25.0
1
10
1
1
1
0
0
0
1
-14
14
-9
16
1
1
1
ticks
30.0

BUTTON
80
10
143
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

BUTTON
145
45
208
78
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
36
80
208
113
nr-of-iterations-per-step
nr-of-iterations-per-step
0
100
15.0
1
1
NIL
HORIZONTAL

BUTTON
80
45
143
78
steps
repeat nr-of-iterations-per-step [ go ]
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

SLIDER
36
360
208
393
nr-of-species
nr-of-species
1
10
3.0
1
1
NIL
HORIZONTAL

CHOOSER
36
395
208
440
fitness-matrix
fitness-matrix
"custom" "random" "Shapley" "shaked-Shapley" "rock-paper-scissors" "NE-but-not-stable" "ASS-but-not-ESS" "ASS-but-not-ES" "Cooperation-defection-TFT" "invasion" "interesting-1" "interesting-2" "interesting-3" "interesting-4" "interesting-5"
1

SLIDER
36
512
208
545
lowest-payoff
lowest-payoff
-10
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
36
477
208
510
highest-payoff
highest-payoff
-10
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
36
582
208
615
perturb-factor
perturb-factor
0
0.2
0.0
0.001
1
NIL
HORIZONTAL

INPUTBOX
947
10
1120
70
custom-fitness-matrix
[[2 1 0] [3 3 0] [2 0 3]]
1
0
String

SLIDER
36
185
208
218
probability-to-restart
probability-to-restart
0
5E-1
0.0
5E-2
1
NIL
HORIZONTAL

SLIDER
36
547
208
580
beta
beta
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
36
617
208
650
mutation-factor
mutation-factor
0
0.1
0.0
0.001
1
NIL
HORIZONTAL

SLIDER
36
220
208
253
nr-of-riders-per-edge
nr-of-riders-per-edge
0
100
24.0
1
1
NIL
HORIZONTAL

MONITOR
1122
25
1313
70
NIL
current-fitness-matrix
17
1
11

OUTPUT
947
72
1313
568
10

SLIDER
36
325
208
358
speed-color-shift
speed-color-shift
0
1E5
3000.0
1E3
1
NIL
HORIZONTAL

SLIDER
36
150
208
183
restart-after-N-ticks
restart-after-N-ticks
0
1E2
0.0
1E0
1
NIL
HORIZONTAL

SLIDER
36
442
208
475
RPS-parameter
RPS-parameter
-10
10
3.5
0.5
1
NIL
HORIZONTAL

BUTTON
1124
606
1232
639
redraw-frame
draw-frame
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
145
10
208
43
restart
set restart? true
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

BUTTON
36
290
208
323
toggle-speed-indicator
set indicate-speed? not indicate-speed?
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

SWITCH
36
255
208
288
indicate-speed?
indicate-speed?
0
1
-1000

SLIDER
947
606
1122
639
epsilon-for-stationary
epsilon-for-stationary
0
5E-7
3.0E-7
5E-9
1
NIL
HORIZONTAL

SLIDER
947
641
1122
674
stationary-neighbourhood
stationary-neighbourhood
0
5E-1
0.2
5E-3
1
NIL
HORIZONTAL

SWITCH
947
571
1122
604
plot-stationary-points
plot-stationary-points
0
1
-1000

BUTTON
1124
571
1195
604
NIL
correct
T
1
T
OBSERVER
NIL
C
NIL
NIL
1

SLIDER
36
115
208
148
do-already-N-ticks
do-already-N-ticks
0
100
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
1134
646
1284
674
Create invisible high-resolution riders for the rest points.
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

circle black
false
0
Circle -16777216 true false 0 0 300

circle gray
false
14
Circle -7500403 true false 0 0 300

circle3
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240

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

default red black
true
0
Polygon -16777216 true false 150 -30 0 270 150 180 300 270
Polygon -2674135 true false 150 0 30 240 150 165 270 240

default shaded black
true
0
Polygon -16777216 true false 150 -30 0 270 150 180 300 270
Polygon -7500403 true true 150 0 30 240 150 165 270 240

default white black
true
0
Polygon -16777216 true false 150 -30 0 270 150 180 300 270
Polygon -1 true false 150 0 30 240 150 165 270 240

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
<experiments>
  <experiment name="Experiment" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>map [ precision ? 5 ] start-proportions</metric>
    <metric>map [ precision ? 5 ] proportions</metric>
  </experiment>
</experiments>
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
