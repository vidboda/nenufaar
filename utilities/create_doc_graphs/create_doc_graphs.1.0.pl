#!/usr/bin/perl -w

use strict;

use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

##########################################################################################
##	Script to create doc graphs with R based on GATK ouputs from IURC pipeline	##
##	generates R scripts then run them via Rscript					##
##	david baux 10/2015								##
##	david.baux@inserm.fr								##
##########################################################################################

my (%opts, $file, $new_file);
getopts('i:', \%opts);

if ((not exists $opts{'i'}) || ($opts{'i'} !~ /\.grp/o)) {
	&HELP_MESSAGE();
	exit
}

if ($opts{'i'} =~ /(.+)_BCD\.grp/o) {$file = $1} #get file path and prefix

open(F, $file.'_BCD.grp') or die $!;

while (<F>) {
	if ($_ !~ /^#/o) {
		my $line = $_;
		$line =~ s/\s+/,/og;
		$line =~ s/^,//og;
		$line =~ s/,$//og;
		$new_file .= "$line\n";
	}
}

close F;

open(G, '>'.$file.'_BCD.csv') or die $!;

print G $new_file;

close G;

#for QMI.grp
undef $new_file;

open(F, $file.'_QMI.grp') or die $!;

while (<F>) {
	if ($_ !~ /^#/o) {
		my $line = $_;
		$line =~ s/\s+/,/og;
		$line =~ s/,$//og;
		$new_file .= "$line\n";
	}
}

close F;

open(G, '>'.$file.'_QMI.csv') or die $!;

print G $new_file;

close G;

#generates R script

my $r = "
library(ggplot2)
grp<-read.table(\"".$file."_BCD.csv\", sep=\",\", header=TRUE)
ggplot(grp, aes(x=Coverage, y=Count)) + geom_histogram(stat=\"identity\") +
    labs(x=\"Depth Of Coverage\", y=\"Number Of Bases\") + theme_bw()
ggsave(\"".$file."_DOC_bases.png\", dpi=100)
doc<-read.table(\"".$file."_DoC.sample_interval_summary\", sep=\"\t\", header=TRUE)
ggplot(doc, aes(x=Target, y=average_coverage))  + geom_point(stat=\"identity\") +
    labs(x=\"Regions\", y=\"Depth Of Coverage\") + theme_bw()
ggsave(\"".$file."_DOC_regions.png\", dpi=100)
grp<-read.table(\"".$file."_QMI.csv\", sep=\",\", header=TRUE)
ggplot(grp, aes(x=INTERPRETATION)) + geom_histogram(stat=\"bin\") +
    labs(x=\"Reasons for bad coverage\", y=\"Number Of Regions\") + theme_bw()
ggsave(\"".$file."_bad_regions.png\", dpi=100)
";

open(H, ">$file.r") or die $!;

print H $r;

close H;

system "Rscript $file.r";


#for QMI.grp

open(F, $file.'_QMI.grp') or die $!;

while (<F>) {
	if ($_ !~ /^#/o) {
		my $line = $_;
		$line =~ s/\s+/,/og;
		$line =~ s/,$//og;
		$new_file .= "$line\n";
	}
}

close F;



sub HELP_MESSAGE {
	print "\nUsage: ./GATK_graphs.1.0.pl -i path/to/grp/file_BCD.grp \nSupports --help or --version\n\n
### This script converts GATK grp files to csv
### then generates R script to get graphs and prints them in 3 png files
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 13/11/2015\n"
}