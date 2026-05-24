module Physics.Evolution.Transform

import Physics.Evolution.State
import Physics.Core
import Math.Chromogeometry

import Math.UnaryMultiset
import Math.Multiset
import Math.IntPolynumber
import Data.List
import Data.Vect
import Decidable.Equality

%default total

-----------------------------------------------------------------------
-- 1. THE PARTITION GATE (Latent / Visible Split)
--
-- Naming Zoo:
--   Physics:          The 128/27 Polynomial Splitting Gate / Baryogenesis Filter
--   Category Theory:  Sheaf Restriction Map / Tensor Factorisation over Objects
--   Concrete:         Filters IntPolynumber terms by coefficient threshold.
--                     coeff >= latentBarrier → LatentState (Red Metric / Dark Energy)
--                     coeff <  latentBarrier → VisibleState (Blue Metric / Matter)
-----------------------------------------------------------------------

||| Evaluates if a given monomial term coefficient belongs to the Latent band.
isLatentTerm : Integer -> ((Nat, Nat), Integer) -> Bool
isLatentTerm latentBarrier (_, coef) = coef >= latentBarrier

||| The fundamental partition gate. 
public export
partitionLogic : Integer 
              -> PixelNL Integer
              -> IntPolynumber 
              -> (Multiset (PixelNL Integer, IntPolynumber), Multiset (PixelNL Integer, IntPolynumber))
partitionLogic latentBarrier geom rawTerms_mset =
  let (latentTerms, visibleTerms) = partition (isLatentTerm latentBarrier) (multisetToList rawTerms_mset)
      latentPoly  = fromList latentTerms
      visiblePoly = fromList visibleTerms
      latentSpace  = fromList [( (geom, latentPoly), 1 )]
      visibleSpace = fromList [( (geom, visiblePoly), 1 )]
  in (latentSpace, visibleSpace)

-----------------------------------------------------------------------
-- 2. THE RESONANCE GATE (Modulo Shattering)
--
-- Naming Zoo:
--   Physics:          n=13 Resonance Scattering / Wavefunction Collapse / Decoherence
--   Category Theory:  Sheaf Radical Subtraction / Ideal of the Polynumber Algebra
--   Concrete:         If totalLag > capacityLimit, shatters every visible polynomial
--                     term through a modulo filter, producing the ResidueState (Green Metric).
-----------------------------------------------------------------------

||| Evaluates polynomial shattering on a single monomial term using a specific modulo base.
shatterTerm : Integer -> ((Nat, Nat), Integer) -> ((Nat, Nat), Integer)
shatterTerm moduloBase (powers, coef) = 
  let residue = coef `mod` moduloBase
  in (powers, residue)

||| The Resonance Filter.
public export
evaluateResonance : Integer 
                 -> Integer
                 -> PixelNL Integer 
                 -> Multiset (PixelNL Integer, IntPolynumber) 
                 -> Multiset (PixelNL Integer, IntPolynumber)
evaluateResonance capacityLimit moduloBase geom visibleSpace@items_mset =
  let totalLag = multiplicityAll visibleSpace
  in if totalLag > capacityLimit
        then 
          let allTerms = concatMap (\((_, polyItems_mset), count) => 
                                      map (\(p, c) => (p, c * count)) (multisetToList polyItems_mset)) (multisetToList items_mset)
              shatteredTerms = map (shatterTerm moduloBase) allTerms
              residuePoly    = fromList shatteredTerms
          in fromList [( (geom, residuePoly), 1 )]
        else 
          visibleSpace

-----------------------------------------------------------------------
-- 3. THE ASCENSION GATE (Scale N -> N+1)
--
-- Naming Zoo:
--   Physics:          Scale Ascension / Emergence Phase Transition / Holonomy Collapse
--   Category Theory:  Corestriction / Left Adjoint Direct Image Section
--   Concrete:         Folds all micro-polynomials into a single macro-node via addMultiset.
--                     The result is a singleton FiberBundle at Scale N+1.
-----------------------------------------------------------------------

||| Scalar-only ascension check.
||| Use buildAscensionCapacities for the full three-fold proof.
public export
checkAscension : Integer -> Multiset (PixelNL Integer, IntPolynumber) -> Bool
checkAscension capacityLimit stateSpace =
  let totalLag = multiplicityAll stateSpace
  in totalLag == capacityLimit

||| Macro Scale Condensation.
public export
ascendScale : PixelNL Integer 
           -> Multiset (PixelNL Integer, IntPolynumber) 
           -> Multiset (PixelNL Integer, IntPolynumber)
ascendScale macroGeom items_mset =
  let macroPoly = foldl (\acc, ((_, poly), count) =>
                          addMultiset acc (scaleMultiset count poly)
                        ) emptyIntPoly (multisetToList items_mset)
  in fromList [( (macroGeom, macroPoly), 1 )]

-----------------------------------------------------------------------
-- 4. THREE-FOLD ASCENSION PROOF
--
-- Naming Zoo:
--   Physics:          Ascension Conditions / Phase Transition Parameters /
--                     Harmonic Scale Lock / Gauge Closure
--   Category Theory:  Sheaf Cohomology Section Existence Criteria /
--                     Existence of a Global Section / Gluing Condition
--
-- The three requirements (from the FiberBundle / Sheaf Cohomology model):
--
--   Req 1 (residueLag):       A non-zero ResidueState must survive the n=13 gate.
--                             Without raw material (dark matter dust), there is
--                             nothing to aggregate into the macro-node.
--
--   Req 2 (ancestralContext): The Scale N layer must read Scale N-1 boundary
--                             conditions (the Substrate causal density). Without
--                             this, the system lacks a metric to organise its
--                             collective behaviour.
--
--   Req 3 (twistCapacity):    The Chromogeometric A(Q) = T(s) structural lock
--                             must hold. This is the "twisting" or holonomy
--                             that prevents the macro-node from flying apart.
-----------------------------------------------------------------------

||| The three structural capacities required for Scale Ascension.
public export
record AscensionCapacities where
  constructor MkCapacities
  ||| Req 1: Leibniz Lag of the residue after resonance shattering.
  ||| Source: cast (multiplicityAll residueState)
  residueLag       : Nat
  ||| Req 2: Causal density of the Substrate (Scale N-1 ancestral context).
  ||| Source: length (MaxelNL.pixels substrate)
  ancestralContext : Nat
  ||| Req 3: Chromogeometric twist capacity from A(Q) = T(s) structural lock.
  ||| Source: derived from quadranceNL applied to the active Geometry.
  ||| Zero means the structural lock does not hold and ascension is blocked.
  twistCapacity    : Nat

||| The Ascension Proof Obligation.
|||
||| A substrate CAN ascend to Scale (S n) if and only if its three capacities
||| balance exactly to the Leibniz limit. The limit is a parameter (not hardcoded)
||| so the proof remains valid at any fractal scale.
public export
data CanAscend : (limit : Nat) -> AscensionCapacities -> Type where
  MkAscensionProof : {limit : Nat}
                  -> (caps  : AscensionCapacities)
                  -> caps.residueLag + caps.ancestralContext + caps.twistCapacity = limit
                  -> CanAscend limit caps

-----------------------------------------------------------------------
-- 5. SCALE LEVEL HIERARCHY
--
-- Naming Zoo:
--   Physics:          Scale Orders (Quantum → Elemental → Molecular → Biological → Observer)
--   Category Theory:  Inverse Limit / Direct Image Sheaf / Colimit of Local Sections
--   Concrete:         An indexed family of FiberBundle states gated by CanAscend.
-----------------------------------------------------------------------

||| The scale level hierarchy.
||| BaseScale is always valid. AscendedScale is ONLY constructable with a CanAscend proof.
public export
data ScaleLevel : (scaleLevel : Nat) -> Type where
  ||| Base Scale (Quantum foam / primordial vacuum): always valid, no proof required.
  BaseScale : (fb : Multiset (PixelNL Integer, IntPolynumber))
            -> ScaleLevel 0

  ||| Higher-Order Scale Ascension.
  ||| The `limit` (e.g. 137) is carried explicitly so the proof is self-contained.
  ||| Dead scales — where the three capacities do not balance to `limit` — cannot
  ||| construct this node. The Idris 2 type checker enforces this statically.
  AscendedScale : (limit      : Nat)
               -> (macroGeom  : PixelNL Integer)
               -> (microStates : Multiset (PixelNL Integer, IntPolynumber))
               -> (caps       : AscensionCapacities)
               -> CanAscend limit caps
               -> ScaleLevel (S scaleLevel)



-----------------------------------------------------------------------
-- 6. THREE-FOLD ASCENSION CHECK (Chromogeometric Twist Wired In)
-----------------------------------------------------------------------

||| Computes the chromogeometric twist capacity from the A(Q) = T(s) structural lock.
|||
||| The A(Q) = T(s) lock checks whether Archimedes' area function over the three
||| quadrances equals the Triple Spread Formula over the three spreads.
|||
||| The spreads are computed as the angular tension between the geometry pixel
||| and the unit reference direction (1, 0) under each Chromogeometric metric,
||| using the full rational trigonometry formula:
|||   s_m = (a1*b2 - a2*b1)^2 / (Q_m(p1) * Q_m(p2))
|||
||| Returns the absolute sum of the three quadrances as the twist magnitude
||| if the lock holds, or 0 otherwise.
export
computeTwist : PixelNL Integer -> Nat
computeTwist geom =
  let ref    = MkPixelNL 1 0
      qBlue  = quadranceNL Blue  geom
      qRed   = quadranceNL Red   geom
      qGreen = quadranceNL Green geom
      sBlue  = spreadIntNL Blue  geom ref
      sRed   = spreadIntNL Red   geom ref
      sGreen = spreadIntNL Green geom ref
  in if isStructuralLock qBlue qRed qGreen sBlue sRed sGreen
     then cast (abs qBlue + abs qRed + abs qGreen)
     else 0


||| Attempts to build a valid AscensionCapacities record and CanAscend proof
||| from the current physical configuration.
|||
||| Returns Nothing if the three capacities do not balance to the given limit —
||| the system cannot ascend at this tick and either resonance-shatters or
||| remains at the current scale.
public export
buildAscensionCapacities : (limit : Nat)
                        -> (substrate : Substrate)
                        -> (geom      : PixelNL Integer)
                        -> (residue   : Multiset (PixelNL Integer, IntPolynumber))
                        -> Maybe (caps : AscensionCapacities ** CanAscend limit caps)
buildAscensionCapacities limit sub geom residue =
  let residueLag_val = cast (multiplicityAll residue) in
  let ancestral_val  = substrateLag sub in
  let twist_val      = computeTwist geom in
  let caps = MkCapacities residueLag_val ancestral_val twist_val in
  case decEq (caps.residueLag + caps.ancestralContext + caps.twistCapacity) limit of
    Yes prf => Just (caps ** MkAscensionProof caps prf)
    No  _   => Nothing

