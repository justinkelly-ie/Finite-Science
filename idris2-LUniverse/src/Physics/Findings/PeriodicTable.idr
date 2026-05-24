module Physics.Findings.PeriodicTable

import Physics.Evolution.State
import Physics.Evolution.Transform
import Physics.Evolution.Gate

import Math.Core
import Math.Multiset
import Math.IntPolynumber
import Math.SpreadPolynumber

%default total

||| The Periodic Table and The Feynmanium Limit
|||
||| In standard physics, Richard Feynman predicted that element 137 
||| (Untriseptium, or Feynmanium) represents an absolute physical limit.
|||
||| In the LUniverse model, Element Z is an accumulation of Z baryonic
||| units passed through the resonance gate (n=13). The gate shatters
||| any state whose total lag exceeds the capacity limit (137):
|||
|||   Z ≤ 137 → survives resonance → stable element
|||   Z > 137 → shattered mod 13   → decoherence (radioactive decay)
|||
||| Element 137 is not a speed limit — it is a combinatorial storage limit!
||| The periodic table IS the n=13 resonance boundary at the Elemental scale.
|||
||| Oxygen (Z=8) as the Universal Mediator
|||
||| Oxygen occupies a unique structural position in the 128/27 partition:
|||
|||   128 / 8 = 16  — Oxygen divides the dark energy pool (2^7) perfectly
|||   27 mod 8 = 3   — Its remainder in visible matter IS the MatterGate degree
|||   210 / 8        — Does NOT divide the primorial manifold
|||
||| Oxygen is the bridge between the latent sector (2^7 = 128) and the
||| visible sector (3^3 = 27). It can partition the dark energy pool into
||| exactly 16 equal quanta, and its residue in the visible sector
||| (27 mod 8 = 3) is exactly the MatterGate — the gate that generates
||| visible structure. This is why Oxygen is the universal electron
||| acceptor driving metabolism: it mediates the transfer from latent
||| energy to visible matter.

-----------------------------------------------------------------------
-- CONSTANTS (from the pipeline)
-----------------------------------------------------------------------

||| The capacity limit at which resonance shattering triggers.
capacityLimit : Integer
capacityLimit = 137

||| The modulo base for the n=13 resonance gate.
moduloBase : Integer
moduloBase = 13

-----------------------------------------------------------------------
-- ELEMENT CONSTRUCTION
-----------------------------------------------------------------------

||| Constructs an elemental state vector for atomic number Z.
||| Each proton contributes one unit of baryonic lag at the elemental
||| geometry. The spread polynomial S_1 is the unit baryon — Z protons
||| means multiplicity Z. The resonance gate checks if Z > 137.
public export
elementalState : (z : Nat) -> PixelNL Integer -> Multiset (PixelNL Integer, IntPolynumber)
elementalState z geom =
  let unitBaryon = spreadPoly 1
  in fromList [((geom, unitBaryon), cast z)]

||| Tests whether an element at atomic number Z survives the resonance gate.
||| If the total lag exceeds 137, the resonance gate shatters the state
||| and the element is unstable (decoheres).
|||
||| This derives the Feynman limit from the pipeline — no hardcoded Fin 138.
public export
isStableElement : (z : Nat) -> Bool
isStableElement z =
  let geom  = MkPixelNL 0 0
      state = elementalState z geom
      afterResonance = evaluateResonance capacityLimit moduloBase geom state
  in stateLag afterResonance == stateLag state

-----------------------------------------------------------------------
-- THE PERIODIC TABLE (derived from stability)
-----------------------------------------------------------------------

||| An Element is a state vector at the Elemental scale that has
||| survived the resonance gate. The atomic number Z is the baryon count.
public export
record Element where
  constructor MkElement
  atomicNumber : Nat
  stateVector  : Multiset (PixelNL Integer, IntPolynumber)
  stable       : isStableElement atomicNumber = True

-----------------------------------------------------------------------
-- STANDARD ELEMENTS
-----------------------------------------------------------------------

public export
Hydrogen : Element
Hydrogen = MkElement 1 (elementalState 1 (MkPixelNL 0 0)) Refl

public export
Carbon : Element
Carbon = MkElement 6 (elementalState 6 (MkPixelNL 0 0)) Refl

||| Oxygen (Z=8): the universal mediator.
|||
||| Structural position in the 128/27 partition:
|||   - 8 = 2^3 (BackgroundGate cubed)
|||   - 128 / 8 = 16 (divides dark energy pool exactly)
|||   - 27 mod 8 = 3  (remainder = MatterGate degree)
|||   - Does NOT divide the primorial (210)
|||
||| This makes Oxygen the bridge between the latent and visible sectors:
||| it partitions dark energy into 16 equal quanta and its remainder in
||| visible matter is the MatterGate — the gate that generates structure.
public export
Oxygen : Element
Oxygen = MkElement 8 (elementalState 8 (MkPixelNL 0 0)) Refl

||| Iron (Z=26): the stellar fusion limit.
||| Heaviest element producible by core fusion before gravitational collapse.
public export
Iron : Element
Iron = MkElement 26 (elementalState 26 (MkPixelNL 0 0)) Refl

||| The absolute maximum stable element on the grid.
||| Z=137 survives the resonance gate. Z=138 does not.
public export
Feynmanium : Element
Feynmanium = MkElement 137 (elementalState 137 (MkPixelNL 0 0)) Refl

-----------------------------------------------------------------------
-- STRUCTURAL FINDINGS
-----------------------------------------------------------------------

||| The BackgroundGate quantum: adding S_2 to any element always
||| contributes exactly 8 units of lag (the vacuum fluctuation quantum).
public export
vacuumQuantum : Integer
vacuumQuantum = multiplicityAll (spreadPoly 2)

||| Oxygen divides the dark energy pool (128 = 2^7) exactly.
||| 128 / 8 = 16 quanta.
public export
oxygenDividesLatent : (div 128 8 = 16)
oxygenDividesLatent = Refl

||| Oxygen's remainder in visible matter (27 = 3^3) is exactly 
||| the MatterGate degree (n=3).
public export
oxygenVisibleResidue : (mod 27 8 = 3)
oxygenVisibleResidue = Refl

||| Oxygen does NOT divide the primorial manifold (210).
||| This is why it acts as a mediator rather than a structural primitive.
public export
oxygenNotPrimorial : (mod 210 8 = 2)
oxygenNotPrimorial = Refl

||| The total count of stable elements is exactly 137.
||| (Checked at runtime by the test suite, verified compile-time for
||| individual elements via the `stable` field's Refl proof.)
public export
stableElementCount : Nat
stableElementCount = length (filter id (map isStableElement [1..150]))
