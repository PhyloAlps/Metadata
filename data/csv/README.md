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

### `TestMetadata.csv`

This is a test metadata file that contains the data from 10 samples. It contains 25 columns, though not all filled in or relevant:

1. The sample batch.
2. The Tromso herbarium sample code.
3. The BOLD sample code. Note: the same as the herbarium code with a "_sg" suffix.
4. Species.
5. Family.
6. The NCBI taxonID.
7. An alternate NCBI taxonID to species or genus level if the requested ID in column 6 is not active.
8. Note explaining wich alternate NCBI taxonID was used.
9. The sample collection date in dd/mm/yyyy format.
10. The collection month.
11. The sample collector in "lastname, firstname" format. Multiple collectors are separated by ";".
12. Country
13. Sampling location. Regions are separated by comma's and in most cases start with the country (need to correct some that have info missing.). Some descriptions are more elaborate than others.
14. Latitude (decimal).
15. Longitude (decimal).
16. Sample age when extracted.
17. Weight of the extracted material in grams. Missing for some samples.
18. Extraction concentration in ng/ul. Missing for some samples
19. Genoscope sequence library in "sequence run:library" format.
20. Library read count.
21. Assembled chloroplast length. Not available for all samples.
22. Number of chloroplast contigs. Not available for all samples.
23. Chloroplast coverage. Not available for all samples.
24. Assembled nrDNA length. Not available for all samples.
25. Number of nrDNA contigs. Not available for all samples.
26. Chloroplast nrDNA. Not available for all samples.




