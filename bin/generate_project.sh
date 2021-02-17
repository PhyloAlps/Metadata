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

# This function transforms a relative path to an absolute one
# starting from the root (/) of the directory tree.
relative2absolute(){
  local thePath
  if [[ ! "$1" =~ ^/ ]];then
    thePath="$PWD/$1"
  else
    thePath="$1"
  fi
  echo "$thePath"|(
  IFS=/
  read -a parr
  declare -a outp
  for i in "${parr[@]}";do
    case "$i" in
    ''|.) continue ;;
    ..)
      len=${#outp[@]}
      if ((len==0));then
        continue
      else
        unset outp[$((len-1))] 
      fi
      ;;
    *)
      len=${#outp[@]}
      outp[$len]="$i"
      ;;
    esac
  done
  echo /"${outp[*]}"
)
}


HOMEDIR=$(relative2absolute $THIS_DIR/..)
BIN_DIR="${HOMEDIR}/bin"
LIB_DIR="${HOMEDIR}/lib"
TEMPLATE_DIR="${HOMEDIR}/xml_templates"
DATA_DIR="${HOMEDIR}/data"
CSV_DIR="${DATA_DIR}/csv"
XSD_DIR="${LIB_DIR}/ena_xsd"

XSD_FILE="${XSD_DIR}/ENA.project.xsd"

PROJECT_TEMPLATE="${TEMPLATE_DIR}/project.xml"
PROJECT_DATA="${CSV_DIR}/projects.csv"

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
