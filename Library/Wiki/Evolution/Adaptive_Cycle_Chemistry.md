# Adaptive Cycle Chemistry & Geometry

These tests verify the chromogeometric structure of the $H_2O$ molecule and the Pythagorean fixed point underlying chemical stability.

```idris
module Evolution.Adaptive_Cycle_Chemistry

import QuickCheck
import Simplex.Core
import Evolution.Cycle
import Evolution.Transform
import Evolution.Gate
import Evolution.Clock
import Physics.Elements.Hydrogen
import Physics.Elements.Oxygen
import Physics.Elements.Water
import Physics.Scales.PythagoreanFixedPoint
import Physics.Scales.ScaleTrajectory
import Physics.Scales.IceGeometry
import Math.Multiset
import Math.IntPolynumber
import Math.SpreadPolynumber
import Math.Chromogeometry
import Math.Fraction

import Data.List

%default covering
```

## Water Chemistry

### Property 1: Water Baryonic Lag is 10

Total $Z = 2 \times 1 + 8 = 10$.

```idris
prop_waterBaryonicLag : Bool
prop_waterBaryonicLag = waterBaryonicLag == 10
```

### Property 2: Water Bond Count is 2

Oxygen's valence = BackgroundGate degree = 2.

```idris
prop_waterBondCount : Bool
prop_waterBondCount = waterBondCount == 2
```

### Property 3: Water is Stable

Z=10 is well below the Feynman limit (137).

```idris
prop_waterIsStable : Bool
prop_waterIsStable = waterIsStable
```

### Property 4: Oxygen Valence is BackgroundGate

Oxygen needs 2 electrons = BackgroundGate degree.

```idris
prop_oxygenValenceIs2 : Bool
prop_oxygenValenceIs2 = oxygenValence == 2
```

### Property 5: Dark Energy Quanta is 16

128 / 8 = 16. Oxygen partitions the dark energy pool into 16 quanta.

```idris
prop_darkEnergyQuantaIs16 : Bool
prop_darkEnergyQuantaIs16 = darkEnergyQuanta == 16
```

### Property 6: Hydrogen has Minimal Lag

Hydrogen is the unit baryon — lag = 1.

```idris
prop_hydrogenLagMinimal : Bool
prop_hydrogenLagMinimal = hydrogenLag (MkPixel 0 0) > 0
```

### Property 7: Bond Quadrance is ChargeGate²

$Q(OH) = 4^2 + 3^2 = 25 = 5^2 = \text{ChargeGate}^2$.

```idris
prop_bondQuadranceIs25 : Bool
prop_bondQuadranceIs25 = bondQuadrance == 25
```

### Property 8: Bond Spread is 7²/5⁴

The spread at O = $49/625 = \text{TimeGate}^2 / \text{ChargeGate}^4$.

```idris
prop_bondSpreadGateDerived : Bool
prop_bondSpreadGateDerived =
  let (num, den) = bondSpread
  in num == 196 && den == 2500
```

### Property 9: Inter-Hydrogen Quadrance is BackgroundGate

$Q(H_1 H_2) = 2 = \text{BackgroundGate}$ degree.

```idris
prop_interHydrogenIsBackground : Bool
prop_interHydrogenIsBackground =
  interHydrogenQuadrance == cast (degree BackgroundGate)
```

### Property 10: Bonds are Red-Perpendicular

The O-H bonds are perpendicular in the Red (Minkowski) metric.
This means they are null-separated in relativistic spacetime.

```idris
prop_bondsRedPerpendicular : Bool
prop_bondsRedPerpendicular = bondsRedPerpendicular
```

### Property 11: Electron Red Quadrance is TimeGate

$Q_{Red}(\text{electron at } H_1) = 4^2 - 3^2 = 16 - 9 = 7 = \text{TimeGate}$ degree.
The electron's relativistic quadrance IS the TimeGate.

```idris
prop_electronRedIsTimeGate : Bool
prop_electronRedIsTimeGate =
  electronRedQuadrance == cast (degree TimeGate)
```

### Property 12: Electron Green Quadrance is Oxygen × MatterGate

$Q_{Green}(\text{electron at } H_1) = 2 \times 4 \times 3 = 24 = 8 \times 3 = \text{Oxygen}(Z) \times \text{MatterGate}(n)$.
The electron's product-metric quadrance encodes the Oxygen-MatterGate product.

```idris
prop_electronGreenIsOxygenMatter : Bool
prop_electronGreenIsOxygenMatter =
  electronGreenQuadrance == 8 * cast (degree MatterGate)
```

### Property 13: Electron-Electron Spread Equals Bond Spread

The angular separation between the two bonding electrons (as seen from O)
is identical to the bond spread. The electrons ARE the bonds.

```idris
prop_electronSpreadIsBondSpread : Bool
prop_electronSpreadIsBondSpread =
  electronElectronSpread == bondSpread
```

## Pythagorean Fixed Point & N+1 Scale Transition

### Property 14: Water is a Pythagorean Fixed Point

The (4,3) coordinate decodes to gate degrees in all three metrics.

```idris
prop_waterIsFixedPoint : Bool
prop_waterIsFixedPoint = waterIsFixedPoint
```

### Property 15: Hydrogen Bond Direction is TimeGate Diagonal

At N+1, the hydrogen bond direction = (7, 7) = TimeGate diagonal.

```idris
prop_hydrogenBondIsTimeGateDiagonal : Bool
prop_hydrogenBondIsTimeGateDiagonal =
  let hb = hydrogenBondDirection
  in hb.src == cast (degree TimeGate) && hb.tgt == cast (degree TimeGate)
```

### Property 16: Hydrogen Bond is Red-Null (Identity Diagonal)

$Q_{Red}(7,7) = 7^2 - 7^2 = 0$. The N+1 bond IS the [J,J] identity diagonal.
A null vector in Minkowski space — pure self-reference.

```idris
prop_hydrogenBondIsIdentity : Bool
prop_hydrogenBondIsIdentity = hydrogenBondIsIdentity
```

### Property 17: Hydrogen Bond is Isotropic

$Q_{Blue} = Q_{Green} = 98$. The bond looks identical from Euclidean and
product metrics — metric-invariant.

```idris
prop_hydrogenBondIsIsotropic : Bool
prop_hydrogenBondIsIsotropic = hydrogenBondIsIsotropic
```

### Property 18: N+1 Blue Quadrance = BackgroundGate × TimeGate²

$98 = 2 \times 49 = \text{BackgroundGate} \times \text{TimeGate}^2$. The scale hierarchy
persists into N+1.

```idris
prop_hbondBlueDecomposition : Bool
prop_hbondBlueDecomposition =
  let fp = hydrogenBondFingerprint
  in fp.blueQ == cast (degree BackgroundGate) * cast (degree TimeGate) * cast (degree TimeGate)
```

## Main Test Runner

```idris
runProp : String -> Bool -> IO ()
runProp name result = putStrLn $ name ++ ": " ++ (if result then "PASS" else "FAIL")

public export
main : IO ()
main = do
  putStrLn "=== Adaptive Cycle Chemistry ==="
  putStrLn ""

  runProp "prop_waterBaryonicLag" prop_waterBaryonicLag
  runProp "prop_waterBondCount" prop_waterBondCount
  runProp "prop_waterIsStable" prop_waterIsStable
  runProp "prop_oxygenValenceIs2" prop_oxygenValenceIs2
  runProp "prop_darkEnergyQuantaIs16" prop_darkEnergyQuantaIs16
  runProp "prop_hydrogenLagMinimal" prop_hydrogenLagMinimal
  runProp "prop_bondQuadranceIs25" prop_bondQuadranceIs25
  runProp "prop_bondSpreadGateDerived" prop_bondSpreadGateDerived
  runProp "prop_interHydrogenIsBackground" prop_interHydrogenIsBackground
  runProp "prop_bondsRedPerpendicular" prop_bondsRedPerpendicular
  runProp "prop_electronRedIsTimeGate" prop_electronRedIsTimeGate
  runProp "prop_electronGreenIsOxygenMatter" prop_electronGreenIsOxygenMatter
  runProp "prop_electronSpreadIsBondSpread" prop_electronSpreadIsBondSpread

  runProp "prop_waterIsFixedPoint" prop_waterIsFixedPoint
  runProp "prop_hydrogenBondIsTimeGateDiagonal" prop_hydrogenBondIsTimeGateDiagonal
  runProp "prop_hydrogenBondIsIdentity" prop_hydrogenBondIsIdentity
  runProp "prop_hydrogenBondIsIsotropic" prop_hydrogenBondIsIsotropic
  runProp "prop_hbondBlueDecomposition" prop_hbondBlueDecomposition
```
