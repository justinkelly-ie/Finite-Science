module Math.Chromogeometry

import Math.BoxInt
import Math.Maxel
import Math.MaxelNL
import Math.UnaryMultiset
import Math.Interfaces

%default total

-----------------------------------------------------------------------
-- 1. THE THREE METRICS (BLUE, RED, GREEN)
-----------------------------------------------------------------------

||| The three fundamental planar geometries of Chromogeometry.
public export
data Metric = Blue | Red | Green
public export
implementation Eq Metric where
  Blue == Blue = True
  Red == Red = True
  Green == Green = True
  _ == _ = False

public export
implementation Show Metric where
  show Blue = "Blue"
  show Red = "Red"
  show Green = "Green"



-- ||| The Chromogeometric Quadrance (Q)
-- ||| Linear version: Ensures each atom is used exactly once for the valuation.
-- public export
-- quadrance : (m : Metric) -> (val : (1 _ : a) -> BoxInt) -> (1 _ : Pixel a) -> BoxInt
-- quadrance Blue v (Builtin.(#) l r) =
--   let Builtin.(#) va1 va2 = lcomult (v l)
--       Builtin.(#) vb1 vb2 = lcomult (v r)
--   in boxAdd (boxMult va1 va2) (boxMult vb1 vb2)
-- quadrance Red v (Builtin.(#) l r) =
--   let Builtin.(#) va1 va2 = lcomult (v l)
--       Builtin.(#) vb1 vb2 = lcomult (v r)
--   in boxSub (boxMult va1 va2) (boxMult vb1 vb2)
-- quadrance Green v (Builtin.(#) l r) =
--   let Builtin.(#) va1 va2 = lcomult (v l)
--       Builtin.(#) vb1 vb2 = lcomult (v r)
--       term1 = boxMult va1 vb1
--       term2 = boxMult va2 vb2
--   in boxAdd term1 term2

-----------------------------------------------------------------------
-- 2. ARCHIMEDES' FUNCTION & THE TRIPLE QUAD FORMULA
-----------------------------------------------------------------------

-- ||| Archimedes' Function A(Q1, Q2, Q3).
-- ||| A(Q1, Q2, Q3) = (Q1 + Q2 + Q3)pow2 - 2(Q1pow2 + Q2pow2 + Q3pow2).
-- public export
-- archimedes : (1 _ : BoxInt) -> (1 _ : BoxInt) -> (1 _ : BoxInt) -> BoxInt
-- archimedes q1 q2 q3 =
--   let Builtin.(#) q1a q1b = lcomult q1
--       Builtin.(#) q1c q1d = lcomult q1b
--       Builtin.(#) q2a q2b = lcomult q2
--       Builtin.(#) q2c q2d = lcomult q2b
--       Builtin.(#) q3a q3b = lcomult q3
--       Builtin.(#) q3c q3d = lcomult q3b
--       sum1 = boxAdd q1a (boxAdd q2a q3a)
--       Builtin.(#) sum1a sum1b = lcomult sum1
--       sumSq = boxMult sum1a sum1b
--       q1Sq = boxMult q1c q1d
--       q2Sq = boxMult q2c q2d
--       q3Sq = boxMult q3c q3d
--       sumOfSq = boxAdd q1Sq (boxAdd q2Sq q3Sq)
--       Builtin.(#) sqA sqB = lcomult sumOfSq
--       twoSumSq = boxAdd sqA sqB
--   in boxSub sumSq twoSumSq

-- ||| The Chromogeometric Invariant Theorem.
-- ||| Proves the Quadrea (A) is identical across all three colors.
-- public export
-- verifyChromogeometry : (1 _ : BoxInt) -> (1 _ : BoxInt) -> (1 _ : BoxInt) -> Bool
-- verifyChromogeometry ab ar ag =
--   let Builtin.(#) ar1 ar2 = lcomult ar
--       Builtin.(#) ok1 (Builtin.(#) res_ab res_ar1) = lEq ab ar1
--       Builtin.(#) ok2 (Builtin.(#) res_ar2 res_ag) = lEq ar2 ag
--       () = lconsume res_ab
--       () = lconsume res_ar1
--       () = lconsume res_ar2
--       () = lconsume res_ag
--   in case ok1 of
--        True => case ok2 of
--          True => True
--          False => False
--        False => case ok2 of
--          True => False
--          False => False

-----------------------------------------------------------------------
-- 3. COSMOLOGICAL PRESSURE (CHROMOGEOMETRIC)
-----------------------------------------------------------------------

-- ||| Calculates the 'Color Pressure' of a Maxel lattice.
-- ||| Sums the quadrances of all transitions within a specific metric.
-- public export
-- colorPressure : (m : Metric) -> (val : (1 _ : a) -> BoxInt) -> (1 _ : UnaryMultiset (Pixel a)) -> BoxInt
-- colorPressure m v Zero = Zero
-- colorPressure m v (Add p ps) = 
--   let q = Math.Chromogeometry.quadrance m v p
--       s = colorPressure m v ps
--   in boxAdd q s

-----------------------------------------------------------------------
-- 4. GEOMETRIC AUDIT
-----------------------------------------------------------------------

-- ||| Checks if a transition P1 * P2 = P3 is a 'flat' identity (Triple Quad = 0).
-- ||| Exact Integer equality ensures no rounding errors in the Rational Spacetime Lattice.
-- public export
-- tripleQuadAudit : (LComonoid a) => (m : Metric) -> (val : (1 _ : a) -> BoxInt) -> (1 _ : Pixel a) -> (1 _ : Pixel a) -> (1 _ : Pixel a) -> Bool
-- tripleQuadAudit m v p1 p2 p3 =
--   let (p1a # p1b) = lcomult p1
--       (p2a # p2b) = lcomult p2
--       (p3a # p3b) = lcomult p3
--       q1 = Math.Chromogeometry.quadrance m v p1a
--       q2 = Math.Chromogeometry.quadrance m v p2a
--       q3 = Math.Chromogeometry.quadrance m v p3a
--       res = archimedes q1 q2 q3
--       Builtin.(#) ok (Builtin.(#) res_a zero_a) = lEq res Zero
--       () = lconsume res_a
--       () = lconsume zero_a
--   in case lconsume p1b of
--        () => case lconsume p2b of
--          () => case lconsume p3b of
--            () => ok

-----------------------------------------------------------------------
-- 5. PIVOT PRIMITIVES (The Logical Foundations of Flavor and Color)
-----------------------------------------------------------------------

-- ||| ColorPivot: A transition between two distinct metrics (geometries).
-- ||| This is the mathematical basis for the Gluon.
-- public export
-- 0 ColorPivot : Type
-- ColorPivot = Pixel Metric

-- ||| MetricPivot: A configuration transition that carries a specific 
-- ||| metric-basis association. This is the mathematical basis for the Quark.
-- public export
-- record MetricPivot a where
--   constructor MkPivot
--   basis : Metric
--   transition : Pixel a

-- public export
-- implementation (Show a) => Show (MetricPivot a) where
--   show (MkPivot b t) = "MkPivot " ++ show b ++ " " ++ show t


-----------------------------------------------------------------------
-- 6. LEGACY INTEGER BRIDGES (For Incremental Refactoring)
-----------------------------------------------------------------------

-- ||| Unwraps the archimedes function into an Integer for legacy module boundaries.
public export
archimedesUr : Integer -> Integer -> Integer -> Integer
archimedesUr q1 q2 q3 = (q1 + q2 + q3) * (q1 + q2 + q3) - 2 * (q1*q1 + q2*q2 + q3*q3)

||| The Triple Spread Formula T(s1, s2, s3).
||| Evaluates the quantum angular tension of an Omega Triangle.
||| T(s1, s2, s3) = (s1 + s2 + s3)^2 - 2(s1^2 + s2^2 + s3^2) + 4 * s1 * s2 * s3
public export
tripleSpreadUr : Integer -> Integer -> Integer -> Integer
tripleSpreadUr s1 s2 s3 = 
  let sum = s1 + s2 + s3
      sumSq = sum * sum
      sqSum = s1*s1 + s2*s2 + s3*s3
      prod = 4 * s1 * s2 * s3
  in sumSq - (2 * sqSum) + prod

||| Evaluates the A(Q) = T(s) structural lock limit.
||| A particle maintains stability if its geometric area (Archimedes)
||| equals its internal angular tension (Triple Spread).
public export
isStructuralLock : Integer -> Integer -> Integer -> Integer -> Integer -> Integer -> Bool
isStructuralLock q1 q2 q3 s1 s2 s3 =
  archimedesUr q1 q2 q3 == tripleSpreadUr s1 s2 s3

||| Non-linear (Integer) calculation of quadrance.
public export
quadranceNL : Metric -> PixelNL Integer -> Integer
quadranceNL Blue (MkPixelNL x y) = x*x + y*y
quadranceNL Red (MkPixelNL x y) = x*x - y*y
quadranceNL Green (MkPixelNL x y) = x*y + y*x -- or 2xy

||| Non-linear (Integer) perpendicularity audit.
public export
isPerpendicularNL : Metric -> PixelNL Integer -> PixelNL Integer -> Bool
isPerpendicularNL Blue (MkPixelNL a1 b1) (MkPixelNL a2 b2) = (a1 * a2 + b1 * b2) == 0
isPerpendicularNL Red (MkPixelNL a1 b1) (MkPixelNL a2 b2) = (a1 * a2 - b1 * b2) == 0
isPerpendicularNL Green (MkPixelNL a1 b1) (MkPixelNL a2 b2) = (a1 * b2 + b1 * a2) == 0

-----------------------------------------------------------------------
-- 6b. SPREAD (Angular Tension Between Two Directions)
--
-- Naming Zoo:
--   Physics:          Angular Tension / Twist Capacity / Phase Angle
--   Category Theory:  Cosheaf Angular Measurement / Metric Form Restriction
--   Rational Trig:    Spread s(l1, l2) = (a1*b2 - a2*b1)^2 / (Q(l1) * Q(l2))
--
-- The spread measures the angular separation between two direction vectors
-- in each of the three Chromogeometric metrics. In the Blue metric this is
-- the classical sin²(θ). In Red and Green it has hyperbolic and product
-- interpretations respectively.
-----------------------------------------------------------------------

||| Cross product of two 2D direction vectors: a1*b2 - a2*b1.
||| This is the fundamental building block for spread computation.
public export
crossNL : PixelNL Integer -> PixelNL Integer -> Integer
crossNL (MkPixelNL a1 b1) (MkPixelNL a2 b2) = a1 * b2 - a2 * b1

||| The spread numerator: (a1*b2 - a2*b1)^2.
||| Always non-negative. Equal to zero iff the two directions are parallel.
public export
spreadNumeratorNL : PixelNL Integer -> PixelNL Integer -> Integer
spreadNumeratorNL p1 p2 =
  let c = crossNL p1 p2
  in c * c

||| The full spread between two direction vectors under a given Metric.
|||
||| Returns (numerator, denominator) where:
|||   numerator   = (cross product)^2
|||   denominator = Q_m(p1) * Q_m(p2)
|||
||| The spread is exactly numerator / denominator.
||| Returns (0, 1) if either direction has zero quadrance (degenerate).
|||
||| Naming Zoo:
|||   Physics:        sin²(θ) in Blue / sinh²(θ) in Red
|||   Rational Trig:  s(l1, l2) = (a1*b2 - a2*b1)^2 / (Q1 * Q2)
public export
spreadNL : Metric -> PixelNL Integer -> PixelNL Integer -> (Integer, Integer)
spreadNL m p1 p2 =
  let q1  = quadranceNL m p1
      q2  = quadranceNL m p2
      num = spreadNumeratorNL p1 p2
      den = q1 * q2
  in if den == 0 then (0, 1) else (num, den)

||| Integer-approximate spread: returns the spread numerator divided by the
||| denominator using integer division. Exact when the spread is rational
||| with integer value (e.g., s = 0 or s = 1 for perpendicular directions).
|||
||| This is the form used by computeTwist for the ascension check, where
||| we need a Nat-compatible value.
public export
spreadIntNL : Metric -> PixelNL Integer -> PixelNL Integer -> Integer
spreadIntNL m p1 p2 =
  let (num, den) = spreadNL m p1 p2
  in if den == 0 then 0 else div num den


-- ||| Checks if two vectors (represented as Pixels) are perpendicular
-- ||| according to the specified Chromogeometric Metric.
-- public export
-- isPerpendicular : Metric -> (1 _ : Pixel BoxInt) -> (1 _ : Pixel BoxInt) -> Bool
-- isPerpendicular Blue (Builtin.(#) a1 b1) (Builtin.(#) a2 b2) =
--   let a1a2 = boxMult a1 a2
--       b1b2 = boxMult b1 b2
--       sum  = boxAdd a1a2 b1b2
--       Builtin.(#) ok (Builtin.(#) res_a zero_a) = lEq sum Zero
--       () = lconsume res_a
--       () = lconsume zero_a
--   in ok
-- isPerpendicular Red (Builtin.(#) a1 b1) (Builtin.(#) a2 b2) =
--   let a1a2 = boxMult a1 a2
--       b1b2 = boxMult b1 b2
--       diff = boxSub a1a2 b1b2
--       Builtin.(#) ok (Builtin.(#) res_a zero_a) = lEq diff Zero
--       () = lconsume res_a
--       () = lconsume zero_a
--   in ok
-- isPerpendicular Green (Builtin.(#) a1 b1) (Builtin.(#) a2 b2) =
--   let a1b2 = boxMult a1 b2
--       b1a2 = boxMult b1 a2
--       sum  = boxAdd a1b2 b1a2
--       Builtin.(#) ok (Builtin.(#) res_a zero_a) = lEq sum Zero
--       () = lconsume res_a
--       () = lconsume zero_a
--   in ok
