---
title: "CodeBook"
author: "ishamor"
date: "Friday, February 20, 2015"
output: html_document
---

#DATA PROCESSING
##Merge the training and the test sets to create one data set
The data in our database is composed of 7 different files:

Files                     | Contents
------                    | ---------
dir/features.txt          |*561 names of features*
dir/test/X_test.txt       |*2947x561 data with col for each var and 2947 observations*
dir/test/y_test.txt       |*2947 labels 1-6 for the activities* 
dir/test/subject_test.txt |*numbers 1-30 for the subjects 2947 long*
dir/test/X_train.txt      |*7352x561 data with col for each var and 7352 observations*
dir/test/y_train.txt      |*7352 labels 1-6 for the activities*
dir/test/subject_train.txt|*numbers 1-30 for the subjects 7352 long*

I first read in the 7 files.
Then I merge the 3 files from the training set into a 2947x563 data-frame, by appending the `subject_test` and `y_test` columns to the `X_test` column.
I similarly merge the 3 files from the test set into a 7352x563 data-frame.
I then stack the two data-frames to a single frame **mrg** 10299x563:
```
features <- read.table("./UCI HAR Dataset/features.txt",stringsAsFactors = FALSE) #561 names

testData <- read.table("./UCI HAR Dataset/test/X_test.txt")#2947x561 data
testLabels <- read.table("./UCI HAR Dataset/test/y_test.txt")#2947 labels 1-6 for the activities
testSubjs <- read.table("./UCI HAR Dataset/test/subject_test.txt")#2947 numbers 1-30 for the subjects

trainData <- read.table("./UCI HAR Dataset/train/X_train.txt")#7352x561 data
trainLabels <- read.table("./UCI HAR Dataset/train/y_train.txt")#7352 labels 1-6 for the activities
trainSubjs <- read.table("./UCI HAR Dataset/train/subject_train.txt")#7352 numbers 1-30 for the subjects

#merge the three parts of train/test and merge the by putting then one on top of the other
train <- cbind(trainData,trainLabels,trainSubjs)
test <- cbind(testData,testLabels,testSubjs)
mrg <- rbind(train,test)
```

To assign names to the columns I read in the `features.txt` file which contains the original names, into a character array. I then append two more names like this:
```
features <- read.table("./UCI HAR Dataset/features.txt",stringsAsFactors = FALSE)
varnames <- features[,2]#subset the names from the table
colnames(mrg) <- c(varnames,"Activity.Label","Subject")
```

##Extract only the measurements on the mean and standard deviation
Names of measurements of mean or standard deviation are recognized by having "mean()" or "std()" in them. I then remove columns with names that do not have these markers and name the new data-frame **mrg2**
```
keepInds <- c(grep("mean\\(\\)|std\\(\\)",varnames),562:563)#Keep last two columns
mrg2 <- mrg[,keepInds]#now has 68 columns: 66 measurements, activity and subjects
```
Note that I deliberately did not incude the measurements:
gravityMean, tBodyAccMean, tBodyAccJerkMean, tBodyGyroMean, tBodyGyroJerkMean
Since they are a different type of mean than all the others, being calculated on the angle() variables.
Including the "Subject" and "Activity" columns we are not left with 68 columns.

##Using descriptive activity
I replace the 1-6 levels of activity with the labels provided in the `activity_labels.txt` file.
```
act <- factor(mrg2$Activity.Label,labels = c("WALKING","WALKING_UPSTAIRS","WALKING_DOWNSTAIRS","SITTING","STANDING","LAYING"))
mrg2$Activity.Label <- act
names(mrg2)[names(mrg2)=="Activity.Label"] <- "Activity"#rename column appropriately
```
##Appropriately labelling the data set with descriptive variable names
First, there are variable names where BodyBody appears by mistake instead of Body. Like fBodyBodyAccJerkMag-mean(). I will fix this:
```
names(mrg2) <- sub("BodyBody","Body",names(mrg2))
```
The following shows the automatic transformation on the names. The 66 column names are broken up into tokens which are then rearranged to form a meaningful sentance. {t/f} means that either the string "t" or the string "f" can appear in the name. On the right side then  {time/frequency} means that the new name will include "time" or "frequency" accordingly.
The trasformation:

1. {t/f}{Body/Gravity}{Acc/Gyro}{Jerk}-{mean/std}()-{X/Y/Z} --> \
{mean/standard-deviation} of {body/gravity} {linear/angular} acceleration {derivative} in {X/Y/Z} direction over {time/frequency}
2. {t/f}{Body/Gravity}{Acc/Gyro}{Jerk}Mag-{mean/std}() --> \
{mean/standard-deviation} of the magnitude of {derivative of}{body/gravity} {linear/angular} acceleration vector over {time/frequency}

Algorithm in pseudo-code (for the actual code and comments see `run_analysis.R`)
First classify which of the cases:
```
if has -[X|Y|Z] case <- 1
else case  <- 2
```

Then create a series of string variables set according to what you find in the string:
```
first letter 't' or 'f'? tf <- "time" or "frequency"
contains Body or Gravity? bg <- "body" or "gravity"
contains Acc or Gyro? ag <- "linear" or "angular"
contains Jerk? jk <- "derivative" or "" ["derivative of" if case==2)]
contains mean() or std()? ms <- "mean" or "standard-deviation"
contains X or Y or Z? coor <- "X" or "Y" or "Z"
```

Each case is then translated as:

- case1:
    + "`ms` of `bg` `ag` acceleration `jk` in `coor` direction over `tf`"
  
- case2
    + "`ms` of the magnitude of `jk` `bg` `ag` acceleration vector over `tf`"

##Create tidy data set
We will create a flat table with blocks of mean value of variable per subject and this will be repeated 6 times per activity.
```
#change subject column to factor
mrg2$Subject <- as.factor(mrg2$Subject)
#Melt dataframe so it has four columns, value, variable, Subject, Activity.
library(reshape2)
names <- names(mrg2)
ids <- names[67:68]
measure <- names[1:66]
mrgmelt <- melt(mrg2,id = ids, measure.vars = measure)
#Xtabs will prepare a table of values with respect to Subject, Activity and the column name
#The aggregate function will compute the mean on each cross tabulation
xt <- xtabs(value~.,aggregate(value~.,mrgmelt,mean))
ft <- ftable(xt);
write.ftable(ft,file = "./tidy.txt")
```
#Variable Code Book
Here is a list of the original variabe names followd by the final dataset names. The new names are self-explanatory.

**tBodyAcc-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.X.direction over.time\
**tBodyAcc-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.Y.direction over.time\
**tBodyAcc-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.Z.direction over.time\
**tBodyAcc-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.X.direction over.time\
**tBodyAcc-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.Y.direction over.time\
**tBodyAcc-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.Z.direction over.time\
**tGravityAcc-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.gravity.linear.acceleration..in.X.direction over.time\
**tGravityAcc-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.gravity.linear.acceleration..in.Y.direction over.time\
**tGravityAcc-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.gravity.linear.acceleration..in.Z.direction over.time\
**tGravityAcc-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.gravity.linear.acceleration..in.X.direction over.time\
**tGravityAcc-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.gravity.linear.acceleration..in.Y.direction over.time\
**tGravityAcc-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.gravity.linear.acceleration..in.Z.direction over.time\
**tBodyAccJerk-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.X.direction over.time\
**tBodyAccJerk-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.Y.direction over.time\
**tBodyAccJerk-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.Z.direction over.time\
**tBodyAccJerk-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.X.direction over.time\
**tBodyAccJerk-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.Y.direction over.time\
**tBodyAccJerk-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.Z.direction over.time\
**tBodyGyro-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.X.direction over.time\
**tBodyGyro-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.Y.direction over.time\
**tBodyGyro-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.Z.direction over.time\
**tBodyGyro-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.X.direction over.time\
**tBodyGyro-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.Y.direction over.time\
**tBodyGyro-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.Z.direction over.time\
**tBodyGyroJerk-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration.derivative.in.X.direction over.time\
**tBodyGyroJerk-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration.derivative.in.Y.direction over.time\
**tBodyGyroJerk-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration.derivative.in.Z.direction over.time\
**tBodyGyroJerk-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration.derivative.in.X.direction over.time\
**tBodyGyroJerk-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration.derivative.in.Y.direction over.time\
**tBodyGyroJerk-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration.derivative.in.Z.direction over.time\
**tBodyAccMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of..body.linear.acceleration vector over.time\
**tBodyAccMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of..body.linear.acceleration vector over.time\
**tGravityAccMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of..gravity.linear.acceleration vector over.time\
**tGravityAccMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of..gravity.linear.acceleration vector over.time\
**tBodyAccJerkMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of.derivative of.body.linear.acceleration vector over.time\
**tBodyAccJerkMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of.derivative of.body.linear.acceleration vector over.time\
**tBodyGyroMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of..body.angular.acceleration vector over.time\
**tBodyGyroMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of..body.angular.acceleration vector over.time\
**tBodyGyroJerkMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of.derivative of.body.angular.acceleration vector over.time\
**tBodyGyroJerkMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of.derivative of.body.angular.acceleration vector over.time\
**fBodyAcc-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.X.direction over.time\
**fBodyAcc-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.Y.direction over.time\
**fBodyAcc-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration..in.Z.direction over.time\
**fBodyAcc-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.X.direction over.time\
**fBodyAcc-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.Y.direction over.time\
**fBodyAcc-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration..in.Z.direction over.time\
**fBodyAccJerk-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.X.direction over.time\
**fBodyAccJerk-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.Y.direction over.time\
**fBodyAccJerk-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.linear.acceleration.derivative.in.Z.direction over.time\
**fBodyAccJerk-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.X.direction over.time\
**fBodyAccJerk-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.Y.direction over.time\
**fBodyAccJerk-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.linear.acceleration.derivative.in.Z.direction over.time\
**fBodyGyro-mean()-X**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.X.direction over.time\
**fBodyGyro-mean()-Y**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.Y.direction over.time\
**fBodyGyro-mean()-Z**&nbsp;&nbsp;&nbsp;&nbsp; mean.of.body.angular.acceleration..in.Z.direction over.time\
**fBodyGyro-std()-X**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.X.direction over.time\
**fBodyGyro-std()-Y**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.Y.direction over.time\
**fBodyGyro-std()-Z**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of.body.angular.acceleration..in.Z.direction over.time\
**fBodyAccMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of..body.linear.acceleration vector over.time\
**fBodyAccMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of..body.linear.acceleration vector over.time\
**fBodyBodyAccJerkMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of.derivative of.body.linear.acceleration vector over.time\
**fBodyBodyAccJerkMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of.derivative of.body.linear.acceleration vector over.time\
**fBodyBodyGyroMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of..body.angular.acceleration vector over.time\
**fBodyBodyGyroMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of..body.angular.acceleration vector over.time\
**fBodyBodyGyroJerkMag-mean()**&nbsp;&nbsp;&nbsp;&nbsp; mean.of the magnitude of.derivative of.body.angular.acceleration vector over.time\
**fBodyBodyGyroJerkMag-std()**&nbsp;&nbsp;&nbsp;&nbsp; standard-deviation.of the magnitude of.derivative of.body.angular.acceleration vector over.time\
\
And the two new columns:\
**Activity** &nbsp;&nbsp;&nbsp;&nbsp; the type of activity performed while the measurements were taken\
**Subject**&nbsp;&nbsp;&nbsp;&nbsp; A number between 1-30 depicting a subject from the study group.