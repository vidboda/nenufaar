#!/usr/bin/perl -wT

use strict;

use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;


###################################################################################################
### script to modify VCF files and computes AB for homozygous sites and indels.			###
### also annotates LowVariantFreq modified sites						###
### david baux 2015 david.baux@inserm.fr							###
###################################################################################################


my (%opts, $file, $new_file);
getopts('i:', \%opts);

if ((not exists $opts{'i'}) || ($opts{'i'} !~ /\.vcf/o)) {
	&HELP_MESSAGE();
	exit
}


if ($opts{'i'} =~ /(.+)\.vcf$/o) {$file = $1} #get file path and prefix


open(F, "$file.vcf") or die "$file $!";

while (<F>) {
	my $ligne = $_;
	if ($ligne =~ /#/o) {$new_file .= $ligne;next;}
	if ($ligne =~ /:AB:/o) {
		my $ab = /\t[01]\/1:([\d\.]+):\d+,\d+:/o;
		### We filter on the fly
		if ($ab < 0.2) {
			#$ligne =~ s/PASS/LowVariantFreq/o
			my @line = split(/\t/, $ligne);
			if ($line[6] eq 'PASS') {$ligne =~ s/PASS/LowVariantFreq/o}
			else {				
				$line[6] .= ';LowVariantFreq';
				$ligne = join("\t",@line);
			}
			
		}
		$new_file .= $ligne;
		next;
	}	
	elsif ($ligne =~ /GT:AD:/o) {
		my @line = split(/\t/, $ligne);
		my @format_labels = split(/:/, $line[8]); #get format labels
		my @format_value = split(/:/, $line[9]); #get format values
		#look for AD index
		my $i = 0;
		foreach(@format_labels) {if (/AD/o) {last}$i++}
		my @value = split(/,/, $format_value[$i]);
		
		#my $total_read_dp = $format_value[$i+2];
		my (@ab, @alt, $txt_ab, $total_read);
		$total_read = $value[0];
		if ($#value == 1) {$alt[0] = $value[1];$total_read += $value[1];}
		else {	#if multiple variants at a given site we calculate each alt AB and total
			for (my $j=1;$j<=$#value;$j++) {push @alt, $value[$j];$total_read += $value[$j];}
		}
		
		foreach my $alt (@alt) {
			#case 0 ref, 0 alt (seen!!)
			if ($alt == 0) {push @ab, 0}
			else {push @ab, sprintf('%.3f', ($alt/$total_read))}#normal case
			#else {push @ab, sprintf('%.3f', ($alt/($alt+$value[0])))}#normal case
		}	#AB calculation
		### We filter on the fly
		my $k;
		foreach my $ab (@ab) {
			$k++;
			if ($ab < 0.2) {
				#$ligne =~ s/PASS/LowVariantFreq/o
				if ($line[6] eq 'PASS' && $k == 1) {$ligne =~ s/PASS/LowVariantFreq/o}
				else {
					$line[6] .= ';LowVariantFreq';
					$ligne = join("\t",@line);
				}
			}
			$txt_ab .= "$ab,";
		}
		$txt_ab =~ s/,$//o;
		$ligne =~ s/GT:AD/GT:AB:AD/og;
		$ligne =~ s/\t([01]\/[12]):([\d,]+):/\t$1:$txt_ab:$2:/;

		#old fashion with cumulated alt
		#my ($ab, $alt);
		#if ($#value == 1) {$alt = $value[1]}
		#else {	#if multiple variants at a given site we cumulate alt depth
		#	for (my $j=1;$j<=$#value;$j++) {$alt .= $value[$j]}
		#}
		#$ab = sprintf('%.3f', ($alt/($alt+$value[0])));	#AB calculation
		#### We filter on the fly
		#if ($ab < 0.2) {
		#	#$ligne =~ s/PASS/LowVariantFreq/o
		#	if ($line[6] eq 'PASS') {$ligne =~ s/PASS/LowVariantFreq/o}
		#	else {
		#		$line[6] .= ';LowVariantFreq';
		#		$ligne = join("\t",@line);
		#	}
		#	
		#}
		#
		#$ligne =~ s/GT:AD/GT:AB:AD/o;
		#$ligne =~ s/\t([01]\/1):([\d,]+):/\t$1:$ab:$2:/;
		##$ligne =~ s/\t([01]\/1):(\d+,\d+):/\t$1:$ab:$2:/;
		
		
		$new_file .= $ligne;
	}
}

close F;
###FILTER=<ID=LowVariantFreq,Description="AB < 0.2">
if ($new_file !~ /##FORMAT=<ID=AB.+/o) {
	$new_file =~ s/##FORMAT=<ID=AD,Number=.,Type=Integer,Description="Allelic depths for the ref and alt alleles in the order listed">/##FILTER=<ID=LowVariantFreq,Description="AB < 0.2">\n##FILTER=<ID=PASS,Description="good">\n##FORMAT=<ID=AB,Number=1,Type=String,Description="Allele balance for each genotype">\n##FORMAT=<ID=AD,Number=.,Type=Integer,Description="Allelic depths for the ref and alt alleles in the order listed">/
}
elsif ($new_file =~ /##FORMAT=<ID=AB,Number=1,Type=Float,Description="Allele balance for each het genotype">/o) {
	$new_file =~ s/##FORMAT=<ID=AB,Number=1,Type=Float,Description="Allele balance for each het genotype">/##FILTER=<ID=LowVariantFreq,Description="AB < 0.2">\n##FILTER=<ID=PASS,Description="good">\n##FORMAT=<ID=AB,Number=1,Type=String,Description="Allele balance for each genotype">/o
}

$new_file =~ s/\n#CHROM/\n##ABannotation="completed with vcf_allele_balance perl script written at IURC"\n#CHROM/o;


$file =~ /(.+)\.raw.polyx.gatk/o;

open(G, ">$1.final.vcf") or die $!;

print G $new_file;

close G;


sub HELP_MESSAGE {
	print "\nUsage: ./vcf_allele_balance.pl -i path/to/vcf/file.vcf\nSupports --help or --version\n\n
### This script annototes the AB (AlleleBalance) field for each line of a VCF file
### Input is a vcf file, output is another vcf file
### AB is computed for homozygous and indels variants, because GATK does not
### AB calculation is based on AD annotation (DepthPerAlleleBySample) of the FORMAT field
### for multiple variants at a given site, refs are cumulated
### And the script replaces PASS FILTER with LowVariantFreq if AB < 0.2 at the considered site
### therefore must be launched right after variant calling and before filtration (before PASS could be replaced)
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 18/06/2015\n"
}