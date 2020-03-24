extensions [ table ]

globals [
  day ;ticks are minutes, this variable counts days
  hour ;ticks are minutes, this variable counts hours
  forwardstep ;movement step for people
  referencestart ;starting time of normal workday
  activitylength ;length of workday
  leisurelength ;amount of time spent at a leisure location
  list-houses ;list of house patches
  list-jobs ;list of job titles
  list-joblocationslookup ;lookup for job patches
  list-schools ;list of school patches
  fridgeempty ;threshold of meals per person in household for when to stock the fridge
  fridgerestock ;number of meals per person in household to restock the fridge from grocery store
]

turtles-own [
  age ;age of person
  houselocation ;patch reference for house
  title ;job title
  joblocation ;patch reference for workplace
  distjob ;distance from home to job
  timeneededjob ;time needed to get to job
  workstart ;starting time of workday
  leisurestart ;starting time of non-work or leisure
  leisurelocation ;patch reference for leisure activity
  leisurecounter ;how long person stays in leisure activity
  infectionlevel ;set the level of infection - 0 = not infected, 1 = infected, 2 = severe, 3 = recovered
  infectedtime ;how long person is infected
  severeprobability ;a person's probability of having a severe infection
]

patches-own [
  capacity ;household size and capacity of hospital
  open? ;is the workplace open
  savings ;household savings from salaries of working adults and pension of retired people
  dailyrent ;rent for household prorated daily
  food ;stock of food in house
]

to setup
  clear-all
  ifelse new_city = true [random-seed random 1000] [random-seed 973]
  set-default-shape turtles "person"
  set forwardstep .3 ;play around with this number to make the movements more fluid
  set referencestart 7 * 60 ;7am is the normal start of the working day in this model
  set activitylength 8 * 60 ;8 hours is the length of the workday and leisure activity
  set leisurelength 60 ;1 hour is how long people spend at their leisure activity
  set fridgeempty 3 ;fridge is considered empty if there are this many meals per person in the household left in the fridge
  set fridgerestock 6 ;number of meals per person in household to restock the fridge from grocery store
  createworld
  createpeople
  updatepopulationplot
  reset-ticks
end

to createworld
  ask patches [ set pcolor white ]

  ask n-of 40 patches with [pcolor = white] [
    set pcolor brown
    set plabel "H"
    set savings starting_household_money ;households get money units at the start based on slider
    set food 20 ;households get 20 food units at the start
    set open? true
  ]

  ask n-of 2 patches with [pcolor = white] [
    set pcolor grey
    set plabel "O"
  ]

  ask n-of 2 patches with [pcolor = white] [
    set pcolor orange
    set plabel "S"
  ]

  ask n-of 5 patches with [pcolor = white] [
    set pcolor green
    set plabel "P"
    set open? true
  ]

  ask n-of 5 patches with [pcolor = white] [
    set pcolor blue
    set plabel "G"
    set savings 0
  ]

  ask n-of 5 patches with [pcolor = white] [
    set pcolor violet
    set plabel "BR"
    set savings 0
  ]

  ask n-of 1 patches with [pcolor = white] [
    set pcolor red
    set plabel "+"
  ]

  set list-houses patches with [plabel = "H"]
  set list-jobs ["2) doctor" "2) teacher" "2) grocerystoreworker" "2) bar/restaurantworker" "2) office worker"] ;titles for jobs
  set list-joblocationslookup ["+" "S" "G" "BR" "O"] ;lookup list for associating titles with the right workplace locations
  set list-schools patches with [pcolor = orange]
end

to createpeople
  create-turtles percent_retired_65+ [
    set color black
    set size 1.5 ;allows differentiation
    set age (65 + random 25) ;retirees are aged 65-90
    set houselocation min-one-of list-houses [count turtles-here] ;ensures that all households have people
    setxy [pxcor] of houselocation [pycor] of houselocation ;sends the person home at the start of the model
    set title "1) retired" ;sets title of person
    set joblocation houselocation ;retirees don't work
    set workstart referencestart ;starts day at 7am
    set leisurestart workstart + activitylength  ;this doesn't matter so much since their work and leisure is the same
    set severeprobability random 100; this is a person's probability of having a severe infection
  ]

  create-turtles percent_workingage_18-64 [
    set color black
    set size 1.3 ;allows differentiation
    set age (18 + random 46) ;working people are aged 18 to 64
    set houselocation min-one-of list-houses [count turtles-here] ;ensures that all households have people
    setxy [pxcor] of houselocation [pycor] of houselocation ;sends the person home at the start of the model
    set title (ifelse-value ;this makes sure that all job titles are filled
      count turtles with [title = "2) doctor"] < 3 [ "2) doctor" ]
      count turtles with [title = "2) grocerystoreworker" ] < 10 [ "2) grocerystoreworker" ]
      count turtles with [title = "2) bar/restaurantworker" ] < 10 [ "2) bar/restaurantworker" ]
      count turtles with [title = "2) teacher" ] < 2 [ "2) teacher" ]
      count turtles with [title = "2) office worker" ] < 2 [ "2) office worker" ]
      [one-of list-jobs]
    )
    let workplace item ( position title list-jobs ) list-joblocationslookup ;looks up the workplace based on the title
    set joblocation min-one-of patches with [ plabel = workplace ] [count turtles with [joblocation = myself]] ;assigns a workplace patch with the least number of workers to make sure they are all filled
    set distjob distance joblocation ;distance from home to the job
    set timeneededjob distjob / forwardstep ;time needed to go to the job
    set workstart referencestart ;normal people start work at 7
    set leisurestart workstart + activitylength ;leisure starts at end of workday
    ask turtles with [title = "2) doctor"] [ ;makes sure there are doctors available 24/7
      if (count turtles with [joblocation = [joblocation] of myself and workstart = referencestart] > count turtles with [joblocation = [joblocation] of myself and workstart = referencestart + activitylength]) [
        set workstart referencestart + activitylength ;work starts at 15 and ends at 23
        set leisurestart workstart + activitylength ;leisure starts at end of workday
      ]
      if (count turtles with [joblocation = [joblocation] of myself and workstart = referencestart] > count turtles with [joblocation = [joblocation] of myself and workstart = referencestart + activitylength * 2]) [
        set workstart referencestart + activitylength * 2 ;work starts at 23 and ends at 7
        set leisurestart workstart + activitylength ;leisure starts at end of workday
      ]
    ]
    ask turtles with [title = "2) grocerystoreworker" or title = "2) bar/restaurantworker"] [ ;makes sure there are grocery and bar/restaurant workers available the whole day
      if (count turtles with [joblocation = [joblocation] of myself and workstart = referencestart] > count turtles with [joblocation = [joblocation] of myself and workstart = referencestart + activitylength]) [
        set workstart referencestart + activitylength ;work starts at 15 and ends at 23
        set leisurestart workstart + activitylength ;leisure starts at end of workday
      ]
    ]
    set severeprobability random 100; this is a person's probability of having a severe infection
  ]

  let list-housesadults patches with [any? turtles-here = true] ;this creates a list of houses with an adult

  create-turtles percent_schoolage_under18 [
    set color black
    set size 1 ;allows differentiation
    set age (5 + random 12) ;school age children are 5-17 years old - there are no babies in this model
    set houselocation one-of list-housesadults ;this makes sure that kids aren't living by themselves
    setxy [pxcor] of houselocation [pycor] of houselocation ;sends the person home at the start of the model
    set title "3) school student"
    set joblocation min-one-of list-schools [count turtles-here] ;makes sure all schools have students
    set distjob distance joblocation ;distance from home to the job
    set timeneededjob distjob / forwardstep ;time needed to go to the job
    set workstart referencestart ;school starts at 7
    set leisurestart workstart + activitylength ;leisure starts after school ends
    set severeprobability random 100; this is a person's probability of having a severe infection
  ]

  ask patches with [plabel = "H"] [ ;this sets daily rent to be the combined income of the household
    set capacity count turtles-here
    set dailyrent house_rent_percent_of_hh_income / 100 * (
      count turtles-here with [title = "2) doctor" or title = "2) office worker"] * daily_salary_doctor_officeworker +
      count turtles-here with [title = "2) teacher" ] * daily_salary_teacher +
      count turtles-here with [title = "2) grocerystoreworker" or title = "2) bar/restaurantworker"] * daily_salary_grocery_barworker +
      count turtles-here with [title = "1) retired" ] * daily_pension_retiree
    )
  ]

  ask turtles [ set infectionlevel "0) notinfected" ] ;at the beginning everyone is not infected

  if outbreak = true [ ;if the outbreak switch is turned on, someone at random gets infected
    ask n-of 3 turtles [
      set infectionlevel "1) infected"
      set color 18
    ]
  ]
  if (Close_school = true) [ ;if schools are closed, then teachers and students stay at home and engage in e-learning
    ask turtles with [member? joblocation list-schools] [
      set joblocation houselocation
    ]
  ]
  if (Close_bar = true) [ ;if bars are closed, then bar and restaurant workers don't get paid and have a freeday
    ask turtles with [member? joblocation patches with [plabel = "BR"]] [
      set joblocation houselocation
    ]
  ]
  if Lockdown = true [ ;if there is a lockdown, then all work locations except grocery stores and the hospital are closed
    ask turtles with [title != "2) grocerystoreworker" and title != "2) doctor"] [
      set joblocation houselocation
    ]
  ]

end

to updatepopulationplot ;this creates the bar plot that summarizes the distribution of the population by job title
  set-current-plot "Population and Job Title"
  clear-plot
  let counts table:counts [ title ] of turtles
  let jobtitles sort table:keys counts
  let n length jobtitles
  set-plot-x-range 0 n
  let step 0.05 ;tweak this to leave no gaps
  (foreach jobtitles range n [ [s i] ->
    let y table:get counts s
    let c hsb (i * 360 / n) 50 75
    create-temporary-plot-pen s
    set-plot-pen-mode 1 ;bar mode
    set-plot-pen-color c
    foreach (range 0 y step) [ _y -> plotxy i _y ]
    set-plot-pen-color black
    plotxy i y
    set-plot-pen-color c ;to get the right color in the legend
  ])
end

to go
  set hour floor ((ticks / 60) mod 24) ;the ticks are minutes, so this translates it into hours
  set day floor (ticks / 1440) + 1 ;the ticks are minutes, so this translates it into days

  ifelse
    (day mod 6 = 0 or day mod 7 = 0) [ ;during weekends, grocery store workers, bar/restaurantworkers, and doctors continue working, others have a freeday and if you have a severe infection you are in the hospital
      workday turtles with [ title = "2) grocerystoreworker" or title = "2) bar/restaurantworker" or title = "2) doctor" and infectionlevel != "2) severe"]
      freeday turtles with [ title != "2) grocerystoreworker" and title != "2) bar/restaurantworker" and title != "2) doctor" and infectionlevel != "2) severe"]
    ]
    [ ;during weekdays, only retired people have a freeday
     workday turtles with [ title != "1) retired" and infectionlevel != "2) severe"]
     freeday turtles with [ title = "1) retired" and infectionlevel != "2) severe"]
    ]

  joblocationopen ;this opens or closes the location of the workplace depending on whether there are workers there

  householdmealsrent ;this subtracts means and rent every day

  infectionspread ;this starts the infection spread sequence

  tick
end

to workday [agents]
  ask agents [
    if (ticks >= workstart - timeneededjob) and (ticks < workstart + activitylength) [ ;every workeday people make sure they leave their homes early enough to get to work or school on time
      ifelse
        (Test_Isolate = true and infectionlevel = "1) infected" and title != "2) doctor" and title != "2) grocerystoreworker") [
          move houselocation
        ]
        [
          move joblocation
        ]
    ]

    if (ticks = leisurestart) [
      set workstart workstart + 1440 ;this advances the workstart time so they get to work on time the next day
      set leisurecounter 0 ;this resets their leisure counter so they only spend one hour going somewhere in their free time
      ask houselocation [ ;this makes sure that workers get paid after their workday
        set savings (ifelse-value
          [title] of myself = "2) doctor" or [title] of myself = "2) office worker" [savings + daily_salary_doctor_officeworker]
          [title] of myself = "2) teacher" [savings + daily_salary_teacher]
          [title] of myself = "2) grocerystoreworker" [savings + daily_salary_grocery_barworker]
          [title] of myself = "2) bar/restaurantworker" and [patch-here] of myself != [houselocation] of myself [savings + daily_salary_grocery_barworker]
          [savings + 0]
        )
      ]
      setleisure ;once the workday is over, they select where they want to go in their free time
    ]

    if (ticks > leisurestart + random activitylength) and (ticks < leisurestart + activitylength * 2)  [
      goleisure ;at some random time they move towards their leisure activity
    ]

    if (ticks = leisurestart + activitylength * 2) [
      set leisurestart leisurestart + 1440 ;this advances the leisurestart time so they leave work on time the next day
      set leisurecounter 0 ;this resets their leisure counter so they only spend one hour going somewhere in their free time
    ]
  ]

end

to freeday [agents]
  ask agents [
    if (ticks = workstart) [
      setleisure ;at the start of every freeday people pick a place they want to go, workstart here doesn't mean they go to work since it's a free day
    ]

    if (ticks > workstart + random activitylength / 2) and (ticks < workstart + activitylength)  [
      goleisure
    ]

    if (ticks = leisurestart) [
      set workstart workstart + 1440
      set leisurecounter 0
      ask houselocation [ ;during freedays retirees get their pension - even during weekends
        set savings (ifelse-value
            [title] of myself = "1) retired" [
              savings + daily_pension_retiree
            ]
            [
              savings + 0
            ]
        )
      ]
      setleisure ;during freedays everyone selects two places to go during the day
    ]

    if (ticks > leisurestart + random activitylength) and (ticks < leisurestart + activitylength * 2)  [
      goleisure
    ]

    if (ticks = leisurestart + activitylength * 2) [
      set leisurestart leisurestart + 1440 ;this advances the leisurestart time so they leave work on time the next day
      set leisurecounter 0 ;this resets their leisure counter so they only spend one hour going somewhere in their free time
    ]
  ]
end

to move [location] ;this moves people towards the place they want to go based on the steps per minute set at the start
  face location
  ifelse distance location <= forwardstep
    [ move-to location ]
    [ fd forwardstep ]
end

to setleisure ;this set of code sets the leisure location
  if (title != "3) school student") [ ;if the person isn't a school kid, they first prioritize restocking their fridge, then select either a bar or a park
    set leisurelocation (ifelse-value
      ([food] of houselocation < fridgeempty * [capacity] of houselocation and [savings] of houselocation > fridgerestock * [capacity] of houselocation * meal_cost_grocerystore) [
        min-one-of patches with [plabel = "G" and open? = true] [ distance myself ] ;if they don't have enough food in the fridge, they go to the nearest grocery to restock
      ]
      (Lockdown = true or (Test_Isolate = true and infectionlevel = "1) infected")) [ ;if there is a lockdown or if there is test and isolation and someone is infected, they stay home
        houselocation
      ]
      ([savings] of houselocation > fridgerestock * [capacity] of houselocation * meal_cost_grocerystore) [
        one-of (patch-set min-n-of 3 patches with [plabel = "BR" or plabel = "P" and open? = true] [distance myself] houselocation) ;if they have enough money they select either a restaurant or a park or stay at home
      ]
      [
        one-of (patch-set min-one-of patches with [plabel = "P" and open? = true] [distance myself] houselocation) ;if they have don't enough money they select a park to spend their free time
      ]
    )
  ]
  if (title = "3) school student") [ ;school kids are assumed to be independent enough to select their own leisure place and hang out
    set leisurelocation (ifelse-value
      (Lockdown = true or (Test_Isolate = true and infectionlevel = "1) infected")) [ ;if there is a lockdown or if there is test and isolation and someone is infected, they stay home
        houselocation
      ]
      ([savings] of houselocation > fridgerestock * [capacity] of houselocation * meal_cost_grocerystore) [
        one-of (patch-set min-n-of 3 patches with [plabel = "BR" or plabel = "P" and open? = true] [distance myself] houselocation) ;if they have enough money they select either a restaurant or a park or stay at home
      ]
      [
        one-of (patch-set min-one-of patches with [plabel = "P" and open? = true] [distance myself] houselocation) ;if they have don't enough money they select a park to spend their free time
      ]
    )
  ]
  if leisurelocation = nobody [ ;in case no leisure location is selected, then they stay home
    set leisurelocation houselocation
  ]
end

to goleisure ;this code makes people go to their leisure location and spend leisurelength (set to 1 hour) there
  ifelse
    (leisurecounter < leisurelength and [ open? ] of leisurelocation = true) [
      move leisurelocation
      if (patch-here = leisurelocation) [
        set leisurecounter leisurecounter + 1 ;this counter tracks how long they are at their leisurelocation
        if ([plabel] of patch-here = "G") [ ;if they are in a grocerystore, this adds restocked food to the fridge and subtracts the cost of the restock from savings
          ask houselocation [
            set food food + (fridgerestock * capacity) / leisurelength ;we divde by leisurelength since this code runs every minute and they only stay there for leisurelength (set to 1 hour)
            set savings savings - (fridgerestock * capacity * meal_cost_grocerystore) / leisurelength
          ]
        ]
        if ([plabel] of patch-here = "BR") [ ;if they are in a bar/restaurant, this adds 1 meal since they don't eat their food at home and subtracts the cost of the meal from savings
          ask houselocation [
            set food food + 1 / leisurelength
            set savings savings - (meal_cost_barrestaurant) / leisurelength
          ]
        ]
      ]
    ]
    [
      move houselocation
    ]
end

to joblocationopen ;this opens or closes the location of the workplace depending on whether there are workers there
  ask patches with [plabel != "P"] [
    ifelse any? turtles-here with [joblocation = myself]
    [
      set open? true
    ]
    [
      set open? false
    ]
  ]
end

to householdmealsrent
  if (ticks > 0 and ticks mod 1440 = 0) [
    ask patches with [plabel = "H"] [
      set food food - 3 * capacity ;3 meals are subtracted everyday to assume everyone eats 3 meals a day
      set savings savings - dailyrent ;rent is subtracted daily from savings
    ]
  ]
end

to infectionspread
  ask turtles [
    if (infectionlevel = "0) notinfected") and (patch-here = houselocation or patch-here = joblocation or patch-here = leisurelocation) and (any? turtles-here with [infectionlevel = "1) infected" or infectionlevel = "2) severe"]) [
      if random 10 < probability_transmission [
        set infectionlevel "1) infected" ;if someone is not infected and they are in the same house, workplace, or leisurelocation as someone with an infection, they get infected with a certain probability
      ]
    ]

    if infectionlevel = "1) infected" or infectionlevel = "2) severe" [ ;if someone is infected, this counter shows for how long they have been infected
      set infectedtime infectedtime + 1
    ]

    if infectedtime >= severity_time_days * 1440 and infectedtime < recovery_time_days * 1440 [ ;if someone is infected for more than the severity period, their condition becomes severe with a certain probability
      set infectionlevel (ifelse-value
        title = "1) retired" and severeprobability <= severe_infection_probability_retired [ "2) severe" ]
        member? title list-jobs and severeprobability <= severe_infection_probability_workingage [ "2) severe" ]
        title = "3) school student" and severeprobability <= severe_infection_probability_schoolage [ "2) severe" ]
        [infectionlevel])
    ]

    if infectedtime >= recovery_time_days * 1440 and infectionlevel != "2) severe" [ ;if someone is not severe, and they have been infected for longer than the recovery period, their condition recovers
      set infectionlevel "3) recovered"
    ]

    set color(ifelse-value ;this colors people by infection level
      infectionlevel = "1) infected" [18]
      infectionlevel = "2) severe" [15]
      infectionlevel = "3) recovered" [65]
      [black])

    if infectionlevel = "2) severe" [
      move one-of patches with [plabel = "+"]
    ]

   ]
end
@#$#@#$#@
GRAPHICS-WINDOW
65
41
655
632
-1
-1
17.64
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
0
ticks
30.0

BUTTON
666
435
755
468
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
666
473
755
506
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
0

TEXTBOX
30
10
642
47
MODEL OF HEALTH AND ECONOMIC IMPACTS OF COVID-19
20
0.0
1

SLIDER
44
689
247
722
percent_retired_65+
percent_retired_65+
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
44
732
246
765
percent_workingage_18-64
percent_workingage_18-64
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
44
776
247
809
percent_schoolage_under18
percent_schoolage_under18
0
100
25.0
1
1
NIL
HORIZONTAL

PLOT
993
13
1303
161
Population and Job Title
Titles
Frequency
0.0
25.0
0.0
30.0
true
true
"" "updatepopulationplot"
PENS

TEXTBOX
795
15
963
183
City Characteristics:\n-----------------------------------------40 Households\n100 People\n2 offices (O) in grey\n2 schools (S in orange\n5 parks (P) in green\n5 grocery stores (G) in blue\n5 bars/restaurants (BR)in purple\n1 hospital (+) in red\n
11
0.0
1

MONITOR
666
17
716
62
Day
day
17
1
11

MONITOR
716
17
766
62
Hour
hour
17
1
11

SLIDER
292
730
519
763
daily_salary_doctor_officeworker
daily_salary_doctor_officeworker
50
500
300.0
50
1
NIL
HORIZONTAL

SLIDER
292
773
519
806
daily_salary_teacher
daily_salary_teacher
50
500
150.0
50
1
NIL
HORIZONTAL

SLIDER
293
815
520
848
daily_salary_grocery_barworker
daily_salary_grocery_barworker
50
500
100.0
50
1
NIL
HORIZONTAL

SLIDER
293
856
520
889
daily_pension_retiree
daily_pension_retiree
50
500
200.0
50
1
NIL
HORIZONTAL

TEXTBOX
45
662
195
680
Demographic inputs:
12
0.0
1

TEXTBOX
294
662
444
680
Income inputs:
12
0.0
1

TEXTBOX
563
662
713
680
Health inputs:
12
0.0
1

SLIDER
292
897
520
930
starting_household_money
starting_household_money
0
500
300.0
50
1
NIL
HORIZONTAL

SLIDER
292
938
521
971
meal_cost_grocerystore
meal_cost_grocerystore
0
50
5.0
5
1
NIL
HORIZONTAL

SLIDER
291
977
522
1010
meal_cost_barrestaurant
meal_cost_barrestaurant
0
50
20.0
5
1
NIL
HORIZONTAL

SLIDER
290
1053
522
1086
house_rent_percent_of_hh_income
house_rent_percent_of_hh_income
0
50
30.0
5
1
NIL
HORIZONTAL

PLOT
783
175
1304
366
Household Money
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
"Total" 1.0 0 -16777216 true "" "plot sum [savings] of patches with [plabel = \"H\"]"
"With Bar Workers" 1.0 0 -7171555 true "" "plot sum [savings] of patches with [plabel = \"H\" and count turtles with [houselocation = myself and title = \"2) bar/restaurantworker\"] > 0]"

TEXTBOX
296
690
526
732
Model assumes that teachers and office workers can work from home
11
0.0
1

TEXTBOX
294
1020
495
1050
Rent is a percent of daily income and is subtracted from savings daily
11
0.0
1

SWITCH
666
395
756
428
new_city
new_city
1
1
-1000

SLIDER
557
814
809
847
severe_infection_probability_retired
severe_infection_probability_retired
0
100
30.0
5
1
NIL
HORIZONTAL

SLIDER
557
854
809
887
severe_infection_probability_workingage
severe_infection_probability_workingage
0
100
15.0
5
1
NIL
HORIZONTAL

SLIDER
558
892
810
925
severe_infection_probability_schoolage
severe_infection_probability_schoolage
0
100
10.0
5
1
NIL
HORIZONTAL

SWITCH
661
94
771
127
Outbreak
Outbreak
0
1
-1000

SWITCH
661
184
771
217
Close_school
Close_school
1
1
-1000

SWITCH
661
225
772
258
Close_bar
Close_bar
1
1
-1000

SWITCH
661
266
773
299
Lockdown
Lockdown
1
1
-1000

SWITCH
659
307
774
340
Test_Isolate
Test_Isolate
1
1
-1000

TEXTBOX
557
693
864
728
Slider values set based on this data:\nhttps://www.nejm.org/doi/full/10.1056/NEJMoa2002032eh
11
0.0
1

PLOT
784
385
1304
628
Infection Level of Population
NIL
NIL
0.0
20000.0
0.0
100.0
false
true
"" ""
PENS
"Infected" 1.0 0 -1069655 true "" "plot count turtles with [infectionlevel = \"1) infected\"]"
"Severe" 1.0 0 -2674135 true "" "plot count turtles with [infectionlevel = \"2) severe\"]"
"Recovered" 1.0 0 -13840069 true "" "plot count turtles with [infectionlevel = \"3) recovered\"]"

SLIDER
557
774
809
807
severity_time_days
severity_time_days
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
557
933
810
966
recovery_time_days
recovery_time_days
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
558
733
809
766
probability_transmission
probability_transmission
0
100
20.0
5
1
NIL
HORIZONTAL

TEXTBOX
669
161
819
179
Policy responses:
13
0.0
1

@#$#@#$#@
## HOW IT WORKS

This model tries to simulate the spread of the Coronavirus and the resulting health and economic impacts in a virtual city.

The model supposes 40 households (H) in a city and 100 people in these households. The ages of the people in the model are distributed by 1) retired age 65 or older, 2) working age 18-64, or 3) school age under 18 based on the demographic sliders. 

And each person is assigned to a household such that there is at least one legal adult above 18 years of age per household. To simplify the model, we suppose that people go to school until they are 18, work until they are 65, after which they retire and live until a maximum age of 90.

The model has 2 offices (O), 2 schools (S), 5 parks (P), 5 grocery stores (G), and 5 bars/restaurants (BR). And 1 hospital (+).

Normal working adults between 18 and 65 in the household go to work at one of these places from Monday to Friday from 7am to 3pm, while children go to school, and those who are above 65 stay at home or visit a park, a bar/restaurant, or a grocery store. After 3pm they have leisure time.

Grocery store workers and bar/restaurant workers have a day shift from 7am to 3pm and a night shift from 3pm to 11pm. While doctors have 3 shifts from 7am to 3pm, from 3pm to 11pm, and from 11pm to 7am to ensure 24/7 care. These workers also  work during the weekends.

Workers get paid a daily salary - determined by the sliders - which then goes to their household savings after each workday. Each household gets a certain amount of money at the start, which can be set in the income inputs. For simplicity, the income of businesses and business owners are not considered in this model.

All households start with 20 meals in their fridge and eat 3 meals a day. When not working, people first prioritize buying food if their fridge has less than 3 meals per person in the household. They will then go to the grocery store and restock their fridge with 5 meals per person in the household. The cost of the meals in the grocery store are set in the slider.

If they have enough savings (more than the money needed to restock their fridge), then they can go to a restaurant during their leisure time. Otherwise they usually go to a park to relax. During the weekends they repeat this decision during the day (7am-3pm) and the evening (3pm-11pm).

Households pay rent every day, which is scaled based on a percentage of the total household income. This percentage is set by the sliders.

Once the outbreak switch is toggled, three people at random get infected by the Coronavirus. Through contact with others at their house, their workplace, or their leisure location, they spread the virus with a certain probability of transmission set by the sliders - the model ignores incubation periods. 

After a certain number of days - set by the sliders in the health inputs section - the infected person gets admitted to the hospital if their disease becomes severe based on a probability dependent on their age.

And after a certain number of days set by the sliders if their infection isn't severe, they recover - this model does not take into account deaths from the virus.

There are various options to combat the virus, which can be chosen by the different switches:

Close schools
this shuts down schools, causing teachers and students to study from home.

Close bars
this shuts down bars, and the workers do not get paid and have a freeday.

Lockdown
this shuts down all workplaces except grocery stores and hospitals, so those who can work from home do so, while those who can't like bar and restaurant workers have a free day and do not get paid.

Test and Isolate
this provides testing kits to everyone and if they test positive, they choose to remain at home and work/study from home if they can.


## CREDITS AND REFERENCES

Shyaam Ramkumar, 2020. 
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 15000</exitCondition>
    <metric>sum [savings] of patches with [plabel = "H"]</metric>
    <metric>sum [savings] of patches with [plabel = "H" and count turtles with [houselocation = myself and title = "2) bar/restaurantworker"] &gt; 0]</metric>
    <metric>count turtles with [infectionlevel = "1) infected"]</metric>
    <metric>count turtles with [infectionlevel = "2) severe"]</metric>
    <metric>count turtles with [infectionlevel = "3) recovered"]</metric>
    <enumeratedValueSet variable="starting_household_money">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severe_infection_probability_retired">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal_cost_barrestaurant">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severity_time_days">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_city">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability_transmission">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal_cost_grocerystore">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="house_rent_percent_of_hh_income">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily_salary_teacher">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_schoolage_under18">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily_pension_retiree">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severe_infection_probability_schoolage">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_retired_65+">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Outbreak">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily_salary_doctor_officeworker">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="severe_infection_probability_workingage">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recovery_time_days">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent_workingage_18-64">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily_salary_grocery_barworker">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Close_school">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Close_bar">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Lockdown">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test_Isolate">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
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
