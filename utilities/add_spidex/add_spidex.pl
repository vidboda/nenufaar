#!/usr/bin/perl -w

use strict;


use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

###################################################################################################
### script to add spidex results to tsv files							###
### david baux 2015 david.baux@inserm.fr							###
###################################################################################################



my (%opts, $file, $new_file, $ext);
getopts('i:e:s:', \%opts);

if ((not exists $opts{'i'}) || ($opts{'i'} !~ /\.t[xs][tv]/o) || (not exists $opts{'e'}) || (not exists $opts{'s'})) {
	&HELP_MESSAGE();
	exit
}

my ($TABIX, $SPIDEX);
#my $TABIX_VERSION='0.2.6';
#my $TABIX="/Users/galaxy_dev_user/variant-calling-pipeline-dev/refData/dbNSFP/3.1a/spidex_public_noncommercial_v1_0.tab.gz";
#my $TABIX="software/tabix-$TABIX_VERSION/tabix";
if ($opts{'e'} =~ /(.+tabix)/o) {$TABIX = $1}
else {exit}
if ($opts{'s'} =~ /(.+spidex.+)/o) {$SPIDEX = $1}
else {exit}

#my $SPIDEX_VERSION='1.0';
#my $SPIDEX="/Users/galaxy_dev_user/variant-calling-pipeline-dev/refData/spidex_public_noncommercial/$SPIDEX_VERSION/spidex.tab.gz";
#my $SPIDEX="refData/spidex_public_noncommercial_v$SPIDEX_VERSION/spidex_public_noncommercial_v$SPIDEX_VERSION.tab.gz";
#print $SPIDEX;
#exit;
if ($opts{'i'} =~ /(.+)\.(txt|tsv)$/o) {$file = $1;$ext = $2;} #get file path and prefix and suffix

if ($file =~ /vep/) {$new_file = "#VEP CSQ column Format:llele|Consequence|IMPACT|SYMBOL|Gene|Feature_type|Feature|BIOTYPE|EXON|INTRON|HGVSc|HGVSp|cDNA_position|CDS_position|Protein_position|Amino_acids|Codons|Existing_variation|DISTANCE|STRAND|SYMBOL_SOURCE|HGNC_ID|REFSEQ_MATCH|SIFT|PolyPhen|DOMAINS|HGVS_OFFSET|GMAF|AA_MAF|EA_MAF|CLIN_SIG|SOMATIC|PHENO|PUBMED|ExAC_AF|ExAC_AF_AFR|ExAC_AF_AMR|ExAC_AF_EAS|ExAC_AF_FIN|ExAC_AF_NFE|ExAC_AF_OTH|ExAC_AF_SAS|MaxEntScan_alt|MaxEntScan_diff|MaxEntScan_ref|ada_score|rf_score\n"} ### OLD in case of VEP producing VCF
elsif ($file =~ /snpeff/) {$new_file ="#SNPEFF EFF column Format:Effect_Impact | Functional_Class | Codon_Change | Amino_Acid_Change| Amino_Acid_length | Gene_Name | Transcript_BioType | Gene_Coding | Transcript_ID | Exon_Rank  | Genotype_Number [ | ERRORS | WARNINGS ]\n"}


open(F, "$file.$ext") or die "$file $!";

while (<F>) {
	my $line = $_;
	chomp $line;
	my $vep_txt = 0;
	if ($line =~ /^(CHROM|ID|#Uploaded_variation)\t/o) {$new_file .= "$line\tSPIDEX_dPSI\tSPIDEX_Z-SCORE\n"}
	elsif ($line =~ /^Chr\t/o) {$new_file .= "$line\t\t\t\t\t\t\t\t\t\t\t\t\tSPIDEX_dPSI\tSPIDEX_Z-SCORE\n"}#annovar
	#elsif ($line =~ /^##/o) {$new_file .= "$line\n";$vep_txt=1}#VEP txt
	else {
		my ($chr, $pos, $wt, $mt);
		my @tab = split(/\t/, $line);
		#tsv files are coming from GATK variant2table (for vep if --vcf in IURC_VCF_ANNOT scipt and snpeff) and have the same organisation
		#if ($vep_txt=1) {
		#	#code
		#}

		if ($ext eq 'tsv') {($chr, $pos, $wt, $mt) = ($tab[0], $tab[1], $tab[4], $tab[5])}
		elsif ($line =~ /^chr/o) {($chr, $pos, $wt, $mt) = ($tab[0], $tab[1], $tab[3], $tab[4])}#annovar format
		elsif ($line =~ /^(\.|rs)/o) {($chr, $pos, $wt, $mt) = ("chr$tab[1]", $tab[2], $tab[3], $tab[4])}#cava format
		#if ($chr =~ /chr([0-9XY]{1,2})/o) {$chr = $1}
		#check if substitution
		if ($wt =~ /^[ATGC]{1}$/o && $mt =~ /^[ATGC]{1}$/o) {
			#print "$TABIX $SPIDEX $chr:$pos-$pos\n";exit;
			my @spidex = split(/\n/, `$TABIX $SPIDEX $chr:$pos-$pos`);
			my $semaph = 0;
			foreach (@spidex) {
				if (/\t$wt\t$mt\t/) {
					my @res = split(/\t/, $_);
					$new_file .= "$line\t$res[4]\t$res[5]\n";
					$semaph = 1;
				}
			}
			if ($semaph == 0) {$new_file .= "$line\t.\t.\n"}

		}
		else {$new_file .= "$line\t.\t.\n"}
	}
}

close F;

open(G, ">$file.spidex.$ext") or die $!;

print G $new_file;

close G;

print "$file.spidex.$ext";

exit 0;

sub HELP_MESSAGE {
	print "\nUsage: ./add_spidex.pl -i path/to/txt/file.txt -e path/to/tabix -s path/to/spidex.gz\nSupports --help or --version\n\n
### This script adds spidex data to tabulated cava and annovar files (VEP and snpeff to be updated)
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 10/09/2015\n"
}
