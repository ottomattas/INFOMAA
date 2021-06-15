extensions [ array ]

globals [
  rounds
  nr-shift-gears
  all-actions ; typically: [0 1 2 3 4]
  realisation ; an immediate payoff vector for all actions
  ;
  mean-of ; a vector of means for all actions
  devn-of ; a vector of deviations for all actions
  ;
  lastval ; last value of player's action
  freqncy ; player's frequency of actions
  tot-rwd ; total reward of player's actions
  geo-avg ; geometric average of player's actions (see geometric-avg-rate-player)
  ;
  tot-com ; total reward of computer's actions
  freqcom ; computer's frequency of actions
  geo-com ; geometric average of computer's actions (see geometric-avg-rate-comptr)
  ;
  action-player action-comptr action-random ; current action
  reward-player reward-comptr reward-random ; immediate payoff
  payoff-player payoff-comptr payoff-random ; total payoff
]

to setup
  ca
  ;
  set rounds 0
  set nr-shift-gears 0
  set all-actions n-values (max-pxcor + 1) [ ? ]
  ;
  set mean-of make-array "random-float 15" 
  if cheat [ print-mean-payoffs ]
  ; to ensure positive payoffs, ensure that deviation of uniform distribution is not too high
  set devn-of array:from-list map [ random-float (? / sqrt(3)) ] array:to-list mean-of
  ;
  set lastval make-array "hyphen"
  set freqncy make-array "0"
  set tot-rwd make-array "0"
  set geo-avg make-array "10"
  ;
  set tot-com make-array "0"
  set freqcom make-array "0"
  set geo-com make-array "10"
  ;
  set payoff-player 0
  set payoff-comptr 0
  set payoff-random 0
end

to-report make-array [ x ]
  report array:from-list n-values (max-pxcor + 1) [ run-result x ]
end

to-report hyphen
  report "-"
end
  
to c [ x ]
  set rounds rounds + 1
  if allow-shift-gears and random-float 1.0 < probability-shift-gears [ shift-gears ]
  set action-player (x - 1)
  set action-comptr  y
  set action-random  z
  color-patches
  set realisation map [ give-immediate-reward ? ] all-actions
  compute-reward-player
  compute-reward-comptr
  compute-reward-random
end

to explore
  foreach all-actions [ c (? + 1) ]
end

to shift-gears
  let x random-pxcor
  array:set mean-of x random-float 15
  array:set devn-of x random-float ((array:item mean-of x) / sqrt(3))
  set nr-shift-gears nr-shift-gears + 1
  if cheat [ print-mean-payoffs ]
end

to compute-reward-player
  set reward-player item action-player realisation
  set payoff-player payoff-player + reward-player
  set-current-plot "Average reward"
  set-current-plot-pen "Human player"
  plot payoff-player / rounds
  array:set lastval action-player reward-player
  array:set freqncy action-player (1      + array:item freqncy action-player)
  array:set tot-rwd action-player (reward-player + array:item tot-rwd action-player)
  array:set geo-avg action-player geometric-update array:item geo-avg action-player reward-player geometric-avg-rate-player
end

to compute-reward-comptr
  set reward-comptr item action-comptr realisation
  set payoff-comptr payoff-comptr + reward-comptr
  set-current-plot-pen "Computer player"
  plot payoff-comptr / rounds
  array:set freqcom action-comptr (1      + array:item freqcom action-comptr)
  array:set tot-com action-comptr (reward-comptr + array:item tot-com action-comptr)
  array:set geo-com action-comptr geometric-update array:item geo-com action-comptr reward-comptr geometric-avg-rate-comptr

end

to compute-reward-random
  set reward-random item action-random realisation
  set payoff-random payoff-random + reward-random
  set-current-plot-pen "Random player"
  plot payoff-random / rounds
end

to-report y ; computer player 
  ; the "1 + " is the initial propensity of play
  report epsilon-greedy map [ array:item geo-com ? ] all-actions
end

to-report optimistic-average [ my-total frequency ]
  if frequency = 0 [ report 99 ]
  report my-total / frequency
end

to-report z ; random player
  report random (max-pxcor + 1)
end

to-report give-immediate-reward [ x ]
  report round random-uniform (array:item mean-of x) (array:item devn-of x)
end  

to-report Total [ x ]
  report array:item tot-rwd (x - 1)
end

to-report Avg [ x ]
  report (array:item tot-rwd (x - 1)) / (array:item freqncy (x - 1))
end

to-report Geom [ x ]
  report array:item geo-avg (x - 1)
end

to-report Last2 [ x ]
  report array:item lastval (x - 1)
end

to color-patches
  ask patches with [ pcolor != black ] [ set pcolor black ]
  ask patch action-player 2 [ set pcolor red   ]
  ask patch action-comptr 1 [ set pcolor brown ]
  ask patch action-random 0 [ set pcolor gray  ]
end

to-report probabilistic-max [ l ]
  let cut random-float (sum l)
  let i -1 let s 0
  while [ s < cut ] [
    set i i + 1
    set s s + item i l
  ]
  report i
end

to-report epsilon-greedy [ l ]
  if random-float 1.0 < epsilon-for-greedy [ report random length l ]
  report arg-max l
end

to-report arg-max [ l ]
  let indices n-values length l [ ? ]
  let maximum max l
  report one-of filter [ item ? l = maximum ] indices
end

to-report random-uniform [ mu sigma ]
  let diameter sqrt(3.0) * sigma
  report mu - diameter + random-float (2 * diameter)
end 

to-report geometric-update [ old new lambda ]
  report (1 - lambda) * old + lambda * new
end


to print-mean-payoffs
  clear-output
  foreach all-actions [
    output-print (word "c " (? + 1) ": mu = " precision array:item mean-of ? 1)
  ]
end

  
@#$#@#$#@
GRAPHICS-WINDOW
210
10
500
209
-1
-1
56.0
1
10
1
1
1
0
1
1
1
0
4
0
2
0
0
1
ticks

BUTTON
443
211
498
244
NIL
c 5
NIL
1
T
OBSERVER
NIL
5
NIL
NIL

BUTTON
215
211
270
244
NIL
c 1
NIL
1
T
OBSERVER
NIL
1
NIL
NIL

BUTTON
272
211
327
244
NIL
c 2
NIL
1
T
OBSERVER
NIL
2
NIL
NIL

BUTTON
329
211
384
244
NIL
c 3
NIL
1
T
OBSERVER
NIL
3
NIL
NIL

BUTTON
386
211
441
244
NIL
c 4
NIL
1
T
OBSERVER
NIL
4
NIL
NIL

BUTTON
135
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
S
NIL
NIL

MONITOR
215
328
270
373
NIL
Avg 1
1
1
11

MONITOR
272
328
327
373
NIL
Avg 2
1
1
11

MONITOR
329
328
384
373
NIL
Avg 3
1
1
11

MONITOR
386
328
441
373
NIL
Avg 4
1
1
11

MONITOR
443
328
498
373
NIL
Avg 5
1
1
11

MONITOR
215
281
270
326
Last 1
Last2 1
17
1
11

MONITOR
272
281
327
326
Last 2
Last2 2
17
1
11

MONITOR
386
281
441
326
Last 4
Last2 4
17
1
11

MONITOR
329
281
384
326
Last 3
Last2 3
17
1
11

MONITOR
443
281
498
326
Last 5
Last2 5
17
1
11

MONITOR
215
375
270
420
NIL
Geom 1
1
1
11

MONITOR
272
375
327
420
NIL
Geom 2
1
1
11

MONITOR
329
375
384
420
NIL
Geom 3
1
1
11

MONITOR
386
375
441
420
NIL
Geom 4
1
1
11

MONITOR
443
375
498
420
NIL
Geom 5
1
1
11

SLIDER
36
45
208
78
geometric-avg-rate-comptr
geometric-avg-rate-comptr
0
0.5
0.3
0.05
1
NIL
HORIZONTAL

PLOT
502
10
962
209
Average reward
NIL
NIL
0.0
10.0
0.0
1.0
true
true
PENS
"Human player" 1.0 0 -2674135 true
"Computer player" 1.0 0 -6459832 true
"Random player" 1.0 0 -7500403 true

SLIDER
36
80
208
113
epsilon-for-greedy
epsilon-for-greedy
0
0.5
0.1
0.01
1
NIL
HORIZONTAL

SWITCH
5
150
131
183
allow-shift-gears
allow-shift-gears
1
1
-1000

SLIDER
36
115
208
148
probability-shift-gears
probability-shift-gears
0
0.001
1.0E-4
0.0001
1
NIL
HORIZONTAL

BUTTON
140
211
213
244
NIL
explore
NIL
1
T
OBSERVER
NIL
E
NIL
NIL

BUTTON
140
246
213
279
NIL
explore
T
1
T
OBSERVER
NIL
F
NIL
NIL

SLIDER
41
375
213
408
geometric-avg-rate-player
geometric-avg-rate-player
0
0.5
0.3
0.05
1
NIL
HORIZONTAL

BUTTON
215
246
270
279
NIL
c 1
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
272
246
327
279
NIL
c 2
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
329
246
384
279
NIL
c 3
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
386
246
441
279
NIL
c 4
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
443
246
498
279
NIL
c 5
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
133
150
208
195
NIL
nr-shift-gears
0
1
11

TEXTBOX
509
218
951
429
Multi-armed bandit problem.  Which of the 5 handles must be pulled to maximise your average reward? \"c 1\" means: pull 1st handle, \"c 2\"means: pull 2nd handle, and so on.\n\nExplore pulls all 5 handles in succession one time.  Rows display last payoff, the average payoff for that particular handle, and the geometric average payoff for that particular handle (regulated by \"geometric-avg-rate-player\").\n\nThe computer (brown square) selects its actions epsilon-greedy, based on the maximum geometric average payoff of the computer's actions (regulated by \"geometric-avg-rate-comptr\").  Try to beat the computer without cheating!\n\nIf you allow the multi-armed bandit problem to shift gears, then at every pull of a handle the payoff of one randomly selected handle is redefined with a small probability that is equal to \"probability-shift-gears\".
11
0.0
1

TEXTBOX
157
287
207
338
Monitor of player's rewards:
11
0.0
1

OUTPUT
5
246
138
336
11

SWITCH
5
211
138
244
cheat
cheat
0
1
-1000

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
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
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
