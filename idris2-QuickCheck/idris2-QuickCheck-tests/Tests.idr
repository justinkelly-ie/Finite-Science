module Tests

import System
import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "Engine Verification" `atDir` "properties"
  ]
