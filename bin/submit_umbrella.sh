#!/bin/bash

##################################
#
# Submit the umbrella project. The default submission
# is done on the test server. you have to add the -p
# option to force submission on the production server.
#
# Example:
#
# bin/submit_umbrella.sh
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

TEST_SERVER="https://wwwdev.ebi.ac.uk/ena/submit/drop-box"
PROD_SERVER="https://www.ebi.ac.uk/ena/submit/drop-box"


#
# Looks at the option on the commande line for the 
# -p or --production option
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

PRODUCTION="NO"

case $key in
    -p|--production)
    PRODUCTION="YES"
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#
# Selects the submission server according to the -p option
#

if [[ "${PRODUCTION}" == "YES" ]] ; then
    echo "BE CAREFUL : This is a true submission" 1>&2
    SERVER="$PROD_SERVER"
else
    echo "That submission is done on the test server"
    SERVER="$TEST_SERVER"
fi

# Loads webin credential
webin_credentials

UMBRELLA_XML=$(basename $(ls -1 ${DATA_DIR}/common/umbrella*.xml \
                             | grep -v '\.receipt\.xml$'))
UMBRELLA_AC=$(awk -F':' '{print $2}' <<< "${UMBRELLA_XML/.xml/}")

echo "Using umbrella XML file :  ${UMBRELLA_XML}"  1>&2

if [[ -z "${UMBRELLA_AC}" ]] ; then
    echo "This umbrella project has no Accession Number" 1>&2
    echo "It is submitted as a new project" 1>&2

    ACTION="${TEMPLATE_DIR}/submission.xml"
else
    echo "This umbrella project has Accession Number : ${UMBRELLA_AC}" 1>&2
    echo "We are submitting an update" 1>&2

    ACTION="${TEMPLATE_DIR}/update.xml"
fi 

receipt=$(curl -u $LOGIN:$PASSWD \
        -F "SUBMISSION=@${ACTION}" \
        -F "PROJECT=@${DATA_DIR}/common/${UMBRELLA_XML}" \
        "${SERVER}/submit")

ERRORS=$(receipt_error_messages "$receipt")

if [[ ! -z "${ERRORS}" ]] ; then
    echo "Some errors occur during the submission process" 1>&2
    echo "================================================" 1>&2
    echo "${ERRORS}" 1>&2
    receipt_info_messages "$receipt" 1>&2
    echo "================================================" 1>&2
    exit 1
fi

echo "Submission process was successful" 1>&2

RETURN_AC=$(receipt_project_accession "$receipt")

echo "Project got Accession number : ${RETURN_AC}" 1>&2

curl -u "$LOGIN:$PASSWD" \
     "${SERVER}/projects/${RETURN_AC}" > "${DATA_DIR}/common/umbrella_tmp_$$.xml"

rm -f "${DATA_DIR}/common/${UMBRELLA_XML}"
mv "${DATA_DIR}/common/umbrella_tmp_$$.xml" \
   "${DATA_DIR}/common/umbrella:${RETURN_AC}.xml"

echo "${receipt}" > "${DATA_DIR}/common/umbrella:${RETURN_AC}.receipt.xml"

