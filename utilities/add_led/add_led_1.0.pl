#!/usr/bin/perl -w

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

############################################################################################################
##	Script to put a LED (Lgm Exome Database) to get occurence of variants in the lab		  ##
##	david baux 08/2016										  ##
##	david.baux@inserm.fr										  ##
############################################################################################################


my (%opts, $file, $led_file, $header, $new_file, $tabix);
getopts('l:t:e:', \%opts);

if ((not exists $opts{'l'}) || ($opts{'l'} !~ /LED_hg\d{2}_\d{4}_\d{2}_\d{2}\.vcf\.gz$/o) || (not exists $opts{'t'}) || ($opts{'t'} !~ /\.txt$/o) || (not exists $opts{'e'}) || ($opts{'e'} !~ /tabix$/o)) {
	&HELP_MESSAGE();
	exit
}

if ($opts{'t'} =~ /(.+)\.txt$/o) {$file = $1} #get file path and prefix
if ($opts{'l'} =~ /(.+LED_hg\d{2}_\d{4}_\d{2}_\d{2}\.vcf\.gz)$/o) {$led_file = $1} #get led file path
if ($opts{'e'} =~ /(.+tabix)$/o) {$tabix = $1} #get tabix path


my ($i, $j) = (0, 0);

open(G, "$file.txt") or die "$file.txt $!";

while (<G>) {
	chomp;
	my $ligne = $_;
	if (/Chr\sStart/o) {
		if ($file =~ /barcoded/o || $file =~ /merged/o) {$new_file = "$ligne\tLED#het/hem\tLED#hom\tLED URL\n";next;}
		else {$new_file = "$ligne\t.\t.\t.\t.\t.\t.\t.\t.\t.\tLED#het/hem\tLED#hom\tLED URL\n";next;}

	}
	my @line = split(/\t/, $ligne);
	my $k = 0;
	#my ($chr, $pos, $end, $ref, $alt) = (shift(@line), shift(@line), shift(@line), shift(@line), shift(@line));
	my ($chr, $pos, $end, $ref, $alt) = ($line[0], $line[1], $line[2], $line[3], $line[4]);
	shift(@line);
	if ($ref eq '-' || $alt eq '-') {
		foreach my $item (@line) {		
			if ($item =~ /chr[\dXYM]/o) {
				#$chr = $1;
				($pos, $ref, $alt) = ($line[$k+1], $line[$k+3], $line[$k+4]);
				#print "$chr-$pos-$ref-$alt\n";
				last;
			}
			$k++;
		}
	}
	#my ($chr, $pos, $end, $ref, $alt) = (shift(@line), shift(@line), shift(@line), shift(@line), shift(@line));
	if ($chr =~ /chr([\dXYM])/o) {$chr = $1}
	my ($het, $hom, $url) = (0, 0, '');
	my @led =  split(/\n/, `$tabix $led_file $chr:$pos-$pos`);
	#print "$tabix $led_file $chr:$pos-$pos\n";
	foreach (@led) {
		#print "$_\n";
		my @current = split(/\t/, $_);
		if (/\t$ref\t$alt\t/) {
			($het, $hom, $url) = &populate(\@current);
			#if ($current[5] eq 'homozygous') {$hom = $current[4]}
			#else {$het = $current[4]}
			#$url = "https://194.167.35.158/perl/led/variant.pl?var=$current[6]";
		}
		elsif (/\t$ref/) {#case ref with multiple entries (e.g. C,CAA) either in target file (case 1) of in led file (case 2)
			if ($alt =~ /,/o) {
				my @poss = split(/,/, $alt);
				foreach (@poss)	{
					if ($current[3] eq $_) {($het, $hom, $url) = &populate(\@current)}
				}
			}
			elsif ($current[3] =~ /,/o) {
				my @poss = split(/,/, $current[3]);
				foreach (@poss)	{
					if ($alt eq $_) {($het, $hom, $url) = &populate(\@current)}
				}
			}
		}
		
	}
	$new_file .= "$ligne\t$het\t$hom\t$url\n";
}

close G;

open(H, ">$file.led.txt") or die $!;

print H $new_file;

close H;

print "$file.led.txt";

sub HELP_MESSAGE {
	print "\nUsage: perl -w  add_led_1.0.pl  -t path/to/annotated/file.txt -l patho/to/led_file.vcf.gz -e path/to/tabix \nSupports --help or --version\n\n
### This script puts LED data in an annotated txt variant file
### -l led vcf file
### -t file to add led
### -e path to tabix
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 09/08/2016\n"
}
sub populate {
	my $current = shift;
	my ($hom, $het) = (0, 0);
	if ($current->[5] eq 'homozygous') {$hom = $current->[4]}
	else {$het = $current->[4]}
	return ($het, $hom, "https://194.167.35.158/perl/led/variant.pl?var=$current->[6]");	
}