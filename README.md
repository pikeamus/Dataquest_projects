# Dataquest_projects
Notebooks from selected Dataquest guided projects, with some additional workings. Listed in order of advancement through the dataquest datascience path.

## NYC schools - 
Uses Requests library to get json data from some APIs, about New York city schools and their SAT results/demographics. Processes the datasets using pandas and combines them into a single dataset for further analysis. Some initial visual data discovery of correlations. Requires basemap library for one step. 

## Analysis of Jeopardy questions - 
Uses pandas, some string maniulation and data cleaning, and a chisquared test to look for study tips for winning Jeopardy. In particular we look at word recurrances in strings, and whether given words correlate with high value questions.

## Car Price Prediction - 
Uses the k-nearest neighbours machine learning algorithm to predict car prices from numeric features (like horsepower or fuel efficiency). Includes some preliminary data cleaning. Now updated to include cross validation (using the scikit-learn cross validator) to generate improved error metrics.

## House Price Prediction - WIP
Example of using linear regression modelling to predict sale prices of houses. Demonstrates feature transformation (creating dummies for nominals, dealing with nulls, mapping ordinal strings), feature selection and using cross validation for generating error metrics.
WIP status: About 75% complete, perhaps more. Now achieving an average root mean squared error below 30k when cross validating the train set. Haven't yet tested on the clean test set.
