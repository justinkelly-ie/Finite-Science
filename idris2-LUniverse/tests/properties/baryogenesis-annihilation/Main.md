# Baryogenesis Annihilation Verification

We verify that the `DarkPlusMatter` state implicitly resolves matter/antimatter asymmetry via the structural decay inherited from `SignedUnaryMultiset`.

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.SignedUnaryMultiset
import Math.Multiset
import Math.MaxelNL
import Math.UnaryMultiset

%default total

implementation Show (PixelNL Integer) where
  show (MkPixelNL x y) = "PixelNL(" ++ show x ++ ", " ++ show y ++ ")"

-- Generate a lattice coordinate (PixelNL Integer)
genPixelNL : Gen (PixelNL Integer)
genPixelNL = do
  x <- int (linear 0 10)
  y <- int (linear 0 10)
  pure (MkPixelNL (cast x) (cast y))

-- Add N copies of the SAME pixel to a multiset
replicateMSet : Nat -> PixelNL Integer -> UnaryMultiset (PixelNL Integer)
replicateMSet Z _ = Zero
replicateMSet (S k) p = Add p (replicateMSet k p)

export covering
prop_perfectAnnihilation : Property
prop_perfectAnnihilation = property $ do
  -- Generate N, a random number of particle pairs
  n <- forAll (nat (linear 1 100))
  
  -- Generate a random coordinate for the collision
  pixel <- forAll genPixelNL
  
  -- Create N Matter and N Antimatter at the exact same location
  let posAtoms = replicateMSet n pixel
  let negAtoms = replicateMSet n pixel
  
  -- The pre-annihilation state
  let supp = MkSignedUnaryMultiset posAtoms negAtoms
  
  -- Wrap it in the DarkPlusMatter engine, and let it annihilate
  let state = primordialDarkPlusMatter (toDense supp)
  
  -- Verify the vacuum is totally clean (Size = 0)
  let (MkSignedUnaryMultiset pSet nSet) = toUnary (maxelProjection state)
  (size pSet + size nSet) === 0

export covering
prop_baryogenesisAsymmetry : Property
prop_baryogenesisAsymmetry = property $ do
  -- N Matter > M Antimatter
  n <- forAll (nat (linear 50 100))
  m <- forAll (nat (linear 1 49))
  
  pixel <- forAll genPixelNL
  
  let posAtoms = replicateMSet n pixel
  let negAtoms = replicateMSet m pixel
  let supp = MkSignedUnaryMultiset posAtoms negAtoms
  
  -- Process annihilation natively
  let state = primordialDarkPlusMatter (toDense supp)
  
  let (MkSignedUnaryMultiset pSet nSet) = toUnary (maxelProjection state)
  -- Verify that EXACTLY N - M matter particles remain
  size pSet === minus n m
  
  -- Verify that ZERO antimatter particles remain
  size nSet === 0

export covering
main : IO ()
main = do
  res <- checkGroup $ MkGroup "Baryogenesis"
    [ ("prop_perfectAnnihilation", prop_perfectAnnihilation)
    , ("prop_baryogenesisAsymmetry", prop_baryogenesisAsymmetry)
    ]
  if res then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
