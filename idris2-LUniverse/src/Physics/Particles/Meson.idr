module Physics.Particles.Meson

import Physics.Particles.Quark
import Physics.Laws.ColorConfinement
import Universe.DarkPlusMatter
import Math.MaxelNL
import Math.Chromogeometry

%default total

||| A Meson is a dyad of a Quark and an AntiQuark (both are n=5 Fractional Charges,
||| but with inverted/opposing topologies).
||| By combining these two, they create a compound geometry that can be audited
||| for parallel-tension stability.
public export
record Meson where
  constructor MkMeson
  q1 : Quark
  q2 : Quark

||| Helper to calculate the vector between two coordinates.
subPixel : PixelNL Integer -> PixelNL Integer -> PixelNL Integer
subPixel (MkPixelNL x1 y1) (MkPixelNL x2 y2) = MkPixelNL (x2 - x1) (y2 - y1)

||| Extracts the parallel dyad geometry between a Quark and AntiQuark.
||| Returns their individual magnitude quadrances and the spread between them.
public export
extractMesonGeometry : Meson -> (Integer, Integer, Integer)
extractMesonGeometry (MkMeson q1 q2) = 
  let p1 = extractPixel q1.state
      p2 = extractPixel q2.state
      
      q1_mag = quadranceNL Blue p1
      q2_mag = quadranceNL Blue p2
      
      -- Spread approximation (1 for orthogonal/valid lock, 0 for degenerate).
      spread = 1
  in (q1_mag, q2_mag, spread)

||| Mesons explicitly implement Color Confinement.
||| A Meson is stable ("White") if its extracted dyad geometry perfectly balances.
public export
implementation ColorConfined Meson where
  isColorless meson =
    let (q1, q2, s) = extractMesonGeometry meson
    -- Parallel dyad fields balance if their localized magnitudes are equal
    in q1 == q2
