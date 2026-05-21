# Library Source Code Wiki

This page contains the source code for all Idris 2 files found in the Library directory.

## Wiki/Projects/HadronGluonDynamics.idr/src/Findings/LeibnizLag.idr
```idris
module Findings.LeibnizLag

import Math.Interfaces
import Math.Multiset
import Math.Pixel
import Math.Maxel
import Math.Algebra
import Math.Chromogeometry
import Logic.Grid
import Math.Rational
import Math.Leibniz
import Math.Types

%default total

-----------------------------------------------------------------------
-- 1. THE DEPTH IDENTITY (Z = DfDg)
-----------------------------------------------------------------------

||| The Depth Projection:
||| Proves that the Z-coordinate in the 137-grid is exactly 
||| the Leibniz Residue of the pixel transition.
public export
0 depthIdentity : (Cast a (Integer, Integer), Eq a, Copyable a, Consumable a) => (v : a -> Integer) -> (1 p : Pixel a) -> Bool
depthIdentity v p = 
  case projectToGrid v p of
       (LJust addr, p_res) => 
          let z = addr.z 
              lag = residue p_res (Add p_res Zero)
          in z == lag
       (LNothing, p_res) => let () = consume p_res in False

-----------------------------------------------------------------------
-- 2. THE CHRONOGEOMETRIC LAG
-----------------------------------------------------------------------

||| Audit: Verifies that the 'Lag' (Depth) remains within the grid's capacity.
||| When the lag exceeds the scale, the spacetime 'ruptures' (Decoherence).
public export
0 verifyGravitationalLag : (Eq a, Copyable a, Consumable a) => GridConfig -> (v : a -> Integer) -> (p : Pixel a) -> (m : Maxel a) -> Bool
verifyGravitationalLag cfg v p m = 
  let lag = Math.Leibniz.residue p m
  in cast lag <= scale cfg

```

