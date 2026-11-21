module Main

import Control.App
import Control.App.Console
import Control.App.FileIO
import Data.List
import System
import System.File
import FiniteScience

%default total

public export
runPureSuite : Has [Console] e => App e (Bool, List String)
runPureSuite = do
  let banner = [ "================================================================"
               , "  FINITE-SCIENCE: App -> App1 Black-Box A/B Experiment Suite     "
               , "  (Closed-Energy Wildberger Pythagorean Gate, Zero Battery)     "
               , "================================================================" ]
  traverse_ putStrLn banner
  (p1, l1) <- runExperiment1
  (p2, l2) <- runExperiment2
  (p3, l3) <- runExperiment3
  (p4, l4) <- runExperiment4and5
  let ok = p1 && p2 && p3 && p4
  let footer = [ "================================================================"
               , if ok then "ALL 5 FINITE-SCIENCE EXPERIMENTS PASSED" else "FINITE-SCIENCE EXPERIMENTS FAILED"
               ]
  traverse_ putStrLn footer
  pure (ok, banner ++ l1 ++ l2 ++ l3 ++ l4 ++ footer)

public export
covering
writeTelemetryFile : FileIO e => String -> String -> App e Bool
writeTelemetryFile path body =
  withFile path WriteTruncate
    (\_ => pure False)
    (\h => do fPutStrLn h body
              fflush h
              pure True)

public export
covering
runWithTelemetry : HasErr AppHasIO e => App e Bool
runWithTelemetry = do
  (ok, lines) <- runPureSuite
  wrote <- withFileIO
    (writeTelemetryFile "experiment_trace.txt" (fastConcat (intersperse "\n" lines)))
    (\res => pure res)
    (\err => do putStrLn ("FileIO telemetry error: " ++ show err)
                pure False)
  putStrLn ("Boundary telemetry written to experiment_trace.txt: " ++ show wrote)
  pure (ok && wrote)

public export
covering
main : IO ()
main = do
  ok <- run runWithTelemetry
  if ok then pure () else exitFailure
