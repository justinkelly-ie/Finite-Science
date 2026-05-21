# Implementation Plan: Multiset 1s (Norman Wildberger's Definition)

This document outlines the plan for implementing the `MSet1` (Multiset 1) data structure in Idris2, based on the definitions provided by Norman Wildberger's Box Arithmetic. 

## 1. Data Structure Definition
We define the linear multiset purely recursively without relying on Idris's built-in `List`. This elegantly reflects the nature of Box Arithmetic where everything is built purely from empty boxes.

```idris
data MSet1 : Type where
  Empty : MSet1
  Insert : MSet1 -> MSet1 -> MSet1
```

## 2. Core Constants and Conversions
Natural numbers are represented as a multiset containing $n$ `zero` elements.
- **Zero**: The empty multiset `[]`.
  ```idris
  zero : MSet1
  zero = Empty
  ```
- **Natural Numbers**:
  ```idris
  fromNat : Nat -> MSet1
  fromNat Z = Empty
  fromNat (S k) = Insert Empty (fromNat k)
  ```

## 3. Algebraic Operations
Following the requested definitions:

- **Addition** (`add`): Concatenates the elements of two multisets.
  ```idris
  add : MSet1 -> MSet1 -> MSet1
  add Empty b = b
  add (Insert a as) b = Insert a (add as b)
  ```

- **Summation** (`sigma` / `concatMSet1`): Flattens a box, summing all elements.
  ```idris
  sigma : MSet1 -> MSet1
  sigma Empty = Empty
  sigma (Insert x xs) = add x (sigma xs)
  ```

- **Multiplication** (`mul`): Applies addition pairwise over the elements of both multisets.
  ```idris
  mul : MSet1 -> MSet1 -> MSet1
  mul a b = sigma (mapMSet1 (\x => mapMSet1 (\y => add x y) b) a)
  ```

- **Carret** (`carret`): Applies multiplication pairwise over the elements.
  ```idris
  carret : MSet1 -> MSet1 -> MSet1
  carret a b = sigma (mapMSet1 (\x => mapMSet1 (\y => mul x y) b) a)
  ```

## 4. Alpha Powers and Truncation
- **Alpha Powers**: The notation `[n]` represents $\alpha^n$. If we have a multiset `x`, placing it in a single-element multiset `[x]` acts as raising $\alpha$ to the power of `x`.
  ```idris
  alphaPow : MSet1 -> MSet1
  alphaPow x = Insert x Empty
  ```
- **Truncation**: Removes elements whose structural size is strictly greater than $k$.
  ```idris
  truncate : Nat -> MSet1 -> MSet1
  ```

## 5. Typeclass Implementations
To make the library ergonomic to use in Idris2, we implement common interfaces:
- **`Show`**: To easily print nested box representations like `[[] []]`.
- **`Eq`**: Order-agnostic equality using a recursive `deleteFirst` approach to truly represent unordered multisets.
- **`Num`**: To allow using standard Idris operators (`+`, `*`, integer literals) with `MSet1`.

## 6. Testing Strategy
We utilize the `idris2-golden-runner-helper` setup.
1. **Simple Tests**: Print the results of various basic operations (`+`, `*`, `^`) and verify them via golden tests.
2. **Hedgehog Property Tests**:
   - Commutativity and Associativity for `add` and `mul`.
   - Truncation Properties: `Tk(p + q) = Tk(p) + Tk(q)` and `Tk(p * q) = Tk(Tk(p) * Tk(q))`
   - Fundamental Identity of Arithmetic (`carret` of truncated prime boxes yields strictly positive integers up to $n$).
   - Dirichlet Convolution Algebra (Testing identities with Zeta, Divisor Count, Divisor Sum, and Totient).
   - Caret Product Identity: `sigma (carret a b) = mul (sigma a) (sigma b)`.
