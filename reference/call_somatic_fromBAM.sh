#!/bin/bash

#AUTHOR: tangxia

#DATE: 2025/04/05 

source ~/.bashrc

########NOTE: you need to change your path to resource firstly #########

# # variable declaration (please see the readme file in Github for details: https://github.com/Shuhua-Group/CHIP-mutation-calling-NGS-pipeline/)  
gatk_db=/share/labdata/POG/refrence/humpopg_reference/humpopg-bigdata5/AAGC/bundle

# GRCh38 reference
reference=$gatk_db/GATK_hg38_from_Google_Cloud_bucket.2016/Homo_sapiens_assembly38.fasta

# gnomAD resource for well known germline mutations
germline_resource=$gatk_db/somatic/af-only-gnomad.hg38.vcf.gz

# download from the 'reference' folder in Github links
interval_bed=$gatk_db/somatic/common.interval_GRCh38.bed

# dbsnp
dbsnp=$gatk_db/GATK_hg38_from_Google_Cloud_bucket.2016/backup/Homo_sapiens_assembly38.dbsnp138.vcf.gz

# known Indels
known_indels=$gatk_db/GATK_hg38_from_Google_Cloud_bucket.2016/Homo_sapiens_assembly38.known_indels.vcf.gz

# Known sites of 1KG
known_mills=$gatk_db/06.NGSreference/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
known_1kg=$gatk_db/06.NGSreference/1000G_phase1.snps.high_confidence.hg38.vcf.gz
known_omni=$gatk_db/06.NGSreference/1000G_omni2.5.hg38.vcf.gz

# Well-trained panel of normal (PON) control based on 1KG for CHIP mutation calling
PON=$gatk_db/somatic/somatic-hg38_1000g_pon.hg38.vcf.gz

# # program (change the work path firstly)
proj_dir=/share1/home/tangxia/projects/
cd $proj_dir

if [ ! -d "gatk" ]; then mkdir gatk; fi
if [ ! -d "mutect2" ]; then mkdir mutect2; fi
if [ ! -d "svcf" ]; then mkdir svcf; fi

# tmp dir
TMP_DIR=$proj_dir/gatk/$id/tmp
if ! [ -d $TMP_DIR ]; then mkdir $TMP_DIR; fi

# # # # # # # # # # # # #
# # # # functions # # # #
# # # # # # # # # # # # #


run_BQSR () {
        # Recalibrate base quality scores

        #samtools index ${id}.dedup.bam

        # Analyze patterns of covariation in the sequence dataset
        gatk --java-options "-Xmx32g -Xms4g" BaseRecalibrator \
                -R $reference \
                -I $bam1 \
                --known-sites $dbsnp \
                --known-sites $known_indels \
                --known-sites $known_mills \
                --known-sites $known_1kg \
                --known-sites $known_omni \
                -O $recalTable

        # Apply the recalibration to your sequence data 
        gatk --java-options "-Xmx32g -Xms4g" ApplyBQSR \
                -R $reference \
                -I $bam1 \
                --bqsr-recal-file $recalTable \
                -O $bam2
}


gatk_mutect () {
	gatk Mutect2 \
		-R $reference \
		-I $bam2 \
		-pon $PON \
		--germline-resource $germline_resource \
		-L $interval_bed \
		--af-of-alleles-not-in-resource 0.000001 \
		--f1r2-tar-gz $f1r2 \
		-O $mutect2_output
}
	
# # read oritentation
learnReadOrientationModel () {
	gatk LearnReadOrientationModel \
		-I $f1r2 \
 		-O $orientation_output 
}

# # 
getPileupSummaries () {
	gatk GetPileupSummaries \
		-R $reference \
		-I $bam2 \
		-L $interval_bed \
		-V $germline_resource \
		-O $pileupsummariseTable 
}

# #
calculateContamination () {
	gatk CalculateContamination \
		-I $pileupsummariseTable \
		-O $contaminationTable 
}

# step2: filter
filterMutectCalls () {
	gatk FilterMutectCalls \
		-R $reference \
		-V $mutect2_output \
		--contamination-table $contaminationTable \
		-L $interval_bed \
		--ob-priors $readOrientation \
		-O $filteredVCF 

	vcftools --gzvcf $filteredVCF --remove-filtered-all --recode --stdout |\
		bgzip -c -f > $finalVCF 
	
	tabix $finalVCF 
}

# # # # # # # # #  # # #
# # # main program # # #
# # # # # # # # #  # # #

main () {
	id=$1
	
	 if ! [ -d $proj_dir/mutect2/$id ]; then mkdir $proj_dir/mutect2/$id; fi
	 if ! [ -d $proj_dir/svcf/$id ]; then mkdir $proj_dir/svcf/$id; fi
	 if ! [ -d $proj_dir/gatk/$id ]; then mkdir $proj_dir/gatk/$id; fi
	
	### Locate the BAM file (if just dedup bam, see 'bam1'; if BQSR bam, see 'bam2', and skip the 'run_BQSR' step)
        ## change the bam_dir to your own firstly
	bam_dir=/home/pogadmin/PGG_data_20220603/Data7/120.remove.duplicates.b38/
        
	## dedup.bam, without BQSR, then you need to run_BQSR
	bam1="$bam_dir/${id}/${id}.dedup.bam"
        
	recalTable="$proj_dir/gatk/${id}/${id}.recal_data.table"

	## if the input bam is after BQSR, then start from 'gatk_mutect' step 
	## change the path to your BQSR bam firtsly
	bam2="$proj_dir/gatk/${id}/${id}.recal_reads.bam"

	f1r2="$proj_dir/mutect2/${id}/${id}.f1r2.tar.gz"
	mutect2_output="$proj_dir/vcf/${id}/${id}.mutect2.vcf.gz"
	orientation_output="$proj_dir/mutect2/${id}/${id}.read-orientation-model.tar.gz"
	pileupsummariseTable="$proj_dir/mutect2/${id}/${id}.tumor.getpileupsummaries.table"
	contaminationTable="$proj_dir/mutect2/${id}/${id}.calculatecontamination.table"
	readOrientation="$proj_dir/mutect2/${id}/${id}.read-orientation-model.tar.gz"
	filteredVCF="$proj_dir/vcf/${id}/${id}.somatic_oncefiltered.vcf.gz"

	## this is the output file for each individual
	finalVCF="$proj_dir/vcf/${id}/${id}.somatic.final.vcf.gz"


        ### 1. generate recalibrated bam file 
        run_BQSR 
		
	### 2. mutect2 somatic mutation calling
	gatk_mutect
	learnReadOrientationModel
	getPileupSummaries
	calculateContamination
	filterMutectCalls
}

# declare your path to sample_list, and put the sample name into one .txt file, each row indicates one sample name
sample_list=your/path/to/sample_list 
cut -f1 $proj_dir/src/${sample_list}  | uniq | while read id; do main $id; done


# # # END # # #
