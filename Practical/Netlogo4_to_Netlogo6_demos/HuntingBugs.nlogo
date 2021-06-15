globals [ agents-are-tracked centroids-are-tracked centroids-are-shown links-are-shown ]

; renamed agent to agent' due conflict with primitive function is-agent?
breed [ agents agent' ]
breed [ centroids centroid ]

agents-own [ center ]

to setup
  clear-all
  create-agents number-of-agents [ setxy random-pxcor random-pycor ]
  ask agents [
    hatch-centroids 1 [
      set hidden? true
      set shape "target" ; "x"
      set color [ color ] of myself
      ask myself [ set center myself ]
      create-link-with myself [
        set thickness 0.33
        set color [ color ] of myself
        set hidden? true
      ]
    ]
    set shape "bug" ; "car top"
    set size 3
  ]
  set agents-are-tracked    not track-agents
  set centroids-are-tracked not track-centroids
  set centroids-are-shown   not show-centroids
  set links-are-shown       not show-links
  reset-ticks
end

to go
  read-sliders
  ifelse done
    [ wait 1 setup tick wait 1 ]
    [ ask agents [ move ] tick ]
end

to read-sliders
  if agents-are-tracked != track-agents [
    ask agents [ ifelse track-agents [ pd ] [ pu ] ]
    set agents-are-tracked track-agents
  ]
  if centroids-are-tracked != track-centroids [
    ask centroids [ ifelse track-centroids [ pd ] [ pu ] ]
    set centroids-are-tracked track-centroids
  ]
  if centroids-are-shown != show-centroids [
     ask centroids [ set hidden? not show-centroids ]
     set centroids-are-shown show-centroids
  ]
  if links-are-shown != show-links [
     ask links     [ set hidden? not show-links ]
     set links-are-shown show-links
  ]
end

to erase-tracks
  clear-drawing
end

to do-plot [ average maximum minimum ]
  set-current-plot "Distance to others"
  set-current-plot-pen "Min"
  plot minimum
  set-current-plot-pen "Max"
  plot maximum
  set-current-plot-pen "Avg"
  plot average
  if ticks > 1500 [ set-plot-x-range (ticks - 1500) ticks ]
end


to-report done
  let mean-average-distance-to-others mean [ average-distance-to-others ] of agents
  let max-average-distance-to-others max [ average-distance-to-others ] of agents
  let min-average-distance-to-others min [ average-distance-to-others ] of agents
  do-plot mean-average-distance-to-others max-average-distance-to-others min-average-distance-to-others
  report mean-average-distance-to-others < 1.0
end

to move
  right (ifelse-value better-turn-right [ 1 ] [ -1 ]) * attraction * turn-degree
  fd step-size
end

to-report better-turn-right
  let relative-target-heading ( target-heading - heading ) mod 360
  report 0 < relative-target-heading and relative-target-heading < 180
end

to-report other-agents-i-perceive
  let other-agents other agents
  if adapt-to-all-others [ report other-agents ]
  if attraction < 0 [
    if count other-agents <= number-closest-to-adapt-to [ report other-agents ]
    report min-n-of number-closest-to-adapt-to other-agents [ distance myself ]
  ]
  let far-agents other-agents with [ distance myself >= neighbourhood ]
  if not any? far-agents [ report other-agents ]
  if count far-agents <= number-closest-to-adapt-to [ report far-agents ]
  report min-n-of number-closest-to-adapt-to far-agents [ distance myself ]
end

to-report target-heading
  let ot other-agents-i-perceive
  let mean-amp-xcor mean-modulo ([ xcor + 0.5 ] of ot) (max-pxcor + 1)
  let mean-amp-ycor mean-modulo ([ ycor + 0.5 ] of ot) (max-pycor + 1)
  let mean-xcor (item 0 mean-amp-xcor) - 0.5
  let mean-ycor (item 0 mean-amp-ycor) - 0.5
  let ampl-xcor  item 1 mean-amp-xcor
  let ampl-ycor  item 1 mean-amp-ycor
  ask center [
    setxy mean-xcor mean-ycor
    set size 0.2 + 2.5 * (1.0 - ampl-xcor) + 2.5 * (1.0 - ampl-ycor)
  ]
  report towardsxy mean-xcor mean-ycor
end

to-report average-distance-to-others
  report mean [ distance myself ] of other agents
end

; This function takes the mean (average) of a sequence of numbers modulo k.
; First, all numbers are remapped to 0..360 degrees.  The numbers are now
; vectors on the unit circle.  We now take the mean of the sine and the
; cosine of these vectors, which yields a new vector.
; (1) The /direction/ of the vector yields the average of the numbers.
; (2) The /length/ (amplitude) of the vector yields the certainty of the mean.
; Examples: mean of ( 60, 180, -60 ) mod 360 is (undef, 0).
; Mean of (90, 90, 90) mod 360 is (90, 1).
to-report mean-modulo [ l k ]
  let factor 360 / k
  let mean-sin mean map [ ?1 -> sin ( factor * ?1 ) ] l
  let mean-cos mean map [ ?1 -> cos ( factor * ?1 ) ] l
  ; Atan in Netlogo is special--read manual.  It must therefore be
  ; corrected by the formula (90 - x) mod 360.
  let average (((90 - (atan mean-cos mean-sin))) mod 360) / factor
  ; Amplitude represents certainty of the average.
  let amplitude sqrt (  mean-cos ^ 2 +  mean-sin ^ 2 )
  report list average amplitude
end
@#$#@#$#@
GRAPHICS-WINDOW
431
10
889
469
-1
-1
9.0
1
12
1
1
1
0
1
1
1
0
49
0
49
1
1
1
ticks
30.0

BUTTON
260
10
315
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
1

BUTTON
374
10
429
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
1

SLIDER
260
45
429
78
number-of-agents
number-of-agents
2
40
40.0
1
1
NIL
HORIZONTAL

SLIDER
260
115
429
148
turn-degree
turn-degree
0
12
3.5
0.1
1
NIL
HORIZONTAL

PLOT
10
311
429
491
Distance to others
Ticks
Dist.
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Avg" 1.0 0 -13345367 true "" ""
"Max" 1.0 0 -2674135 true "" ""
"Min" 1.0 0 -10899396 true "" ""

SLIDER
260
185
429
218
number-closest-to-adapt-to
number-closest-to-adapt-to
1
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
260
220
429
253
neighbourhood
neighbourhood
0.00
2.0
1.77
0.01
1
NIL
HORIZONTAL

SWITCH
260
150
429
183
adapt-to-all-others
adapt-to-all-others
1
1
-1000

CHOOSER
163
10
255
55
attraction
attraction
1 -1
0

SWITCH
10
104
141
137
track-agents
track-agents
1
1
-1000

SWITCH
10
69
141
102
show-centroids
show-centroids
1
1
-1000

BUTTON
10
209
94
242
NIL
erase-tracks
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
260
80
429
113
step-size
step-size
0
0.5
0.13
0.01
1
NIL
HORIZONTAL

BUTTON
317
10
372
43
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
10
174
141
207
show-links
show-links
1
1
-1000

SWITCH
10
139
141
172
track-centroids
track-centroids
1
1
-1000

TEXTBOX
46
10
161
36
Attraction 1: pursuit.\nAttraction -1: evasion.
11
0.0
1

SLIDER
260
255
429
288
decay-factor
decay-factor
0
1
1.0
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Bugs live on a torus and have, depending on the value of "attraction", either the objective to meet each other ("attraction" = 1) or to avoid each other, i.e. stay out of each other's way ("attraction" = -1).  They do so by watching the location of other bugs and then turn left or right based on the observed location of these other bugs.  The problem is that adaptation is based on locations of bugs that are in the process of adaptation themselves.

## WHY?

For a master course on adaptive agents I was thinking of a very simple example that I could begin the course with.  This example should demonstrate, above all, typical behavior of agents that adapt their behaviour to other agents that are themselves in the same process of adaptation.

After I constructed the program, I realised that it is a simple instance of an N-type pursuit (a = 1) or avoidance (a = -1) game.  Pursuit and avoidance games are instances of so-called differential games.  Books on differential games are written among others by Isaacs (1965), Friedman (1971), and Hajek (1975).  I think by then dg's were hot because of research in military warfare stimulated by the cold war (1945-1989).  Could be.

## SIMPLICITY

The challenge partially was to find one of the most simple examples.  An even simpler example would be to put bugs on the unit circle, but then bug traces would be difficult to see.   (Bugs frequently re-visit locations in 1D.)  The unit interval (bounded 1D) is not suitable, because boundaries would influence avoidance behaviour.  Also, the real line (unbounded 1D) is not suitable, because the absence of boundaries would enable simple avoidance behaviour.  (Simply flee away to infinity.)

## HOW IT WORKS

A bug moves as follows: 1) determine location of other bugs 2) based on this observation, turn left "turn-degree" degrees or turn right "turn-degrees" degrees.  3) Move forward "step-size".

## OTHER BUGS

The set named "other bugs" is determined as follows.  Depending on the value of "number-closest-to-adapt-to", let's call this N, a bug determines the location of its N closest neighbours.  N may vary from 1 to the total number of bugs - 1.  Thus, if "number-closest-to-adapt-to" = N = 3, a bug determines the location of its three closest neighbours.  Then the centroid (center of gravity, middle point) of these N bugs is determined.  This centroid (depicted in the form of a target) will be point of direction for the present bug.  If the centroid is on the left to the present bug, and the objective is to meet other bugs, then the bug will turn left.  Similarly, if the centroid is on the left to the present bug, and the objective is to avoid other bugs, then the bug will turn right.

The "adapt-to-all-others" switch is a shortcut to "number-closest-to-adapt-to" := number of other turtles.

The "neighbourhood" slider is to set a neighborhood in attraction scenarios.  If "neighbourhood" is set to, say 1.141, then neighbours within 1.141 crow distance are considered to be on the same location and are ignored in the determination of the N closest neighbours.  This is to avoid adaptation to neighbours that may already be considered to be on the same location.  If "neighbourhood" is set to 0 in attraction scenarios, then N = 1 would cause bugs to adapt in pairs and ignore the rest.  The value SQRT(2) = 1.141 is a good value, because it respects the patch size of the simulation.

## CENTROID ON A TORUS

In 2D, i.e. the plane, the centroid of N points is clearly defined.  I.e., the average of (1, 3), (2, 5) and (-1, 6) is ((1+2-1)/3, (3+5+6)/3).  The centroid of N points on a torus is defined similarly, but we will have to take notice that nearness and direction on a torus are of course defined differently.

To understand how the concept of a centroid on a torus is defined, let's move down one dimension lower to the unit circle.  Let the degrees stand for directions of wind.  You receive two wind directions, and then you'll have to report an average wind direction.  The set { 120, 122 } is a clear case, you'd most probably report 121 as an average.  But what about the set { 0, 180 }?  The number 90 is not the right answer, because then -90 or 270 equally well would be.  Probably the best answer is to remain undecisive here.  The wind is blowing from two totally opposite directions, so you simply can't tell.

The average of two (or more) directions is computed by representing degrees as vectors on a circle, and then add the vectors.  Then map the sum of the vectors back to the circle, that is your average.  The certainy factor of this average is the length of the sum vector.  If the vectors point in different directions, the certainty factor is low; the certainty factor is 1 if and only if all vectors point in the same direction.

Now generalise to the torus and we are done.

## TO DO

Implement decay factor.  The decay factor should cause bugs to slow down when they are in the neighborhood of their goal.

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

Gerard Vreeswijk (c) 2009.
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

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

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

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

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
NetLogo 6.0.4
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
