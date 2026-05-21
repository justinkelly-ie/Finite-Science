module Universe.DarkPlusMatter

import Data.Linear
import Math.IntPolynumber
import Math.SpreadPolynomial
import Math.MaxelNL
import Math.Chromogeometry
import Math.DenseAMSet
import Math.AMSet

%default total

||| The Chromogeometric Configuration of a DarkPlusMatter State.
||| Instead of tracking parity (Möbius 1/-1), we map directly into
||| the three forms: Matter (Blue), Dark Energy (Red), Background (Green).
public export
data Flavor = Matter | DarkEnergy | Background

||| Determines the Metric corresponding to a Flavor.
public export
flavorMetric : Flavor -> Metric
flavorMetric Matter = Blue
flavorMetric DarkEnergy = Red
flavorMetric Background = Green

||| DarkPlusMatter acts as the unprojected coordinate engine and
||| cosmological state vector for the 137-Grid.
||| It unifies Matter and Dark Energy using Norman Wildberger's
||| Spread Polynomials and the underlying Maxel Support.
public export
record DarkPlusMatter where
  constructor MkDarkPlusMatter
  ||| The current generation number (N) of the Universe unfolding.
  generation : Nat
  ||| The current generation encoded as a Spread Polynomial.
  ||| This replaces the legacy Möbius Transformation engine.
  statePoly : IntPolynumber
  ||| The underlying lattice topology (Support of the Maxel)
  ||| that embeds the 128 + 27 states.
  maxelSupport : DenseAMSet (PixelNL Integer)
  ||| The current unified Flavor configuration
  flavor : Flavor

||| Creates a foundational, unexcited (Background) DarkPlusMatter state.
||| Utilizes the zeroth (or empty) spread polynomial.
export
primordialDarkPlusMatter : DenseAMSet (PixelNL Integer) -> DarkPlusMatter
primordialDarkPlusMatter supp = 
  MkDarkPlusMatter Z emptyIntPoly supp Background

||| Progresses the DarkPlusMatter state to the N-th spread polynomial.
||| This simulates cosmological scaling / unfolding over N generations.
export covering
unfoldState : Nat -> DarkPlusMatter -> DarkPlusMatter
unfoldState n (MkDarkPlusMatter _ _ supp f) =
  MkDarkPlusMatter n (spreadPoly n) supp f

||| Pivots the Flavor configuration (e.g., swapping Dark Energy / Matter).
||| This is mathematically analogous to shifting the active Chromogeometric Metric.
export
pivotFlavor : Flavor -> DarkPlusMatter -> DarkPlusMatter
pivotFlavor newF (MkDarkPlusMatter gen p supp _) =
  MkDarkPlusMatter gen p supp newF

||| Extracts the active topological pixel from a DarkPlusMatter state.
||| For localized particles, this grabs the primary coordinate from the DenseAMSet.
||| Defaults to origin (0,0) if the particle is totally delocalized (empty vacuum).
export
extractPixel : DarkPlusMatter -> PixelNL Integer
extractPixel state =
  case state.maxelSupport.items of
    [] => MkPixelNL 0 0
    ((p, _) :: _) => p
