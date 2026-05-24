module Physics.Evolution.State

import public Math.UnaryMultiset
import public Math.Polynumber
import public Math.Multiset
import public Math.IntPolynumber
import public Math.MaxelNL
import public Math.SpreadPolynumber
import public Math.Chromogeometry

%default total

-----------------------------------------------------------------------
-- DARK PLUS MATTER (Concrete Cosmological State Vector)
-----------------------------------------------------------------------

||| The Chromogeometric Configuration of a DarkPlusMatter State.
||| Maps directly to the three forms: Matter (Blue), Dark Energy (Red), Background (Green).
public export
data Flavor = Matter | DarkEnergy | Background

||| Determines the Chromogeometric Metric corresponding to a Flavor.
public export
flavorMetric : Flavor -> Metric
flavorMetric Matter     = Blue
flavorMetric DarkEnergy = Red
flavorMetric Background = Green

||| DarkPlusMatter acts as the unprojected coordinate engine and
||| cosmological state vector for the 137-Grid.
||| It unifies Matter and Dark Energy using Norman Wildberger's Spread Polynomials.
public export
record DarkPlusMatter where
  constructor MkDarkPlusMatter
  ||| The current generation number (N) of the Universe unfolding.
  generation   : Nat
  ||| The current generation encoded as a Spread Polynomial.
  statePoly    : IntPolynumber
  ||| The underlying lattice topology (Support of the Maxel) embedding the 128+27 states.
  maxelProjection : Multiset (PixelNL Integer)
  ||| The current unified Flavor configuration.
  flavor       : Flavor

public export
Eq Flavor where
  Matter == Matter = True
  DarkEnergy == DarkEnergy = True
  Background == Background = True
  _ == _ = False

public export
Eq DarkPlusMatter where
  (MkDarkPlusMatter g1 p1 m1 f1) == (MkDarkPlusMatter g2 p2 m2 f2) =
    g1 == g2 && p1 == p2 && m1 == m2 && f1 == f2

||| Creates a foundational, unexcited (Background) DarkPlusMatter state.
public export
primordialDarkPlusMatter : Multiset (PixelNL Integer) -> DarkPlusMatter
primordialDarkPlusMatter supp = MkDarkPlusMatter Z emptyIntPoly supp Background

||| Progresses the DarkPlusMatter state to the N-th spread polynomial.
public export covering
unfoldState : Nat -> DarkPlusMatter -> DarkPlusMatter
unfoldState n (MkDarkPlusMatter _ _ supp f) = MkDarkPlusMatter n (spreadPoly n) supp f

||| Pivots the Flavor configuration.
public export
pivotFlavor : Flavor -> DarkPlusMatter -> DarkPlusMatter
pivotFlavor newF (MkDarkPlusMatter gen p supp _) = MkDarkPlusMatter gen p supp newF

||| Extracts the primary topological pixel from a DarkPlusMatter state.
public export
extractPixel : DarkPlusMatter -> PixelNL Integer
extractPixel state =
  case state.maxelProjection of
    ZeroM      => MkPixelNL 0 0
    AddM p _ _ => p
