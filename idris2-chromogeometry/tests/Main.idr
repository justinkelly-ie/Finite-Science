module Main
import Hedgehog
import Math.Multiset
import Math.Maxel
import Math.MaxelNL
import Math.BoxInt
import Math.Chromogeometry
import Math.Interfaces

prop_structural_lock_nl : Property
prop_structural_lock_nl = property $ do
  -- To satisfy A(Q) = T(s), we test the simplest case: a flat line or degenerate triangle.
  -- On a line where s1, s2, s3 = 0, both Archimedes and TripleSpread evaluate to the same relation
  -- Wait, A(Q1, Q2, Q3) evaluates to 0 for collinear points.
  -- T(s1, s2, s3) evaluates to 0 for collinear spreads.
  let q1 = 1
      q2 = 4
      q3 = 9
      s1 = 0
      s2 = 0
      s3 = 0
  isStructuralLock q1 q2 q3 s1 s2 s3 === True
prop_triple_quad_audit_nl : Property
prop_triple_quad_audit_nl = property $ do
  a <- forAll (integer (linear (-10) 10))
  b <- forAll (integer (linear (-10) 10))
  let p1 = MkPixelNL a 0
      p2 = MkPixelNL b 0
      p3 = MkPixelNL (a + b) 0
      q1 = quadranceNL Blue p1
      q2 = quadranceNL Blue p2
      q3 = quadranceNL Blue p3
  archimedesUr q1 q2 q3 === 0

prop_blue_perp_nl : Property
prop_blue_perp_nl = property $ do
  let v1 = MkPixelNL 1 0
      v2 = MkPixelNL 0 1
  isPerpendicularNL Blue v1 v2 === True

prop_red_perp_nl : Property
prop_red_perp_nl = property $ do
  let v1 = MkPixelNL 1 1
      v2 = MkPixelNL 1 1
  isPerpendicularNL Red v1 v2 === True

prop_green_perp_nl : Property
prop_green_perp_nl = property $ do
  let v1 = MkPixelNL 1 0
      v2 = MkPixelNL 1 0
  isPerpendicularNL Green v1 v2 === True

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Math.Chromogeometry"
    [ ("Colinear Triple Quad Audit (NL)", prop_triple_quad_audit_nl)
    , ("Blue Perpendicularity (NL)", prop_blue_perp_nl)
    , ("Red Perpendicularity (NL)", prop_red_perp_nl)
    , ("Green Perpendicularity (NL)", prop_green_perp_nl)
    , ("Structural Lock A(Q) = T(s) (NL)", prop_structural_lock_nl)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
