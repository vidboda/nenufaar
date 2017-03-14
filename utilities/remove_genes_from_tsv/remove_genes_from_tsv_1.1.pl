#!/usr/bin/perl -wT

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

##########################################################################################################
##	Script to remove genes from an annotated file	(tsv format)					##
##	david baux 11/2015										##
##	david.baux@inserm.fr										##
##########################################################################################################



my (%opts, $list, $file, $cleaned, $file_list, $ext, $found);
getopts('l:f:', \%opts);

if ((not exists $opts{'l'}) || ($opts{'l'} !~ /\.txt/o) || (not exists $opts{'f'}) || ($opts{'f'} !~ /\.txt/o)) {
	&HELP_MESSAGE();
	exit
}
$ext = 'txt';
if ($opts{'l'} =~ /(.+)\.txt$/o) {$file_list = $1} #get file path and prefix
if ($opts{'f'} =~ /(.+)\.txt$/o) {$file = $1}



open(F, "$file_list.$ext") or die "$file_list $!";

while (<F>) {
	chomp;
	$list->{$_} = 0;
}
close F;

open(G, "$file.$ext") or die "$file $!";
while (<G>) {
	my $line = $_;
	my @vars = split(/\t/, $_);
	my @genes = split(/,/, $vars[6]);
	my $semaph = 0;
	foreach(@genes) {
		if (exists $list->{$_}) {$semaph = 1;$list->{$_}++;$found .= $line;}#il y a juste à mettre $found ici
	}
	if ($semaph == 0) {$cleaned .= $line}	
}
close G;

open(G, , ">$file.cleaned.txt") or die $!;

print G $cleaned;

close G;

#
#Inutile: tu reparcours le même fichier et tu fais exactement la même chose
#
#open(I, "$file.$ext") or die "$file $!";
#while (<I>) {
#	my $line = $_;
#	my @vars = split(/\t/, $_);
#	my @genes = split(/,/, $vars[6]);
#	foreach(@genes) {
#		if (exists $list->{$_}) {$found .= $line}
#	}
#}	
#
#close I;

open(I, , ">$file.founddetail.txt") or die $!;

print I $found;

close I;


open(H, , ">$file.found.txt") or die $!;

print H "0 means not found in annotation file\n";

foreach my $key (sort keys%{$list}) {print H "$key\t$list->{$key}\n"}

close G;

print "\nDone!!! output file: $file.cleaned.txt\nfound file: $file.found.txt and $file.founddetail.txt\n\n";

exit;


sub HELP_MESSAGE {
	print "\nUsage: ./remove_genes_from_tsv.1.0.pl -l path/to/gene_list.txt -f path/to/annotated/file.txt \nSupports --help or --version\n\n
### This script removes genes from an annotated file	(tsv format)	
### -l gene list (HGNC), txt file, one gene per line
### -f file to clean
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.1 28/06/2016\n"
}