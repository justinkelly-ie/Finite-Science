# The Algebra of Anti-Multisets

We verify the properties of Anti-Multisets (AMSet).

```idris
module Main

import Math.Multiset
import Math.AMSet
import QuickCheck
import Data.So

%default covering

record AMSetSingle where
  constructor MkAMSetSingle
  posN : Nat; posXs : MSet Int
  negN : Nat; negXs : MSet Int

Show AMSetSingle where
  show (MkAMSetSingle p _ n _) = "(+" ++ show p ++ ", -" ++ show n ++ ")"

Arbitrary AMSetSingle where
  arbitrary = do
    p <- arbitrary {a=Int}; let p' = cast (mod (abs p) 5)
    n <- arbitrary {a=Int}; let n' = cast (mod (abs n) 5)
    pxs <- genMSet p'
    nxs <- genMSet n'
    pure (MkAMSetSingle p' pxs n' nxs)
  where
    genMSet : (n : Nat) -> Gen (MSet Int)
    genMSet 0 = pure Zero
    genMSet (S k) = do
      x <- arbitrary
      xs <- genMSet k
      pure (Add x xs)
  coarbitrary _ = variant 0

record AMSetPair where
  constructor MkAMSetPair
  a : AMSetSingle
  b : AMSetSingle

Show AMSetPair where
  show (MkAMSetPair a b) = "[" ++ show a ++ ", " ++ show b ++ "]"

Arbitrary AMSetPair where
  arbitrary = do
    a <- arbitrary
    b <- arbitrary
    pure (MkAMSetPair a b)
  coarbitrary _ = variant 0

record AMSetTriple where
  constructor MkAMSetTriple
  a : AMSetSingle
  b : AMSetSingle
  c : AMSetSingle

Show AMSetTriple where
  show (MkAMSetTriple a b c) = "[" ++ show a ++ ", " ++ show b ++ ", " ++ show c ++ "]"

Arbitrary AMSetTriple where
  arbitrary = do
    a <- arbitrary
    b <- arbitrary
    c <- arbitrary
    pure (MkAMSetTriple a b c)
  coarbitrary _ = variant 0

toAMSet : AMSetSingle -> AMSet Int
toAMSet s = MkAMSet (posXs s) (negXs s)

prop_addCommutative : Property
prop_addCommutative = forAll {a = AMSetPair} {prop = Bool} arbitrary (MkFn (\p => 
  Math.AMSet.addA (toAMSet (a p)) (toAMSet (b p)) == Math.AMSet.addA (toAMSet (b p)) (toAMSet (a p))))

prop_addAssociative : Property
prop_addAssociative = forAll {a = AMSetTriple} {prop = Bool} arbitrary (MkFn (\t =>
  Math.AMSet.addA (Math.AMSet.addA (toAMSet (a t)) (toAMSet (b t))) (toAMSet (c t)) == 
  Math.AMSet.addA (toAMSet (a t)) (Math.AMSet.addA (toAMSet (b t)) (toAMSet (c t)))))

prop_addIdentity : Property
prop_addIdentity = forAll {a = AMSetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.AMSet.addA (MkAMSet Zero Zero) (toAMSet s) == (toAMSet s)))

prop_annihilation : Property
prop_annihilation = forAll {a = AMSetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.AMSet.addA (toAMSet s) (Math.AMSet.negateA (toAMSet s)) == MkAMSet Zero Zero))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_addCommutative
  putStrLn $ "prop_addCommutative: " ++ res1.msg
  let res2 = QuickCheck.quickCheck prop_addAssociative
  putStrLn $ "prop_addAssociative: " ++ res2.msg
  let res3 = QuickCheck.quickCheck prop_addIdentity
  putStrLn $ "prop_addIdentity: " ++ res3.msg
  let res4 = QuickCheck.quickCheck prop_annihilation
  putStrLn $ "prop_annihilation: " ++ res4.msg
```
