# The Standard Model of Particles (RCIT)

The 137-Grid Protocol models the Standard Library of Particles natively through purely geometric and linear algebraic constructs, without the need for arbitrary intermediate types. All particles are formed as specific symmetric configurations of `Pixel` and `Maxel` data structures.

## 1. Quarks (`Physics.Particles.Quark`)
Quarks are formalized as `FormalQuark`, which binds a transition `Pixel` to a specific **Metric Flavor**:
- **Up (U)**: `Blue` (Euclidean basis)
- **Down (D)**: `Green` (Galilean basis)
- **Strange (S)**: `Red` (Minkowski basis)

**Antimatter** (`antiPixel`) is mapped mathematically as the strict geometric inversion of the transition vector, swapping the origin and target states.

## 2. Mesons (`Physics.Particles.Meson`)
A `FormalMeson` is structurally defined as a `Maxel` of size 2. It is considered "bound" (and geometrically valid) only when the Chromogeometric Spread between its two constituent Quarks evaluates to exactly `0 // 1`. This represents the Quark and Anti-Quark pair locking into strict parallel geometric tension.

## 3. Baryons (`Physics.Particles.Baryon`)
A `Baryon` is structurally defined as a `Maxel` of size 3. It maintains stability through the **Triple Spread Law** (Color Balance). A Baryon is mathematically "White" (stable) only if the internal spreads between all three constituent Quarks evaluate strictly to `3 // 4` (representing perfect 120-degree symmetric displacement).

## 4. Nucleons (`Physics.Particles.Nucleon`)
A stable subset of Baryons representing the atomic nucleus.
- **Proton**: A formally verified UUD (Up-Up-Down) baryon. Built from two Euclidean transitions and one Galilean transition.
- **Neutron**: A formally verified UDD (Up-Down-Down) baryon. Built from one Euclidean transition and two Galilean transitions.

## 5. Hyperons (`Physics.Particles.Hyperon`)
The `LambdaHyperon` extends the standard Baryon. It explicitly audits for the $uds$ (Up, Down, Strange) flavor configuration and aligns the chiral thread to the vacuum's base state. This computationally mirrors the real-world Baryogenesis models observed at the BNL RHIC in 2026.
