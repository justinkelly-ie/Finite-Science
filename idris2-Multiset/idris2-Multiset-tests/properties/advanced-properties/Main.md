# The Algebra of Multisets

Multisets are more than just collections; they form a robust algebraic structure. In this chapter, we use property-based testing to verify that our implementation satisfies the fundamental laws of a commutative monoid.

```idris
module Main

import Math.UnaryMultiset
import QuickCheck
import Data.So

%default total
```

## 1. Data Generation

To test our properties, we need a way to generate random multisets. We define custom `Arbitrary` instances that create multisets of varying sizes.

```idris
||| A single Multiset wrapper for identity testing.
record MSetSingle where
  constructor MkMSetSingle
  n : Nat
  xs : UnaryMultiset Int

Show MSetSingle where
  show (MkMSetSingle n _) = "(" ++ show n ++ ")"

Arbitrary MSetSingle where
  arbitrary = do
    n <- arbitrary {a=Int}
    let n' = cast (mod (abs n) 5)
    xs' <- genMSet n'
    pure (MkMSetSingle n' xs')
  where
    genMSet : (n : Nat) -> Gen (UnaryMultiset Int)
    genMSet 0 = pure Zero
    genMSet (S k) = do
      x <- arbitrary
      xs <- genMSet k
      pure (Add x xs)
  coarbitrary _ = variant 0

record MSetPair where
  constructor MkMSetPair
  n : Nat; xs : UnaryMultiset Int
  m : Nat; ys : UnaryMultiset Int

Show MSetPair where
  show (MkMSetPair n _ m _) = "(" ++ show n ++ ", " ++ show m ++ ")"

Arbitrary MSetPair where
  arbitrary = do
    n <- arbitrary {a=Int}; let n' = cast (mod (abs n) 5)
    m <- arbitrary {a=Int}; let m' = cast (mod (abs m) 5)
    xs' <- genMSet n'
    ys' <- genMSet m'
    pure (MkMSetPair n' xs' m' ys')
  where
    genMSet : (n : Nat) -> Gen (UnaryMultiset Int)
    genMSet 0 = pure Zero
    genMSet (S k) = do
      x <- arbitrary
      xs <- genMSet k
      pure (Add x xs)
  coarbitrary _ = variant 0

record MSetTriple where
  constructor MkMSetTriple
  n : Nat; xs : UnaryMultiset Int
  m : Nat; ys : UnaryMultiset Int
  k : Nat; zs : UnaryMultiset Int

Show MSetTriple where
  show (MkMSetTriple n _ m _ k _) = "(" ++ show n ++ ", " ++ show m ++ ", " ++ show k ++ ")"

Arbitrary MSetTriple where
  arbitrary = do
    n <- arbitrary {a=Int}; let n' = cast (mod (abs n) 5)
    m <- arbitrary {a=Int}; let m' = cast (mod (abs m) 5)
    k <- arbitrary {a=Int}; let k' = cast (mod (abs k) 5)
    xs' <- genMSet n'
    ys' <- genMSet m'
    zs' <- genMSet k'
    pure (MkMSetTriple n' xs' m' ys' k' zs')
  where
    genMSet : (n : Nat) -> Gen (UnaryMultiset Int)
    genMSet 0 = pure Zero
    genMSet (S k) = do
      x <- arbitrary
      xs <- genMSet k
      pure (Add x xs)
  coarbitrary _ = variant 0
```

## 2. Algebraic Properties

We verify the following laws using the QuickCheck engine:

### Size and Cardinality
The size of the sum of two multisets must be equal to the sum of their individual sizes.

```idris
prop_sizeAdd : Property
prop_sizeAdd = forAll {a = MSetPair} {prop = Bool} arbitrary (MkFn (\p => 
  Math.UnaryMultiset.size (Math.UnaryMultiset.add (xs p) (ys p)) == (n p + m p)))
```

### Commutativity
Multiset addition is commutative: `A + B = B + A`.

```idris
prop_addCommutative : Property
prop_addCommutative = forAll {a = MSetPair} {prop = Bool} arbitrary (MkFn (\p => 
  Math.UnaryMultiset.add (xs p) (ys p) == Math.UnaryMultiset.add (ys p) (xs p)))
```

### Associativity
Multiset addition is associative: `(A + B) + C = A + (B + C)`.

```idris
prop_addSignedssociative : Property
prop_addSignedssociative = forAll {a = MSetTriple} {prop = Bool} arbitrary (MkFn (\t =>
  Math.UnaryMultiset.add (Math.UnaryMultiset.add (xs t) (ys t)) (zs t) == 
  Math.UnaryMultiset.add (xs t) (Math.UnaryMultiset.add (ys t) (zs t))))
```

### Identity
The `Zero` multiset acts as the identity element for addition.

```idris
prop_addLeftIdentity : Property
prop_addLeftIdentity = forAll {a = MSetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.UnaryMultiset.add Zero (xs s) == (xs s)))

prop_addRightIdentity : Property
prop_addRightIdentity = forAll {a = MSetSingle} {prop = Bool} arbitrary (MkFn (\s =>
  Math.UnaryMultiset.add (xs s) Zero == (xs s)))
```

### Sigma Size
The `sigma` operation flattens a multiset of multisets. Its size must be equal to the sum of the sizes of the inner multisets.

```idris
prop_sizeSigma : Property
prop_sizeSigma = forAll {a = MSetPair} {prop = Bool} arbitrary (MkFn (\p =>
  let xss = Add (xs p) (Add (ys p) Zero)
  in Math.UnaryMultiset.size (Math.UnaryMultiset.sigma xss) == (n p + m p)))
```

## 3. Verification Execution

Finally, we run our properties. If any property fails, QuickCheck will provide us with a counterexample, allowing us to harden our implementation.

```idris
main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_sizeAdd
  putStrLn $ "prop_sizeAdd: " ++ res1.msg
  let res2 = QuickCheck.quickCheck prop_addCommutative
  putStrLn $ "prop_addCommutative: " ++ res2.msg
  let res3 = QuickCheck.quickCheck prop_addSignedssociative
  putStrLn $ "prop_addSignedssociative: " ++ res3.msg
  let res4 = QuickCheck.quickCheck prop_addLeftIdentity
  putStrLn $ "prop_addLeftIdentity: " ++ res4.msg
  let res5 = QuickCheck.quickCheck prop_addRightIdentity
  putStrLn $ "prop_addRightIdentity: " ++ res5.msg
  let res6 = QuickCheck.quickCheck prop_sizeSigma
  putStrLn $ "prop_sizeSigma: " ++ res6.msg
```
