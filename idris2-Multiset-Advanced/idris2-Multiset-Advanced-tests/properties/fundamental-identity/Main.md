# Fundamental Identity

```idris
module Main

import Math.UnaryMultiset
import QuickCheck
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

primePowerBox : Nat -> Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
primePowerBox p n = Math.UnaryMultiset.fromList (map Math.UnaryMultiset.fromNat (powersUpTo p n))

fiaLeft : Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
fiaLeft n = foldl (\acc, p => Math.UnaryMultiset.truncate n (Math.UnaryMultiset.carret acc (primePowerBox p n))) (Math.UnaryMultiset.fromList [Math.UnaryMultiset.fromNat 1]) (primesUpTo n)

box1ToN : Nat -> UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
box1ToN n = Math.UnaryMultiset.fromList (map Math.UnaryMultiset.fromNat [1 .. n])

record FIATest where
  constructor MkFIATest
  n : Nat

Show FIATest where
  show (MkFIATest n) = "FIATest(" ++ show n ++ ")"

Arbitrary FIATest where
  arbitrary = do
    n <- arbitrary {a=Int}; let n' = cast (mod (abs n) 15)
    pure (MkFIATest (S n'))
  coarbitrary _ = variant 0

prop_fia : Property
prop_fia = forAll {a = FIATest} {prop = Bool} arbitrary (MkFn (\t => 
  let left = fiaLeft t.n
      right = box1ToN t.n
  in left == right))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_fia
  putStrLn $ "prop_fia: " ++ res1.msg
```
