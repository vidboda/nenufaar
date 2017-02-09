#!/bin/bash

# takes a BAM input file  sequenced with the desired design
# and 2 bed files for baits and targets - no extension for BEDs
#adapted from http://seqanswers.com/forums/showthread.php?t=14878

BAM=$1 #ex output/nrcce_negs/SU3813/24189/SU3813.bam
BAITS=$2 #ex Intervals/NS_NRCCE_112_baits
TARGETS=$3 #ex Intervals/NS_NRCCE_112_targets

#get the headers extracted from a bam file
#samtools view -H ${BAM} | grep -e @SQ  | tr -s ':chr' ':' > ${BAITS}_picard.intervals
samtools view -H ${BAM} | grep -e @SQ > ${BAITS}_picard.intervals
cp ${BAITS}_picard.intervals ${TARGETS}_picard.intervals

#convert bed file
awk 'BEGIN { OFS="\t"} {print $1,$2+1,$3,$6,$4 }' ${BAITS}.bed | grep -v ^track | grep -v ^browser >> ${BAITS}_picard.intervals
#awk 'BEGIN { OFS="\t"} {print $1,$2+1,$3,$6,$4 }' ${BAITS}.bed | grep -v ^track | grep -v ^browser | tr -d '^chr' >> ${BAITS}_picard.intervals



#awk 'BEGIN { OFS="\t"} {print $1,$2+1,$3,$6,$4 }' ${TARGETS}.bed | grep -v ^track | grep -v ^browser | tr -d '^chr' >> ${TARGETS}_picard.intervals
awk 'BEGIN { OFS="\t"} {print $1,$2+1,$3,$6,$4 }' ${TARGETS}.bed | grep -v ^track | grep -v ^browser >> ${TARGETS}_picard.intervals


#then remove headers not linked with chr (by hand)
