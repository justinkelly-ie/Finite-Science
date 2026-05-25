module Data.Linear.Ref1.Swap

import public Data.Linear.Ref1

import Syntax.T1
import Data.Linear

%default total

||| A safe, purely linear swap for Ref1.
||| Replaces the value in a mutable reference and returns the previous value.
export
swap1 : Ref s a -> (1 _ : a) -> F1 s a
swap1 r v t =
  assert_linear (\val =>
    let old # t1 := read1 r t
        _   # t2 := write1 r val t1
     in old # t2
  ) v
