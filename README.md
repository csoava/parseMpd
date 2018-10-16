# parseMpd
Bash script to parse MPD and check all referenced dash segments.

The scope of these scripts is to monitor DASH Live Streaming on a minimal level.
 - Check if the MDP file is downloadable
 - Parse the MDP file;
 - Check if the dash referenced segments are downloadable.
 
 <h3>Prerequisites </h3>
 - bc (Linux bc - An arbitrary precision calculator language) </bc>
 - xmllint compiled with xpath
 
