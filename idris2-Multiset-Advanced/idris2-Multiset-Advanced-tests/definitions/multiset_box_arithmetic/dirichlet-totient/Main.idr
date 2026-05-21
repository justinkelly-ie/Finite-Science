module Main
import Hedgehog
import Math.Multiset
import Data.List

gcdNat : Nat -> Nat -> Nat
gcdNat a 0 = a
gcdNat a b = gcdNat b (fromInteger ((cast a) `mod` (cast b)))

totient : Nat -> Nat
totient k = length (filter (\x => gcdNat k x == 1) [1..k])

repeatElements : Nat -> Nat -> List (MSet (MSet ()))
repeatElements count val = replicate count (Math.Multiset.fromNat val)

totientBox : Nat -> MSet (MSet (MSet ()))
totientBox n = fromList (concatMap (\k => repeatElements (totient k) k) [1..n])

identityBox : Nat -> MSet (MSet (MSet ()))
identityBox n = fromList (concatMap (\k => repeatElements k k) [1..n])

zetaBox : Nat -> MSet (MSet (MSet ()))
zetaBox n = fromList (map Math.Multiset.fromNat [1..n])

prop_zeta_totient_id : Property
prop_zeta_totient_id = property $ do
  n <- forAll (nat (linear 1 30))
  truncate n (carret (zetaBox n) (totientBox n)) === identityBox n

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Zeta^Totient = Identity" [ ("prop", prop_zeta_totient_id) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
