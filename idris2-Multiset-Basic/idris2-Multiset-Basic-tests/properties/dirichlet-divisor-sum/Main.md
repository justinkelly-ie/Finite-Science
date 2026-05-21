### Dirichlet Divisor Sum

```idris
module Main
import Hedgehog
import MSet1
import Data.List

isDivisibleBy : Integer -> Integer -> Bool
isDivisibleBy a b = (a `mod` b) == 0

divisors : Nat -> List Nat
divisors k = filter (\d => isDivisibleBy (cast k) (cast d)) [1..k]

dSum : Nat -> Nat
dSum k = foldl (+) 0 (divisors k)

repeatElements : Nat -> Nat -> List MSet1
repeatElements count val = replicate count (fromNat val)

divisorSumBox : Nat -> MSet1
divisorSumBox n = fromList (concatMap (\k => repeatElements (dSum k) k) [1..n])

identityBox : Nat -> MSet1
identityBox n = fromList (concatMap (\k => repeatElements k k) [1..n])

zetaBox : Nat -> MSet1
zetaBox n = fromList (map fromNat [1..n])

prop_zeta_id_dsum : Property
prop_zeta_id_dsum = property $ do
  n <- forAll (nat (linear 1 30))
  truncate n (carret (zetaBox n) (identityBox n)) === divisorSumBox n

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Zeta^Identity = Divisor Sum" [ ("prop", prop_zeta_id_dsum) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
