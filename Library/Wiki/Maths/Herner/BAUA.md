# From Boolean Algebra to Unified Algebra

**Eric C. R. Hehner**  
University of Toronto  
*Published in the Mathematical Intelligencer v.26 n.2 p.3-19, 2004*

---

> [!IMPORTANT]
> **Project Adoption & Synthesis**
> In this documentation pipeline, we adopt **Hehner's Unified Algebra** specifically for its treatment of **Quantifiers** and **Probability**. However, we **reject** Hehner's specific symbols and "Unified" Boolean logic in favor of **Wildberger's [[Maths/Wildberger/Algebra_of_Boole/Algebra_of_Boole_Index|Algebra of Boole]]**. 
> - **Quantifiers/Probability**: Follow Hehner (Operators on functions, Information scale).
> - **Boolean Logic**: Follow Wildberger (Arithmetic in GF(2), $x^2=x$ polynomial approach).

---

## 1. Summary of Foundations

### Introduction: The Educational Failure
Boolean algebra is inherently simpler than number algebra, yet it is taught much later. Hehner argues this is due to poor terminology, confusing symbols, and a historical accident where formal reasoning was not seen as a "calculation" tool. We must move logic from a "specialised philosophy" to a "routine tool" like arithmetic.

### Historical Perspective: The Distrust of Abstraction
Just as early mathematicians justified $2+3=5$ with "gentylmenne counting chekyns," modern logicians often justify steps with natural language ("hence," "thus," "therefore"). History shows that once we trust the algebra (symbol manipulation), we can calculate faster and more accurately without referring back to "meaning" at every step.

### Boolean Calculation: Simplification is Proof
A formal proof is nothing more than a boolean calculation. Proving $(a \implies b) \lor (b \implies a)$ is equivalent to simplifying the expression to $\top$ (true). Solving equations and proving theorems are the same activity: algebraic simplification.

---

## 2. Detailed Arguments (Hehner's Perspective)

### A. Quantifiers: The Unified Operator
Hehner proposes that all quantifiers ($\forall, \exists, \Sigma, \Pi$) are instances of a single pattern: an **operator applied to a function**.

- **Structure**: Let $O$ be an operator and $f$ be a function. The quantified expression is $O f$.
- **Unified Mapping**:
    - If $f$ returns a number, $O = +$ gives the **Sum** ($\Sigma f$).
    - If $f$ returns a number, $O = \times$ gives the **Product** ($\Pi f$).
    - If $f$ returns a boolean, $O = \land$ gives **Universal Quantification** ($\forall f$).
    - If $f$ returns a boolean, $O = \lor$ gives **Existential Quantification** ($\exists f$).
- **Benefit**: This removes the need for separate logical and mathematical quantifier rules. All rules for $\Sigma$ (like change of variable) apply directly to $\forall$ and $\exists$.

### B. Probability: The Information Scale
Hehner views Booleans as the "endpoints" of probability. Probability is not a separate logic but a real-valued extension of Boolean algebra where:
- $\perp$ (false) is $0$.
- $\top$ (true) is $1$.
- Any value in $[0, 1]$ represents a probability.

In his **[[Herner/ProPer|Probability Perspective]]**, he equates probability with **Information**. Information ($I$) in bits and Probability ($p$) are the same measure on different scales ($I = -\log p$). This treats "no information" as a uniform distribution by definition, dissolving the "problem of prior probabilities."

### C. Metalogic: Dissolving the Meta-Level
Traditionally, logic is divided into "object language" and "metalanguage" (where we talk *about* the logic). Hehner argues this distinction is an unnecessary complication.
- **Single Algebra**: There is no "is true" outside the system; there is only the value $\top$ within the algebra.
- **Proof as Calculation**: A proof that $P \implies Q$ is simply the calculation $P \leq Q = \top$. 
- **Consistency**: The system is its own metalogic. Consistency is not a meta-property to be proven from outside, but a property of the calculation rules themselves.

---

## 3. The Wildberger Bypass (Boolean Logic)

While we adopt Hehner's higher-level unification (Quantifiers and Probability), we diverge on the core Boolean engine. Hehner uses lattice-based symbols ($\land, \lor, \top, \perp$) and traditional truth-table logic. 

We instead adopt **Wildberger’s [[Maths/Wildberger/Algebra_of_Boole/Algebra_of_Boole_Index|Algebra of Boole]]**, which:
1.  **Rejects** the Lattice approach as overly complicated for calculation.
2.  **Employs** the polynomial approach: $x \land y \mapsto xy$ and $x \oplus y \mapsto x+y$.
3.  **Enforces** the Law of Duality ($x^2 = x$) as the primary simplification engine.

This allows us to perform "Boolean Calculation" using the familiar rules of high-school algebra (polynomial reduction) while retaining Hehner’s powerful unified treatment of quantifiers and probability.

---
*Note: This synthesis forms the logical core of the RCIT documentation pipeline.*
