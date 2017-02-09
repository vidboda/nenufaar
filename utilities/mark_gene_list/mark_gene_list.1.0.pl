#!/usr/bin/perl -wT

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

##########################################################################################################
##	Script to mark genes from an annotated file	(tsv format)																						##
##	david baux 10/2016																																									##
##	david.baux@inserm.fr																																								##
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
my $filter_name;
while (<F>) {
	chomp;
	if(/#(\w+)$/o) {$filter_name = $1;next;}
	$list->{$_} = $filter_name;
}
close F;

open(G, "$file.$ext") or die "$file $!";
my $marked;
while (<G>) {
	my $line = $_;
	if ($line =~ /^Chr\t/o) {$marked = "Marked Genes\t$line";next;}
	my @vars = split(/\t/, $_);
	my @genes = split(/,/, $vars[6]);
	my $semaph = 0;
	foreach(@genes) {
		if (exists $list->{$_}) {$marked .= "$list->{$_}\t$line";$semaph = 1;}
	}
	if ($semaph == 0) {$marked .= "\t$line"}
}
close G;

open(G, , ">$file.marked.txt") or die $!;

print G $marked;

close G;

print "$file.marked.txt";

exit;


sub HELP_MESSAGE {
	print "\nUsage: ./mark_gene_list.1.0.pl -l path/to/gene_list.txt -f path/to/annotated/file.txt \nSupports --help or --version\n\n
### This script marks genes from an annotated file	(tsv format)
### -l gene list (HGNC), txt file, one gene per line
### -f file to treat
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 03/10/2016\n"
}
