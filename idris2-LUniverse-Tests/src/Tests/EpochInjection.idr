module Tests.EpochInjection

import QuickCheck
import Math.Core
import Physics.Evolution.Gate
import Physics.Evolution.Init
import Physics.Evolution.Cycle
import Tests.Common
import Tests.DimensionalCausality

%default total

||| An injected starting Universe: Skipping the Vacuum and starting exactly
||| at Phase 2: EXPANSION (Baryogenesis / MatterGate).
public export
baryogenesisEpoch : UniverseState
baryogenesisEpoch = runEpochs 2 (seedChromogeometricVacuum 137)
