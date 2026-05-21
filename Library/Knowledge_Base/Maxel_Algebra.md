# Maxel Algebra and Combinatorics

This document summarizes the stabilized findings regarding the algebraic representation of combinatorial structures using **Maxels**.

## Algebraic Representation

A combinatorial structure is modeled as a **Maxel** $M$, which is a multiset of directed edges (pixels) $[a, b]$. 

### SYNTRO Property Model

The fundamental properties of combinatorial objects are captured by the **SYNTRO** model (Set, Symmetric, Anti-symmetric, Transitive, Reflexive, Irreflexive, Total):

1.  **Direct Multigraph**: An unrestricted Maxel.
2.  **Poset**: A Maxel with properties **R** (Reflexive), **N** (Anti-symmetric), and **T** (Transitive).
3.  **Equivalence Relation**: A Maxel with properties **R** (Reflexive), **Y** (Symmetric), and **T** (Transitive).
4.  **Tournament**: A Maxel with properties **I** (Irreflexive), **N** (Anti-symmetric), and **O** (Total).

## The Transitive Product

The key algebraic operation for Maxels is the **Transitive Product** (Maxel Multiplication). For two maxels $M_1$ and $M_2$:
$$M_1 \cdot M_2 = \{ [a, c] \mid [a, b] \in M_1 \text{ and } [b, c] \in M_2 \}$$

This product allows for the verification of structural properties (like transitivity) through matrix-like multiplication in Idris 2.

## Non-Linear Audit Primitives

To support complex audits (SYNTRO) in a QTT-hardened environment, the algebra provides a set of **Non-Linear (NL)** primitives:

*   **transposeNL**: A non-erased, non-linear transpose function that can be used within runtime predicates and property tests.
*   **Order-Independent Symmetry**: A Maxel $M$ is symmetric ($Y$) if its non-linear representation is equal to its non-linear transpose ($M_{NL} = \text{transposeNL}(M_{NL})$). This is necessary because the linear `lEq` for multisets is order-dependent, while the physical symmetry of the transition lattice is not.

## Stabilized Implications

- **Structural Parity**: The algebraic properties of the Maxel (S, Y, N, T, R, I, O) directly map to the logical constraints of the underlying data structure.
- **Transitivity Verification**: A Maxel $M$ is transitive if and only if $M \cdot M \subseteq M$.
- **Reflexivity Extraction**: For any transitive and symmetric Maxel, the reflexive property $R$ can be derived as $T + Y \implies R$.
- **Resource Exhaustion**: The use of linear types ensures that the audit process itself does not leak information; the multiset must be fully consumed or reconstructed by the auditor.

## 4. Entanglement Witness (The Red Bridge)
The Maxel Algebra formalizes non-locality through the **Entanglement Witness** protocol.
- **Indivisible Unit**: Entanglement is modeled as a single multiset containing two transitions.
- **Metric Stability**: Physical consistency requires that any transformation preserving the **Red Metric** (Minkowski) invariant on one transition must be coupled with a corresponding shift in the other.
- **Audit Requirement**: $A_{Red}(p_1, p_2, \text{cross}) = 0$.

This algebraic framework provides the foundation for the **Orange Book** documentation and the formal verification of the RCIT metric spaces.


