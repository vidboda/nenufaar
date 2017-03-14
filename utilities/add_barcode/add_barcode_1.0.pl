#!/usr/bin/perl -wT

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

############################################################################################################
##	Script to put a barcode resuming genotypes in an annotated txt variant file with multiple samples ##
##	david baux 06/2016										  ##
##	david.baux@inserm.fr										  ##
############################################################################################################


my (%opts, $list, $file, $header, $vcf_file, $ext, $new_file);
getopts('v:t:', \%opts);

if ((not exists $opts{'v'}) || ($opts{'v'} !~ /\.vcf$/o) || (not exists $opts{'t'}) || ($opts{'t'} !~ /\.txt$/o)) {
	&HELP_MESSAGE();
	exit
}

if ($opts{'t'} =~ /(.+)\.txt$/o) {$file = $1} #get file path and prefix
if ($opts{'v'} =~ /(.+\.vcf)$/o) {$vcf_file = $1}



open(F, $vcf_file) or die "$vcf_file $!";

while (<F>) {
	chomp;
	if (/#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t(.+)$/o) {
		$list = $1;
	}
}
close F;

my ($i, $j) = (0, 0);

open(G, "$file.txt") or die "$file.txt $!";

while (<G>) {
	chomp;
	#header
	if (/Chr\tStart/o) {
		$header = $_;
		#get 'otherinfo' index
		my @header_line = split(/\t/, $header);
		foreach (@header_line) {$i++}
		#print $i;exit;
	}
	elsif (/chr[\dXY]/o) {
		my $ligne = $_;
		my @line = split(/\t/, $ligne);
		my $barcode;
		for (my $k = $i;$k <= $#line;$k++) {#read only data under and after 'otherinfo' column
			if ($j == 0) {
				#get number of tabs to correctly define headers
				if ($line[$k] =~ /^\d\/\d:/o || $line[$k] eq './.') {
					my $limit = ($k-$i)+1;
					for (my $l = 1;$l <= $limit;$l++) {$header .= "\t"}
					$header .= $list;
					$new_file = "$header\tBarcode\n";
					$j = 1;
				}
			}
			if ($line[$k] =~ /\d\/\d:/o || $line[$k] eq './.') {
				#-1 => ./. (no possible call)
				#0  => ref hom
				#1  => alt het (variant number if > 1)
				#2 alt hom (variant number if > 1)
				if ($line[$k] eq './.') {$barcode .= '-1:'}
				elsif ($line[$k] =~ /(\d)\/(\d):/o) {
					my ($al1, $al2) = ($1, $2);
					if ($al1 eq '0' && $al2 eq '0') {$barcode .= '0:'}
					elsif (($al1 eq '1' && $al2 eq '0') || ($al1 eq '0' && $al2 eq '1')) {$barcode .= '1:'}
					elsif (($al1 =~ /([2-9])/o && $al2 eq '0') || ($al1 eq '0' && $al2  =~ /([2-9])/o)) {$barcode .= "1($1):"}
					elsif ($al1 eq '1' && $al2 eq '1') {$barcode .= '2:'}
					elsif ($al1 =~ /[1-9]/o && $al2 =~ /[1-9]/o) {
						if ($al1 == $al2) {$barcode .= "2($al1):"}
						else {$barcode .= "1($al1)|1($al2):"}
					}
				}
			}
		}
		chop $barcode;
		$new_file .= "$ligne\t$barcode\n";
		#print "$barcode\n";
	}

}

close G;

open(H, ">$file.barcoded.txt") or die $!;

print H $new_file;

close H;

print "$file.barcoded.txt";

sub HELP_MESSAGE {
	print "\nUsage: perl -T  add_barcode_1.0.pl  -v path/to/vcf_file.vcf -t path/to/annotated/file.txt \nSupports --help or --version\n\n
### This script puts a barcode resuming genotypes in an annotated txt variant file with multiple samples
### -v vcf file, annotated or not
### -t file to add barcode
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 05/07/2016\n"
}
