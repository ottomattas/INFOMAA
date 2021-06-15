globals [ shape-of-ants ants-visible? tentacles-visible? ]
breed [ ants ant ]
breed [ tentacle-ends tentacle-end ]

patches-own [ pheromone ]
ants-own [ my-pheromone-deposit-rate end-F end-L end-R endings ] ; blessed means that it may lay pheromone

to setup
  clear-all
  set ants-visible? true
  set tentacles-visible? true
  set shape-of-ants "circle"
  reset
  reset-ticks
end

to toggle-ants
  ask ants [ set hidden? ants-visible? ]
  set ants-visible? not ants-visible?
end

to toggle-sensors
  ask tentacle-ends [ set hidden? tentacles-visible? ]
  ask links [ set hidden? tentacles-visible? ]
  set tentacles-visible? not tentacles-visible?
end

to reset
  create-ants nr-of-ants [
    set shape "bug without sensors" ; "paramecium" or "bug without sensors"
    set color orange
    set size ant-body-size
    setxy random-xcor random-ycor
    set heading 30
    set my-pheromone-deposit-rate 0
    hatch-tentacle-ends 3 [
      set size 2 * sensor-width set shape "circle"
      set color lput sensor-end-transparency extract-rgb [ color ] of myself
      if who mod 3 = 0 [ ask myself [ set end-F myself ] ]
      if who mod 3 = 1 [ ask myself [ set end-L myself ] ]
      if who mod 3 = 2 [ ask myself [ set end-R myself ] ]
      create-link-with myself [ set thickness 0.2 ]
    ]
    set endings (turtle-set end-F end-L end-R)
    align-sensor-endings
  ]
  ask patches [ set pheromone 0 ]
end

to align-sensor-endings
  ask end-F [ move-to myself set heading [ heading ] of myself fd sensor-offset ]
  ask end-L [ move-to myself set heading [ heading ] of myself - sensor-angle fd sensor-offset ]
  ask end-R [ move-to myself set heading [ heading ] of myself + sensor-angle fd sensor-offset ]
end

to recolor-sensor-endings
  ask endings [ set color lput sensor-end-transparency extract-rgb [ color ] of myself ]
end

to go
  ask ants [ sense move ]
  ; -- patches ------------------------------------
  if diffusion-rate > 0 [ diffuse pheromone diffusion-rate ]
  ask patches [
    set pheromone evaporation-rate * pheromone
    set pcolor scale-color lime pheromone 0 pheromone-contrast
  ]
  tick
end

to move ; execute motor stage
  recolor-sensor-endings display
  ; if co-location is allowed or goal patch is not occupied
  if-else co-location-allowed? or not any? ants-on patch-ahead ant-step-size [
    repeat 10 [ fd 0.1 * ant-step-size align-sensor-endings display ] ; forward and deposit pheromone
    set pheromone pheromone + pheromone-deposit-rate
  ] [
    let random-turn random-float 360
    repeat (random-turn / 4) [ rt 4 align-sensor-endings display ]
  ]
end

to sense ; execute sensory stage
  ; sample trail map values
  let FF 0 let FL 0 let FR 0
  let NF 0 let NL 0 let NR 0
  let PF patch-ahead                        sensor-offset
  let PL patch-left-and-ahead  sensor-angle sensor-offset
  let PR patch-right-and-ahead sensor-angle sensor-offset
  ask PF [ set NF neighbours set FF sum [ pheromone ] of NF ]
  ask PL [ set NL neighbours set FL sum [ pheromone ] of NL ]
  ask PR [ set NR neighbours set FR sum [ pheromone ] of NR ]
  let sense-area (patch-set NF NL NR)
  if color-sensed-patches? [
    ask sense-area [ set pcolor red ] display
    ask sense-area [ set pcolor scale-color lime pheromone 0 pheromone-contrast ]
  ]
  if FF > FL and FF > FR [ ask end-F [ set color yellow ] display recolor-sensor-endings stop ]
  if FF < FL and FF < FR [
    ask (turtle-set end-L end-R) [ set color yellow ]
    repeat (ant-rotation-value / 4) [
      right (random-polarity * ant-rotation-value)
      align-sensor-endings
      display
    ]
    stop
  ]
  if FL < FR [ ask end-R [ set color yellow ] repeat (ant-rotation-value / 4) [ right 4 align-sensor-endings display ] stop ]
  if FR < FL [ ask end-L [ set color yellow ] repeat (ant-rotation-value / 4) [ left  4 align-sensor-endings display ] stop ]
  ; else continue facing same direction
end

to-report neighbours
  report patches in-radius sensor-width
end

to-report random-polarity
  report (2 * random 2) - 1
end

to clear-pheromone
  ask patches [ set pheromone 0 set pcolor black ]
end

to spray-pheromone
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
       ask patches in-radius spray-radius [
         set pheromone pheromone + spray-factor * 50
         set pcolor scale-color lime pheromone 0 pheromone-contrast
       ]
    ]
    display
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
669
470
-1
-1
11.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
17
10
80
43
setup
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
144
10
208
43
go
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
17
150
208
183
ant-rotation-value
ant-rotation-value
0
90
45.0
5
1
NIL
HORIZONTAL

SLIDER
17
115
208
148
ant-step-size
ant-step-size
0
4
3.0
0.25
1
NIL
HORIZONTAL

SLIDER
17
255
208
288
sensor-width
sensor-width
1
8
1.5
0.5
1
NIL
HORIZONTAL

SLIDER
17
220
208
253
sensor-angle
sensor-angle
0
90
45.0
5
1
NIL
HORIZONTAL

SLIDER
17
185
208
218
sensor-offset
sensor-offset
0
100
8.0
1
1
NIL
HORIZONTAL

SLIDER
673
45
864
78
evaporation-rate
evaporation-rate
0.85
1
0.9
0.01
1
NIL
HORIZONTAL

SLIDER
673
10
864
43
pheromone-deposit-rate
pheromone-deposit-rate
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
673
80
864
113
diffusion-rate
diffusion-rate
0
1
0.9
0.1
1
NIL
HORIZONTAL

SWITCH
17
290
208
323
co-location-allowed?
co-location-allowed?
1
1
-1000

SLIDER
673
115
864
148
pheromone-contrast
pheromone-contrast
0
5
2.5
0.1
1
NIL
HORIZONTAL

BUTTON
790
150
864
183
spray
spray-pheromone
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
673
185
864
218
spray-factor
spray-factor
-0.1
0.1
0.02
0.01
1
NIL
HORIZONTAL

BUTTON
673
150
788
183
NIL
clear-pheromone
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
673
220
864
253
spray-radius
spray-radius
1
5
3.5
0.5
1
NIL
HORIZONTAL

SLIDER
17
45
208
78
nr-of-ants
nr-of-ants
1
100
1.0
1
1
NIL
HORIZONTAL

BUTTON
82
10
142
43
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

SWITCH
17
325
208
358
color-sensed-patches?
color-sensed-patches?
1
1
-1000

SLIDER
17
360
208
393
sensor-end-transparency
sensor-end-transparency
5
255
85.0
10
1
NIL
HORIZONTAL

BUTTON
17
395
208
428
NIL
toggle-sensors
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
17
430
208
463
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
1

SLIDER
17
80
208
113
ant-body-size
ant-body-size
0
40
16.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## ARTICLES

Jones, Jeff: Characteristics of pattern formation and evolution in approximations of Physarum transport networks. Artificial life, 16(2). pp. 127-53. ISSN 1064-5462, 2010.

Generierung Fehlertoleranter Verbindungsnetzwerke. Florian Johannes Schmidt, 07 September 2012.  Leibniz Universit�t Hannover.

## PARAMETERS

World-width: 600
World-height: 600
Number of agents: 6000 (2%)
Number of foodsources: 35
Radius foodsources: 10.0
Agent rotation value: 45.0 (85.0) normaalverdeeld
Agent distance (step size): 3.0
Sensor width: 2.0 (or 1 as in Jones)
Sensor angle: 45 (or 22.5 as in Jones)
Sensor offsetlength: 15.0 (or 9 as in Jones)
Trailmap damprate: 0.9
Trail value (deposit trail): 50
Diffusion: none

## EXTRA

Agent beweegt zich over re�elwaardige map.  Iedere agent die al voedsel heeft bezocht, krijgt de mogelijkheid een spoor te zetten en verliest deze mogelijkheid niet.   Op steden wordt oneindig veel feromoon gelegd.   If the movement is not successful, the agent remains in its current position, no chemoattractant is deposited, and a new orientation is randomly selected.

## REST

Zoals Jones beschrijft in [ Jon12 ] , is er een manier om generatie grafiek gebaseerd op een implementatie van een matrix van oorsprong . Er zal de voedselbron van Een bron van voedsel door het tellen van het aantal B over de huidige agenten en dit aangehouden voor alle voedselbronnen in een matrix . Is de basis van een drempel uiteindelijk is het mogelijk om alle randen van de grafiek waarin het aantal hin�berge - weer lopen agenten boven de drempelwaarde zijn . Deze drempel is ten hoogste 1/4 tot 1/10 iteraties . Als de grafiek nog steeds niet staat moet de proef herhaald , als gevolg van sterke afwijkt van de gebruikelijke resultaten . 3.2.2 parameterinstellingen Parameters voor de simulator Jones [ Jon10 ] Hattendorf [ Hat10 ] Schmidt Kaart grootte 200 � 200 400 � 300 600 � 600 Agenten 3-15 % 5-15 3-15 Vochtige tarief 0,1 0,1 0,1 Di usion 0.01-0.1 ? - Draaihoek 45 ? 45 ? 85 ? Stap Maat 1 3 pix pix pix 3 Sensor Breedte 1 pix 2 pix 2 pix Sensor hoek 22.5 ? of 45 ? 45 ? 45 ? Sensor O setlength ? 9 pix 15 pix 15 pix Borg Trail 5 50 20 Tabel 3.1 : Mogelijke parameterinstellingen voor de simulator Voor elk gebruik had de parameters van de slijmzwam ingevoerd als First worden gesteld en de taak was de rand ? ects die zich voordoen in de hoeken om minimaliseren , die kan worden gezien in de rode omcirkelde gebied in figuur 3.6 zijn . Om te bepalen welke parameters bijzonder de effecten op de rand e ecten hebben ? hebben , werd elke parameter afzonderlijk veranderd . De resulterende slijmsporen 14 3 algoritmen Figuur 3.6 : Voorbeeld van de rand ects . ( A ) Jones ( b ) Hattendorf ( c ) Schmidt Figuur 3.7 : Tokyo als voorbeeld van de parameterinstellingen ( De trailmap ) werden beoordeeld volgens subjectief uit het beeld en hij - volgt op een beslissing voor een parameter . Wees de resultaten eindigt? Gegeven in Tabel 3.1 . In [ Jon10 ] en [ Hat10 ] ook parameters worden beschreven . An - overhandigen de slijmspoor , de rode waarden beschreven in tabel 3.1 lie�en ontmoedigen - levensmiddelen , de betere eigenschappen aan de rand ects ? tonen . Vooral veroorzaakt de verhoging van de rotatiehoek ( rotatiehoek ) , een aanzienlijke verbetering . Echter, een De ? Zit geboden bij gebruik van deze nieuwe waarde . Het was namelijk significant vaker dat nodes waren niet langer met elkaar verbonden door het spoor . In figuur 3.7 kunt u de impact van verschillende parametersets zien overwegen om het voorbeeld van Tokio. Wanneer de oorsprong matrix ( HM ) werden rood waarden die op basis van dit proces gemarkeerde gedolven , waren ook niet goed te gebruiken . Met de parameters van Friedrich Hattendorf kon rendabeler netwerken te cre�ren over de oorsprong matrix , in tegenstelling tot het bepalen dus de volgende experimenten altijd met de Parameter specificaties van Friedrich Hattendorf werd verwacht . de drempel 3 Algoritmes 15 de oorsprong matrix worden gekarakteriseerd namelijk sterk toenemen . Als u echter de Origin matrix niet wil kijken , dan bieden de rood gemarkeerde Neten waarden . 3.2.3 Herkomst matrix De volgende test is er de verdere behandeling van het gedrag van herkomst matrix op in verschillende drempels . Er zijn dus verschillende Drempels opgeslagen in een simulatie . De drempels zijn pro - procentueel gezien meer dan het aantal iteraties gespecificeerd. Dus bij 5000 iteraties en een drempelwaarde van 500 500/5000 = 0,1 gespecificeerde drempelwaarde . Dit helpt voor een betere vergelijking tussen de verschillende lengtes en iteraties hun drempels .
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

bug without sensors
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80

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

paramecium
true
0
Polygon -7500403 true true 178 269 147 287 119 271 106 217 107 163 91 118 86 78 105 30 150 3 181 28 195 66 196 103 183 154 187 225
Line -7500403 true 85 22 109 32
Line -7500403 true 60 80 90 78
Line -7500403 true 179 156 209 159
Line -7500403 true 171 269 200 278
Line -7500403 true 92 279 123 269
Line -7500403 true 183 223 217 230
Line -7500403 true 192 104 226 107
Line -7500403 true 63 119 91 114
Line -7500403 true 83 216 113 214
Line -7500403 true 79 165 109 163
Line -7500403 true 175 27 205 25
Line -7500403 true 190 65 220 63

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
