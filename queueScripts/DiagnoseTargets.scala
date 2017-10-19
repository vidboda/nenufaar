import org.broadinstitute.gatk.queue.QScript
import org.broadinstitute.gatk.queue.extensions.gatk._

class performDiagnoseTargets extends QScript {

	@Input(doc="Reference file for the bam files", shortName="R")
	var referenceFile: File = _

	@Input(doc="Input bam file", shortName="I")
	var bamFile: File = _

	@Input(doc="A file with a list of intervals to proccess.", shortName="L")
	var intervalFile: File = _

	@Output(doc="Output DT file", shortName="o")
	var outputFile: File = _

	@Argument(doc="output GATK TEMP directory", shortName="gatkOutputDir")
    var gatkOutputDir: String = "./"
		
	@Argument(doc="Number of available cores to define scatterCount", shortName="nbThreads")
    var nbThreads: Int = _

	def script() {

		val diagnoseTargets = new DiagnoseTargets
		diagnoseTargets.scatterCount = nbThreads
		//7 to get 12G per thread for WGS
		diagnoseTargets.reference_sequence = referenceFile
		diagnoseTargets.input_file :+= bamFile
		diagnoseTargets.intervals = if (intervalFile == null) Nil else List(intervalFile)
		//diagnoseTargets.out = outputFile
		diagnoseTargets.missing = new File(gatkOutputDir + swapExt(bamFile, ".sorted.dupMarked.realigned.recalibrated.compressed.bam", "_missing_intervals.list"))
		diagnoseTargets.out = outputFile

		add(diagnoseTargets)
	}
}


/*
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S DiagnoseTargets.scala -I A135.sorted.dupMarked.realigned.recalibrated.bam -R ../../../refData/genome/hg38/hg38.fa  -L dev/Intervals.list -o A135_DT.vcf -gatkOutputDir DIR_GATK/ -jobRunner Drmaa -jobReport log/log.txt
*/