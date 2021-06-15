globals [ min-t max-t min-s max-s periodicity? lyapunov? end-value? radius-1? mouse-s mouse-t mouse-min-x mouse-x mouse-max-x mouse-period ]
patches-own [ S T periodicity lyapunov x min-x max-x ]

to-report result
  set x random-float 1.0 ;  start-x ;  
  set min-x  1E250
  set max-x -1E250
  let i 0
  let l [] ; for periodicity
  let c 1E-100  ; for lyapunov
  while [ i < iterations ] [
    set i i + 1
    let old-x x
    ;set x x + x * (1 - x) * (S - P + (P + R - T - S) * x) ; replicator equation (eq. 4 of Vilone) @@@@@ P en R @@@@@@@@@@@@@@@
    ;set x x * (kappa + S + (R - S) * x) / (kappa + P + x * (S + T - 2 * P + x * (P + R - S - T))) ; replicator as it should be
    set x x - ((-1 + x) * x * (S + P * (-1 + x) + R * x - (S + T) * x)) / (1 + delta * (-1 + kappa + P * (-1 + x) ^ 2 + x * (S + T + R * x - (S + T) * x))) ; mix van de twee
    ;set x S / 2 * (1 - (abs x) ^ T) - 1 ; http://demonstrations.wolfram.com/FiniteLyapunovExponentForGeneralizedLogisticMapsWithZUnimoda/
    ;set x S / 4 * (1 - (abs (2 * x - 1)) ^ T); generalised logistic
    ;set x (kappa / 100) + x * (S + T * x) ; quadratic iterator
    ;set x (500 * S * x) / (1 + T * x) ^ 4 ; Hassell model / Beverton-Holt model
    ;set x ifelse-value (x > 1 - 1 / T) [ T * (1 - x) ] [ 1 - S * (1 - 1 / T) + S * x ] ; asymptotic tent map; success!
    ;set x S * x ^ 2 + T ; quadratic function
    ;set x 1 / (1.5 - 1.5 * T * x + S * x ^ 2)
    ; set x precision x my-precis
    if x < min-x [ set min-x x ]
    if x > max-x [ set max-x x ]
    if abs x > 1E+50 [ report nobody ]
    if i > transient [
      if not lyapunov? [ if abs(x - old-x) < 1E-10 [ report ifelse-value periodicity? [ 1 ] [ x ] ] ]
      if-else lyapunov? [
        let y kappa - P + S + x * (2 * (2 * P + R - 2 * S - T) + 3 * x * (S + T - P - R)) ; replicator equation (eq. 4 of Vilone) @@@@@ P en R @@@@@@@@@@@@@@@
        ;let y ((kappa + P) * (kappa + S) + 2 * (kappa + P) * (R - S) * x + (P * (S - 2 * R) + R * T + kappa * (S + T - P - R)) * x ^ 2) / (kappa + P * (x - 1) ^ 2 + x * (S + T + R * x - (S + T) * x)) ^ 2 ; as it should
        set c c + abs y
      ] [
        if periodicity? [ set l fput x l ]
      ]
    ]
  ]
  report ifelse-value periodicity? [
    period l repetitions epsilon
  ] [
     ifelse-value lyapunov? [ ln (c / (iterations - transient + 1)) ] [ pi ]
  ]
end

to go
  set periodicity? modus = "periodicity"
  set lyapunov?    modus = "lyapunov"
  set end-value?   modus = "end-value"
  set radius-1?    modus = "radius-1"
  
  set min-s center-s - radius set max-s center-s + radius
  set min-t center-t - radius set max-t center-t + radius
  
  if overlay? [ clear-drawing draw-overlay ]
  
  ask patches [
    set S ((max-s - min-s) * pxcor + (min-s * max-pxcor - max-s * min-pxcor)) / (max-pxcor - min-pxcor)
    set T ((max-t - min-t) * pycor + (min-t * max-pycor - max-t * min-pycor)) / (max-pycor - min-pycor)
    run (word "compute-" modus)
  ]
  histogram [ periodicity ] of patches
end

to compute-periodicity
  set periodicity result
  color-periodicity
end
to color-periodicity
; if periodicity = 1 [ set pcolor black stop ]
  set pcolor ifelse-value (periodicity = nobody) [ 103 ] [
    ifelse-value (periodicity = 16) [ white ] [
      ifelse-value (periodicity < 14) [ 10 * periodicity + 5  ] [ red ]
    ]
  ]
end

to compute-lyapunov
  set lyapunov result
  color-lyapunov
end
to color-lyapunov
  set pcolor ifelse-value (lyapunov = nobody) [ 103 ] [
   ; ifelse-value (lyapunov < 0) [ scale-color red lyapunov 0.5 -2 ] [ scale-color lime lyapunov 0 1 ]
    ifelse-value (lyapunov < 0) [ scale-color red lyapunov 0.5 -10 ] [ scale-color lime lyapunov 0 10 ]
  ]
end

to compute-end-value
  set x result
  color-end-value
end
to color-end-value
  set pcolor ifelse-value (x = nobody) [ 103 ] [
    ;ifelse-value (x = pi) [ scale-color lime (max-x - min-x)  -0.1 1 ] [ scale-color red x -0.2 1.2 ]
    ifelse-value (x = pi) [ scale-color lime (max-x - min-x)  -0.2 10 ] [ scale-color red x -10 10 ]
  ]
end

to compute-radius-1
  set x result
  color-radius-1
end
to color-radius-1
  set pcolor ifelse-value (x = nobody) [ 103 ] [
    ifelse-value (0 <= min-x)
      [ ifelse-value (max-x <= 1) [ scale-color white ((min-x + max-x) / 2) 0 1 ]  [ scale-color cyan max-x 0.75 2.25 ] ]
      [ ifelse-value (max-x <= 1) [ scale-color magenta min-x 0.2 -0.80 ] [ yellow ] ]
  ]
end

to-report period [ lst k eps ] ; satisfied with k repetitions, k must be 2 or larger
  let l length lst
  let q 0
  loop [
    set q q + 1
    if k * q > l [ report 0 ] ; if k * q > l, k reps of q is impossible 
    let i 0
    let j q
    while [ j < l and abs(item i lst - item j lst) < eps ] [
      if i > (k - 1) * q - 2 [ report q ] ; j already takes care of index last period
      set i i + 1
      set j j + 1
    ]
  ]
end

to draw-overlay
  crt 1 [
    set color white
    foreach [ 0 1 ] [
      let c to-xcor ?
      if min-pxcor <= c and c <= max-pxcor [
        setxy c min-pycor set heading  0 pd fd world-height pu
      ]
      set c to-ycor ?
      if min-pycor <= c and c <= max-pycor [
        setxy min-pxcor c set heading 90 pd fd world-width  pu
      ]
    ]
    let diagonal patches with-min [ abs(S - T) ]
    move-to min-one-of diagonal [ distancexy 0 0 ]
    set heading 45 pd
    hatch 1 [ rt 180 ]
  ]
  ask turtles [ while [ can-move? 1 ] [ fd 1 ] die ]
  display
end

to-report game-colour ; 1: pd; 2: chicken; 3: leader; 4: bos; 7: harmony; 8: stag hunt; 12: dead lock
  report ifelse-value (S < 0) [
    ifelse-value (T < 0) [ifelse-value (S < T) [9] [10] ] [ ifelse-value (T < 1) [11] [12] ]
  ] [
    ifelse-value (S < 1) [
      ifelse-value (T < 0) [8] [ ifelse-value (T < 1) [ ifelse-value (S < T) [7] [6] ] [5] ]
    ] [
      ifelse-value (T < 0) [1] [ ifelse-value (T < 1) [2] [ ifelse-value (S < T) [3] [4] ] ]
    ]
  ]
end

to show-period
  no-display
  ask patches [
    set pcolor ifelse-value (periodicity = period-to-show) [ white ] [ black ]
  ]
  display
; print sort remove-duplicates [ periodicity ] of patches
; [0 1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 17 18 20 21 24 28 30 32 36 40 42 44 48 50 56 60 72 80 91 96 100 108 128 144 154 288]
end
  
to-report to-xcor [ s-val ]
  report ((max-pxcor - min-pxcor) * s-val + (min-pxcor * max-s - max-pxcor * min-s)) / (max-s - min-s)
end

to-report to-ycor [ t-val ]
  report ((max-pycor - min-pycor) * t-val + (min-pycor * max-t - max-pycor * min-t)) / (max-t - min-t)
end

to display-s-t
  ask patch mouse-xcor mouse-ycor [
    set mouse-period periodicity
    set mouse-s S set mouse-t T
    set mouse-x x set mouse-min-x min-x set mouse-max-x max-x
  ]
end

to defaults
  set center-s 6.5
  set center-t 6.5
  set radius 15   
end

to zoom
  set center-s 0.2
  set center-t 1.2
  set radius 1.3
end

to d [ name ]
  export-view (word "C:/Onderzoek/TheReplicatorFractal/img/" name ".png")
end

; The logistic equation
; Didier Gonze
; September 30, 2015

; ------------------------------------------------------------------------------------

to gek
  foreach n-values 9 [ ? / 2 - 2 ] [
    set R ? 
    foreach n-values 9 [ ? / 2 - 2  ] [
      set P ? 
      go
      d (word "overview/overview_[" precision P 1 "]_[" precision R 1 "]")
    ]
  ]
end 

to hoi
  let z sort remove-duplicates [ periodicity ] of patches
  print z
  print filter [ not member? ? z ] n-values 110 [ ? ]
end 

to-report is-prime? [ n ]
  let i 2
  let b floor sqrt n
  while [ i <= b ] [
    if n mod i = 0 [ report false ]
    set i i + 1
  ]
  report true
end 
@#$#@#$#@
GRAPHICS-WINDOW
210
10
751
572
88
88
3.0
1
10
1
1
1
0
0
0
1
-88
88
-88
88
0
0
1
ticks

BUTTON
36
10
134
43
one sweep
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
36
255
208
288
iterations
iterations
0
1000
410
10
1
NIL
HORIZONTAL

SLIDER
36
220
208
253
transient
transient
0
500
100
5
1
NIL
HORIZONTAL

SLIDER
36
360
208
393
radius
radius
0
15
15
0.5
1
NIL
HORIZONTAL

SLIDER
36
325
208
358
center-t
center-t
-10
10
6.5
0.5
1
NIL
HORIZONTAL

SLIDER
36
290
208
323
center-s
center-s
-10
10
6.5
0.5
1
NIL
HORIZONTAL

BUTTON
36
45
103
78
NIL
defaults
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

MONITOR
757
484
814
529
NIL
min-t
1
1
11

MONITOR
757
10
814
55
NIL
max-t
1
1
11

MONITOR
151
531
208
576
NIL
min-s
1
1
11

MONITOR
757
531
814
576
NIL
max-s
1
1
11

SWITCH
105
45
208
78
overlay?
overlay?
0
1
-1000

TEXTBOX
763
64
936
488
If modus is periodicity:\nGrey: 0 (chaotic);\nred: 1 (fixed point);\norange: 2;\nbrown: 3;\nyellow: 4;\ngreen: 5; lime: 6; turquoise: 7; cyan: 8; sky: 9; blue: 10; violet: 11; magenta: 12; pink: 13;\nwhite: 16;\nblack: != 16, > 13.\n\nIf modus is lyapunov:\nred: negative, meaning convergence. Light red is fast convergence.\ngreen: positive, meaning divergence.  Light green is fast divergence.\nblue: out of bounds.\n\nIf modus is end-value:\nred: fixed point.  Dark: close to zero; light: close to one.\ngreen: divergent but bounded within Netlogo's arithmetic.  Dark: small amplitude; light: large amplitude.\nblue: out of bounds.
11
0.0
1

CHOOSER
816
10
954
55
modus
modus
"periodicity" "lyapunov" "end-value" "radius-1"
0

TEXTBOX
45
406
201
522
If overlay is on:\nupper left = prisoner's;\nupper middle = chicken;\nupper right up: leader;\nupper right down: battle of the sexes; middle left: stag hunt;\nmiddle middle up: harmony;\nlower right: dead lock.
11
0.0
1

MONITOR
984
221
1156
266
s
mouse-s
17
1
11

MONITOR
984
268
1156
313
t
mouse-t
17
1
11

BUTTON
996
315
1097
348
display (s, t)
display-s-t
T
1
T
OBSERVER
NIL
D
NIL
NIL

SLIDER
36
185
208
218
start-x
start-x
0
1
0.69
0.01
1
NIL
HORIZONTAL

SLIDER
984
10
1156
43
repetitions
repetitions
0
100
2
1
1
NIL
HORIZONTAL

SLIDER
984
45
1156
78
epsilon
epsilon
0
0.1
0.01
0.001
1
NIL
HORIZONTAL

MONITOR
984
174
1156
219
NIL
mouse-min-x
17
1
11

MONITOR
984
127
1156
172
NIL
mouse-max-x
17
1
11

SLIDER
36
150
208
183
kappa
kappa
-3.0
3
1
0.05
1
NIL
HORIZONTAL

BUTTON
136
10
208
43
sweep
go
T
1
T
OBSERVER
NIL
G
NIL
NIL

MONITOR
1099
315
1156
360
period
mouse-period
0
1
11

BUTTON
956
362
1020
395
rough
set-patch-size 3\nresize-world -88 88 -88 88
NIL
1
T
OBSERVER
NIL
R
NIL
NIL

BUTTON
1022
362
1091
395
coarse
set-patch-size 2\nresize-world -133 133 -133 133
NIL
1
T
OBSERVER
NIL
C
NIL
NIL

BUTTON
1093
362
1156
395
fine
set-patch-size 1\nresize-world -267 267 -267 267
NIL
1
T
OBSERVER
NIL
F
NIL
NIL

BUTTON
1158
315
1258
348
NIL
show-period
T
1
T
OBSERVER
NIL
P
NIL
NIL

SLIDER
1158
350
1330
383
period-to-show
period-to-show
0
100
10
1
1
NIL
HORIZONTAL

PLOT
956
397
1356
547
Period frequency
NIL
NIL
0.0
100.0
0.0
500.0
false
false
PENS
"default" 1.0 1 -16777216 true

SLIDER
36
115
208
148
P
P
-15
15
0
0.25
1
NIL
HORIZONTAL

SLIDER
36
80
208
113
R
R
-15
15
0
0.25
1
NIL
HORIZONTAL

MONITOR
984
80
1156
125
NIL
mouse-x
17
1
11

SLIDER
1158
45
1330
78
delta
delta
0
1
0.5
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
REFERENCES
----------
Chaos and Unpredictability in Evolutionary Dynamics in Discrete Time
Daniele Vilone, Alberto Robledo and Angel Sanchez

A discrete-time version of the replicator equation for two-strategy games is studied. The stationary properties differ from those of continuous time for sufficiently large values of the parameters, where periodic and chaotic behavior replace the usual fixed-point population solutions. We observe the familiar period-doubling and chaotic-band-splitting attractor cascades of unimodal maps but in some cases more elaborate variations appear due to bimodality. Also unphysical stationary solutions can have unusual physical implications, such as the uncertainty of the final population caused by sensitivity to initial conditions and fractality of attractor preimage manifolds.

If overlay is on:
upper left = prisoner's;
upper middle = chicken;
upper right up: leader;
upper right down: battle of the sexes; middle left: stag hunt;
middle middle up: harmony;
lower right: dead lock.

For a more elaborate discussion of these and other areas, cf. Posch, M., Pichler, A. & Sigmund, K. [1999] “The efficiency of adapting aspiration levels,” Proc. R. Soc.Lond. B266, 1427–1435.	

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
