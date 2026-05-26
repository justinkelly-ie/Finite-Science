module GoldenTests

import System
import Test.Golden.RunnerHelper

export
main : IO ()
main = goldenRunner
  [ "Linear Physics Golden Tests" `atDir` "properties" ]
