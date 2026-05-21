module Tests

import System
import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "Definition Test" `atDir` "definitions"
  , "Box Arithmetic Test" `atDir` "definitions/multiset_box_arithmetic"
  , "Property Test" `atDir` "properties"
  ]
