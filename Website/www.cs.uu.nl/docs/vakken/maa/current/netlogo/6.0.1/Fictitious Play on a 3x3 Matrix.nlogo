globals [ scale sqrt-3 mean-row-0 mean-row-1 mean-row-2 mean-col-0 mean-col-1 mean-col-2 ]

turtles-own [ payoff-matrix action absolute-frequencies relative-frequencies mixed-strategy opponent ]

to init
  set scale max-pxcor
  set sqrt-3 1.7320508075688772935274463415059
  ; ask patches [ set pcolor (pxcor + pycor) mod 2 ]
  create-starting-points
  create-frame ; comes last because drawing turtle dies
  ask patch (1 - scale) (0 - 0.5 * scale) [ set plabel "0" ]
  ask patch (scale - 1) (0 - 0.5 * scale) [ set plabel "1" ]
  ask patch 0 (scale + 1) [ set plabel "2" ]
end

;
to create-starting-points
  let frequency-0 0.0
  while [ frequency-0 <= max-initial-frequency ] [
    let frequency-1 0.0
    while [ frequency-1 <= max-initial-frequency - frequency-0 ] [
      let frequency-2 max-initial-frequency - frequency-0 - frequency-1
      crt 2 [
        set shape "circle" set size 0.3
        set mixed-strategy some-random-mixed-strategy 3
        set absolute-frequencies (list frequency-0 frequency-1 frequency-2)
        compute-relative-frequencies-and-determine-position
        if-else who mod 2 = 0 [ ; so for example turtle 24 is row, then turtle 25 is column
          set color yellow
          set payoff-matrix runresult payoff-matrix-row
        ] [
          set color green
          set payoff-matrix runresult payoff-matrix-col
        ]
        set opponent -1 ; -1 means: does not have an opponent assigned, yet
        pen-down
      ]
      set frequency-1 frequency-1 + initial-frequency-step
    ]
    set frequency-0 frequency-0 + initial-frequency-step
  ]
  ; pair opponents (goes easier after all are created)
  ask turtles with [ who mod 2 = 0 ] [
    set opponent one-of turtles with [
      who mod 2 = 1 and opponent = -1
    ]
    ask opponent [ set opponent myself ]
    create-link-with opponent
  ]
end

to create-frame ; draw a triangle. Start at (0, scale), then move CW
  crt 1 [
    setxy 0 scale set color gray set heading 150 set pen-size 2 pd
    repeat 3 [ fd scale * sqrt-3 rt 120 ] die
  ]
end

to random-payoffs
  set payoff-matrix-row (word n-values 3 [ n-values 3 [ random-payoff ] ])
  set payoff-matrix-col (word n-values 3 [ n-values 3 [ random-payoff ] ])
end

to chaotic-payoffs-1
  set payoff-matrix-row "[[4 5 -7] [-5 7 9] [1 -9 6]]"
  set payoff-matrix-col "[[-3 2 -9] [-3 1 5] [1 -7 -7]]"
end

to chaotic-payoffs-2
  set payoff-matrix-row "[[8 8 -8] [-2 5 -1] [-8 8 4]]"
  set payoff-matrix-col "[[0 -1 -1] [-9 -5 6] [-4 -8 4]]"
end

to shapley-payoffs
  set payoff-matrix-row "[[0 0 1] [1 0 0] [0 1 0]]"
  set payoff-matrix-col "[[0 0 1] [1 0 0] [0 1 0]]"
end

to-report random-payoff
  report round random-normal 0 variation-in-random-payoffs
end

to report-absolute-frequencies
  print (word "1: " [ absolute-frequencies ] of turtle 0 "; 2: " [ absolute-frequencies ] of turtle 1)
end

to report-mixed-strategies
  print (word "1: " [ mixed-strategy ] of turtle 0 "; 2: " [ mixed-strategy ] of turtle 1)
end

to plot-mixed-strategies
  set mean-row-0 mean [ item 0 mixed-strategy ] of turtles with [ who mod 2 = 0 ]
  set-current-plot-pen "row-0"
  plot mean-row-0
  set mean-row-1 mean [ item 1 mixed-strategy ] of turtles with [ who mod 2 = 0 ]
  set-current-plot-pen "row-1"
  plot mean-row-1
  set mean-col-0 mean [ item 0 mixed-strategy ] of turtles with [ who mod 2 = 1 ]
  set-current-plot-pen "col-0"
  plot mean-col-0
  set mean-col-1 mean [ item 1 mixed-strategy ] of turtles with [ who mod 2 = 1 ]
  set-current-plot-pen "col-1"
  plot mean-col-1
  set mean-row-2 1.0 - mean-row-0 - mean-row-1
  set mean-col-2 1.0 - mean-col-0 - mean-col-1
end

to go
  if ticks >= no-trace-after-X-rounds [ ask turtles [ pen-up ] ]
  ask turtles [
    set mixed-strategy best-response payoff-matrix relative-frequencies
    set action generate-action-from mixed-strategy
  ]
  ; report-mixed-strategies
  plot-mixed-strategies
  ask turtles [
    let a [ action ] of opponent
    set absolute-frequencies replace-item a absolute-frequencies (persistence-of-memory * (item a absolute-frequencies) + 1)
    compute-relative-frequencies-and-determine-position
  ]
  tick
  ;if ticks mod 500 = 0 [ ask one-of turtles [ show-info ] ]
end

to compute-relative-frequencies-and-determine-position
  let total (item 0 absolute-frequencies) + (item 1 absolute-frequencies) + (item 2 absolute-frequencies)
  set relative-frequencies (list ((item 0 absolute-frequencies) / total) ((item 1 absolute-frequencies) / total))
  ; draw them
  let x item 0 relative-frequencies
  let y item 1 relative-frequencies
  let triangle-x 0.5 * sqrt-3 * (y - x)  ; convert (x, y) with x + y <= 1 to ternary plot
  let triangle-y 1.0 - 1.5 * x - 1.5 * y ;
  setxy scale * triangle-x scale * triangle-y
end

to-report generate-action-from [ s ]
  let f random-float 1.0
  let my-sum 0.0 let i 0
  foreach s [ ?1 -> set my-sum my-sum + ?1 if my-sum >= f [ report i ] set i i + 1 ]
  report i
end

; To generate n random numbers that sum to one uniformly, one can not generate n random numbers and
; project-on-simplex them.  Instead draw n times Gamma(1) distributed and then project-on-simplex.  The resulting
; vector is Dirichlet(1,1,1) distributed--and that is uniform.
; http://stats.stackexchange.com/questions/14059/generate-uniformly-distributed-weights-that-sum-to-unity
to-report some-random-mixed-strategy [ n ]
  report project-on-simplex n-values n [ 0 - ln random-float 1 ]
end

to-report project-on-simplex [ l ] ; make it sum to 1
  let s sum l
  report map [ ?1 -> ?1 / s ] l
end

; m is one's own payoff matrix, r is the empirical play of the opponent
to-report best-response [ m r ]
  let a item 0 (item 0 m)
  let b item 1 (item 0 m)
  let c item 2 (item 0 m)
  let d item 0 (item 1 m)
  let f item 1 (item 1 m)
  let g item 2 (item 1 m)
  let h item 0 (item 2 m)
  let i item 1 (item 2 m)
  let j item 2 (item 2 m)
  let u item 0 r
  let v item 1 r
  let x (a - h) * u + (b - i) * v + (c - j) * (1 - u - v) ; marginal utility for first action
  let y (d - h) * u + (f - i) * v + (g - j) * (1 - u - v) ; marginal utility for second action
  if x < 0 and y < 0 [ report [0 0] ] ; first actions have negative utility
  if x > y [ report [1 0] ] ; first action has positive marginal utility and better then second
  if y > x [ report [0 1] ] ; analog for second
  let p random-float 1.0 ; both actions have equal positive marginal utility
  if x > 0 [ report (list p (1 - p)) ] ; spread choice between first two actions
  let q random-float 1.0 ; both actions have zero marginal utility
  report (list (min (list p q)) abs(q - p))
end

to default-values
  set max-initial-frequency 100
  set initial-frequency-step 10
  set no-trace-after-X-rounds 20
  set persistence-of-memory 1.000
  set variation-in-random-payoffs 3
end

to inspect-profiles
  if mouse-down? [
    ask min-one-of turtles [ distancexy mouse-xcor mouse-ycor ] [ show-info ]
  ]
end

to show-info
  clear-output
  ;output-print (word "Payoff matrix: " payoff-matrix)
  ;output-print (word "Action: " action)
  output-print (word "Color (yellow is row): " ifelse-value (shade-of? yellow color) [ "yellow" ] [ "green" ])
  output-print (word "Absolute frequencies: " absolute-frequencies)
  output-print (word "Relative frequencies: " map [ ?1 -> precision ?1 2 ] relative-frequencies)
  output-print (word "Current best response: " map [ ?1 -> precision ?1 1 ] mixed-strategy)
  output-print (word "Payoff matrix:\n\n" join map [ ?1 -> (word " action " ?1 ": " join item ?1 payoff-matrix ", ") ] n-values 3 [ ?1 -> ?1 ] "\n")
  ;output-print (word "Opponent: " opponent)
end

to-report join [ l c ]
  report reduce [ [?1 ?2] -> (word ?1 c ?2) ] l
end

to-report pad-left [ s n ]
  report (word join n-values (n - length s) [ " " ] "" s)
end

to print-game-matrix
  clear-output
  let row-matrix runresult payoff-matrix-row
  let col-matrix runresult payoff-matrix-col
  output-print (word "       " join n-values 3 [ ?1 -> (word "   col " ?1 ": " ) ] " ")
  foreach n-values 3 [ ?1 -> ?1 ] [ ?1 ->
    let row ?1 let r []
    foreach n-values 3 [ ??1 -> ??1 ] [ ??1 ->
      set r lput (word "(" pad-left (word item ??1 (item row row-matrix)) 3 ", " pad-left (word item row (item ??1 col-matrix)) 3 ")") r
    ]
    output-print (word "row " ?1 ": " join r " ")
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
305
10
775
425
-1
-1
14.0
1
11
1
1
1
0
0
0
1
-16
16
-10
18
1
1
1
ticks
30.0

BUTTON
228
10
303
43
random
clear-all\nreset-ticks\nrandom-payoffs init
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
240
379
303
412
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

BUTTON
174
379
238
412
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

INPUTBOX
54
150
303
210
payoff-matrix-row
[[3 1 -5] [4 -4 2] [-3 2 -4]]
1
0
String

INPUTBOX
54
212
303
272
payoff-matrix-col
[[0 0 0] [2 0 -2] [0 5 1]]
1
0
String

SLIDER
54
10
226
43
max-initial-frequency
max-initial-frequency
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
54
45
226
78
initial-frequency-step
initial-frequency-step
0
10
10.0
1
1
NIL
HORIZONTAL

BUTTON
228
45
303
78
chaos-1
clear-all\nreset-ticks\nchaotic-payoffs-1 init
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
228
80
303
113
chaos-2
clear-all\nreset-ticks\nchaotic-payoffs-2 init
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
861
57
1105
196
Strategies
NIL
NIL
0.0
1.0
0.1
1.0
true
false
"" ""
PENS
"row-0" 1.0 0 -2674135 true "" ""
"row-1" 1.0 0 -13345367 true "" ""
"col-0" 1.0 0 -10899396 true "" ""
"col-1" 1.0 0 -6459832 true "" ""

MONITOR
779
57
859
102
NIL
mean-row-0
2
1
11

MONITOR
779
104
859
149
NIL
mean-row-1
2
1
11

MONITOR
861
10
941
55
NIL
mean-col-0
2
1
11

MONITOR
943
10
1023
55
NIL
mean-col-1
2
1
11

SLIDER
54
309
303
342
no-trace-after-X-rounds
no-trace-after-X-rounds
0
1000
20.0
10
1
NIL
HORIZONTAL

SLIDER
54
274
303
307
variation-in-random-payoffs
variation-in-random-payoffs
0
8
3.0
0.1
1
NIL
HORIZONTAL

MONITOR
779
151
859
196
NIL
mean-row-2
2
1
11

MONITOR
1025
10
1105
55
NIL
mean-col-2
2
1
11

BUTTON
228
115
303
148
shapley
clear-all\nreset-ticks\nshapley-payoffs init
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
54
344
303
377
persistence-of-memory
persistence-of-memory
0.95
1
1.0
0.001
1
NIL
HORIZONTAL

BUTTON
54
115
226
148
init-with-these-values
clear-all\nreset-ticks\ninit
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
54
80
226
113
NIL
default-values
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
779
275
951
308
NIL
inspect-profiles
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
779
309
1105
446
10

BUTTON
953
275
1105
308
NIL
print-game-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
867
199
1101
246
Red: row-0; blue: row-1; what remains is row-2.  Green: col-0; brown: col-1; what remains is col-2.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

Basic idea: let two players execute fictitious play on a 3x3 stage game.  Row player is yellow, column player is green.

For an interesting graphic effect this basic setup is extended as follows.  Instead of two players there are many player couples yellow/green (row/col), all connected by a grey line to indicate they are a couple.

In fictitious play it is impossible to start with zero initial empirical frequencies, on the pain of dividing by zero.  Therefore each player receives at the outset an a-priori distribution of absolute frequencies of opponent actions.  If for example initial-frequency-step = 10 and max-initial-frequency = 100, then row players will be created with empirical frequnecty distributions of [f1, f2, f3], where f1, f2, and f3 are multiples of 10 and have 100 as their highest value.  In this case, that would give 11^3 = 1331 different initial absolute frequency profiles, and that many different row players will be created.  Similarly for column players.  Coupling does not take notice of initial frequencies.

For display purposes, absolute frequency profiles are normalised to relative frequency profiles and displayed in a 2-dimensional simplex.  That's the triangle you are looking at.

## TRIANGLE

A player's place in the trangle indicates the observed empirical frequencies of its opponent (the play which it is coupled with).  For example, a player in the top of the triangle may have observed empirical frequencies [3 7 212]. A player in the lower left corner of the triangle may have observed empirical frequencies [331 4 6].   A player in the lower right corner may have observed empirical frequencies [2 721 9].

Inspect profiles is a first activity you can do.

## INSPECT PROFILES

To read off profile distributions yourself, initialise randomly (hit "random"), then hit "inspect-profiles".  Then click on various player profiles (yellow/green dots).  If you do not see yellow dots, this is because they are initially hidden under the green dots.  Do you understand what is printed in the output pane?

Let the model run for a short time (hit "go", then quickly hit "go" again).  You see that row profiles (yellow dots) become visible.  Click on them to see their (by now changed) profile.

## PAYOFF MATRICES

Matrix input is symmetrical, so values of column player must be read top down.   Left-under is action 1 ("Top" for row player, "Left" for col player), right under is action 2 ("Middle" for row; "Center" for col).

## MEAN_ROW MEAN-COL

These indicate the average weight of each action.  For example, "mean-row-0" displays the average probability with which the yellow players (row) choose action 0.  The graphs display these averages.  Red: row-0; blue: row-1; what remains is row-2.  Green: col-0; brown: col-1; what remains is col-2.

## PERSISTENCE OF MEMORY

Persistence of memory denotes a factor with which empirical frequencies are multiplied every round.  For normal fictitious play this facor is 1.0.

## NO TRACE AFTER X ROUNDS

No trace after X rounds ensures that animation is not cluttered by traces in later rounds. Plot is a so-called ternary plot.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

Hit "random" then "go". Do you see how different couples converges?  Sometimes they converge to the same observed play.  Sometimes they do not.

## THINGS TO TRY

Hit "chaos 1" then "go".  The profiles do not seem to converge but instead move around in a chaotic pattern.

Hit "Shapley" then "go".  The dynamics is cyclic, thanks to the payoffs in Shapley's game. (Hit "print-game-matrix" if necessary.)

## SPECTACULAR

When Shapley runs and persistance of memory is varied, interesting things happen.  Try!  Can you explain?

## CREDITS AND REFERENCES

Gerard Vreeswijk (c) 2014.
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
