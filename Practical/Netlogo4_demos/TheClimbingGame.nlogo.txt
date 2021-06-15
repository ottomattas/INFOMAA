;; Drie soorten agents, agent1 (de linker), agent2 (de bovenste) en agent3 (het gele vierkant)
breed [agent1]
breed [agent2]
breed [agent3]

;; Agents 1 en 2 kunnen een keuze maken en hebben verschillende q-waarden voor hun 3 acties
agent1-own [keuze q1 q2 q3]
agent2-own [keuze q1 q2 q3]

;; Agent 3 heeft een payoff-waarde, afhankelijk van het vakje waar hij op staat
agent3-own [payoff]

;; n is het aantal ticks dat verstreken is, qActie wordt gebruikt bij het updaten van de q-waarde
;; gemPayoff wordt geplot in de grafiek, en wordt berekend met totalPayoff/n
globals [n qActie totalPayoff gemPayoff]









;; Setup
to setup
  ;; Maak de interface leeg van een vorige sessie
  clear-all

  ;; De layout: het 3x3 grid is zwart met witte labels
  ask patches [set pcolor black]
  ask patches [set plabel-color white]
  ;; De rest is wit met zwarte labels
  ask patches with [pxcor = 0 or pycor = 0 or pycor = 4 or pxcor > 3]
  [
    set pcolor white
    set plabel-color black
  ]

  ;; De negen tegels van de matrix krijgen een label met hun payoff-waarde
  ask patches with [pxcor = 1 and pycor = 1] [set plabel "0     "]
  ask patches with [pxcor = 2 and pycor = 1] [set plabel "0     "]
  ask patches with [pxcor = 3 and pycor = 1] [set plabel "5     "]
  ask patches with [pxcor = 1 and pycor = 2] [set plabel "-30     "]
  ask patches with [pxcor = 2 and pycor = 2] [set plabel "7     "]
  ask patches with [pxcor = 3 and pycor = 2] [set plabel "6     "]
  ask patches with [pxcor = 1 and pycor = 3] [set plabel "11     "]
  ask patches with [pxcor = 2 and pycor = 3] [set plabel "-30     "]
  ask patches with [pxcor = 3 and pycor = 3] [set plabel "0     "]

  ;; Agent1 is de agent links, hij is blauw gekleurd en wordt geinitaliseerd op (0,3)
  create-agent1 1
  [
    setxy 0 3
    facexy 1 3
    set color blue
  ]

  ;; Agent2 is de agent boven, hij is rood gekleurd en wordt geïnitialiseerd op (1,4)
  create-agent2 1
  [
    setxy 1 4
    facexy 1 3
    set color red
  ]

  ;; Als optimistic-greedy, initialiseer alle Q-waarden op 50 (bij Epsilon-greedy zijn ze automatisch op 0 geinitialiseerd)
  if(strategy = "Optimistic-greedy")
  [
    ask agent1 [set q1 100 set q2 100 set q3 100]
    ask agent2 [set q1 100 set q2 100 set q3 100]
  ]

  ;; Agent 3 is een geel vierkant
  set-default-shape agent3 "square"
  create-agent3 1
  [
    setxy 1 3
    set color yellow
  ]
end









;; Go, begin de simulatie!
to go
  ;; Agent 1 is eerst aan de beurt, hij maakt zijn keuze...
  ask agent1 [maakkeuze]
  ;; ... en gaat vervolgens op het juiste vakje staan.
  ask agent1 [
    if keuze = 1 [setxy 0 3]
    if keuze = 2 [setxy 0 2]
    if keuze = 3 [setxy 0 1]
  ]

  ;; Hetzelfde geldt voor agent 2, hij maakt een keuze en gaat op een vakje staan.
  ask agent2 [maakkeuze]
  ask agent2 [setxy keuze 4]


  ;; Agent 3 gaat op een vakje staan afhankelijk van de twee gemaakte keuzes van agent 1&2...
  ask agent3 [
    if first [keuze] of agent1 = 1 [setxy first [keuze] of agent2 3]
    if first [keuze] of agent1 = 2 [setxy first [keuze] of agent2 2]
    if first [keuze] of agent1 = 3 [setxy first [keuze] of agent2 1]
  ]
  ;; ... en daarna update hij zijn payoff waarde aan de hand van het vakje waar hij nu op staat.
  ask agent3 [updatepayoff]

  ;; Vervolgens updaten de twee agents hun Q-waarde
  ask agent1 [updateQ]
  ask agent2 [updateQ]

  ;; De Q-waarden worden voor het overzicht bijgehouden naast het grid, deze moeten dus ook een update
  updatelabels

  ;; Het aantal ticks bijhouden
  set n n + 1

  ;; Update plot
  update-plot

  ;; Tick!
  tick
end









;; Explore is soms handig om de agents een zetje te geven als ze dezelfde keuze blijven maken
;; doordat de exploratie niet zo hoog staat. Behalve dat agent 1&2 nu een random keuze maken,
;; doet deze methode precies hetzelfde als de go button.
to explore
  ;; Agent 1 is eerst aan de beurt, hij maakt een willekeurige keuze...
  ask agent1 [set keuze random 3 + 1]
  ;; ... en gaat vervolgens op het juiste vakje staan.
  ask agent1 [
    if keuze = 1 [setxy 0 3]
    if keuze = 2 [setxy 0 2]
    if keuze = 3 [setxy 0 1]
  ]

  ;; Hetzelfde geldt voor agent 2, hij maakt een willekeurige keuze en gaat op een vakje staan.
  ask agent2 [set keuze random 3 + 1]
  ask agent2 [setxy keuze 4]


  ;; Agent 3 gaat op een vakje staan afhankelijk van de twee gemaakte keuzes van agent 1&2...
  ask agent3 [
    if first [keuze] of agent1 = 1 [setxy first [keuze] of agent2 3]
    if first [keuze] of agent1 = 2 [setxy first [keuze] of agent2 2]
    if first [keuze] of agent1 = 3 [setxy first [keuze] of agent2 1]
  ]
  ;; ... en daarna update hij zijn payoff waarde aan de hand van het vakje waar hij nu op staat.
  ask agent3 [updatepayoff]

  ;; Vervolgens updaten de twee agents hun Q-waarde
  ask agent1 [updateQ]
  ask agent2 [updateQ]

  ;; De Q-waarden worden voor het overzicht bijgehouden naast het grid, deze moeten dus ook een update
  updatelabels

  ;; Het aantal ticks bijhouden
  set n n + 1

  ;; Update plot
  update-plot

  ;; Tick!
  tick
end






;; Update de payoffwaarden aan de hand van de gegeven matrix
to updatepayoff
  if xcor = 1 and ycor = 1 [set payoff 0]
  if xcor = 2 and ycor = 1 [set payoff 0]
  if xcor = 3 and ycor = 1 [set payoff 5]
  if xcor = 1 and ycor = 2 [set payoff -30]
  if xcor = 2 and ycor = 2 [set payoff 7]
  if xcor = 3 and ycor = 2 [set payoff 6]
  if xcor = 1 and ycor = 3 [set payoff 11]
  if xcor = 2 and ycor = 3 [set payoff -30]
  if xcor = 3 and ycor = 3 [set payoff 0]

  set totalPayoff totalPayoff + payoff
  if(n > 0) [set gemPayoff (totalPayoff / n)]

end









;; Update de Q-waardes
to updateQ
  ;; Het updaten van de Q-waardes gaat als volgt:
  ;; Eerst wordt Qactie berekend volgens de formule Qactie = Qactie + a(r - Qactie)
  ;; Daarna wordt gemiddeld over een aantal stappen (te bepalen met de slider 'middelen')
  ;; Als er minder ticks zijn verstreken dan het aantal stappen waarover gemiddeld moet worden, wordt
  ;; de nieuwe Q-waarde de waarde van Qactie, en anders wordt er wel gemiddeld over het aantal stappen.
  ;; Dit werkt uiteraard voor alledrie Q-waadren (q1, q2, q3) hetzelfde.
  if keuze = 1
  [
    set qActie (q1 + leersnelheid * (first [payoff] of agent3 - q1))
    if(n >= middelen) [set q1 (middelen * q1 + qActie) / (middelen + 1)]
    if(n < middelen) [set q1 qActie]
  ]

  if keuze = 2
  [
    set qActie (q2 + leersnelheid * (first [payoff] of agent3 - q2))
    if(n >= middelen) [set q2 (middelen * q2 + qActie) / (middelen + 1)]
    if(n < middelen) [set q2 qActie]
  ]

  if keuze = 3
  [
    set qActie (q3 + leersnelheid * (first [payoff] of agent3 - q3))
    if(n >= middelen) [set q3 (middelen * q3 + qActie) / (middelen + 1)]
    if(n < middelen) [set q3 qActie]
  ]

end









;; Update de labels die corresponderen met de Q-waarden van de twee agents
;; Om het overzicht te bewaren zijn de Q-waarden afgerond
to updatelabels
  ask patches with [pxcor = 0 and pycor = 1] [set plabel round first [q3] of agent1]
  ask patches with [pxcor = 0 and pycor = 2] [set plabel round first [q2] of agent1]
  ask patches with [pxcor = 0 and pycor = 3] [set plabel round first [q1] of agent1]

  ask patches with [pxcor = 1 and pycor = 4] [set plabel round first [q1] of agent2]
  ask patches with [pxcor = 2 and pycor = 4] [set plabel round first [q2] of agent2]
  ask patches with [pxcor = 3 and pycor = 4] [set plabel round first [q3] of agent2]
end



to update-plot
  if(n > 30)
  [
    set-current-plot-pen "gemPayoff"
    set-plot-pen-color black
    plot gemPayoff
  ]
end






;; Om de agents een keuze te laten maken
to maakkeuze
  ;; Eerst wordt willekeurig gekozen, dit is om wel de agents wel een keuze te laten maken als de twee hoogste
  ;; q-waardes gelijk zijn, bijvoorbeeld aan het begin bij epsilon-greedy, als alle q-waardes 0 zijn.
  set keuze random 3 + 1

  ;; Vervolgens wordt aan de hand van de hoogste q-waarde een keuze gemaakt
  if(q1 > q2) and (q1 > q3) [set keuze 1]
  if(q2 > q1) and (q2 > q3) [set keuze 2]
  if(q3 > q1) and (q3 > q2) [set keuze 3]

  ;; Met een bepaalde exploratiekans wordt een willekeurige keuze gemaakt
  if(random-float 1 < exploratie) and (strategy = "Epsilon-greedy") [set keuze random 3 + 1]
end
@#$#@#$#@
GRAPHICS-WINDOW
211
10
571
391
-1
-1
70.0
1
20
1
1
1
0
0
0
1
0
4
0
4
0
0
1
ticks

BUTTON
78
10
144
43
NIL
Setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
146
10
209
43
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
37
127
209
160
Leersnelheid
Leersnelheid
0.01
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
37
162
209
195
Exploratie
Exploratie
0
0.2
0.08
0.001
1
NIL
HORIZONTAL

BUTTON
71
92
134
125
NIL
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
136
92
209
125
NIL
Explore
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

CHOOSER
63
45
209
90
Strategy
Strategy
"Epsilon-greedy" "Optimistic-greedy"
1

SLIDER
37
197
209
230
Middelen
Middelen
0
100
50
1
1
NIL
HORIZONTAL

PLOT
9
232
209
382
Gemiddelde payoff
Time
Payoff/time
0.0
10.0
0.0
2.0
true
false
PENS
"default" 1.0 0 -16777216 true
"gemPayoff" 1.0 0 -16777216 true

@#$#@#$#@
WAT IS HET?
-----------
Dit model heet 'the climbing game'. Het bestaat uit twee agents die drie keuzes krijgen. Voor elke combinatie van keuzes is er een andere beloning variërend van -30 tot 11. De twee agents zijn links (blauw) en boven (rood) gemodelleerd als pijlen. Een derde agent, het gele blok, selecteert de juiste payoffwaarde in de 3x3 matrix.

HOE WERKT HET?
--------------
Als de simulatie begint krijgen de agents steeds drie keuzes. Intern houden ze Q-waarden bij voor deze drie keuzes, en kiezen aan de hand van deze Q-waarde.

HOE TE GEBRUIKEN?
-----------------
Om te beginnen druk je op de setup-button. Een nieuw veld wordt gemaakt met de drie agents en de matrix. Klik op de bovenste Go button om de simulatie te starten of op de andere Go button om één stap vooruit te gaan. Daarnaast is er een exploratie-knop om de agents éénmaal willekeurig te laten kiezen.

IN TE STELLEN
-------------
- Leersnelheid, de leersnelheid.
- Exploratie, de exploratie.
- Middelen, het aantal stappen waarover de agents hun Q-waarden moeten middelen
- Stategieën: Er zijn twee strategieën. Ten eerste Epsilon-greedy, waarbij de Q-waarden op 0 geïnitialiseerd worden en de agents de actie met de hoogste Q-waarde kiezen, uitgezonderd een bepaald exploratie-percentage (in te stellen met de slider). De andere strategie is Optimistic-greedy, waarbij de Q-waarden op 100 worden geïnitialiseerd en vervolgens altijd de actie met de hoogste Q-waarde wordt gekozen.

VRAAG 1: KLIMGEDRAG MET EPSILON-GREEDY
--------------------------------------
In het begin lijkt het klimgedrag redelijk willekeurig, na een tijdje wordt dit stabiel: vaak kiezen beide agents actie 3 (payoff 5) of actie 2 (payoff 7). Deze twee acties lijken het meest veilig te zijn. Af en toe kiezen ze een tijdje allebei voor actie 1 (payoff 11) maar dit lijkt meestal niet lang te duren. Een lagere exploratiefactor zorgt logischerwijs voor meer stabiliteit. De leersnelheid lijkt niet veel invloed te hebben.

VRAAG 2: KLIMGEDRAG MET OPTIMISTIC-GREEDY
-----------------------------------------
De agents vertonen hier duidelijk ander gedrag. Bij een lage leersnelheid veranderen de keuzes zeer regelmatig en eindigt de situatie vaak stabiel met de ideale situatie a1-a1. Met een hoge leersnelheid eindigt de situatie vaak stabiel maar de toestand waarin varieert: vaak wel eentje met payoff 5,6,7 of 11.

VRAAG 3: EXPLORATIE BIJ OPTIMISTIC-GREEDY
-----------------------------------------
De Q-waardes bij optimistic-greedy worden hoog geinitialiseerd. Dat betekent dat ze in het begin slechts zullen dalen. Als een actie de hoogste Q-waarde heeft zal deze gekozen worden en elke keer wordt de Q-waarde lager tot dat een andere actie een lagere waarde heeft, dan wordt die actie gekozen. Zo wordt er steeds gevarieerd in keuze.

VRAAG 4: VOORKEUR VOOR STRATEGIE
--------------------------------
Voor mij heeft de optimistic-greedy strategie een voorkeur, en dan wel met een lage leersnelheid, omdat deze het vaker naar een a1-a1 stabiele situatie leidt.

VRAAG 5: INVLOED KENNIS ANDERE AGENT
------------------------------------
Ja, ik zou het probleem anders aanpaken door de agents ook op te laten slaan welke actie van de andere agent welke beloning geeft in combinatie met hun eigen actie.

VRAAG 6: ANDERE MOGELIJKHEDEN
-----------------------------
Een mogelijkheid zou zijn om de agents (bijvoorbeeld) de eerste 100 stappen willekeurig te laten kiezen, en daarna voor altijd de actie die ze éénmaal de hoogste beloning heeft gegeven te laten kiezen. Op die manier zullen ze na de 100 willekeurige acties automatisch allebei actie 1 kiezen.

GEMAAKT DOOR
------------
Vincent Menger, 2009.
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
