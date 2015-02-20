#data: 
#dir/features.txt   561 names of features
#dir/test/X_test.txt 2947x561 data with col for each var and 2947 observations
#dir/test/y_test.txt 2947 labels 1-6 for the activities 
#dir/test/subject_test.txt numbers 1-30 for the subjects 2947 long

#dir/test/X_train.txt 7352x561 data with col for each var and 7352 observations
#dir/test/y_train.txt 7352 labels 1-6 for the activities 
#dir/test/subject_train.txt numbers 1-30 for the subjects 7352 long

#Read in the 7 data files
features <- read.table("./UCI HAR Dataset/features.txt",stringsAsFactors = FALSE) #561 names

testData <- read.table("./UCI HAR Dataset/test/X_test.txt")#2947x561 data
testLabels <- read.table("./UCI HAR Dataset/test/y_test.txt")#2947 labels 1-6 for the activities
testSubjs <- read.table("./UCI HAR Dataset/test/subject_test.txt")#2947 numbers 1-30 for the subjects

trainData <- read.table("./UCI HAR Dataset/train/X_train.txt")#7352x561 data
trainLabels <- read.table("./UCI HAR Dataset/train/y_train.txt")#7352 labels 1-6 for the activities
trainSubjs <- read.table("./UCI HAR Dataset/train/subject_train.txt")#7352 numbers 1-30 for the subjects


#1) merge the three parts of train/test and merge the by putting then one on top of the other
train <- cbind(trainData,trainLabels,trainSubjs)
test <- cbind(testData,testLabels,testSubjs)
mrg <- rbind(train,test)

#assign colums names
varnames <- features[,2]#separate the feature names
colnames(mrg) <- c(varnames,"Activity.Label","Subject")

#2) Measurements of mean or standard deviation are recognized by having "mean()" or "std()" 
#Remove columns with names that do not have these markers.
keepInds <- c(grep("mean\\(\\)|std\\(\\)",varnames),562:563)#Keep last two columns
mrg2 <- mrg[,keepInds]#now has 68 columns: 66 measurements, activity and subjects
#Note that I deliberately did not incude the vectors:
#gravityMean,tBodyAccMean,tBodyAccJerkMean,tBodyGyroMean,tBodyGyroJerkMean
#Since they are a different type of mean than all the others, being calculated on the angle() variables.

#3) Replace the numbers 1-6 of activity labels with the labeld provided in the activity_labels.txt file.
act <- factor(mrg2$Activity.Label,labels = c("WALKING","WALKING_UPSTAIRS","WALKING_DOWNSTAIRS"
                                             ,"SITTING","STANDING","LAYING"))
mrg2$Activity.Label <- act
names(mrg2)[names(mrg2)=="Activity.Label"] <- "Activity"#rename column appropriately

#4) First, there are names where BodyBody appears by mistake instead of Body. Like fBodyBodyAccJerkMag-mean()
names(mrg2) <- sub("BodyBody","Body",names(mrg2))

#See CodeBook.md for the name transformation details
#Iterate over names and prepare new names
shortNames <- names(mrg2)
nlen = length(shortNames)
extendedNames = character(nlen)
for (ni in seq_along(shortNames)){
  name <- shortNames[ni]
  #Classify class
  if (grepl("-[X,Y,Z]",name)){
    class = 1
  }
  else if (grepl("Mag",name)){
    class = 2
  }
  else {
    class = 3 #last two names
  }
  
  #Prepare all substrings for explanation
  tf <- "time"
  if (sub(name,1,1)=="f"){
    tf <- "frequency"
  }
  bg <- "gravity"
  if (grepl("Body",name)){
    bg <- "body"
  }
  ag <- "angular"
  if (grepl("Acc",name)){
    ag <- "linear"
  }
  jk <- ""
  if (grepl("Jerk",name)){
    jk <- if (class==1) "derivative" else "derivative of"
    
  }
  ms <- "mean"
  if (grepl("std",name)){
    ms <- "standard-deviation"
  }
  coor <- "X"
  if (grepl("-Y",name)) {coor <-"Y"}
  if (grepl("-Z",name)) {coor <- "Z"}
  
  #Build the string
  if (class==1){
  newName <- paste(ms,"of",bg,ag,"acceleration",jk,"in",coor,"direction over",tf,sep=".")
  }
  if (class==2){
    newName <- paste(ms,"of the magnitude of",jk,bg,ag, "acceleration vector over",tf,sep=".")
  }
  if (class==3){
    newName <- name
  }
  extendedNames[ni]<-newName
}

names(mrg2) <-extendedNames

#Use ftable to get a good table of the data. Create the md and readme, push to github and submit.
#We will try to create a flat table with subjectxvar and this repeated 6 times per activity.
#change subject column to factor
mrg2$Subject <- as.factor(mrg2$Subject)
#Melt dataframe so it has four columns, value, variable, Subject, Activity.
library(reshape2)
names <- names(mrg2)
ids <- names[67:68]
measure <- names[1:66]
mrgmelt <- melt(mrg2,id = ids, measure.vars = measure)
#Xtabs will prepare a table of values with respect to Subject, Activity and the column name
xt <- xtabs(value~.,aggregate(value~.,mrgmelt,mean))
ft <- ftable(xt);
write.ftable(ft,file = "./tidy.txt")
