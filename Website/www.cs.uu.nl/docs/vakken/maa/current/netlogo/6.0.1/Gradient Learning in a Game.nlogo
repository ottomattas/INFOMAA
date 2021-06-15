globals [ color-back color-particle color-trail gradient-x gradient-y eigenvalues ]

breed [ profiles profile ]
breed [ stables stable ]

profiles-own [ avg-row-strat avg-col-strat updates ]

to setup
  clear-all

  ifelse black-and-white
    [ set color-back white set color-particle 103   set color-trail 14   ]
    [ set color-back black set color-particle blue  set color-trail red  ]

  ask patches [ set pcolor color-back ]

  set-default-shape stables "circle"

  let raster ceiling (10 * world-width / nr-of-strategy-profiles)

  ask patches with [pxcor mod raster = 0 and pycor mod raster = 0] [
    sprout-profiles 1 [
      set color color-particle
      set size 2
      setxy pxcor pycor
      set avg-row-strat xcor / 100
      set avg-col-strat ycor / 100
      set updates 0
      pd
    ]
  ]

  reset-ticks
end

to go
  ask profiles [ move ]
  tick
  if ticks > max-ticks [ setup ]
end


to move

  let row-strat xcor / 100
  let col-strat ycor / 100

; set payoff-row
;        row-strat  *      col-strat  * payoff-row-CC +
;        row-strat  * (1 - col-strat) * payoff-row-CD +
;   (1 - row-strat) *      col-strat  * payoff-row-DC +
;   (1 - row-strat) * (1 - col-strat) * payoff-row-DD
;
; set payoff-col
;        row-strat  *      col-strat  * payoff-col-CC +
;        row-strat  * (1 - col-strat) * payoff-col-CD +
;   (1 - row-strat) *      col-strat  * payoff-col-DC +
;   (1 - row-strat) * (1 - col-strat) * payoff-col-DD

  let payoff-row-deriv col-strat * (
    payoff-row-CC - payoff-row-CD - payoff-row-DC + payoff-row-DD ) +
    payoff-row-CD - payoff-row-DD - correction * ( row-strat - avg-row-strat )

  let payoff-col-deriv row-strat * (
    payoff-col-CC - payoff-col-CD - payoff-col-DC + payoff-col-DD ) +
    payoff-col-DC - payoff-col-DD - correction * ( col-strat - avg-col-strat )

  if payoff-row-deriv = 0 and payoff-col-deriv = 0 [ set breed stables stop ]

  set heading (atan payoff-row-deriv payoff-col-deriv) + (random-float 2 * perturbe-heading) - perturbe-heading

  if xcor < min-pxcor [
    if 270 < heading                   [ set heading   0 ]
    if 180 < heading and heading < 270 [ set heading 180 ]
  ]
  if xcor > max-pxcor [
    if   0 < heading and heading <  90 [ set heading   0 ]
    if  90 < heading and heading < 180 [ set heading 180 ]
  ]
  if ycor < min-pycor [
    if  90 < heading and heading < 180 [ set heading  90 ]
    if 180 < heading and heading < 270 [ set heading 270 ]
  ]
  if ycor > max-pycor [
    if   0 < heading and heading <  90 [ set heading  90 ]
    if 270 < heading                   [ set heading 270 ]
  ]

  set color color-trail
  fd delta * sqrt ( payoff-row-deriv ^ 2 + payoff-col-deriv ^ 2 )
  set color color-particle

  if ticks mod 100 = 0 [
    set updates updates + 1
    set avg-row-strat ((updates - 1) * avg-row-strat + row-strat) / updates
    set avg-col-strat ((updates - 1) * avg-row-strat + col-strat) / updates
  ]

end

to set-gradient-formula
  let u1 precision (payoff-row-CC - payoff-row-CD + payoff-row-DD - payoff-row-DC) 2
  let u2 precision (payoff-row-CD - payoff-row-DD) 2
  let v1 precision (payoff-col-CC - payoff-col-DC + payoff-col-DD - payoff-col-CD) 2
  let v2 precision (payoff-col-DC - payoff-col-DD) 2
  set gradient-x (word " " u1 " * y + " u2)
  set gradient-y (word " " v1 " * x + " v2)
  set eigenvalues ifelse-value (u1 * v1 > 0) [ "real" ] [ "complex" ]
end

;-----------------------------------------------------------------------------------------

to prisoner-dilemma
  setup
  set payoff-row-CC  3
  set payoff-row-CD  0
  set payoff-row-DC  5
  set payoff-row-DD  1
  make-symmetric
  set-gradient-formula
end

to game-of-chicken
  setup
  set payoff-row-CC  0
  set payoff-row-CD -1
  set payoff-row-DC  1
  set payoff-row-DD -3
  make-symmetric
  set-gradient-formula
end

to stag-hunt
  setup
  set payoff-row-CC  5
  set payoff-row-CD  0
  set payoff-row-DC  3
  set payoff-row-DD  2
  make-symmetric
  set-gradient-formula
end

to matching-pennies
  setup
  set payoff-row-CC   1
  set payoff-row-CD  -1
  set payoff-row-DC  -1
  set payoff-row-DD   1
  make-zerosum
  set-gradient-formula
end

to battle-of-the-sexes
  setup
  set payoff-row-CC  0
  set payoff-row-CD  2
  set payoff-row-DC  3
  set payoff-row-DD  1
  make-symmetric
  set-gradient-formula
end

to hawk-dove
  setup
  set payoff-row-CC  -2
  set payoff-row-CD  2
  set payoff-row-DC  0
  set payoff-row-DD  1
  make-symmetric
  set-gradient-formula
end

to rock-paper
  setup
  set payoff-row-CC  0
  set payoff-row-CD  3
  set payoff-row-DC  1
  set payoff-row-DD  2
  set payoff-col-CC  3
  set payoff-col-CD  2
  set payoff-col-DC  0
  set payoff-col-DD  1
  set-gradient-formula
end

to random-game
  set payoff-row-CC -3 + random 7
  set payoff-row-CD -3 + random 7
  set payoff-row-DC -3 + random 7
  set payoff-row-DD -3 + random 7
  set payoff-col-CC -3 + random 7
  set payoff-col-CD -3 + random 7
  set payoff-col-DC -3 + random 7
  set payoff-col-DD -3 + random 7
  repeat 3 [
    setup
    set-gradient-formula
    repeat 14 / delta [ go ]
  ]
end

to imaginary-eigenvalue
  setup
  set payoff-row-CC  0
  set payoff-row-CD  6
  set payoff-row-DC  2
  set payoff-row-DD  4
  set payoff-col-CC  3
  set payoff-col-CD  2
  set payoff-col-DC  0
  set payoff-col-DD  1
  set-gradient-formula
end

to coordination-game
  setup
  set payoff-row-CC  1
  set payoff-row-CD  0
  set payoff-row-DC  0
  set payoff-row-DD  1
  set payoff-col-CC  1
  set payoff-col-CD  0
  set payoff-col-DC  0
  set payoff-col-DD  1
  set-gradient-formula
end

to anti-coordination
  setup
  set payoff-row-CC  1
  set payoff-row-CD  0
  set payoff-row-DC  0
  set payoff-row-DD -1
  set payoff-col-CC -1
  set payoff-col-CD  0
  set payoff-col-DC  0
  set payoff-col-DD  1
  set-gradient-formula
end

to coordination-negpayoffs
  setup
  set payoff-row-CC   1
  set payoff-row-CD  -1
  set payoff-row-DC  -1
  set payoff-row-DD   1
  make-symmetric
  set-gradient-formula
end

to make-symmetric
  set payoff-col-CC payoff-row-CC
  set payoff-col-CD payoff-row-DC
  set payoff-col-DC payoff-row-CD
  set payoff-col-DD payoff-row-DD
  set-gradient-formula
end

to make-zerosum
  set payoff-col-CC 0 - payoff-row-CC
  set payoff-col-CD 0 - payoff-row-CD
  set payoff-col-DC 0 - payoff-row-DC
  set payoff-col-DD 0 - payoff-row-DD
  set-gradient-formula
end
@#$#@#$#@
GRAPHICS-WINDOW
188
10
711
534
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
102
0
102
1
1
1
ticks
30.0

BUTTON
58
10
121
43
NIL
setup
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
123
10
186
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
716
10
888
43
payoff-row-CC
payoff-row-CC
-10
10
-2.0
1
1
NIL
HORIZONTAL

SLIDER
716
45
888
78
payoff-row-CD
payoff-row-CD
-10
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
716
80
888
113
payoff-row-DC
payoff-row-DC
-10
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
716
115
888
148
payoff-row-DD
payoff-row-DD
-10
10
-2.0
1
1
NIL
HORIZONTAL

SLIDER
716
160
888
193
payoff-col-CC
payoff-col-CC
-10
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
716
230
888
263
payoff-col-CD
payoff-col-CD
-10
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
716
195
888
228
payoff-col-DC
payoff-col-DC
-10
10
-3.0
1
1
NIL
HORIZONTAL

SLIDER
716
265
888
298
payoff-col-DD
payoff-col-DD
-10
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
14
115
186
148
delta
delta
0
0.2
0.05
0.001
1
NIL
HORIZONTAL

SLIDER
14
80
186
113
nr-of-strategy-profiles
nr-of-strategy-profiles
20
1000
200.0
10
1
NIL
HORIZONTAL

BUTTON
49
290
186
323
NIL
prisoner-dilemma
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
325
186
358
NIL
game-of-chicken
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
395
186
428
NIL
battle-of-the-sexes
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
360
186
393
NIL
stag-hunt
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
716
310
766
355
CC-row
payoff-row-CC
0
1
11

MONITOR
766
310
816
355
CC-col
payoff-col-CC
0
1
11

MONITOR
821
310
871
355
CD-row
payoff-row-CD
0
1
11

MONITOR
871
310
921
355
CD-col
payoff-col-CD
0
1
11

MONITOR
716
359
766
404
DC-row
payoff-row-DC
0
1
11

MONITOR
766
359
816
404
DC-col
payoff-col-DC
0
1
11

MONITOR
821
359
871
404
DD-row
payoff-row-DD
0
1
11

MONITOR
871
359
921
404
DD-col
payoff-col-DD
0
1
11

BUTTON
49
465
186
498
NIL
random-game
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
185
186
218
correction
correction
0
0.5
0.0
0.001
1
NIL
HORIZONTAL

SLIDER
14
150
186
183
perturbe-heading
perturbe-heading
0
50
0.0
1
1
NIL
HORIZONTAL

SWITCH
716
410
858
443
black-and-white
black-and-white
0
1
-1000

MONITOR
717
446
807
491
NIL
gradient-x
17
1
11

MONITOR
717
494
807
539
NIL
gradient-y
17
1
11

BUTTON
49
255
186
288
NIL
coordination-game
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
430
186
463
NIL
matching-pennies
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
810
446
933
481
NIL
set-gradient-formula
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
500
186
533
NIL
random-game
T
1
T
OBSERVER
NIL
R
NIL
NIL
1

SLIDER
14
45
186
78
max-ticks
max-ticks
0
10000
300.0
100
1
NIL
HORIZONTAL

BUTTON
49
220
186
253
NIL
hawk-dove
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
809
494
888
539
NIL
eigenvalues
0
1
11

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
