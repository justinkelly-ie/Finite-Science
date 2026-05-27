module Tests

import System
import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "Multiset Definitions" `atDir` "definitions"
  , "Multiset Properties"  `atDir` "properties"
  ]
