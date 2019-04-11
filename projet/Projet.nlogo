globals [
  initial-energy
  red-initial-energy
  green-initial-energy
  blue-initial-energy
  initial-attacker
  red-initial-attacker
  green-initial-attacker
  blue-initial-attacker
  red-nest-x
  red-nest-y
  green-nest-x
  green-nest-y
  blue-nest-x
  blue-nest-y
  nest-size
  max-food
  nb-red-ant
  nb-blue-ant
  nb-green-ant
  nb-red-food
  nb-blue-food
  nb-green-food
]

breed [red-ants red-ant]
breed [green-ants green-ant]
breed [blue-ants blue-ant]

red-ants-own [
  job ;; 0 for worker, 1 for attacker
  status ;; 0 wiggling, 1 holding food for worker
  energy
  nest-x
  nest-y
  has-food?
  soldier-type
  speed
  pheromone-coef-work
  pheromone-coef-sold
  atk-power
]

green-ants-own [
  job ;; 0 for worker, 1 for attacker
  status ;; 0 wiggling, 1 holding food for worker
  energy
  nest-x
  nest-y
  has-food?
  soldier-type
  speed
  pheromone-coef-work
  pheromone-coef-sold
  atk-power
]

blue-ants-own [
  job ;; 0 for worker, 1 for attacker
  status ;; 0 wiggling, 1 holding food for worker
  energy
  nest-x
  nest-y
  has-food?
  soldier-type
  speed
  pheromone-coef-work
  pheromone-coef-sold
  atk-power
]

patches-own [
  red-worker-chemical
  red-attacker-chemical
  green-worker-chemical
  green-attacker-chemical
  blue-worker-chemical
  blue-attacker-chemical
  ;; amount of chemical for each ant species and job
  nest? ;; is this patch part of a nest
  food ;; amount of food on the patch (0, 5)
]

to setup
  clear-all

  ;; Configure all data initial values
  config

  set-default-shape turtles "bug"

  ;; create ants
  birth-ant-rgb initial-red initial-green initial-blue

  ask patches [
    set nest? (distancexy red-nest-x red-nest-y) < nest-size
    ifelse nest? [] [ set nest? (distancexy green-nest-x green-nest-y) < nest-size ]
    ifelse nest? [] [ set nest? (distancexy blue-nest-x blue-nest-y) < nest-size ]
  ]

  spawn-food
  ask patches [
    set food 0
    recolor-patch
  ]

  reset-ticks
end

to config
  set initial-energy 100
  ;; Default value for all species can be edited per species on the 3 lines under
  set red-initial-energy initial-energy
  set green-initial-energy initial-energy
  set blue-initial-energy initial-energy
  set initial-attacker 30 ;; percentage of attacker at initial (other are workers)
  ifelse species-red = "legionary" or species-red = "red"
  [ set red-initial-attacker 50]
  [ set red-initial-attacker initial-attacker ]
  ifelse species-green = "legionary" or species-red = "red"
  [ set green-initial-attacker 50]
  [ set green-initial-attacker initial-attacker ]
  ifelse species-blue = "legionary" or species-red = "red"
  [ set blue-initial-attacker 50]
  [ set blue-initial-attacker initial-attacker ]
  set red-nest-x 0
  set red-nest-y 100
  set green-nest-x -80
  set green-nest-y -60
  set blue-nest-x 80
  set blue-nest-y -60
  set nest-size 10
  set max-food 5
  set nb-red-ant initial-red
  set nb-blue-ant initial-blue
  set nb-green-ant initial-green
  set nb-red-food 0
  set nb-blue-food 0
  set nb-green-food 0
end

to go
  spawn-food
  ask turtles [
    ifelse job = 0 [
      ifelse has-food? [ return-to-nest ] [ move ]
    ] [
      soldier-move
    ]
    handle-death
  ]

  reproduce

  diffuse-chemical
  ask patches [
    recolor-patch
  ]
  tick
end

;; Map managment

to recolor-patch
  ifelse nest?
  [ ifelse (distancexy red-nest-x red-nest-y) < nest-size [ set pcolor red]
    [ ifelse (distancexy green-nest-x green-nest-y) < nest-size [ set pcolor green]
      [ if (distancexy blue-nest-x blue-nest-y) < nest-size [ set pcolor blue] ]
    ]
  ]
  ;; not a nest
  [ ifelse food > 0 [ set pcolor scale-color yellow food 1 max-food ]
    ;; no food
    [ ;; color-chemical
      ifelse red-worker-chemical > 1 [ set pcolor scale-color (red + 1) red-worker-chemical 0.1 5 ] [
        ifelse red-attacker-chemical > 1 [ set pcolor scale-color (red - 1) red-attacker-chemical 0.1 5 ] [
          ifelse green-worker-chemical > 1 [ set pcolor scale-color (green + 1) green-worker-chemical 0.1 5 ] [
            ifelse green-attacker-chemical > 1 [ set pcolor scale-color (green - 1) green-attacker-chemical 0.1 5 ] [
              ifelse blue-worker-chemical > 1 [ set pcolor scale-color (blue + 1) blue-worker-chemical 0.1 5 ] [
                ifelse blue-attacker-chemical > 1 [ set pcolor scale-color (blue - 1) blue-attacker-chemical 0.1 5 ]
                [ set pcolor black]
    ]]]]]]
  ]
end

to spawn-food
  ask patches
  [ ifelse nest? [] [ if random-float 100 < food-spawn-rate and food < max-food [ set food food + 1 ] ] ]
end

to diffuse-chemical
  diffuse red-worker-chemical (diffusion-rate / 100)
  diffuse red-attacker-chemical (diffusion-rate / 100)
  diffuse green-worker-chemical (diffusion-rate / 100)
  diffuse green-attacker-chemical (diffusion-rate / 100)
  diffuse blue-worker-chemical (diffusion-rate / 100)
  diffuse blue-attacker-chemical (diffusion-rate / 100)

  ask patches [
    set red-worker-chemical red-worker-chemical * (100 - evaporation-rate) / 100
    set red-attacker-chemical red-attacker-chemical * (100 - evaporation-rate) / 100
    set green-worker-chemical green-worker-chemical * (100 - evaporation-rate) / 100
    set green-attacker-chemical green-attacker-chemical * (100 - evaporation-rate) / 100
    set blue-worker-chemical blue-worker-chemical * (100 - evaporation-rate) / 100
    set blue-attacker-chemical blue-attacker-chemical * (100 - evaporation-rate) / 100
  ]
end

;; General turtles behavior

to-report follow-chemical [isFollowEnemy]
  let scent-ahead chemical-scent-at-angle   0 isFollowEnemy
  let scent-right chemical-scent-at-angle  45 isFollowEnemy
  let scent-left  chemical-scent-at-angle -45 isFollowEnemy
  ifelse (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ]
    report true
  ] [
    report false
  ]
end

to-report chemical-scent-at-angle [angle isFollowEnemy]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]

  ifelse isFollowEnemy = false [
    ifelse breed = red-ants [
      ifelse job = 0
      [ ifelse red-worker-chemical > 1
        [ report [red-attacker-chemical] of p ]
        [ report 0 ]
      ]
      [ if job = 1
        [ ifelse red-worker-chemical > 1
          [ report [red-attacker-chemical] of p ]
          [ report 0 ]
        ]
      ]
    ] [
      ifelse breed = green-ants [
        ifelse job = 0
        [ ifelse green-worker-chemical > 1
          [ report [green-attacker-chemical] of p ]
          [ report 0 ]
        ]
        [ if job = 1
          [ ifelse green-worker-chemical > 1
            [ report [green-attacker-chemical] of p ]
            [ report 0 ]
          ]
        ]
      ] [
        if breed = blue-ants [
          ifelse job = 0
          [ ifelse blue-worker-chemical > 1
            [ report [blue-attacker-chemical] of p ]
            [ report 0 ]
          ]
          [ if job = 1
            [ ifelse blue-worker-chemical > 1
              [ report [blue-attacker-chemical] of p ]
              [ report 0 ]
            ]
          ]
        ]
      ]
    ]
  ] [
    ifelse breed = red-ants [
      report max (list ([green-attacker-chemical] of p) ([blue-attacker-chemical] of p) ([green-worker-chemical] of p) ([blue-worker-chemical] of p))
    ] [
      ifelse breed = green-ants [
        report max (list ([red-attacker-chemical] of p) ([blue-attacker-chemical] of p) ([red-worker-chemical] of p) ([blue-worker-chemical] of p))
      ] [
        if breed = blue-ants [
          report max (list ([green-attacker-chemical] of p) ([red-attacker-chemical] of p)  ([green-worker-chemical] of p) ( [red-worker-chemical] of p))
        ]
      ]
    ]
  ]

  report 0
end

to return-to-nest
  facexy nest-x nest-y
  ifelse nest? [
    set has-food? false
    set food food + 1
    if breed = red-ants [
      set nb-red-food nb-red-food + 1
    ]
    if breed = blue-ants [
      set nb-blue-food nb-blue-food + 1
    ]
    if breed = green-ants [
      set nb-green-food nb-green-food + 1
    ]
  ] [
    if job = 0 and has-food? [
      ifelse breed = red-ants [ set red-worker-chemical (red-worker-chemical + 60) * pheromone-coef-work ] [
        ifelse breed = green-ants [ set green-worker-chemical (green-worker-chemical + 60) * pheromone-coef-work ] [
          if breed = blue-ants [ set blue-worker-chemical (blue-worker-chemical + 60) * pheromone-coef-work ]
      ]]
      move
    ]
  ]
end

to move
  if (follow-chemical false) = false [
    rt random 50
    lt random 50
  ]
  fd speed
  set energy energy - 0.5
  if food > 0 [
    set has-food? true
    set food food - 1
  ]
end

to soldier-move
  ifelse soldier-type = "black" [
    black-behavior
  ] [
    ifelse soldier-type = "legionary" [
      legionary-behavior
    ] [
      ifelse soldier-type = "crazy" [
        crazy-behavior
      ] [
        ifelse soldier-type = "red" [
          red-behavior
        ] [
          if soldier-type = "aztec" [
            aztec-behavior
          ]
        ]
      ]
    ]
  ]
end

;; soldiers behaviors
to black-behavior
  if breed = red-ants [
    ifelse any? green-ants-here
    [ hit-ant green ]
    [ ifelse any? blue-ants-here
      [ hit-ant blue ]
      [
        patrol
      ]
    ]
  ]
  if breed = blue-ants [
    ifelse any? red-ants-here
    [ hit-ant red ]
    [ ifelse any? green-ants-here
      [ hit-ant green ]
      [
        patrol
      ]
    ]
  ]
  if breed = green-ants [
    ifelse any? red-ants-here
    [ hit-ant red ]
    [ ifelse any? blue-ants-here
      [ hit-ant blue ]
      [
        patrol
      ]
    ]
  ]
end

to legionary-behavior
  search-prey
end

to crazy-behavior
  search-prey
end

to red-behavior
  search-prey
end

to aztec-behavior
  search-prey
end

;; function use in behavios
to attack
  if breed = red-ants [
    ifelse any? green-ants-here
    [ hit-ant green ]
    [ if any? blue-ants-here
      [ hit-ant blue ]
    ]
  ]
  if breed = blue-ants [
    ifelse any? red-ants-here
    [ hit-ant red ]
    [ if any? green-ants-here
      [ hit-ant green ]
    ]
  ]
  if breed = green-ants [
    ifelse any? red-ants-here
    [ hit-ant red ]
    [ if any? blue-ants-here
      [ hit-ant blue ]
    ]
  ]
end

to hit-ant [prey-color]
  let prey nobody
  let dmg atk-power

  if prey-color = red [set prey one-of red-ants-here]
  if prey-color = green [set prey one-of green-ants-here]
  if prey-color = blue [set prey one-of blue-ants-here]

  if prey != nobody  [
    ifelse breed = red-ants [ set red-attacker-chemical (red-attacker-chemical + 60) * pheromone-coef-sold ] [
      ifelse breed = green-ants [ set green-attacker-chemical (green-attacker-chemical + 60) * pheromone-coef-sold ] [
        if breed = blue-ants [ set blue-attacker-chemical (blue-attacker-chemical + 60) * pheromone-coef-sold ]
    ]]
    ;;if ([energy] of prey) <= 0 [
    ask prey [ set energy energy - dmg] ;; bite the prey
                     ;;]
  ]
end

to patrol
  ifelse distancexy nest-x nest-y > (8 + nest-size) [
    facexy nest-x nest-y
    fd speed
  ] [
    rt random 50
    lt random 50
    fd speed
  ]
  set energy energy - 0.5
end

to search-prey
  if soldier-type = "legionary" [
    ifelse breed = red-ants [ set red-attacker-chemical (red-attacker-chemical + 60) * pheromone-coef-sold ] [
      ifelse breed = green-ants [ set green-attacker-chemical (green-attacker-chemical + 60) * pheromone-coef-sold ] [
        if breed = blue-ants [ set blue-attacker-chemical (blue-attacker-chemical + 60) * pheromone-coef-sold ]
  ]]]

  if (follow-chemical true) = false [ ;; essaie de suivre une ennemie
    if (follow-chemical false) = false [ ;; essaie de suivre une soldate alliée
      rt random 45
      lt random 45
    ]
  ]

  fd speed
  set energy energy - 0.5
  attack
end

;; life functions
to handle-death
  if energy < 0 [
    if job = 0 and status = 1 [
      set food food + 1
    ]

    if breed = red-ants [
      set nb-red-ant nb-red-ant - 1
    ]
    if breed = blue-ants [
      set nb-blue-ant nb-blue-ant - 1
    ]
    if breed = green-ants [
      set nb-green-ant nb-green-ant - 1
    ]

    die
  ]
end


to reproduce
  let nb-red 0
  let nb-green 0
  let nb-blue 0

  ;; give birth to new ant, but it takes lots of energy
  if (nb-red-food * food-energy) > birth-threshold-red
    [ set nb-red-food nb-red-food - (birth-threshold-red / food-energy) ;; we eat the necessary food to the reproduction
      set nb-red nb-red + 1
      set nb-red-ant nb-red-ant + 1
  ]

  if (nb-green-food * food-energy) > birth-threshold-green
    [ set nb-green-food nb-green-food - (birth-threshold-green / food-energy) ;; we eat the necessary food to the reproduction
      set nb-green nb-green + 1
      set nb-green-ant nb-green-ant + 1
  ]

  if (nb-blue-food * food-energy) > birth-threshold-blue
    [ set nb-blue-food nb-blue-food - (birth-threshold-blue / food-energy) ;; we eat the necessary food to the reproduction
      set nb-blue nb-blue + 1
      set nb-blue-ant nb-blue-ant + 1
  ]

  birth-ant-rgb nb-red nb-green nb-blue
end

to birth-ant-rgb [nb-red nb-green nb-blue]
  create-red-ants nb-red [
    ifelse random 100 < red-initial-attacker
    [ set job 1
      set color red - 1]
    [ set job 0
      set color red + 1]
    set size 2
    set energy red-initial-energy
    set nest-x red-nest-x
    set nest-y red-nest-y
    setxy nest-x nest-y
    set has-food? false
    set soldier-type species-red
    ifelse soldier-type = "crazy" [
      set speed 2
      set pheromone-coef-work 0
      set pheromone-coef-sold 0
    ] [
      set speed 1
      set pheromone-coef-work 1
      ifelse soldier-type = "aztec"
      [set pheromone-coef-sold 0]
      [set pheromone-coef-sold 1]
    ]
    ifelse soldier-type = "black"
    [set atk-power 25]
    [ifelse soldier-type = "aztec"
      [set atk-power 50]
      [set atk-power 40]
    ]
  ]

  create-green-ants nb-green [
    ifelse random 100 < green-initial-attacker
    [ set job 1
      set color green - 1]
    [ set job 0
      set color green + 1]
    set size 2
    set energy green-initial-energy
    set nest-x green-nest-x
    set nest-y green-nest-y
    setxy nest-x nest-y
    set has-food? false
    set soldier-type species-green
    ifelse soldier-type = "crazy" [
      set speed 2
      set pheromone-coef-work 0
      set pheromone-coef-sold 0
    ] [
      set speed 1
      set pheromone-coef-work 1
      ifelse soldier-type = "aztec"
      [set pheromone-coef-sold 0]
      [set pheromone-coef-sold 1]
    ]
    ifelse soldier-type = "black"
    [set atk-power 25]
    [ifelse soldier-type = "aztec"
      [set atk-power 50]
      [set atk-power 40]
    ]
  ]

  create-blue-ants nb-blue [
    ifelse random 100 < blue-initial-attacker
    [ set job 1
      set color blue - 1]
    [ set job 0
      set color blue + 1]
    set size 2
    set energy blue-initial-energy
    set nest-x blue-nest-x
    set nest-y blue-nest-y
    setxy nest-x nest-y
    set has-food? false
    set soldier-type species-blue
    ifelse soldier-type = "crazy" [
      set speed 2
      set pheromone-coef-work 0
      set pheromone-coef-sold 0
    ] [
      set speed 1
      set pheromone-coef-work 1
      ifelse soldier-type = "aztec"
      [set pheromone-coef-sold 0]
      [set pheromone-coef-sold 1]
    ]
    ifelse soldier-type = "black"
    [set atk-power 25]
    [ifelse soldier-type = "aztec"
      [set atk-power 50]
      [set atk-power 40]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
7
10
918
922
-1
-1
3.0
1
10
1
1
1
0
1
1
1
-150
150
-150
150
0
0
1
ticks
30.0

SLIDER
948
21
1120
54
initial-red
initial-red
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
944
79
1116
112
initial-green
initial-green
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
948
139
1120
172
initial-blue
initial-blue
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
966
213
1039
246
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
965
274
1028
307
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
953
430
1132
463
food-spawn-rate
food-spawn-rate
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1192
430
1364
463
diffusion-rate
diffusion-rate
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1193
484
1371
517
evaporation-rate
evaporation-rate
0
100
20.0
1
1
NIL
HORIZONTAL

CHOOSER
1138
20
1276
65
species-red
species-red
"black" "legionary" "crazy" "red" "aztec"
1

CHOOSER
1138
80
1276
125
species-green
species-green
"black" "legionary" "crazy" "red" "aztec"
0

CHOOSER
1139
144
1277
189
species-blue
species-blue
"black" "legionary" "crazy" "red" "aztec"
2

MONITOR
1168
215
1249
260
Red ants
nb-red-ant
17
1
11

MONITOR
1161
291
1258
336
Green ants
nb-green-ant
17
1
11

MONITOR
1174
357
1249
402
Blue ants
nb-blue-ant
17
1
11

MONITOR
1275
213
1395
258
Red's nest food
nb-red-food
17
1
11

MONITOR
1282
294
1414
339
Green's nest food
nb-green-food
17
1
11

MONITOR
1286
365
1406
410
Blue's nest food
nb-blue-food
17
1
11

PLOT
948
539
1148
689
Populations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Red" 1.0 0 -2674135 true "" "plot nb-red-ant"
"Green" 1.0 0 -10899396 true "" "plot nb-green-ant"
"Blue" 1.0 0 -13345367 true "" "plot nb-blue-ant"

PLOT
1196
540
1396
690
Nests food
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Red" 1.0 0 -2674135 true "" "plot nb-red-food"
"Green" 1.0 0 -10899396 true "" "plot nb-green-food"
"Blue" 1.0 0 -13345367 true "" "plot nb-blue-food"

SLIDER
1289
21
1482
54
birth-threshold-red
birth-threshold-red
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
1290
82
1501
115
birth-threshold-green
birth-threshold-green
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
1290
143
1490
176
birth-threshold-blue
birth-threshold-blue
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
954
483
1126
516
food-energy
food-energy
0
100
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
