### Dirichlet Divisor Count

```idris
module Main
import Hedgehog
import MSet1
import Data.List

isDivisibleBy : Integer -> Integer -> Bool
isDivisibleBy a b = (a `mod` b) == 0

divisors : Nat -> List Nat
divisors k = filter (\d => isDivisibleBy (cast k) (cast d)) [1..k]

dCount : Nat -> Nat
dCount k = length (divisors k)

repeatElements : Nat -> Nat -> List MSet1
repeatElements count val = replicate count (fromNat val)

divisorCountBox : Nat -> MSet1
divisorCountBox n = fromList (concatMap (\k => repeatElements (dCount k) k) [1..n])

zetaBox : Nat -> MSet1
zetaBox n = fromList (map fromNat [1..n])

prop_zeta_zeta_dcount : Property
prop_zeta_zeta_dcount = property $ do
  n <- forAll (nat (linear 1 30))
  truncate n (carret (zetaBox n) (zetaBox n)) === divisorCountBox n

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Zeta^Zeta = Divisor Count" [ ("prop", prop_zeta_zeta_dcount) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
