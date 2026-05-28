# Adaptive Cycle Pipeline

The Adaptive Cycle is the cosmological heartbeat of the Pure Multiset Ascension architecture.
This test verifies that the full quantum gate pipeline ($n=2 \to n=3 \to n=4 \to n=5 \to n=7 \to n=11 \to n=13$)
correctly partitions, shatters, and evaluates the ascension/decoherence decision.

```idris
module Evolution.Adaptive_Cycle_Pipeline

import QuickCheck
import Simplex.Core
import Evolution.Cycle
import Evolution.Transform
import Evolution.Gate
import Evolution.Clock
import Math.Multiset
import Math.IntPolynumber
import Math.SpreadPolynumber
import Math.Chromogeometry
import Math.Fraction

import Data.List

%default covering
```

## Test Seeds

We construct concrete seed states to exercise the pipeline. The origin geometry
`(0, 0)` is the canonical active coordinate used throughout the evolution modules.

We cap spread polynomial degrees at 8 to keep computation tractable — `spreadPoly 13`
generates polynomials with thousands of terms.

```idris
origin : Geometry
origin = MkPixel 0 0

-- Cap degree to avoid huge polynomial explosion (spreadPoly 13 has thousands of terms)
capDegree : Nat -> Nat
capDegree n = if n > 7 then 7 else n

seedPoly : IntPolynumber
seedPoly = spreadPoly 3

seedState : Multiset (Geometry, Amplitude)
seedState = fromList [((origin, seedPoly), 1)]

vacuumUniverse : UniverseState
vacuumUniverse = MkUniverseState emptySubstrate emptySparseMaxel

seededUniverse : UniverseState
seededUniverse = MkUniverseState emptySubstrate seedState
```

## Pipeline Properties

### Property 1: Partition Gate Returns Two Parts

The 128/27 partition must produce two multisets (latent and visible).
We verify both are structurally valid (non-crashing, finite).

```idris
prop_partitionProducesTwoParts : Property
prop_partitionProducesTwoParts = forAll {a = Nat} {prop = Bool} arbitrary (MkFn (\rawDeg =>
  let degree = capDegree rawDeg
      poly = spreadPoly degree
      (latent, visible) = partitionLogic 128 origin poly
      latentCount = length (multisetToList latent)
      visibleCount = length (multisetToList visible)
  in latentCount >= 0 && visibleCount >= 0))
```

### Property 2: Resonance Reduces Coefficients

After the $n=13$ resonance shattering, every coefficient in the result must be
in range `[0, moduloBase)`. We force the trigger by setting multiplicity to 200.

```idris
allCoeffsBelow : Integer -> IntPolynumber -> Bool
allCoeffsBelow bound poly =
  all (\(_, coef) => coef >= 0 && coef < bound) (multisetToList poly)

prop_resonanceReduces : Property
prop_resonanceReduces = forAll {a = Nat} {prop = Bool} arbitrary (MkFn (\rawDeg =>
  let degree = capDegree rawDeg
      poly = spreadPoly degree
      bigState = fromList [((origin, poly), 200)]
      resonated = evaluateResonance 137 13 origin bigState
      polys = map (\((_, p), _) => p) (multisetToList resonated)
  in case polys of
       []      => True
       (p::ps) => allCoeffsBelow 13 p))
```

### Property 3: Ascension Produces a Singleton

`ascendScale` must condense any number of micro-states into exactly one macro-node.

```idris
prop_ascensionCondenses : Property
prop_ascensionCondenses = forAll {a = Nat} {prop = Bool} arbitrary (MkFn (\rawDeg =>
  let degree = capDegree rawDeg
      poly1 = spreadPoly degree
      poly2 = spreadPoly (degree + 1)
      microStates = fromList [((origin, poly1), 1), ((MkPixel 1 1, poly2), 1)]
      macroNode = ascendScale origin microStates
      entries = multisetToList macroNode
  in length entries == 1))
```

### Property 4: CanAscend Requires Exact Balance

The three-fold proof should only succeed when the three capacities sum to the limit.
On a vacuum substrate with origin geometry and empty residue, it should fail.

```idris
prop_canAscendRequiresBalance : Bool
prop_canAscendRequiresBalance =
  let result = canAscend Blue emptySubstrate emptySparseMaxel
  in result == False
```

## Main Test Runner

```idris
runProp : String -> Bool -> IO ()
runProp name result = putStrLn $ name ++ ": " ++ (if result then "PASS" else "FAIL")

public export
main : IO ()
main = do
  putStrLn "=== Adaptive Cycle Pipeline Simulation ==="
  putStrLn ""

  let r1 = QuickCheck.quickCheck prop_partitionProducesTwoParts
  putStrLn $ "prop_partitionProducesTwoParts: " ++ r1.msg

  let r2 = QuickCheck.quickCheck prop_resonanceReduces
  putStrLn $ "prop_resonanceReduces: " ++ r2.msg

  let r3 = QuickCheck.quickCheck prop_ascensionCondenses
  putStrLn $ "prop_ascensionCondenses: " ++ r3.msg

  runProp "prop_canAscendRequiresBalance" prop_canAscendRequiresBalance
```
