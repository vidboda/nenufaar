import org.broadinstitute.gatk.queue.QScript
import org.broadinstitute.gatk.queue.extensions.gatk._

class performVariantFiltration extends QScript {

	@Input(doc="Reference file for the bam files", shortName="R")
	var referenceFile: File = _

	@Input(doc="Input bam file", shortName="V")
	var vcfFile: File = _

	@Output(doc="Output bam file", shortName="o")
	var outputFile: File = _

	@Argument(doc="SNP file", shortName="dcov")
	var downCov: Int = _

	@Argument(doc="List of Filter Expressions", shortName = "filterExpression")
        var filterExpressions: List[String] = Nil

	@Argument(doc="List of Filter Names", shortName="filterName")
	var filterNames: List[String] = Nil

	def script() {
		val variantFiltration = new VariantFiltration
		variantFiltration.scatterCount = 28
		variantFiltration.reference_sequence = referenceFile
		variantFiltration.V = vcfFile
		variantFiltration.dcov = downCov
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.filterExpression = filterExpressions
		variantFiltration.filterName = filterNames
		variantFiltration.out = outputFile
		add(variantFiltration)
	}
}

/*
export LD_LIBRARY_PATH=/cm/shared/apps/drmaa/gcc/64/1.0.7/lib/:$LD_LIBRARY_PATH
java -Djava.io.tmpdir=tmp -jar -Xmx48g ../../Queue/3.5/Queue.jar -S VariantFiltration.scala -V A135.vcf -R ../../../refData/genome/hg19/hg19.fa -dcov 1000 -o A.135_hc.vcf -filterExpression "DP < 10" -filterName "LowCoverage" -filterExpression "QUAL < 30.0" -filterName "LowQual" -filterExpression "QD < 1.5" -filterName "LowQD" -filterExpression "FS > 60.000" -filterName "StrandBias" -filterExpression "MQ < 10.00" -filterName "LowMappingQuality" -filterExpression "POLYX > 7" -filterName "R8" -jobRunner Drmaa -jobReport log/log.txt
*/
