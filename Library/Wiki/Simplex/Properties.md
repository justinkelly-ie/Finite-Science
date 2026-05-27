```idris
module Simplex.Properties

import QuickCheck
import Simplex.Core
import Math.Multiset
import Math.Chromogeometry
import Physics.Common

%default total

```
Verifies that merging two causal substrates strictly aggregates their Leibniz lag (causal density).
```idris
public export
prop_substrateMergeLag : Property
prop_substrateMergeLag = forAll genUniverseStateWithDepth (MkFn (\(depth1, u1) => 
  forAll genUniverseStateWithDepth (MkFn (\(depth2, u2) =>
    let mergedSub = mergeSubstrate u1.substrate u2.substrate
        expectedLag = substrateLag u1.substrate + substrateLag u2.substrate
    in property (substrateLag mergedSub == expectedLag)))))

```
Verifies that superposing two SparseMaxels perfectly preserves the total state lag (Quantum Probability / Mass).
```idris
public export
prop_superposeLag : Property
prop_superposeLag = forAll genUniverseStateWithDepth (MkFn (\(d1, u1) =>
  forAll genUniverseStateWithDepth (MkFn (\(d2, u2) =>
    let superposed = superposeStates u1.stateVector u2.stateVector
        expectedLag = stateLag u1.stateVector + stateLag u2.stateVector
    in property (stateLag superposed == expectedLag)))))

```
Verifies that an empty Substrate and an empty SparseMaxel are always topologically synchronised.
```idris
public export
prop_emptyVacuumSynchronised : Property
prop_emptyVacuumSynchronised = property (isSynchronised emptySubstrate emptySparseMaxel == True)
```
