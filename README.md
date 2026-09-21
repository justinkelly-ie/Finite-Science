# Finite-Science

**A constructive, discrete-mathematical framework for physical law verification, enforcing conservation laws and cosmological structures at compile time in Idris 2.**

[![Idris 2](https://img.shields.io/badge/Idris_2-0.8.0-blue.svg)](https://www.idris-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🔬 Project Overview & Scientific Integration

**Finite-Science** provides a constructive, discrete-mathematical engine for physical law verification built on multiset algebra, Two-Level / Three-Level Type Theory (2LTT / 3LTT) staged compilation, and Quantitative Type Theory (QTT). Expressing physical conservation laws over exact rational numbers (`UnixelFraction`) and signed multiset tokens (`BoxInt`) enables compile-time verification of physical invariants with zero floating-point rounding drift.

This framework complements continuum and differential formulations in modern physics by offering:
- **Constructive & Exact Algebraic Formulations**: Utilizes exact rational trigonometric spreads, integer matrix tensor operations, and total termination (`%default total`) to guarantee exact numerical conservation.
- **Zero-Cost Staged Compilation**: Leverages 2LTT and 3LTT staging to ensure calculation artifacts, observer coordinate frames, and intermediate proof ledgers are evaluated at Stage 1 / Stage 2 and erased at compile time, yielding un-polluted runtime physical payloads ($O(1)$ stack, zero-heap execution).
- **Compile-Time Verification**: Enforces physical conservation laws and symmetry invariants via `%macro` reflection proofs and QuickCheck property test suites.

---

## ⚛️ Why a Physicist Cares: Core Principles & Verification Specifications

The framework addresses key numerical and theoretical challenges in physics through constructive type theory and staged compilation:

### 1. Zero Floating-Point Drift & Exact Conservation Laws
- **Physics Value**: Numerical simulations in quantum dynamics, orbital mechanics, and lattice gauge theories accumulate floating-point rounding errors and non-conservation drift over long time integrations.
- **Constructive Verification**: Formulating state evolution over exact signed integer multisets (`BoxInt`) and exact rational fractions (`UnixelFraction`) guarantees definitionally exact conservation laws ($\Delta E = 0$, $+a \oplus -a = 0$ annihilation).
- **Key Specifications**:
  - [BoxIntAlgebraSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/BoxIntAlgebraSpec.md) (Signed integer arithmetic and Dirac positive/negative cancellation)
  - [BoxelStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/BoxelStagingSpec.md) (1D Boxel additive Dirac cancellation $+137 \oplus -137 = 0$ and mass capacity budget $210$ closure)
  - [MaxelStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/MaxelStagingSpec.md) (2D Maxel matrix product tensor cancellation and Grassmann wedge nilpotency $v \wedge v \to 0$)

### 2. Operational Erasure of Observer Bookkeeping via 2LTT & 3LTT Staging
- **Physics Value**: Gauge choices, coordinate transformations, intermediate tensor index arithmetic, and calculation ledgers are artifacts of the observer's calculation apparatus—not physical state payload.
- **Constructive Verification**: Staged compilation in Two-Level and Three-Level Type Theory (2LTT / 3LTT) guarantees all observer bookkeeping and gauge calculations evaluate at Stage 1 ($\mathcal{U}_1$) / Stage 2 ($\mathcal{U}_2$) and are **100% erased at compile time** via QTT quantity `0` annotations (`0 s : StrictLevel Nat`). What manifests at Stage 0 ($\mathcal{U}_0$) is pure, un-polluted physical state payload ($O(1)$ stack, zero heap allocation).
- **Key Specifications**:
  - [TwoLevelTypeTheoryStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/TwoLevelTypeTheoryStagingSpec.md) (2LTT 2-stage presheaf compilation, QTT 0 erasure, and subfibration reflection functors $L \dashv R$)
  - [ThreeLevelTypeTheoryStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/ThreeLevelTypeTheoryStagingSpec.md) (3LTT inter-cycle staging, `ParameterizedCycleState`, and 3-tier universe stratification)
  - [ThreeLevelHyloSpec.md](file:///var/home/justin/Projects/FinSc-Epoch-Wiki/Library/Wiki/ThreeLevelHyloSpec.md) (3LTT inter-cycle conjugate hylomorphisms and cosmic cycle dynamic state loading)
  - [SpreadStreamStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/SpreadStreamStagingSpec.md) (Coinductive stream deforestation and Gauss totient sum identity $\sum_{d \vert 6} \phi(d) = 6$)

### 3. Structural Concordance with Standard Model & Cosmological Observables
- **Physics Value**: Provides machine-checked proofs connecting discrete multiset nesting depth and prime gate spectra to Standard Model particle families and observational cosmology.
- **Constructive Verification**:
  - **12 Standard Model Matter Fermions & 12 Gauge Force Generators**: The 12-deep nested multiset hierarchy ($\eta_{12} \circ \dots \circ \eta_1$) bijectively maps to the 12 matter fermions ($6$ quarks $+ 6$ leptons) and 12 gauge force channels ($8$ gluons $+ 3$ weak bosons $+ 1$ photon).
  - **CMB Spectral Tilt ($n_s = 53/55 \approx 0.96364$)**: The 13-smooth prime gate spectrum $\mathbb{P}_{13} = \{2, 3, 5, 7, 11, 13\}$ yields exact spectral tilt $n_s = 53/55 \approx 0.96364$, matching Planck 2018 observational data ($0.9649 \pm 0.0042$).
  - **Dark Matter / Baryon Mass Ratio ($\frac{165}{27} \approx 6.11$)**: 3-metric weighted ratio matching empirical astrophysical observations ($\Omega_c / \Omega_b \approx 5.47 - 6.1$).
- **Key Specifications**:
  - [TwelveDeepMultisetPhysicsSpec.md](file:///var/home/justin/Projects/FinSc-Epoch-Wiki/Library/Wiki/TwelveDeepMultisetPhysicsSpec.md) (12-deep multiset hierarchy, Standard Model fermion/boson bijection, and CMB $n_s = 53/55$)
  - [Observer37HypothesisSpec.md](file:///var/home/justin/Projects/FinSc-Epoch-Wiki/Library/Wiki/Observer37HypothesisSpec.md) (37th Epoch observational predictions, weighted DM/VM ratio $165/27$, and 137 scale horizon)
  - [VexelStagingSpec.md](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki/Library/Wiki/VexelStagingSpec.md) (1D Vexel color charge payload $R=[1], G=[2], B=[3]$ and zero-pruning passbands)

---

## 🏗️ 10-Layer Ecosystem Pipeline Architecture

The core pipeline represents a 10-layer constructive sequence from flat multiset primitives up to 37-epoch multi-cyclic cosmological evolution, executable via [`Epoch-all.sh`](file:///var/home/justin/Projects/Epoch-all.sh):

```text
  Layer 10: 37-Epoch Cosmic Evolution & 3LTT Engine  ← (FinSc-Epoch, FinSc-Epoch-Wiki)
                       ▲
  Layer 9: Cosmic Scaling & 137 Horizon               ← (FinSc-Cosmology, FinSc-Cosmology-Wiki)
                       ▲
  Layer 8: Pre-ordered Monoids & Free Energy          ← (FinSc-Thermodynamics, FinSc-Thermodynamics-Wiki)
                       ▲
  Layer 7: Cellular Automata & Lattice Dynamics       ← (FinSc-Cellular, FinSc-Cellular-Wiki)
                       ▲
  Layer 6: Discrete Cell Complexes & Homology        ← (FinSc-Topology, FinSc-Topology-Wiki)
                       ▲
  Layer 5: Emergent Rational Metric Geometry         ← (FinSc-Geometry, FinSc-Geometry-Wiki)
                       ▲
  Layer 4: Dihedral Group & Metric Rotations         ← (FinSc-Dihedron, FinSc-Dihedron-Wiki)
                       ▲
  Layer 3: Balanced Ternary Sifting                  ← (FinSc-Multiset-Ternary, FinSc-Multiset-Ternary-Wiki)
                       ▲
  Layer 2: Fields & Scale Transform Functors         ← (FinSc-Multiset-Transform, FinSc-Multiset-Transform-Wiki)
                       ▲
  Layer 1: Flat Primitives & Box Monoids             ← (FinSc-Multiset-Core, FinSc-Multiset-Core-Wiki)
```

---

## 📚 10-Layer Ecosystem Repository Catalog

| Layer | Domain Library | Literate Verification Wiki | Brief Description |
| :--- | :--- | :--- | :--- |
| **Layer 1** | [`FinSc-Multiset-Core`](file:///var/home/justin/Projects/FinSc-Multiset-Core) | [`FinSc-Multiset-Core-Wiki`](file:///var/home/justin/Projects/FinSc-Multiset-Core-Wiki) | Ground QTT multiset kernel, signed `BoxInt` arithmetic, `Bit` singletons, and free commutative box monoids. |
| **Layer 2** | [`FinSc-Multiset-Transform`](file:///var/home/justin/Projects/FinSc-Multiset-Transform) | [`FinSc-Multiset-Transform-Wiki`](file:///var/home/justin/Projects/FinSc-Multiset-Transform-Wiki) | Scale transformation functors (`ScaleTransform`), inverse scale dualities, and $O(\log N)$ parallel multiset trees. |
| **Layer 3** | [`FinSc-Multiset-Ternary`](file:///var/home/justin/Projects/FinSc-Multiset-Ternary) | [`FinSc-Multiset-Ternary-Wiki`](file:///var/home/justin/Projects/FinSc-Multiset-Ternary-Wiki) | Balanced ternary algebra ($\mathbb{F}_3$), Narayana combinatorial polynomials $N(n,k)$, and 3-state spatial sifting logic. |
| **Layer 4** | [`FinSc-Dihedron`](file:///var/home/justin/Projects/FinSc-Dihedron) | [`FinSc-Dihedron-Wiki`](file:///var/home/justin/Projects/FinSc-Dihedron-Wiki) | Dihedral group $D_4$ symmetries, chromogeometric rotations, and 4D algebraic metric tensor projections. |
| **Layer 5** | [`FinSc-Geometry`](file:///var/home/justin/Projects/FinSc-Geometry) | [`FinSc-Geometry-Wiki`](file:///var/home/justin/Projects/FinSc-Geometry-Wiki) | Emergent discrete rational metric geometry, Wildberger quadrance and spread invariants, and 4-metric spacetime. |
| **Layer 6** | [`FinSc-Topology`](file:///var/home/justin/Projects/FinSc-Topology) | [`FinSc-Topology-Wiki`](file:///var/home/justin/Projects/FinSc-Topology-Wiki) | Discrete cell complexes (`ChainCell n`), topological boundary Nilpotency ($\partial^2 = 0$), and toroidal homology rings. |
| **Layer 7** | [`FinSc-Cellular`](file:///var/home/justin/Projects/FinSc-Cellular) | [`FinSc-Cellular-Wiki`](file:///var/home/justin/Projects/FinSc-Cellular-Wiki) | Discrete cellular automata, lattice field dynamics, local transition rules, and state space propagation. |
| **Layer 8** | [`FinSc-Thermodynamics`](file:///var/home/justin/Projects/FinSc-Thermodynamics) | [`FinSc-Thermodynamics-Wiki`](file:///var/home/justin/Projects/FinSc-Thermodynamics-Wiki) | Bounded pre-ordered monoids, discrete Helmholtz free energy calculation ($F = U - T \cdot S$), and entropic arrow cascades. |
| **Layer 9** | [`FinSc-Cosmology`](file:///var/home/justin/Projects/FinSc-Cosmology) | [`FinSc-Cosmology-Wiki`](file:///var/home/justin/Projects/FinSc-Cosmology-Wiki) | Cosmic budget allocation, 137 fine-structure horizon scaling ($137 - 37 = 100$), and Eddington number bounds ($137^{38}$). |
| **Layer 10** | [`FinSc-Epoch`](file:///var/home/justin/Projects/FinSc-Epoch) | [`FinSc-Epoch-Wiki`](file:///var/home/justin/Projects/FinSc-Epoch-Wiki) | 37-epoch cosmic evolution engine, 3LTT hyper-cycle state loading (`ParameterizedCycleState`), and active inference vacuum rebound. |

---

## 🚀 Building & Verification Suite

### Prerequisites

All builds execute inside the container `fedora-toolbox-44` using Idris 2 (`/var/home/justin/.local/bin/idris2`).

### Pipeline Build & Verification Script

To compile and verify the minimal 10-layer pipeline for `FinSc-Epoch`:

```bash
./Epoch-all.sh
```

### Full Ecosystem Verification

To run all standalone wiki verification suites:

```bash
./verify-all-wikis.sh
```

---

## 🧪 Property Verification Framework

Property verification across the workspace is powered by `idris2-QuickCheck`. To compile and test `idris2-QuickCheck`:

```bash
toolbox run -c fedora-toolbox-44 /var/home/justin/.local/bin/idris2 --build idris2-QuickCheck/idris2-QuickCheck.ipkg
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
