module Math.BoxNat

import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.Multiset.Labeled

%default total

||| BoxNat based on LabeledMSet
public export
0 BoxNat : Type
BoxNat = LabeledMSet () ()
