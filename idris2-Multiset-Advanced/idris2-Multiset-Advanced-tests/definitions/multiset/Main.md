# Multiset Structure and Cardinality

The Multiset is a fundamental structure in combinatorial algebra, representing a collection where elements can appear multiple times, but their order does not matter. In our linear implementation, we ensure that every element is strictly accounted for.

```idris
module Main
import Hedgehog
import Math.Multiset

%default total
```

## Basic Cardinality

One of the simplest properties of a multiset is its size. When we add an element to a multiset, its size should increase by exactly one.

```idris
prop_add_size : Property
prop_add_size = property $ do
  x <- forAll (nat (linear 0 100))
  let m = Add x Zero
  let MkSizeProof n orig recon = sizeL m
  let () = lconsume orig
  let () = lconsume recon
  countMSet n === 1
```

## Test Runner

We execute our structural checks using the Hedgehog engine to ensure basic sanity before moving on to deeper algebraic properties.

```idris
main : IO ()
main = do
  success <- checkGroup $ MkGroup "Math.Multiset"
    [ ("Add Size", prop_add_size) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
