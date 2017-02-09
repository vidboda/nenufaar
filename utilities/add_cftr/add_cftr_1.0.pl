#!/usr/bin/perl -w

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

############################################################################################################
##	Script to put a CFTR database data (obtained from Taulan's group (jess)				  ##
##	to get occurence of CFTR variants in the lab							  ##
##	david baux 08/2016										  ##
##	david.baux@inserm.fr										  ##
############################################################################################################


my (%opts, $file, $cftr_file, $header, $new_file, $tabix);
getopts('c:t:e:', \%opts);

if ((not exists $opts{'c'}) || ($opts{'c'} !~ /CFTR_hg\d{2}_\d{2}_\d{2}_\d{4}\.vcf\.gz$/o) || (not exists $opts{'t'}) || ($opts{'t'} !~ /\.txt$/o) || (not exists $opts{'e'}) || ($opts{'e'} !~ /tabix$/o)) {
	&HELP_MESSAGE();
	exit
}

if ($opts{'t'} =~ /(.+)\.txt$/o) {$file = $1} #get file path and prefix
if ($opts{'c'} =~ /(.+CFTR_hg\d{2}_\d{2}_\d{2}_\d{4}\.vcf\.gz)$/o) {$cftr_file = $1} #get led file path
if ($opts{'e'} =~ /(.+tabix)$/o) {$tabix = $1} #get tabix path


my ($i, $j) = (0, 0);

open(G, "$file.txt") or die "$file.txt $!";

while (<G>) {
	chomp;
	my $ligne = $_;
	if (/Chr\sStart/o) {
		my $led = '';
		if ($file =~ /led/o) {$led = '\t\t'}
		if ($file =~ /barcoded/o) {$new_file = "$ligne\tXX\tXX\n";next;}#to be changed for CFTR
		else {$new_file = "$ligne$led\t\t\t\t\t\t\t\t\t\tXX\tXX\n";next;}#to be changed for CFTR	
	}
	my @line = split(/\t/, $ligne);
	my ($chr, $pos, $end, $ref, $alt) = (shift(@line), shift(@line), shift(@line), shift(@line), shift(@line));
	if ($chr =~ /chr([\dXYM])/o) {$chr = $1}
	my ($het, $hom) = (0, 0);
	my @led =  split(/\n/, `$tabix $cftr_file $chr:$pos-$pos`);
	foreach (@led) {
		#print "$_\n";
		my @current = split(/\t/, $_);
		if (/\t$ref\t$alt\t/) {
			if ($current[5] eq 'homozygous') {$hom = $current[4]}#to be changed for CFTR
			else {$het = $current[4]}#to be changed for CFTR
		}
	}
	$new_file .= "$ligne\t$het\t$hom\n";#to be changed for CFTR	
}

close G;

open(H, ">$file.cftr.txt") or die $!;

print H $new_file;

close H;

print "$file.cftr.txt";

sub HELP_MESSAGE {
	print "\nUsage: perl -w  add_cftr_1.0.pl  -t path/to/annotated/file.txt -l patho/to/cftr_file.vcf.gz -e path/to/tabix \nSupports --help or --version\n\n
### This script puts CFTR custom data (custom IURC file obtained from Taulan's group (jess)) in an annotated txt variant file
### -c cftr vcf file
### -t file to add led
### -e path to tabix
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 28/10/2016\n"
}