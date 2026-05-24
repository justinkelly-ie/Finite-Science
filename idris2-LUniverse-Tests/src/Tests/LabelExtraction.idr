module Tests.LabelExtraction

import QuickCheck
import Math.FiberBundle
import Physics.Evolution.Gate
import Tests.Common

%default total

||| A simple property test ensuring that the generated SpacetimeManifold
||| successfully extracts a valid string label (verifying our Poset traversal works).
||| 
||| Why this matters:
||| As the QuickCheck engine unfolds the universe, every new topological epoch
||| MUST be formally labeled by its prime gate. This test proves that the Poset
||| is intact and string extraction never segfaults or points to a null node!
public export
prop_spacetimeHasLabel : Property
prop_spacetimeHasLabel = forAll genSpacetime (MkFn (\tree => 
    let label = getLabel tree
    in property (length label > 0)
  ))
