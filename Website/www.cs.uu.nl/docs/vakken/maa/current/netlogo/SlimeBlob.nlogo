breed [ cities city ]
breed [ ants ant ]

globals [ nr-of-ants city-patches convex-hull ] 

patches-own [ pheromone in-convex-hull? in-city? ]

to setup
  ca
  create-and-separate-cities
  create-convex-hull
  create-ants start-nr-of-ants [
    set hidden? true set color orange
    set shape "circle" set size 1
    move-to one-of convex-hull
  ]
end

to go
  ask ants [ sense move ]
  diffuse pheromone diffusion-rate
  ask patches [ ; originally all patches, could be confined to convex-hull
    set pheromone evaporation-rate * pheromone
    set pcolor scale-color lime pheromone 0 pheromone-contrast
  ]
  ask cities [
    let ants-in-this-city count ants in-radius city-radius
    set color ifelse-value (ants-in-this-city <= threshold-to-interior) [ yellow ] [ red ]
    let presence-of-ants ifelse-value (ants-in-this-city = 0) [ 10 ] [ 3 ] ; 10 0  0.01275
    ask patches in-radius city-radius [ set pheromone presence-of-ants ]
  ]
  if all? cities [ color = yellow ] [ stop ]
  tick
  set nr-of-ants count ants
  if ticks > 100 [ set-plot-x-range (ticks - 100) ticks set-plot-y-range nr-of-ants - 100 nr-of-ants + 200 ]
  plot nr-of-ants
end

to sense
  if random-float 1.0 < probability-of-death [ die ]
  ; execute sensory stage
  let FF [ pheromone ] of patch-ahead sensor-offset
  let FL [ pheromone ] of patch-left-and-ahead sensor-angle sensor-offset
  let FR [ pheromone ] of patch-right-and-ahead sensor-angle sensor-offset
  if FF > FL and FF > FR [ stop ]
  if FF < FL and FF < FR [ right (random-polarity * rotation-angle) stop ]
  if FL < FR [ right rotation-angle stop ]
  if FR < FL [ left rotation-angle stop ]
  ; else continue facing same direction
end  

to move
  if (who + ticks) mod 10 = 2 [ check-may-live ]
  ; now execute motor stage
  if-else can-move? ant-step-size and (co-location-allowed or not any? ants-on patch-ahead ant-step-size) [
    fd ant-step-size ; forward, then deposit pheromone
    if not in-convex-hull? [ die ]
    set pheromone pheromone + pheromone-deposit-rate
    if (who + ticks) mod  5 = 0 [ try-to-split ]
  ] [
    right random-float 360 ; choose a random new orientation
  ]
end

to try-to-split
  let large-n patches in-radius neighbourhood-radius
  if count ants-on large-n < min-ants-in-neighbourhood [
    hatch 1 [
      move-to one-of large-n with [ not any? ants-here ]
    ]
  ]
end

to check-may-live
  if count ants in-radius neighbourhood-radius > max-ants-in-neighbourhood [ die ]
end

to-report random-polarity ; returns either 1 or -1
  report (2 * random 2) - 1
end

to create-and-separate-cities ; create cities, make sure they are 25 patches apart and not too close to the border
  create-cities nr-of-cities [
    set shape "circle" set size 2 * city-radius
    fd random-float 0.2 * max-pxcor set color red
  ]
  let busy? true
  while [ busy? ] [
    set busy? false
    ask cities [
      move-to min-one-of patches [ distance myself ] display
      let too-close other cities in-radius 20
      if any? too-close [
        let x one-of too-close face x
        fd (0 - random-poisson 2) display
        set busy? true
      ]
      if abs(xcor) > max-pxcor - 6 - sensor-offset or abs(ycor) > max-pycor - 6 - sensor-offset  [
        facexy 0 0 rt random-float 15 fd random-poisson 2 display
        set busy? true
      ]
    ]
  ]
  ask patches [ set in-city? false ]
  ask cities [ ask patches in-radius city-radius [ set in-city? true ] ]
  set city-patches patches with [ in-city? ]
end

to create-convex-hull
  ask patches [ set in-convex-hull? in-convex-hull ]
  set convex-hull patches with [ in-convex-hull? ]
end
    
to-report in-convex-hull
  if in-city? [ report true ]
  let degrees [ towards myself ] of city-patches
  let lower filter [ ? <= 180 ] degrees
  let upper filter [ ? >  180 ] degrees
  if not empty? lower and not empty? upper and (360 + max lower) - min upper < 180 [
    report false
  ]
  report max degrees - min degrees >= 180
end

to spray-pheromone
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
       ask patches in-radius city-radius [
         set pheromone pheromone + spray-factor * pheromone-deposit-rate
         set pcolor scale-color lime pheromone 0 pheromone-contrast
       ]
    ]
    display
  ]
end

to toggle-ants
  ask ants [ set hidden? not hidden? ]
end

to toggle-convex-hull
  ifelse any? convex-hull with [ pcolor != green ] [
    ask convex-hull [ set pcolor green ]
  ] [
    ask convex-hull [ set pcolor scale-color lime pheromone 0 pheromone-contrast ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
713
534
70
70
3.5
1
10
1
1
1
0
0
0
1
-70
70
-70
70
1
1
1
ticks

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
NIL
NIL
NIL

BUTTON
145
10
208
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
715
45
887
78
nr-of-cities
nr-of-cities
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
36
80
208
113
start-nr-of-ants
start-nr-of-ants
0
15000
10000
100
1
NIL
HORIZONTAL

SLIDER
715
389
887
422
diffusion-rate
diffusion-rate
0
1.0
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
715
354
887
387
evaporation-rate
evaporation-rate
0
1
0.95
0.05
1
NIL
HORIZONTAL

SLIDER
715
424
887
457
pheromone-contrast
pheromone-contrast
0
100
18
1
1
NIL
HORIZONTAL

SWITCH
36
255
208
288
co-location-allowed
co-location-allowed
1
1
-1000

SLIDER
36
115
208
148
ant-step-size
ant-step-size
0
3
1
1
1
NIL
HORIZONTAL

SLIDER
715
319
887
352
pheromone-deposit-rate
pheromone-deposit-rate
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
36
150
208
183
sensor-offset
sensor-offset
0
20
7
1
1
NIL
HORIZONTAL

SLIDER
36
185
208
218
sensor-angle
sensor-angle
0
120
60
1
1
NIL
HORIZONTAL

SLIDER
36
220
208
253
rotation-angle
rotation-angle
0
120
60
1
1
NIL
HORIZONTAL

SLIDER
715
80
887
113
city-radius
city-radius
0
10
1.5
1.5
1
NIL
HORIZONTAL

SLIDER
715
495
887
528
spray-factor
spray-factor
-0.4
0.4
0.4
0.01
1
NIL
HORIZONTAL

BUTTON
715
459
860
492
NIL
spray-pheromone
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
101
45
208
78
NIL
toggle-ants
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
715
115
887
148
minimum-city-distance
minimum-city-distance
0
30
25
1
1
NIL
HORIZONTAL

SLIDER
715
199
887
232
neighbourhood-radius
neighbourhood-radius
3
7
5.08
0.01
1
NIL
HORIZONTAL

SLIDER
715
234
887
267
min-ants-in-neighbourhood
min-ants-in-neighbourhood
0
100
11
1
1
NIL
HORIZONTAL

SLIDER
715
269
887
302
max-ants-in-neighbourhood
max-ants-in-neighbourhood
0
100
80
1
1
NIL
HORIZONTAL

MONITOR
144
477
208
522
NIL
nr-of-ants
0
1
11

SLIDER
715
150
887
183
threshold-to-interior
threshold-to-interior
0
20
1
1
1
NIL
HORIZONTAL

BUTTON
715
10
847
43
NIL
toggle-convex-hull
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
8
325
208
475
Number of ants
NIL
NIL
0.0
100.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

SLIDER
36
290
208
323
probability-of-death
probability-of-death
0
0.001
0
0.00001
1
NIL
HORIZONTAL

@#$#@#$#@
The exact population size differed depending on the area of the Convex Hull but the initial blob was typically composed of between 10,000 and 15,000 particles. Particles were given random initial positions within these confines and random initial orientations. Any particles migrating out of the bounds of the Convex Hull region were deleted.

The projection concentration was 1.275 units per scheduler step. If a node was covered by a portion of the blob (i.e. if the number of agents in a 3x3 window surrounding the node was >) the projection was reduced to 0.01275 units. Suppression of projection from covered sites was necessary to ensure a uniform concentration within the blob at internal data points. Uncovering of the data points by the shrinking blob acted to increase concentration at exposed nodes, causing the blob to be anchored by the nodes. Diffusion in the lattice was implemented at each scheduler step and at every site in the lattice via a simple mean filter of kernel size 3x3. Damping of the diffusion distance, which limits the distance of chemoattractant gradient diffusion, was achieved by multiplying the mean kernel value by 0.95 per scheduler step.

Shrinkage mechanism

Adaptation of the blob size is implemented via tests at regular intervals as follows.  If there are 1–10 particles in a 9x9 neighbourhood of a particle, and the particle has moved forwards successfully, the particle attempts to divide into two if there is a space available at a randomly selected empty location in the immediate 3x3 neighbourhood surrounding the particle. If there are 0–80 particles in a 9x9 neighbourhood of a particle the particle survives, otherwise it is deleted. Deletion of a particle leaves a vacant space at this location which is filled by nearby particles, causing the blob to shrink slightly. As the process continues the blob shrinks and adapts to the stimuli provided by the configuration of city data points. The frequency at which the growth and shrinkage of the population is executed determines a turnover rate for the particles. The frequency of testing for particle division was every five scheduler steps and the frequency for testing for particle removal was every ten scheduler steps. Since the shrinking blob method is only concerned with the reduction in size of the population it might beasked as to why there are tests for particle division at all.  The particle division mechanism is present to ensure that the adaptation of the blob sheet is uniform across the sheet to prevent ‘tears’ or holes forming within the blob sheet, particularly at the start of an experiment when flux within the blob is initially established.
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
