#!/bin/bash

##################################
#
# Submit a project as a sub-project of an umbrella project. 
# The default submission is done on the test server. 
# You have to add the -p option to force submission on the 
# production server.
#
# Example:
#
# bin/submit_project.sh PhyloAlps batch01
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
PRODUCTION="NO"
PUBLISH="NO"
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -p|--production) PRODUCTION="YES"
                     shift # past argument
                     ;;
    -u|--make-public) PUBLISH="YES"
                     shift # past argument
                     ;;
    # unknown option
    *) POSITIONAL+=("$1") # save it in an array for later
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

# Consider the first positional argument as the project name

UMBRELLA_NAME="$1"
PROJECT_NAME="$2"
PROJECT_DIR="${DATA_DIR}/${PROJECT_NAME}"

if [[ ! -d "${PROJECT_DIR}" ]] ; then
    echo "ERROR: the project directory doesn't exist you must create it first"
    echo "       using the command generate_project.sh ${PROJECT}"
    exit 1
fi

# Loads webin credential
webin_credentials

# Look for the XML file describing the project
PROJECT_XML=$(basename $(ls -1 ${PROJECT_DIR}/project*.xml  \
                             | grep -v '\.receipt\.xml$'))
PROJECT_AC=$(awk -F'.' '(NF==4) {print $3}' <<< "${PROJECT_XML}")

# Checks if the project file has an accession number
if [[ -z "${PROJECT_AC}" ]] ; then
    echo "This project has no Accession Number" 1>&2
    echo "It is submitted as a new project" 1>&2

    ACTION="${TEMPLATE_DIR}/submission.xml"
else
    echo "This project project has Accession Number : ${PROJECT_AC}" 1>&2
    if [[ "$PUBLISH" == "YES" ]] ; then
        echo "Makes the project public" 1>&2
        ACTION="$$.make_public.xml"
        sed "s/@@ACCESSION@@/${PROJECT_AC}/" \
            "${TEMPLATE_DIR}/make_public.xml" \
            > "$ACTION"
    else
        echo "Submitting as an update" 1>&2
        ACTION="${TEMPLATE_DIR}/update.xml"
    fi
fi 

echo "Umbrella $UMBRELLA Submitting account : $LOGIN"  1>&2

# Submit the new project of the update 
receipt=$(curl -u $LOGIN:$PASSWD \
        -F "SUBMISSION=@${ACTION}" \
        -F "PROJECT=@${PROJECT_DIR}/${PROJECT_XML}" \
        "${SERVER}/submit")

# Look for error in the submission
ERRORS=$(receipt_error_messages "$receipt")

# If errors occur print them and exit with the code 1
if [[ ! -z "${ERRORS}" ]] ; then
    echo "Some errors occur during the submission process" 1>&2
    echo "================================================" 1>&2
    echo "${ERRORS}" 1>&2
    receipt_info_messages "$receipt" 1>&2
    echo "================================================" 1>&2

    echo "${receipt}" > "${PROJECT_DIR}/project.${PROJECT_NAME}.error.receipt.xml"

    exit 1
fi

echo "Submission process was successful" 1>&2

if [[ "$PUBLISH" == "NO" ]] ; then

    # Extracts the Accession number from the receipt
    RETURN_AC=$(receipt_project_accession "$receipt")

    echo "Project got Accession number : ${RETURN_AC}" 1>&2
else
    if [[ "${PROJECT_AC}" != "*" ]] ; then
        RETURN_AC="${PROJECT_AC}"
    fi
fi

if [[ ! -z "${RETURN_AC}" ]] ; then
    # Upload the serveur version of the project file
    curl -u "$LOGIN:$PASSWD" \
        "${SERVER}/projects/${RETURN_AC}" > "${PROJECT_DIR}/project.${PROJECT_NAME}_$$.xml.tmp"

    mv "${PROJECT_DIR}/project.${PROJECT_NAME}_$$.xml.tmp" \
    "${PROJECT_DIR}/project.${PROJECT_NAME}.${RETURN_AC}.xml"

    echo "${receipt}" > "${PROJECT_DIR}/project.${PROJECT_NAME}.${RETURN_AC}.receipt.xml"
fi

#
# We now need for editing the umbrella project XML
# file to include the dependency to the newly submitted 
# project
#

UMBRELLA_XML=$(basename $(ls -1 ${DATA_DIR}/common/umbrella.${UMBRELLA_NAME}*.xml \
                             | grep -v '\.receipt\.xml$'))
UMBRELLA_AC=$(awk -F'\.' '(NF==4) {print $3}' <<< "${UMBRELLA_XML}")

echo "Using umbrella XML file :  ${UMBRELLA_XML}"  1>&2

if [[ -z "${UMBRELLA_AC}" ]] ; then
    echo "This umbrella project has no Accession Number" 1>&2
    echo "Don't forget to submit it as a new project" 1>&2
else
    echo "This umbrella project has Accession Number : ${UMBRELLA_AC}" 1>&2
fi 

#
# Adding the link to the new project in the umbrella
#

if xmllint --xpath "//PROJECT/RELATED_PROJECTS" \
           "${DATA_DIR}/common/${UMBRELLA_XML}" > /dev/null ; then 
    echo "Umbrella project have already declared related projects"  1>&2

    if xmllint --xpath "//PROJECT/RELATED_PROJECTS/RELATED_PROJECT/CHILD_PROJECT[@accession='${RETURN_AC}']" \
           "${DATA_DIR}/common/${UMBRELLA_XML}" > /dev/null ; then 

        echo "Umbrella project have already declared ${RETURN_AC} project"  1>&2

        exit 0
    else
        XML_PATCH="<RELATED_PROJECT>
                    <CHILD_PROJECT accession=\"${RETURN_AC}\"/>
                   </RELATED_PROJECT>"

        # Remove new lines characters
        XML_PATCH=$(tr '\n' ' ' <<< "$XML_PATCH" | sed 's/"/\\"/g')

        sed "s@<RELATED_PROJECTS>@<RELATED_PROJECTS>${XML_PATCH}@" \
            "${DATA_DIR}/common/${UMBRELLA_XML}" \
            | xmllint --format - \
            > "${DATA_DIR}/common/umbrella.${UMBRELLA_NAME}_$$.xml.tmp"

        mv "${DATA_DIR}/common/umbrella.${UMBRELLA_NAME}_$$.xml.tmp"\
        "${DATA_DIR}/common/${UMBRELLA_XML}"

    fi
else
    echo "This is the first related project declared for that umbrella"

    XML_PATCH="<RELATED_PROJECTS>
                 <RELATED_PROJECT>
                    <CHILD_PROJECT accession=\"${RETURN_AC}\"/>
                 </RELATED_PROJECT>
               </RELATED_PROJECTS>"

    # Remove new lines characters
    XML_PATCH=$(tr '\n' ' ' <<< "$XML_PATCH" | sed 's/"/\\"/g')

    sed "s@<UMBRELLA_PROJECT/>@<UMBRELLA_PROJECT/>${XML_PATCH}@" \
        "${DATA_DIR}/common/${UMBRELLA_XML}" \
        | xmllint --format - \
        > "${DATA_DIR}/common/umbrella.${UMBRELLA_NAME}_$$.xml.tmp"

    mv "${DATA_DIR}/common/umbrella.${UMBRELLA_NAME}_$$.xml.tmp" \
       "${DATA_DIR}/common/${UMBRELLA_XML}"
fi

echo "You must now run an update of the umbrella project" 1>&2
echo "Using command : submit_umbrella.sh ${UMBRELLA_NAME}" 1>&2