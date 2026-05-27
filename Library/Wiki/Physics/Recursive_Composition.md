# Recursive Multiset Composition

## The Core Thesis
In the LUniverse architecture, there are no separate phenomena for quantum interactions, systemic scale orders, or cosmological epochs. They are all unified expressions of a single, combinatorial mathematical identity: **Recursive Spread Polynomial Composition**.

$$ S_{n \times m}(s) = S_n(S_m(s)) $$

In Rational Trigonometry, Spread Polynomials inherently compose. Because they map into themselves, evaluating a macro-scale structure (an Epoch, or a Galaxy) is mathematically identical to recursively feeding a microscopic polynomial (a Quark) back into itself.

### What "Recursion" Means Here

In type-theoretic terms, self-similarity is just:

> A `Multiset a` where `a` is itself a `Multiset b`.

The inner multiset evaluates through the polynomial recurrence. The outer multiset parameterises the scale. There is no special "fractal" mechanism — it's **nested multisets** all the way down. The same `Multiset.idr` engine that stores polynomial coefficients also stores the causal graph, and the same spread polynomial recurrence that generates a quark also generates a galaxy.

---

## State vs. Event: The Nature of Time
In standard continuous physics, time ($t$) is an external dimension that objects passively drift through. In the discrete deterministic grid of LUniverse, time does not exist as a dimension. 

Instead, it is an **event-driven ontology** mirrored perfectly by Idris 2 functional evaluation:
1. **The State:** The universe evolves until it reaches the next event; until then it maintains a static configuration of substrates (e.g., the `UniverseState` record containing a `Substrate` graph, stable state vector and geometry).
2. **The Event (Polynomial):** Time only "advances" when a Spread Polynomial is mathematically executed. The polynomial *is the event*. It consumes the current state and geometrically projects the grid into the next discrete phase.

---

## QTT Linearity: Composition vs. Collapse
The Idris 2 compiler mechanically enforces these scale limits using **Quantitative Type Theory (Linear Types)**. A linear resource *must* be consumed exactly once. 

When an event (Polynomial) evaluates a state:
* **Composition (Ascension):** If the polynomial maps cleanly to an integer on the 137-grid (like the Baryon lock $A(Q) = T(s)$), the linear resource is safely consumed. The system successfully composes, ascends to the next `ScaleLevel`, and stable mass forms.
* **Collapse (Decoherence):** If the polynomial hits an asymptotic boundary (like the $n=11$ 128-state boundary) and yields an irreducible fractional residue, it **violates linearity**. It cannot map to a single integer. To satisfy the compiler, the wave-function *must* shatter into lower-order integer primitives. This mathematically forces a phase collapse (radioactive decay) or an Epoch reset.

---

## The Adaptive Cycle as Polynomial Geometry
The Adaptive Cycle (`adaptiveCycle` in `Evolution.Gate`) is the geometric curve of the spread polynomial itself:
* **Expansion:** The algebraic climb of the polynomial (gates n=2, 3, 4).
* **Saturation:** The peak of the polynomial where it hits integer lock (gates n=5, 7).
* **Collapse:** The fractional overflow breaking linearity (gates n=11, 13).

After all 7 gates, `buildAscensionCapacities` in `Evolution.Transform` constructs either a `CanAscend` proof (→ `ScaleLevel (S n)`) or returns `Nothing` (→ decoherence).

**Cosmological Epochs** are not measures of time. They are strictly the composed bounds of $S_{137}(S_{previous}(s))$. Universal expansion is simply the universal scale computing the next order of the recursive composition.

---

## Computational Evidence: The 137-Scale Trajectory

The strongest evidence for recursive composition is the **137-Scale Trajectory** derived from Water's Pythagorean Fixed Point.

Starting from Water's bond coordinate $(4,3)$ and iterating the self-addition rule:

$$\text{position}(k) = (4(k+1),\ 3(k+1))$$

The gate fingerprint is **invariant** at every scale:
* Blue $Q(k) = 25(k+1)^2$ = ChargeGate² × $(k+1)^2$
* Red $Q(k) = 7(k+1)^2$ = TimeGate × $(k+1)^2$
* Green $Q(k) = 24(k+1)^2$ = Oxygen×MatterGate × $(k+1)^2$

The only variable is $(k+1)^2$ — the generation number squared. Water's chromogeometric signature persists identically from quarks (k=0) to the grid wall (k=136, n=137).

Decoherence occurs precisely when the generation number $n = k+1$ contains a prime beyond the gate hierarchy $\{2, 3, 5, 7, 11, 13\}$. Across all 137 scales: **76 are gate-pure, 61 are decoherent**. The observer epoch $k=38$ ($n=39 = 3 \times 13$ = MatterGate × ResonanceGate) is gate-pure.

This is recursive composition made visible: a single molecular coordinate, iterated across 137 scales, reproduces the entire cosmological structure — not because of any special "fractal" mechanism, but because the Multiset engine evaluates the same polynomial at every level.

See `Physics.Scales.ScaleTrajectory` for the implementation and `Physics.Scales.PythagoreanFixedPoint` for the fixed point derivation.
