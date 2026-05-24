# Observer Tests

```idris
module Main

import Hedgehog
import Physics.Evolution.Observer

%default covering

prop_decoherence_threshold : Property
prop_decoherence_threshold = property $ do
  -- An Observer decoheres the system if lag > 137
  let mockIdentity : IdentityDiagonal Nat = MkDiagonal 1 Refl
  let observer : PersistentIdentity Nat 6 = MkIdentity Observer mockIdentity
  
  assert (not (enforceDecoherence observer 100))
  assert (enforceDecoherence observer 150)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Observer Mechanics"
    [ ("Decoherence Threshold respects 137 lag limit", prop_decoherence_threshold)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
