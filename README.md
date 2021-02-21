# COMP0016 2020/21 - Team 26

[![GitHub Super-Linter](https://github.com/UCLComputerScience/COMP0016_2020_21_Team26/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)

# NudgeMe

V2 of the CarerCare app.

This is built on Flutter's stable branch.

## Initial Requirements

- The system should be designed for a user between 13 and 99
- The target user is a person who wishes to share their wellbeing with others
- It should passively gather movement data from the pedometer and cross reference this against a self reported wellbeing score
- The wellbeing score will be gathered at 12 pm on a Sunday
- People will be nudged to share their wellbeing score as a pdf/jpeg is their score falls twice over any two week period. 
This will be facilitated.
- They will also be encouraged to do the same of there is no pedometer reading over two days. 
On a Monday each week they will be asked if they to share their average wellbeing score (in a locally differentially private manner) with a central wellbeing hub. 
This hub will request put requests in the same manner as the previous App

## API Docs

Endpoint to send wellbeing data: `https://comp0016.cyberchris.xyz/add-wellbeing-record`

- postCode: string e.g. TW6
- wellbeingScore: integer
- weeklySteps: integer
- errorRate: integer, this is abs(score-userScore), where score is our estimate of their score
- supportCode: String
- date_sent: string, 'yyyy-MM-dd'

### Example POST

Using curl:

``` sh
DATA='{"postCode":"TW5", "wellbeingScore":9, "weeklySteps":650, "errorRate":9, "supportCode":"GP", "date_sent":"2021-01-02"}'
curl -d $DATA -H 'Content-Type: application/json;charset=UTF-8' https://comp0016.cyberchris.xyz/add-wellbeing-record
```
