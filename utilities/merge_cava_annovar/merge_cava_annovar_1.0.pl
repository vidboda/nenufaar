#!/usr/bin/perl -wT

use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

##########################################################################################################
##	Script to merge annotation files form cava and annovar, obtained from IURC_VFC_ANNOT_1.2.sh	##
##	david baux 11/2015										##
##	david.baux@inserm.fr										##
##########################################################################################################



my (%opts, $annovar, $cava, $ext, $cava_content, $header, $merged);
getopts('c:a:', \%opts);

if ((not exists $opts{'a'}) || ($opts{'a'} !~ /\.txt/o) || (not exists $opts{'c'}) || ($opts{'c'} !~ /\.txt/o)) {
	&HELP_MESSAGE();
	exit
}
$ext = 'txt';
if ($opts{'a'} =~ /(.+)\.txt$/o) {$annovar = $1} #get file path and prefix
if ($opts{'c'} =~ /(.+)\.txt$/o) {$cava = $1}



open(F, "$cava.$ext") or die "$cava $!";

while (<F>) {
	my $line = $_;
	chomp $line;
	if ($_ !~ /^ID/o) {
		my @var_cava = split(/\t/, $line);
		$cava_content->{"chr$var_cava[1]-$var_cava[2]-$var_cava[3]-$var_cava[4]"} = \@var_cava;
	}
	else {$header = $_}
}
close F;

#foreach my $key (sort keys (%{$cava_content})) {
#	print "$key - $cava_content->{$key}->[12]\n"
#}
#my ($chr_pos, $pos_pos, $ref_pos, $alt_pos, $end_pos) = (0, 69, 71, 72, 79);#columns chr pos ref alt in original vcf - moves when adding annovar fields
my ($chr_pos, $pos_pos, $ref_pos, $alt_pos, $end_pos) = (0, 108, 110, 111, 118);#columns chr pos ref alt in original vcf - moves when adding annovar fields
open(G, "$annovar.$ext") or die "$annovar $!";
while (<G>) {
	my $line = $_;
	chomp $line;
	if ($line =~ /chr/o) {
		my @annovar_content = split(/\t/, $line);
		my $insert = '';
		if (!$annovar_content[$end_pos]) {$insert = "\t\t"}		
		if (not exists $cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$annovar_content[$alt_pos]"}) {
			if ($annovar_content[$alt_pos] =~ /([ATCG]+),([ATCG]+)/o) {#for multiple variants at a given site
				if ($cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$1"}) {$merged .= $line.$insert."\t".join("\t", @{$cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$1"}})."\n"}
				elsif ($cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$2"}) {$merged .= $line.$insert."\t".join("\t", @{$cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$2"}})."\n"}
				else {print "$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$annovar_content[$alt_pos]\n"}
			}
			else {print "$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$annovar_content[$alt_pos]\n"}
		}
		else {
			$merged .= $line.$insert."\t".join("\t", @{$cava_content->{"$annovar_content[$chr_pos]-$annovar_content[$pos_pos]-$annovar_content[$ref_pos]-$annovar_content[$alt_pos]"}})."\n"
		}		
	}
	else {$header = $line."\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t".$header}
}
$merged = $header.$merged;

close G;

open(G, , ">$annovar.cava.merged.txt") or die $!;

print G $merged;

close G;

print "\nDone!!! output file: $annovar.cava.merged.txt\n\n";

exit;


sub HELP_MESSAGE {
	print "\nUsage: ./merge_cava_annovar.1.0.pl -a path/to/annovar/file.txt -c path/to/cava/file.txt \nSupports --help or --version\n\n
### This script merges annotation files form cava and annovar, obtained from IURC_VFC_ANNOT_1.1.sh
### -a annovar annotation file
### -c cava annotation file
### contact: david.baux\@inserm.fr\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 29/11/2015\n"
}