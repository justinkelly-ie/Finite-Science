module Physics.SigmaBridge

import Math.Core
import Math.SigmaLinear
import Math.Multiset

-----------------------------------------------------------------------
-- SIGMA MELT ENGINE
-----------------------------------------------------------------------

||| Recursively builds a Linear Dependent Multiset from a standard runtime list.
||| This is the magic step that elevates runtime data into the type signature!
public export
buildLDep : (c : List (a, Integer)) -> LDepMultiset a c
buildLDep [] = LEmptyM
buildLDep ((item, count) :: rest) = LAddM item count (buildLDep rest)

||| Melts a standard SparseMaxel (Legacy) into a Dynamic Universe wrapper (Sigma).
||| This takes the raw non-linear field and locks it into the DPair wrapper.
public export
sigmaMeltMaxel : Math.Core.SparseMaxel -> Math.SigmaLinear.DynamicUniverse (Math.Core.Geometry, Math.Core.Amplitude)
sigmaMeltMaxel (MkSparseMaxel mset) = 
  let c = multisetToList mset
  in (c ** buildLDep c)

||| Melts a standard Substrate (Legacy) into a Dynamic Substrate (Sigma).
public export
sigmaMeltChain : Math.Core.Substrate -> Math.SigmaLinear.DynamicSubstrate
sigmaMeltChain sub = 
  let edges = multisetToList sub
  in (edges ** buildLDep edges)

-----------------------------------------------------------------------
-- SIGMA FREEZE ENGINE
-----------------------------------------------------------------------

||| Tail-recursive helper to freeze a linear multiset into an unrestricted list.
||| The accumulator ensures the linear variable `prev` is consumed in a linear context,
||| avoiding Idris 2's strict QTT restrictions on placing linear variables inside unrestricted constructors.
freezeLDepAcc : (acc : List (a, Integer)) -> (1 m : LDepMultiset a c) -> List (a, Integer)
freezeLDepAcc acc LEmptyM = acc
freezeLDepAcc acc (LAddM item count prev) = freezeLDepAcc ((item, count) :: acc) prev

||| Freezes a Linear Dependent Multiset back into a standard runtime list.
public export
freezeLDep : {0 c : List (a, Integer)} -> (1 m : LDepMultiset a c) -> List (a, Integer)
freezeLDep m = freezeLDepAcc [] m

||| Freezes a Dynamic Universe back into the legacy SparseMaxel.
||| This allows the visualizer to render the output cleanly.
public export
sigmaFreezeMaxel : Math.SigmaLinear.DynamicUniverse (Math.Core.Geometry, Math.Core.Amplitude) -> Math.Core.SparseMaxel
sigmaFreezeMaxel (c ** m) = MkSparseMaxel (fromList (freezeLDep m))

||| Freezes a Geometry-only topological boundary into a legacy SparseMaxel.
public export
sigmaFreezeGeometryMaxel : Math.SigmaLinear.DynamicSparseMaxel -> Math.Core.SparseMaxel
sigmaFreezeGeometryMaxel (c ** m) = 
  let geomList = freezeLDep m
      maxelList = map (\(g, count) => ((g, emptyAmplitude), count)) geomList
  in MkSparseMaxel (fromList maxelList)

||| Freezes a Dynamic Substrate back into the legacy Substrate.
public export
sigmaFreezeChain : Math.SigmaLinear.DynamicSubstrate -> Math.Core.Substrate
sigmaFreezeChain (edges ** chain) = fromList (freezeLDep chain)
