# Idris2 Linear Physics

**A deterministic, discrete-geometry physics engine where the laws of nature are enforced at compile-time.**

[![Idris2](https://img.shields.io/badge/Idris2-Linear_Types-blue.svg)](https://github.com/idris-lang/Idris2)
[![Physics](https://img.shields.io/badge/Physics-Rational_Chromogeometry-red.svg)]()
[![Tests](https://img.shields.io/badge/Tests-51_passing-green.svg)]()

---

## Significance
Modern physics is plagued by infinities. Continuous wave equations, singularities, arbitrary constants, and ad-hoc parameters like "gluons" or "virtual particles" dominate the Standard Model. 

**Linear Physics** dispenses with that. Here we construct the **Linear Universe**, which attempts to provide a rational, algebraic and geometric explanation for the observed evidence.

Built on [Norman Wildberger's](https://njwildberger.com/) Finitist Mathematics including Box Arithmetic (Multisets), Chromogeometry and Spread Polynomials, this project models the universe as a discrete, combinatorial engine. In the Linear Universe, continuous fields are unnecessary, particles are modelled simply as geometric and algebraic constraints, acting on a discrete integer pixel grid.

### Why "Linear Physics"?
Originally, this project heavily utilized Idris 2's Quantitative Type Theory (QTT) and Linear Types to structurally enforce conservation laws. However, as the universe scaled, the compiler inevitably exhausted its memory attempting to mathematically track nested linear resource reductions.

We have since stripped away the heavy categorical abstractions and replaced them with an ultra-lean **Pure Multiset Integer Architecture**. Rather than relying on rigid compile-time typestate tracking, the core simulation is now a flat $O(N)$ integer matrix.

*   **Extreme Leanness**: The engine drops arbitrary rational fractions, topological wrappers, and linear variables in favor of raw structural algebraic arrays (`Math.Multiset`).
*   **Exact Integer Calculations**: Using pure non-linear integer cross-multiplication, geometric spreads and quadrances never lose precision.
*   **Automatic Conservation**: Because everything evaluates as flat additions and subtractions across a multiset (`addM`, `subM`), terms automatically annihilate when opposite, guaranteeing perfect conservation of mass and energy naturally.

---

## Key Results

> **48 modules. 53 property tests. Zero failures. No hardcoded constants.**

| Result | Verified By |
|---|---|
| **137 stable elements** derived from the gate pipeline (Feynman limit) | `prop_periodicTableHas137` |
| **Cosmic energy budget** 128/55/27 emerges from Spread Polynomial $S_{13}$ | `prop_cosmicBudgetMatches` |
| **Water's bond triangle** $(4,3) \leftrightarrow (3,4)$ is a **Pythagorean Fixed Point** — encoding all gate degrees simultaneously | `prop_waterIsFixedPoint` |
| **The electron IS the bond** — particle and interaction are the same chromogeometric coordinate | `prop_electronSpreadIsBondSpread` |
| **The hydrogen bond is a null vector** — Red $Q = 0$, a pure $[J,J]$ identity diagonal | `prop_hydrogenBondIsIdentity` |
| **76 of 137 scales are gate-pure**, 61 are decoherent — the grid wall (137) IS decoherence | `coherentScaleCount` |
| **Observer epoch** $k=38$ ($n = 39 = 3 \times 13$) is gate-pure; $137^{38} \approx 10^{81}$ = Eddington Number | `prop_eddingtonIsCoherent` |
| **Gate fingerprint $(25, 7, 24)$ is invariant** across all 137 scales | `fingerprintInvariant` |

---

## Core Architecture

### 1. The Grid and Chromogeometry
Space is modeled as a discrete Multiset (a directed graph of integer pixel coordinates).
The universe's coordinate space is structurally bounded by the 210 states of the 4th Primorial Spread Polynomial ($2 \times 3 \times 5 \times 7 = 210$). These values are **not hardcoded constants** — they emerge from the combinatorial mathematics, partitioning Maxels into:
* **27 Maxels (Visible Matter):** Resolvable $3^3$ integer states that successfully collapse into stable geometric projections.
* **128 Maxels (Dark Energy):** Unresolvable $2^7$ fractional states that remain spread across the grid, exerting expansional topological pressure.
* **55 Maxels (Dark Matter):** The mathematically emergent residue ($210 - (128 + 27) = 55$) that acts as a latent gravitational halo.


The geometry is governed by Chromogeometry's three interlocked metrics:
*   **Blue Metric (Matter):** The standard Euclidean $x^2 + y^2$ geometry where stable particles materialize as integer states in the discrete space.
*   **Red Metric (Dark Energy/Radiation):** The relativistic $x^2 - y^2$ geometry where photons and other energetic particles propagate along null-quadrance bounds invisible to us.
*   **Green Metric (Background/Tension):** The $2xy$ geometry that traps unresolvable fractional states, generating topological tension (e.g., Color Confinement).

### 2. The Spread Polynomial Primorial Quantum Gates
The spread polynomial structure is visible in the particle realm. Particles are modeled as identical base data structures filtered through specific prime-number spread polynomial gates:
*   **$n=2$ (Background Gate):** The fundamental vacuum fluctuation quantum.
*   **$n=3$ (Matter Gate):** Electrons forming stable topological knots.
*   **$n=4$ (Bond Gate):** Molecular bonding — the gate that holds matter together.
*   **$n=5$ (Charge Gate):** Quarks forming fractional matrices that must bond in triads (Baryons) to mathematically clear their fractional denominators.
*   **$n=7$ (Time Gate):** Causal evolution — the chromogeometric interactions of quarks and gluons.
*   **$n=11$ (Weak Force / Decoherence Gate):** A boundary overflow that shatters the arithmetic, forcing the state to spontaneously decay (W/Z Bosons).
*   **$n=13$ (Resonance Gate):** Geometric resonance and wave-function collapse (Decoherence), where complex fractional residues push the grid to its computational limits — at this point it will compose or collapse.

### 3. Composition or Collapse
After n=13, the spread polynomial primorial structure will either compose or collapse. If it composes, it repeats the cycle in new substrate. If it collapses, it decoheres.

---

## The Pythagorean Fixed Point

### Water as the Self-Referential Seed

The H₂O bond triangle at coordinates **(4,3)↔(3,4)** with Oxygen at the origin is a **Pythagorean Fixed Point** — a grid coordinate where the chromogeometric quadrances in all three metrics decode back to gate degrees from the pipeline that generated them.

Reading the single coordinate `(4,3)` in each metric reveals a different gate:

| Metric | Formula | Value | Gate Origin |
|---|---|---|---|
| **Blue** (Euclidean) | $4^2 + 3^2$ | $25 = 5^2$ | ChargeGate² |
| **Red** (Minkowski) | $4^2 - 3^2$ | $7$ | TimeGate |
| **Green** (Product) | $2 \cdot 4 \cdot 3$ | $24 = 8 \times 3$ | Oxygen × MatterGate |
| Coordinates | $(4, 3)$ | — | BondGate, MatterGate |

$(3, 4, 5)$ is the **only** primitive Pythagorean triple whose legs and hypotenuse are all gate degrees. Note that $4$ (BondGate) is the only non-prime gate — and it is precisely the non-primality of the bond that enables the Pythagorean triple to exist. Five of the seven gates are encoded in one coordinate. The bond describes the gates that create the bond.

### The Electron IS the Bond

The electron at position (4,3) has Red quadrance 7 (= TimeGate) and Green quadrance 24 (= Oxygen × MatterGate). The spread between the two bonding electrons equals the bond spread. At the fixed point, the distinction between **particle** and **interaction** dissolves — the electron's position IS the bond geometry.

### Scale Transitions via Self-Addition

The N+1 molecular scale emerges from the sum of the two H positions: $(4,3) + (3,4) = (7,7)$. Each subsequent scale is then reached by adding the fixed point $(4,3)$:

| Scale | Position | Key Property | Identity |
|---|---|---|---|
| **N** (Elemental) | $(4,3)$ | Pythagorean fixed point — encodes all gates | The bond IS the electron |
| **N+1** (Molecular) | $(7,7) = (4,3)+(3,4)$ | Red Q = 0 → null vector → pure [J,J] identity | H-bond IS the identity diagonal |
| **N+2** (Ice/Folding) | $(11,10) = (7,7)+(4,3)$ | Red Q = 21 = 3×7 (folding), Blue Q = 13×17 (decoherence onset) | Matter and Time become reciprocal |

The Archimedes invariant **A(Q) = 196** persists across all three transitions — the chromogeometric signature is inherited.

At N+2, the folding number 21 = MatterGate × TimeGate connects to natural folding: 21/7 = 3 (MatterGate folds from TimeGate polynomial), 21/3 = 7 (TimeGate folds from MatterGate polynomial). Matter and Time are perfectly reciprocal at the ice scale.

---

## The 137-Scale Trajectory

### Gate Fingerprint Invariance

Self-adding (4,3) yields: $\text{position}(k) = (4(k+1),\ 3(k+1))$

The gate fingerprint is **invariant** at every scale:
*   Blue $Q(k) = 25(k+1)^2$ = ChargeGate² × $(k+1)^2$
*   Red $Q(k) = 7(k+1)^2$ = TimeGate × $(k+1)^2$
*   Green $Q(k) = 24(k+1)^2$ = Oxygen×MatterGate × $(k+1)^2$

The only variable is $(k+1)^2$ — the generation number squared. Water's chromogeometric signature persists from quarks to the grid wall.

### Gate Purity and Decoherence

A generation $n = k+1$ is **gate-pure** if it factors entirely into the gate primes $\{2, 3, 5, 7, 11, 13\}$ (i.e., it is 13-smooth). **Decoherence** occurs when $n$ contains a prime beyond the gate hierarchy.

Across all 137 scales:

| Quantity | Value |
|---|---|
| **Total scales** | **137** (the grid wall) |
| **Gate-pure scales** | **76** (55.5%) |
| **Decoherent scales** | **61** (44.5%) |
| **First 16 scales** | All coherent (structure formation) |
| **First decoherence** | $k=16$ ($n=17$, the first prime beyond the gates) |
| **Observer epoch** | $k=38$, $n=39 = 3 \times 13$ = MatterGate × ResonanceGate ✅ |
| **Last gate-pure** | $k=134$, $n=135 = 5 \times 3^3$ = ChargeGate × MatterGate³ |
| **Grid wall** | $k=136$, $n=137$ ❌ (137 is prime, non-gate → irrecoverable decoherence) |

### Why 137?

The resonance gate ($n=13$) shatters any element with $Z > 137$ — this is the Feynman limit derived from the pipeline. On the trajectory side, 137 is prime and non-gate, meaning generation $n=137$ cannot be factored into gate primes. Unlike earlier non-gate primes (17, 19, 23...) which are flanked by gate-pure neighbours, 137 sits at the absolute boundary. The grid wall IS decoherence: the number of stable elements and the number of coherent scales are the same number for the same reason.

### Why Are We at Scale 38?

$n = 39 = 3 \times 13$ = MatterGate × ResonanceGate — the observer epoch sits in a **gate-pure pocket** between two decoherent gaps ($n=38 = 2 \times 19$ and $n=41$, prime). The universe is observable precisely because it is coherent HERE. $137^{38} \approx 1.56 \times 10^{81}$ — matching the Eddington Number (total baryons in the observable universe).

---

## The Periodic Table

Elements are baryonic state vectors passed through the resonance gate ($n=13$). The pipeline derives exactly **137 stable elements** — from Hydrogen ($Z=1$) to Feynmanium ($Z=137$). No hardcoded limits.

### Oxygen (Z=8) — The Universal Mediator

| Property | Value | Significance |
|---|---|---|
| $128 / 8$ | $16$ exactly | Divides the dark energy pool ($2^7$) perfectly |
| $27 \bmod 8$ | $3$ | Remainder = MatterGate degree |
| $8$ | $2^3$ | BackgroundGate cubed |
| Valence | $2$ | BackgroundGate degree — accepts exactly 2 electrons |

### Water (H₂O) — The Molecular Bridge

Water's bond triangle $(4,3) \leftrightarrow (3,4)$ is the Pythagorean Fixed Point. The bond quadrance is ChargeGate², the bond spread is TimeGate²/ChargeGate⁴, the inter-hydrogen distance is BackgroundGate, and the O-H bonds are perpendicular in the Red metric (null-separated in Minkowski space).

---

## The Biological Fold
Life is formalized as a linear wrapper that preserves geometric integrity. Biological folding is not a continuous thermodynamic accident; it is the geometric execution of a Spread Polynomial attempting to neutralize topological tension over a finite integer grid.

*   **The Helix Barrier:** The stability of the Alpha Helix and DNA Double Helix structures are enforced by specific geometric "locks". Driven by polynomials (such as $S_{10}$), these structures emerged only once in history because they are the strictly unique, linear mathematical solutions capable of folding and consuming the substrate without violating linearity or causing localized decoherence.
*   **Neurological Folding:** The extreme folding of the cerebral cortex (Cortical Gyri) is modeled at the macro scale by massive polynomials (e.g., $S_{137}$). A dense neuronal substrate naturally generates high-frequency structural locks to neutralize topological tension, maximizing computational capacity.
*   **Ice Geometry & Folding Reciprocity:** At the N+2 scale, the folding number $21 = 3 \times 7$ (MatterGate × TimeGate) establishes a reciprocity: $21/7 = 3$ (Matter folds from Time) and $21/3 = 7$ (Time folds from Matter). This is the scale at which structure and time become interchangeable.

---

## Project Structure

```
Linear-Physics/
├── idris2-LUniverse/           ← The physics engine (46 modules)
│   ├── src/Simplex/            ← Topological stage (5 modules)
│   │   ├── Core.idr                ← Substrate, Geometry, type aliases
│   │   ├── SigmaLinear.idr         ← Linear Dependent Multisets, Dynamic DPairs
│   ├── src/Evolution/          ← The universal engine (7 modules)
│   │   ├── Gate.idr                ← Adaptive cycle phases
│   │   ├── Cycle.idr               ← The loop
│   ├── src/Physics/            ← The emergent properties
│   │   ├── SigmaBridge.idr         ← Sigma-Linear Execution Engine Bridge
│   │   ├── Particles/              ← Photon, Quark, Baryon, Electron, etc. (8 modules)
│   │   ├── Laws/                   ← Conservation laws (5 modules)
│   │   ├── Findings/               ← Derived physics (16 modules)
│   │   ├── Scales/                 ← Scale transitions (5 modules)
│   │   │   ├── Phylogeny.idr           Fork/merge lineage tree
│   │   │   ├── NaturalFolding.idr      Helix, DNA, cortical folding
│   │   │   ├── PythagoreanFixedPoint.idr   The (4,3) self-referential encoding
│   │   │   ├── IceGeometry.idr         N+2 folding reciprocity
│   │   │   └── ScaleTrajectory.idr     Full 137-scale trajectory
│   │   └── Elements/              ← Derived chemistry (3 modules)
│   │       ├── Hydrogen.idr            Z=1 unit baryon
│   │       ├── Oxygen.idr              Z=8 universal mediator
│       └── Water.idr               H₂O Pythagorean fixed point
│
├── Library/Wiki/Code/           ← Comprehensive Code Architecture
├── idris2-chromogeometry/       ← Wildberger's 3-metric geometry
├── idris2-Multiset/    ← Multiset algebra + topology
└── idris2-QuickCheck/           ← Property-testing suite (53 tests)
```

---

## Getting Started

### Prerequisites
LUniverse requires [Idris 2](https://github.com/idris-lang/Idris2). Use **[pack](https://github.com/stefan-hoeck/idris2-pack)** to install Idris2 and as an Idris2 package manager.

```bash
# 1. Build the main library
pack build idris2-LUniverse/idris2-LUniverse.ipkg

# 2. Run the full unified property-testing suite
./Scripts/run-tests.sh

# Or run it directly from the root package:
pack run Linear-Physics.ipkg
```
If you are unfamiliar with Idris2 but wish to explore the project, download Google Antigravity [^1] and have it assist you with the steps above; you can then prompt it to explore the model textually.

---

## Theoretical Foundation & Wiki
The physics mapping and derivation in this project are massive. If you are a physicist or mathematician looking to audit the transition from orthodox QCD to Deterministic Finitist Arithmetic, please read the Wiki:

*   📖 **[Physics Index](Library/Wiki/Physics/Index.md)** — Overview of research areas and key discoveries
*   💻 **[Code Architecture](Library/Wiki/Code/Index.md)** — Detailed breakdown of the $O(1)$ Sigma-Linear execution engine
*   ✅ **[Verification Matrix](Library/Wiki/Code/Verification_Matrix.md)** — Live QuickCheck properties and Golden test results demonstrating absolute physics adherence
*   ⚛️ **[Primorial Particle Mapping](Library/Wiki/Physics/Particles.md)** — How standard model particles map to spread polynomials, plus Oxygen/Water chemistry
*   🔄 **[Recursive Multiset Composition](Library/Wiki/Physics/Recursive_Composition.md)** — Time, scale, and the 137-scale trajectory as recursive polynomial composition
*   🧮 **[Mathematical Type Architecture](Library/Wiki/Simplex/Types.md)** — How every physical concept is one parameterised Multiset

---

*LUniverse shifts physics from phenomenological observation to mathematical verification.*

---

&copy; Justin Kelly. All rights reserved.

[^1]: Formalised and architected in collaboration with Antigravity, an advanced AI coding assistant by Google DeepMind.
