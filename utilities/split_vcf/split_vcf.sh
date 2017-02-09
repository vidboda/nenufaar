#!/bin/sh

#just launches GATK selectVariants

srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmpjp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/MYO/MERGED_SAMPLES.final.vcf -o ../../output/MYO/I237.vcf -sn I237

srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmpjp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/MYO/MERGED_SAMPLES.final.vcf -o ../../output/MYO/I362.vcf -sn I362

srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmpjp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/MYO/MERGED_SAMPLES.final.vcf -o ../../output/MYO/I91.vcf -sn I91

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/21053/family_JUL/MERGED_SAMPLES/27748/MERGED_SAMPLES.final.vcf -o i6.vcf -sn i6

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/21053/family_JUL/MERGED_SAMPLES/27748/MERGED_SAMPLES.final.vcf -o i7.vcf -sn i7

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/21053/family_JUL/MERGED_SAMPLES/27748/MERGED_SAMPLES.final.vcf -o i8.vcf -sn i8

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant ../../output/8757/family_ICH/MERGED_SAMPLES/4508/MERGED_SAMPLES.final.vcf -o B00HKLL2.vcf -sn B00HKLL2

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant MERGED_SAMPLES.final.vcf -o B00HLK8.vcf -sn B00HLK8

#srun --job-name=srun_split -N1 -n1 -c24 --partition=defq --account=IURC /gpfs2/cluster/softs/jdk-1.8.25/jdk1.8.0_25/bin/java -jar -Xmx48g -Djava.io.tmpdir=tmp/ ../../software/GenomeAnalysisTK/3.5.0/GenomeAnalysisTK.jar -T SelectVariants -R ../../refData/genome/hg19/hg19.fa -nt 24 --variant MERGED_SAMPLES.final.vcf -o B00HLK9.vcf -sn B00HLK9