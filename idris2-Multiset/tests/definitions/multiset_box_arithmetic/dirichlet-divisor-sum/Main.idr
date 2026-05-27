module Main
import Hedgehog
import Math.UnaryMultiset
import Data.List

isDivisibleBy : Integer -> Integer -> Bool
isDivisibleBy a b = (a `mod` b) == 0

divisors : Nat -> List Nat
divisors k = filter (\d => isDivisibleBy (cast k) (cast d)) [1..k]

dSum : Nat -> Nat
dSum k = foldl (+) 0 (divisors k)

repeatElements : Nat -> Nat -> List (UnaryMultiset (UnaryMultiset ()))
repeatElements count val = replicate count (Math.UnaryMultiset.fromNat val)

divisorSumBox : Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
divisorSumBox n = fromList (concatMap (\k => repeatElements (dSum k) k) [1..n])

identityBox : Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
identityBox n = fromList (concatMap (\k => repeatElements k k) [1..n])

zetaBox : Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
zetaBox n = fromList (map Math.UnaryMultiset.fromNat [1..n])

prop_zeta_id_dsum : Property
prop_zeta_id_dsum = property $ do
  n <- forAll (nat (linear 1 30))
  truncate n (carret (zetaBox n) (identityBox n)) === divisorSumBox n

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Zeta^Identity = Divisor Sum" [ ("prop", prop_zeta_id_dsum) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
