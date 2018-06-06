package corrupt

import java.util.List
import blang.runtime.SampledModel
import bayonet.distributions.ExhaustiveDebugRandom
import java.util.LinkedHashMap
import java.util.Map
import static extension corrupt.SplitSampler.sampleInPlace

import java.util.ArrayList
import static extension corrupt.CorruptExtensionUtils.*
import static corrupt.CorruptStaticUtils.*
import corrupt.Synthetic
import blang.io.GlobalDataSource
import blang.types.Plated
import blang.types.StaticUtils
import bayonet.distributions.Random
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.runtime.Observations
import blang.types.internals.SimplePlate
import blang.mcmc.internals.SamplerBuilder
import blang.types.Plate
import blang.core.RealVar

class EnumerationUtils {
  
  def static List<SampledModel> enumerateUniformModels(int nCells, int nLoci) {
    val phylo = new PerfectPhylo(syntheticCells(nCells), syntheticLoci(nLoci)) 
    val current = new SampledModel(new Uniform.Builder().setPhylo(phylo).build)
    val result = new ArrayList
    val exhaustive = new ExhaustiveDebugRandom
    while (exhaustive.hasNext) {
      val copy = current.duplicate
      sampleNonUniform(exhaustive, (copy.model as Uniform).phylo)
      result.add(copy)
    }
    return result 
  }
  
  def static syntheticModel(int nCells, int nLoci, Plated<RealVar> observations) {
    return new Synthetic.Builder()
      .setData(GlobalDataSource.empty)
      .setCells(new SimplePlate("cells", syntheticCells(nCells))) 
      .setLoci( new SimplePlate("loci",  syntheticLoci(nLoci))) 
      .setObservations(observations)
      .build 
  }
  
  def static syntheticModel(int nCells, int nLoci) {
    return syntheticModel(nCells, nLoci, Plated::latent("observations", [StaticUtils::latentReal]))
  }
  
  def static List<SampledModel> enumerateSyntheticModels(int nCells, int nLoci) {
    val model = syntheticModel(nCells, nLoci, generateObservations(nCells, nLoci))
    var sModel = new SampledModel(model)
    
    val result = new ArrayList
    val exhaustive = new ExhaustiveDebugRandom
    while (exhaustive.hasNext) {
      // freeze observation
      var copy = sModel.duplicate
      val observations = new Observations
      observations.markAsObserved((copy.model as Synthetic).observations)
      sampleNonUniform(exhaustive, (copy.model as Synthetic).phylo)
      val graphAnalysis = new GraphAnalysis(copy.model, observations)
      copy = new SampledModel(graphAnalysis, SamplerBuilder.build(graphAnalysis), null)
      result.add(copy)
    }
    return result 
  }
  
  def static generateObservations(int nCells, int nLoci) {
    val model = syntheticModel(nCells, nLoci)
    var sModel = new SampledModel(model)
    // do forward simulation
    sModel.forwardSample(new Random(1), false)
    println("Tree used to generate data:\n" + model.phylo)
    println("Data:\n" + model.observations)
    return model.observations
  }
  
  def static private void sampleNonUniform(ExhaustiveDebugRandom rand, PerfectPhylo phylo) {
    for (locus : phylo.loci)
      phylo.tree.collapseEdge(locus) 
    for (locus : phylo.loci) 
      phylo.tree.sampleInPlace(locus, missingTips(phylo.tree.cells), rand)
    phylo.updateAllSplits
  }
  
  def static private Map<Cell, SubtreeLikelihood> missingTips(List<Cell> cells) {
    val result = new LinkedHashMap
    for (cell : cells)
      result.put(cell, SubtreeLikelihood::missingTip)
    return result
  }
}