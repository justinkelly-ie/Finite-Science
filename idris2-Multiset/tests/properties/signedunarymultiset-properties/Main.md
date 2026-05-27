# The Algebra of Anti-Multisets

We verify the properties of Anti-Multisets (SignedUnaryMultiset).

```idris
module Main

import Math.UnaryMultiset
import Math.SignedUnaryMultiset
import QuickCheck
import Data.So

%default covering

record SignedUnaryMultisetSingle where
  constructor MkSignedUnaryMultisetSingle
  posN : Nat; posXs : UnaryMultiset Int
  negN : Nat; negXs : UnaryMultiset Int

Show SignedUnaryMultisetSingle where
  show (MkSignedUnaryMultisetSingle p _ n _) = "(+" ++ show p ++ ", -" ++ show n ++ ")"

Arbitrary SignedUnaryMultisetSingle where
  arbitrary = do
    p <- arbitrary {a=Int}; let p' = cast (mod (abs p) 5)
    n <- arbitrary {a=Int}; let n' = cast (mod (abs n) 5)
    pxs <- genMSet p'
    nxs <- genMSet n'
    pure (MkSignedUnaryMultisetSingle p' pxs n' nxs)
  where
    genMSet : (n : Nat) -> Gen (UnaryMultiset Int)
    genMSet 0 = pure Zero
    genMSet (S k) = do
      x <- arbitrary
      xs <- genMSet k
      pure (Add x xs)
  coarbitrary _ = variant 0

record SignedUnaryMultisetPair where
  constructor MkSignedUnaryMultisetPair
  a : SignedUnaryMultisetSingle
  b : SignedUnaryMultisetSingle

Show SignedUnaryMultisetPair where
  show (MkSignedUnaryMultisetPair a b) = "[" ++ show a ++ ", " ++ show b ++ "]"

Arbitrary SignedUnaryMultisetPair where
  arbitrary = do
    a <- arbitrary
    b <- arbitrary
    pure (MkSignedUnaryMultisetPair a b)
  coarbitrary _ = variant 0

record SignedUnaryMultisetTriple where
  constructor MkSignedUnaryMultisetTriple
  a : SignedUnaryMultisetSingle
  b : SignedUnaryMultisetSingle
  c : SignedUnaryMultisetSingle

Show SignedUnaryMultisetTriple where
  show (MkSignedUnaryMultisetTriple a b c) = "[" ++ show a ++ ", " ++ show b ++ ", " ++ show c ++ "]"

Arbitrary SignedUnaryMultisetTriple where
  arbitrary = do
    a <- arbitrary
    b <- arbitrary
    c <- arbitrary
    pure (MkSignedUnaryMultisetTriple a b c)
  coarbitrary _ = variant 0

toSignedUnaryMultiset : SignedUnaryMultisetSingle -> SignedUnaryMultiset Int
toSignedUnaryMultiset s = MkSignedUnaryMultiset (posXs s) (negXs s)

prop_addCommutative : Property
prop_addCommutative = forAll {a = SignedUnaryMultisetPair} {prop = Bool} arbitrary (MkFn (\p => 
  Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset (a p)) (toSignedUnaryMultiset (b p)) == Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset (b p)) (toSignedUnaryMultiset (a p))))

prop_addSignedssociative : Property
prop_addSignedssociative = forAll {a = SignedUnaryMultisetTriple} {prop = Bool} arbitrary (MkFn (\t =>
  Math.SignedUnaryMultiset.addSigned (Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset (a t)) (toSignedUnaryMultiset (b t))) (toSignedUnaryMultiset (c t)) == 
  Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset (a t)) (Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset (b t)) (toSignedUnaryMultiset (c t)))))

prop_addIdentity : Property
prop_addIdentity = forAll {a = SignedUnaryMultisetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.SignedUnaryMultiset.addSigned (MkSignedUnaryMultiset Zero Zero) (toSignedUnaryMultiset s) == (toSignedUnaryMultiset s)))

prop_annihilation : Property
prop_annihilation = forAll {a = SignedUnaryMultisetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.SignedUnaryMultiset.addSigned (toSignedUnaryMultiset s) (Math.SignedUnaryMultiset.negateSigned (toSignedUnaryMultiset s)) == MkSignedUnaryMultiset Zero Zero))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_addCommutative
  putStrLn $ "prop_addCommutative: " ++ res1.msg
  let res2 = QuickCheck.quickCheck prop_addSignedssociative
  putStrLn $ "prop_addSignedssociative: " ++ res2.msg
  let res3 = QuickCheck.quickCheck prop_addIdentity
  putStrLn $ "prop_addIdentity: " ++ res3.msg
  let res4 = QuickCheck.quickCheck prop_annihilation
  putStrLn $ "prop_annihilation: " ++ res4.msg
```
