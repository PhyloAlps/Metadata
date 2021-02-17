# The `CSV`directory

The `CSV` directory contains every up to date metadata that will be used
to generate XLM files for submission. 

**This is these files that will be considered as the reference data for every submissions.**

## Constraints on the CSV format.

The CSV formated files will be parsed with a simple CSV parser written in AWK.
That parser is coming from that place :

    http://lorance.freeshell.org/csv/

You can find an original copy of the script into the `lib` directory under the
name `read_csv.awk`.

For our CSV files the rules are :

- The field separaptor is the comma `,`
- If a field contains a coma the complet string have to be quoted using double quotes `"`
- Never use double quotes `"` in a data field.
- Only ASCII characters are allowed in the file. Thefore every country specific 
    fancy characters have to be avoided.
- The first line of a CSV file must contains the column name.
    - The name cannot contain anything else that alphabet letters, numeric characters 
        or underscores.
    - The name of the column will be used in XML template file surrounded by two `@` 
        characters as substitution pattern (*e.g.* `@@column_name@@`). 


## The CSV files included in that directory

### `projects.csv`

This file describes projects that will be hosted by the PhyloNorway umbrella project.
It contains three columns :

- Project_Dir
- Project_Title
- Project_Description
 
 The XML files corresponding to that templates are generated from the `project.xml` template
 using the `generate_project.sh` script. See below for the correspondance beteewn the CSV columns and the XML tags.

```xml
<PROJECT_SET>
   <PROJECT alias="phylonorway_@@Project_Dir@@">
      <TITLE>@@Project_Title@@</TITLE>
      <DESCRIPTION>@@Project_Description@@</DESCRIPTION>
      <SUBMISSION_PROJECT>
         <SEQUENCING_PROJECT/>
      </SUBMISSION_PROJECT>
   </PROJECT>
</PROJECT_SET>
```