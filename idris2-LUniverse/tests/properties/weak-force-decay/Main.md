# Weak Force Decay

```idris
module Main

import Hedgehog
import Physics.FiberBundle Physics.WeakForce
import Math.MaxelNL
import Math.SignedUnaryMultiset
import Math.Multiset
import Math.UnaryMultiset

%default covering

prop_weak_force : Property
prop_weak_force = withTests 1 $ property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
  let gen10 = unfoldState 10 prim
  let gen11 = unfoldState 11 prim
  isDenominatorOverflow gen10 === False
  isDenominatorOverflow gen11 === True
  
  case triggerDecay gen11 of
    Nothing => True === False
    Just decay => do
      decay.quarkState.generation === 5
      decay.bondState.generation === 4
      decay.leptonState.generation === 2

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.WeakForce"
    [ ("Weak Force overflow and decay works correctly", prop_weak_force)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
