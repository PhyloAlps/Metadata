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
# bin/generate_runs.sh projects batch01
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

export LANG=C

GENOSCOPE_SEQUENCER="Illumina HiSeq 2500"
FASTERIS_SEQUENCER="Illumina HiSeq 2500"
BGI_SEQUENCER="Illumina HiSeq 2000"

PROJECT_NAME=$1
BATCH_NAME=$2

EXPERIMENT_TEMPLATE="${TEMPLATE_DIR}/experiment.xml"
RUN_TEMPLATE="${TEMPLATE_DIR}/run.xml"

# The XSD file correponding to a project
EXPERIMENT_XSD_FILE="${XSD_DIR}/SRA.experiment.xsd"
RUN_XSD_FILE="${XSD_DIR}/SRA.run.xsd"

#SAMPLE_DATA="${CSV_DIR}/libraries_orthoskim_PhyloAlps_FINAL.csv"
SAMPLE_DATA="${CSV_DIR}/PHYLOALPS_HERBARIUM_61_29nov2021.csv"
#SAMPLE_DATA="${CSV_DIR}/test.csv"

function db_field {
    local field=$2
    local file=$1
    head -1 ${file} | \
        awk -v FIELD=${field} '
            BEGIN {RS=","} 
            ($0==FIELD) {print NR}'
}

function select_batch {
    local batch=$1
    local field=$(db_field ${SAMPLE_DATA} "Submission_Batch_Name")

    head -1 ${SAMPLE_DATA}

    tail -n +1 ${SAMPLE_DATA} | \
    awk -F ',' \
        -v field=$field \
        -v batch="$batch" \
        '(tolower($field) ~ tolower(batch)) {print $0}' | \
    sort -t ',' -k
}

function join_csv {
    local field1=$1
    local field2=$2
    local file1=$3
    local file2=$4


    head -1 $file1 > /tmp/$$.__temp_join__1.txt
    head -1 $file2 > /tmp/$$.__temp_join__2.txt

    join -t, -1 $field1 -2 $field2 \
        /tmp/$$.__temp_join__1.txt \
        /tmp/$$.__temp_join__2.txt

    tail -n +2 $file1 | \
        sort -t ',' -k $field1 \
        > /tmp/$$.__temp_join__1.txt

    tail -n +2 $file2 | \
        sort -t ',' -k $field2 \
        > /tmp/$$.__temp_join__2.txt

    join -t, -1 $field1 -2 $field2 \
        /tmp/$$.__temp_join__1.txt \
        /tmp/$$.__temp_join__2.txt
       
    rm -f /tmp/$$.__temp_join__1.txt \
          /tmp/$$.__temp_join__2.txt
}




if [[ ! -d "${DATA_DIR}/${BATCH_NAME}" ]] ; then
    echo "The folder corresponding to the project doesn't exist" 1>&2
    echo "Create it first by running the command :" 1>&2
    echo "   generate_project.sh ${BATCH_NAME}"  1>&2
    exit 1
fi

PROJECT_XML=$(basename $(ls -1 ${DATA_DIR}/${BATCH_NAME}/project*.xml \
                             | grep -v '\.receipt\.xml$'))

PROJECT_AC=$(awk -F':' '{print $2}' <<< "${PROJECT_XML/.xml/}")

if [[ -z "PROJECT_XML" ]]  ; then
    echo "The folder corresponding to the project doesn't contain project file" 1>&2
    echo "Create it first by running the command :" 1>&2
    echo "   generate_project.sh ${BATCH_NAME}"  1>&2
    exit 1
fi

if [[ -z "${BATCH_NAME}" ]] ; then
    echo "The ${BATCH_NAME} project has no Accession Number" 1>&2
    echo "Do not forget to submit it as a new project" 1>&2
else
    echo "The ${BATCH_NAME} project has Accession Number : ${PROJECT_AC}" 1>&2
fi

# If no XSD files are present then download them

if [ ! -f "${XSD_DIR}/xsd_version.txt" ] || [ ! -f "${EXPERIMENT_XSD_FILE}" ] || [ ! -f "${RUN_XSD_FILE}" ]; then
  rm -rf "${XSD_DIR}/xsd_version.txt"
  ${LIB_DIR}/update_xsd.sh
fi

# Build the xml files

pushd "${DATA_DIR}/${BATCH_NAME}"

mkdir -p tmp

join_csv 3 1 \
    ${CSV_DIR}/"sequencing_${PROJECT_NAME}_${BATCH_NAME}.csv" \
    ${CSV_DIR}/"sequencing_${PROJECT_NAME}_${BATCH_NAME}.files.csv" \
    > tmp/files.tmp

join_csv 1 2 \
    "${SAMPLE_DATA}" \
    tmp/files.tmp \
    > tmp/data.tmp 

rm -f tmp/files.tmp

echo "Generating experiment XML files" 1>&2

for filename in $(${LIB_DIR}/process_template.awk -v ENTRY="${PROJECT_NAME}" \
                    ${EXPERIMENT_TEMPLATE} \
                    "tmp/data.tmp" \
                    | awk '($1=="<!--") {filename=$2;        \
                                         print filename}     \
                                                             \
                           ($1!="<!--") {print $0 > filename}\
                          ') ; do

    ## Attention le AC de la study est cablé en dur

    cat ${filename} \
        | sed 's@<INSTRUMENT_MODEL>Fasteris</INSTRUMENT_MODEL>@<INSTRUMENT_MODEL>Illumina HiSeq 2500</INSTRUMENT_MODEL>@' \
        | sed 's@<INSTRUMENT_MODEL>Genoscope</INSTRUMENT_MODEL>@<INSTRUMENT_MODEL>Illumina HiSeq 2500</INSTRUMENT_MODEL>@' \
        | sed 's@<INSTRUMENT_MODEL>BGI</INSTRUMENT_MODEL>@<INSTRUMENT_MODEL>Illumina HiSeq 2000</INSTRUMENT_MODEL>@' \
        | sed 's@%%STUDY_ENA_AC%%@ERP133303@' \
        > $$.tmp
    mv $$.tmp ${filename}

    # Check for previous version of the sample file with an accession
    AC=$(awk -F'\.' '{print $3}' <<< $(echo ${filename/.xml/.*.xml}))

    if [[ "$AC" != '*' ]] ; then
        SAMPLE=$(awk -F'\.' '{print $2}' <<< $(echo ${filename}))
        echo "Experiment $SAMPLE already submitted with AC : $AC"  1>&2

        awk -v accession="$AC" \
            '{gsub("<EXPERIMENT alias=","<EXPERIMENT accession=\""accession"\" alias=",$0); print $0}' \
            "${filename}" \
            > "${filename}_$$.tmp"
        mv "${filename}_$$.tmp" "${filename}"

    else
        echo "Experiment $SAMPLE was never submitted"  1>&2
    fi

    valid_xml=$(xmllint --schema "${EXPERIMENT_XSD_FILE}" \
                        "${DATA_DIR}/${BATCH_NAME}/${filename}" \
                        > /dev/null && echo ok || echo bad)

    if [[ "$valid_xml" == "bad" ]] ; then
        echo "** The produced XML file : ${DATA_DIR}/${BATCH_NAME}/${filename} is not valid **" 1>&2
        mv "${DATA_DIR}/${BATCH_NAME}/${filename}" \
        "${DATA_DIR}/${BATCH_NAME}/${filename}.bad"
    fi

done

for filename in $(${LIB_DIR}/process_template.awk -v ENTRY="${PROJECT_NAME}" \
                    ${RUN_TEMPLATE} \
                    "tmp/data.tmp" \
                    | awk '($1=="<!--") {filename=$2;        \
                                         print filename}     \
                                                             \
                           ($1!="<!--") {print $0 > filename}\
                          ') ; do

    # Check for non complete run date

    if ! egrep 'run_date="[^"]*T[^"]"' ${filename} ; then
        sed 's/run_date="[^"]*" //' ${filename} > "${filename}_$$.tmp"
        mv "${filename}_$$.tmp" "${filename}"
    fi


    # Check for previous version of the sample file with an accession
    AC=$(awk -F'\.' '{print $3}' <<< $(echo ${filename/.xml/.*.xml}))

    if [[ "$AC" != '*' ]] ; then
        SAMPLE=$(awk -F'\.' '{print $2}' <<< $(echo ${filename}))
        echo "Run $SAMPLE already submitted with AC : $AC"  1>&2

        awk -v accession="$AC" \
            '{gsub("<RUN alias=","<RUN accession=\""accession"\" alias=",$0); print $0}' \
            "${filename}" \
            > "${filename}_$$.tmp"
        mv "${filename}_$$.tmp" "${filename}"

    else
        echo "Run $SAMPLE was never submitted"  1>&2
    fi

    valid_xml=$(xmllint --schema "${RUN_XSD_FILE}" \
                        "${DATA_DIR}/${BATCH_NAME}/${filename}" \
                        > /dev/null && echo ok || echo bad)

    if [[ "$valid_xml" == "bad" ]] ; then
        echo "** The produced XML file : ${DATA_DIR}/${BATCH_NAME}/${filename} is not valid **" 1>&2
        mv "${DATA_DIR}/${BATCH_NAME}/${filename}" \
        "${DATA_DIR}/${BATCH_NAME}/${filename}.bad"
    fi

done

popd

exit 0


