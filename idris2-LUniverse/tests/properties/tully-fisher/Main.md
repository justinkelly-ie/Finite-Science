# Tully-Fisher Rotation Limits

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.Multiset
import Math.MaxelNL
import Physics.Findings.TullyFisherRelation

%default covering

prop_tully_fisher_constant : Property
prop_tully_fisher_constant = property $ do
  let supp = MkMultiset [(MkPixelNL 1 2, 50)]
  let state = primordialDarkPlusMatter supp
  
  -- The flat rotation curve must hold
  assert (verifyTullyFisherLaw state)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Tully-Fisher"
    [ ("Velocity-Mass Power Law is structurally maintained", prop_tully_fisher_constant)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
