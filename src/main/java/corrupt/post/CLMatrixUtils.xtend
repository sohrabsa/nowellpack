package corrupt.post

import bayonet.distributions.Random
import corrupt.PerfectPhylo
import blang.distributions.Normal

import static blang.types.StaticUtils.*
import bayonet.distributions.Multinomial
import briefj.BriefIO
import java.io.File
import java.util.ArrayList
import corrupt.Locus
import corrupt.Cell
import blang.inits.providers.CoreProviders
import xlinear.Matrix
import blang.distributions.Generators
import java.util.Set
import java.util.HashSet

class CLMatrixUtils {
  
  public static val String CELLS = "cells"
  public static val String LOCI = "loci"
  public static val String TIP_INCL_PRS = "tipInclusionProbabilities"
  
  static def void toCSV(CellLocusMatrix matrix, File f) {
    toCSV(matrix, f, null)
  }
  static def void toCSV(CellLocusMatrix matrix, File f, CellLocusMatrix reference) {
    val out = BriefIO.output(f)
    out.println('''«CELLS»,«LOCI»,«TIP_INCL_PRS»«IF reference !== null»,reference«ENDIF»''')
    for (cell : matrix.cells)
      for (locus : matrix.loci)
        out.println('''«cell»,«locus»,«matrix.get(cell, locus)»«IF reference !== null»,«reference.get(cell, locus)»«ENDIF»''')
    out.close
  }
  
  static def int locusEdgeDistance(PerfectPhylo phylo1, PerfectPhylo phylo2) {
    val s1 = locusEdges(phylo1)
    val s2 = locusEdges(phylo2)
    val union = new HashSet => [
      addAll(s1)
      addAll(s2)
    ]
    val intersection = new HashSet(s1)
    intersection.retainAll(s2)
    union.removeAll(intersection)
    return union.size
  }
  
  static def Set<Pair<Locus,Locus>> locusEdges(PerfectPhylo phylo) {
    val result = new HashSet
    for (top : phylo.loci)
      for (bottom : phylo.tree.children(top))
        switch (bottom) {
          Locus : result.add(top -> bottom)
        }
    return result
  }
  
  static def double distance(PerfectPhylo phylo1, PerfectPhylo phylo2) {
    return distance(fromPhylo(phylo1), fromPhylo(phylo2))
  }
  
  static def double distance(SimpleCLMatrix mtx1, SimpleCLMatrix mtx2) {
    checkCompatible(mtx1, mtx2)
    return distance(mtx1.matrix, mtx2.matrix)
  }
  
  static def double distance(Matrix mtx1, Matrix mtx2) {
    return delta(mtx1, mtx2) / mtx1.nEntries
  }
  
  static def double delta(Matrix mtx1, Matrix mtx2) {
    val diff = mtx1 - mtx2
    return diff.nonZeroEntries().map[Math.abs(it)].sum()
  }
  
  static def SimpleCLMatrix fromCSV(File f) {
    val cells = new ArrayList<Cell>
    val loci = new ArrayList<Locus>
    val values = new ArrayList<Double>
    for (line : BriefIO::readLines(f).indexCSV) {
      if (!line.containsKey(CELLS) || !line.containsKey(LOCI) || !line.containsKey(TIP_INCL_PRS))
        throw new RuntimeException
      cells.add(new Cell(line.get(CELLS)))
      loci.add(new Locus(line.get(LOCI)))
      values.add(CoreProviders::parse_double(line.get(TIP_INCL_PRS)))
    }
    val result = new SimpleCLMatrix(cells, loci)
    for (var int i = 0; i < cells.size; i++) 
      result.set(cells.get(i), loci.get(i), values.get(i))
    return result
  }
  
  static def SimpleCLMatrix fromPhylo(PerfectPhylo phylo) {
    val result = new SimpleCLMatrix(phylo.cells, phylo.loci)
    result += phylo 
    return result
  }
  
  static def ReadOnlyCLMatrix syntheticInclusionPrs(Random rand, PerfectPhylo phylo, double stdDev) {
    val syntheticInclusionPrs = new SimpleCLMatrix(phylo.cells, phylo.loci)
    val inclNormal = Normal::distribution(fixedReal(0.0), fixedReal(stdDev * stdDev))
    val exclNormal = Normal::distribution(fixedReal(1.0), fixedReal(stdDev * stdDev))
    for (locus : phylo.loci) {
      val tips = phylo.getTips(locus)
      for (cell : phylo.cells) {
        val dist = if (tips.get(cell)) inclNormal else exclNormal
        val observation = dist.sample(rand)
        val prs = newDoubleArrayOfSize(2)
        prs.set(0, exclNormal.logDensity(observation))
        prs.set(1, inclNormal.logDensity(observation))
        Multinomial::expNormalize(prs)
        syntheticInclusionPrs.set(cell, locus, prs.get(1)) 
      }
    }
    return ReadOnlyCLMatrix.readOnly(syntheticInclusionPrs)
  }
  
  static def ReadOnlyCLMatrix syntheticPerturbedBinaryMatrix(Random rand, PerfectPhylo phylo, double fpRate, double fnRate) {
    val syntheticInclusionPrs = new SimpleCLMatrix(phylo.cells, phylo.loci)
    for (locus : phylo.loci) {
      val tips = phylo.getTips(locus)
      for (cell : phylo.cells) {
        var indic = tips.get(cell)
        if (indic) {
          if (Generators::bernoulli(rand, fnRate))
            indic = false
        } else {
          if (Generators::bernoulli(rand, fpRate))
            indic = true
        }
        syntheticInclusionPrs.set(cell, locus, if (indic) 1.0 else 0.0) 
      }
    }
    return ReadOnlyCLMatrix.readOnly(syntheticInclusionPrs)
  }
  
  static def void checkCompatible(SimpleCLMatrix cl1, SimpleCLMatrix cl2) {
    if (cl1.cellsIdx != cl2.cellsIdx || cl1.lociIdx != cl2.lociIdx)
      throw new RuntimeException
  }
}