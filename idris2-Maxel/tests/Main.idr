module Main

import Math.Maxel
import Math.MaxelNL
import Math.UnaryMultiset
import Math.Interfaces
import Data.Linear

%default total

v1 : UnaryMultiset ()
v1 = Add () Zero

v2 : UnaryMultiset ()
v2 = Add () (Add () Zero)

v3 : UnaryMultiset ()
v3 = Add () (Add () (Add () Zero))

v4 : UnaryMultiset ()
v4 = Add () (Add () (Add () (Add () Zero)))

p12 : Pixel (UnaryMultiset ())
p12 = Builtin.(#) v1 v2

p13 : Pixel (UnaryMultiset ())
p13 = Builtin.(#) v1 v3

p14 : Pixel (UnaryMultiset ())
p14 = Builtin.(#) v1 v4

p24 : Pixel (UnaryMultiset ())
p24 = Builtin.(#) v2 v4

p34 : Pixel (UnaryMultiset ())
p34 = Builtin.(#) v3 v4

diamondMaxel : Maxel (UnaryMultiset ())
diamondMaxel = Add p12 (Add p13 (Add p14 (Add p24 (Add p34 Zero))))

diamondProduct : Maxel (UnaryMultiset ())
diamondProduct = composeMaxel diamondMaxel diamondMaxel

transposedDiamond : Maxel (UnaryMultiset ())
transposedDiamond = transposeMaxel diamondMaxel

t12 : Pixel (UnaryMultiset ())
t12 = Builtin.(#) v1 v2

t23 : Pixel (UnaryMultiset ())
t23 = Builtin.(#) v2 v3

t13 : Pixel (UnaryMultiset ())
t13 = Builtin.(#) v1 v3

tournamentMaxel : Maxel (UnaryMultiset ())
tournamentMaxel = Add t12 (Add t23 (Add t13 Zero))

tournamentNL : MaxelNL (UnaryMultiset ())
tournamentNL = maxelToNL tournamentMaxel

covering
main : IO ()
main = do
  putStrLn "Maxel tests compiled successfully."
  putStrLn ("Diamond Maxel: " ++ show diamondMaxel)
  putStrLn ("Transitive Product (D * D): " ++ show diamondProduct)
  putStrLn ("Transposed Diamond: " ++ show transposedDiamond)
  
  putStrLn ("Tournament Maxel: " ++ show tournamentMaxel)
  putStrLn ("Tournament isSet: " ++ show (isSetNL tournamentNL))
  putStrLn ("Tournament isIrreflexive: " ++ show (isIrreflexiveNL tournamentNL))
  putStrLn ("Tournament isAntiSymmetric: " ++ show (isAntiSymmetricNL tournamentNL))
  putStrLn ("Tournament isTotal: " ++ show (isTotalNL tournamentNL))

