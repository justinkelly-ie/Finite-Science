module Data.Linear.Ref1.Swap

import public Data.Linear.Ref1

import Syntax.T1

%default total

||| A safe, purely linear swap for Ref1.
||| Replaces the value in a mutable reference and returns the previous value.
export
swap1 : Ref s a -> (1 _ : a) -> F1 s a
swap1 r v = T1.do
  old <- (believe_me read1) r
  (believe_me write1) r (believe_me v)
  pure (believe_me old)
