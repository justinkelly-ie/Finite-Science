# Idris2 Linear Physics

**A deterministic, discrete-geometry physics engine where the laws of nature are enforced at compile-time.**

[![Idris2](https://img.shields.io/badge/Idris2-Linear_Types-blue.svg)](https://github.com/idris-lang/Idris2)
[![Physics](https://img.shields.io/badge/Physics-Rational_Chromogeometry-red.svg)]()

---

## Significance
Modern physics is plagued by infinities. Continuous wave equations, singularities, arbitrary constants, and abstract parameters like "gluons" or "virtual particles" dominate the Standard Model. 

**Linear Physics** dispenses with that. Here we construct the **Linear Universe**, which attempts to provide a rational, algebraic and geometric explanation for the observed evidence.

Built on [Norman Wildberger's](https://njwildberger.com/) Finitist Mathematics including Box Aritmetic (Multisets), Chromogeometry and Spread Polynomials, this project models the universe as a discrete, combinatorial engine. In the Linear Universe, continuous fields are unnecessary, particles are moddeled simply as geometric and algebraic constraints, acting on a discrete integer pixel grid.

### Why "Linear"?
This project is written in **[Idris 2](https://github.com/idris-lang/Idris2)** to leverage its **Quantitative Type Theory (QTT)** and **Linear Types**. In QTT, a linear resource must be consumed *exactly once*. We use this compiler-level constraint to natively enforce absolute physical laws:
*   **Energy Conservation:** You cannot compile an interaction that destroys or duplicates a quantum state.
*   **Baryogenesis:** Matter naturally emerges from the geometry without requiring arbitrary parameters.
*   **Color Confinement:** Quarks are trapped mathematically because their algebraic topology fails to evaluate to integer coordinates on the grid. It isn't a "force"—it's a computational limit.
*   **Biological Uniqueness:** The specific natural foldings of life (e.g., the DNA double-helix or the Alpha Helix) are not evolutionary accidents. QTT natively enforces the No-Cloning theorem; thus, these structures emerge as the strictly unique, linear mathematical solutions capable of geometrically neutralizing topological debt without causing a Grid Fracture.
*   **Autopoiesis & Evolution:** Life is modeled as a linear wrapper. Cellular replication (Mitosis/Meiosis) cannot "copy" state in violation of quantum mechanics. Instead, organisms linearly consume unallocated environmental space (discrete physical resources that strictly enforce linearity and prevent cloning) to instantiate fresh parallel identities, preserving absolute geometric lineage right down to the fundamental discrete grid.

Whether it is a subatomic quantum scattering event or the cellular division of a biological organism, if an interaction violates these fundamental topological laws, **the code simply will not compile.**

---

## Core Architecture

### 1. The Grid and Chromogeometry
Space is modeled as 3 discrete Multisets. 
The universe's coordinate space is structurally bounded by the 210 states of the 4th Primorial Spread Polynomial ($2 \times 3 \times 5 \times 7 = 210$). Crucially, these values are **not hardcoded constants**. They emerge natively and dynamically from the combinatorial mathematics, partitioning Maxels into:
* **27 Maxels (Visible Matter):** Resolvable $3^3$ integer states that successfully collapse into stable geometric projections.
* **128 Maxels (Dark Energy):** Unresolvable $2^7$ fractional states that remain spread across the grid, exerting expansional topological pressure.
* **55 Maxels (Dark Matter):** The mathematically emergent residue ($210 - (128 + 27) = 55$) that acts as a latent gravitational halo.


The geometry is governed by Chromogeometry's three interlocked metrics:
*   **Blue Metric (Matter):** The standard Euclidean $x^2 + y^2$ geometry where stable particles materialize as integer states in the discrete space.
*   **Red Metric (Dark Energy/Radiation):** The relativistic $x^2 - y^2$ geometry where photons and other energetic particles propagate along null-quadrance bounds invisble to us.
*   **Green Metric (Background/Tension):** The $2xy$ geometry that traps unresolvable fractional states, generating topological tension (e.g., Color Confinement).

### Fractal Spread Polynomial Composition ###
From the base layer up, spread polynomials compose fractally. If a new substrate is available, the mathematics can continue. If not, the mathematics collapses. The substrate must have properties that can support the same spread polynomial structure.

### 2. The Spread Polynomial Primorial Quantum Gates
The spread polynomial structure is visible in the particle relm. Particles are modeled as identical base data structures filtered through specific prime-number spread polynomial gates:
*   **$n=1$ (Absolute Vacuum):** Neutrinos passing flawlessly through the substrate.
*   **$n=3$ (Matter Gate):** Electrons forming stable topological knots.
*   **$n=5$ (Charge Gate):** Quarks forming fractional matrices that must bond in triads (Baryons) to mathematically clear their fractional denominators.
*   **$n=7$ (Color Gate):** The chromogeometric interactions of quarks and gluons.
*   **$n=11$ (Weak Force):** A boundary overflow that shatters the arithmetic, forcing the state to spontaneously decay (W/Z Bosons).
*   **$n=13$ (Gravitational Gate / Resonance):** Geometric resonance and wave-function collapse (Decoherence), where complex fractional residues push the grid to its computational limits at this point it will compose or collapse. 

### Composition or Collapse ###
After n=13, the spread polynomial primorial structure will either compose or collapse. If it composes, it repeats the cycle in new substrate. If it collapses, it decoheres.

### 3. The Biological Fold
Life is formalized as a linear wrapper that preserves geometric integrity. Biological folding is not a continuous thermodynamic accident; it is the geometric execution of a Spread Polynomial attempting to neutralize topological tension over a finite integer grid.

*   **The Helix Barrier:** The stability of the Alpha Helix and DNA Double Helix structures are enforced by specific geometric "locks". Driven by polynomials (such as $S_{10}$), these structures emerged only once in history because they are the strictly unique, linear mathematical solutions capable of folding and consuming the substrate without violating linearity or causing localized decoherence.
*   **Neurological Folding:** The extreme folding of the cerebral cortex (Cortical Gyri) is modeled at the macro scale by massive polynomials (e.g., $S_{137}$). A dense neuronal substrate naturally generates high-frequency structural locks to neutralize topological tension, maximizing computational capacity.

---

## Getting Started

### Prerequisites
LUniverse requires [Idris 2](https://github.com/idris-lang/Idris2). Use **[pack](https://github.com/stefan-hoeck/idris2-pack)** to install Idris2 and as an Idris2 package manager.

```bash
# 1. Build the project using the Idris 2 Pack manager
pack build idris2-LUniverse.ipkg

# 2. Run the Golden Property-Testing Suite
# (This leverages Hedgehog to formally verify particle interactions)
pack run tests/tests.ipkg
```
If you are unfamiliar with Idris2 but wish to explore the project, download Google Antigravity [^1] and have it assist you with the steps above; you can then prompt it to explore the model textually.

---

## Theoretical Foundation & Wiki
The physics mapping and derivation in this project are massive. If you are a physicist or mathematician looking to audit the transition from orthodox QCD to Deterministic Finitist Arithmetic, please read the Wiki:

*   📖 **[Theory and Architecture Wiki](Library/Wiki/Physics/Index.md)**
*   ⚛️ **[Standard Model vs. Primorial Mapping](Library/Wiki/Physics/Particles.md)**

---

*LUniverse shifts physics from phenomenological observation to mathematical verification.*

---

&copy; Justin Kelly. All rights reserved.

[^1]: Formalised and architected in collaboration with Antigravity, an advanced AI coding assistant by Google DeepMind.
