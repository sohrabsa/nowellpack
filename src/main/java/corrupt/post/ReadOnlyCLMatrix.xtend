package corrupt.post

import com.rits.cloning.Immutable
import org.eclipse.xtend.lib.annotations.Data
import corrupt.Cell
import corrupt.Locus
import blang.inits.DesignatedConstructor
import blang.inits.Input
import java.io.File

@Immutable
@Data class ReadOnlyCLMatrix implements CellLocusMatrix {
  val CellLocusMatrix enclosed 
  
  private new(CellLocusMatrix enclosed) {
    this.enclosed = enclosed
  }
  
  def static ReadOnlyCLMatrix readOnly(CellLocusMatrix m) {
    if (m instanceof ReadOnlyCLMatrix) return m
    else return new ReadOnlyCLMatrix(m)
  }
  
  override getTipAsDouble(Cell cell, Locus locus) { enclosed.getTipAsDouble(cell, locus) }
  override getCells() { enclosed.cells }
  override getLoci() { enclosed.loci}
  
  @DesignatedConstructor
  public static def ReadOnlyCLMatrix create(
      @Input String path
  ) { 
    println("Loading tip inclusion probabilities...")
    return ReadOnlyCLMatrix::readOnly(CLMatrixUtils::fromCSV(new File(path)))    
  } 
}