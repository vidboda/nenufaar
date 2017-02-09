#!/usr/bin/perl -wT


####################################################################################################
########
########	script to compare VCF in order to assess different parameters for NGS pipeline
########	david baux 07/2015
########
####################################################################################################


### 	We need here the tsv file as in 1st version
###	but add a summary before - needed a new version because complete recoding
###	modified 1st column of each result from useles binary 0/1 with allele balance values
###	And added variant type (snv/indel)

###

###	Variant	Type	AB in VCF1	VCF1 filter	AB in VCF2	VCF2 filter....
###	chr_pos_ref_alt	indel/snv	0.233	PASS/R8...	0.337	PASS/R8/LowDP...
###	chr_pos_ref_alt	indel/snv	0.978	PASS/R8...	0.932	PASS/R8/LowDP...
###


use strict;
use Getopt::Std;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

my ($vars, %opts, $files, $totalvar);
getopts('n:', \%opts);

#bug when counting PASS and OTHER
#my ($o, $p) = (0, 0);

if ((not exists $opts{'n'}) || ($opts{'n'} < 2)) {
	&HELP_MESSAGE();
	exit
}
else {
	my ($headerone, $headertwo, $summary);
	for (my $i=0;$i<$opts{'n'};$i++) { #builds a hashref $files->{index} = ['path/to/vcf', hindex, nbvar, nbpass, nbother, nbna], index being 0,2,4 - hindex being 1,2,3...
		#$files{$ARGV[$i]} = $i*2;
		$files->{$i*2} = [$ARGV[$i], $i+1, '0', '0', '0', '0'];
		$headertwo .= "\tAB in VCF".($i+1)."\tVCF".($i+1)." filter";
		$headerone .= '##### VCF'.($i+1).': '.$ARGV[$i]."\n";
	}
	$summary = "\nVCF\tPASS\tOTHER\tNA\tTOTAL (PASS+OTHER)";
	foreach my $index (sort keys(%{$files})) {
		my $file = $files->{$index}[0];
		if (-e $file) {
			open(F, $file) or die $!;
			while (<F>) {
				if (/^#/o) {next}

				my @tab = split(/\t/, $_);
				my ($chr, $pos, $ref, $alt, $filter) = ($tab[0], $tab[1], $tab[3], $tab[4], $tab[6]);
				if ($chr !~ /^chr/o) {$chr = "chr$chr"}
				my $alt_count;
				my $ab = 0;
				if ($tab[8] =~ /:AD:/o) {
					#my @line = split(/\t/, $ligne);
					my @format_labels = split(/:/, $tab[8]); #get format labels
					my @format_value = split(/:/, $tab[9]); #get format values
					#look for AD index
					my $i = 0;
					foreach(@format_labels) {if (/AD/o) {last}$i++}
					my @value = split(/,/, $format_value[$i]);

					if ($#value == 1) {$alt_count = $value[1]}
					else {	#if multiple variants at a given site we cumulate alt depth
						for (my $j=1;$j<=$#value;$j++) {$alt_count .= $value[$j]}
					}
					$ab = sprintf('%.3f', ($alt_count/($alt_count+$value[0])));	#AB calculation
				}

				my $type = 'snv';
				if ($ref !~ /^[ATGC]$/o || $alt !~ /^[ATGC]$/o) {$type = 'indel'}



				if (exists $vars->{"$chr-$pos-$ref-$alt-$type"}) {#if var exists, just complete entry
					&fill_table($chr, $pos, $ref, $alt, $filter, $index, $ab, $type, 'b');
				}
				else {#create variant
					$vars->{"$chr-$pos-$ref-$alt-$type"} = [];

					for (my $i=0;$i<($opts{'n'}*2);$i+=2) { #we want to create ['0', 'NA', '0', 'NA',...] for each vcf for the considered variant
						&fill_table($chr, $pos, $ref, $alt, 'NA', $i, '0', $type, 'a');
					}

					&fill_table($chr, $pos, $ref, $alt, $filter, $index, $ab, $type, 'b');
					$totalvar++;
				}

			}

		}
		else {
			die "\nCould not find $file\n"
		}
	}

	# determining #NA for each VCF needs a complete hash, so done outside main loop
	foreach my $index (sort {$a <=> $b} keys(%{$files})) {
		$files->{$index}[5] = $totalvar - ($files->{$index}[3] + $files->{$index}[4]); #	#NA = #total - (#PASS + #OTHER)
		$summary .= "\n$files->{$index}[1]\t$files->{$index}[3]\t$files->{$index}[4]\t$files->{$index}[5]\t$files->{$index}[2]";
	}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $month = ($mon+1);
	if ($month < 10) {$month = "0$month"}
	if ($mday < 10) {$mday = "0$mday"}
	my $date =  (1900+$year).'_'.$month.'_'.$mday;

	open(G,'>'.$date.'_var_compared.txt') or die $!;
	print G "##### compare_vcfs.pl version 1.2 $date\n#####\n##### Total assessed variants: $totalvar\n\n$headerone\n$summary\n\nVariant\tType$headertwo\n";

	foreach my $variants (sort keys(%{$vars})) {
		$variants =~ /^(.+)-(snv|indel)$/o;
		print G "$1\t$2";
		#print G $variants;
		foreach (@{$vars->{$variants}}) {print G "\t$_"}
		print G "\n";
	}

}

#print "\n\nDEBUG: $o variant records\n\n";


sub fill_table {
	my ($chr, $pos, $ref, $alt, $filter, $index, $value, $type, $round) = @_;
	$vars->{"$chr-$pos-$ref-$alt-$type"}[$index] = $value;
	$vars->{"$chr-$pos-$ref-$alt-$type"}[$index+1] = $filter;
	#if ($value ne 'i') {#BUG FIX 12/08/2016 thks to charles - some variants were omitted
	if ($round eq 'b') {	#not to be done at variant creation
		#$o++;
		$files->{$index}[2]++;	#increments total variant
		if ($filter eq 'PASS') {$files->{$index}[3]++} #increments # of PASS
		else {$files->{$index}[4]++}	#increments number of OTHER
	}
}


sub HELP_MESSAGE {
	print "\nUsage: ./compare_vcfs -n number_of_vcfs_to_compare /path/to/vcf1 /path/to/vcf2 /path/to/vcfx...\nn: must be > 1\nSupports --help or --version\n\n
### We just build a tsv which will look like\n
###	VCF index	#PASS	#OTHER	#NA	#TOTAL (PASS+OTHER)
###	1	x	y	z	g
###	2	f	r	lk	b...
###
###	Then details
###
###	Variant	Type	AB in VCF1	VCF1 filter	AB in VCF2	VCF2 filter....
###	chr_pos_ref_alt	indel/snv	0.233	PASS/R8...	0.337	PASS/R8/LowDP...
###	chr_pos_ref_alt	indel/snv	0.978	PASS/R8...	0.932	PASS/R8/LowDP...\n
###	and give some basic statistics on the different VCF (# of PASS, etc)\n\n"
}

sub VERSION_MESSAGE {
	print "\nVersion 1.2 07/2015\n"
}
