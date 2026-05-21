# The Formal Laws of Physics (RCIT)

In the 137-Grid Protocol, the macro-scale "Laws of Physics" are not arbitrary rules or empirical constants. Instead, they are dependently typed proofs that mathematically emerge from the pure geometric algebra of the system. By verifying these laws at compile time, the Idris 2 engine guarantees that the simulation can never violate fundamental conservation principles.

The current verified Laws library (`Physics.Laws.*`) contains the following proofs:

## 1. CPT Symmetry (`Physics.Laws.CPTSymmetry`)
**Charge-Parity-Time Reversal Invariance**
- `cptPixelSymmetry`: Proves that a double-transposition of any transition vector (`Pixel`) strictly returns the original state (`transpose (transpose p) = p`).
- `cptFieldSymmetry`: Inductively proves that reversing the geometry of an entire quantum field (`Maxel`) twice perfectly reconstitutes the field without any metrical loss or data corruption.

## 2. Information Conservation (`Physics.Laws.InformationConservation`)
**The Conservation of Data**
- `informationConservation`: Proves that when two physical states (Multisets) collide or merge, their total informational cardinality (size) is strictly conserved (`size (xs ++ ys) = size xs + size ys`). 
- This formally prevents the engine from artificially duplicating or deleting elements during a physical transition without explicit metrical taxation.

## 3. Conservation of Energy (`Physics.Laws.EnergyConservation`)
**The First Law of Thermodynamics**
- `conservationOfEnergy`: Energy in the grid is modeled strictly as structural geometric tension (`BoxInt` debt). This theorem proves that the total absolute scale (cardinality) of the physical debt of two merged geometries is strictly equal to the sum of their isolated isolated geometric debts. 
- Energy can neither be created nor destroyed; it can only be passed linearly across the 137-Grid substrate.

## 4. Color Confinement (`Physics.Laws.ColorConfinement`)
**The Strong Force Geometric Limit**
- `confinementBaryonProof` & `confinementMesonProof`: Dependently-typed proofs that an isolated Quark (a `Maxel` containing exactly 1 transition) can NEVER evaluate to `True` when checked against the stability audits of a Baryon (Spread 3/4) or Meson (Spread 0/1). 
- Because isolated Quarks fail these geometric audits, they are barred from persisting in the vacuum linearly; they must dynamically "confine" into larger composite structures to shield their structural debt.
