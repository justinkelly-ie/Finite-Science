module FiniteScience.GeometryAudits

import Control.App
import Control.App.Console
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Lenses
import FinScBox.QuadraticExchange
import FinScSpace
import FinScLens
import FiniteScience.Lab

%default total

--------------------------------------------------------------------------------
-- AUDIT 9: RATIONAL CHROMOGEOMETRY, RELATIVISTIC SPREAD LAW, METRIC ROTORS
--          & FRAME-COVARIANT NON-PERTURBING 3D OBSERVATION
--------------------------------------------------------------------------------

||| Spread Law `s_i / Q_i == A / (4 Q1 Q2 Q3)` checked with Sterling `Eq Proportion` on all three vertices.
public export
spreadLawHolds : Ord k => Maxel BoxInt k k SymForm -> (v1, v2 : Box BoxInt k) -> Bool
spreadLawHolds g v1 v2 =
  let (s1, s2, s3) = triangleSpreads g v1 v2
      q1   = metricQuadrance g v1
      q2   = metricQuadrance g v2
      q3   = metricQuadrance g (subM v2 v1)
      quad = MkProportion (triangleQuadrea g v1 v2) (4 * q1 * q2 * q3)
      per  = \s, q => MkProportion s.propNum (s.propDen * q)
  in (per s1 q1 == quad) && (per s2 q2 == quad) && (per s3 q3 == quad)

public export
stepFlatN : GroupCoord k => Nat -> DynamicsParams -> (1 u : FlatBlackBox k) -> App1 e (FlatBlackBox k)
stepFlatN Z       _ u = App1.pure1 u
stepFlatN (S rem) p u = App1.do
  u1 <- stepFlatWith p u
  stepFlatN rem p u1

public export
stepHereditaryN : Nat -> DynamicsParams -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
stepHereditaryN Z       _ u = App1.pure1 u
stepHereditaryN (S rem) p u = App1.do
  u1 <- stepHereditaryWith 3 p u
  stepHereditaryN rem p u1

||| Canonical external observer frame (`N_blue = 4 + 1 + 1 + 4 = 10`).
public export
observerRotor : Rotor
observerRotor = MkRotor 2 (vec3Box 1 (-1) 2)

||| Evolves a 3D dipole in Model A and observes its rotated moment through `PureObservation`.
export
runFlat3DFrame : App1 {u = Any} e (Box BoxInt (Fin 3), Box BoxInt (Fin 3), Integer)
runFlat3DFrame = App1.do
  u0  <- bootFlatWith (spaceBasis {n = 3})
  u1  <- injectFlatState (seedBoundDipole (spaceBasis {n = 3}) [1, 0, 0] [0, 0, 1] 2048) u0
  u2  <- stepFlatN 4 (canonDynamicsParams (ModeFactor 1 4)) u1
  obs <- observeFlatPure (observeRotatedMoment3D spaceBasis blueMetric observerRotor) u2
  let MkPureObs u3 mRot _ = obs
  st  <- closeFlat0D u3
  App1.pure (mRot, observeStateMoment3D spaceBasis st, stateQuadrance st)

||| Evolves the same 3D dipole in Model B and observes its rotated moment through `PureObservation`.
export
runHereditary3DFrame : App1 {u = Any} e (Box BoxInt (Fin 3), Box BoxInt (Fin 3), Integer)
runHereditary3DFrame = App1.do
  u0  <- bootHereditary0D
  u1  <- injectHereditaryState (seedBoundDipole (pureMSetBasis 3) [1, 0, 0] [0, 0, 1] 2048) u0
  u2  <- stepHereditaryN 4 (canonDynamicsParams (ModeFactor 1 4)) u1
  obs <- observeHereditaryPure
           (\r => observeRotatedMoment3D (pureMSetBasis 3) blueMetric observerRotor
                    (unpackRootToEvolutionState r).stateData) u2
  let MkPureObs u3 mRot _ = obs
  root <- closeHereditary0D u3
  let st = (unpackRootToEvolutionState root).stateData
  App1.pure (mRot, observeStateMoment3D (pureMSetBasis 3) st, stateQuadrance st)

||| Live 2D deflection spread of an 18-sweep directed pulse with and without a top dipole load.
export
runDeflectionSpreads : App1 {u = Any} e (Proportion, Proportion)
runDeflectionSpreads = App1.do
  let lab   = flatLab {n = 2}
      mode  = ModeFactor 1 4
      dpTop = seedBoundDipole lab.labBasis [4, 5] [4, 6] 8192
      pulse = seedDirectedPulse lab.labBasis [0, 0] (FS FZ) 512
  eaVac <- bootInjectAndRun lab mode 18 pulse
  eaBg  <- bootInjectAndRun lab mode 18 dpTop
  eaDp  <- bootInjectAndRun lab mode 18 (dpTop <+> pulse)
  App1.pure ( measureBandDeflectionSpread lab.labBasis (axisAtom 1) (-3) 4 0 eaVac.eaState neutral
            , measureBandDeflectionSpread lab.labBasis (axisAtom 1) (-3) 4 0 eaDp.eaState eaBg.eaState )

public export
check9AChromo : (Bool, Bool, BoxInt, BoxInt, BoxInt, BoxInt)
check9AChromo =
  let p1 = vec2Box 3 1; p2 = vec2Box 1 4
      aB = triangleQuadrea blueMetric p1 p2
      aR = triangleQuadrea redMetric  p1 p2
      aG = triangleQuadrea greenMetric2 p1 p2
      chromoOk = (aB == negate aR) && (aB == negate aG) &&
                 spreadLawHolds blueMetric p1 p2 && spreadLawHolds greenMetric2 p1 p2
      wOut = vec2Box 5 3; wEnd = vec2Box 10 0
      aTw = triangleQuadrea redMetric wOut wEnd
      twinOk = (metricQuadrance redMetric wOut == 16) &&
               (metricQuadrance redMetric (subM wEnd wOut) == 16) &&
               (metricQuadrance redMetric wEnd == 100) &&
               (aTw == -3600) && spreadLawHolds redMetric wOut wEnd
  in (chromoOk, twinOk, aB, aR, aG, aTw)

public export
check9BBlue : Bool
check9BBlue =
  let vBlue = vec3Box 3 (-2) 5
      bRot1 = MkRotor 1 (vec3Box 1 0 0)
      mB1   = rotorActionMaxel blueMetric bRot1
      mB2   = rotorActionMaxel blueMetric observerRotor
      mB12  = rotorActionMaxel blueMetric (composeRotor blueMetric observerRotor bRot1)
      nBlue = rotorNorm blueMetric observerRotor
  in (composeMaxel mB2 mB1 == mB12) &&
     (actMaxelR mB2 (actMaxelR mB1 vBlue) == actMaxelR mB12 vBlue) &&
     (metricQuadrance blueMetric (actMaxelR mB2 vBlue) == nBlue * nBlue * metricQuadrance blueMetric vBlue)

public export
check9BRed : (Bool, Box BoxInt (Fin 3))
check9BRed =
  let g2   = pythGeneratorTriple 2
      bst  = boostFromQuadraticTriple g2
      wB   = actMaxelR (rotorActionMaxel redMetric bst) (vec3Box 1 0 0)
      nB   = rotorNorm redMetric bst
      rA1  = boostRotorAxis1 3 1; rA2 = boostRotorAxis2 2 1
      mR1  = rotorActionMaxel redMetric rA2; mR2 = rotorActionMaxel redMetric rA1
      mR12 = rotorActionMaxel redMetric (composeRotor redMetric rA1 rA2)
      ok   = isQuadraticTriple g2 && (wB == vec3Box 90 54 0) &&
             (MkProportion (lookupBox (FS FZ) wB) (lookupBox FZ wB) == MkProportion 3 5) &&
             (spreadBetween redMetric (vec3Box 1 0 0) wB == MkProportion (-9) 16) &&
             (metricQuadrance redMetric wB == nB * nB) && (composeMaxel mR2 mR1 == mR12)
  in (ok, wB)

public export
check9BPrecessionAndFrame :
  (Box BoxInt (Fin 3), Box BoxInt (Fin 3), Integer, Box BoxInt (Fin 3), Box BoxInt (Fin 3), Integer) ->
  (Bool, Bool, Bool, Bool, BoxInt, BoxInt)
check9BPrecessionAndFrame (fRot, fRaw, fQ, hRot, hRaw, hQ) =
  let classes = map classifyRedRotor
                  [ spatialRotationRotor 2 1, boostRotorAxis1 2 1, parabolicNullRotor 3 2
                  , MkRotor 0 (vec3Box 1 0 0), MkRotor 1 (vec3Box 0 1 0) ]
      classOk = classes == [ EllipticSpatialRotation, HyperbolicLorentzBoost, ParabolicNullRotation
                           , InvolutionHalfTurn, SingularNullRotor ]
      p12 = composeRotor redMetric (boostRotorAxis1 3 1) (boostRotorAxis2 2 1)
      p21 = composeRotor redMetric (boostRotorAxis2 2 1) (boostRotorAxis1 3 1)
      t12 = lookupBox FZ p12.rotorBivector
      t21 = lookupBox FZ p21.rotorBivector
      wigOk = (t12 /= 0) && (t12 == negate t21)
      gi = toGeneralMaxel quatUnitI; gj = toGeneralMaxel quatUnitJ; gk = toGeneralMaxel quatUnitK
      mxlOk = (composeMaxel epsilonDihedronMaxel2 epsilonDihedronMaxel2 == emptyMaxel) &&
              (composeMaxel gi gj == gk) && isCanonicalMaxel quatUnitI
      nBlue = rotorNorm blueMetric observerRotor
      frmOk = (fRaw == hRaw) && (fRot == hRot) && (fQ == hQ) && (fRaw /= BoxLeaf) &&
              (metricQuadrance blueMetric fRot == nBlue * nBlue * metricQuadrance blueMetric fRaw)
  in (classOk, wigOk, mxlOk, frmOk, t12, t21)

export
runAudit9 : Has [Console] e => App e (Bool, List String)
runAudit9 = do
  (sVac, sDp)      <- app1 runDeflectionSpreads
  (fRot, fRaw, fQ) <- app1 runFlat3DFrame
  (hRot, hRaw, hQ) <- app1 runHereditary3DFrame
  let (chromoOk, twinOk, aB, aR, aG, aTw) = check9AChromo
      deflOk                              = isAffineRatio sVac && isAffineRatio sDp && isValidProportion sDp && not (sVac == sDp)
      blueOk                              = check9BBlue
      (boostOk, wB)                       = check9BRed
      (classOk, wigOk, mxlOk, frmOk, t12, t21) = check9BPrecessionAndFrame (fRot, fRaw, fQ, hRot, hRaw, hQ)
      nBlue                               = rotorNorm blueMetric observerRotor
      pass                                = chromoOk && twinOk && deflOk && blueOk && boostOk && classOk && wigOk && mxlOk && frmOk
      lines =
        [ "----------------------------------------------------------------"
        , "[Audit 9] Rational Chromogeometry, Relativistic Spread Law, Metric Rotors & Frame-Covariant Observation"
        , "  * 9-A Chromogeometry & Spread Law (A_b=" ++ show aB ++ ", A_r=" ++ show aR ++ ", A_g=" ++ show aG ++ "): ok=" ++ show chromoOk
        , "    - Minkowski Twin Triangle (0,0)->(5,3)->(10,0): Q=(16,16,100), A_red=" ++ show aTw ++
          " < 0, tau_out+tau_back=8 < 10, redSpreadLaw: ok=" ++ show twinOk
        , "    - Live Load Deflection Spread (18 sweeps): vac=" ++ show sVac ++ ", topDipole=" ++ show sDp ++ ": ok=" ++ show deflOk
        , "  * 9-B Metric Rotors (N_blue=" ++ show nBlue ++ ", boost(3,4,5)->" ++ show wB ++ ", beta=3/5): blue=" ++ show blueOk ++
          ", boost=" ++ show boostOk ++ ", classes=" ++ show classOk
        , "    - Wigner-Thomas precession t12=" ++ show t12 ++ ", t21=" ++ show t21 ++ ": ok=" ++ show wigOk ++
          ", eps^2=0 & D(x)D quaternions: ok=" ++ show mxlOk
        , "    - Frame-Covariant 3D Observation (Space 3 == PureMultiset): raw=" ++ show fRaw ++ ", rotated=" ++ show fRot ++
          ", Q=" ++ show fQ ++ ": ok=" ++ show frmOk
        , "  -> Audit 9 pass=" ++ show pass
        ]
  traverse_ putStrLn lines
  pure (pass, lines)
