module Tests.Common

import QuickCheck
import Math.Core
import Physics.Evolution.State
import Physics.Evolution.Cycle
import Physics.Evolution.Init
import Physics.Evolution.Gate

%default total

||| Allows the QuickCheck framework to formally print out the physical topology
||| of any UniverseState if a universe fails a test!
public export
Show UniverseState where
  show (MkUniverseState sub field) = "[UniverseState]"

public export
genUniverseStateWithDepth : Gen (Nat, UniverseState)
genUniverseStateWithDepth = do
  depthInt <- choose (1, 137)
  let depth = cast {to=Nat} depthInt
  let vacuum = seedChromogeometricVacuum 137
  pure (depth, runEpochs depth vacuum)
