import org.broadinstitute.gatk.queue.QScript
import org.broadinstitute.gatk.queue.extensions.gatk._
import org.broadinstitute.gatk.tools.walkers.indels.IndelRealigner.ConsensusDeterminationModel

class performIndelRealigner extends QScript {

	@Input(doc="Reference file for the bam files", shortName="R")
	var referenceFile: File = _

	@Input(doc="Input bam file", shortName="I")
	var bamFile: File = _

	@Input(doc="Interval file", shortName="targetIntervals")
	var intervalFile: File = _

	@Output(doc="Output bam file", shortName="o")
	var outputFile: File = _

	@Input(doc="List of known indels", shortName="known")
	var knownIndels: List[File] = Nil
	
	@Argument(doc="Number of available cores to define scatterCount", shortName="nbThreads")
    var nbThreads: Int = _

	def script() {
		val indelRealigner = new IndelRealigner
		indelRealigner.scatterCount = nbThreads
		indelRealigner.reference_sequence = referenceFile
		indelRealigner.input_file :+= bamFile
		indelRealigner.targetIntervals = intervalFile
		indelRealigner.knownAlleles = knownIndels
		indelRealigner.knownAlleles = knownIndels
		indelRealigner.maxReadsForRealignment = 200000
		indelRealigner.maxReadsInMemory = 1000000
		indelRealigner.consensusDeterminationModel = ConsensusDeterminationModel.USE_READS
		indelRealigner.out = outputFile
		add(indelRealigner)
	}
}

/*
export LD_LIBRARY_PATH=/cm/shared/apps/drmaa/gcc/64/1.0.7/lib/:$LD_LIBRARY_PATH
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S IndelRealigner.scala -I A135.bam -R ../../../refData/genome/hg19/hg19.fa -known ../../../refData/indelReference/hg19/1000G_phase1.indels.hg19.sites.vcf -known ../../../refData/indelReference/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -targetIntervals Intervals.list -jobRunner Drmaa -jobReport log/log.txt
indelRealigner.out = swapExt(bamFile, "bam", "realigned.bam")
*/


/*
to run
export LD_LIBRARY_PATH=/cm/shared/apps/drmaa/gcc/64/1.0.7/lib/:$LD_LIBRARY_PATH
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S testIndelRealigner.scala -I A34_S1.bam -R ../../../refData/genome/hg19/hg19.fa -known ../../../refData/indelReference/hg19/1000G_phase1.indels.hg19.sites.vcf -known ../../../refData/indelReference/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -targetIntervals Intervals.list -jobRunner Drmaa -run
*/