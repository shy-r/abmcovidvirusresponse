# Simulation Model of the Health and Economic Trade-offs in Responses to Covid-19 Type Viruses
This Netlogo model tries to simulate the spread of the viruses like Covid-19 and the resulting health and economic impacts in a virtual city.

The model supposes 40 households (H) in a city and 100 people in these households. The ages of the people in the model are distributed by 1) retired age 65 or older, 2) working age 18-64, or 3) school age under 18 based on the demographic sliders.
And each person is assigned to a household such that there is at least one legal adult above 18 years of age per household. To simplify the model, we suppose that people go to school until they are 18, work until they are 65, after which they retire and live until a maximum age of 90.

The model has 2 offices (O), 2 schools (S), 5 parks (P), 5 grocery stores (G), and 5 bars/restaurants (BR). And 1 hospital (+).
Normal working adults between 18 and 65 in the household go to work at one of these places from Monday to Friday from 7am to 3pm, while children go to school, and those who are above 65 stay at home or visit a park, a bar/restaurant, or a grocery store. After 3pm they have leisure time. The distribution of people by job title is shown in the barplot on the top right corner of the model.

Grocery store workers and bar/restaurant workers have a day shift from 7am to 3pm and a night shift from 3pm to 11pm. While doctors have 3 shifts from 7am to 3pm, from 3pm to 11pm, and from 11pm to 7am to ensure 24/7 care. These workers also work during the weekends.
Workers get paid a daily salary - determined by the sliders - which then goes to their household savings after each workday. Each household gets a certain amount of money at the start, which can be set in the income inputs. For simplicity, the income of businesses and business owners are not considered in this model.

All households start with 20 meals in their fridge and eat 3 meals a day. When not working, people first prioritize buying food if their fridge has less than 3 meals per person in the household. They will then go to the grocery store and restock their fridge with 5 meals per person in the household. The cost of the meals in the grocery store are set in the slider.

If they have enough savings (more than the money needed to restock their fridge), then they can go to a restaurant during their leisure time. Otherwise they usually go to a park to relax. During the weekends they repeat this decision during the day (7am-3pm) and the evening (3pm-11pm).

Households pay rent every day, which is scaled based on a percentage of the total household income. This percentage is set by the sliders.

Once the outbreak switch is toggled, three people at random get infected by a virus like the Coronavirus. Through contact with others at their house, their workplace, or their leisure location, they spread the virus with a certain probability of transmission set by the sliders - the model ignores incubation periods.

After a certain number of days - set by the sliders in the health inputs section - the infected person gets admitted to the hospital if their disease becomes severe based on a probability dependent on their age.
And after a certain number of days set by the sliders if their infection isn’t severe, they recover - this model does not take into account deaths from the virus.

There are various options to combat the virus, which can be chosen by the different switches:

Close schools:
this shuts down schools, causing teachers and students to study from home.

Close bars:
this shuts down bars, and the workers do not get paid and have a freeday.

Lockdown:
this shuts down all workplaces except grocery stores and hospitals, so those who can work from home do so, while those who can’t like bar and restaurant workers have a free day and do not get paid.

Test and Isolate:
this provides testing kits to everyone and if they test positive, they choose to remain at home and work/study from home if they can.

When running simulations, there is a set random-seed that is specified so that results from the different options can be compared. This random seed can be changed in the code. If you want to generate a new random city every time, turn on the new_city switch.

As the simulation runs, the total money of all households and the money of households with bar and restaurant workers is displayed in one of the plots. Another plot shows the number of people who are infected, severely infected, and recovered.

The counter for the simulation and the x-axis for the plots is in minutes. This is converted to hours and days and displayed in the monitors in the top-center of the model.
