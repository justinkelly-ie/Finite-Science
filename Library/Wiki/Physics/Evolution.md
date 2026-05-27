# Evolution Engine Verification

This module provides the rigorous QuickCheck proofs for the physics evolution engine, specifically focusing on the phase transitions (Scale Ascensions).

```idris
module Physics.Evolution

import QuickCheck
import Math.Core
import Math.Multiset
import Physics.Evolution.Cycle
import Physics.Evolution.Clock
import Physics.Evolution.Transform
import Physics.Common

%default total
```

## Total Inner Polynomial Mass

Calculates the total inner polynomial mass (sum of all coefficients) of a state vector. This extracts the true quantum mass from the underlying `IntPolynumber` elements.

```idris
totalPolyLag : SparseMaxel -> Integer
totalPolyLag (MkSparseMaxel m) = 
  foldl (\acc, ((_, poly), count) => acc + count * multiplicityAll poly) 0 (multisetToList m)
```

## Ascension Mass Conservation

Verifies that ascending a scale perfectly preserves the total mass (Leibniz Lag) of the state vector. When the micro-history annihilates into a macro-node, all polynomial energy is structurally conserved. The integer mass invariant cannot be violated!

```idris
public export
prop_ascensionConservesMass : Property
prop_ascensionConservesMass = forAll genUniverseStateWithDepth (MkFn (\(depth, u) => 
  let targetNode = MkPixel 0 0
      ascendedField = ascendScale targetNode u.stateVector.maxelMap
      originalMass = totalPolyLag u.stateVector
      ascendedMass = totalPolyLag (MkSparseMaxel ascendedField)
  in property (originalMass == ascendedMass)))
```

## Empty Vacuum Anchor

Verifies that if a state vector is entirely empty, it can never trigger a topological ascension (because there is no geometric mass to cross the capacity limit).

```idris
public export
prop_emptyNeverAscends : Property
prop_emptyNeverAscends = property (canAscend Blue emptySubstrate emptySparseMaxel == False)
```
