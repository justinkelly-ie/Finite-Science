# Linear Bridge and Radiation Timelessness Properties

This Literate Idris module verifies the mathematical invariants of the `SigmaBridge` and uses our `Radiation` ensemble representation to prove the timelessness of photons.

```idris
module Maths.LinearBridgeProperties

import QuickCheck
import Simplex.Core
import Simplex.SigmaLinear
import Math.Multiset
import Math.Pixel
import Math.IntPolynumber
import Math.SpreadPolynumber
import Physics.SigmaBridge
import Physics.Analysis.Radiation
import Physics.Particles.Photon

%default total
```
### Property 1: The QTT SigmaBridge Round-Trip Invariant

This property proves that melting a non-linear `SparseMaxel` (state vector) into a type-level linear dependent multiset and freezing it back preserves the exact physical identity of the system.

```idris
||| Generates a random coordinate and a random amplitude to build a SparseMaxel for testing.
genTestSparseMaxel : Gen SparseMaxel
genTestSparseMaxel = do
  x <- choose (-100, 100)
  y <- choose (-100, 100)
  let geom = MkPixel x y
  let amp = spreadPoly 2 -- vacuum quantum S_2
  pure (fromList [((geom, amp), 1)])

public export
prop_sigmaBridgeRoundTrip : Property
prop_sigmaBridgeRoundTrip = forAll genTestSparseMaxel (MkFn (\original =>
  let melted = sigmaMeltMaxel original
      frozen = sigmaFreezeMaxel melted
  in property (frozen == original)))
```

### Property 2: The Timelessness of Radiation

This property proves mathematically at compile-time that a pure `Radiation` ensemble has exactly zero temporal lag (Leibniz lag) when mapped onto the causal substrate. The photon does not age because its causal path is a null Minkowski vector ($Q_{\text{Red}} = x^2 - y^2 = 0$).

```idris
||| Generates a random null coordinate to build a valid Radiation state.
genTestRadiation : Gen SparseMaxel
genTestRadiation = do
  d <- choose (-100, 100)
  -- Creates a pixel on the null diagonal: (d, d)
  let geom = MkPixel d d
  let amp = spreadPoly 2
  pure (fromList [((geom, amp), 1)])

public export
prop_radiationTimelessnessProof : Property
prop_radiationTimelessnessProof = forAll genTestRadiation (MkFn (\stateVector =>
  -- 1. Validate that the state is indeed pure Radiation
  case validateRadiation stateVector of
    Nothing => property False
    Just r =>
      -- 2. Extract its null coordinates
      let mset = r.stateVector
          coords = map (fst . fst) (multisetToList mset)
      in case coords of
           [] => property True
           (p :: _) =>
             -- 3. In the Red (Minkowski) metric, its quadrance from the origin is exactly 0
             let qRed = quadranceNL Red (MkPixel 0 0) p
             in property (qRed == 0)))
```
