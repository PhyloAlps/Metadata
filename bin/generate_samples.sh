#!/bin/bash

##################################
#
# The generate_project.sh script allows for creating
# or modifying a project directory. It takes in charge
# the creation of the project subdirectory in the data
# directory and update or create the project.xml file
# according to the data contained in the data/projects.csv 
# file. The script accepts a single argument, the name of the
# subproject. That name must be identical to the name of the project
# declared in the first column of the csv file.
#
# Example:
#
# bin/generate_project.sh batch01
#
##################################


# This command allows for identifying the directory
# where the scripts are stored. Later on every paths
# will be setup relatively to that one
THIS_DIR="$(dirname ${BASH_SOURCE[0]})"

# This one is for loading a bash script containing every function
# common to every bash scripts

. "$THIS_DIR/../lib/bashlib.sh"

#########################################
#
# Here start the actual script code
#
#########################################

PROJECT_NAME=$1

SAMPLE_TEMPLATE="${TEMPLATE_DIR}/sample.xml"
SAMPLE_DATA="${CSV_DIR}/TestMetadata.csv"


# The XSD file correponding to a project
XSD_FILE="${XSD_DIR}/SRA.sample.xsd"



if [[ ! -d "${DATA_DIR}/${PROJECT_NAME}" ]] ; then
    echo "The folder corresponding to the project doesn't exist" 1>&2
    echo "Create it first by running the command :" 1>&2
    echo "   generate_project.sh ${PROJECT_NAME}"  1>&2
    exit 1
fi

PROJECT_XML=$(basename $(ls -1 ${DATA_DIR}/${PROJECT_NAME}/project*.xml \
                             | grep -v '\.receipt\.xml$'))
PROJECT_AC=$(awk -F':' '{print $2}' <<< "${PROJECT_XML/.xml/}")

if [[ -z "PROJECT_XML" ]]  ; then
    echo "The folder corresponding to the project doesn't contain project file" 1>&2
    echo "Create it first by running the command :" 1>&2
    echo "   generate_project.sh ${PROJECT_NAME}"  1>&2
    exit 1
fi

if [[ -z "${PROJECT_AC}" ]] ; then
    echo "The ${PROJECT_NAME} project has no Accession Number" 1>&2
    echo "Do not forget to submit it as a new project" 1>&2
else
    echo "The ${PROJECT_NAME} project has Accession Number : ${PROJECT_AC}" 1>&2
fi 

# Build the xml sample files

pushd "${DATA_DIR}/${PROJECT_NAME}"

for filename in $(${LIB_DIR}/process_template.awk -v ENTRY="${PROJECT_NAME}" \
                    ${SAMPLE_TEMPLATE} \
                    ${SAMPLE_DATA} \
                    | awk '($1=="<!--") {filename=$2;        \
                                         print filename}     \
                                                             \
                           ($1!="<!--") {print $0 > filename}\
                          ') ; do 
   
   lat=$(xmllint --xpath '//SAMPLE_ATTRIBUTE/TAG[text()="geographic location (latitude)"]/../VALUE/text()' \
         "${filename}")
   lon=$(xmllint --xpath '//SAMPLE_ATTRIBUTE/TAG[text()="geographic location (longitude)"]/../VALUE/text()' \
         "${filename}")
   country=$(${LIB_DIR}/geocoding_country.sh $lat $lon)

    if [[ ! -z "$country" ]] ; then 
        awk -v country="$country" \
            '{gsub("@@Sampling_country@@",country,$0); print $0}' \
            "${filename}" \
            > "${filename}_$$.tmp"
        mv "${filename}_$$.tmp" "${filename}"
    fi
    
   echo "$filename ($lat,$lon) is in $country" 1>&2
done

popd

exit 0

# If no XSD files are present then download them

if [ ! -f "${XSD_DIR}/xsd_version.txt" ] || [ ! -f "${XSD_FILE}" ] ; then
  rm -rf "${XSD_DIR}/xsd_version.txt"
  ${LIB_DIR}/update_xsd.sh
fi

valid_xml=$(xmllint --schema "${XSD_FILE}" \
                    "${DATA_DIR}/${PROJECT_NAME}/sample.xml" \
                    > /dev/null && echo ok || echo bad)

if [[ "$valid_xml" == "bad" ]] ; then
  echo "** The produced XML file : ${DATA_DIR}/${PROJECT_NAME}/project.xml is not valid **" 1>&2
  cat "${DATA_DIR}/${PROJECT_NAME}/project.xml" 1>&2
  rm -f "${DATA_DIR}/${PROJECT_NAME}/project.xml"
fi
