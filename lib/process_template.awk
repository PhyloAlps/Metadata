#!/usr/bin/awk -f
#**************************************************************************
#
# This file is in the public domain.
#
# It is derived from the code proposed by LoranceStinson+csv@gmail.com.
# (see http://lorance.freeshell.org/csv/)
#
# The original code is provided in the same directory under the name
# read_csv.awk. It contains every explanation on the parse_csv function.
# Here only the parameter documention is conserved
#
# The process_template.awk script requires two arguments
#
# - The name of the XML template
# - The name of the data file (a CVS file) 
#
# The variable ENTRY can be defined using the -v option of awk.
# If the ENTRY variable is defined only the line in the CVS file
# having as first filed a value equal to ENTRY will be processed.
# If the ENTRY variable is not specified, every entries of the cvs file
# will be processed
#
# The cvs file must have its first row containing column names without any space.
# Field must be separated using comas "," and text can be quoted using double quotes ".
#
# Example command:
#
# bin/process_template.awk xml_templates/project.xml data/projects.csv
#
# bin/process_template.awk -v PROJECT=batch01 xml_templates/project.xml data/projects.csv
#
#**************************************************************************
#
# Below documentation concerns the parse_csv function.
#
# Parse a CSV string into an array.
# The number of fields found is returned.
# In the event of an error a negative value is returned and csverr is set to
# the error. See below for the error values.
#
# Parameters:
# string  = The string to parse.
# csv     = The array to parse the fields into.
# sep     = The field separator character. Normally ,
# quote   = The string quote character. Normally "
# escape  = The quote escape character. Normally "
# newline = Handle embedded newlines. Provide either a newline or the
#           string to use in place of a newline. If left empty embedded
#           newlines cause an error.
# trim    = When true spaces around the separator are removed.
#           This affects parsing. Without this a space between the
#           separator and quote result in the quote being ignored.
#
#**************************************************************************

function parse_csv(string,csv,sep,quote,escape,newline,trim, fields,pos,strtrim) {
    # Make sure there is something to parse.
    if (length(string) == 0) return 0;
    string = sep string; # The code below assumes ,FIELD.
    fields = 0; # The number of fields found thus far.
    while (length(string) > 0) {
        # Remove spaces after the separator if requested.
        if (trim && substr(string, 2, 1) == " ") {
            if (length(string) == 1) return fields;
            string = substr(string, 2);
            continue;
        }
        strtrim = 0; # Used to trim quotes off strings.
        # Handle a quoted field.
        if (substr(string, 2, 1) == quote) {
            pos = 2;
            do {
                pos++
                if (pos != length(string) &&
                    substr(string, pos, 1) == escape &&
                    (substr(string, pos + 1, 1) == quote ||
                     substr(string, pos + 1, 1) == escape)) {
                    # Remove escaped quote characters.
                    string = substr(string, 1, pos - 1) substr(string, pos + 1);
                } else if (substr(string, pos, 1) == quote) {
                    # Found the end of the string.
                    strtrim = 1;
                } else if (newline && pos >= length(string)) {
                    # Handle embedded newlines if requested.
                    if (getline == -1) {
                        csverr = "Unable to read the next line.";
                        return -1;
                    }
                    string = string newline $0;
                }
            } while (pos < length(string) && strtrim == 0)
            if (strtrim == 0) {
                csverr = "Missing end quote.";
                return -2;
            }
        } else {
            # Handle an empty field.
            if (length(string) == 1 || substr(string, 2, 1) == sep) {
                csv[fields] = "";
                fields++;
                if (length(string) == 1)
                    return fields;
                string = substr(string, 2);
                continue;
            }
            # Search for a separator.
            pos = index(substr(string, 2), sep);
            # If there is no separator the rest of the string is a field.
            if (pos == 0) {
                csv[fields] = substr(string, 2);
                fields++;
                return fields;
            }
        }
        # Remove spaces after the separator if requested.
        if (trim && pos != length(string) && substr(string, pos + strtrim, 1) == " ") {
            trim = strtrim
            # Count the number fo spaces found.
            while (pos < length(string) && substr(string, pos + trim, 1) == " ") {
                trim++
            }
            # Remove them from the string.
            string = substr(string, 1, pos + strtrim - 1) substr(string,  pos + trim);
            # Adjust pos with the trimmed spaces if a quotes string was not found.
            if (!strtrim) {
                pos -= trim;
            }
        }
        # Make sure we are at the end of the string or there is a separator.
        if ((pos != length(string) && substr(string, pos + 1, 1) != sep)) {
            csverr = "Missing separator.";
            return -3;
        }
        # Gather the field.
        csv[fields] = substr(string, 2 + strtrim, pos - (1 + strtrim * 2));
        fields++;
        # Remove the field from the string for the next pass.
        string = substr(string, pos + 1);
    }
    return fields;
}

# Set the record separator to \0 to insure the reading of the first file
# as a single string
BEGIN {RS="\0"; FIRST=0} 

# The rule which is reading the second file

(FIRST==1) {
    num_fields = parse_csv($0, csv, ",", "\"", "\"", "\\n", 1);
}

(FIRST==1 && NR==2) {
    ncol = num_fields;
    for (i=0; i<ncol; i++)
        HEADER[i]=csv[i];
}

(FIRST==1 && NR>2 && (PROJECT=="" || ENTRY==csv[0])) {
    result=TEMPLATE;

    if (ncol!=num_fields) {
        printf "ERROR: %s (%d) -> %s\n", csverr, num_fields, $0; 
    } else {
        for (i=0; i<ncol; i++) {
            pattern="@@" HEADER[i] "@@";
            gsub(pattern,csv[i],result);
        }
        print result;
    }
}

# The rule which is reading the first file 
(FIRST==0){
        TEMPLATE=$0;
        FIRST=1;
        RS="\n"

    } 
