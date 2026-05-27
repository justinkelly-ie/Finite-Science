```idris
module Physics.LabelExtraction

import QuickCheck
import Simplex.Core
import Evolution.Gate
import Physics.Common

%default total

```
A simple property test ensuring that the generated UniverseState
successfully extracts a valid string label (verifying our topology can be printed).
```idris
public export
prop_spacetimeHasLabel : Property
prop_spacetimeHasLabel = forAll genUniverseStateWithDepth (MkFn (\(depth, univ) => 
    let label = show univ
    in property (length label > 0)
  ))
```
