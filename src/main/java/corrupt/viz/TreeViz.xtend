package corrupt.viz

import java.util.Map
import java.util.LinkedHashMap
import java.util.List
import java.util.Collection
import java.util.ArrayList
import corrupt.DirectedTree
import corrupt.CorruptStaticUtils
import corrupt.PerfectPhylo
import bayonet.distributions.Random
import corrupt.viz.PublicSize

class TreeViz<T> extends Viz {
  val T root
  val (T)=>Collection<T> tree // for each node, return the children
  public var (T)=>Number branchLengths = [1.0f]
  
  // Imagine root is at time zero, what is the age of the other nodes?
  private val Map<T,Float> times = new LinkedHashMap
  public val Map<T,Integer> tipIndices = new LinkedHashMap
  private val int nLeaves
  private var float depth = 0.0f
  
  def int tipIndex(T node) { return tipIndices.get(node) }
  
  new (T root, (T)=>List<T> tree, PublicSize size) {
    super(size)
    this.root = root
    this.tree = tree
    computeTimes(root, 0.0f)
    nLeaves = tipIndices(root, 0)
  }
  
  new (DirectedTree<T> t, PublicSize size) {
    this(t.root, [t.children(it)], size) 
  }
  
  private def void computeTimes(T node, float time) {
    times.put(node, time)
    depth = Math.max(depth, time)
    for (T child : children(node)) {
      computeTimes(child, time + branchAbove(node))
    }
  }
  
  private def int tipIndices(T node, int firstAvailable) {
    if (node.children.empty) {
      tipIndices.put(node, firstAvailable)
      return firstAvailable + 1
    }
    var available = firstAvailable
    for (T child : children(node)) {
      available = tipIndices(child, available)
    }
    return available
  }
  
  private def Collection<T> children(T node) {
    return tree.apply(node)
  }
  
  private def float branchAbove(T node) {
    return branchLengths.apply(node).floatValue
  }
  
  override draw() {
    draw(root)
  }
  
  private def float draw(T node) {
    strokeWeight(0.05f)
    if (children(node).size == 0) 
      return tipIndices.get(node) 
    val yAxes = new ArrayList
    for (child : children(node)) {
      val current = draw(child)
      yAxes.add(current) 
      val float bl = branchAbove(child).floatValue
      hLine(current, times.get(node), bl)
    }
    val smallestY = yAxes.min
    val largestY = yAxes.max
    vLine(times.get(node), smallestY, largestY - smallestY) 
    return (smallestY + largestY) / 2.0f
  }
  
  // the actual branch lengths
  private def void hLine(float y, float start, float length) {
    line(start, y + 0.5f, start + length, y + 0.5f)
  }
  
  private def void vLine(float x, float start, float length) {
    line(x, start + 0.5f, x, start + length + 0.5f)
  }
  
  override privateSize() {
    new PrivateSize(depth, nLeaves as float)
  }
  
  public static def void main(String [] args) { 
    val phylo = new PerfectPhylo(CorruptStaticUtils::syntheticCells(10), CorruptStaticUtils::syntheticLoci(10))
    phylo.sampleUniform(new Random(1))
    println(phylo.tree)
    new TreeViz(phylo.tree, fixWidth(200)).show
  }
}