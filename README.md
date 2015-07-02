# Kaggle EMCL/PKDD 15: Taxi Trajectory and Trip Time

## Introduction
Kaggle hosted two competitions based on partial taxi trajectories in Porto, Portugal.  The first competition is to predict the [final destination](https://www.kaggle.com/c/pkdd-15-predict-taxi-service-trajectory-i) and the second is to forecast the total [trip duration](https://www.kaggle.com/c/pkdd-15-taxi-trip-time-prediction-ii).  The trip duration can be calculated as 15 seconds * number of GPS readings.  While the train data contains over a million trips gathered in one year, the test set consists of active trips at specific times on 5 different days.  The small test size of 320 trips means possible large leaderboard swings.  So I decided to just do a simple solution without any cross validation, tuning, machine learning, statistics, outlier detection, blending, etc.

Found a bug while cleaning up the code.  It would have ranked 45/381 and 22/345 in the two competitions.

## Algorithm
The idea is to look up similar trajectories based on 2 points.  One point is the starting location.  The other is the GPS location closest to where the test trajectory was cut.  Instead of looking at the whole polyline, we limit ourselves to the positions after the trip duration time has elapsed.

In addition, the trips available for matching is limited by the type of trip.  For example, one of the cutoff times in the test set is for morning commutes.  Another cutoff time is the Sunday afternoon before a public holiday.

## Similarity Features
* Haversine distance between the train and trip trajectories at the starting location
* Haversine distance between the train and trip trajectories at the cutoff location
* Angle between the overall bearing
* Angle between the last bearing

## Dependencies
* R version 3.1+
* R packages
  * data.table

## Run
Requires unzipped train.csv and test.csv.  Run util.R -> read_data.R -> lookup.R
