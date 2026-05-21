# Maxel Combinatorics (Dense Reference)

### 1. The SYNTRO Model
Maxels (multisets of pixels) are classified by their algebraic properties:

| Code | Property | Formal Definition |
| :--- | :--- | :--- |
| **S** | **Set** | Every pixel multiplicity is exactly 1. |
| **Y** | **Symmetric** | Invariant under transpose: $(a, b) \in M \iff (b, a) \in M$. |
| **N** | **Anti-symmetric** | $(a, b) \in M \land (b, a) \in M \implies a = b$. |
| **T** | **Transitive** | $(a, b) \in M \land (b, c) \in M \implies (a, c) \in M$. |
| **R** | **Reflexive** | For all $a \in J$, $(a, a) \in M$. |
| **I** | **Irreflexive** | No diagonal pixels $(a, a)$ exist in $M$. |
| **O** | **Total** | For any distinct $a, b \in J$, $(a, b) \in M \lor (b, a) \in M$. |

### 2. Combinatorial Objects as Maxels
| Object | Required Properties |
| :--- | :--- |
| **Directed Multigraph** | None (Generic Maxel) |
| **Directed Graph** | **S** (Set) |
| **Simple Graph** | **S** + **Y** + **I** |
| **Pre-order** | **S** + **R** + **T** |
| **Poset** | **S** + **R** + **N** + **T** |
| **Equivalence Relation** | **S** + **R** + **Y** + **T** |
| **Tournament** | **S** + **I** + **N** + **O** |

### 3. Key Identities
- **$T + Y \implies R$**: A transitive and symmetric maxel is automatically reflexive on its support.
- **Transitive Product**: $M$ is transitive if its matrix product $M^2$ (in Box Arithmetic) satisfies $\text{supp}(M^2) \subseteq \text{supp}(M)$.

---
**Status**: Modularized for Token Efficiency
**Related**: [Math_Foundations](../Maths_Foundations/Index.md), [Box_Arithmetic](./Box_Arithmetic_Index.md)
