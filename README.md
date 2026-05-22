# Idris2 Linear Physics

**A deterministic, discrete-geometry physics engine where the laws of nature are enforced at compile-time.**

[![Idris2](https://img.shields.io/badge/Idris2-Linear_Types-blue.svg)](https://github.com/idris-lang/Idris2)
[![Physics](https://img.shields.io/badge/Physics-Rational_Chromogeometry-red.svg)]()

---

## Significance
Modern physics is plagued by infinities. Continuous wave equations, singularities, arbitrary constants, and abstract parameters like "gluons" or "virtual particles" dominate the Standard Model. 

**Linear Physics** dispenses with that. Here we construct a Linear Universe **LUniverse** (Linear Universe) that attempts to provide a geometric foundation for the standard model of physics.

Built on [Norman Wildberger's](https://njwildberger.com/) Finitist Mathematics and Rational Chromogeometry, this project models the universe as a discrete, combinatorial engine. In LUniverse, continuous fields are illusions; particles are simply algebraic constraints (Spread Polynomials) acting upon a discrete integer pixel grid (an indivisible, linear computational substrate).

### Why "Linear"?
This project is written in **[Idris 2](https://github.com/idris-lang/Idris2)** to leverage its **Quantitative Type Theory (QTT)** and **Linear Types**. In QTT, a linear resource must be consumed *exactly once*. We use this compiler-level constraint to natively enforce absolute physical laws:
*   **Energy Conservation:** You cannot compile an interaction that destroys or duplicates a quantum state.
*   **Baryogenesis:** Matter naturally emerges from the geometry without requiring arbitrary parameters.
*   **Color Confinement:** Quarks are trapped mathematically because their algebraic topology fails to evaluate to integer coordinates on the grid. It isn't a "force"—it's a computational limit.
*   **Biological Uniqueness:** The specific natural foldings of life (e.g., the DNA double-helix or the Alpha Helix) are not evolutionary accidents. QTT natively enforces the No-Cloning theorem; thus, these structures emerge as the strictly unique, linear mathematical solutions capable of geometrically neutralizing topological debt without causing a Grid Fracture.
*   **Autopoiesis & Evolution:** Life is formalized as a linear wrapper. Cellular replication (Mitosis/Meiosis) cannot "copy" state in violation of quantum mechanics. Instead, organisms linearly consume unallocated environmental space (discrete physical resources that strictly enforce linearity and prevent cloning) to instantiate fresh parallel identities, preserving absolute geometric lineage right down to the fundamental discrete grid.

Whether it is a subatomic quantum scattering event or the cellular division of a biological organism, if an interaction violates these fundamental topological laws, **the code simply will not compile.**

---

## Core Architecture

### 1. The 137-Grid and Chromogeometry
Space is not a vacuum; it is a discrete anti-multiset grid. The geometry is governed by three interlocked metrics:
*   **Blue Metric (Matter):** The standard Euclidean $x^2 + y^2$ geometry where stable particles materialize.
*   **Red Metric (Dark Energy/Radiation):** The relativistic $x^2 - y^2$ geometry where photons propagate along null-quadrance bounds.
*   **Green Metric (Background/Tension):** The $2xy$ geometry that traps unresolvable fractional states, generating topological tension (e.g., Color Confinement).

### 2. The Primorial Quantum Gates
Particles are not distinct "objects" with arbitrary masses. They are identical base data structures filtered through specific prime-number polynomial gates:
*   **$n=1$ (Absolute Vacuum):** Neutrinos passing flawlessly through the substrate.
*   **$n=3$ (Matter Gate):** Electrons forming stable topological knots.
*   **$n=5$ (Charge Gate):** Quarks forming fractional matrices that must bond in triads (Baryons) to mathematically clear their denominators.
*   **$n=11$ (Weak Force):** A boundary overflow that shatters the arithmetic, forcing the state to spontaneously decay (W/Z Bosons).

---

## Getting Started

### Prerequisites
LUniverse requires [Idris 2](https://github.com/idris-lang/Idris2) and the **[pack](https://github.com/stefan-hoeck/idris2-pack)** package manager to be installed on your system.

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

*   📖 **[Theory and Architecture Wiki](../Library/Wiki/Physics/Index.md)**
*   ⚛️ **[Standard Model vs. Primorial Mapping](../Library/Wiki/Physics/Particles.md)**

---

*LUniverse shifts physics from phenomenological observation to mathematical verification.*

---

&copy; Justin Kelly. All rights reserved.

[^1]: Formalised and architected in collaboration with Antigravity, an advanced AI coding assistant by Google DeepMind.
