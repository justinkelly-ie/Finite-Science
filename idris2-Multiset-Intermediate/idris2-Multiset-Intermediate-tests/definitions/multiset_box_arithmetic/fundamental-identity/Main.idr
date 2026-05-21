module Main

import Hedgehog
import Math.Multiset
import Data.List

isDivisibleBy : Integer -> Integer -> Bool
isDivisibleBy a b = (a `mod` b) == 0

isPrime : Nat -> Bool
isPrime 0 = False
isPrime 1 = False
isPrime 2 = True
isPrime n = not (any (\d => isDivisibleBy (cast n) d) (map cast [2 .. n `minus` 1]))

primesUpTo : Nat -> List Nat
primesUpTo n = filter isPrime [2 .. n]

powersUpTo : Nat -> Nat -> List Nat
powersUpTo p n = gen 1
  where
    gen : Nat -> List Nat
    gen curr = if curr > n then [] else curr :: gen (curr * p)

primePowerBox : Nat -> Nat -> MSet (MSet (MSet ()))
primePowerBox p n = fromList (map Math.Multiset.fromNat (powersUpTo p n))

fiaLeft : Nat -> MSet (MSet (MSet ()))
fiaLeft n = foldl (\acc, p => truncate n (carret acc (primePowerBox p n))) (fromList [Math.Multiset.fromNat 1]) (primesUpTo n)

box1ToN : Nat -> MSet (MSet (MSet ()))
box1ToN n = fromList (map Math.Multiset.fromNat [1 .. n])

prop_fia : Property
prop_fia = property $ do
  n <- forAll (nat (linear 1 30))
  let left = fiaLeft n
  let right = box1ToN n
  left === right

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Fundamental Identity of Arithmetic"
    [ ("prop_fia", prop_fia)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
