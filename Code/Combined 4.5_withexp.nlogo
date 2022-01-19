globals [percentage-separate pmd-missing %-organic %-general %-pmd pmd-bin-size pmd-bin-level general-bin-size general-bin-level recycled-general recycled-organic
  recycled-pmd general-collected pmd-collected recycle-ratio recycle-perception-neigh]
breed [households household]
breed [bins bin]
breed [wastecomps wastecomp ]
breed [trashcans trashcan]
households-own [ waste pmd-trashcan-size pmd-trashcan-level general-trashcan-size general-trashcan-level separated non-separated id education-level recycle-perception bin-satisfaction r happy]
wastecomps-own [ collected-pmd collected-gen counterpmd countergen];  ;not sure how to interpret technology for specific turtle -->< breed function can be used; trucks should be seperate agent; cost trucks (another variables)


to set-up
  clear-all
  set %-organic 0.37 ; need clarificaiton and explanation; Retreived from Milieucentraal
  set %-general 0.53
  set %-pmd     0.10
    ask patches [
    set pcolor black
  ]
    create-bins 2
  [ set shape "garbage can"
    set color red
    set size 2
    set xcor -300 + who * 600          ; location of bins
    set general-bin-size general-regionbin-size            ; we can also make it decision variable
    set pmd-bin-size pmd-regionbin-size
  ]
  create-wastecomps 1[
    set color green set shape "factory" set size 3  ;; easier to see
    setxy 1500 1500

  ]

  create-households number-of-households [
  set id  random 4                 ; how we make sure we have 4 different type of agents in agentset, type of household
  set education-level random 5     ; assumption: educational level is per household, 0 = basisonderwijs (grammar) ; 1= voorgezet onderwijs (secondary); 2 = MBO ; 3 = HBO ; 4 = University
  set pmd-trashcan-size 10        ; assume that bins do not exceed
  set general-trashcan-size 30     ; assume that bins do not exceed
  set bin-satisfaction 0.9         ; starting value, arbitrary
    if who <= 13
    [setxy (-1500 + who * 3) -750 ]
    if who <= 50 and who > 13
    [setxy (-1500 + who * 3) 750]
  set shape "house"
  set size 3
  ( ifelse
      id = 0 [   ; family
        set r 2
        set color green
      ]
      id = 1 [   ; couple
        set r 1.7
        set color brown
      ]
      id = 2 [  ; retiree
        set r 1.5
        set color pink
      ]
      id = 3 [  ; single
        set r 1
        set color white
      ])
    ( ifelse
      education-level = 0 [   ; grammar
        set recycle-perception 0.4
      ]
      education-level = 1 [   ; secondary schooling
        set recycle-perception 0.5
      ]
      education-level = 2 [  ;  MBO
        set recycle-perception 0.6
      ]
      education-level = 3 [  ;HBO
        set recycle-perception 0.7 ;
      ]
      education-level = 4 [  ;University
        set recycle-perception 0.8
      ]
      )
  ]
  reset-ticks
end

to go
  if ticks >= 520 [ stop ]; 10 years
    ifelse separation-at-home = true
     [ask households [
      produce-waste ;it is function
      manage-waste
      change-perceptionlevel]

    ask wastecomps [
     set counterpmd counterpmd + 1
     set countergen countergen + 1
     collect-waste
     recycle-pmd-at-home
     recycle-organic
     calculate-recycle-ratio]
    ]
    [ask households [
      produce-waste
      manage-all
      change-perceptionlevel ] ; Could leave this of since it wont affect the model
     ask wastecomps [
      set counterpmd counterpmd + 1
      set countergen countergen + 1
      collect-waste
      recycle-general-pmd
      recycle-organic
      calculate-recycle-ratio]
    ]
  tick
  ask households [ set waste 0]
end


to produce-waste  ;create a function with r that represents different agentsets , if else will  be used [
    set waste waste + r *  ((376.4 - 0.2 * ticks) - exp(-0.01 * ticks )* sin (0.3 * ticks)) / 52   ; prodcuction of waste per person per week in kg
end

to manage-waste
    set separated  waste * recycle-perception * %-pmd
    set percentage-separate recycle-perception * %-pmd
    set pmd-missing (%-pmd - percentage-separate)
    set non-separated  waste - separated
    set general-trashcan-level (non-separated + general-trashcan-level)
    set pmd-trashcan-level (separated + pmd-trashcan-level)
  ifelse general-trashcan-level >= general-trashcan-size
      [ dump-general-waste ]
      [ ;print "still collecting general"
        set general-trashcan-level general-trashcan-level + non-separated ]
  ifelse pmd-trashcan-level >= pmd-trashcan-size
      [ dump-pmd-waste ]
      [ ;print "still collecting pmd"
        set pmd-trashcan-level pmd-trashcan-level + separated ]
end

to manage-all  ; only applicable in the no separation at home scenario
  set general-trashcan-level general-trashcan-level + waste
  ifelse general-trashcan-level >= general-trashcan-size
      [ dump-general-waste ]
      [ ;print "still collecting general"
      set general-trashcan-level general-trashcan-level + waste ]
end

to dump-general-waste    ; same in both scenarios
  ifelse [general-bin-level] of bin 1 >= [general-bin-size] of bin 1
     [ set happy false
       ;print "no general dump"
       change-satisfactionlevel
       set general-trashcan-level 0]   ; assume that people will still dump their waste but just besides the bin
     [set general-bin-level general-bin-level + general-trashcan-level
      set happy true
      ;print "hallo"
      change-satisfactionlevel
      set general-trashcan-level 0 ]
end

to dump-pmd-waste   ; not applicable in the no separation at home scenario
  ifelse [pmd-bin-level] of bin 0  >= [pmd-bin-size] of bin 0
      [set happy false
       ;print "no pmd dump"
       change-satisfactionlevel
       set pmd-trashcan-level 0]  ; assume that people will still dump their waste but just besides the bin
      [set pmd-bin-level pmd-bin-level + pmd-trashcan-level
      set happy true
      change-satisfactionlevel
      set pmd-trashcan-level 0]
end

to change-satisfactionlevel
  ifelse happy = true
    [ifelse bin-satisfaction >= 0.95238      ; This function makes sure that bin-satisfaction cannot be higher than 1
      [set bin-satisfaction 1]
      [set bin-satisfaction bin-satisfaction * 1.05]]; satisfied = satisfaction level increases %5.
    [set bin-satisfaction bin-satisfaction * 0.95]  ; dissatisfied = satisfaction level decreases %5. It can never reach 0
end

to change-perceptionlevel
  set recycle-perception-neigh mean [recycle-perception] of other households in-radius 5
  ifelse recycle-perception <= recycle-perception-neigh and recycle-perception != 0
    [ifelse recycle-perception >= (recycle-perception-neigh / (2 * recycle-perception-neigh - recycle-perception ))  ; This function makes sure that recycle-perception cannot be higher than 1
      [set recycle-perception recycle-perception * bin-satisfaction
      ;print "lower perception, close to 1"
      ]
      [set recycle-perception (((((recycle-perception-neigh) - recycle-perception)/(recycle-perception-neigh)) + 1 ) * recycle-perception) * bin-satisfaction
      ;print "lower perception, not close to 1"
  ]] ; multiply its own recycle perception by the % difference with the neighbors
   [ifelse recycle-perception <= 0.01
     [set recycle-perception recycle-perception + 0.05]
     [ifelse recycle-perception >= 0.99
      [set recycle-perception recycle-perception * bin-satisfaction
      ;print "higher perception, close to 1"
      ]
      [set recycle-perception recycle-perception * 1.05 * bin-satisfaction
     ;print "higher perception, not close to 1"
    ] ]
  ];
end


to collect-waste ;;Either collection at home or central point collection --> This can be analysed
  if  counterpmd >= nmbr-weeks-pickup-pmd
      [ set pmd-collected pmd-collected + pmd-bin-level
        set pmd-bin-level 0
        print pmd-collected
        set counterpmd 0]
  if  countergen >= nmbr-weeks-pickup-gen
      [ set general-collected general-collected + general-bin-level
        set general-bin-level 0
        print general-collected
        set countergen 0 ]
end

to recycle-pmd-at-home  ; only applicable when pmd is separated at home
   ifelse technology = "Basic"
    [ set recycled-pmd  pmd-collected + (general-collected * pmd-missing * 0.6)] ; depends on the quality of the technology    ; the ratio for pmd collection should be find.
    [ set recycled-pmd  pmd-collected + (general-collected * pmd-missing * 0.8)] ; idem
end

to recycle-general-pmd   ; only applicable when there is no separation at home
   ifelse technology = "Basic"
    [ set recycled-pmd general-collected * %-pmd * 0.6] ; depends on the quality of the technology
    [ set recycled-pmd general-collected * %-pmd * 0.8] ; idem
end

to recycle-organic
  ifelse technology = "Basic"
    [ set recycled-organic general-collected * %-organic * 0.6] ; depends on the quality of the technology
    [ set recycled-organic general-collected * %-organic * 0.8] ;idem
end

to calculate-recycle-ratio
if ticks >= 10 [
    ifelse separation-at-home = true
    [ifelse technology =  "Basic"
      [set recycle-ratio (percentage-separate + (pmd-missing * 0.6)) * 100]
      [set recycle-ratio (percentage-separate + (pmd-missing * 0.8)) * 100] ]
     [set recycle-ratio recycled-pmd / general-collected * 100] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
231
15
662
447
-1
-1
12.82
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
15
19
88
52
set-up
set-up
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
102
19
165
52
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

PLOT
677
12
877
162
PMD Trashcan Level avg
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot mean [pmd-trashcan-level] of households"

PLOT
677
167
877
317
General Bin 1 Level
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [general-bin-level] of bin 1"

PLOT
677
322
877
472
PMD Bin Level Bin 0
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot [pmd-bin-level] of bin 0"

PLOT
897
11
1097
161
General Trashcan Level avg
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean[general-trashcan-level] of households"

PLOT
891
325
1091
475
Total Waste of Households
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [waste] of households"

SWITCH
12
105
177
138
Separation-at-home
Separation-at-home
0
1
-1000

PLOT
8
353
208
503
Average-Bin-Satisfaction
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [bin-satisfaction] of households"

SLIDER
12
63
213
96
number-of-households
number-of-households
0
26
26.0
1
1
NIL
HORIZONTAL

CHOOSER
15
146
153
191
Technology
Technology
"Advanced" "Basic"
1

PLOT
885
170
1085
320
General Collected
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [general-collected] of wastecomps"

PLOT
10
506
210
656
recycle-perception
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [recycle-perception] of households"

PLOT
347
515
667
665
Recycle ratio
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot recycle-ratio"

PLOT
1113
326
1313
476
recycled-pmd
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot recycled-pmd"

MONITOR
219
609
329
654
avg recycle perc.
mean [recycle-perception] of households
3
1
11

SLIDER
19
235
192
268
pmd-regionbin-size
pmd-regionbin-size
50
400
300.0
50
1
NIL
HORIZONTAL

SLIDER
16
198
189
231
general-regionbin-size
general-regionbin-size
100
800
400.0
100
1
NIL
HORIZONTAL

SLIDER
18
270
200
303
nmbr-weeks-pickup-gen
nmbr-weeks-pickup-gen
1
3
2.0
1
1
NIL
HORIZONTAL

SLIDER
18
308
203
341
nmbr-weeks-pickup-pmd
nmbr-weeks-pickup-pmd
1
3
2.0
1
1
NIL
HORIZONTAL

MONITOR
368
456
451
501
NIL
recycle-ratio
3
1
11

MONITOR
223
458
341
503
avg bin-satisfaction
mean [bin-satisfaction] of households
3
1
11

MONITOR
941
550
1057
595
avg education level
mean [education-level] of households
1
1
11

MONITOR
943
615
1046
660
avg household r
mean [r] of households
1
1
11

MONITOR
1093
552
1351
597
NIL
count households with [education-level = 1]
0
1
11

MONITOR
1023
492
1132
537
NIL
general-collected
17
1
11

MONITOR
1150
491
1240
536
NIL
pmd-collected
17
1
11

MONITOR
459
458
547
503
NIL
recycled-pmd
0
1
11

MONITOR
555
458
664
503
NIL
general-collected
0
1
11

PLOT
1135
172
1335
322
PMD collected
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [pmd-collected] of wastecomps"

PLOT
1142
15
1342
165
non-separated of households
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean[non-separated] of households"

MONITOR
690
538
833
583
NIL
pmd-missing
4
1
11

MONITOR
690
587
898
632
separated percentage by households
mean [percentage-separate] of households
3
1
11

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

garbage can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

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
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="2" runMetricsEveryStep="true">
    <setup>set-up</setup>
    <go>go</go>
    <metric>recycle-ratio</metric>
    <enumeratedValueSet variable="Technology">
      <value value="&quot;Basic&quot;"/>
      <value value="&quot;Advanced&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Separation-at-home">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="nmbr-weeks-pickup-pmd" first="1" step="1" last="3"/>
    <steppedValueSet variable="general-regionbin-size" first="200" step="50" last="400"/>
    <enumeratedValueSet variable="number-of-households">
      <value value="26"/>
    </enumeratedValueSet>
    <steppedValueSet variable="nmbr-weeks-pickup-gen" first="1" step="1" last="3"/>
    <steppedValueSet variable="pmd-regionbin-size" first="100" step="50" last="300"/>
  </experiment>
</experiments>
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
