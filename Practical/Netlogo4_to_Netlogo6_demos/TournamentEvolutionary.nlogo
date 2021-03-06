globals [
  nr-of-strategies strategy-indexes
  relative-score
  strategies history payoff-matrix
  proportion proportion-times-score stop-light
]

to setup
  clear-all
  set strategies (list "always-coop" "always-defect" "tit-for-tat" "tits-for-tat-5" "pavlov" "unforgiving" "play-randomly") ;
  set nr-of-strategies length strategies
  set strategy-indexes n-values nr-of-strategies [ ?1 -> ?1 ]
  output-print (word
    "There are " nr-of-strategies " strategies:\n\n* " reduce [ [?1 ?2] -> (word ?1 ",\n* " ?2) ] strategies ".\n\n"
    "First row: score of " item 0 strategies " against\nthe rest in " nr-of-restarts " tournaments of " nr-of-rounds " rounds.\n"
    "Second row: score of " item 1 strategies " against\nthe rest in " nr-of-restarts " tournaments of " nr-of-rounds " rounds,\nand so on.\n"
    "Due to noise (every player does a " (noise * 100)  "%\nrandom move), scores may vary.\n"
    "Green is average score.\n"
    "Orange is average score\nweighed by proportions.\n"
    "Blue represents initial proportions.\n"
    "Pink represents running proportions.\n"
    "(Same as what you see on the plot).\n"
  )
  set payoff-matrix [ [ [3 3] [0 5] ] [ [5 0] [1 1] ] ]
  compute-relative-score-table
  ;
  let x 0
  set proportion create-partition nr-of-strategies
  foreach strategy-indexes [ ?1 ->
    ask patch (?1 + 1) (0 - nr-of-strategies - 1) [
      write-proportion ?1
      set plabel (precision item ?1 proportion 1) set plabel-color cyan
    ]
    set x expected-score-of ?1
  ]
  define-stop-light
  reset-ticks
end

to-report create-partition [ n ]
  let answer n-values n [ 1 + random n ]
  report map [ ?1 -> ?1 / sum answer ] answer
end

to go
  foreach strategy-indexes [ ?1 ->
    write-proportion ?1
    set-current-plot-pen item ?1 strategies
    plot item ?1 proportion
  ]
  set proportion-times-score map [ ?1 -> (item ?1 proportion) * (expected-score-of ?1) ] strategy-indexes
  let total-score sum map [ ?1 -> ?1 ] proportion-times-score
  let old-proportion proportion
  set proportion map [ ?1 -> ?1 / total-score ] proportion-times-score
  tick
  if stop-if-no-change [
    let delta sum (map [ [?1 ?2] -> (?1 - ?2) ^ 2 ] proportion old-proportion)
    if delta < 1.0E-20 [
      output-print (word "Stopped at round " ticks " because of convergence.")
      let ranking map [ ?1 -> item ?1 strategies ] sort-by [ [?1 ?2] -> item ?1 proportion > item ?2 proportion ] strategy-indexes
      output-print (word "Winner: " reduce [ [?1 ?2] -> (word ?1 ",\nthen " ?2) ] ranking ".")
      set-stop-light red
      stop
    ]
  ]
  if ticks mod nr-of-gens-before-stop = 0 [
    output-print (word "Stopped on " ticks "th generation")
    let ranking map [ ?1 -> item ?1 strategies ] sort-by [ [?1 ?2] -> item ?1 proportion > item ?2 proportion ] strategy-indexes
    output-print (word "Ranking so far: " reduce [ [?1 ?2] -> (word ?1 ",\nthen " ?2) ] ranking ".")
    set-stop-light orange
    stop
  ]
  set-stop-light black
end

to-report expected-score-of [ strategy-index ]
  let expected-score sum map [ ?1 ->
    (item ?1 proportion) * (item (nr-of-strategies * strategy-index + ?1) relative-score)
  ] strategy-indexes
  ask patch (nr-of-strategies + 2) (0 - strategy-index) [ set plabel (precision expected-score 1) set plabel-color orange ]
  report expected-score
end

to-report play-with-noise [ strategy-index player ]
  if noise > random-float 1.0 [ report random 2 ]
  report run-result (word (item strategy-index strategies) " " player)
end

to-report always-coop [ player ]
  report 0
end

to-report always-defect [ player ]
  report 1
end

to-report unforgiving [ player ]
  let others-history item (1 - player) history
  if member? 1 others-history [ report 1 ]
  report 0
end

to-report tit-for-tat [ player ]
  let others-history item (1 - player) history
  if empty? others-history [ report 0 ]
  if first others-history = 1 [ report 1 ]
  report 0
end

to-report tits-for-tat-5 [ player ]
  let others-history item (1 - player) history
  if empty? others-history [ report 0 ]
  if member? 1 sublist others-history 0 min (list 4 (length others-history - 1)) [ report 1 ]
  report 0
end

to-report play-randomly [ player ]
  report random 2
end

to-report pavlov [ player ]
  ; win-stay, loose-shift
  ; Pavlov does what he did if he wasn't punished, but does what he
  ; didn't do when he was punished.
  ; Werk nu samen als en slechts als zowel jij als de tegenstander in de
  ; vorige ronde dezelfde strategie hanteerden.
  ; Wissel van strategie als de tegenstander in de vorige ronde
  ; verzaakte.
  if length (item (1 - player) history) = 0 [ report 0 ]
  if first (item (1 - player) history) = first (item player history) [ report 0 ]
  report 1
end

; joss, friedman, tit-for-two-tats


to compute-relative-score-table
  set relative-score n-values (nr-of-strategies ^ 2) [ 0.0 ]
  foreach strategy-indexes [ ?1 ->
    let strat-0 ?1
    let sum-of-score 0.0
    foreach strategy-indexes [ ??1 ->
      let strat-1 ??1
      if strat-1 >= strat-0 [
        let payoff-0-total 0
        let payoff-1-total 0
        repeat nr-of-restarts [
          set history [[] []]
          repeat nr-of-rounds [
            let action-0 play-with-noise strat-0 0
            let action-1 play-with-noise strat-1 1
            set history (list (fput action-0 item 0 history) (fput action-1 item 1 history))
            ; if length history > 10 [ set history but-last history ]
            let payoff-0 item 0 (item action-1 (item action-0 payoff-matrix))
            let payoff-1 item 1 (item action-1 (item action-0 payoff-matrix))
            set payoff-0-total payoff-0-total + payoff-0
            set payoff-1-total payoff-1-total + payoff-1
            ;print (word strat-0 "/" strat-1 " [" action-0 "," action-1 "] -> (" payoff-0 "," payoff-1 ")")
          ]
        ]
        set relative-score replace-item (nr-of-strategies * strat-0 + strat-1) relative-score (payoff-0-total / (nr-of-restarts * nr-of-rounds))
        set relative-score replace-item (nr-of-strategies * strat-1 + strat-0) relative-score (payoff-1-total / (nr-of-restarts * nr-of-rounds))
        ask patch (strat-1 + 1) (0 - strat-0) [ set plabel precision item (nr-of-strategies * strat-0 + strat-1) relative-score 1 ]
        if strat-1 > strat-0 [
          ask patch (strat-0 + 1) (0 - strat-1) [ set plabel precision item (nr-of-strategies * strat-1 + strat-0) relative-score 1 ]
        ]
      ]
      set sum-of-score sum-of-score + item (nr-of-strategies * strat-0 + strat-1) relative-score
    ]
    let average-score precision (sum-of-score / nr-of-strategies) 1
    ask patch 0 (0 - strat-0) [ set plabel item strat-0 strategies set plabel-color yellow ]
    ask patch (nr-of-strategies + 1) (0 - strat-0) [ set plabel average-score set plabel-color lime ]
  ]
end

to write-proportion [ strategy-index ]
  ask patch (strategy-index + 1) (0 - nr-of-strategies) [ set plabel (precision item strategy-index proportion 1) set plabel-color pink ]
end

to define-stop-light
  set stop-light patches with [
    pxcor < 0 and pxcor > min-pxcor and
    pycor < (0 - nr-of-strategies) and pycor > min-pycor
  ]
end

to set-stop-light [ c ]
  ask stop-light [ set pcolor c ]
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
585
290
-1
-1
27.1
1
11
1
1
1
0
0
0
1
-2
10
-9
0
1
1
1
ticks
30.0

BUTTON
94
10
157
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
159
10
222
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

PLOT
50
314
587
492
Proportion of strategies
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"always-defect" 1.0 0 -2674135 true "" ""
"always-coop" 1.0 0 -10899396 true "" ""
"tit-for-tat" 1.0 0 -8630108 true "" ""
"pavlov" 1.0 0 -6459832 true "" ""
"play-randomly" 1.0 0 -7500403 true "" ""
"unforgiving" 1.0 0 -13345367 true "" ""
"tits-for-tat-5" 1.0 0 -955883 true "" ""

SLIDER
50
115
222
148
noise
noise
0
1
0.05
0.05
1
NIL
HORIZONTAL

SLIDER
50
45
222
78
nr-of-restarts
nr-of-restarts
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
50
80
222
113
nr-of-rounds
nr-of-rounds
0
1000
100.0
50
1
NIL
HORIZONTAL

OUTPUT
589
10
949
492
12

SLIDER
50
150
222
183
nr-of-gens-before-stop
nr-of-gens-before-stop
0
500
500.0
50
1
NIL
HORIZONTAL

SWITCH
50
184
222
217
stop-if-no-change
stop-if-no-change
0
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
