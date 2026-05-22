module TestQC

import QuickCheck

0 prop_identity : Fn Int Bool
prop_identity = MkFn (\x => x == x)

0 check_identity : So (QuickCheck True prop_identity)
check_identity = Oh
