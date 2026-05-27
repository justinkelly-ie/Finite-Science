```idris
module Physics.EpochInjection

import QuickCheck
import Simplex.Core
import Physics.Evolution.Gate
import Physics.Evolution.Init
import Physics.Evolution.Cycle
import Physics.Common
import Physics.DimensionalCausality

import Physics.Findings.CosmicPartition

%default total

```
An injected starting Universe: Skipping the Vacuum and starting exactly
at Phase 2: EXPANSION (Baryogenesis / MatterGate).
```idris
public export
baryogenesisEpoch : UniverseState
baryogenesisEpoch = runEpochs 2 (seedChromogeometricVacuum (cast (calculateGridLimit constructPrimorialGrid)))
```
