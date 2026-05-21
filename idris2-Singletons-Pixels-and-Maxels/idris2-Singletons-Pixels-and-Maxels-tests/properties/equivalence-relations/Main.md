### Equivalence Relations

```idris
module Main
import Hedgehog
import MSet1
import Base
import Combinatorics

genNode : Gen MSet1
genNode = do
  n <- nat (linear 1 3)
  pure $ fromNat n

-- A complete graph (clique) over a set of nodes is always an equivalence relation
genClique : Gen Maxel
genClique = do
  nodes <- list (linear 1 3) genNode
  -- Generate every possible a->b pair
  pure $ MkMaxel [ MkPix a b | a <- nodes, b <- nodes ]

prop_clique_is_equivalence : Property
prop_clique_is_equivalence = property $ do
  m <- forAll genClique
  isReflexive m === True
  isSymmetric m === True
  isTransitive m === True

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Equivalence Relations"
    [ ("prop_clique_is_equivalence", prop_clique_is_equivalence) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
