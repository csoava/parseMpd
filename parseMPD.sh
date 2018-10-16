#!/bin/bash

dashManifestUrl=$1
dateTemp=0
while true
    do
    dateStart=`date +%s%3N`
    diffDate=$(( dateStart - dateTemp ))

    if [[ $(( dateStart - dateTemp )) -lt 1900 ]]; then
        diff=`echo "scale=1; (2000 - $diffDate) / 1000" | bc`
        sleep 0$diff
    fi

	dateTemp=`date +%s%3N`
    dashManifest=`curl -X GET -sL "${dashManifestUrl}" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.62 Safari/537.36"  | xmllint --format - | grep -v ContentProtection | grep -v "cenc:pssh" | grep -v "mspr:pro"`

    if [[ `echo "${dashManifest}" | grep "availabilityStartTime" | wc -c` -lt 3 ]]; then
        timestamp=`date +%s`
        echo "CRITICAL,Unable to read the MPD manifest file,$dashManifestUrl,${timestamp}" >> dash.log
    fi
        channelUri=`echo ${dashManifestUrl} | cut -d"/" -f1-6`
        channelIdWithSuff=`echo ${channelUri} | cut -d"/" -f6 | cut -d"." -f1`

    streamTypes=`echo "${dashManifest}" |xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection"  | xmllint --xpath "//Period/AdaptationSet/@mimeType" - | sed 's/ /\n/g' | cut -d"\"" -f2 | sed '/^\s*$/d' `
    while read streamType;
    do
       streamIds=`echo "${dashManifest}" |xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection"   | xmllint --format --xpath "//Period/AdaptationSet[@mimeType=\"${streamType}\"]/Representation/@id" - | sed -e "s/ /\n/g" | cut -d"\"" -f2 | sed '/^\s*$/d'`


       startNumber=`echo "${dashManifest}" | xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection" | xmllint --format --xpath "//Period/AdaptationSet[@mimeType=\"${streamType}\"]/SegmentTemplate/SegmentTimeline/S/@t" - | cut -d"\"" -f2`
       segDuration=`echo "${dashManifest}" | xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection" | xmllint --format --xpath "//Period/AdaptationSet[@mimeType=\"${streamType}\"]/SegmentTemplate/SegmentTimeline/S/@d" - | cut -d"\"" -f2`
       segsToEdge=`echo "${dashManifest}" | xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection" | xmllint --format --xpath "//Period/AdaptationSet[@mimeType=\"${streamType}\"]/SegmentTemplate/SegmentTimeline/S/@r" - | cut -d"\"" -f2`
       currentChunk=`echo "$segsToEdge * $segDuration + $startNumber" | bc`

       while read streamId;
       do
          if [[ `echo ${streamId} | grep "mode=trik" | wc -c` -gt 1 ]]; then
              continue
          fi
          segFullUrl="${channelUri}/dash/${channelIdWithSuff}-${streamId}-${currentChunk}.dash"
          tf=`echo  "${dashManifest}" |xmllint --format - |  grep -v "MPD\|MarlinContentId\|default_KID\|UTCTiming\|ContentProtection"   | xmllint --format --xpath "//Period/AdaptationSet[@mimeType=\"${streamType}\"]/Representation[@id=\"${streamId}\"]/@bandwidth" -| cut -d"\"" -f2 | sed '/^\s*$/d'`

           ./getFile.sh ${segFullUrl} &
       done<<<"${streamIds}"
    done<<<"${streamTypes}"
done
