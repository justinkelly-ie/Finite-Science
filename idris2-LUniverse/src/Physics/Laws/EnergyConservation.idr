module Physics.Laws.EnergyConservation

import Math.MaxelNL
import Math.Chromogeometry

%default total

||| The Law of Conservation of Energy.
||| In the Chromogeometric framework, Energy corresponds strictly to Spatial 
||| extension on the grid, which is measured by Blue Quadrance.
||| This interface asserts that during any valid physical transformation or decay,
||| the total Blue Quadrance must remain perfectly constant.
public export
interface ConservesEnergy a b where
  ||| Validates that the total Blue Quadrance of the input state(s)
  ||| exactly equals the total Blue Quadrance of the output state(s).
  isEnergyConserved : a -> b -> Bool

||| A simple implementation demonstrating energy conservation between two pixels.
||| (e.g. a Photon transforming into another state, or elastic scattering).
public export
implementation ConservesEnergy (PixelNL Integer) (PixelNL Integer) where
  isEnergyConserved p1 p2 = 
    quadranceNL Blue p1 == quadranceNL Blue p2
