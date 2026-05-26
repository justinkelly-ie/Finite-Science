module Physics.Tests.Common

import Math.Core
import QuickCheck
import Physics.Evolution.State
import Physics.Evolution.Cycle
import Physics.Evolution.Gate
import Physics.Evolution.Init

%default total




||| Allows the QuickCheck framework to formally print out the physical topology
||| of any UniverseState if a universe fails a test!
public export
Show Math.Core.UniverseState where
  show (MkUniverseState sub field) = "[UniverseState]"

public export
genUniverseStateWithDepth : Gen (Nat, Math.Core.UniverseState)
genUniverseStateWithDepth = do
  depthInt <- choose (1, 137)
  let depth = cast {to=Nat} depthInt
  let vacuum = seedChromogeometricVacuum 137
  pure (depth, runEpochs depth vacuum)
