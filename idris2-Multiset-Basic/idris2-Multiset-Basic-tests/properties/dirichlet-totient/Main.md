### Dirichlet Totient

```idris
module Main
import Hedgehog
import MSet1
import Data.List

gcdNat : Nat -> Nat -> Nat
gcdNat a 0 = a
gcdNat a b = gcdNat b (fromInteger ((cast a) `mod` (cast b)))

totient : Nat -> Nat
totient k = length (filter (\x => gcdNat k x == 1) [1..k])

repeatElements : Nat -> Nat -> List MSet1
repeatElements count val = replicate count (fromNat val)

totientBox : Nat -> MSet1
totientBox n = fromList (concatMap (\k => repeatElements (totient k) k) [1..n])

identityBox : Nat -> MSet1
identityBox n = fromList (concatMap (\k => repeatElements k k) [1..n])

zetaBox : Nat -> MSet1
zetaBox n = fromList (map fromNat [1..n])

prop_zeta_totient_id : Property
prop_zeta_totient_id = property $ do
  n <- forAll (nat (linear 1 30))
  truncate n (carret (zetaBox n) (totientBox n)) === identityBox n

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Zeta^Totient = Identity" [ ("prop", prop_zeta_totient_id) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
