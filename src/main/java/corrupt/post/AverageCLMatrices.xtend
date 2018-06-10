package corrupt.post

import corrupt.PerfectPhylo

import static extension corrupt.post.CLMatrixUtils.toCSV
import briefj.BriefIO
import java.io.File
import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.util.Optional
import blang.inits.DefaultValue

class AverageCLMatrices extends Experiment {
  
  @Arg File csvFile
  
  @Arg
  Optional<File> referenceTree
  
  @Arg 
  @DefaultValue("value")
  String field ="value"
  
  public static val OUTPUT_NAME = "average.csv"
  override run() {
    if (referenceTree.present)
      parsedTreeIndicators = CLMatrixUtils::fromPhylo(PerfectPhylo::parseNewick(referenceTree.get)) 
    averageTipIndicators(BriefIO.readLines(csvFile).indexCSV.map[new PerfectPhylo(it.get(field))])
    result.toCSV(results.getFileInResultFolder(OUTPUT_NAME))
  }
  
  def static void main(String [] args) {
    Experiment.start(args)
  }
  
  var SimpleCLMatrix parsedTreeIndicators = null
  var SimpleCLMatrix result = null
  
  /**
   * Null if empty.
   */
  def void averageTipIndicators(Iterable<PerfectPhylo> phylos) {
    var distanceOutput = if (referenceTree === null) null else results.getAutoClosedBufferedWriter("distances.csv")
    var count = 0
    for (phylo : phylos) {
      
      if (result === null) 
        result = new SimpleCLMatrix(phylo.cells, phylo.loci)
      result += phylo
      if (parsedTreeIndicators !== null)
        distanceOutput.append(distance(parsedTreeIndicators, result) + "\n")
      count++
    }
    if (result !== null)
      result /= count
  }
  
  def double distance(SimpleCLMatrix refTree, SimpleCLMatrix matrix) {
    val diff = refTree.matrix - matrix.matrix
    return diff.nonZeroEntries().map[double value | Math.abs(value)].sum() / diff.nEntries
  }
  

  
}