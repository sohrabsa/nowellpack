package corrupt

import com.google.common.graph.MutableGraph
import com.google.common.graph.GraphBuilder
import static briefj.BriefCollections.pick
import java.util.List
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Accessors
import static java.util.Collections.emptyList
import com.google.common.graph.ElementOrder
import java.util.Collection

@Data class DirectedTree<T> { 
  @Accessors(NONE)
  val MutableGraph<T> graph = GraphBuilder.directed.allowsSelfLoops(false).nodeOrder(ElementOrder.insertion).build
  val T root
  
  def T parent(T node) {
    val iterator = graph.predecessors(node).iterator
    if (!iterator.hasNext) return null
    val result = iterator.next
    if (iterator.hasNext) throw new RuntimeException
    return result
  }
  
  def List<T> children(T node) {
    return new ArrayList(graph.successors(node))
  }
  
  def boolean isLeaf(T node) {
    return children(node).size === 0
  }
  
  def boolean hasNode(T node) {
    return graph.nodes.contains(node)
  }
  
  def Collection<T> nodes() { return graph.nodes }
  
  def List<T> collapseEdge(T bottomOfEdge) {
    val topOfEdge = parent(bottomOfEdge)
    if (topOfEdge === null) 
      throw new RuntimeException("This does not define an edge: no parent for " + bottomOfEdge)
    val movedChildren = children(bottomOfEdge)
    for (child : movedChildren) {
      graph.removeEdge(bottomOfEdge, child)
      graph.putEdge(topOfEdge, child)
    }
    graph.removeNode(bottomOfEdge) 
    return movedChildren
  }
  
  def void addEdge(T existingTopNode, T newBottomNode) {
    addEdge(existingTopNode, newBottomNode, emptyList)
  }

  def void addEdge(T existingTopNode, T newBottomNode, List<T> movedChildren) {
    if (!graph.addNode(newBottomNode))
      throw new RuntimeException("Should not be in the tree: " + newBottomNode)
    if (!graph.nodes.contains(newBottomNode))
      throw new RuntimeException("Should be in the tree: " + existingTopNode) 
    graph.putEdge(existingTopNode, newBottomNode)
    for (child : movedChildren) {
      if (!graph.removeEdge(existingTopNode, child))
        throw new RuntimeException
      graph.putEdge(newBottomNode, child)
      graph.removeEdge(existingTopNode, child)
    }
  }
}