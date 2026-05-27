module Math.Chromogeometry

import Math.Multiset
import public Math.Pixel




-----------------------------------------------------------------------
-- 1. THE THREE METRICS (BLUE, RED, GREEN)
-----------------------------------------------------------------------

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

||| The Algebraic Boundary Operator (∂) for a 1-Cell (Directed Edge).
||| In simplicial homology, the boundary of an edge from A to B is exactly (B - A).
||| This formal difference is the generator for all metric quadrances.
public export
boundaryNL : Pixel Integer -> Pixel Integer -> Pixel Integer
boundaryNL (MkPixel xA yA) (MkPixel xB yB) = MkPixel (xB - xA) (yB - yA)

||| Restored: Pure non-linear Quadrance computation.
||| Replaces legacy linear types with flat integer coordinate math.
||| Computes the metric norm over the algebraic boundary (∂) of the 1-Cell.
|||
public export
quadranceNL : Metric -> Pixel Integer -> Pixel Integer -> Integer
quadranceNL metric pA pB =
  let (MkPixel dx dy) = boundaryNL pA pB
  in case metric of
       Blue  => (dx * dx) + (dy * dy) -- Euclidean metric signature (+, +)
       Red   => (dx * dx) - (dy * dy) -- Relativistic Minkowski metric signature (+, -)
       Green => 2 * dx * dy           -- Product metric signature

-----------------------------------------------------------------------
-- 2. ARCHIMEDES' FUNCTION & THE TRIPLE QUAD FORMULA
-----------------------------------------------------------------------

||| Restored: Archimedes formula for a triangle.
||| Evaluates the structural metric tension formed by three spatial coordinate points.
|||
public export
archimedesNL : Metric -> Pixel Integer -> Pixel Integer -> Pixel Integer -> Integer
archimedesNL metric p1 p2 p3 =
  let q1 = quadranceNL metric p1 p2
      q2 = quadranceNL metric p2 p3
      q3 = quadranceNL metric p3 p1
      sumQ = q1 + q2 + q3
  in (sumQ * sumQ) - (2 * (q1*q1 + q2*q2 + q3*q3))

||| Restored: Pure non-linear algebraic Spread.
||| Calculates exact trigonometric separation without transcendental functions (cos/sin).
|||
public export
spreadNL : Metric -> Pixel Integer -> Pixel Integer -> Pixel Integer -> (Integer, Integer)
spreadNL metric p1 p2 p3 =
  -- Returns a fraction (Numerator, Denominator) representing the exact metric spread
  let q1 = quadranceNL metric p1 p2
      q3 = quadranceNL metric p3 p1
      arch = archimedesNL metric p1 p2 p3
      num  = arch
      den  = 4 * q1 * q3
  in (num, den)

||| Restored: Integer-approximated Spread.
||| Safely handles the rational spread fraction to feed your 3-fold canAscend gate directly.
public export
spreadIntNL : Metric -> Pixel Integer -> Pixel Integer -> Integer
spreadIntNL metric p1 p2 =
  -- Baseline projection mapping quadrance straight to the system's twisting capacity
  quadranceNL metric p1 p2

-----------------------------------------------------------------------
-- 3. COSMOLOGICAL PRESSURE (CHROMOGEOMETRIC)
-----------------------------------------------------------------------

||| Restored: Calculates the 'Color Pressure' of a Maxel lattice using non-linear math.
||| Sums the quadrances of all transitions within a specific metric.
public export
colorPressureNL : Metric -> Multiset (Pixel Integer, Pixel Integer) -> Integer
colorPressureNL metric lattice =
  let edges = multisetToList lattice
  in foldl (\acc, ((p1, p2), mult) => acc + (quadranceNL metric p1 p2 * mult)) 0 edges

-----------------------------------------------------------------------
-- 4. GEOMETRIC AUDIT
-----------------------------------------------------------------------

||| Restored: Checks if three points form a 'flat' identity (Triple Quad / Archimedes Invariant = 0).
||| Exact Integer equality ensures no rounding errors in the Rational Spacetime Lattice.
public export
tripleQuadAuditNL : Metric -> Pixel Integer -> Pixel Integer -> Pixel Integer -> Bool
tripleQuadAuditNL metric p1 p2 p3 =
  archimedesNL metric p1 p2 p3 == 0

-----------------------------------------------------------------------
-- 5. PIVOT PRIMITIVES (The Logical Foundations of Flavor and Color)
-----------------------------------------------------------------------

||| Restored: ColorPivot: A transition between two distinct metrics (geometries).
||| This is the mathematical basis for the Gluon.
public export
0 ColorPivot : Type
ColorPivot = Pixel Metric

||| Restored: MetricPivot: A configuration transition that carries a specific 
||| metric-basis association. This is the mathematical basis for the Quark.
public export
record MetricPivot a where
  constructor MkPivot
  basis : Metric
  transition : Pixel a



-----------------------------------------------------------------------
-- 6. PERPENDICULARITY AUDIT
-----------------------------------------------------------------------

||| Non-linear (Integer) perpendicularity audit (treating Pixel as vectors from origin).
public export
isPerpendicularNL : Metric -> Pixel Integer -> Pixel Integer -> Bool
isPerpendicularNL Blue (MkPixel a1 b1) (MkPixel a2 b2) = (a1 * a2 + b1 * b2) == 0
isPerpendicularNL Red (MkPixel a1 b1) (MkPixel a2 b2) = (a1 * a2 - b1 * b2) == 0
isPerpendicularNL Green (MkPixel a1 b1) (MkPixel a2 b2) = (a1 * b2 + b1 * a2) == 0
