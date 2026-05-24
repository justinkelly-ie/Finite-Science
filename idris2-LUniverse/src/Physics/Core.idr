module Physics.Core

import public Math.Multiset
import public Math.MaxelNL
import public Math.IntPolynumber
import public Math.Chromogeometry
import Data.List

%default total

-----------------------------------------------------------------------
-- THE TWO FUNDAMENTAL PRIMITIVES
--
-- Every concept in this engine is built from two nested structures:
--
--   Geometry  = PixelNL Integer   (a 2-component chromogeometric coordinate)
--   Amplitude = IntPolynumber     (a polynomial of integer coefficients)
--
-- All categorical and physics naming conventions below are aliases or
-- documentation wrappers around these two primitives.
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- 1. GEOMETRY (The Elementary Spatial Unit)
-----------------------------------------------------------------------

||| A chromogeometric coordinate cell — the elementary spatial unit.
|||
||| Naming Zoo:
|||   - Physics:          Spacetime Voxel / Chromogeometric Coordinate / Spin State
|||   - Category Theory:  Object of the Base Category / Point of the Poset
|||   - Concrete:         A two-component integer pair (x, y) where each component
|||                       carries a magnitude evaluable under any of the three Metrics.
|||
||| The three Chromogeometric Metrics act on this type:
|||   quadranceNL Blue  (MkPixelNL x y) = x² + y²   (Euclidean measure)
|||   quadranceNL Red   (MkPixelNL x y) = x² - y²   (Minkowski measure)
|||   quadranceNL Green (MkPixelNL x y) = 2xy        (Null / light-like measure)
|||
||| The Flavor (Matter / DarkEnergy / Background) is encoded by which Metric
||| colour is used to evaluate the geometry:
|||   Blue  → VisibleState  (Matter, 27 states, 3^3 integer grid)
|||   Red   → LatentState   (DarkEnergy, 128 states, 2^7 fractional band)
|||   Green → ResidueState  (Background / Dark Matter dust after resonance collapse)
public export
0 Geometry : Type
Geometry = PixelNL Integer

-----------------------------------------------------------------------
-- 2. AMPLITUDE (The Quantum State Value)
-----------------------------------------------------------------------

||| The polynomial amplitude at a geometric coordinate.
|||
||| Naming Zoo:
|||   - Physics:          Quantum Amplitude / Polynumber / Fock State / Energy Coefficient
|||   - Category Theory:  Fiber Value / Local Section of the Sheaf
|||   - Concrete:         A Run-Length Encoded multiset of (alpha_power, beta_power)
|||                       pairs where the Integer multiplicity is the coefficient.
|||                       IntPolynumber = Multiset (Nat, Nat)
|||
||| Rename history: was called DenseAMSet (before rename to Multiset).
||| The linear QTT version is LabeledMSet in Math.UnaryMultiset.Labeled.
public export
0 Amplitude : Type
Amplitude = IntPolynumber

-----------------------------------------------------------------------
-- 3. SUBSTRATE (The Causal Graph — pure Multiset of directed edges)
--
-- Formerly: MaxelNL / Poset / SpacetimeManifold
--
-- The Substrate is now a pure Multiset (Geometry, Geometry) — each entry
-- is a directed causal edge from parent to child. No wrapper record,
-- no intermediate List — just the same Multiset engine used everywhere.
--
--   Substrate = Multiset (G, G)     where G = PixelNL Integer
--
-- This makes the architecture diagram exact:
--
--       [ BASE SUBSTRATE ]              [ STATE SPACE ]
--       Multiset (G, G)                 Multiset (G, Vector)
-----------------------------------------------------------------------

||| The directed causal graph of the spacetime manifold.
|||
||| Naming Zoo:
|||   - Physics:          Spacetime Manifold / Causal Graph / Spin Foam / Loop Quantum Gravity DAG
|||   - Category Theory:  Poset Category / Base Space of the Sheaf / Category of Opens
|||   - Concrete:         A Multiset of (Geometry, Geometry) directed edges.
|||                       Each entry (g1, g2) with multiplicity n encodes
|||                       "g1 causally precedes g2, with n parallel pathways."
|||   - Replaces:         MaxelNL / Math.Topology.Poset / SpacetimeManifold
|||
||| Rename history: AMSet → MaxelNL → Multiset (Geometry, Geometry)
|||
||| This is the same RLE Multiset engine used by PixelIntPoly, IntPolynumber,
||| and SpreadPolynomial. Any optimisation to Multiset.idr flows through
||| to the causal graph automatically.
public export
0 Substrate : Type
Substrate = Multiset (Geometry, Geometry)

-----------------------------------------------------------------------
-- 4. PIXEL-INT-POLY (The Quantum State Vector)
--
-- Formerly: FiberBundle / Sheaf / DenseAMSet (Geometry, Polynumber)
-----------------------------------------------------------------------

||| The quantum state vector — a dense map from coordinates to amplitudes.
|||
||| Naming Zoo:
|||   - Physics:          Fiber Bundle / Wavefunction / Fock Space State Vector / Gauge Field
|||   - Category Theory:  Sheaf of Polynumbers over the Poset Base Space
|||   - Concrete:         Multiset (PixelNL Integer, IntPolynumber) — each pixel
|||                       mapped to its local quantum amplitude polynomial.
|||   - Replaces:         Math.Topology.Sheaf / FiberBundle / DenseAMSet wrappers
|||
||| The Flavor of each entry is determined by the Metric applied to its Geometry:
|||   Blue Geometry  → VisibleState  (partitioned by partitionLogic latentBarrier)
|||   Red  Geometry  → LatentState   (coefficients >= latentBarrier)
|||   Green Geometry → ResidueState  (produced by evaluateResonance)
public export
0 PixelIntPoly : Type
PixelIntPoly = Multiset (Geometry, Amplitude)

-----------------------------------------------------------------------
-- 5. UNIVERSE STATE (The Total Cosmological Configuration)
-----------------------------------------------------------------------

||| The complete universe state: a causal substrate graph paired with a
||| quantum state vector.
|||
||| Naming Zoo:
|||   - Physics:  Total Cosmological State / Universe Configuration at Scale N
|||   - Category: Global Section of the Sheaf over the Poset Base Space
|||   - Concrete: (Multiset (G,G), Multiset (G, Vector)) — both pure multisets
|||
||| This is the product type that should be threaded through the full
||| stepRelationalTime pipeline once it is implemented.
public export
record UniverseState where
  constructor MkUniverseState
  ||| The directed causal relations (spacetime / poset / substrate).
  substrate    : Substrate
  ||| The quantum amplitude assignments (matter fields / state vector).
  stateVector  : PixelIntPoly

-----------------------------------------------------------------------
-- 6. SUBSTRATE UTILITIES
-----------------------------------------------------------------------

||| Computes the total causal density (Leibniz Lag) of the Substrate.
|||
||| Naming Zoo:
|||   - Physics:  Local Proper Time / Causal Mesh Delay / Relational Clock Tick
|||   - Category: Total Weight of Arrow Ideals / Poset Morphism Cardinality
|||   - Concrete: sum of multiplicities of all directed edges
|||
||| This replaces MaxelClock.computeCausalLag and the old MaxelNL-based substrateLag.
public export
substrateLag : Substrate -> Nat
substrateLag sub = cast (multiplicityAll sub)

||| Merge two Substrate causal graphs (native multiset union).
|||
||| Naming Zoo:
|||   - Physics:  Causal Merge / Time Step Advance
|||   - Category: Coproduct in the Poset Category
public export
mergeSubstrate : Substrate -> Substrate -> Substrate
mergeSubstrate = addMultiset

||| The empty Substrate (vacuum — no causal relations).
public export
emptySubstrate : Substrate
emptySubstrate = ZeroM

||| A single directed causal edge: g1 causally precedes g2.
public export
singleEdge : Geometry -> Geometry -> Substrate
singleEdge g1 g2 = fromList [((g1, g2), 1)]

||| Extracts all unique Geometry nodes referenced in the Substrate
||| (both parents and children of all edges).
public export
substrateNodes : Substrate -> List Geometry
substrateNodes sub =
  nub (concatMap (\((g1, g2), _) => [g1, g2]) (multisetToList sub))

-----------------------------------------------------------------------
-- 7. PIXEL-INT-POLY UTILITIES
-----------------------------------------------------------------------

||| The empty PixelIntPoly — the physical vacuum state.
public export
emptyPixelIntPoly : PixelIntPoly
emptyPixelIntPoly = ZeroM

||| A singleton PixelIntPoly — a single coordinate mapped to one amplitude.
||| This is the result of ascendScale: the entire micro-graph collapses to one entry.
|||
||| Naming Zoo:
|||   - Physics:  Point Particle / Localized Wavepacket
|||   - Category: Stalk of the Sheaf at a Point / Unit Section
public export
singletonPixelIntPoly : Geometry -> Amplitude -> PixelIntPoly
singletonPixelIntPoly geom amp = fromList [((geom, amp), 1)]

||| Superposition — the native multiset union of two state vectors.
|||
||| Naming Zoo:
|||   - Physics:  Quantum Superposition / State Overlap
|||   - Category: Coproduct of Sheaf Sections / Direct Sum
public export
superposeStates : PixelIntPoly -> PixelIntPoly -> PixelIntPoly
superposeStates = addMultiset

||| The total Leibniz Lag of a PixelIntPoly (sum of all entry multiplicities).
|||
||| Naming Zoo:
|||   - Physics:  Total Energy / Occupation Number / Computational Cost
|||   - Category: Global Sections Cardinality
public export
stateLag : PixelIntPoly -> Integer
stateLag = multiplicityAll

||| Restriction of a PixelIntPoly to entries matching a specific Geometry.
|||
||| This is the sheaf restriction map: pulling back entries from a large
||| open set to a smaller one. In multiset terms: filter by coordinate.
|||
||| Naming Zoo:
|||   - Physics:  Local Measurement / Projection onto a Coordinate
|||   - Category: Restriction Map of the Sheaf
public export
restrictToPixel : Geometry -> PixelIntPoly -> PixelIntPoly
restrictToPixel geom pip =
  fromList (filter (\((g, _), _) => g == geom) (multisetToList pip))

||| Checks that every Geometry referenced in the PixelIntPoly exists as a node
||| in the Substrate causal graph.
|||
||| A synchronised state guarantees the state vector does not reference a
||| spacetime location that has no causal history. An unsynchronised state
||| indicates a torn sheaf — undefined physics.
|||
||| Naming Zoo:
|||   - Physics:  Causal Consistency / No-Signalling Check
|||   - Category: Gluing Condition of the Sheaf
public export
isSynchronised : Substrate -> PixelIntPoly -> Bool
isSynchronised sub pip =
  let subNodes = substrateNodes sub
      pipCoords = map (fst . fst) (multisetToList pip)
  in all (\g => elem g subNodes) pipCoords
