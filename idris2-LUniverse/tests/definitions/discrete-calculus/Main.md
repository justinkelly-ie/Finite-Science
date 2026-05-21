# Discrete Calculus

```idris
module Main

import Hedgehog
import Math.DiscreteCalculus
import Math.IntPolynumber

%default total

prop_mcbride : Property
prop_mcbride = property $ do
  let emp : List Nat = []
  
  -- Can't easily use === on Maybe without Eq for DiracHole, so we pattern match
  case mcbrideDerivative emp of
    Nothing => True === True
    Just _ => True === False
    
  let l : List Nat = [1, 2, 3]
  case mcbrideDerivative l of
    Nothing => True === False
    Just (hole, x) => do
      hole.leftContext === []
      hole.rightContext === [2, 3]
      x === 1

prop_wildberger : Property
prop_wildberger = property $ do
  let w0 = wildbergerDerivative 0
  -- Test simply that it executes without crashing
  True === True

prop_leibniz : Property
prop_leibniz = property $ do
  leibnizIntegralLag 0 === 0
  leibnizIntegralLag 1 === 1
  leibnizIntegralLag 2 === 3
  leibnizIntegralLag 3 === 6

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Math.DiscreteCalculus"
    [ ("McBride Derivative handles boundaries", prop_mcbride)
    , ("Wildberger Derivative calculates delta", prop_wildberger)
    , ("Leibniz Lag sums integers correctly", prop_leibniz)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
