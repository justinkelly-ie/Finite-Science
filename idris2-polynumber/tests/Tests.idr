module Tests

import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "Polynumber" `atDir` "polynumber"
  ]
