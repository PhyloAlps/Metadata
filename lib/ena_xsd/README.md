# The `ena_xsd` directory

The `ena_xsd` directory contains every XML schema files (XSD files)
required to validate XML files before submiting them to EBI.
The XSD files are uploaded directly from the EBI FTP site at
the following address

    ftp://ftp.ebi.ac.uk/pub/databases/ena/doc/xsd

To do the first download or to update the XSD files to the latest
version, you have to use the `lib/update_xsd.sh` script.

The `ena_xsd` directory contains also a `xsd_version.txt` file
containing a single string indicating the current local version of
the XDS files. If you want to force the reload of the XSD file by the
`lib/update_xsd.sh` script, delete that file.



