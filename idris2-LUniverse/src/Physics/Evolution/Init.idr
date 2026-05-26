module Physics.Evolution.Init

import Physics.Evolution.Cycle
import public Data.Linear.Ref1
import Math.Core

import Math.Multiset
import Math.MaxelNL
import Math.Chromogeometry
import Math.IntPolynumber
import Math.Core
import Physics.Evolution.Cycle

%default total

-- Naming Zoo Reference:
--   - Physics: Primordial Vacuum Seed / Chromogeometric Background State
--   - Category Theory: Initial Object of the Sheaf Manifold Layout
--   - Concrete: Populating a baseline Substrate and SparseMaxel grid at T=0.

||| Generates the default initial conditions where Chromogeometry acts as the macro target.
||| It seeds the grid with foundational points (like the Water/H-Bond origin roots)
||| to jumpstart the relational clock loop safely at T=0.
public export
seedChromogeometricVacuum : (capacityLimit : Integer) -> UniverseState
seedChromogeometricVacuum capacityLimit =
  let -- 1. Define the baseline primordial coordinate vertices (The Root Geometry)
      origin = MkPixelNL 0 0
      basisX = MkPixelNL 1 0 -- The primordial X-axis Pauli vector
      basisY = MkPixelNL 0 1 -- The primordial Y-axis Pauli vector
      
      -- 2. Build the initial Substrate (A small seed graph of relationships)
      -- This gives the clock its very first relational links so T can begin to tick
      -- This is our initial 1-Chain!
      initSubstrate = fromList [ ((origin, basisX), 1)
                               , ((origin, basisY), 1)
                               ]
                               
      -- 3. Seed the initial State Vector with unexcited background amplitudes
      -- The emptyIntPoly represents the quiet vacuum before spreadPoly convolution triggers
      vacuumAmp  = emptyIntPoly
      initFields = fromList [ ((origin, vacuumAmp), 1)
                            , ((basisX, vacuumAmp), 1)
                            , ((basisY, vacuumAmp), 1)
                            ]
  in MkUniverseState initSubstrate (MkSparseMaxel initFields)


