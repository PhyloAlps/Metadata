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


webin_credentials() {
    #
    # Looks at ~/.ENA_passwd
    #

    if [[ ! -f ~/.ENA_passwd ]] ; then
        echo "You must create a file in your home directory called : .ENA_passwd"  1>&2
        echo "That file must contain a line following the format   : ${UMBRELLA}:LOGIN:PASSWD"  1>&2
        echo "With LOGIN your actual ENA user id, something like Webin-XXXXX with X being a digit." 1>&2
        echo "And PASSWD, the password associated with that account" 1>&2
        exit 1
    fi

    #
    # Get the LOGIN and PASSWD information for the umbrella project
    #

    LOGIN=$(awk -F':' -v umbrella="$UMBRELLA" '($1==umbrella) {print $2}' < ~/.ENA_passwd)
    PASSWD=$(awk -F':' -v umbrella="$UMBRELLA" '($1==umbrella) {print $3}' < ~/.ENA_passwd)

}

receipt_info_messages() {
   xmllint --noblanks --xpath '/RECEIPT/MESSAGES/INFO' - 2>/dev/null <<< $* \
      | sed 's@</INFO>@\n@g' \
      | sed 's@<INFO>@@g'
}

receipt_error_messages() {
   xmllint --noblanks --xpath '/RECEIPT/MESSAGES/ERROR' - 2>/dev/null <<< $* \
      | sed 's@</ERROR>@\n@g' \
      | sed 's@<ERROR>@@g'
}

receipt_project_accession() {
   xmllint --noblanks --xpath '/RECEIPT/PROJECT/@accession' - 2>/dev/null <<< $* \
      | sed 's/accession=//' \
      | sed 's/"//g' \
      | sed 's/^ *//' | sed 's/ *$//'
}




HOMEDIR=$(relative2absolute $THIS_DIR/..)
BIN_DIR="${HOMEDIR}/bin"
LIB_DIR="${HOMEDIR}/lib"
TEMPLATE_DIR="${HOMEDIR}/xml_templates"
DATA_DIR="${HOMEDIR}/data"
CSV_DIR="${DATA_DIR}/csv"
XSD_DIR="${LIB_DIR}/ena_xsd"


UMBRELLA="PhyloNorway"
