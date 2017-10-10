import org.broadinstitute.gatk.queue.QScript
import org.broadinstitute.gatk.queue.extensions.gatk._
import org.broadinstitute.gatk.tools.walkers.genotyper.GenotypingOutputMode
import org.broadinstitute.gatk.utils.downsampling.DownsampleType

class performHaplotypeCaller extends QScript {

	@Input(doc="Reference file for the bam files", shortName="R")
	var referenceFile: File = _

	@Input(doc="Input bam file", shortName="I")
	var bamFile: File = _

	@Input(doc="Interval file", shortName="L")
	var intervals: File = _

	@Input(doc="SNP file", shortName="D")
	var snpFile: File = _

	@Output(doc="Output vcf file", shortName="o")
	var outputFile: File = _

	//@Argument(doc="The minimum phred-scaled confidence threshold at which variants should be called", shortName="stand_emit_conf")
	//var standEmitConf: Int = _

	@Argument(doc="The minimum phred-scaled confidence threshold at which variants should be emitted (and filtered with LowQual if less than the calling threshold)", shortName="stand_call_conf")
    var standCallConf: Int = _

	@Argument(doc="List of Filters", shortName="A")
	var annot: List[String] = Nil
	
	@Argument(doc="Number of available cores to define scatterCount", shortName="nbThreads")
    var nbThreads: Int = _

	def script() {
		val haplotypeCaller = new HaplotypeCaller
		haplotypeCaller.scatterCount = nbThreads
		haplotypeCaller.reference_sequence = referenceFile
		haplotypeCaller.input_file :+= bamFile
		haplotypeCaller.intervals = if (performHaplotypeCaller.this.intervals == null) Nil else List(performHaplotypeCaller.this.intervals)
		haplotypeCaller.dbsnp = snpFile
		//haplotypeCaller.stand_emit_conf = standEmitConf - removed in GATK 3.8
		haplotypeCaller.stand_call_conf = standCallConf
		haplotypeCaller.genotyping_mode = GenotypingOutputMode.DISCOVERY
		haplotypeCaller.maxAltAlleles = 10
		haplotypeCaller.minPruning = 1
		haplotypeCaller.dt = DownsampleType.NONE
		haplotypeCaller.A = annot
		haplotypeCaller.A = annot
		haplotypeCaller.out = outputFile
		add(haplotypeCaller)
	}
}

/*
export LD_LIBRARY_PATH=/cm/shared/apps/drmaa/gcc/64/1.0.7/lib/:$LD_LIBRARY_PATH
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S HaplotypeCaller.scala -I dev/A135.bam -R ../../../refData/genome/hg19/hg19.fa -D ../../../refData/dbSNP/138/CORRECT_dbsnp_138.hg19.vcf -L dev/Intervals.list -o dev/A.135_hc.vcf -stand_emit_conf 10 -stand_call_conf 30 -A AlleleBalanceBySample -A ReadPosRankSumTest -jobRunner Drmaa -jobReport log/log.txt
*/
