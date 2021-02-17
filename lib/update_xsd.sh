#!/bin/bash

##################################
#
# Get the latest version of the complete set
# of XML schema file available at EBI from the 
# foloowing ftp site :
#
#     ftp://ftp.ebi.ac.uk/pub/databases/ena/doc/xsd/
#    
# Example:
#
# lib/update_xsd.sh batch01
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

XSD_URL="ftp://ftp.ebi.ac.uk/pub/databases/ena/doc/xsd"

# Look at the latest version of XSD on the EBI FTP site

XSD_VERSION=$(curl ${XSD_URL}/ \
                | sort -k 9 \
                | tail -1 \
                | awk '{print $NF}')

# Create if needed the local XSD local directory
# and the version file

mkdir -p "$XSD_DIR"
touch "${XSD_DIR}/xsd_version.txt"

LOCAL_XSD_VERSION=$(cat "${XSD_DIR}/xsd_version.txt")

if [[ "$LOCAL_XSD_VERSION" != "$XSD_VERSION" ]] ; then
    echo update EBI ENA XSD files to version $XSD_VERSION  1>&2

    file_list=$(curl ${XSD_URL}/${XSD_VERSION}/ \
                  | awk '($NF ~ /\.xsd$/) {print $NF}')

    for f in $file_list ; do
        curl ${XSD_URL}/${XSD_VERSION}/$f > "${XSD_DIR}/$f"
    done
    
    echo $XSD_VERSION > "${XSD_DIR}/xsd_version.txt"
else
    echo "local EBI ENA XSD files are up to date ($XSD_VERSION)" 1>&2
fi

