# COMP0016 2020/21 - Team 26

# NudgeMe

V2 of the CarerCare app.

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

## Tentative API Docs

http://178.79.172.202:8080/androidData

- postCode: postcodeprefix e.g. TW6
- wellBeingScore: String that represents an integer
- weeklySteps: String that represents an integer
- weeklyCalls: String *Obsolete*
- errorRate: String that represents an integer, this is abs(score-userScore), where score is our estimate of their score
- supportCode: String
- date: LocalDate.now() as a string, deleting '-'. i.e. "ddmmyyyy"

### Example successful POST

Using curl:

``` sh
DATA='{"postCode":"TW5", "wellbeingScore":"9", "weeklySteps":"650", "weeklyCalls":"0", "errorRate":"200", "supportCode":"GP", "date":"08122020"}'
curl -d $DATA -H 'Content-Type: application/json;charset=UTF-8' http://178.79.172.202:8080/androidData
```
