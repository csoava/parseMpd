#!/bin/bash

#Gets a file via curl and saves the http response code, timestamp and url to log file. 
#Usufull for bulding up statistics
urlToGet=$1
headerFile=`echo ${urlToGet} | rev | cut -d"/" -f1 | rev`
curl -sD $headerFile $urlToGet > /dev/null
httpResponseCode=`cat ${headerFile} | grep HTTP | cut -d" " -f2`
rm -f $headerFile
currDate=`date +"%Y-%d-%m %T"`
echo $currDate $urlToGet $httpResponseCode >> dash.log
