# a Probability Perspective

**Eric C.R. Hehner**  
Department of Computer Science, University of Toronto  
*Published in Formal Aspects of Computing v.23 n.4 p.391-419, 2011*

---

## Abstract

This paper draws together four perspectives that contribute to a new understanding of probability and solving problems involving probability. The first is the Subjective Bayesian perspective that probability is affected by one's knowledge, and that it is updated as one's knowledge changes. The second is the Information Theory perspective, in which we take the bold new step of equating probability with information. The third is the formalist perspective (formalise, calculate, unformalise). Finally, the programmer's perspective provides a suitable formalism. To illustrate the benefits, we completely solve the hitherto open problem of the two envelopes.

> “Writing is nature's way of letting you know how sloppy your thinking is.” —Richard Guindon
> “Mathematics is nature's way of letting you know how sloppy your writing is.” —Leslie Lamport
> “Formal mathematics is nature's way of letting you know how sloppy your mathematics is.” —Leslie Lamport

---

## Introduction

Probability is often poorly understood. Simple problems like the "Two Children" problem often lead to debate even among experts.
- **Problem 1:** I have two children. At least one is a girl. What is the probability the other is a girl? (Answer: $1/3$)
- **Problem 2:** I have two children. The older is a girl. What is the probability the younger is a girl? (Answer: $1/2$)

This paper proposes an approach based on four pillars:
1. **Subjective Bayesian:** Probability expresses strength of belief based on knowledge.
2. **Information Theory:** Information and probability are the same thing on different scales.
3. **Formalist:** Replace argument with calculation.
4. **Programmer:** Use programming notations (assignments, if-then-else, loops) as the formal language for probability.

## Bayesian Perspective

Probability is not a property of an event, but a measure of belief according to someone's state of knowledge.
- A "fair coin" is not an object; a "fair bet" is a meaningful concept between two people with the same knowledge.
- Gaining knowledge can sometimes reduce predictability (e.g., learning about a coin's bias might move the probability from $1/2$ to $5/7$, but learning about the flipping machine's counter-bias might move it back to $1/2$).

## Information and Scale


## Formalisation and Calculation

The template for solving problems is:
1. **Formalise:** Choose variables and represent info as math expressions.
2. **Calculate:** Turn your back on the informal problem and use algebraic laws.
3. **Unformalise:** State the result in natural language.

## Probabilistic Programming

We generalise programming notations to handle probabilities:
- `ok`: The empty statement (probability $1$ that the state is unchanged).
- `x := e`: Assignment (probability $1$ that $x'$ becomes $e$).
- `if c then A else B`: $c \times A + (1-c) \times B$.
- `A ; B`: Sequential composition (summing over intermediate states).
- `A || B`: Parallel composition (joint probability, normalised).

A **distribution** is an expression whose sum over all states is $1$. We use the notation $\text{normalise}(E)$ or $(E)$ to turn any non-negative expression into a distribution.

## Famous Examples

### The Two Children
Formalising "at least one is a girl" for two children $c_1, c_2 \in \{G, B\}$:
The state space has 4 states: $GG, GB, BG, BB$, each with probability $1/4$.
Learning "at least one is a girl" ($c_1=G \lor c_2=G$):
- $GG: 1/4$
- $GB: 1/4$
- $BG: 1/4$
- $BB: 0$ (filtered out)
Normalize: $1/4 \div 3/4 = 1/3$ for each of the remaining 3 states.
The probability of "the other child is a girl" ($GG$) is $1/3$.

### Monty Hall
A contestant chooses a door ($c \in \{1, 2, 3\}$). The car is behind door $h$. Monty opens door $m$.
1. Initial state: $c, h, m$.
2. Car is placed: $h := \text{rand } \{1, 2, 3\}$
3. Choice is made: $c := \text{rand } \{1, 2, 3\}$
4. Monty opens a door: $m := \text{rand } (\{1, 2, 3\} \setminus \{c, h\})$
Calculation shows that the probability the car is behind the *other* door is $2/3$.

### The Two Envelopes
There are two envelopes, one with $x$ and one with $2x$. You pick one and see $y$. Should you switch?
Standard argument: The other envelope has $y/2$ or $2y$ with probability $1/2$ each. Expected value $1.25y$.
Hehner's perspective: The probability depends on your prior knowledge of $x$. If you have no information about the range of $x$, you cannot switch to gain an advantage. The "paradox" arises from an improper use of infinite distributions. Formalising the information content of $x$ resolves the problem.

## Conclusion

By equating probability with information and using a programming formalism, we can solve complex probability problems through calculation rather than intuition. This approach provides a solid foundation for "Probabilistic Programming" and automated reasoning about uncertainty.
Information and probability measure the same thing on different scales:
- **Information ($I$):** measured in bits. $I = -\log p$
- **Probability ($p$):** measured in "chances". $p = 2^{-I}$
- **State Space ($s$):** measured in "states". $s = 1/p$

| Bits ($b$) | States ($s$) | Chances ($c$) | Meaning |
| :--- | :--- | :--- | :--- |
| $0$ | $1$ | $1$ | Certainty |
| $1$ | $2$ | $1/2$ | Fair toss |
| $\infty$ | $\infty$ | $0$ | Impossible |

The "problem of prior probabilities" disappears: having no information about which of $n$ states occurs means probability $1/n$ for each state by definition (change of scale).

---
*Note: This summary captures the innovative "Unified Scale" and "Programmer's Perspective" central to Hehner's work.*
