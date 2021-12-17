#!/bin/bash

##################################
#
# Submit the run and experiment xml files. 
# The default submission is done on the test server. 
# You have to add the -p option to force submission on the 
# production server.
#
# Example:
#
# bin/submit_samples.sh PhyloAlps batch01
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

echo "DB_ID,EXPERIMENT_ENA_AC,RUN_ENA_AC" > ${PROJECT_DIR}/experiment_accession_list.tsv

# go through all sample files and upload them
for file in $(ls ${PROJECT_DIR}/experiment*.xml | grep -Ev 'experiment\..+\..+\.xml'); do
	SAMPLE_NAME=$(basename ${file%.*} | sed 's/^experiment\.//')
	echo "Processing sample : $SAMPLE_NAME"
	echo $file

	runfile=$(sed 's@/experiment\.@/run.@' <<< $file)

	# Checks if the experiment file has an accession number
	EXPERIMENT_AC=$(awk -F'\.' '{print $(NF-1)}' <<< $(echo ${file/.xml/.*.xml}))
	if [[ "$EXPERIMENT_AC" != '*' ]] ; then
		echo "The experiment has an Accession Number : ${EXPERIMENT_AC}" 1>&2
		if [[ "$PUBLISH" == "YES" ]] ; then
			echo "Makes the experiment public" 1>&2
			ACTION="$$.make_public.xml"
			sed "s/@@ACCESSION@@/${EXPERIMENT_AC}/" \
				"${TEMPLATE_DIR}/make_public.xml" \
				> "$ACTION"
		else
			echo "Submitting as an update" 1>&2
			ACTION="${TEMPLATE_DIR}/update.xml"
		fi
	else
		echo "The experiment has no Accession Number" 1>&2
		echo "It will be submitted as a new experiment" 1>&2
		ACTION="${TEMPLATE_DIR}/submission.xml"
	fi

	RUN_AC=$(awk -F'\.' '{print $(NF-1)}' <<< $(echo ${runfile/.xml/.*.xml}))
	# if [[ "$RUN_AC" != '*' ]] ; then

	# else

	# fi

	echo ${file}
	echo ${runfile}

	# Submit the sample of the update
	receipt=$(curl -u $LOGIN:$PASSWD \
        	-F "SUBMISSION=@${ACTION}" \
	        -F "EXPERIMENT=@${file}" \
	        -F "RUN=@${runfile}" \
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

	    echo "${receipt}" >> "${PROJECT_DIR}/project.${PROJECT_NAME}.sample.error.receipt.xml"

	    #exit 1

	fi

	echo "Submission of ${file} was successful" 1>&2

	if [[ "$PUBLISH" == "NO" ]] ; then

		# Extracts the Accession number from the receipt
		RETURN_AC=$(receipt_experiment_accession "$receipt")
		RETURN_RUN_AC=$(receipt_run_accession "$receipt")

		echo "Experiment got Accession number : ${RETURN_AC}" 1>&2
		echo "Run got Accession number : ${RETURN_RUN_AC}" 1>&2
	else
		if [[ "${EPERIMENT_AC}" != "*" ]] ; then
			RETURN_AC="${EPERIMENT_AC}"
		fi

		if [[ "${RUN_AC}" != "*" ]] ; then
			RETURN_AC="${RUN_AC}"
		fi


	fi

	if [[ ! -z "${RETURN_AC}" ]] ; then

		# Upload the serveur version of the project file
		curl -u "$LOGIN:$PASSWD" \
		"${SERVER}/experiments/${RETURN_AC}" > "${PROJECT_DIR}/experiment.${SAMPLE_NAME}_$$.xml.tmp"

		mv "${PROJECT_DIR}/experiment.${SAMPLE_NAME}_$$.xml.tmp" \
			"${PROJECT_DIR}/experiment.${SAMPLE_NAME}.${RETURN_AC}.xml"

		curl -u "$LOGIN:$PASSWD" \
		"${SERVER}/runs/${RETURN_RUN_AC}" > "${PROJECT_DIR}/run.${SAMPLE_NAME}_$$.xml.tmp"

		mv "${PROJECT_DIR}/run.${SAMPLE_NAME}_$$.xml.tmp" \
			"${PROJECT_DIR}/run.${SAMPLE_NAME}.${RETURN_RUN_AC}.xml"

		echo -e "${SAMPLE_NAME},${RETURN_AC},${RETURN_RUN_AC}" >> ${PROJECT_DIR}/experiment_accession_list.tsv
	fi

	echo "------------------------------------------------------------------" 1>&2
	echo  1>&2

done
