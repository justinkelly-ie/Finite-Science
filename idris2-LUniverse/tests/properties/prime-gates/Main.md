# Prime Gates

```idris
module Main

import Hedgehog
import Physics.FiberBundle Physics.QuantumGates
import Math.MaxelNL
import Math.SignedUnaryMultiset
import Math.Multiset
import Math.UnaryMultiset

%default covering

prop_prime_gates : Property
prop_prime_gates = withTests 1 $ property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
  
  -- Test n=2 (Background)
  let gen2 = unfoldState 2 prim
  isBackgroundGate gen2 === True
  activePrimeGate gen2 === 2
  
  -- Test n=3 (Matter)
  let gen3 = unfoldState 3 prim
  isMatterGate gen3 === True
  activePrimeGate gen3 === 3
  
  -- Test n=5 (Fractional Charge)
  let gen5 = unfoldState 5 prim
  isFractionalChargeGate gen5 === True
  activePrimeGate gen5 === 5
  
  -- Test n=7 (Time Dilation)
  let gen7 = unfoldState 7 prim
  isTimeDilationGate gen7 === True
  activePrimeGate gen7 === 7
  
  -- Test n=11 (Weak Force)
  let gen11 = unfoldState 11 prim
  isWeakForceGate gen11 === True
  activePrimeGate gen11 === 11
  
  -- Test non-prime transition (e.g. n=4)
  let gen4 = unfoldState 4 prim
  activePrimeGate gen4 === 0

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.FiberBundle"
    [ ("Prime gates are correctly identified", prop_prime_gates)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
