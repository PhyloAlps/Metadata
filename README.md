# The PhyloAlps metadata project

The `PhyloAlps metadata` project is aiming to store every files related to the submission of the PhyloAlps genome skimming project to the EBI<sup>[[1]](#EBI)</sup> ENA<sup>[[2]](#ENA)</sup> database.

## Directories organisation


### The `bin` directory

The `bin` directory contains every scripts (mainly bash scripts) needed to submit 
PhyloAlps data to the ENA database.

### The `lib` directory

The `lib` directory contains pieace of code that end users are not supposed to use
directly. The scripts included in that directory are called from scripts located in
the `bin` directory. 

### The `data` directory

The `data` directory contains every XML files describing the samples and sequences.
It also contains the `metadata_sample.csv` file containing every data needed to generate every
XML files required by the submission process for the sample description.

The `data` directory is splited in a `common` directory which contains every files related to the *PhyloAlps* umbrella project, a `csv` directory containing every up to date metadata in CSV format, and one directory by sub project. As each sub project is corresponding to a set (batch) of samples, I propose to name them `batchXX` where `XX` is an ordinal number padded on
two digits (*e.g.* `batch01`).

### The `xml_template` directory

The `xml_template` directory contains XML files or XML files templates used to generate the 
medata files automaticaly generated from the CVS files describing samples and sequences.

<a name="EBI"><sup>[1]</sup></a>:EBI: - [European Bioinformatic Institut](https://ebi.ac.uk).

<a name="ENA"><sup>[2]</sup></a>:ENA: - [European Nucleotide Archive](https://www.ebi.ac.uk/ena).

## Some information about ENA submission

Global information on the ENA submission :

https://buildmedia.readthedocs.org/media/pdf/ena-docs/latest/ena-docs.pdf

Documentation for programmatic access can be found at the following place:

https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html


### Samples attributes have to follow checklists

The complete set of checklists is available at EBI.

https://www.ebi.ac.uk/ena/browser/checklists

For PhyloNorway samples we are following the [ERC000037](https://www.ebi.ac.uk/ena/browser/view/ERC000037) checklists.


Among the proposed attributes the following ones will be documùented :

