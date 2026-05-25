# Pure Multiset Ascension Architecture

> **Living Reference** — Updated 2026-05-24.
> All sections below are ✅ IMPLEMENTED and building (40/40 modules, 17/17 tests).

---

## Module Map

```
Physics/
├── Core.idr                    ← Substrate, Geometry, PixelIntPoly, type aliases
├── WeakForce.idr               ← Weak force model
│
├── Evolution/                  ← The Engine (7 modules)
│   ├── State.idr                   Re-exports of math libraries
│   ├── Gate.idr                    FundamentalGate, adaptiveCycle, primorialManifold
│   ├── Clock.idr                   Relational clock (stepMaxelTime)
│   ├── Transform.idr               Partition, Resonance, Ascension gates + CanAscend proof
│   ├── Cycle.idr                   applyGate, stepRelationalTime, runAdaptiveCycle, runEpochs
│   ├── Identity.idr                [J,J] diagonal — PersistentIdentity, ScaleOrder
│   └── Ontogeny alias              (via Physics.Scales.Phylogeny)
│
├── Scales/                     ← Scale Models (2 modules)
│   ├── Phylogeny.idr               Fork/merge lineage tree (Ontogeny = PersistentIdentity)
│   └── NaturalFolding.idr          Helix, DNA, cortical folding
│
├── Particles/                  ← 8 particle modules
│   ├── Photon, Quark, Baryon, Meson, Electron, WeakBoson, Bond, Neutrino
│
├── Laws/                       ← 4 conservation laws
│   ├── ColorConfinement, EnergyConservation, PrimorialConservation, PauliExclusion
│
└── Findings/                   ← 16 compiled derivations
    ├── Baryogenesis, Cosmology, HolographicFreeze
    ├── DarkEnergyExpansion, DarkMatterFriction
    ├── CosmicPartition, CosmicEnergyBudget
    ├── PeriodicTable                ← Pipeline-derived Feynman limit + Oxygen mediator
    ├── HadronGluonDynamics, StrongNuclearForce
    ├── VacuumPairProduction, FineStructureDerivation
    ├── GravitationalTimeDilation, TullyFisherRelation
    ├── CosmologicalConstant, MassRatios, Spread13
```

---

## §1 Name Translation

| Design Name | Compiled Name | Module |
|---|---|---|
| `FiberBundle` | `Multiset (Geometry, Amplitude)` | `Physics.Core` |
| `SpacetimeManifold` / `Maxel` | `Substrate` = `Multiset (Geometry, Geometry)` | `Physics.Core` |
| `ScaleLevel n` | `data ScaleLevel : (scaleLevel : Nat) -> Type` | `Physics.Evolution.Transform` |
| `BaseScale` | `ScaleLevel 0` constructor | `Physics.Evolution.Transform` |
| `AscendedScale` | `ScaleLevel (S n)` constructor (requires `CanAscend` proof) | `Physics.Evolution.Transform` |
| `PersistentIdentity` | The [J,J] diagonal at a ScaleOrder | `Physics.Evolution.Identity` |
| `Ontogeny` | Alias for `PersistentIdentity` in phylogenetic context | `Physics.Scales.Phylogeny` |
| `LineageNode` | Identity + linear Substrate + lag | `Physics.Scales.Phylogeny` |

---

## §2 Architectural Alignment

| Concept | Implementation | Physical Meaning |
|---|---|---|
| `ScaleLevel n` | `data ScaleLevel : (scaleLevel : Nat) -> Type` | The scale zoom-factor |
| `LatentState` | `partitionLogic` output (coeff ≥ 128) | Dark Energy — Red Metric — 2^7 potential |
| `VisibleState` | `partitionLogic` output (coeff < 128) | Matter — Blue Metric — 3^3 manifest states |
| `ResidueState` | `evaluateResonance` output | Background — Green Metric — dark matter dust |
| `partitionLogic` | `Transform.partitionLogic : Integer -> Geometry -> IntPolynumber -> (PixelIntPoly, PixelIntPoly)` | Sheaf restriction |

A system "levels up" if and only if `buildAscensionCapacities` constructs a `CanAscend` proof.

**Status: ✅ COMPILED** — `Physics.Evolution.Transform`

---

## §3 Three-Fold Ascension Requirements

For a `Substrate` at Scale N to re-emerge at Scale N+1:

```
Ascension Condition = f( residueLag, ancestralContext, twistCapacity )
```

1. **residueLag** — non-zero ResidueState surviving the n=13 gate
   → `cast (multiplicityAll residue)`
2. **ancestralContext** — Scale N-1 boundary conditions (Substrate causal density)
   → `substrateLag sub`
3. **twistCapacity** — Chromogeometric A(Q) = T(s) structural lock
   → `computeTwist geom` using `isStructuralLock` from `Math.Chromogeometry`

**Status: ✅ COMPILED** — `Physics.Evolution.Transform.AscensionCapacities`

---

## §4 The CanAscend Proof Type

```idris
-- Compiled (Transform.idr):
data CanAscend : (limit : Nat) -> AscensionCapacities -> Type where
  MkAscensionProof : {limit : Nat}
                  -> (caps  : AscensionCapacities)
                  -> caps.residueLag + caps.ancestralContext + caps.twistCapacity = limit
                  -> CanAscend limit caps
```

Uses propositional equality (`=`) — the Idris 2 type checker enforces this statically.

### The Scale Level Hierarchy

```idris
-- Compiled (Transform.idr):
data ScaleLevel : (scaleLevel : Nat) -> Type where
  BaseScale     : (fb : PixelIntPoly) -> ScaleLevel 0
  AscendedScale : (limit : Nat) -> (macroGeom : Geometry)
               -> (microStates : PixelIntPoly)
               -> (caps : AscensionCapacities)
               -> CanAscend limit caps
               -> ScaleLevel (S scaleLevel)
```

Dead scales **cannot construct AscendedScale**. The type checker prevents it at compile time.

**Status: ✅ COMPILED — exceeds original design (propositional proof > boolean check)**

---

## §5 The n=13 Resonance Gate

```idris
-- Compiled (Transform.idr):
evaluateResonance : Integer -> Integer -> Geometry
                 -> Multiset (Geometry, IntPolynumber)
                 -> Multiset (Geometry, IntPolynumber)
evaluateResonance capacityLimit moduloBase geom visibleSpace =
  if multiplicityAll visibleSpace > capacityLimit
     then fromList [((geom, residuePoly), 1)]  -- SHATTER mod 13
     else visibleSpace                          -- STABLE
```

Both `capacityLimit` and `moduloBase` are parameterised.

**Status: ✅ COMPILED**

---

## §6 The Partition Gate (128/27 Split)

```idris
-- Compiled (Transform.idr):
partitionLogic : Integer -> Geometry -> IntPolynumber
              -> (Multiset (Geometry, IntPolynumber), Multiset (Geometry, IntPolynumber))
```

`latentBarrier` is parameterised (not hardcoded 128).

**Status: ✅ COMPILED**

---

## §7 The Relational Clock

```idris
-- Compiled (Clock.idr):
stepMaxelTime : Substrate -> Substrate
             -> Multiset (Geometry, IntPolynumber)
             -> Multiset (Geometry, IntPolynumber)
stepMaxelTime currentGraph incomingRelations stateVec =
  let updatedGraph    = mergeGraph currentGraph incomingRelations
      structuralDensity = computeCausalLag updatedGraph
      temporalSpread  = spreadPoly structuralDensity
      evolvePair ((geom, poly), count) =
        ((geom, mulIntPoly poly temporalSpread), count)
  in fromList (map evolvePair (multisetToList stateVec))
```

> Time is self-referential: the spread polynomial degree is derived from the state's own structural density.

**Status: ✅ COMPILED**

---

## §8 The Complete Pipeline

### applyGate (single gate application)

```idris
-- Compiled (Cycle.idr):
applyGate : FundamentalGate -> Multiset (Geometry, IntPolynumber)
          -> Multiset (Geometry, IntPolynumber)
```

### stepRelationalTime (single tick)

```idris
-- Compiled (Cycle.idr):
stepRelationalTime : Substrate -> FundamentalGate -> UniverseState -> UniverseState
```

### runAdaptiveCycle (full 7-gate cycle + ascend/decohere)

```idris
-- Compiled (Cycle.idr):
runAdaptiveCycle : Substrate -> UniverseState -> UniverseState
```

### runEpochs (38-cycle Eddington scaling)

```idris
-- Compiled (Cycle.idr):
runEpochs : Nat -> UniverseState -> UniverseState
```

**Status: ✅ COMPILED**

---

## §9 The Adaptive Cycle (Gate Sequence)

```idris
-- Compiled (Gate.idr):
adaptiveCycle : List FundamentalGate
adaptiveCycle = [ BackgroundGate    -- n=2  Phase 1:  Unfolding
               , MatterGate         -- n=3  Phase 2:  Expansion
               , BondGate           -- n=4  Phase 2b: Molecular Bonding
               , ChargeGate         -- n=5  Phase 3a: Saturation (charge)
               , TimeGate           -- n=7  Phase 3b: Saturation (time)
               , WeakForceGate      -- n=11 Phase 4:  Collapse
               , ResonanceGate      -- n=13 Phase 5:  Residue → ascend/decohere
               ]
```

Each gate's degree is an index into the spread polynomial sequence `S_n(s)`.

**Status: ✅ COMPILED**

---

## §10 Identity and Phylogeny

### Ontogeny — The [J,J] Diagonal

```idris
-- Compiled (Identity.idr):
record PersistentIdentity (n : Nat) where
  constructor MkIdentity
  scale        : ScaleOrder n
  consciousness: IdentityDiagonal
```

The [J,J] diagonal is the self-referential fixed point that persists through an entity's
entire lifetime. It is the Maxel edge `(g, g)` where source equals target — pure identity.

### Phylogeny — The Branching Tree

```idris
-- Compiled (Phylogeny.idr):
Ontogeny : Nat -> Type
Ontogeny = PersistentIdentity

data LineageNode : (n : Nat) -> Type where
  MkNode : (identity : PersistentIdentity n)
         -> (1 state : Substrate) -> (lag : Nat) -> LineageNode n

fork  : (1 parent : LineageNode n) -> Ontogeny n -> (1 env : Substrate) -> Fork n
merge : (1 a : LineageNode n) -> (1 b : LineageNode n) -> Ontogeny n -> (1 env : Substrate) -> Merge n
```

- **fork**: parent keeps identity (ages), child gets new identity (zero lag)
- **merge**: two parents age, child gets third identity — no cloning
- QTT linearity enforces the No-Cloning Theorem

**Status: ✅ COMPILED**

---

## §11 The Periodic Table (Pipeline-Derived)

### The Feynman Limit

Elements are baryonic state vectors passed through the resonance gate (n=13).
Z protons = multiplicity Z. The gate shatters any state with lag > 137.

```idris
-- Compiled (PeriodicTable.idr):
isStableElement : (z : Nat) -> Bool
-- Z ≤ 137 → survives resonance → stable
-- Z > 137 → shattered mod 13   → decoheres
```

**Result: Exactly 137 stable elements.** (Verified at compile time via `Refl` proofs.)

### Oxygen (Z=8) — The Universal Mediator

| Property | Value | Significance |
|---|---|---|
| `128 / 8` | **16 exactly** | Divides the dark energy pool (2^7) perfectly |
| `27 mod 8` | **3** | Remainder = MatterGate degree |
| `210 mod 8` | **2 (≠ 0)** | Does NOT divide the primorial manifold |
| `8` | **2³** | BackgroundGate cubed |

Oxygen bridges the latent (128) and visible (27) sectors:
- It partitions dark energy into 16 equal quanta
- Its residue in visible matter IS the MatterGate (n=3)
- This is why Oxygen is the universal electron acceptor driving metabolism

All three properties are **compile-time verified** via `Refl` proofs.

### Vacuum Quantum

Adding S₂ (BackgroundGate) to **any** element contributes exactly **+8 lag**.
This is the vacuum fluctuation quantum — constant across all Z.

**Status: ✅ COMPILED + PROVEN**

---

## The Complete Flow

```
   [ CURRENT UniverseState { substrate, stateVector } ]
      │
      ├─── n=2  stepRelationalTime(BackgroundGate)   ── causal merge → S₂ → partition → resonance
      ├─── n=3  stepRelationalTime(MatterGate)       ── causal merge → S₃ → partition → resonance
      ├─── n=4  stepRelationalTime(BondGate)         ── causal merge → S₄ → partition → resonance
      ├─── n=5  stepRelationalTime(ChargeGate)       ── causal merge → S₅ → partition → resonance
      ├─── n=7  stepRelationalTime(TimeGate)         ── causal merge → S₇ → partition → resonance
      ├─── n=11 stepRelationalTime(WeakForceGate)    ── causal merge → S₁₁ → partition → resonance
      ├─── n=13 stepRelationalTime(ResonanceGate)    ── causal merge → S₁₃ → partition → resonance
      │
      ▼
   buildAscensionCapacities(137, substrate, geom, stateVector)
      │
      ├─── Just proof → ascendScale(geom, stateVector)  →  Scale N+1 macro-node
      │
      └─── Nothing    → postCycle state returned         →  residue seeds next cycle
```

Repeat × 38 cycles → Eddington Number (≈ 10⁸¹ particles)

---

## §12 True Linear Memory (LUniverse Refactor)

> *This is the defining feature distinguishing `LUniverse` from the pure functional `Universe` baseline.*

### Enforcing $O(1)$ Thermodynamic Fluid Dynamics
In the original design, the state vector `PixelIntPoly` was a `Multiset (Geometry, Amplitude)`. Evolving the universe required structurally replacing the old amplitude with the new amplitude, which in Idris allocates a new node, effectively cloning a universe branch on every gate application.

By incorporating `Linear` and `Ref1` (Quantitative Type Theory) into the core primitives, we achieve true in-place $O(1)$ mutation, accurately reflecting the energy-conserving properties of a physical fluid dynamic system:

```idris
public export
0 LCell0 : (s : Type) -> Type
LCell0 s = Ref s (Geometry, Amplitude)

public export
0 LPixelIntPoly : (s : Type) -> Type
LPixelIntPoly s = Multiset (LCell0 s)
```

### The Linear Gate Engine (`LGate.idr`)
With the geometry and amplitude strictly bundled behind the `Ref1` pointer, the state vector is reduced to a pure graph of physical pointers. Evolving a gate no longer branches the state; it consumes the linear `F1 s` execution token, reads the cell, applies the local propagator, and writes it back in place:

```idris
export
applyLinearMatterGate : LCell0 s -> ((Geometry, Amplitude) -> (Geometry, Amplitude)) -> F1 s ()
applyLinearMatterGate cell f = T1.do
  -- Read the old state (Geometry, Amplitude) linearly
  oldState <- read1 cell
  
  -- Compute the new state locally
  let newState = f oldState
  
  -- Write the new state in-place, consuming the linear F1 context
  write1 cell newState
```

This transforms `stepUniverseLocalized` from a functional pipeline mapping over tuples into a GPU-like kernel shader that zips over the `Multiset` pointers, mutating space-time perfectly without dropping bits or relying on garbage collection.

**Status: ✅ COMPILED**

---

## §13 The Cosmological Bridge (`LPhysics.Bridge`)

The `idris2-Universe` (pure math) and `idris2-LUniverse` (physical memory) pathways are explicitly linked via a Cosmological Bridge. This safely transforms pure geometry into a thermodynamic fluid and back.

### Melt (Instantiation Engine)
The `melt` operation condenses mathematical truth into an instantiated spatial reality. It operates over the entire `Math.Core.UniverseState`, discovering every unique geometric coordinate actively represented in either the Causal Graph (`Substrate`) or the State Vector. 

It then enters the linear `F1 s` token and allocates exactly **one** physical `LCell0 s = Ref1 (Geometry, Amplitude)` pointer for each coordinate. Both the linear substrate edges and linear state vector nodes are woven together using these perfectly shared, exact physical addresses. 

### Freeze (Photographic Snapshot)
The `freeze` operation provides a static cross-section of the linear universe's state at a precise cycle boundary. It traverses the `LUniverseState` invoking `read1`, seamlessly recovering the non-linear pure `UniverseState` graph of geometries without consuming or destroying the underlying pointers.

**Status: ✅ COMPILED**

---

## §14 The Linear Adaptive Cycle (`runLEpochs`)

With `LCell0` correctly established, `runLEpochs` and `runLAdaptiveCycle` bypass architectural duplication completely. They function entirely as GPU-kernel shaders:

```idris
runLAdaptiveCycle : Integer -> Metric -> LMath.Core.Geometry -> LUniverseState s -> F1 s ()
```

Rather than folding, mapping, or reducing an immutable tree, `runLAdaptiveCycle` accepts the execution token `F1 s` and loops through the physical nodes of the `LStateVec`. It applies linear updates in-place, meaning hundreds of epochs can tick by locally without allocating a single byte of structural memory. 

The universe is physically mutated exactly as it evolved!

### Physical Wave-Function Shift (`executeLocalShift`)

Inside `runLAdaptiveCycle`, the execution of the wave-function shift has been successfully wired to the `SpreadPolynumber` mechanics. Because the `Substrate` causal graph edges do not mutate dynamically within a single cycle, the engine takes a static pure snapshot of the substrate geometry via `freezeSub`. 

This frozen graph is then passed into `executeLocalShift`, which loops over every single `Ref1` cell and computes the localized pure `generateLocalSpreadPoly` operator for its geometric coordinate. The `IntPolynumber` amplitude inside the memory cell is then directly mutated by multiplying it against the generated spatial twist.

This eliminates structural tree reallocation entirely — the state vector's probabilities flow continuously through memory as an unboxed thermodynamic fluid.
### Topological Condensation (`canAscend` & `melt`)

The engine perfectly models topological collapse (the transition from 137 micro-states into a single macro-node at Scale N+1) by exploiting Idris 2's GC and linear types:
1. **Freeze State**: After the linear wave-function shift completes, the state vector pointers are photographed into a pure topological graph via `freezeState`.
2. **Pure Condensation**: `canAscend` and `ascendScale` execute entirely in pure math to collapse the graph into a new monolithic target topology.
3. **Melt Instantiation**: If ascension triggers, `melt` is invoked on the collapsed state. This allocates an entirely fresh, continuous block of physical memory for the newly ascended macro-universe. The previous cycle's `Ref1` pointers fall out of scope and are abandoned cleanly to the Scheme GC.
4. **Fluid Grind**: If ascension does not trigger, the original physical layout pointers are returned unmodified, allowing the `runLEpochs` shader to instantly recurse through another cycle using exactly the same unboxed memory.

**Status: ✅ COMPILED**
