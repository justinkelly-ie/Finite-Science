# Finite-Science

**A step-by-step introduction to discrete physics built purely from finite multisets of Black and Red boxes — no floating-point numbers, no pre-built grid walls, and no external clock.**

All mathematics and simulations are written in total (`%default total`) Idris 2 over [`FinSc-Box`](file:///var/home/justin/Projects/FinSc-Box), with every core conservation law checked by the compiler or verified across 6 automated experiments.

---

## Step 1: Nothing at All — The Empty Box

Start with an empty container:

```text
[]
```

This is the **vacuum**. It has:
- **0 boxes** inside it,
- **0 energy**,
- **0 net charge**, and
- **0 time ticks** (nothing is happening, so nothing advances).

---

## Step 2: Black Boxes (⬛) and Red Boxes (🟥)

Now introduce just **two** kinds of elementary tokens that can sit inside a container:
- a **Black box** `⬛` meaning `+1`, and
- a **Red box** `🟥` meaning `-1`.

There is only **one fundamental cancellation rule**: whenever a Black box and a Red box meet inside the same container, they annihilate back to nothing:

```text
[ ⬛ , 🟥 ]  =  []
```

Everything else follows from counting:

```text
[ ⬛ , ⬛ , ⬛ ]           =  +3   (three Black boxes)
[ 🟥 , 🟥 ]               =  -2   (two Red boxes)
[ ⬛ , ⬛ , 🟥 ]           =  [ ⬛ ]   (+1, because one ⬛ and one 🟥 cancel)
```

Notice what this also allows in reverse: **empty vacuum `[]` can split into a balanced pair** — one `⬛` and one `🟥` — while keeping the total count strictly `0`. In our model, every closed universe begins at `0` net boxes and stays at **exact `0`** forever (no floating-point drift).

---

## Step 3: Boxes Inside Boxes — Space Without a Grid

So far we only have a single pile of Black and Red boxes (`0D`). How do you get **space** (left/right, up/down, forward/back) without inventing a separate coordinate grid?

**Put boxes inside other boxes.** A container whose items are themselves containers of Black and Red boxes is called a **Hereditary Multiset** (`PureMultiset` in [`HereditaryMSet.idr`](file:///var/home/justin/Projects/FinSc-Box/src/FinScBox/HereditaryMSet.idr)).

Each inner box acts as an **address**:

```text
[]                        =  the origin (0)
[ ⬛ inside [] ]           =  1 step along Axis 1 (X)
[ ⬛ , ⬛ inside [] ]      =  1 step along Axis 2 (Y)
[ ⬛ , ⬛ , ⬛ inside [] ]  =  1 step along Axis 3 (Z)
```

Putting a `⬛` at address `A` and a `🟥` at address `B` creates a **balanced spatial dipole**:

```text
Address A: [ ⬛ ]   (+1)
Address B: [ 🟥 ]   (-1)
────────────────────────
Total:       []      (0)
```

Because addresses are just nested boxes:
- There are **no grid walls** — space extends as far as excitations travel.
- **Dimension is emergent:** if an excitation uses 2 axis shapes, the universe is 2D; if a 3rd axis shape is present, the exact same engine automatically evolves in 3D (verified in Experiment 6-3D).

---

## Step 4: Links Between Addresses (`WaveMaxel`) and Energy (`EnergyMaxel`)

Neighboring addresses are connected by **directed links**. A flow of `⬛` boxes from `A` to `B` is simultaneously a flow of `🟥` boxes from `B` to `A` (`u_AB = -u_BA`).

We store site charges ($\psi$, Black or Red) on the diagonal `(A, A)` and directed link flows ($u_{AB}$) off the diagonal `(A, B)` inside one half-stored table called a **`WaveMaxel`** ([`Energy.idr`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Energy.idr)). Its signed sum is always `0`.

**Energy** is what you get when you multiply every entry by itself (`EnergyMaxel = wave .*. wave`):
- Both `⬛` (`+`) and `🟥` (`-`) square to **positive** energy (`2 * psi^2` on sites, `u^2` on links).
- **Pure link energy creates matter-antimatter dipoles from vacuum:** if an empty link `(0, 0)` holds a pure bond of `u = 50` (`E = 50^2 = 2500`), one exact integer Pythagorean rotation splits the vacuum sites into a balanced Red/Black dipole `(-7, +7)` with `u' = 48` and exact energy conservation:

```text
Before:  Site A = 0,   Site B = 0,   Bond = 50   ->  E = 0 + 0 + 50^2          = 2500
After:   Site A = -7,  Site B = +7,  Bond = 48   ->  E = 2*(49 + 49) + 48^2    = 2500
```

All updates use exact Wildberger Pythagorean integer rotations (`rotatePythPow` in [`ProjectiveRotation.idr`](file:///var/home/justin/Projects/FinSc-Box/src/FinScBox/ProjectiveRotation.idr)), so energy never grows (`E_{t+1} <= E_t`) and net charge stays strictly `0`.

---

## Step 5: Time = Peeling Boxes & Emergent Gravity

In this model, **time is not an external ticking clock** — time is the finite work of peeling boxes one quantum at a time (`GohFuel` in [`HereditaryMSet.idr`](file:///var/home/justin/Projects/FinSc-Box/src/FinScBox/HereditaryMSet.idr)):
- An active update emits `StreamYield` (spending `GohFuel`).
- A paused or empty tick emits `StreamSkip` (costing **`0 GohFuel`**).

Where energy concentrates into a dense core, its causal 1-hop metric (`metricMaxel`, propagating strictly at speed `c = 1`) causes local links to emit more `StreamSkip` pauses. From this single local rule, standard gravitational signatures emerge with no continuous spacetime and no `1/r` force law baked in:
- **Self-trapping:** dense cores trap `91%` of their energy (vs `60%` in linear dispersion).
- **Time dilation:** a dense breather executes `12` sweeps on the same `GohFuel` budget where an unpaced packet finishes in `2` sweeps (`1338` `StreamSkip`s at `0 GohFuel` cost).
- **Causal deflection & Shapiro delay:** passing wavepackets bend toward a nearby breather and arrive later, while remaining bit-for-bit unaffected outside the `c = 1` light cone.
- **Equal-mass 2-body attraction & 3D gravity:** two free wavepackets pull toward each other, and the same local rule attracts packets along the Z-axis in emergent 3D.

---

## Step 6: Open Universes, Coupled Seams, and Self-Seeding Cycles

Because everything is a `PureMultiset`, universes can also interact with external multisets of the exact same type:

1. **Open $\to$ Closed Energy Flow (`stepCoupledSourceFlow`):** An external reservoir `E_src : PureMultiset` peels one bond quantum per tick into a universe `U` via `viewAsAntiBox`. While `E_src` has boxes left, `U` heats up; the instant `E_src` empties to `[]`, `U` automatically transitions to closed cooling — no mode switch needed.
2. **Active Two-Universe Seam Coupling (`stepCoupledUniversePair`):** Two evolving universes `U_A` and `U_B` coupled across any `Maxel` boundary seam (`maskByBox`) exchange zero-sum bond quanta strictly along the local boundary gradient, equilibrating smoothly while keeping `netA = netB = 0`.
3. **Freeze-Out $\to$ Self-Seeding Cycles (`MSetSupport`):** When a universe exhausts its `GohFuel` and freezes, `MSetSupport` strips all signed amplitudes down to pure unit-weight presence — keeping only *where* structure survived. That stripped topological relic then serves as **both** the `GohFuel` clock and the external reservoir `E_src` to boot a fresh empty universe (`[]`), converging from distinct initial seeds to an exact self-reproducing fixed point by Cycle 3.

---

## Step 7: Project Layout & Running the Verified Suite

### Active Stack
- **[`FinSc-Box`](file:///var/home/justin/Projects/FinSc-Box)** (10 modules): Pure multiset & `Maxel` algebra (`BoxInt`, `Interfaces`, `Box`, `HereditaryMSet` + `MSetSupport` + `GohFuel`/freeze-out, `ProjectiveRotation`, `MultisetCodec`, `Views`, `BlackRedZoom`, `Lenses`).
- **[`FinSc-Box-Wiki`](file:///var/home/justin/Projects/FinSc-Box-Wiki)**: Compile-time `QTT 0` `Refl` proofs and QuickCheck property tests.
- **[`Finite-Science`](file:///var/home/justin/Projects/Finite-Science)** (`src/FiniteScience/`):
  - [`Energy.idr`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Energy.idr) — `EnergyState`, `WaveMaxel`/`EnergyMaxel`, Pythagorean sweeps, coupled source & `Maxel`-seam dynamics, and Model-B zero-tag root pack/unpack.
  - [`FlatSpaceUniverse.idr`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/FlatSpaceUniverse.idr) & [`HereditaryUniverse.idr`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/HereditaryUniverse.idr) — Linear `App1` black-box isolation comparing flat `Coord2` (Model A) against single-root `PureMultiset` (Model B).
  - [`Experiments.idr`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Experiments.idr) — 6 automated experiments verifying 0D conservation, peel work, non-interfering zoomed observers, 2D causal gravity (`4A–4F`), Model A == Model B parity, Goh spread polynumbers, coupled flow, 5-cycle relic attractors, `Maxel`-seam equilibration, and emergent 3D gravity.

### Build & Run

All commands run non-interactively inside `fedora-toolbox-44` using `/var/home/justin/.local/bin/idris2`:

```bash
# 1. Build and install FinSc-Box
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/FinSc-Box && rm -rf build && /var/home/justin/.local/bin/idris2 --build FinSc-Box.ipkg && /var/home/justin/.local/bin/idris2 --install FinSc-Box.ipkg"

# 2. Verify FinSc-Box-Wiki proofs & QuickCheck
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/FinSc-Box-Wiki && rm -rf build && /var/home/justin/.local/bin/idris2 --build FinSc-Box-Wiki.ipkg && ./build/exec/finsc-box-wiki"

# 3. Build and run Finite-Science Experiments 1–6 (~2m19s runtime)
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/Finite-Science && rm -rf build && /var/home/justin/.local/bin/idris2 --build Finite-Science.ipkg && ./build/exec/finite-science-experiments"
```

---

## License

Released under the MIT License.
