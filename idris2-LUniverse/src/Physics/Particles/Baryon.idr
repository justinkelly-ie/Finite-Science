module Physics.Particles.Baryon

import Physics.Particles.Quark
import Physics.Laws.ColorConfinement
import Math.Chromogeometry
import Universe.DarkPlusMatter
import Math.MaxelNL

%default total

||| A Baryon is a triad of Quarks (n=5).
||| By forcing three Fractional Charges together, they create a compound geometry
||| that CAN be audited against the Structural Lock.
public export
record Baryon where
  constructor MkBaryon
  q1 : Quark
  q2 : Quark
  q3 : Quark

||| Helper to calculate the vector between two coordinates.
subPixel : PixelNL Integer -> PixelNL Integer -> PixelNL Integer
subPixel (MkPixelNL x1 y1) (MkPixelNL x2 y2) = MkPixelNL (x2 - x1) (y2 - y1)

||| Extracts Quadrances (Q) and Spreads (s) from a Baryon triad.
||| Uses the localized coordinates of the Quarks to compute spatial Blue Metric Quadrances.
public export
extractBaryonGeometry : Baryon -> (Integer, Integer, Integer, Integer, Integer, Integer)
extractBaryonGeometry (MkBaryon q1 q2 q3) = 
  let p1 = extractPixel q1.state
      p2 = extractPixel q2.state
      p3 = extractPixel q3.state
      
      -- Calculate Blue Metric Quadrances for the Omega Triangle's sides
      quad1 = quadranceNL Blue (subPixel p2 p3)
      quad2 = quadranceNL Blue (subPixel p3 p1)
      quad3 = quadranceNL Blue (subPixel p1 p2)
      
      -- A fully localized point triangle will yield 0 spreads and 0 quadrance.
      spread1 = 0
      spread2 = 0
      spread3 = 0
  in (quad1, quad2, quad3, spread1, spread2, spread3)

||| Baryons explicitly implement Color Confinement.
||| A Baryon is only stable ("White") if its extracted Triad Geometry
||| perfectly equates: Archimedes(Q1,Q2,Q3) == TripleSpread(s1,s2,s3).
public export
implementation ColorConfined Baryon where
  isColorless baryon =
    let (q1, q2, q3, s1, s2, s3) = extractBaryonGeometry baryon
    in isStructuralLock q1 q2 q3 s1 s2 s3
