module Physics.Evolution.State

import public Data.Linear.Ref1

import public Math.UnaryMultiset
import public Math.Polynumber
import public Math.Multiset
import public Math.IntPolynumber
import public Math.MaxelNL
import public Math.SpreadPolynumber
import public Math.Chromogeometry
import public Math.Twist
import public Math.Core
import public Math.Composition
import public Math.Topology.Chain
import public Math.Topology.Simplex
import public Data.List

%default total

-----------------------------------------------------------------------
-- CELL STATE (Concrete Cosmological State Vector)
-----------------------------------------------------------------------

||| The Chromogeometric Configuration of a CellState.
||| Maps directly to the three forms: Matter (Blue), Dark Energy (Red), Background (Green).
public export
data Flavor = Matter | DarkEnergy | Background

||| Determines the Chromogeometric Metric corresponding to a Flavor.
public export
flavorMetric : Flavor -> Metric
flavorMetric Matter     = Blue
flavorMetric DarkEnergy = Red
flavorMetric Background = Green

||| CellState acts as the unprojected coordinate engine and
||| cosmological state vector for the 137-Grid.
||| It unifies Matter and Dark Energy using Norman Wildberger's Spread Polynomials.
public export
record CellState where
  constructor MkCellState
  ||| The current generation number (N) of the Universe unfolding.
  generation   : Nat
  ||| The current generation encoded as a Spread Polynomial.
  statePoly    : IntPolynumber
  ||| The underlying lattice topology (Support of the Maxel) embedding the 128+27 states.
  ||| Note: This is explicitly a Chain0 (0-Chain of vertices/dust).
  ||| Because it lacks 1-Cell causal edges, this state is physically "frozen"
  ||| and possesses no relational time until it is bound to a Substrate graph.
  maxelProjection : Chain0
  ||| The current unified Flavor configuration.
  flavor       : Flavor

public export
Eq Flavor where
  Matter == Matter = True
  DarkEnergy == DarkEnergy = True
  Background == Background = True
  _ == _ = False

public export
Eq CellState where
  (MkCellState g1 p1 m1 f1) == (MkCellState g2 p2 m2 f2) =
    g1 == g2 && p1 == p2 && m1 == m2 && f1 == f2

||| Creates a foundational, unexcited (Background) CellState.
public export
primordialCellState : Chain0 -> CellState
primordialCellState supp = MkCellState Z emptyIntPoly supp Background

||| Progresses the CellState to the N-th spread polynomial.
public export covering
unfoldState : Nat -> CellState -> CellState
unfoldState n (MkCellState _ _ supp f) = MkCellState n (spreadPoly n) supp f

||| Pivots the Flavor configuration.
public export
pivotFlavor : Flavor -> CellState -> CellState
pivotFlavor newF (MkCellState gen p supp _) = MkCellState gen p supp newF

||| Extracts the primary topological pixel from a CellState.
public export
extractPixel : CellState -> Cell0
extractPixel state =
  case state.maxelProjection of
    ZeroM      => MkPixelNL 0 0
    AddM p _ _ => p


