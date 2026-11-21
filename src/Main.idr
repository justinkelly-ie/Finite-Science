module Main

import Control.App
import Control.App.Console
import System
import FiniteScience

%default total

public export
runFiniteScienceSuite : Has [Console] e => App e Bool
runFiniteScienceSuite = do
  putStrLn "================================================================"
  putStrLn "  FINITE-SCIENCE: App1 + Nested PureMultiset + Compute Latency  "
  putStrLn "================================================================"
  p1 <- runExperiment1
  p2 <- runExperiment2
  p3 <- runExperiment3
  p4 <- runExperiment4
  putStrLn "================================================================"
  let ok = p1 && p2 && p3 && p4
  if ok
    then putStrLn "ALL 4 FINITE-SCIENCE EXPERIMENTS PASSED"
    else putStrLn "FINITE-SCIENCE EXPERIMENTS FAILED"
  pure ok

public export
covering
main : IO ()
main = do
  ok <- run runFiniteScienceSuite
  if ok then pure () else exitFailure
