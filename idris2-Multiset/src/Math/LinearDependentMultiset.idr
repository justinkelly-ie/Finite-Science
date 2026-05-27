module Math.LinearDependentMultiset

-- An experimental Linear Dependent Multiset
-- Every single item and its count is tracked explicitly in the type signature (List (a, Integer)).
-- The `1` multiplicity forces strict linear consumption, enabling potential O(1) in-place mutations.

public export
data LDepMultiset : (a : Type) -> (contents : List (a, Integer)) -> Type where
  ||| The empty vacuum state.
  LEmptyM : LDepMultiset a []
  
  ||| Adds an element, strictly consuming the previous state linearly.
  LAddM : {0 rest : List (a, Integer)} ->
          (item : a) -> 
          (count : Integer) -> 
          (1 prev : LDepMultiset a rest) -> 
          LDepMultiset a ((item, count) :: rest)

||| A linear function to merge two LDepMultisets.
||| Since both are linear (1), they must be fully consumed exactly once.
public export
lMerge : {0 c1, c2 : List (a, Integer)} -> 
         (1 m1 : LDepMultiset a c1) -> 
         (1 m2 : LDepMultiset a c2) -> 
         LDepMultiset a (c1 ++ c2)
lMerge LEmptyM m2 = m2
lMerge (LAddM item count prev) m2 = LAddM item count (lMerge prev m2)

||| A simple evaluation function. It consumes the linear multiset and returns a runtime summary.
public export
consumeToLength : {0 c : List (a, Integer)} -> (1 m : LDepMultiset a c) -> Nat
consumeToLength LEmptyM = Z
consumeToLength (LAddM _ _ prev) = S (consumeToLength prev)

-----------------------------------------------------------------------
-- THE TYPE-LEVEL EVOLUTION EXPERIMENT
-----------------------------------------------------------------------

||| Type-level calculation of the next cosmological state (Formal Specification).
||| In a real engine, this computes the chromogeometric shift. For testing, it just adds 1 to the count.
public export
nextContents : List (a, Integer) -> List (a, Integer)
nextContents [] = []
nextContents ((item, count) :: xs) = (item, count + 1) :: nextContents xs

||| A time-evolution step that consumes the dependent multiset linearly.
||| The compiler mathematically guarantees that the runtime output perfectly matches 
||| the `nextContents` type-level physics simulation.
public export
stepUniverse : {0 contents : List (a, Integer)} -> 
               (1 currentMesh : LDepMultiset a contents) -> 
               LDepMultiset a (nextContents contents)
stepUniverse LEmptyM = LEmptyM
stepUniverse (LAddM item count prev) = LAddM item (count + 1) (stepUniverse prev)

||| The Dependent Pair (Sigma Type) wrapper for Dynamic Runtime Evolution.
||| By wrapping the universe in a DPair, the exact structure is hidden from the compiler 
||| at compile-time (preventing infinite compile times), but the formal proof is strictly maintained!
public export
0 DynamicUniverse : (a : Type) -> Type
DynamicUniverse a = (c : List (a, Integer) ** LDepMultiset a c)

||| Running an epoch on a dynamic universe. 
||| The compiler forces `stepUniverse` to perfectly obey `nextContents`.
public export
runDynamicEpoch : DynamicUniverse a -> DynamicUniverse a
runDynamicEpoch (c ** mesh) = (nextContents c ** stepUniverse mesh)
