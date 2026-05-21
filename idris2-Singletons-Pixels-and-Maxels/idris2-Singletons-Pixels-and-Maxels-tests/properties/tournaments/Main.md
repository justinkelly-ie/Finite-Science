### Tournaments

```idris
module Main
import Hedgehog
import MSet1
import Base
import Combinatorics

genTournament : Gen Maxel
genTournament = do
  -- A simple hardcoded tournament on 3 nodes: 1->2, 2->3, 1->3
  pure $ MkMaxel [
      MkPix (fromNat 1) (fromNat 2),
      MkPix (fromNat 2) (fromNat 3),
      MkPix (fromNat 1) (fromNat 3)
    ]

prop_is_tournament : Property
prop_is_tournament = property $ do
  m <- forAll genTournament
  isSet m === True
  isIrreflexive m === True
  isAntiSymmetric m === True
  isTotal m === True

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Tournaments"
    [ ("prop_is_tournament", prop_is_tournament) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
