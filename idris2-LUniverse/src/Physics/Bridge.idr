module Physics.Bridge

import Math.Core
import Math.Core
import Data.Linear.Ref1
import Syntax.T1
import Math.Multiset
import Data.List

%default covering

-----------------------------------------------------------------------
-- MELT ENGINE
-----------------------------------------------------------------------

||| Helper to look up an Amplitude for a given Geometry.
getAmp : Math.Core.Geometry -> Math.Core.SparseMaxel -> Math.Core.Amplitude
getAmp g pip =
  let matches = filter (\((geom, _), _) => geom == g) (multisetToList (maxelMap pip))
  in case matches of
       (((geom, amp), _) :: _) => amp
       [] => ZeroM

||| Allocates a distinct physical `Ref1` pointer for every unique Geometry coordinate.
allocateCells : Math.Core.SparseMaxel -> List Math.Core.Geometry -> F1 s (List (Math.Core.Geometry, LCell0 s))
allocateCells pip [] = pure []
allocateCells pip (g :: gs) = T1.do
  let amp = getAmp g pip
  cell <- ref1 (g, amp)
  rest <- allocateCells pip gs
  pure ((g, cell) :: rest)

||| Looks up the physical pointer assigned to a Geometry coordinate.
lookupCell : Math.Core.Geometry -> List (Math.Core.Geometry, LCell0 s) -> LCell0 s
lookupCell g [] = believe_me () -- Covered: we allocate exactly the list we look up from
lookupCell g ((g', c) :: rest) = if g == g' then c else lookupCell g rest

||| Bypasses the `Eq` constraint of `fromList` since the mapped list is guaranteed to be structurally unique.
export
fromListFast : List (a, Integer) -> Multiset a
fromListFast [] = ZeroM
fromListFast ((k, v) :: rest) = AddM k v (fromListFast rest)

||| Melt a pure non-linear UniverseState into a mutable linear LUniverseState.
export
melt : Math.Core.UniverseState -> F1 s (LUniverseState s)
melt (Math.Core.MkUniverseState sub stateVec) = T1.do
  let subNodes = Math.Core.substrateNodes sub
  let pipCoords = map (fst . fst) (multisetToList (maxelMap stateVec))
  let allUniqueGeoms = nub (subNodes ++ pipCoords)
  
  -- 1. Allocate exact physical memory
  allocMap <- allocateCells stateVec allUniqueGeoms
  
  -- 2. Build linear state vector using the shared pointers
  let buildLStateVec : ((Math.Core.Geometry, Math.Core.Amplitude), Integer) -> ((LCell0 s), Integer)
      buildLStateVec ((g, amp), count) = (lookupCell g allocMap, count)
  let lStateVec = fromListFast (map buildLStateVec (multisetToList (maxelMap stateVec)))
  
  -- 3. Build linear substrate edges using the exact same shared pointers
  let buildLSub : ((Math.Core.Geometry, Math.Core.Geometry), Integer) -> ((LCell0 s, LCell0 s), Integer)
      buildLSub ((g1, g2), count) = ((lookupCell g1 allocMap, lookupCell g2 allocMap), count)
  let lSub = fromListFast (map buildLSub (multisetToList sub))
  
  pure (MkLUniverseState lSub lStateVec)

-----------------------------------------------------------------------
-- FREEZE ENGINE
-----------------------------------------------------------------------

||| Helper to traverse the linear substrate and extract pure geometry edges.
export
freezeSub : List ((LCell0 s, LCell0 s), Integer) -> F1 s (List ((Math.Core.Geometry, Math.Core.Geometry), Integer))
freezeSub [] = pure []
freezeSub (((c1, c2), count) :: rest) = T1.do
  (g1, _) <- read1 c1
  (g2, _) <- read1 c2
  restFrozen <- freezeSub rest
  pure (((g1, g2), count) :: restFrozen)

||| Helper to traverse the linear state vector and extract pure values.
export
freezeState : List (LCell0 s, Integer) -> F1 s (List ((Math.Core.Geometry, Math.Core.Amplitude), Integer))
freezeState [] = pure []
freezeState ((c, count) :: rest) = T1.do
  (g, amp) <- read1 c
  restFrozen <- freezeState rest
  pure (((g, amp), count) :: restFrozen)

||| Freeze a linear LUniverseState back into a pure UniverseState.
export
freeze : LUniverseState s -> F1 s Math.Core.UniverseState
freeze (MkLUniverseState lSub lStateVec) = T1.do
  frozenSub <- freezeSub (multisetToList lSub)
  frozenState <- freezeState (multisetToList lStateVec)
  pure (Math.Core.MkUniverseState (fromList frozenSub) (MkSparseMaxel (fromList frozenState)))
