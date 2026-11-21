module FiniteScience.Experiments

import Control.App
import Control.App.Console
import Data.DPair
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.HereditaryMSet
import FiniteScience.MultisetCodec
import FiniteScience.BlackRedZoom
import FiniteScience.ComputeKernel
import FiniteScience.Settings
import FiniteScience.LinearUniverse

%default total

--------------------------------------------------------------------------------
-- EXPERIMENT 1: SERIALIZED SETTINGS CODEC PARITY & BLACK/RED ZOOM LAWS
--------------------------------------------------------------------------------

export
runExperiment1 : Has [Console] e => App e Bool
runExperiment1 = do
  putStrLn "----------------------------------------------------------------"
  putStrLn "[Experiment 1] Serialized Multiset Settings & Black/Red Zoom"
  let presets : List (String, String, PureMultiset)
      presets = [ ("Vacuum",        vacuumSettingText,        vacuumMSet)
                , ("Photon",        photonSettingText,        photonMSet)
                , ("Proton",        protonSettingText,        protonMSet)
                , ("Neutron",       neutronSettingText,       neutronMSet)
                , ("HeavyMass",     heavyMassSettingText,     heavyMassMSet)
                , ("LightObserver", lightObserverSettingText, lightObserverMSet)
                , ("HeavyObserver", heavyObserverSettingText, heavyObserverMSet)
                ]
  let parityOk =
        all (\(_, txt, m) =>
               show m == renderPureMultiset m &&
               renderPureMultiset m == txt &&
               (case parsePureMultiset (show m) of
                  Just m' => m' == m
                  Nothing => False))
            presets
  let shiftAnnihilated = addHMSet (blackShift 1) (redShift 1)
  let timeZoomOk =
        (zoomTime (redShift 1) (zoomTime (blackShift 1) photonMSet) == photonMSet) &&
        (zoomTime shiftAnnihilated photonMSet == photonMSet)
  let spaceZoomOk =
        (zoomSpace (redShift 1) (zoomSpace (blackShift 1) protonMSet) == protonMSet) &&
        (zoomSpace shiftAnnihilated protonMSet == protonMSet)
  putStrLn ("  * Settings Show == renderPureMultiset == settingText & round-trip: " ++ show parityOk)
  putStrLn ("  * ZoomTime  (Black + Red = [] & round-trip): " ++ show timeZoomOk)
  putStrLn ("  * ZoomSpace (Black + Red = [] & round-trip): " ++ show spaceZoomOk)
  let pass = parityOk && timeZoomOk && spaceZoomOk
  putStrLn ("  -> Experiment 1 pass=" ++ show pass)
  pure pass

--------------------------------------------------------------------------------
-- EXPERIMENT 2: 0D VACUUM ROOT -> SINGLE NESTED `PureMultiset` UNIVERSE (`App1`)
--------------------------------------------------------------------------------

export
runExperiment2 : Has [Console] e => App e Bool
runExperiment2 = do
  putStrLn "----------------------------------------------------------------"
  putStrLn "[Experiment 2] App1 0D Vacuum Expansion -> Single Nested PureMultiset"
  snap <- app1 $ App1.do
    u0 <- bootUniverse
    u1 <- loadSettingIntoUniverse roleMatter   (5, 0, 0)  protonSettingText u0
    u2 <- loadSettingIntoUniverse roleMatter   (12, 0, 0) heavyMassSettingText u1
    u3 <- loadSettingIntoUniverse roleObserver (0, 0, 0)  lightObserverSettingText u2
    u4 <- zoomUniverseTime  (blackShift 1) u3
    u5 <- zoomUniverseTime  (redShift 1)   u4
    u6 <- zoomUniverseSpace (blackShift 1) u5
    u7 <- zoomUniverseSpace (redShift 1)   u6
    freezeUniverse u7
  let parseBackOk =
        case decodeCanonicalMultiset snap.canonicalText of
          Just (Element m _) => isCanonicalHMSet m
          Nothing            => False
  let showParity = snap.serializedShow == snap.canonicalText
  let nonEmpty   = snap.elapsedTicks > 0 && snap.universeMetrics.supportNodes == 3
  putStrLn ("  * Snapshot: " ++ show snap)
  putStrLn ("  * Root Show == canonicalText: " ++ show showParity ++ ", canonical AVL re-parse: " ++ show parseBackOk)
  let pass = parseBackOk && showParity && nonEmpty
  putStrLn ("  -> Experiment 2 pass=" ++ show pass)
  pure pass

--------------------------------------------------------------------------------
-- EXPERIMENT 3: PHOTON-MEDIATED OBSERVATION & OBSERVER COMPUTE LAG
--------------------------------------------------------------------------------

export
runExperiment3 : Has [Console] e => App e Bool
runExperiment3 = do
  putStrLn "----------------------------------------------------------------"
  putStrLn "[Experiment 3] Observer Photon Lag Impacting Universe Time (`App1`)"
  let probeWith : String -> Has [Console] e => App e (UniverseSnapshot, ObservationReceipt)
      probeWith observerText = app1 $ App1.do
        u0 <- bootUniverse
        u1 <- loadSettingIntoUniverse roleMatter   (5, 0, 0) protonSettingText u0
        u2 <- loadSettingIntoUniverse roleObserver (0, 0, 0) observerText      u1
        res1 <- observeViaPhoton (5, 0, 0) u2
        let MkLinRes u3 receipt = res1
        snap <- freezeUniverse u3
        App1.pure (snap, receipt)
  (lightSnap, lightRec) <- probeWith lightObserverSettingText
  (heavySnap, heavyRec) <- probeWith heavyObserverSettingText
  let horizon : Nat
      horizon = 200
  let lightRemaining = minus horizon lightSnap.elapsedTicks
  let heavyRemaining = minus horizon heavySnap.elapsedTicks
  putStrLn ("  * Light Observer Receipt : " ++ show lightRec)
  putStrLn ("  * Light Observer Snap    : " ++ show lightSnap ++ " (remaining budget in 200 ticks: " ++ show lightRemaining ++ ")")
  putStrLn ("  * Heavy Observer Receipt : " ++ show heavyRec)
  putStrLn ("  * Heavy Observer Snap    : " ++ show heavySnap ++ " (remaining budget in 200 ticks: " ++ show heavyRemaining ++ ")")
  let lagStrict   = heavyRec.observerLagTicks > lightRec.observerLagTicks
  let timeStrict  = heavySnap.elapsedTicks > lightSnap.elapsedTicks
  let recoilBoth  = lightRec.targetPerturbed && heavyRec.targetPerturbed
  let horizonImpact = lightRemaining > heavyRemaining
  let pass = lagStrict && timeStrict && recoilBoth && horizonImpact
  putStrLn ("  -> Experiment 3 pass=" ++ show pass)
  pure pass

--------------------------------------------------------------------------------
-- EXPERIMENT 4: MASS, TIME DILATION & EMERGENT GRAVITY FROM COMPUTE LATENCY
--------------------------------------------------------------------------------

export
runExperiment4 : Has [Console] e => App e Bool
runExperiment4 = do
  putStrLn "----------------------------------------------------------------"
  putStrLn "[Experiment 4] Emergent Mass & Gravity From Compute-Latency Gradient"
  let lVac   = computeLatencyOf vacuumMSet
  let lPhot  = computeLatencyOf photonMSet
  let lProt  = computeLatencyOf protonMSet
  let lHeavy = computeLatencyOf heavyMassMSet
  putStrLn ("  * Intrinsic Latency Table -> Vacuum=" ++ show lVac ++
            ", Photon=" ++ show lPhot ++
            ", Proton=" ++ show lProt ++
            ", HeavyMass=" ++ show lHeavy)
  let latencyOrdered = lVac < lPhot && lPhot < lProt && lProt < lHeavy

  -- 6-step free fall of a Proton from (4,0,0) toward a Heavy Mass at (10,0,0)
  (fallSnap, reports) <- app1 $ App1.do
    u0 <- bootUniverse
    u1 <- loadSettingIntoUniverse roleMatter (10, 0, 0) heavyMassSettingText u0
    u2 <- loadSettingIntoUniverse roleMatter (4, 0, 0)  protonSettingText u1
    s1 <- stepGravityComputeLag (4, 0, 0) u2
    let MkLinRes u3 r1 = s1
    s2 <- stepGravityComputeLag r1.toPos u3
    let MkLinRes u4 r2 = s2
    s3 <- stepGravityComputeLag r2.toPos u4
    let MkLinRes u5 r3 = s3
    s4 <- stepGravityComputeLag r3.toPos u5
    let MkLinRes u6 r4 = s4
    s5 <- stepGravityComputeLag r4.toPos u6
    let MkLinRes u7 r5 = s5
    s6 <- stepGravityComputeLag r5.toPos u7
    let MkLinRes u8 r6 = s6
    snap <- freezeUniverse u8
    App1.pure (snap, [r1, r2, r3, r4, r5, r6])

  traverse_ (\r => putStrLn ("    - " ++ show r)) reports
  let monotonicRise = all (\r => gtFrac r.fieldAfter r.fieldBefore) reports
  let reachedTarget = case reports of
                        [_, _, _, _, _, r6] => r6.toPos == (10, 0, 0)
                        _ => False

  -- Lagrange saddle equilibrium at (5,0,0) between Heavy Masses at (0,0,0) and (10,0,0)
  lagReport <- app1 $ App1.do
    u0 <- bootUniverse
    u1 <- loadSettingIntoUniverse roleMatter (0, 0, 0)  heavyMassSettingText u0
    u2 <- loadSettingIntoUniverse roleMatter (10, 0, 0) heavyMassSettingText u1
    u3 <- loadSettingIntoUniverse roleMatter (5, 0, 0)  protonSettingText u2
    sEq <- stepGravityComputeLag (5, 0, 0) u3
    let MkLinRes u4 repEq = sEq
    _ <- freezeUniverse u4
    App1.pure repEq

  putStrLn ("  * Balanced Lagrange Probe: " ++ show lagReport)
  putStrLn ("  * Free-Fall Final Snap   : " ++ show fallSnap)
  let lagrangeZero = lagReport.fromPos == (5, 0, 0) && lagReport.toPos == (5, 0, 0)
  let pass = latencyOrdered && monotonicRise && reachedTarget && lagrangeZero
  putStrLn ("  -> Experiment 4 pass=" ++ show pass)
  pure pass
