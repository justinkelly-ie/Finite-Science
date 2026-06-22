# Nat-Science

**A deterministic, discrete-geometry natural science model where the laws of nature are enforced at compile-time over natural numbers.**

[![Idris2](https://img.shields.io/badge/Idris2-Nat_Types-blue.svg)](https://github.com/idris-lang/Idris2)
[![Science](https://img.shields.io/badge/Science-Scale_Invariant-red.svg)]()
[![Tests](https://img.shields.io/badge/Tests-55_passing-green.svg)]()

---

## Significance
Standard physics models heavily rely on continuous infinite space, smooth wave equations, singularities, and ad-hoc parameters to describe physical, chemical, and biological interactions.

**Nat-Science** presents a discrete alternative. We model the universe as a purely discrete, combinatorial engine built on finitist mathematics, including Box Arithmetic (Multisets), Chromogeometry, and Spread Polynomials. By deriving physical properties, molecular bonds, and organic folds strictly as algebraic constraints on a discrete integer grid, this framework bypasses the need for continuous infinite fields, providing a unified and scale-invariant explanation for observed evidence across physics, chemistry, biology, and neurology.

### Why "Nat-Science"?
Originally, this project was called *Linear Physics* and heavily utilized Idris 2's Quantitative Type Theory (QTT) to structurally enforce conservation laws. However, as the universe scaled, the compiler inevitably exhausted its memory attempting to mathematically track nested linear resources. 

We realized that physics, chemistry, biology, and neurology are not distinct systems with different fundamental rules, but are **emergent phases** of the same underlying discrete multiset algebra. 

We have since stripped away the heavy categorical abstractions, elevated the project beyond physics to **Natural Science**, and rebuilt it on an ultra-lean **Pure Multiset Integer Architecture**—representing the entire universe as algebraic properties over the **`Nat`** (Natural numbers) type.

*   **Extreme Leanness**: The engine drops arbitrary rational fractions, topological wrappers, and linear variables in favor of raw structural algebraic arrays (`Math.Multiset`).
*   **Exact Integer Calculations**: Using pure non-linear integer cross-multiplication, geometric spreads and quadrances never lose precision.
*   **Automatic Conservation**: Because everything evaluates as flat additions and subtractions across a multiset (`addMultiset`, `subMultiset`), terms automatically annihilate when opposite, guaranteeing perfect conservation naturally.

---

## Key Concepts: A Primer

Before reviewing the results and core architecture, it is helpful to establish the key definitions used in the Natural Science model:

*   **Maxel (Material Pixel)**: The discrete unit of material coordinates—a spatial grid coordinate possessing both integer position and algebraic amplitude.
*   **The 137-Grid**: Space in this model is not infinitely divisible. It is a discrete, scale-invariant integer grid bounded by exactly 137 nested scales of resolution. The number 137 represents the "grid wall"—the boundary where stable arithmetic factors break down and coordinates decohere.
*   **The Primorial Architecture**: A coordinate space structurally bounded by the product of prime gates ($2 \times 3 \times 5 \times 7 = 210$ total base states), filtering coordinates through prime-degree polynomial "gates".
*   **Leibniz Lag**: The discrete mathematical equivalent of "mass"—a functional measure of causal density and delay concentrated at a coordinate.
*   **Spread Polynomial**: A discrete representation of spatial dispersion. When a spread polynomial resolves to a clean whole number (a "lock"), it projects a stable, observable state.

---

## Key Results

> **57 modules. 55 property tests. Zero failures. No hardcoded constants.**

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

### The Global Finite Science Table

The entire architecture of the universe—from digital logic up to special relativity and quantum invariants—is executed under one unified instruction set: the **`MSetFraction`** (a signed integer numerator over a strictly positive natural denominator). Every row across all repositories evaluates via this exact cross-multiplied structure.

| Level & Physics | Numerator Box ($\in \mathbb{Z}$) | Denominator Box ($\in \mathbb{N}^{+}$) | Operator Field | Combinatorial Mechanism | Repos & Source Files |
|---|---|---|---|---|---|
| 🎛️ **[Digital Repetition](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Digital_Repetition.md)** (Algebra of Boole) | Bit-gate multiset $\{b \cdot [\text{state}]\}$ | The unit constant $\{1 \cdot [\text{Base}]\}$ | Modulo-2 logic field — modulo-2 bit arithmetic | Boolean ring evaluation (Exclusive OR / linear bit flipping where $1+1=0$) | `idris2-Boole` 📄 `BF2.idr` 📄 `BitGate.idr` 📄 `BooleFraction.idr` |
| 💻 **[Lifted Polynumbers](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Lifted_Polynumbers.md)** (Arithmetic Circuits) | Truth table coefficients $\{w \cdot [\text{Monomial}]\}$ | The unit constant $\{1 \cdot [\text{Base}]\}$ | Boole-Möbius shifts — upper-triangular matrix | Polynomial mapping (algebraic normal form lift / idempotent $x^2=x$ collapse) | `idris2-Boole` 📄 `Bridge.idr` 📄 `LiftedPolynumber.idr` |
| 🧮 **[Functional Probability](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Functional_Probability.md)** (Hehner) | Quantified mset $\{w \cdot [\text{valid}]\}$ | Total universe sum $\{\sum w \cdot [\text{all states}]\}$ | Hehner normalization $\overline{E} = E \cdot (\sum E)^{-1}$ | Min / max evaluation (calculational quantifiers $\land$ and $\lor$ replacing infinite logic) | `idris2-Boole` 📄 `FunctionalProbability.idr` |
| 📉 **[Probability Bounds](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Probability_Bounds.md)** (Hailperin) | Min/max corner msets $\langle \text{Box}_\text{Min}, \text{Box}_\text{Max} \rangle$ | Universe constraints $\{\sum w \cdot [\text{bounds}]\}$ | Hailperin co-operations — multiset boundary scaling | Inclusion-exclusion corners (alternating sign sequences / polyhedral vertex squeezing) | `idris2-Boole` 📄 `Hailperin.idr` |
| 🔬 **[Indivisible Stochastic Mechanics](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Indivisible_Mechanics.md)** (Barandes) | Indivisible configurations $\{p \cdot [\text{trajectory}]\}$ | Division time events $\{\sum p \cdot [\text{prior breaks}]\}$ | Non-Markovian transitions — amplitudes $\Theta$ to proportions $P$ | Stochastic correspondence (quantum systems without wavefunctions / $P = \vert\Theta\vert^2$) | `idris2-Universe` 📄 `IndivisibleHistory.idr` |
| 📐 **[Rational Trigonometry](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Rational_Trigonometry.md)** (Wildberger) | Triangle side msets $\{\Delta x^2, \Delta y^2\}$ | Hypotenuse field $\{1 \cdot [Q_\text{Hyp}]\}$ | Affine bilinear forms — dot-product symmetrics | Triple quad / spread laws (quadratic cross-multiplication over integers / no angles) | `idris2-Chromogeometry` 📄 `Math.Chromogeometry` |
| 🔵 **[Blue Geometry](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Blue_Geometry.md)** (Euclidean Space) | Blue metric mset $\{(\Delta x)^2 + (\Delta y)^2\}$ | Blue grid scale mset $\{\text{Grid}_\text{Density}\}$ | Blue maxel tensor ($I$) — standard identity convolution | Euclidean invariance (strictly positive spatial quadrances / rigid shapes) | `idris2-Chromogeometry` 📄 `Math.Chromogeometry` (via `quadranceNL`) |
| 🔴 **[Red Geometry](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Red_Geometry.md)** (Minkowski Relativity) | Red metric mset $\{(\Delta x)^2 - (\Delta y)^2\}$ | Red grid scale mset $\{\text{Grid}_\text{Density}\}$ | Red maxel tensor ($k$) — reflection matrix convolution | Minkowski relativity (light cones / invariant null lines where $Q_r = 0$) | `idris2-Chromogeometry` 📄 `Math.Chromogeometry` (via `quadranceNL`) |
| 🟢 **[Green Geometry](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Green_Geometry.md)** (Diagonal Shear) | Green metric mset $\{2(\Delta x)(\Delta y)\}$ | Green grid scale mset $\{\text{Grid}_\text{Density}\}$ | Green maxel tensor ($j$) — anti-diagonal transposition | Diagonal symmetry / shear (secondary relativistic alternative along the $y=x$ bounds) | `idris2-Chromogeometry` 📄 `Math.Chromogeometry` (via `quadranceNL`) |
| 🌌 **[Universal Hyperbolic Geometry](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Universal_Hyperbolic_Geometry.md)** | Homogeneous msets $\{w \cdot [x : y : z]\}$ | Projective frame field $\{1 \cdot [\text{Base Frame}]\}$ | Projective reconstructions — cross-ratio invariants | Duality matrix switches (perfect point-to-line flips across finite grids) | `idris2-Multiset` 📄 `ExtendedCosmology.idr` |
| ⚡ **[Electromagnetism](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Electromagnetism.md)** | Loop chain tracks $\{q \cdot [\text{Edge Loops}]\}$ | Volume element scale $\{\text{Cell}_\text{Volume}\}$ | Exterior calculus decay — discrete boundary maps | Gauge invariant closure (discrete curl $\Delta_\text{matrix} \to 0$ via Hodge splits / charge conservation) | `idris2-Universe` 📄 `DiscreteCalculus.idr` 📄 `GaugeOperator.idr` |
| 🕳️ **[Inversive Space Relativity](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Inversive_Space.md)** | Conic equation vexels $\{c \cdot [\text{Conic Coeffs}]\}$ | Inversion density $\{1 \cdot [Q_\text{Circle}^n]\}$ | Inversive chromogeometry — circle-reflection transforms | Conic edge splitting (Euler line & omega intersections / bending path bounds) | `idris2-Universe` 📄 `Twist.idr` |
| 🧬 **[Quantum Invariants](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Finite-Science/Quantum_Invariants.md)** | Spread vexel mset $\{c_n \cdot [s^n]\}$ | Hypotenuse scaling mset $\{1 \cdot [Q_\text{Hyp}^n]\}$ | Algebraic calculus — transition difference operators | Goh factorisation (decomposition of spread polynumbers into Fibonacci parts) | `idris2-Multiset` 📄 `SpreadPolynumber.idr` |


### 1. The Grid and Chromogeometry
Space is modeled as a discrete Multiset (a directed graph of integer pixel coordinates).
The universe's coordinate space is structurally bounded by the 210 states of the 4th Primorial Spread Polynomial ($2 \times 3 \times 5 \times 7 = 210$). These values are **not hardcoded constants** — they emerge from the combinatorial mathematics, partitioning Maxels into:
* **27 Maxels (Visible Matter):** Resolvable $3^3$ integer states that successfully collapse into stable geometric projections.
* **128 Maxels (Dark Energy):** Unresolvable $2^7$ fractional states that remain spread across the grid, exerting expansional topological pressure.
* **55 Maxels (Dark Matter):** The mathematically emergent residue ($210 - (128 + 27) = 55$) that acts as a latent gravitational halo.


The geometry is governed by Chromogeometry's three interlocked metrics:
*   **Blue Metric (Matter):** The standard Euclidean $x^2 + y^2$ geometry where stable particles materialize as integer states in the discrete space.
*   **Red Metric (Dark Energy/Radiation):** The relativistic $x^2 - y^2$ geometry where photons and other energetic particles propagate along null-quadrance bounds invisible to us.
*   **Green Metric (Background/Tension):** The $2xy$ geometry that traps unresolvable fractional states, generating multiset coordinate tension (e.g., Color Confinement).

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
Life is formalized as a linear wrapper that preserves geometric integrity. Biological folding is not a continuous thermodynamic accident; it is the geometric execution of a Spread Polynomial attempting to neutralize multiset coordinate tension over a finite integer grid.

*   **The Helix Barrier:** The stability of the Alpha Helix and DNA Double Helix structures are enforced by specific geometric "locks". Driven by polynomials (such as $S_{10}$), these structures emerged only once in history because they are the strictly unique, linear mathematical solutions capable of folding and consuming the substrate without violating linearity or causing localized decoherence.
*   **Neurological Folding:** The extreme folding of the cerebral cortex (Cortical Gyri) is modeled at the macro scale by massive polynomials (e.g., $S_{137}$). A dense neuronal substrate naturally generates high-frequency structural locks to neutralize multiset coordinate tension, maximizing computational capacity.
*   **Ice Geometry & Folding Reciprocity:** At the N+2 scale, the folding number $21 = 3 \times 7$ (MatterGate × TimeGate) establishes a reciprocity: $21/7 = 3$ (Matter folds from Time) and $21/3 = 7$ (Time folds from Matter). This is the scale at which structure and time become interchangeable.

---

## Project Topology

The project is structured as a decentralized network of standalone libraries. `Nat-Science` functions as the main simulation coordinator, pulling algebra and geometry modules from independent sibling repositories:

```
Projects/
├── Nat-Science/                 ← The main natural science engine (this repository)
│   ├── visualizer/             ← The 3D Science Laboratory (Vite + Three.js + React-Three-Fiber)
│   └── Scripts/                ← Orchestration and validation scripts
│
├── idris2-Universe-Wiki/        ← The literate wiki and verification proofs (executable)
│   ├── Library/Wiki/           ← Literate Idris verification proofs & documentation
│   └── idris2-Universe-Wiki.ipkg
│
├── [idris2-LUniverse/](https://github.com/justinkelly-../idris2-Universe)   ← The core simulation engine (59 modules)
│   ├── src/Simplex/            ← State and relation topologies
│   ├── src/Evolution/          ← Polynomial evolution gates and loops
│   └── src/Physics/            ← Physical, chemical, biological, and neurological folds
│
├── idris2-Multiset/            ← STANDALONE: Pure RLE multiset & polynumber algebra
├── idris2-Chromogeometry/      ← STANDALONE: Wildberger's RGB rational chromogeometry
└── idris2-QuickCheck/          ← STANDALONE: Clean property-testing framework
```

---

## Getting Started

### Prerequisites
`Nat-Science` requires [Idris 2](https://github.com/idris-lang/Idris2). We use **[pack](https://github.com/stefan-hoeck/idris2-pack)** to manage dependencies and trigger test builds.

### Sibling Package Development
The sibling packages (`idris2-Multiset` and `idris2-Chromogeometry`) are resolved locally during development via `pack.toml`:
```toml
idris2-Multiset = { path = "../idris2-Multiset" }
idris2-chromogeometry = { path = "../idris2-Chromogeometry" }
```

### Building and Testing

To compile the libraries and execute the 55 property tests, run the unified script from the root of this repository:
```bash
# Using host:
./Scripts/run-tests.sh

# Or using the Fedora Toolbox environment:
toolbox run -c fedora-toolbox-44 ./Scripts/run-tests.sh
```

Alternatively, you can build and run the test package directly via `pack` within the Wiki repository:
```bash
# Using host:
cd ../idris2-Universe-Wiki
pack run idris2-Universe-Wiki.ipkg

# Or using the Fedora Toolbox environment:
toolbox run -c fedora-toolbox-44 bash -c "cd ../idris2-Universe-Wiki && pack run idris2-Universe-Wiki.ipkg"
```
If you are unfamiliar with Idris2 but wish to explore the project, download Google Antigravity [^1] and have it assist you with the steps above; you can then prompt it to explore the model textually.

### Running the 3D Visualizer

The 3D Science Laboratory is built using Vite, React, and React-Three-Fiber. It is powered by the **live compiled Idris 2 physics engine** running directly in the browser!

To launch the interactive visualizer:

1. **Compile the Idris 2 JS Bridge Engine**:
   To enable real-time dynamic simulation in the browser, build the browser JS bundle and copy it to the visualizer's public asset directory:
   ```bash
   # Using host:
   cd ../idris2-Universe
   pack --cg javascript build idris2-LUniverse-js.ipkg
   cp build/exec/luniverse_js ../Nat-Science/visualizer/public/luniverse_js.js
   
   # Or using the Fedora Toolbox environment:
   toolbox run -c fedora-toolbox-44 bash -c "cd ../idris2-Universe && pack --cg javascript build idris2-LUniverse-js.ipkg"
   cp ../idris2-Universe/build/exec/luniverse_js visualizer/public/luniverse_js.js
   ```

2. **Install Visualizer Dependencies**:
   ```bash
   # Using host:
   cd visualizer
   npm install
   
   # Or using the Fedora Toolbox environment:
   toolbox run -c fedora-toolbox-44 bash -c "cd visualizer && npm install"
   ```

3. **Start the Development Server**:
   ```bash
   # Using host:
   npm run dev
   
   # Or using the Fedora Toolbox environment:
   toolbox run -c fedora-toolbox-44 bash -c "cd visualizer && npm run dev"
   ```
   Once started, open [http://localhost:5173](http://localhost:5173) in your browser to view the interactive 3D laboratory. Use the tabs at the top to toggle between:
   * **Simulated Baryon Lock**: Interactive quark metrical tension solver.
   * **Live Serialization Pipeline**: Real-time Idris 2 simulation running dynamically inside your browser! Includes a full preset selector, custom metric selector, and interactive mass-energy injection and causal edge creation sandboxes.
   * **SigmaGate Modeler**: Causal edge boundary solver.

---

## Theoretical Foundation & Wiki
The physics mapping and derivation in this project are massive. If you are a physicist or mathematician looking to audit the transition from orthodox QCD to Deterministic Finitist Arithmetic, please read the Wiki:

*   📖 **[Physics Index](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Verification_Matrix.md)** — Overview of research areas and key discoveries
*   💻 **[Code Architecture](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Code/Index.md)** — Detailed breakdown of the $O(1)$ Sigma-Linear execution engine
*   ✅ **[Verification Matrix](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Code/Verification_Matrix.md)** — Live QuickCheck properties and Golden test results demonstrating absolute physics adherence
*   ⚛️ **[Primorial Particle Mapping](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Symmetry/Particles.md)** — How standard model particles map to spread polynomials, plus Oxygen/Water chemistry
*   🔄 **[Recursive Multiset Composition](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Scale/Recursive_Composition.md)** — Time, scale, and the 137-scale trajectory as recursive polynomial composition
*   🧮 **[Mathematical Type Architecture](https://github.com/justinkelly-ie/idris2-Universe-Wiki/blob/main/Library/Wiki/Simplex/Types.md)** — How every physical concept is one parameterised Multiset

---

*LUniverse shifts physics from phenomenological observation to mathematical verification.*

---

&copy; Justin Kelly. All rights reserved.

[^1]: Formalised and architected in collaboration with Antigravity, an advanced AI coding assistant by Google DeepMind.
