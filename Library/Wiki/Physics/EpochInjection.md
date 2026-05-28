```idris
module Physics.EpochInjection

import QuickCheck
import Simplex.Core
import Evolution.Gate
import Evolution.Init
import Evolution.Cycle
import Physics.Common
import Physics.DimensionalCausality

import Physics.System.CosmicPartition

%default total

```
An injected starting Universe: Skipping the Vacuum and starting exactly
at Phase 2: EXPANSION (Baryogenesis / MatterGate).
```idris
public export
baryogenesisEpoch : UniverseState
baryogenesisEpoch = runEpochs 2 (seedChromogeometricVacuum (cast (calculateGridLimit constructPrimorialGrid)))
```
