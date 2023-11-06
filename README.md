# Somatic mutation calling pipeline for individual sample #

### This pipeline based on snakemake calls somatic variants from next-generation whole-exome/genome sequencing of human samples and produces a purely filtered VCF file containing high confident somatic mutations
![image](https://github.com/MorganHis/Somatic-mutation-calling-test-pipeline/assets/84215074/b490c5fb-6e51-4f0d-b129-f2a24c649a33)
-----------------------------------

## Required downloaded files
#### Please download the following files which are required known variation vcf files in the GRCh38 resource bundle in advance, and put all downloaded files into the same directory -`` gatk_db ``, coincided with the directory in your configuration file (`` config.yaml ``)

### 1). GRCh38 reference: `` GRCh38_full_analysis_set_plus_decoy_hla.fa``
* reference: https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/

### 2). gnomAD resource for well known germline mutations
* germline_resource: https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz

### 3). Well-trained panel of normal (PON) control based on 1KG for somatic mutation calling
* PON: https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38/somatic-hg38_1000g_pon.hg38.vcf.gz

### 4-6). Known sites of 1KG
* known_1kg: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/1000G_phase1.snps.high_confidence.hg38.vcf.gz
* known_omni: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/1000G_omni2.5.hg38.vcf.gz
* known_mills: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

### 7). dbSNP
* dbsnp: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.gz

### 8). Known Indels
* known_indels: https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz

-----------------------------------

## Required input data

### Please place both files in the same directory, which the directory will be set as the `` sample_dir `` in your configuration file (`` config.yaml ``)

* Two FASTQ files (named as 'sampleID_1.fq.gz' and 'sampleID_2.fq.gz') contained paired-end next generation sequencing (WES or WGS) data

-----------------------------------

## Installation

* conda >= 22.9.0 is required

### 0. Open the directory to download the pipeline

```
cd  path/to/download
```

### 1. Clone the repo

```
git clone https://github.com/Shuhua-Group/Somatic-mutation-calling-NGS-pipeline
```

### 2. Open the work directory where you want to run this pipeline

```
cd Somatic-mutation-calling-NGS-pipeline
```

### 3. Create the conda environment

```
conda env create -f environment.yaml
```

### 4. Active the conda environment

```
conda activate SomaticMC
```

-----------------------------------

## How to run

### 0. Modify the configuration file

* The provided configuration file (`` config.yaml ``) is presented as follows, and it requires modification for some items as described in the comment lines

```

## sampleName (your input files should be named as 'sampleName_1.fq.gz' and 'sampleName_2.fq.gz'.)
sampleName: "your_sampleName"

## replace the "/path/to/download/Somatic-mutation-calling-NGS-pipeline" to the absolute directory where the pipeline was downloaded
download_dir: /path/to/download/Somatic-mutation-calling-NGS-pipeline

## replace the "/path/to/reference" to the absolute directory where the required reference data were downloaded
gatk_db: /path/to/reference

## replace the "/path/to/sampleFolder" to the absolute directory where the samples(named as 'sampleID_1.fq.gz' and 'sampleID_2.fq.gz') were
sample_dir: /path/to/sampleFolder

threads: 32

mem_mb: 131072

```

### 1. Run snakemake

Once the config file is ready, you can run the pipeline as follows:

```
snakemake -s snakemake_SMC --configfile config.yaml -c 32

``` 

You can also run the pipeline in PBS or SLURM system

See more details at [snakemake doc](https://snakemake.readthedocs.io/en/stable/executing/cluster.html)

-----------------------------------

## Output

If the pipeline runs correctly, the results file will be written to `{download_dir}/output/`, including:

* a filtered individual VCF (named as *.somatic.final.vcf.gz) containing all detected somatic variants after hard filtering by Mutect2 will be written to: `` {download_dir}/output/vcf/{sample} ``, with high confident somatic variants remained

* an individual VCF (named as *.mutect2.vcf.gz) containing raw somatic variants calling output without filtration will be written to: `` {download_dir}/output/vcf/{sample} ``, which you can define the filtration rules customized

* a bam file (named as *.recal_reads.bam) containing pre-processed reads by the GATK BQSR will be written to: `` {download_dir}/output/gatk/{sample} ``, which could be directly loaded into IGV (Integrative Genomics Viewer) to check the sequenced reads coverage

* all log files will be saved in the `` {download_dir}/output/logs/ `` directory


* To further interpret the results, see more details at(https://gatk.broadinstitute.org/hc/en-us/articles/360037593851-Mutect2)

-----------------------------------

### Notes

* Please give credit to the relevant paper if the pipeline was applied to your work

