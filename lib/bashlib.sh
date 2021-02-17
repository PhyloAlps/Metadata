#!/bin/bash

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
