module Tests

import System
import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "LUniverse Definitions" `atDir` "definitions"
  , "LUniverse Properties"  `atDir` "properties"
  , "LUniverse Particles"   `atDir` "particles"
  , "LUniverse Evolution"   `atDir` "evolution"
  ]
