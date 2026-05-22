# LUniverse Model Architecture Overview

*Last updated: 2026-05-21*

This document describes the complete, current structure of the `idris2-LUniverse` engine — the high-performance cosmological simulation built on the `DenseAMSet` RLE architecture. It is intended as a reference for all modules, their physical interpretation, and how they interlock.

---

## Module Hierarchy

```
idris2-LUniverse/src/
├── Universe/
│   ├── DarkPlusMatter.idr       # The core state engine & coordinate vector
│   └── CosmicPartition.idr      # The 210-state universal pool
├── Math/
│   └── DiscreteCalculus.idr     # Discrete derivative & integration primitives
└── Physics/
    ├── QuantumGates.idr          # Prime Gate definitions (n=2,3,5,7,11,13)
    ├── WeakForce.idr             # Denominator overflow → Decay products
    ├── Particles/
    │   ├── Electron.idr          # Baseline 1-node topological knot (n=3)
    │   ├── Quark.idr             # Fractional charge state (n=5, unconfined)
    │   ├── Baryon.idr            # 3-Quark composite with ColorConfinement
    │   ├── Meson.idr             # 2-Quark composite (quark-antiquark pair)
    │   └── Photon.idr            # Background field propagation
    ├── Laws/
    │   ├── ColorConfinement.idr  # A(Q) = T(s) structural lock interface
    │   ├── EnergyConservation.idr
    │   ├── PauliExclusion.idr    # No two fermions at same PixelNL coordinate
    │   └── PrimorialConservation.idr # 210-state invariant
    ├── Epochs/
    │   ├── Core.idr              # Linear Epoch type + crunchToBang transition
    │   ├── Baryogenesis.idr      # Epoch 2: 128/55/27 state partition
    │   └── Cosmology.idr         # Epoch 38: pow137 & Eddington Limit
    ├── ScaleOrders/
    │   ├── Observer.idr          # Formal Observer, Decoherence, Consciousness
    │   ├── Fractal.idr           # Fractal scaling interface
    │   └── AdaptiveCycle.idr     # Panarchy 5-phase lifecycle (Unfolding→Residue)
    └── Findings/
        ├── CosmicEnergyBudget.idr       # 61%/26%/13% derivation
        ├── DarkEnergyExpansion.idr      # dilateSpace / applyDarkEnergyExpansion
        ├── DarkMatterFriction.idr       # 55-state vacuum drag
        ├── DoubleSlitInterference.idr   # Fringe pattern via Spread Polynomial
        ├── GravitationalTimeDilation.idr # LeibnizLag / Redshift derivation
        ├── HadronGluonDynamics.idr      # Gluon field topology
        ├── PeriodicTable.idr            # Z=1..137 element definitions
        ├── TullyFisherRelation.idr      # Galactic rotation without Dark Matter halos
        ├── StrongNuclearForce.idr       # Topological zipping / vacuumAnnihilation
        ├── VacuumPairProduction.idr     # Schwinger effect / Hawking radiation
        ├── FineStructureDerivation.idr  # Running alpha from LeibnizLag
        ├── CosmologicalConstant.idr     # Finite vacuum energy (solves 10^120 error)
        └── MassRatios.idr              # Proton/Electron mass ratio derivation
```

---

## The Core Engine: DarkPlusMatter

The central type of the entire engine is `DarkPlusMatter`, a cosmological state vector defined as:

```
record DarkPlusMatter where
  generation   : Nat                        -- Current N of the unfolding
  statePoly    : IntPolynumber              -- Spread Polynomial S_N(s)
  maxelSupport : DenseAMSet (PixelNL Integer) -- The spatial coordinate array
  flavor       : Flavor                     -- Matter | DarkEnergy | Background
```

The key insight is that `maxelSupport` is a **Run-Length Encoded** (`DenseAMSet`) array. Addition is lazy ($O(N)$). Annihilation (`annihilateDense`) is only invoked at Epoch boundaries, eliminating the combinatorial explosion that previously caused OOM failures at Generation 11+.

---

## The Universal State Pool: CosmicPartition

The `constructPrimorialGrid` function generates the canonical 210-state universe:

| Pool | Count | Type | Role |
|---|---|---|---|
| `visibleMatter` | 27 = 3³ | Integer-resolved PixelNL | Baryonic matter (Blue Metric) |
| `darkEnergy` | 128 = 2⁷ | Fractional PixelNL | Expansive pressure (Red Metric) |
| `darkMatter` | 55 = 210 − 155 | Background PixelNL | Vacuum drag / friction |

The `PrimorialConservation` law enforces that these three pools always sum to exactly 210.

---

## The Prime Quantum Gates

Seven fundamental prime gates partition the cosmological state space:

| Gate | n | Physical Role |
|---|---|---|
| BackgroundGate | 2 | Binary background / Neutrino emission |
| MatterGate | 3 | Spatial triadic geometry (Electron, Quark confinement) |
| ChargeGate | 5 | Fractional electric charge / Quark definition |
| TimeGate | 7 | Time dilation — introduces LeibnizLag |
| WeakForceGate | 11 | Denominator overflow → Beta decay |
| ResonanceGate | 13 | Decoherence / Wave-function collapse trigger |
| *(137-Grid limit)* | 137 | Saturation asymptote / Fine Structure Constant |

---

## The Adaptive Cycle (Universal Lifecycle)

Every physical substrate — from quarks to galaxies — obeys the same 5-phase Panarchy model:

```
Unfolding → Expansion → Saturation → Collapse → Residue → Unfolding ...
```

The `Collapse` phase corresponds physically to Wave-Function Collapse (quantum) or a Big Crunch (cosmological). The `Residue` phase seeds the next cycle — this is the engine that drives the 38-cycle scaling of the 137-Grid.

---

## The Observer (Consciousness & Decoherence)

The `Physics.ScaleOrders.Observer` module formalises consciousness as a mathematical structure, not a mystical postulate:

- **Consciousness** = preservation of the identity diagonal `[J, J]` in a Maxel as it scales up through 137-loops (from neurons to neural networks to awareness).
- **Decoherence** = the grid enforcing "Settlement" when local `LeibnizLag > 137`, resolving superpositions to integers to protect the `[J, J]` diagonal.
- The `ScaleOrder` type runs from `Quantum (0)` through `Biological (4)` → `Observer (6)` → `Cosmic (38)`.

---

## Key Derivations (Findings)

All quantities below are derived from first principles — zero free parameters:

| Finding | Standard Physics | Primorial Derivation |
|---|---|---|
| **Dark Energy ratio** | ~68% (observed) | 128/210 = 60.95% (+ 8% time-dilated matter) |
| **Dark Matter ratio** | ~27% (observed) | 55/210 = 26.19% ✓ |
| **Eddington Number** | ~10⁸¹ (measured) | 137³⁸ = 1.568 × 10⁸¹ ✓ |
| **Fine Structure Constant** | α ≈ 1/137 (measured) | Topological saturation limit of the grid |
| **Cosmological Constant** | Off by 10¹²⁰ | Bounded by 210-state discrete pool |
| **p/e mass ratio** | 1836.15 (measured) | Structural array length: proton (3-quark S₅ knot) / electron (unity knot) |
| **Galactic rotation curves** | Require Dark Matter halos | Native velocity-mass law from 55-state vacuum drag |

---

## Particle Definitions

| Particle | Gate | Definition |
|---|---|---|
| **Electron** | n=3 MatterGate | Baseline `DenseAMSet [(PixelNL 0 0, 1)]` — the fundamental unity knot |
| **Quark** | n=5 ChargeGate | Fractional state, *cannot* balance grid alone — Color Confinement enforced by type |
| **Baryon** | n=5 × 3 | Three quarks locked by A(Q) = T(s) triple spread structural lock |
| **Photon** | n=2 BackgroundGate | Background-mode propagation across the Green Metric |
