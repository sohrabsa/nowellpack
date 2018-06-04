package corrupt

import org.junit.Test

import bayonet.distributions.ExhaustiveDebugRandom

import static corrupt.CorruptUtils.syntheticCells
import static corrupt.CorruptUtils.syntheticLoci
import briefj.collections.Counter
import org.jgrapht.UndirectedGraph
import briefj.collections.UnorderedPair
import bayonet.distributions.Random

class UniformUnrootedTest {
  @Test
  def void test() {
    val nCells = 1
    val nLoci = 2
//    val exhaustive = new ExhaustiveDebugRandom
//    
//    var count = 0
//    while (exhaustive.hasNext) {
//      val sample = exhaustive.sampleUniformPerfectPhylo(syntheticCells(nCells), syntheticLoci(nLoci))
//      println(sample.tree)
//      println("pr = " + exhaustive.lastProbability)
//      count++
//      println("---")
//    }
//    println(count)
    
    
    val Counter counter = new Counter
    val rand = new Random(1)
    for (i : 0 ..< 10) {
      counter.incrementCount(CorruptUtils::sampleUniform(rand, 400), 1.0)
    }
    counter.normalize
    println(counter)
    println(counter.size)
  }
  
  
}