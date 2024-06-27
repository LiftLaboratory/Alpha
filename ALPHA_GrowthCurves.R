# This file contains code that is used to process the raw data (output from plantCV) 

# Fill in the paths to the two input files
#*******************************************
plantCVfile = "/Path/To/PlantCV_Output_Salinity.csv"
sampleBarcodeFile = "/Path/To/Barcode_Sample_Map.csv"
#*******************************************

# The Main analysis is contained in the function below
# This code reads in the raw data files and processes them into growth curves
Analysis = function()
{
  salt_Csv = read.csv(file = plantCVfile,stringsAsFactors = F)
  salt_Raw = MatchCameras(salt_Csv)
  salt_GC = CreateGrowthCurves(salt_Raw)
  # filter out misread barcodes
  courseLenths = sapply(salt_GC,nrow)
  keep = which(courseLenths>=15)
  salt_GC = salt_GC[keep]

  # Read in the sample-to-barcode map
  sampleMap = read.csv(file = sampleBarcodeFile,stringsAsFactors = F)
  sampleMap = setNames(object = sampleMap$Sample_ID, nm = sampleMap$Unique_ID)

  # Use sample names for the growth curves instead of barcodes
  names(salt_GC) = sampleMap[names(salt_GC)]
}

# This function takes a dataframe made from a plantCV .csv file and returns a data.frame with top and side cameras match and in the same row
# returns (camera_top,timestamp_top,area,camera_side,Height,barcode,timestamp_Side)
MatchCameras<-function(csvDF)
{
  #dataObj<-read.table(file = inFile, sep=",", stringsAsFactors = F, header = T)
  dataObj = csvDF
  dataObj<-dataObj[order(dataObj$timestamp),]
  cam1<-dataObj[dataObj$camera==1,]
  cam2<-dataObj[dataObj$camera==2,]
  cam3<-dataObj[dataObj$camera==3,]
  cam4<-dataObj[dataObj$camera==4,]
  cam5<-dataObj[dataObj$camera==5,]
  cam6<-dataObj[dataObj$camera==6,]
  cam7<-dataObj[dataObj$camera==7,]
  cam8<-dataObj[dataObj$camera==8,]
  
  camList<-list(list(cam2,cam1),list(cam3,cam4), list(cam6,cam5),list(cam7,cam8))
  #print(str(camList))
  retDFs<-lapply(camList,function(x) MC2(x))
  
  retDF<-do.call(rbind,retDFs)
  return(retDF)
}
# This is a helper function for MatchCameras
MC2<-function(cam2Lst)
{
  topCam<-cam2Lst[[1]]
  sideCam<-cam2Lst[[2]]
  #print(sideCam[1:10,])
  #print(paste(dim(topCam),dim(sideCam)))
  # convert timestamps to posix vectors
  topTS<-as.POSIXct(x = topCam$timestamp, format = "%Y_%m_%d_%H:%M:%S")
  sideTS<-as.POSIXct(x = sideCam$timestamp, format = "%Y_%m_%d_%H:%M:%S")
  
  # align the two timestamp vectors
  matchLst<-MatchTimes(topTS,sideTS)
  print(length(matchLst[[1]][,2]))
  
  #print(matchLst[[1]][,2])
  #print(matchLst[[2]][,2])
  # index the matrices
  topCam<-topCam[matchLst[[1]][,2],]
  sideCam<-sideCam[matchLst[[2]][,2],]
  
  # pull out the required data c("timestamp", "area", "Height", "Barcode"))
  topCam<-topCam[,c("camera","timestamp","area")]
  sideCam<-sideCam[,c("camera","Height","Barcode","timestamp")]
  
  retDF<-cbind(topCam,sideCam)
  colnames(retDF)[7] = "timestamp_Side"
  return(retDF)
}

# This function matches up two vectors of posix timestamps. A match requires <= difVal (2) seconds difference in picture time
MatchTimes<-function(tsVec1,tsVec2,difVal=2)
{
  
  # attach indices to each one
  tsVec1<-cbind(tsVec1,1:length(tsVec1))
  tsVec2<-cbind(tsVec2,1:length(tsVec2))
  
  # find the shorter vector
  shortLen<-min(c(nrow(tsVec1),nrow(tsVec2)))
  # calculate the difference between all corresponding times
  tdif<-tsVec1[1:shortLen,1]-tsVec2[1:shortLen,1]
  #print(tdif)
  # find the first index that is more than 2 sec difference
  remInd<-which(abs(tdif)>difVal)
  
  # while unmatched pairs exist, keep cycling
  while(length(remInd)>0)
  {
  remInd<-remInd[1]
  #print(paste("Found Missmatch:",remInd))
  remVal<-tdif[remInd]
  if(remVal>0)
    tsVec2<-tsVec2[-remInd,]
  if(remVal<0)
    tsVec1<-tsVec1[-remInd,]
  
  shortLen<-min(c(nrow(tsVec1),nrow(tsVec2)))
  tdif<-tsVec1[1:shortLen,1]-tsVec2[1:shortLen,1]
  remInd<-which(abs(tdif)>difVal)
  }
  
  # one of the cameras has unmatched images at the end of the list
  if(nrow(tsVec1)!=nrow(tsVec2))
  {
    # find the shorter vector
    shortLen<-min(c(nrow(tsVec1),nrow(tsVec2)))
    # return the same length
    tsVec1 = tsVec1[1:shortLen,]
    tsVec2 = tsVec2[1:shortLen,]
  }
  return(list(tsVec1,tsVec2))
}

# This function creates a list of dataframes.
# Each dataframe contains area measurements for each detected barcode (sample)
CreateGrowthCurves <- function(matchedData)
{
  ret = tapply(1:nrow(matchedData), INDEX = matchedData$Barcode, function(x) matchedData[x,])
  retSort = lapply(ret,function(x) x[order(x$timestamp),c("timestamp","area","Height","Barcode")])
  return(retSort)
}
