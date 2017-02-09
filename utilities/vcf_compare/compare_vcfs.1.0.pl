#!/usr/bin/perl -wT


####################################################################################################
########
########	script to compare VCF in order to assess different parameters for NGS pipeline
########	david baux 06/2015
########
####################################################################################################


### In this 1st verison we just build a tsv which will look like
###

###	Variant	Is in VCF1	VCF1 filter	Is in VCF2	VCF2 filter....
###	chr_pos_ref_alt	1/0	PASS/R8...	0/1	PASS/R8/LowDP...
###	chr_pos_ref_alt	1/0	PASS/R8...	0/1	PASS/R8/LowDP...


use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

my ($vars, $num_var, %opts);
getopts('n:', \%opts);

if ((not exists $opts{'n'}) || ($opts{'n'} < 2)) {
	&HELP_MESSAGE();
	exit
}

else {
	my %files;
	for (my $i=0;$i<$opts{'n'};$i++) { #builds a hash $files{'path/to/vcf'} = 'index', index being 0,1,2...
		$files{$ARGV[$i]} = $i*2;
	}
	
	foreach my $file (sort keys(%files)) {
		
		if (-e $file) {
			open(F, $file) or die $!;
			while (<F>) {
				if (/^#/o) {next}
				my @tab = split(/\t/, $_);
				my ($chr, $pos, $ref, $alt, $filter) = ($tab[0], $tab[1], $tab[3], $tab[4], $tab[6]);
				if (exists $vars->{"$chr-$pos-$ref-$alt"}) {#if var exists, just complete entry
					&fill_table($chr, $pos, $ref, $alt, $filter, $files{$file}, '1');
				}
				else {#create variant
					$vars->{"$chr-$pos-$ref-$alt"} = [];
					
					for (my $i=0;$i<($opts{'n'}*2);$i+=2) { #we want to create ['0', 'NA', '0', 'NA',...] for each vcf for the considered variant
						&fill_table($chr, $pos, $ref, $alt, 'NA', $i, '0');
						#$vars->{"$chr-$pos-$ref-$alt"}->[$i] = '0';
						#$vars->{"$chr-$pos-$ref-$alt"}->[$i+1] = 'NA';
					}				
					$num_var++;
					&fill_table($chr, $pos, $ref, $alt, $filter, $files{$file}, '1');
				}			
			}
		}
		else {
			die "\nCould not find $file\n"
		}	
	}
	
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $month = ($mon+1);
	if ($month < 10) {$month = "0$month"}
	if ($mday < 10) {$mday = "0$mday"}
	my $date =  (1900+$year).'_'.$month.'_'.$mday;
	
	open(G,'>'.$date.'_var_compared.txt') or die $!;
	print G "#####compare_vcfs.pl version 1.0 $date\n";	
	my $header;
	for (my $i=0;$i<$opts{'n'};$i++) {
		print G '#####VCF'.($i+1).': '.$ARGV[$i]."\n";
		$header .= "\tIs in VCF".($i+1)."?\tVCF".($i+1)." filter";
	}
	print G "$header\n";
	
	foreach my $variants (sort keys(%{$vars})) {
		print G $variants;
		foreach (@{$vars->{$variants}}) {print G "\t$_"}
		print G "\n";
	}
	
	print "\n\n$date\tnb vars: $num_var\n\n";
}



sub fill_table {
	my ($chr, $pos, $ref, $alt, $filter, $index, $value) = @_;
	$vars->{"$chr-$pos-$ref-$alt"}[$index] = $value;
	$vars->{"$chr-$pos-$ref-$alt"}[$index+1] = $filter;
}


sub HELP_MESSAGE {
	print "\nUsage: ./compare_vcfs -n number_of_vcfs_to_compare relative/path/to/vcf1 relative/path/to/vcf2 relative/path/to/vcfx...\nn: must be > 1\nSupports --help or --version\n\n
### In this 1st verison we just build a tsv which will look like\n
###	Variant	Is in VCF1	VCF1 filter	Is in VCF2	VCF2 filter....
###	chr_pos_ref_alt	0/1	PASS/R8...	0/1	PASS/R8/LowDP...
###	chr_pos_ref_alt	0/1	PASS/R8...	0/1	PASS/R8/LowDP...\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.0 06/2015\n"
}