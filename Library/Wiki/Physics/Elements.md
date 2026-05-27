```idris
module Physics.Elements

import QuickCheck
import Physics.Elements.Water
import Physics.Elements.Methane
import Physics.Elements.Carbon
import Simplex.Core
import Math.Chromogeometry

%default total

```
Verifies that the Water Molecule maintains its canonical bond quadrance
and its red-metric orthogonality regardless of evaluation context.
```idris
public export
prop_waterArchimedes : Property
prop_waterArchimedes = property ((bondQuadrance == 25) && (bondsRedPerpendicular == True))

```
Verifies the topological stability and mass-energy properties of Methane.
```idris
public export
prop_methaneStability : Property
prop_methaneStability = property ((redSignatureH1 + redSignatureH2 + redSignatureH3 + redSignatureH4 == 0) && (bondsBlueOrthogonal == True))

```
Verifies Carbon's algebraic properties.
```idris
public export
prop_carbonValence : Property
prop_carbonValence = property (carbonValence == 4)
```
