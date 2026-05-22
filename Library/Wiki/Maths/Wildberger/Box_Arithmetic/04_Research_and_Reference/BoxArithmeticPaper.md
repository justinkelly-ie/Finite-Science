# Box Arithmetic: Polynomials without Variables and the Fundamental Identity of Arithmetic

**N J Wildberger**  
School of Mathematics and Statistics  
UNSW, Sydney, Australia

---

## Abstract
Box Arithmetic is a finite combinatorial framework built from boxes, or finite multisets. Starting from a single object, the empty box, natural numbers, polynumbers, and multinumbers arise by successive levels of nesting, together with a corresponding hierarchy of arithmetic operations, and with no need for variables. After addition and multiplication, the third operation in this hierarchy, the caret, gives a new algebraic structure on polynumbers. Its main number-theoretic consequence is the Fundamental Identity of Arithmetic: for each natural number $n$, a finite caret product of truncated prime-power boxes equals exactly the box $[1, 2, \dots, n]$. This finite identity subsumes the usual Fundamental Theorem of Arithmetic and provides a combinatorial model for truncated Dirichlet algebra. In particular, familiar relations involving Euler products, Möbius inversion, divisor-count and divisor-sum functions arise here as exact finite identities, requiring neither infinite series nor analytic convergence.

---

## 1 Introduction

Four millennia ago, the Babylonians already knew how to work with what we would now call polynomial equations, solving quadratics by a kind of geometric completion. Since then, mathematicians have steadily built an enormous edifice on top of this ancient foundation—and in doing so have quietly accumulated a great deal of logical debt. Even something as elementary as a polynomial in one variable, in the modern ZFC framework, requires an infinite set of ordered pairs of natural numbers, where each ordered pair $[a, b]$ is itself defined as the set $\{\{a\}, \{a, b\}\}$. But a polynomial like $3 + x + 2x^3$ is a finite expression. Its definition should not require infinity.

We would like to propose a leaner foundation for pure mathematics, called **Box Arithmetic**, in which every object is genuinely finite, directly constructible, and completely encodable on a computer. The primary data structure is not a set but rather a multiset—which we call a **box**—where repetition is allowed and order is unimportant. Starting from a single object, the empty box (which we call zero), every mathematical object in our framework is built by finite nesting of boxes inside boxes. Natural numbers emerge at the first level after zero, polynomials in one variable at the next, polynomials in arbitrarily many variables at the level after that. At each stage a new arithmetic operation appears, and it is the third of these—which we call the **caret operation**—that leads somewhere surprising.

Here is our destination. To a modern audience comfortable with infinite objects and infinite operations, we may write informally:

$$[1, 2, 2^2, \dots] \wedge [1, 3, 3^2, \dots] \wedge [1, 5, 5^2, \dots] \wedge [1, 7, 7^2, \dots] \wedge \dots = [1, 2, 3, 4, 5, 6, 7, \dots]$$ (FIA)

On the left, we see one box of prime powers for each prime, all connected by the caret operation. On the right, we see the box of all strictly positive natural numbers. The equality of these two boxes, which are ultimately combinatorial objects, is the **Fundamental Identity of Arithmetic**, and the usual Fundamental Theorem of Arithmetic is an immediate consequence. With just a little more work, so is Euler’s product formula for the zeta function, and in fact innumerable further identities involving the Möbius function, divisor counts, divisor sums, the Liouville function, and many more.

Now, the identity as written above is of course informal: both sides contain infinitely many elements, and the caret product on the left runs over infinitely many primes. This sits in apparent tension with our claim that everything in box arithmetic is finite. The resolution is that (FIA) is best understood not as a single identity between infinite objects, but as a *uniform family* of exact finite identities, one for each natural number $n$: for any $n$, the caret product of finitely many finite boxes of prime powers—one box per prime up to $n$, containing only those powers not exceeding $n$—equals exactly the finite box $[1, 2, \dots, n]$.

The infinite version is a suggestive shorthand for this family, in the same way that a power series is shorthand for its sequence of partial sums. Every individual identity in the family involves only finite boxes and finitely many operations, and is directly checkable by computation. We will make this precise in Section 7 via a truncation operator.

The algebra of Dirichlet series from analytic number theory can then be developed in a purely algebraic and combinatorial fashion, with no complex numbers and no convergent series required. And even questions that classically demand real analysis—such as the limiting behavior of $\sum_{0 < n \le N} \frac{1}{\zeta(n)^3}$ as $N$ grows—can be answered perfectly well by rational approximation intervals, improvable on demand by purely finite computation. This is, after all, what applied mathematics and modern computation actually deliver; and since real analysis ultimately grounds itself in equivalence classes of Cauchy sequences of rationals, an infinite construction built on an infinite construction, one may reasonably ask why we should not simply work with the finite rational approximations directly, and be honest about what we are computing.

In Box Arithmetic, the primary data structure, the box, is simply a finite multiset. This is a more natural starting point than a set: multisets can always be added, by combining their elements, independent of the nature of those elements. This operation—combining boxes—underlies almost all linear structure in mathematics. It is built into the foundation, not added later as an afterthought.

We develop the basic arithmetic of boxes in Section 2, establish natural numbers and polynumbers (our name for polynomials without variables) in Sections 3 and 4, extend to multinumbers (polynomials in arbitrarily many variables) in Section 5, and introduce the caret operation in Section 6. Section 7 sets up the summation operator needed for the number-theoretic applications, and Section 8 states and applies the Fundamental Identity of Arithmetic, culminating in a rigorous rational interval for a classical Dirichlet sum computed entirely by finite box arithmetic.

## 2 Boxes and their addition and multiplication

The empty box is an expression of the form $[\ ]$ consisting of a left lower square bracket, followed by a space, followed by a right lower square bracket. We call this empty box **zero**, and denote it with the number $0$. Thus $0 \equiv [\ ]$. We declare that the empty box $0$ is a box.

General boxes are defined recursively by starting with the empty box and then nesting boxes inside boxes, always with only a finite number of boxes involved. Crucially repetitions are allowed, so this is going beyond set theory.

The official definition is that if $A, B, \dots, K$ are boxes, not necessarily distinct, then so is the expression $M = [A, B, \dots, K]$, with the order of the boxes unimportant. The boxes $A, B, \dots, K$ are called the **elements** of the box $M$. If the box $X$ is an element of the box $Y$, then we write $X \in Y$. Boxes are equal if they contain exactly the same elements, possibly rearranged.

**Example 1** Since $0$ is a box, we have that $[0]$ is a box: we call this **one**, and denote it by the number $1$. The box **two** is $2 \equiv [0, 0]$ and the box **three** is $3 \equiv [0, 0, 0]$. Here is a more complicated box, showing that our naming of basic boxes allows different representations of the same box:
$$p = [0, [[0], [0]], [0, 0, 0], [[0, 0, 0]]] = [0, [1, 1], 3, [3]]$$

The fundamental operation on boxes is **addition**. If $A, B, \dots, K$ are boxes, then the sum $A + B + \dots + K$ is the box consisting of all the elements of the boxes $A, B, \dots, K$. So for example if $M = [a, a, K]$ and $N = [a, N]$ and $P = [K, \emptyset]$ are boxes, then $M + N + P = [a, a, a, K, K, N, \emptyset]$. Addition of boxes is the mathematical equivalent of dumping all the contents of several physical boxes into a single new physical box. The simplest example is $0 + 0 = 0$: the sum of two empty boxes is an empty box.

Note that addition is not intrinsically a binary operation, for example:
$[0, 0] + [[0, 0], 0] + [[0, 0, 0], [0]] = [0, 0, [0, 0], 0, [0, 0, 0], [0]] = [0, 0, 0, 1, 2, 3]$ (using numbers as shorthand for boxes of zeros).

Addition of boxes is commutative, associative, and supports cancellation. The empty box $0$ is the additive identity. We also note a **zero sum property**: if $A + B + \dots + K = 0$, then $A = B = \dots = K = 0$.

**Multiplication** is the natural successor to the addition operation, and holds for all boxes. If $A, B, \dots, K$ are boxes, then the product $A \times B \times \dots \times K$ is the box consisting of all possible sums of the elements of the boxes $A, B, \dots, K$, that is:
$$A \times B \times \dots \times K = [a + b + \dots + k : a \in A, b \in B, \dots, k \in K]$$
In case one or more of $A, B, \dots, K$ equals $0$, the product has no elements in it, so is $0$. multiplicities are maintained.

**Example 2** If $M = [a, a, K]$ and $N = [a, N]$ and $P = [K, L]$, then $M \times N \times P$ contains terms like $a+a+K, a+a+L, a+N+K, \dots$ (total $3 \times 2 \times 2 = 12$ elements).

Multiplication is commutative, associative, and distributes over addition. The box $1 \equiv [0]$ is the multiplicative identity. Multiplication supports non-zero cancellation and satisfies a zero product property.

There is a natural hierarchy of operations on boxes:
- Addition: $+ \equiv \oplus^{(0)}$
- Multiplication: $\times \equiv \oplus^{(1)}$
- Successor: $A \oplus^{(n+1)} B \oplus^{(n+1)} \dots \oplus^{(n+1)} K = [a \oplus^{(n)} b \oplus^{(n)} \dots \oplus^{(n)} k : a \in A, b \in B, \dots, k \in K]$

The successor of multiplication is the **caret operation**, denoted by $\wedge \equiv \oplus^{(2)}$.

## 3 Natural number arithmetic

A **natural number** is a box of zeros. Thus $0 = [\ ]$, $1 = [0]$, $2 = [0, 0]$, $3 = [0, 0, 0]$, etc.
The natural numbers are linearly ordered $0 < 1 < 2 < \dots < n$.
Addition and multiplication of boxes of zeros recover the usual arithmetic of natural numbers.
- $3 + 4 = [0, 0, 0] + [0, 0, 0, 0] = [0, 0, 0, 0, 0, 0, 0] = 7$
- $3 \times 4 = [0, 0, 0] \times [0, 0, 0, 0] = [0+0, 0+0, \dots \text{(12 times)}] = [0, 0, \dots] = 12$

We can define multiples $kA = A + A + \dots + A$ and powers $A^k = A \times A \times \dots \times A$.
The **multiplicity** $m_B(A)$ of a box $B$ in $A$ is the number of times $B$ occurs as an element of $A$. We can write boxes using left subscripts for multiplicities: $[_2 7, _1 [3, 5], _1 [[4], 2]]$.

## 4 Polynumber algebra

A **polynumber** is a box of natural numbers.
- Degree $\text{deg}(p)$ is the largest natural number in the box.
- Addition and multiplication of polynumbers are just box operations.
- The base polynumber $\alpha \equiv [1]$. Then $\alpha^2 = [2], \alpha^3 = [3], \dots, \alpha^n = [n]$.
- Any polynumber can be written as a sum of powers of $\alpha$: $p = [0, 2] = 1 + \alpha^2$.
- Multiplicity array: $p = [m_0, m_1, \dots, m_n]$ where $m_i$ is the multiplicity of $i$.
- Multiplication corresponds to the convolution (Cauchy product) of multiplicity arrays.

### 4.1 Truncations of polynumbers
$T_k(p)$ is the polynumber obtained by removing elements strictly greater than $k$.
Degree $k$ equality: $p =_k q \iff T_k(p) = T_k(q)$.

## 5 Multinumbers

A **multinumber** is a box of polynumbers.
Base multinumbers $\chi_n \equiv [[n]]$. Then $\chi_0 = [[0]] = [1] = \alpha$.
Multinumbers correspond to polynomials in variables $\chi_0, \chi_1, \dots$.

## 6 The caret operation

The caret operation $\wedge$ on boxes $A, B, \dots, K$ is:
$A \wedge B \wedge \dots \wedge K = [a \times b \times \dots \times k : a \in A, b \in B, \dots, k \in K]$
For natural numbers, $m \wedge n = m \times n$.
For monomials, $\alpha^m \wedge \alpha^n = \alpha^{mn}$.
For base multinumbers, $\chi_m \wedge \chi_n = \chi_{m+n}$. (Indices are added!)

## 7 Caret forms of Dirichlet series

A **$\ast$-polynumber** is a polynumber with no $0$ elements (i.e., every element is $>0$).
Dirichlet form: $n^s \equiv [n]$.
Caret product: $m^s \wedge n^s = (mn)^s$.
This allows representing Dirichlet series as boxes.
- Zeta: $\zeta_n = \sum_{1 \le k \le n} k^s = [1, 2, \dots, n]$
- Möbius: $\mu_n = \sum_{1 \le k \le n} \mu(k) k^s = [1] - [2] - [3] - [5] + [6] \dots$

## 8 The Fundamental Identity of Arithmetic

For a prime $p$ and natural $n$, let $m(p, n)$ be the largest $k$ s.t. $p^k \le n$.
Prime power $\ast$-polynumber: $\Pi(p)_n = [1, p, p^2, \dots, p^{m(p,n)}]$.

**Theorem (FIA):** For any natural $n$, let $2, 3, 5, \dots, p$ be the primes $\le n$. Then:
$$\Pi(2)_n \wedge \Pi(3)_n \wedge \dots \wedge \Pi(p)_n =_n [1, 2, 3, \dots, n]$$

This finite identity captures the Fundamental Theorem of Arithmetic as an exact equality of multisets.

### 8.1 Calculating a limiting summation interval
Using the FIA, we can compute bounds for sums like $S(N) = \sum_{0 < n \le N} \frac{1}{\zeta(n)^3}$.
For $N \ge 44100$, using primes $2, 3, 5, 7$ and powers up to $2$:
- Lower bound $t \approx 1.06368$
- Upper bound $u \approx 1.125$
Interval width $\approx 0.061 < 1/10$. Precision can be improved by adding more terms.
