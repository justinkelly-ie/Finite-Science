# Partition Sizes

```idris
module Main

import Hedgehog
import Universe.DarkPlusMatter
import Universe.CosmicPartition
import Data.List

%default total

prop_cosmic_partition_sizes : Property
prop_cosmic_partition_sizes = property $ do
  let grid = constructPrimorialGrid
  
  -- Verify the 27 visible matter states
  length grid.visibleMatter === 27
  
  -- Verify the 128 invisible dark matter states
  length grid.darkEnergy === 128
  
  -- Verify the 55 background Dark Matter states
  length grid.darkMatter === 55
  
  -- Verify the completely unified Primorial pool is exactly 210
  length (flattenCosmicPartition grid) === 210

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Universe.DarkPlusMatter"
    [ ("Cosmic Partition sizes are exact", prop_cosmic_partition_sizes)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
