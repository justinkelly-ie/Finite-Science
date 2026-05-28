```idris
module Physics.Common

import QuickCheck
import Simplex.Core
import Evolution.State
import Evolution.Cycle
import Evolution.Init
import Evolution.Gate

import Physics.System.CosmicPartition

%default total

```
Allows the QuickCheck framework to formally print out the physical topology
of any UniverseState if a universe fails a test!
```idris
public export
Show UniverseState where
  show (MkUniverseState sub field) = "[UniverseState]"

public export
genUniverseStateWithDepth : Gen (Nat, UniverseState)
genUniverseStateWithDepth = do
  depthInt <- choose (1, 137)
  let depth = cast {to=Nat} depthInt
  let vacuum = seedChromogeometricVacuum (cast (calculateGridLimit constructPrimorialGrid))
  pure (depth, runEpochs depth vacuum)

public export
Arbitrary UniverseState where
  arbitrary = map snd genUniverseStateWithDepth
  coarbitrary = \_ => id
```
