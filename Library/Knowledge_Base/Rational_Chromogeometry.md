# Rational Chromogeometry

Foundational notes on Rational Chromogeometric Information Theory (RCIT), covering the 2D/3D Bridge, the 137-Grid Protocol, and the Möbius Module. Defines the relationship between the 2D Substrate (Hardware) and the 3D Bulk (Software).

This document outlines the informational relationship between the 2D hardware (Multisets) and the 3D software (Particles) within the RCIT framework.

## 1. The GridConfig Protocol
The `GridConfig` record defines the informational resolution of the 137-grid.
*   **Scale (S)**: The total address space capacity, calculated as $2^{Entropy} + Tax$.
*   **Alpha (α)**: The unit of Leibniz debt ($1/S$).
*   **Standard Config**: 7 bits of entropy with a 9-bit metrical tax ($2^7 + 9 = 137$).
*   **The BNL Invariant**: Proves that the product of Alpha and the Effective Scale is always Unity ($1$).

## 2. Interaction & Lag
Every spacetime interaction ($f \circ g$) generates an **Interaction Lag** ($D(fg)$). 
*   **Saturation Check**: If the lag exceeds the scale ($D(fg) > S$), the interaction is considered non-physical (Congested).
*   **Decoherence**: Saturation triggers the transition from a 'Spread' (Wave) state to a 'Settled' (Particle) state via the Integration protocol.

## 3. The HBW-ISQT Synthesis
The **Hehner-Barandes-Wildberger (HBW)** synthesis integrates information theory with stochastic quantum dynamics:
*   **Information ($I$)**: Measured in bits, where $I = -\log p$. This removes the problem of prior probabilities; "no information" implies $1/n$ probability by definition.
*   **Amplitude ($\psi$)**: Defined as the square root of the bit-rational state, allowing quantum formalism to be treated with exact rational arithmetic.
*   **Indivisible Evolution**: Based on **Indivisible Stochastic Quantum Theory (ISQT)**, evolution is the discrete settlement of the **Leibniz Lag**.

## 4. The Temporal Law
Time ($dt$) is an emergent consequence of informational friction in the 137-grid:
*   **Leibniz Lag ($dt_L$)**: The discrete residue from multiset composition (logical processing delay).
*   **Saturation Residue ($dt_S$)**: The "additional factor" representing the geometric distance from the 137-bit saturation limit.
*   **Total Duration**: $dt = dt_L + dt_S$. Time flows slower (dilation) in sparse vacuums where the saturation residue is high.

## 5. QTT-Compliant Physics Signatures
All physical processes in the bulk are now strictly linear to ensure exact Leibniz accounting:
*   **gluonTransition**: `1 _ : MetricPivot -> Pixel a -> Pixel a` — Consumes the metric shift to produce the color transition.
*   **isWhite**: `(1 _ : Maxel a) -> Bool` — Consumes the maxel to audit the zero-quadrance invariant.
*   **saturationResidue**: `(1 _ : Maxel a) -> Integer` — Consumes the field state to calculate the informational pressure.

## 6. The Color Charge Invariant
Color neutrality (Whiteness) is defined as the state where the net metrical torsion across the Blue, Red, and Green metrics is zero. In 2D space, this invariant is only satisfied by the null multiset (`Zero`) or perfectly balanced dual-transitions, enforcing **Color Confinement** by geometric necessity.

## 7. The EPR Witness (Red Metric Stability)
Non-local entanglement is verified as a requirement of the **Red Metric** (Minkowski) stability. 
*   **Entanglement Witness**: An instant shift in one pixel must be reflected in the second to maintain the **Red Archimedes Invariant** ($A=0$) across the Indivisible Unit (Multiset).

## 8. The AntiPlusMatter Möbius Module
The **`AntiPlusMatter`** type represents the parent, pre-projection dual state of the quantum coordinate field. It formalizes the Möbius transform as a non-orientable topological wrapper over the linear **`Maxel a`** resource:

*   **`AntiPlusMatter a`**: Encapsulates the linear coordinate excitation and a discrete Möbius **`Parity`** ($+1$ or $-1$).
*   **`mobiusTwist`**: An involution automorphism that rotates parity by $180^\circ$ along the Möbius strip (`Positive` $\leftrightarrow$ `Negative`), preserving the underlying linear coordinates.
*   **`projectMobius`**: The projection operator that maps the dual-parity packet into either **`Matter (Maxel a)`** (ordinary baryonic space) or **`Lag (Maxel a)`** (antimatter/dark matter latency) based on its active Möbius parity.

```mermaid
graph TD
  A["Address Space (a)"] -->|Coordinate Transition| B["Pixel a"]
  B -->|Metric Pivot u, d, s| C["FormalQuark a (MetricPivot a)"]
  B -->|Coordinate Collection| D["Maxel a (MSet (Pixel a))"]
  D -->|Unified Möbius Wrapper| E["AntiPlusMatter a"]
  E -->|projectMobius| F["PhysicalManifestation a"]
  F -->|Matter Parity (+1)| G["Manifest Matter (Maxel a)"]
  F -->|Lag Parity (-1)| H["Latent Lag / Antimatter (Maxel a)"]
  G -->|Size 2 Audit| I["FormalMeson a"]
  G -->|Size 3 Audit| J["Baryon a / Nucleon a"]
  H -->|Size 2/3 Latency| K["Anti-Meson / Anti-Baryon"]
```

This ensures that composite particles (Mesons, Baryons, Nucleons) are derived directly from the projected manifest matter state of the grid, enforcing perfect QTT-compliant resource conservation.



