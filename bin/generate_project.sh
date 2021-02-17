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

# Build the project directory in the DATA_DIR

mkdir -p "${DATA_DIR}/${PROJECT_NAME}"

# Build the xml project file

${LIB_DIR}/process_template.awk -v ENTRY="${PROJECT_NAME}" \
           ${PROJECT_TEMPLATE} \
           ${PROJECT_DATA} \
           > "${DATA_DIR}/${PROJECT_NAME}/project.xml"


# If no XSD files are present then download them

if [ ! -f "${XSD_DIR}/xsd_version.txt" ] || [ ! -f "${XSD_FILE}" ] ; then
  rm -rf "${XSD_DIR}/xsd_version.txt"
  ${LIB_DIR}/update_xsd.sh
fi

valid_xml=$(xmllint --schema "${XSD_FILE}" \
                    "${DATA_DIR}/${PROJECT_NAME}/project.xml" \
                    > /dev/null && echo ok || echo bad)

if [[ "$valid_xml" == "bad" ]] ; then
  echo "** The produced XML file : ${DATA_DIR}/${PROJECT_NAME}/project.xml is not valid **" 1>&2
  cat "${DATA_DIR}/${PROJECT_NAME}/project.xml" 1>&2
  rm -f "${DATA_DIR}/${PROJECT_NAME}/project.xml"
fi
