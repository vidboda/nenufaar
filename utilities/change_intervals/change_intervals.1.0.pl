#!/usr/bin/perl -wT

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

##########################################################################################
##	Script to manipulate Intervals.list GATK files					##
##	david baux 10/2015								##
##	david.baux@inserm.fr								##
##########################################################################################



my (%opts, $file, $new_file, $bed_file, $window, $order);
getopts('i:n:o:', \%opts);

if ((not exists $opts{'i'}) || ($opts{'i'} !~ /\.list/o) || (not exists $opts{'n'}) || ($opts{'n'} !~ /\d+/o) || (not exists $opts{'o'}) || ($opts{'o'} !~ /(plus|minus)/o)) {
	&HELP_MESSAGE();
	exit
}

if ($opts{'i'} =~ /(.+)\.list$/o) {$file = $1} #get file path and prefix
if ($opts{'n'} =~ /(\d+)/o) {$window = $1}
if ($opts{'o'} =~ /(plus|minus)/o) {$order = $1}

$bed_file = "track name=modified_interval description=\"Modified Intervals.list file\" visibility=1\n";
open(F, "$file.list") or die "$file $!";
my ($chr, $start, $end, $i);
while (<F>) {
	$i++;
	if (/^(chr[\dXY]+):(\d+)\-(\d+)$/o) {($chr, $start, $end) = ($1, $2, $3)}
	if ($end > $start) {
		if ($order eq '+') {$start = $start - $window;$end = $end + $window}
		else {$start = $start + $window;$end = $end - $window}
	}
	else {print "TO FIX $chr:$start-$end line $i\n"}
	if ($end > $start) {$new_file .= "$chr:$start-$end\n";$bed_file .= "$chr\t$start\t$end\n"}
	else {print "WARNING end <= start line $i\n"}
}
close F;
my $name;
if ($order eq 'plus') {$name = "extended_$window"}
else {$name = "restricted_$window"}

open(G, , ">$file.$name.list") or die $!;

print G $new_file;

close G;

open(H, , ">$file.$name.bed") or die $!;

print H $bed_file;

close H;

print "\nDone!!! \noutput files:\n$file.$name.list\n$file.$name.bed\n\n";

exit;


sub HELP_MESSAGE {
	print "\nUsage: ./change_intervals.1.0.pl -i path/to/interval/file.list -n 50 -o plus\nSupports --help or --version\n\n
### This script manipulates coordinates of Intervals.list GATK files
### Input is a .list file, output is a .list file of format chr:start-end.
### Also generates UCSC track compatible file (BED)
### start - end are moved depending on -n and -o options
### ex -n 15 -o plus will extend interval of 15bp at both ends; -n 20 -o minus will restrict interval of 20 bp at both ends
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 18/10/2015\n"
}