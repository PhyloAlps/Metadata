#!/bin/bash

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
TEMPLATE_DIR="${HOMEDIR}/xml_templates"
DATA_DIR="${HOMEDIR}/data"

PROJECT_TEMPLATE="${TEMPLATE_DIR}/project.xml"
PROJECT_DATA="${DATA_DIR}/projects.csv"

PROJECT_NAME=$1

# Build the project directory in the DATA_DIR

mkdir -p "${DATA_DIR}/${PROJECT_NAME}"

# Build the xml project file

${BIN_DIR}/process_template.awk -v ENTRY="${PROJECT_NAME}" \
           ${PROJECT_TEMPLATE} \
           ${PROJECT_DATA} \
           > "${DATA_DIR}/${PROJECT_NAME}/project.xml"


