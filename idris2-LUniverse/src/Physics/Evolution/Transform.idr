module Physics.Evolution.Transform

import Physics.Evolution.State
import Math.Core
import Math.Twist
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


-- Naming Zoo Reference:
--   - Physics: Three-Fold Primorial Gauge Barrier / Emergence Threshold Gate
--   - Category Theory: Direct Image Sheaf Monad Functor Verification Section
--   - Implementation: Evaluates the combined weight of the current state, ancestral graph, and twist.

||| Validates if a local space-time region matches the exact 137 Primorial threshold to level up.
||| Driven by your clean list-comprehension triad extractor and GCD-bounded rational twist engine.
public export
canAscend : Metric -> Substrate -> PixelIntPoly -> Bool
canAscend metric substrate stateSpace =
  let -- 1. Current State Output: Total active particle energy density in the State Space
      currentOutput = multiplicityAll stateSpace
      
      -- 2. Ancestral Lag: Total structural linkage counts across the Substrate poset network
      ancestralLag = cast (multiplicityAll substrate)
      
      -- 3. Twisting Capacity: The GCD-reduced, path-summed angular spread curvature
      twistingDegrees = cast (computeTwist metric substrate)
      
      -- Combined combinatoric real estate must meet or breach the 137 Leibniz capacity barrier
      totalComputeValue = currentOutput + ancestralLag + twistingDegrees
  in totalComputeValue >= 137
