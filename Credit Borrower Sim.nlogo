globals [
  counter1
  loans-given-with-ir-5
  loans-given-with-ir-10
  loans-given-with-ir-7-5
  loans-refused
  simulation-running?
  customers-served
  current-loan-to-be-served
  current-credit-score
  gross-loan-amount
  ir-multiplier
  credit-score-acceptance-treshold
  total-loans-given
  current-cycle-customers
  prospected-returns

  profit

  unemployment-rate
  bankrupt-rate

  num-bankrupt
  num-unemployment
  num-default

  default-value
  bank-loss
]

extensions[sound]

breed [tenant tenants]
breed [desk desks]
breed [borrower borrowers]

turtles-own [
  monthly-income ; ($) Influences the borrower's ability to make monthly loan payments. Higher monthly income generally indicates a stronger repayment capacity.
  debt ; ($) A lower ratio is generally more favorable.
  credit-score ; (Integer [300-850]) Higher credit scores are associated with lower credit risk. We can use credit score ranges to categorize applicants (e.g., excellent, good, fair, poor).
  proposed-loan ; ($) Ensure it aligns with their income and debt levels. Consider setting maximum limits based on income or using income multipliers.
  interest-rate ; (%) Higher credit scores might qualify for lower interest rates.
  monthly-interest-fee ; (%) The monthly interest rate
  proposed-collateral-value ; ($) It serves as a security measure for the lender. Ensure the proposed collateral value is sufficient to cover the loan amount and provides a safety net for the lender in case of default.
  proposed-payoff-time ; (M) A shorter tenure may result in higher monthly payments but lower overall interest paid.
  employment-stability ; (Y) How long has the borrower been with their current employer? Employment stability is often associated with a steady income.
  debt-payment-history ; (%) Aside from the debt-to-income ratio, consider the borrower's history of on-time payments for existing debts. Late payments or defaults may impact the decision.
  debt-to-income-ratio
  approved? ; (Bool)

  unemployment-chance
  bankrupt-chance
  bankrupted?

  spent-rate
  paid-rate
]

to setup
  set customers-served 0
  clear-all
;  sound:play-sound "Local Forecast - Elevator.wav"
  file-open "log.txt"
  show quota

  ; Control the interest rates based on economic conditions
  if economic-conditions = "Recession" [
    set ir-multiplier 0.75
    set credit-score-acceptance-treshold 1.5 * carefulness

    set unemployment-rate 0.5
    set bankrupt-rate 0.6
  ]

  if economic-conditions = "Stable" [
    set ir-multiplier 1
    set credit-score-acceptance-treshold 1 * carefulness

    set unemployment-rate 0.15
    set bankrupt-rate 0.05
  ]

  if economic-conditions = "Boom" [
    set ir-multiplier 1.5
    set credit-score-acceptance-treshold 0.75 * carefulness

    set unemployment-rate 0.05
    set bankrupt-rate 0
  ]

  set prospected-returns 0
  set total-loans-given 0
  set gross-loan-amount 0
  set loans-given-with-ir-5 0
  set loans-given-with-ir-10 0
  set loans-refused 0
  set simulation-running? true
  set counter1 "Available"
  set customers-served 0

  ask patches [
    set pcolor [128 128 128]
  ]

  create-turtles 1 [
    set shape "x"
    setxy -14 10
    set size 6
    set heading 120
    set color red
  ]

  ask patch -10 10 [
    set plabel "EXIT"
  ]

  create-turtles 1 [
    set shape "dollar bill"
    setxy 14 10
    set size 10
    set heading 120
    set color green
  ]

  ask patch 10 11 [
    set plabel "TREASURY"
  ]
  ask patch 11 10 [
    set plabel "DEPARTMENT"
  ]

  create-desk 1
[
  set shape "desk"
  set size 8
  setxy 0 10
  set heading 0
]

    create-borrower 1
[
  set shape "person business"
  set size 6
  setxy 0 -10
  set monthly-income random 5000 + 1000
  set debt random-float 0.5 * monthly-income

  let upper-limit-factor 4.5 ; Adjust this factor according to your needs
  let upper-limit upper-limit-factor * monthly-income ; Upper limit as a factor of monthly income
  set proposed-loan round(random (upper-limit - 1000) + 1000); Generates a random value between 1000 and the upper limit

  set proposed-collateral-value round(proposed-loan * (1 + random-float 0.5) * 100) / 100
  set debt-to-income-ratio debt / monthly-income
  set credit-score calculate-credit-score debt-to-income-ratio
  set proposed-payoff-time calculate-proposed-payoff-time proposed-loan
  set current-credit-score credit-score
  set current-loan-to-be-served proposed-loan
  set proposed-payoff-time calculate-proposed-payoff-time(proposed-loan)
  set approved? false
  set bankrupted? false

  create-label
]

  create-tenant 1
[
  set shape "person service"
  set size 6
  setxy 0 12.5
  set color red
]

  reset-ticks
end

to go
  set current-cycle-customers 0
  if simulation-running? [
    while [current-cycle-customers < quota] [
      if simulation-running? [
        ask borrower[
          face patch 0 10
          move-until-target
        ]
      ]
      tick
      create-borrower 1
      [
        set shape "person business"
        set size 6
        setxy 0 -10
        set monthly-income random 5000 + 1000
        set debt random-float 0.5 * monthly-income


        let upper-limit-factor 4.5 ; Adjust this factor according to your needs
        let upper-limit upper-limit-factor * monthly-income ; Upper limit as a factor of monthly income
        set proposed-loan round(random (upper-limit - 1000) + 1000); Generates a random value between 1000 and the upper limit


        set proposed-collateral-value round(proposed-loan * (1 + random-float 0.5) * 100) / 100
        set debt-to-income-ratio debt / monthly-income
        set credit-score calculate-credit-score debt-to-income-ratio
        set proposed-payoff-time calculate-proposed-payoff-time proposed-loan
        set current-credit-score credit-score
        set current-loan-to-be-served proposed-loan
        set proposed-payoff-time calculate-proposed-payoff-time proposed-loan
        set approved? false
        set bankrupted? false
        create-label
      ]

      wait (1 / speed) ; Adjust the wait time based on the speed slider
      ]
      ; sound:stop-sound

  ]
end

to-report calculate-proposed-payoff-time [loan-proposed]
  let max-proposed-loan 15000
  let min-payoff-time 6
  let max-payoff-time 60
  let min-loan-for-short-payoff 1000  ; Set a threshold for smaller loans

  if loan-proposed <= min-loan-for-short-payoff [
    ifelse round(min-payoff-time / 2) != 0 [
      let short-payoff-time round(min-payoff-time / 2)
      report ceiling(short-payoff-time / 6) * 6  ; Ensure it's a multiple of 6
    ] [report 0]
  ]

  let normalized-loan-proposed (loan-proposed - min-loan-for-short-payoff) / (max-proposed-loan - min-loan-for-short-payoff)
  let calculated-payoff-time min-payoff-time + round((max-payoff-time - min-payoff-time) * normalized-loan-proposed)

  ; Ensure that the calculated payoff time is a multiple of 6
  report ceiling(calculated-payoff-time / 6) * 6
end

to-report calculate-credit-score [ratio]
  let max-debt-to-income-ratio 0.4
  let min-credit-score 300
  let max-credit-score 850
  let raw-score min-credit-score + ((max-credit-score - min-credit-score) * (1 - (ratio / max-debt-to-income-ratio)))
  let temp = min max-credit-score raw-score
  let temp2 = max min-credit-score temp
  report round (temp2)
end


to show-dialog
    create-turtles 1[
    set shape "cloud"
    setxy 1 13
    set size 6
  ]
end

to move-until-target
  while [not at-target?] [
    fd -.45
;    wait (0.5 / speed) ; Adjust the wait time based on the speed slider
  ]
  set counter1 "Unavailable"
  wait (7.5 / speed) ; Adjust the wait time based on the speed slider
  evaluate-loan
  exit-bank
end

to-report at-target?
  report patch-here = patch 0 10
end

to-report at-right-exit?
  report patch-here = patch 14 10
end

to-report at-left-exit?
  report patch-here = patch -14 10
end

to exit-bank
  if at-target? [
    if approved? [
      set heading 90
      set counter1 "Available"
      while [not at-right-exit?] [
        fd .45
;        wait (0.5 / speed) ; Adjust the wait time based on the speed slider
      ]
      die
    ]
    if not approved? [
      set heading -90
      set counter1 "Available"
      while [not at-left-exit?] [
        fd .45
;        wait (0.5 / speed) ; Adjust the wait time based on the speed slider
      ]
      die
    ]

  ]
end

to create-label
  set label-color white
  set size 9
  set label (word "Credit Score: " credit-score "\nLoan: $" proposed-loan "\nMonthly-income: $" monthly-income "\nPayoff time: " proposed-payoff-time " months\nCollateral value: $" proposed-collateral-value)
  set size 6
end

to evaluate-loan
  set approved? false  ; Assume the loan is not approved by default

  if credit-score >= 750 [
    set interest-rate 5
    set monthly-interest-fee (proposed-loan * 0.05) / 12
  ]
  if credit-score >= 600 and credit-score < 750 [
    set interest-rate 7.5
    set monthly-interest-fee (proposed-loan * 0.075) / 12
  ]
  if credit-score >= 450 and credit-score < 600 [
    set interest-rate 10
    set monthly-interest-fee (proposed-loan * 0.1) / 12
  ]

  let total-payments proposed-payoff-time * 12
  let max-loan (monthly-income * 12 * 3)
  let monthly-installments precision ((proposed-loan / proposed-payoff-time) + monthly-interest-fee) 3
  let total-repayment monthly-installments * proposed-payoff-time

  if credit-score >= 750 * credit-score-acceptance-treshold and debt-to-income-ratio <= 0.5 and proposed-loan <= max-loan and proposed-payoff-time <= 60 [
    set approved? true
    set loans-given-with-ir-5 loans-given-with-ir-5 + 1
    set gross-loan-amount gross-loan-amount + proposed-loan
    set total-loans-given total-loans-given + 1
    set prospected-returns prospected-returns + total-repayment
    set profit profit + total-repayment - proposed-loan
    output-print (word "Customer no: " (customers-served + 1)
      "\nLoan of: $" current-loan-to-be-served
      "\ngiven at: " (ir-multiplier * 5)
      "% Interest Rate. \nGood credit score of: " current-credit-score
      "\nSufficient monthly income of: $" monthly-income
      "\nCollateral value of: $" proposed-collateral-value
      "\nPayoff time: " proposed-payoff-time " months."
      "\nPaid in installments of $" monthly-installments "."
      "\nTotal value to be repaid $" total-repayment "."
     "\nEconomic state: " economic-conditions "."
      "\n=======================================")
    file-print (word "Loan of $" current-loan-to-be-served " given at 5% Interest Rate. Good credit score of " current-credit-score ".")
  ]

  if credit-score >= 600 * credit-score-acceptance-treshold and credit-score < 750 * credit-score-acceptance-treshold and debt-to-income-ratio <= 0.4 and proposed-loan <= max-loan and proposed-payoff-time <= 60 [
    set approved? true
    set loans-given-with-ir-7-5 loans-given-with-ir-7-5 + 1
    set gross-loan-amount gross-loan-amount + proposed-loan
    set total-loans-given total-loans-given + 1
    set prospected-returns prospected-returns + total-repayment
    set profit profit + total-repayment - proposed-loan
    output-print (word "Customer no: " (customers-served + 1)
      "\nLoan of: $" current-loan-to-be-served
      "\ngiven at " (ir-multiplier * 7.5) "% Interest Rate. \nGood credit score of: " current-credit-score
      "\nSufficient monthly income of: $" monthly-income
      "\nCollateral value of: $" proposed-collateral-value
      "\nPayoff time: " proposed-payoff-time " months."
      "\nPaid in installments of $" monthly-installments "."
      "\nTotal value to be repaid $" total-repayment "."
      "\nEconomic state: " economic-conditions "."
      "\n=======================================")

    file-print (word "Loan of $" current-loan-to-be-served " given at 7.5% Interest Rate. Good credit score of " current-credit-score ".")
  ]

  if credit-score >= 450 * credit-score-acceptance-treshold and credit-score < 600 * credit-score-acceptance-treshold and debt-to-income-ratio <= 0.35 and proposed-loan <= max-loan and proposed-payoff-time <= 60 [
    set approved? true
    set loans-given-with-ir-10 loans-given-with-ir-10 + 1
    set gross-loan-amount gross-loan-amount + proposed-loan
    set total-loans-given total-loans-given + 1
    set prospected-returns prospected-returns + total-repayment
    set profit profit + total-repayment - proposed-loan
    output-print (word "Customer no: " (customers-served + 1)
      "\nLoan of: $" current-loan-to-be-served
      "\ngiven at " (ir-multiplier * 10) "% Interest Rate. \nGood credit score of: " current-credit-score
      "\nSufficient monthly income of: $" monthly-income
      "\nCollateral value of: $" proposed-collateral-value
      "\nPayoff time: " proposed-payoff-time " months."
      "\nPaid in installments of $" monthly-installments "."
      "\nTotal value to be repaid $" total-repayment "."
      "\nEconomic state: " economic-conditions "."
      "\n=======================================")

    file-print (word "Loan of $" current-loan-to-be-served " given at 10% Interest Rate. Good credit score of " current-credit-score ".")
  ]

  if credit-score < 450 * credit-score-acceptance-treshold or debt-to-income-ratio > 0.5 or proposed-loan > max-loan or proposed-payoff-time > 60[
    set loans-refused loans-refused + 1
    output-print (word "Customer no: " (customers-served + 1)
      "\nLoan of $" current-loan-to-be-served
      " refused.\nEconomic state: " economic-conditions
      ".\n=======================================")
    file-type (word "Loan of $" current-loan-to-be-served " refused.\nEconomic state: " economic-conditions ".\n=======================================")
  ]

  ; only record those who got the loan approved
  if approved? [
  set bankrupt-chance random-float 1.0
  set paid-rate random-float 1.0

  if bankrupt-chance < bankrupt-rate [
    set num-bankrupt num-bankrupt + 1
    set num-default num-default + 1

    if total-repayment * (paid-rate) - total-repayment < 0 [
        set default-value default-value + total-repayment - total-repayment * (paid-rate)
      ]
    if total-repayment * (paid-rate) - proposed-loan < 0 [
        set bank-loss bank-loss - total-repayment * (paid-rate) + proposed-loan
        set profit profit + total-repayment * (paid-rate) - proposed-loan
      ]
    set bankrupted? true
  ]

  set unemployment-chance random-float 1.0
  set spent-rate random-float 1.0

  if unemployment-chance < unemployment-rate - employment-stability [
        set num-unemployment num-unemployment + 1

  if not bankrupted?[
      set proposed-collateral-value spent-rate * proposed-collateral-value
      if total-repayment - total-repayment * (paid-rate) - proposed-collateral-value > 0 [
        set num-default num-default + 1
        set default-value default-value + total-repayment - total-repayment * (paid-rate) - proposed-collateral-value

        if total-repayment * (paid-rate) - proposed-loan + proposed-collateral-value < 0 [
            set bank-loss bank-loss - total-repayment * (paid-rate) + proposed-loan - proposed-collateral-value
            set profit profit + total-repayment * (paid-rate) - proposed-loan + proposed-collateral-value
          ]
        ]
     ]
  ]

  ]

  set customers-served customers-served + 1
  set current-cycle-customers current-cycle-customers + 1
end

to halt-simulation
  set simulation-running? false

end
@#$#@#$#@
GRAPHICS-WINDOW
679
12
1203
537
-1
-1
15.64
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
0
13
171
125
Open Bank
Setup
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
170
13
331
125
NIL
Go\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
500
12
679
57
Counter Busy
counter1
17
1
11

MONITOR
500
57
679
102
5% Loans Given
loans-given-with-ir-5
17
1
11

MONITOR
500
146
679
191
10% Loans Given
loans-given-with-ir-10
17
1
11

MONITOR
500
191
679
236
Loans Refused
loans-refused
17
1
11

PLOT
0
157
499
327
Loans
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
"5% Loans" 1.0 0 -2674135 true "" "plot loans-given-with-ir-5"
"10% Loans" 1.0 0 -13345367 true "" "plot loans-given-with-ir-10"
"7.5% Loans" 1.0 0 -10899396 true "" "plot loans-given-with-ir-7-5"
"Loans Refused" 1.0 0 -7500403 true "" "plot loans-refused"

BUTTON
331
13
498
124
Close Bank
halt-simulation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
500
236
679
281
Customers Served
customers-served
17
1
11

SLIDER
0
124
498
157
quota
quota
0
100
100.0
1
1
Customers
HORIZONTAL

OUTPUT
0
496
499
722
13

SLIDER
500
504
679
537
speed
speed
1
100
100.0
1
1
NIL
HORIZONTAL

MONITOR
500
102
679
147
7.5% Loans Given
loans-given-with-ir-7-5
17
1
11

MONITOR
500
370
679
415
Amount Given In Loans
(word \"$\"gross-loan-amount)
17
1
11

CHOOSER
500
459
679
504
economic-conditions
economic-conditions
"Stable" "Recession" "Boom"
1

MONITOR
500
281
679
326
Loans Given
total-loans-given
17
1
11

MONITOR
500
326
679
371
Loans Refused Ratio (%)
round((loans-refused / customers-served) * 100)
17
1
11

PLOT
0
327
499
496
Ratio of Refused Loans
NIL
NIL
0.0
0.0
0.0
100.0
true
false
"" ""
PENS
"Ratio" 1.0 0 -16777216 true "" "plot round((loans-refused / customers-served) * 100)"

MONITOR
500
414
679
459
Total Repayment
(word \"$\" round(prospected-returns))
17
1
11

PLOT
500
537
1203
722
Bank's Total Returns ($)
Revenue
Time
0.0
100.0
0.0
600000.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot prospected-returns"

PLOT
1206
10
1406
160
num bankrupt
NIL
NIL
0.0
100.0
0.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-bankrupt"

MONITOR
1407
10
1529
55
NIL
num-bankrupt
17
1
11

PLOT
1205
158
1405
308
num unemployed
NIL
NIL
0.0
100.0
0.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-unemployment"

MONITOR
1407
54
1530
99
NIL
num-unemployment
17
1
11

MONITOR
1406
99
1530
144
NIL
num-default
17
1
11

PLOT
1206
310
1406
460
bank-loss
NIL
NIL
0.0
100.0
0.0
60000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot bank-loss"

PLOT
1206
462
1406
610
profit
NIL
NIL
0.0
100.0
-30000.0
30000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot profit"

MONITOR
1408
146
1533
191
NIL
profit
2
1
11

PLOT
1204
612
1404
762
default-value
NIL
NIL
0.0
100.0
0.0
10000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot default-value"

MONITOR
1408
193
1534
238
NIL
bank-loss
2
1
11

MONITOR
1406
241
1533
286
NIL
default-value
2
1
11

SLIDER
0
725
194
758
carefulness
carefulness
0.01
1.5
1.02
0.01
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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

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

desk
true
0
Polygon -6459832 false false 30 240 30 90 270 90 270 240 195 240 195 165 105 165 105 240 30 240
Rectangle -6459832 true false 45 105 255 150
Rectangle -6459832 true false 45 105 270 105
Rectangle -6459832 true false 30 90 270 105
Rectangle -6459832 true false 30 105 105 240
Rectangle -6459832 true false 90 135 270 165
Rectangle -6459832 true false 195 105 270 240
Rectangle -16777216 true false 30 150 270 165
Line -16777216 false 30 195 105 195
Line -16777216 false 30 225 105 225
Line -16777216 false 195 195 270 195
Line -16777216 false 195 225 270 225
Rectangle -6459832 true false 30 150 270 165
Line -16777216 false 30 165 270 165
Circle -16777216 true false 225 174 14
Circle -16777216 true false 226 202 14
Circle -16777216 true false 60 172 14
Circle -16777216 true false 59 204 14

dollar bill
false
0
Rectangle -7500403 true true 90 15 210 285
Rectangle -1 true false 105 30 195 270
Circle -7500403 true true 120 120 60
Circle -7500403 true true 105 120 60
Circle -7500403 true true 96 254 26
Circle -7500403 true true 176 248 26
Circle -7500403 true true 167 18 36
Circle -7500403 true true 96 21 26
Circle -7500403 true true 137 66 28
Circle -1 true false 143 72 16
Circle -7500403 true true 130 201 32
Circle -1 true false 138 209 16
Rectangle -16777216 true false 182 64 188 86
Rectangle -16777216 true false 182 90 188 124
Rectangle -16777216 true false 182 128 188 188
Rectangle -16777216 true false 182 191 188 237
Rectangle -1 true false 95 106 101 128
Rectangle -1 true false 202 90 204 209
Rectangle -7500403 true true 124 60 132 103
Rectangle -7500403 true true 167 199 173 230
Line -7500403 true 116 59 116 104
Line -7500403 true 111 241 111 196
Line -7500403 true 111 59 111 104
Line -16777216 false 176 116 176 71
Polygon -1 true false 121 127 133 142 140 142 150 130 152 126 168 142 168 158 148 173 144 167 133 164 124 174 107 161 108 135
Rectangle -1 true false 95 134 101 184

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

letter sealed
false
0
Rectangle -7500403 true true 30 90 270 225
Rectangle -16777216 false false 30 90 270 225
Line -16777216 false 270 105 150 180
Line -16777216 false 30 105 150 180
Line -16777216 false 270 225 181 161
Line -16777216 false 30 225 119 161

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

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

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

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
NetLogo 6.4.0
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
