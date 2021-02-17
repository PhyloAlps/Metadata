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
# lib/update_xsd.sh
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

