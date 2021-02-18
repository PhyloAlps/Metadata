#!/bin/bash


URL=$(printf "https://nominatim.openstreetmap.org/reverse?lat=%s&lon=%s&format=xml&zoom=10&accept-language=en" \
             $1 $2) 

curl $URL 2> /dev/null \
  | xmllint --format --xpath '//country/text()' -