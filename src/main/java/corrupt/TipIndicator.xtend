package corrupt

import org.eclipse.xtend.lib.annotations.Accessors

class TipIndicator {
  @Accessors(PUBLIC_GETTER, PACKAGE_SETTER)
  var boolean included = false
  
  @Accessors(PUBLIC_GETTER) val Cell cell
  @Accessors(PUBLIC_GETTER) val Locus locus
  
  new (Cell cell, Locus locus) {
    this.cell = cell
    this.locus = locus
  }
}