# Partition Sizes

```idris
module Main

import Hedgehog
import Physics.FiberBundle Physics.Findings.CosmicPartition
import Data.List

%default total

prop_cosmic_partition_sizes : Property
prop_cosmic_partition_sizes = property $ do
  let grid = constructPrimorialGrid
  
  -- Verify the 27 visible matter states
  partitionSize grid.visibleMatter === 27
  
  -- Verify the 128 invisible dark matter states
  partitionSize grid.darkEnergy === 128
  
  -- Verify the 55 background Dark Matter states
  partitionSize grid.darkMatter === 55
  
  -- Verify the completely unified Primorial pool is exactly 210
  (partitionSize grid.visibleMatter + partitionSize grid.darkEnergy + partitionSize grid.darkMatter) === 210

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.FiberBundle"
    [ ("Cosmic Partition sizes are exact", prop_cosmic_partition_sizes)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
