breed [ players player ]
breed [ outcomes outcome ]
breed [ drawers drawer ]

players-own [ current-action-A current-action-B ]
outcomes-own [ visits ]

globals [ payoff-A payoff-B pa pb xcor-old ycor-old change action-switches actual-switches
          cross-color cross-color-highlighted crosshair-color profile-colors ]

to setup
  ca
  if-else coloured? [
    set cross-color yellow
    set cross-color-highlighted red
    set crosshair-color blue
    set profile-colors [orange lime red magenta cyan]
  ] [
  set cross-color white
  set cross-color-highlighted red
  set crosshair-color white
  set profile-colors [orange lime red yellow magenta cyan]
  ]
  create-drawers 1 [ set hidden? true set color crosshair-color pen-up ]
  ifelse uniform-initial-aspiration [ create-couples-uniformly ] [ create-couples-randomly ]
  ask players [
    set current-action-A random nr-of-actions
    set current-action-B random nr-of-actions
    set shape "circle 2" set size 0.5
    if pens-down [ pen-down ]
    set pen-size 0.5
    set color item (who mod length profile-colors) profile-colors
  ]
  randomise
end

to create-couples-uniformly
  ask patches with [ pxcor mod resolution = 0 and pycor mod resolution = 0 ] [
    sprout-players patch-multiplicity [
      ;set shape "circle" set size 0.2
    ] 
  ]
end

to create-couples-randomly
  create-players number-of-profiles [
    ;set shape "circle 2" set size 0.5
    setxy initial-aspiration-A initial-aspiration-B
  ]
end

to randomise
  ifelse random-payoffs
    [ set-payoffs-randomly ]
    [ set-payoffs-as-indicated ]
  foreach [ 0 1 2 ] [
    let a ?
    foreach [ 0 1 2 ] [
      let b ?
      create-outcomes 1 [
        set visits 0
        set shape "x" set size 0.5 set color cross-color
        setxy (item a (item b payoff-A)) (item a (item b payoff-B))
        set size 0.5
        if draw-crosshairs [
          ask drawers [ drawcross [ xcor ] of myself [ ycor ] of myself ]
        ]
      ]
    ]
  ]
end

to set-payoffs-randomly
  set payoff-A (list (list rd rd rd) (list rd rd rd) (list rd rd rd))
  set payoff-B (list (list rd rd rd) (list rd rd rd) (list rd rd rd))
  set-appropriate
end

to set-PD
  set payoff-A perturb-matrix (list (list sigma 0 0) (list 5 delta 0) (list 0 0 0))
  set payoff-B perturb-matrix (list (list sigma 5 0) (list 0 delta 0) (list 0 0 0))
  update-matrix-in-GUI
  set initial-aspiration-A 2 * sigma
  set initial-aspiration-B 2 * sigma
  set nr-of-actions 2
  set random-payoffs false
  setup
end

to set-appropriate
  update-matrix-in-GUI
  set initial-aspiration-A 9
  set initial-aspiration-B 9
  set nr-of-actions 3
end

to RPSc
  set payoff-A perturb-matrix [[5 8 2] [2 5 8] [8 2 5]]
  set payoff-B perturb-matrix [[5 2 8] [8 5 2] [2 8 5]]
  set-appropriate
  setup
end

to Shapley
  set payoff-A perturb-matrix [[2 7 2] [2 2 7] [7 2 2]]
  set payoff-B perturb-matrix [[2 2 7] [7 2 2] [2 7 2]]
  set-appropriate
  setup
end

to Curve
  set payoff-A perturb-matrix [[9 1.04 3.8] [2.47 1.61 5.85] [0.68 0.44 0.29]] ; hyperbolic-payoffs 9 .65
  set payoff-B perturb-matrix [[0.29 2.47 0.68] [1.04 1.61 0.44] [3.8 5.85 9]] ; reverse map [ reverse ? ] hyperbolic-payoffs 9 .65
  set-appropriate
  setup
end

to-report hyperbolic-payoffs [ value factor ]
  let l []
  repeat 3 [
    let inner []
    repeat 3 [
      set inner lput (precision value 2) inner
      set value factor * value
    ]
    set l lput inner l
  ]
  report l
end

to update-matrix-in-GUI
  set Aa  item 0 (item 0 payoff-A) set Ab  item 1 (item 0 payoff-A) set Ad  item 2 (item 0 payoff-A)
  set Ba  item 0 (item 1 payoff-A) set Bb  item 1 (item 1 payoff-A) set Bd  item 2 (item 1 payoff-A)
  set Da  item 0 (item 2 payoff-A) set Db  item 1 (item 2 payoff-A) set Dd  item 2 (item 2 payoff-A)
  set aA_ item 0 (item 0 payoff-B) set bA_ item 1 (item 0 payoff-B) set dA_ item 2 (item 0 payoff-B)
  set aB_ item 0 (item 1 payoff-B) set bB_ item 1 (item 1 payoff-B) set dB_ item 2 (item 1 payoff-B)
  set aD_ item 0 (item 2 payoff-B) set bD_ item 1 (item 2 payoff-B) set dD_ item 2 (item 2 payoff-B)
end

to set-payoffs-as-indicated
  set payoff-A (list (list Aa  Ba  Da ) (list Ab  Bb  Db ) (list Ad  Bd  Dd ))
  set payoff-B (list (list aA_ aB_ aD_) (list bA_ bB_ bD_) (list dA_ dB_ dD_))
end

to go
  set action-switches 0
  set actual-switches 0
  set change   0
  ask players [ play ]
  tick
  set-current-plot-pen "switches" plot action-switches
  set-current-plot-pen "actual"   plot actual-switches
  if  change = 0 [ if-else restart-after-conv [ setup ] [ stop ] ]
end

to play
  ; print "------------------------------------"
  ; print (word "Asp. [" xcor "," ycor "]")
  ; print (word "Act. (" current-action-A "," current-action-B ")")
  set pa item current-action-A (item current-action-B payoff-A)
  set pb item current-action-A (item current-action-B payoff-B)
  if display-profile-visits [
    let chosen-profile outcomes with [ distancexy pa pb < .01 ]
    ask chosen-profile [ set visits visits + 1 set label visits ]
    if number-of-profiles = 1 [
      ask outcomes with [ color != cross-color ] [ set color cross-color ]
      ask chosen-profile [ set color cross-color-highlighted ]
    ]
  ]
  ; print (word "Pay. <" pa "," pb ">")
  if pa < xcor [ set current-action-A random-but current-action-A nr-of-actions ]
  if pb < ycor [ set current-action-B random-but current-action-B nr-of-actions ]
  set xcor-old xcor
  set ycor-old ycor
  set xcor persistence-rate * xcor + (1.0 - persistence-rate) * pa
  set ycor persistence-rate * ycor + (1.0 - persistence-rate) * pb
  if change = 0 and (xcor - xcor-old) ^ 2 + (ycor - ycor-old) ^ 2 > 1E-10 [ set change 1 ]
end

to-report rd
  report precision (random-float 10) 2
end

to drawcross [ x y ]
  setxy (min-pxcor - 0.4) y pen-down
  setxy x y
  setxy x (min-pycor - 0.4) pen-up
end

to-report size-of [ x ] 
  report 0.3 + ln ( 0.1 * x + 1 )
end

to-report random-but [ k n ]
  set action-switches action-switches + 1
  let new-k ifelse-value force-switch [ one-of remove-item k n-values n [ ? ] ] [ random n ]
  if new-k != k [ set actual-switches actual-switches + 1 ]
  report new-k
end

to-report transpose [ matrix ]
  let ids n-values (length first matrix) [ ? ]
  report map [ n-th-column ? matrix ] ids
end
  
to-report n-th-column [ n matrix ]
  report map [ item n ? ] matrix
end

to-report perturb-matrix [ matrix ]
  report map [ map [ precision (random-uniform ? perturb) 2 ] ? ] matrix
end

to-report random-uniform [ x dev ]
  report x + dev * (-1 + random-float 2)
end
@#$#@#$#@
GRAPHICS-WINDOW
180
10
608
459
-1
-1
38.0
1
18
1
1
1
0
0
0
1
0
10
0
10
0
0
1
ticks

BUTTON
115
10
178
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

BUTTON
115
45
178
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

BUTTON
50
45
113
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

SLIDER
6
260
178
293
initial-aspiration-A
initial-aspiration-A
0
10
9
0.1
1
NIL
HORIZONTAL

SLIDER
6
295
178
328
initial-aspiration-B
initial-aspiration-B
0
10
9
0.1
1
NIL
HORIZONTAL

SLIDER
6
350
178
383
persistence-rate
persistence-rate
0
1
0.9
0.05
1
NIL
HORIZONTAL

SLIDER
6
225
178
258
number-of-profiles
number-of-profiles
1
1000
500
1
1
NIL
HORIZONTAL

SWITCH
610
338
762
371
pens-down
pens-down
0
1
-1000

SWITCH
6
80
178
113
uniform-initial-aspiration
uniform-initial-aspiration
1
1
-1000

INPUTBOX
610
45
660
105
Aa
0.58
1
0
Number

INPUTBOX
660
45
710
105
aA_
5.45
1
0
Number

INPUTBOX
710
45
760
105
Ab
0.2
1
0
Number

INPUTBOX
760
45
810
105
bA_
5.89
1
0
Number

INPUTBOX
810
45
860
105
Ad
8.3
1
0
Number

INPUTBOX
860
45
910
105
dA_
2.94
1
0
Number

INPUTBOX
610
105
660
165
Ba
2.77
1
0
Number

INPUTBOX
660
105
710
165
aB_
1.26
1
0
Number

INPUTBOX
710
105
760
165
Bb
9.11
1
0
Number

INPUTBOX
760
105
810
165
bB_
2.56
1
0
Number

INPUTBOX
810
105
860
165
Bd
5.89
1
0
Number

INPUTBOX
860
105
910
165
dB_
0.12
1
0
Number

INPUTBOX
610
165
660
225
Da
9.22
1
0
Number

INPUTBOX
660
165
710
225
aD_
2.52
1
0
Number

INPUTBOX
710
165
760
225
Db
5.6
1
0
Number

INPUTBOX
760
165
810
225
bD_
8.43
1
0
Number

INPUTBOX
810
165
860
225
Dd
4.91
1
0
Number

INPUTBOX
860
165
910
225
dD_
3.75
1
0
Number

SWITCH
738
10
910
43
random-payoffs
random-payoffs
1
1
-1000

TEXTBOX
615
235
880
261
Actions row: A, B, D.  Actions column: a, b, d.
11
0.0
1

SLIDER
6
135
178
168
resolution
resolution
0
10
2
1
1
NIL
HORIZONTAL

SLIDER
6
170
178
203
patch-multiplicity
patch-multiplicity
0
10
1
1
1
NIL
HORIZONTAL

TEXTBOX
11
120
161
138
for uniform initial aspiration
11
0.0
1

TEXTBOX
11
210
161
228
for predefined initial aspiration
11
0.0
1

TEXTBOX
11
335
161
353
other
11
0.0
1

SWITCH
8
385
178
418
restart-after-conv
restart-after-conv
0
1
-1000

SWITCH
8
420
121
453
force-switch
force-switch
1
1
-1000

SWITCH
610
373
762
406
draw-crosshairs
draw-crosshairs
0
1
-1000

BUTTON
764
338
827
371
PD
set-pd
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
764
373
856
406
sigma
sigma
0
10
2.5
0.5
1
NIL
HORIZONTAL

SLIDER
764
408
856
441
delta
delta
0
10
0.5
0.5
1
NIL
HORIZONTAL

SLIDER
610
261
707
294
nr-of-actions
nr-of-actions
2
3
3
1
1
NIL
HORIZONTAL

TEXTBOX
145
434
176
452
(0,0)
11
0.0
1

TEXTBOX
618
20
667
38
(10, 10)
11
0.0
1

BUTTON
829
303
894
336
NIL
Curve
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
829
338
894
371
NIL
Shapley
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SWITCH
610
303
762
336
display-profile-visits
display-profile-visits
1
1
-1000

PLOT
912
10
1241
200
Action switches
NIL
NIL
0.0
10.0
0.0
1.0
true
true
PENS
"switches" 1.0 0 -16777216 true
"actual" 1.0 0 -6459832 true

BUTTON
764
303
827
336
NIL
RPSc
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
912
202
1010
247
NIL
action-switches
17
1
11

MONITOR
1012
202
1110
247
NIL
actual-switches
17
1
11

SLIDER
709
261
801
294
perturb
perturb
0
10
0
0.1
1
NIL
HORIZONTAL

SWITCH
610
408
762
441
coloured?
coloured?
0
1
-1000

@#$#@#$#@
WHAT IS IT?
-----------
This models shows the dynamics of different aspiration profiles during satisficing play.

HOW IT WORKS
------------
A 2-player 3x3-action matrix game G is initialised with positive payoffs.  Actions for the row player, player A, are: A, B, D.  Actions for the column player, player B, are: a, b, d.  There are nine action profiles: Aa, Ab, ..., Dd.  Each of the 9 action profiles (combinations of actions) corresponds with a payoff profile.  These payoff profiles are displayed as yellow crosses in the canvas.  By the way, in the matrix, B's payoff for action profile Aa is denoted as aA_.  Similarly for other action profiles. 

There are multiple couples, symbolised by dots (uniform-initial-aspiration, to be explained later) or circles (homogeneous aspiration, to be explained later).   A couple consists of two players playing G repeatedly.  One such play is called a round.  In one round each player selects its action through satisficing play.

SATISFICING PLAY
----------------
Each player maintains a state.  A state is a pair consisting of the current action and the current aspiration.  (So each couple maintains an action profile and an aspiration profile.)  The aspiration is a real number that represents a player's desired payoff.  If in one round a player yields a payoff lower than its current aspiration, that player resets its current action to another (random) action.  Irrespective of whether the curent action changes, the aspiration profile is updated each round geometrically with the payoff obtained in that round:

aspiration = (1 - learning-rate) * old-aspiration + learning-rate * payoff-in-current-round

If the simulation runs ("step" or "go"), all couples execute their actions and update their aspiration profiles each round.  If "pens-down" is true then for each couple a trace of aspiration profiles becomes visible during the simulation.

If all aspiration profiles have converged, the simulation restarts if "restart-after-convergence" is on.  If "random-payoffs" is on, the simulation starts with a newly generated payoff matrix.  If "restart-after-convergence" is on., the simulation stops.

PARAMETERS
----------
* random-payoffs: if on, then at setup the payoff matrix is filled with random positive

* integers; else the payoff matrix may be filled manually

* uniform-initial-aspiration: if on, the canvas of aspiration profiles is filled uniformly; else all aspiration profiles are set to (initial-aspiration-A, initial-aspiration-B).  This is called homogeneous aspiration.

* resolution: if uniform-initial-aspiration is on, this regulates the density of initial aspiration profiles.  1 is most dense

* patch-multiplicity: if uniform-initial-aspiration is on, the number of aspiration profiles per patch.  this makes sense, because identical aspiration profiles are likely to diverge due to randomness

* number-of-couples:
* initial-aspiration-A:
* initial-aspiration-B:
* learning-rate-A:
* learning-rate-B:
* restart-after-convergence:
* pens-down:

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
