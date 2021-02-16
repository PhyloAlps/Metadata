# The PhyloNorway metadata project

The `PhyloNorway metadata` project is aiming to store every files related to the submission of the PhyloNorway genome skimming project to the EBI<sup>[[1]](#EBI)</sup> ENA<sup>[[2]](#ENA)</sup> database.

## Directories organisation


### The `bin` directory

The `bin` directory contains every scripts (mainly bash scripts) needed to submit 
PhyloNorway data to the ENA database.

### The `data`directory

The `data` directory contains every XML files describing the samples and sequences.
It also contains the `metadata_sample.csv` file containing every data needed to generate every
XML files required by the submission process for the sample description.

The `data` directory is splited in a `common` directory which contains every files related to the *PhyloNorway* umbrella project and one directory by sub project. As each sub project is corresponding to a
set (batch) of samples, I propose to name them `batchXX` where `XX` is an ordinal number padded on
two digits.

### The `xml_template` directory

The `xml_template` directory contains XML files or XML files templates used to generate the 
medata files automaticaly generated from the CVS files describing samples and sequences.

<a name="EBI"><sup>[1]</sup></a>:EBI: - [European Bioinformatic Institut](https://ebi.ac.uk).

<a name="ENA"><sup>[2]</sup></a>:ENA: - [European Nucleotide Archive](https://www.ebi.ac.uk/ena).