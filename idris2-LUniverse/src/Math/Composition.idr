module Math.Composition

import public Math.Core
import public Math.Twist
import public Math.Chromogeometry
import public Math.Multiset
import public Math.MaxelNL
import public Data.List

%default total

-----------------------------------------------------------------------
-- COMPOSITE STATE (Generic Platonic Field Topology)
-----------------------------------------------------------------------

||| A CompositeState represents a pure, stateless mathematical field topology —
||| a spatial state vector (0-Cochain) mapping coordinates to amplitudes.
public export
0 CompositeState : Type
CompositeState = SparseMaxel

||| Translates a CompositeState's coordinates by a displacement vector.
public export
translateState : PixelNL Integer -> CompositeState -> CompositeState
translateState (MkPixelNL dx dy) (MkSparseMaxel m) =
  let stateItems = multisetToList m
      translatedState = map (\((MkPixelNL x y, amp), count) => 
                              ((MkPixelNL (x + dx) (y + dy), amp), count)
                            ) stateItems
  in MkSparseMaxel (fromList translatedState)

||| Computes the composite rational spread of the active coordinates in the state,
||| which directly determines the structural folding locks at higher scales.
public export
computeStateSpread : Metric -> CompositeState -> (Integer, Integer)
computeStateSpread metric (MkSparseMaxel m) =
  let coords = map (fst . fst) (multisetToList m)
      -- Keep only unique coordinates (active nodes)
      uniqueCoords = nub coords
      -- Extract all triads of distinct coordinates (p1, p2, p3)
      triads = [ (p1, p2, p3)
               | p1 <- uniqueCoords
               , p2 <- uniqueCoords
               , p3 <- uniqueCoords
               , p1 /= p2, p2 /= p3, p3 /= p1
               ]
      
      -- Helper function to destructure the triad and compute its spread
      getSpread : (PixelNL Integer, PixelNL Integer, PixelNL Integer) -> (Integer, Integer)
      getSpread (p1, p2, p3) = spreadNL metric p1 p2 p3
      
      -- Map triads to exact rational spreads
      spreadFractions = map getSpread triads
  in foldl addRationalLocal (0, 1) spreadFractions
