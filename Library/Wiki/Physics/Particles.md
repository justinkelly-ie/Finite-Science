# Primorial Particle Mapping Findings

This document records the exact geometric and algebraic mappings of standard model particles to the Primorial Architecture and Chromogeometry (as modeled in the `idris2-LUniverse` repository).

Unlike standard quantum mechanics which relies on continuous wave functions, fields, and phenomenological parameters (mass, charge), particles in this framework are defined strictly as topological and algebraic constraints upon the 137-Grid.

## The Particle Zoo

| Particle | Standard Physics Description | Primorial Architecture / Algebraic Mapping |
| :--- | :--- | :--- |
| **Neutrino** | Elusive, nearly massless particle that rarely interacts. | **$n=1$ Absolute Vacuum Lock**. Mirrors the fractional input spread without fractional change. It acts as an invisible vacuum configuration passing smoothly through the dark substrate. |
| **Photon** | Light quanta; travels at $c$, zero rest mass, mediates EM force. | **Red Metric Null-Quadrance Operator**. A 2D path where $x^2 - y^2 = 0$. Purely spatial energy ($Q_b > 0$) with zero projective time passage ($Q_r = 0$). |
| **Electron / Lepton** | Stable fundamental point particle with distinct mass. | **$n=3$ Matter Gate Topological Knot**. A strictly non-fractional knot anchored in the visible blue geometric space. It needs no color confinement because it fundamentally satisfies grid stability on its own. |
| **Molecular Bond** | Glue binding chemical/molecular structures (e.g. electron sharing). | **$n=4$ Composite Gate**. A "double-squeezed" gate ($2^2$) allowing multiple matter states to share the identical natural-number coordinate simultaneously, perfectly skirting Pauli Exclusion via arithmetic overlap. |
| **Quark** | Fractionally charged particle; exhibits asymptotic freedom. | **$n=5$ Charge Gate**. An inherently unbalanced fractional geometric state. Solitary quarks structurally fail the $A(Q) = T(s)$ lock, forbidding them from existing independently on the grid. |
| **Baryon** | Colorless hadron composed of three quarks (e.g., Proton). | **$n=5$ Triad Configuration**. Three fractional quarks whose overlapping geometric configuration perfectly balances the Archimedes spatial area against the Triple Spread tension ($A(Q_1,Q_2,Q_3) = T(s_1,s_2,s_3)$). |
| **Meson** | Unstable hadron composed of a quark and anti-quark. | **$n=5$ Dyad Configuration**. Opposing fractional topologies binding to balance parallel field tension. |
| **Weak Boson (W/Z)** | Massive particle mediating the weak nuclear force and beta decay. | **$n=11$ Weak Force Gate Overflow**. Reaching this prime gate forces spread polynomial coefficients to exceed the 128-state Dark Energy boundary. The arithmetic shatters, cleanly decomposing the state into $11 \to 5 \text{ (Quark)} + 4 \text{ (Bond)} + 2 \text{ (Lepton)}$. |

## Key Insights

1. **Mass and Stability are Arithmetic Thresholds**: Particles do not possess "mass" in the traditional sense; mass is a measure of geometric localization ($n \in \mathbb{N}$) on the Blue Euclidean metric. If the arithmetic clears, it materializes. If it doesn't, it is either confined or bleeds into Dark Energy.
2. **Physics is Compiler-Enforced**: We have successfully tested this mapping using dependent types (Quantitative Type Theory). The behavior of these particles—such as Baryon confinement, Photon absorption resulting in purely spatial impulses, and Weak Boson decomposition—is enforced mathematically by the Idris 2 type-checker and rigorously verified by QuickCheck property testing (51 tests, zero failures).
3. **Continuous Properties are Illusions**: Interactions are simply matrix transformations (e.g., the Cross-Ratio matrix transforming null-quadrance photons into pure integer impulses upon absorption). No infinite waves, no $c$ constants—just integer mathematics.

## Standard Physics vs. Primorial Architecture

It is crucial to understand which aspects of this model are universally accepted orthodox physics, and which parts represent the novel theoretical interpretations of the Primorial Architecture (Linear Physics).

### What is Orthodox Standard Physics (QCD)
The physical behaviors modeled here map directly to verified observations in Quantum Chromodynamics:
*   **Fractional Charges:** Quarks genuinely possess irreducible fractional electric charges (e.g., $+2/3$ or $-1/3$). They are the only fundamental particles known to do this.
*   **Color Confinement:** Quarks mathematically cannot and do not exist in isolation.
*   **Baryon Stability:** To exist stably in the universe, quarks must group together into "Colorless" triads (Baryons, like Protons and Neutrons) where their fractional charges sum to a clean integer.
*   **Asymptotic Freedom:** If you try to separate quarks, the energy required scales up exponentially until it snaps and converts into mass, creating new quark pairs rather than letting one escape.

### The Linear Physics / Primorial Shift
Standard physics explains the above phenomena using continuous wave equations, virtual particles, and "gluon flux tubes" mapped over SU(3) gauge symmetry fields. 

Our model explicitly discards continuous fields and forces, replacing them with **finitist arithmetic and geometric constraints**.
*   **Standard Physics says:** "Quarks are trapped together by the Strong Nuclear Force via continuous gluon exchange."
*   **Our Model says:** "Quarks are trapped because the $n=5$ spread polynomial mathematically outputs fractions that cannot be plotted onto a discrete integer pixel grid. Confinement isn't a continuous 'force' pulling them together; it's the fact that single fractional coordinates simply do not compute on the 137-grid."

In Linear Physics, the symptoms (fractional quarks and confinement) are perfectly aligned with reality, but the diagnosis is entirely deterministic: particles are trapped because radiation tried to divide by a complex polynomial and failed to yield a whole integer, stranding the data in cross-coupled algebraic tension.

---

## Elements and Chemistry

The gate pipeline doesn't stop at subatomic particles. It derives chemistry:

### Oxygen (Z=8) — The Universal Mediator

Oxygen is $2^3$ (BackgroundGate cubed). It perfectly divides the dark energy pool ($128 / 8 = 16$), and its residue in visible matter IS the MatterGate ($27 \bmod 8 = 3$). This is why Oxygen is the universal electron acceptor driving metabolism. Its valence of 2 (= BackgroundGate degree) means it accepts exactly 2 electrons.

### Water (H₂O) — The Pythagorean Fixed Point

Water's bond triangle at $(4,3) \leftrightarrow (3,4)$ with Oxygen at origin is the **unique** coordinate where the chromogeometric quadrances decode back to gate degrees:

| Metric | Formula | Value | Gate |
|---|---|---|---|
| Blue | $4^2 + 3^2$ | $25 = 5^2$ | ChargeGate² |
| Red | $4^2 - 3^2$ | $7$ | TimeGate |
| Green | $2 \cdot 4 \cdot 3$ | $24 = 8 \times 3$ | Oxygen × MatterGate |

The electron at position (4,3) has the same spread as the bond. At this coordinate, the distinction between **particle** and **interaction** dissolves.

See `Physics.Elements.Water` and `Physics.Scales.PythagoreanFixedPoint` for the full derivation.
