---
layout: post
title: Development Update 1
---

# Chris

I've defined an initial model for the data that relates to the user,
this is essentially their postcode and a list of wellbeing records.
Each record represents a week and holds the number of steps and the score.

I've also added a 
[graph](https://github.com/UCLComputerScience/COMP0016_2020_21_Team26/pull/15)
that displays the last 5 weeks to the wellbeing page.
Something to note was that we wanted to cross-reference the steps with the
reported score, but clearly if we used the same axis the steps would
be way higher (thousands of steps a week vs. a score between 1-10).
So I came up with a simple normalization trick that converts the number of
steps to a score that represents how healthy that number is, using
70,000 as the recommended number of steps per week.

# Next Week's Task

Here are some possible tasks to start next week:

- Post to the API every monday
- Integrate pedometer

# Saachi
During the last two weeks, I have worked on the checkup screen. This involved becoming familiar with the fit-kit Flutter package. The structure of the page currently is a scale from 1-10 for users to input wellbeing and displaying the number of steps the user has done in the last 7 days. I haven’t quite figured out how to make this a popup screen yet. I still need to test this page.

Before this, I also worked on implementing the weekly notification that requests people to report their wellbeing but decided to pause this and work on the checkup screen first as it was difficult to test without a page to put it in. For this, I used the flutter-local-notifications package. The package is not supposed to work for scheduled weekly notifications, so I will have to test this works. will resume working on this after finishing the checkup screen page. 

# Next Week's Task
- Complete the checkup page
- Test both the checkup page and the notification
- Start another page.
