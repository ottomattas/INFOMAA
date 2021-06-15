breed [players player]
breed [acprofs acprof]

players-own [ matrix action frequencies decaying-frequencies opponent projected-strategy
              cumulative-rewards average-rewards geometric-rewards expected-rewards ]

acprofs-own [ old-x old-y time-here ]

patches-own [ xlabel ylabel visits ]

globals [ max-ln-visits dimension alternative-response ]

to setup
  clear-all
  set dimension run-result (word "dimens-" game-type)
  resize-world 0 (dimension - 1) 0 (dimension - 1)
  create-players 2 [
    set hidden? true
    set matrix run-result (word "matrix-" game-type)
  ]
  ask players [
    set opponent one-of other players
  ]
  create-acprofs 1 [ ht set shape "circle" set color white set size .33 set old-x -1 set old-y -1]
  set alternative-response ["best-action" "best-response" "smoothed-best-action" "smoothed-best-response" "arbitrary-action"]
  set alternative-response ["best-action"]
  reset
end

to reset
  ask players [
    set frequencies          n-values dimension [ 0 ]
    set decaying-frequencies n-values dimension [ 0 ]
    set cumulative-rewards   n-values dimension [ initial-cumulative ]
    set average-rewards      n-values dimension [ 0 ]
    set geometric-rewards    n-values dimension [ initial-geometric ]
    set expected-rewards     n-values dimension [ 1E-10 ]
  ]
  ask patches [
    set xlabel item pxcor (item (max-pycor - pycor) [ matrix ] of player 0)
    set ylabel item (max-pycor - pycor) (item pxcor [ matrix ] of player 1)
    set plabel (word xlabel ", " ylabel)
    set visits 0
    set pcolor black
    set plabel-color lime
  ]
  ask patches [
    let pxlab xlabel let pylab ylabel
    ; set yellow if in pareto front
    if not any? patches with [ (xlabel >= pxlab and ylabel > pylab) or (xlabel > pxlab and ylabel >= pylab) ] [
      set plabel-color yellow
    ]
  ]
  set max-ln-visits 3
  clear-drawing
  clear-output
  reset-ticks
end

to make-action
  run (word "exec-" ifelse-value (experimental? and random-float 1.0 < epsilon) [ one-of alternative-response ] [ "best-response"])
  set frequencies replace-item action frequencies ((item action frequencies) + 1)
  set decaying-frequencies replace-item action decaying-frequencies (
                                            (1 - learning-rate) * (item action decaying-frequencies ) + learning-rate * 1)
end

to play-action
  let other-action [ action ] of opponent
  let payoff item other-action (item action matrix)

  set projected-strategy  normalise [ frequencies ] of opponent
  set expected-rewards    map [ ?1 -> dot-product projected-strategy ?1 ] matrix

  set cumulative-rewards  replace-item action cumulative-rewards ((item action cumulative-rewards) + payoff)
  set average-rewards     replace-item action average-rewards    ((item action cumulative-rewards) / (item action frequencies))
  set geometric-rewards   replace-item action geometric-rewards  (
                                            (1 - learning-rate) * (item action geometric-rewards ) + learning-rate * payoff)

end

to exec-best-action
  set action arg-max average-rewards; greedy reinforcement
end

to exec-best-response
  set action arg-max expected-rewards; greedy fictitious play
end

to exec-smoothed-best-action
  set action soft-max average-rewards lambda ; kind of average payoff matching
end

to exec-smoothed-best-response
  set action soft-max expected-rewards lambda ; smoothed fictitious play
end

to exec-average-payoff-matching
  set action probabilistic-max average-rewards
end

to exec-cumulative-payoff-matching
  set action probabilistic-max cumulative-rewards
end

to exec-arbitrary-action
  set action random dimension
end

to go
  ask players [ make-action ]
  ask acprofs [ show-action ]
  ask players [ play-action ]
  if print-data? [
    output-print "--------------------------------------"
    foreach [ "matrix" "action" "frequencies" "expected-rewards"  ] [ ?1 -> say ?1 ] ; "cumulative-rewards" "average-rewards"
  ]
  tick
end

to say [ var ]
  output-print (word var ": "  map [ ?1 -> prec [ run-result var ] of ?1 2 ] sort players)
end

to-report prec [ l k ]
  if is-number? l [ report precision l k ]
  report map [ ?1 -> prec ?1 k ] l
end

to show-action
  let x [ action ] of player 0
  let y (max-pycor - [ action ] of player 1)
  if-else animate? [
    let new-tile x != old-x or y != old-y
    if new-tile [
      set shape "default"
      if count-visits? [ set plabel-color black ]
      facexy x y let dd (distancexy x y) / 1000 repeat 1000 [ fd dd display ]
    ]
    setxy x y
    if new-tile [ set time-here 0 set old-x x set old-y y ]
    set time-here time-here + 1
    if count-visits? [ set plabel time-here ]
  ] [
    setxy x y
  ]
  set visits visits + 1
  if ln visits > max-ln-visits [ set max-ln-visits ln visits ]
  set pcolor scale-color red (ln visits) 0 (1.5 * max-ln-visits)
  ;
  if hidden? [ st pd ]
end

;-- game definition ---------------------------------------------------


to-report dimens-random report nr-of-actions end
to-report matrix-random report n-values dimension [ n-values dimension [ random max-payoff ] ] end

to-report dimens-Shapley report 3 end
to-report matrix-Shapley report (list (list 0 0 1) (list 1 0 0) (list 0 1 0)) end

to-report dimens-prisoner report 2 end
to-report matrix-prisoner report (list (list 3 0) (list 5 1)) end

to-report dimens-hawk-dove report 2 end
to-report matrix-hawk-dove report (list (list 0 3) (list 1 2)) end

to-report dimens-sqrt-2 report 2 end
to-report matrix-sqrt-2
  report ifelse-value (who = 0) [
    (list (list 1 0) (list 0 precision sqrt 2 3))
  ] [
    (list (list precision sqrt 2 3 0) (list 0 1))
  ]
end

to-report dimens-BoS report 2 end
to-report matrix-BoS
  report ifelse-value (who = 0) [
    (list (list 1 0) (list 0 2))
  ] [
    (list (list 2 0) (list 0 1))
  ]
end

to-report dimens-matching-pennies report 2 end
to-report matrix-matching-pennies
  report ifelse-value (who = 0) [
    (list (list 1 -1) (list -1 1))
  ] [
    (list (list -1 1) (list 1 -1))
  ]
end
   ; set matrix (list (list 10 0 penalty) (list 0 2 0) (list penalty 0 10)) ; penalty game
   ; set matrix (list (list 11 -30 0) (list -30 7 6) (list 0 0 5)) ; climbing game

;-- low level subroutines ---------------------------------------------

to-report dot-product [ l1 l2 ]
  report sum (map [ [?1 ?2] -> ?1 * ?2 ] l1 l2)
end

to-report arg-max [ l ]
  let indices n-values length l [ ?1 -> ?1 ]
  let maximum max l
  report one-of filter [ ?1 -> item ?1 l = maximum ] indices
end

to-report probabilistic-max [ l ]
  let cut random-float (sum l)
  let i -1 let s 0
  while [ s < cut ] [
    set i i + 1
    set s s + item i l
  ]
  report ifelse-value (i < 0) [ random length l ] [ i ]
end

to-report soft-max [ l tau ]
  let l-normalised normalise l
  let l-normalised-logit logit l-normalised tau
  report probabilistic-max l-normalised-logit
end

to-report random-proportion [ n ]
  report normalise n-values n [ 0 - ln (random-float 1.0) ] ; [ x0, x1, ..., x(n-1) ] sum to 1.0
end

to-report logit [ l tau ]
  report map [ ?1 -> exp(?1 / tau) ] l
end

to-report normalise [ l ]
  let s sum l
  if s = 0 [ report random-proportion length l ]
  report map [ ?1 -> ?1 / s ] l
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
577
378
-1
-1
51.33333333333334
1
12
1
1
1
0
0
0
1
0
6
0
6
1
1
1
ticks
30.0

SLIDER
35
130
207
163
nr-of-actions
nr-of-actions
0
10
7.0
1
1
NIL
HORIZONTAL

BUTTON
145
10
208
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
80
45
143
78
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
35
165
207
198
epsilon
epsilon
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
35
200
207
233
initial-cumulative
initial-cumulative
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
35
235
207
268
initial-geometric
initial-geometric
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
35
270
207
303
learning-rate
learning-rate
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
35
305
207
338
max-payoff
max-payoff
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
35
340
207
373
penalty
penalty
-100
0
-15.0
1
1
NIL
HORIZONTAL

CHOOSER
18
80
208
125
game-type
game-type
"random" "hawk-dove" "BoS" "sqrt-2" "matching-pennies" "Shapley" "rochambault"
0

SLIDER
35
375
207
408
lambda
lambda
0
1
0.1
0.001
1
NIL
HORIZONTAL

BUTTON
40
10
142
43
NIL
clear-drawing
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

OUTPUT
581
10
1031
710
12

SWITCH
90
445
207
478
print-data?
print-data?
1
1
-1000

SWITCH
105
480
207
513
animate?
animate?
0
1
-1000

SWITCH
75
515
207
548
experimental?
experimental?
1
1
-1000

BUTTON
15
45
78
78
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

SWITCH
85
410
207
443
count-visits?
count-visits?
1
1
-1000

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
