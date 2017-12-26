import org.broadinstitute.gatk.queue.QScript
import org.broadinstitute.gatk.queue.extensions.gatk._

class performBaseRecalibration extends QScript {

	qscript =>
	// qscript now equals performBaseRecalibration.this

	@Input(doc="Reference file for the bam files", shortName="R")
	var referenceFile: File = _

	@Input(doc="Input bam file", shortName="I")
	var bamFile: File = _

	@Input(doc="n file with a list of intervals to proccess.", shortName="L", required=true)
	var intervals: File = _

	@Input(doc="List of known sites", shortName="knownSites")
	var knownSites: List[File] = Nil

	@Argument(doc="output BAM directory", shortName="outputDir")
    var outputDir: String = "./"

	@Argument(doc="output GATK TEMP directory", shortName="gatkOutputDir")
    var gatkOutputDir: String = "./"
		
	@Argument(doc="Number of available cores to define scatterCount", shortName="nbThreads")
    var nbThreads: Int = _

	def script() {

		val baseRecalibrator = new BaseRecalibrator
		baseRecalibrator.scatterCount = nbThreads
		baseRecalibrator.reference_sequence = referenceFile
		baseRecalibrator.input_file :+= bamFile
		//baseRecalibrator.intervals = intervalsFile
		baseRecalibrator.intervals = if (qscript.intervals == null) Nil else List(qscript.intervals)
		baseRecalibrator.knownSites = knownSites
		baseRecalibrator.knownSites = knownSites
		baseRecalibrator.knownSites = knownSites
		//baseRecalibrator.out = outputFile
		baseRecalibrator.out = new File(gatkOutputDir + swapExt(bamFile, "sorted.dupMarked.realigned.bam", "recal.table"))

		val printReads = new PrintReads
		printReads.scatterCount = nbThreads
		printReads.reference_sequence = referenceFile
		printReads.input_file :+= bamFile
		printReads.BQSR = baseRecalibrator.out
		printReads.DIQ
		printReads.out = new File(outputDir + swapExt(bamFile, "bam", "recalibrated.bam"))

		add(baseRecalibrator, printReads)
	}
}


/*
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S BaseRecalibrator.scala -I A135.sorted.dupMarked.realigned.bam -R ../../../refData/genome/hg38/hg38.fa  -L dev/Intervals.list -knownSites ../../../refData/indelReference/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz -knownSites ../../../refData/indelReference/hg38/Homo_sapiens_assembly38.known_indels.vcf.gz -knownSites ../../../refData/dbSNP/144_hg38/dbsnp_144.hg38.vcf.gz -outputDir . -gatkOutputDir DIR_GATK/ -jobRunner Drmaa -jobReport log/log.txt
indelRealigner.out = swapExt(bamFile, "bam", "realigned.bam")

SNP_PATH=refData/dbSNP/144_hg38/dbsnp_144.hg38.vcf.gz
    INDEL1=refData/indelReference/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
    INDEL2=refData/indelReference/hg38/Homo_sapiens_assembly38.known_indels.vcf.gz
*/
