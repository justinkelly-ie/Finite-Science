module FiniteScience.MultisetCodec

import Data.List
import Data.Nat
import Decidable.Equality
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet

%default total

--------------------------------------------------------------------------------
-- 1. TOTAL BASE-10 INTEGER RENDERING (COMPILE-TIME & RUNTIME CONSISTENT)
--------------------------------------------------------------------------------

||| Renders a single base-10 digit (0..9) to its ASCII Char.
public export
digitToChar : Nat -> Char
digitToChar 0 = '0'
digitToChar 1 = '1'
digitToChar 2 = '2'
digitToChar 3 = '3'
digitToChar 4 = '4'
digitToChar 5 = '5'
digitToChar 6 = '6'
digitToChar 7 = '7'
digitToChar 8 = '8'
digitToChar 9 = '9'
digitToChar _ = '?'

||| Total fueled quotient/remainder by 10 without primitives (`assert_total`-free).
public export
divMod10Fuel : Nat -> Nat -> Nat -> (Nat, Nat)
divMod10Fuel Z     q r = (q, r)
divMod10Fuel (S f) q r =
  if r < 10
    then (q, r)
    else divMod10Fuel f (S q) (minus r 10)

||| Total fueled positive `Nat` to base-10 `List Char`.
public export
natToCharsFuel : Nat -> Nat -> List Char -> List Char
natToCharsFuel Z     _ acc = acc
natToCharsFuel (S f) n acc =
  if n < 10
    then digitToChar n :: acc
    else let (q, r) = divMod10Fuel (S n) 0 n
         in natToCharsFuel f q (digitToChar r :: acc)

||| Renders an `Integer` in base 10 matching `Show Integer`.
public export
renderInteger : Integer -> String
renderInteger n =
  if n == 0
    then "0"
    else if n < 0
      then let k = integerToNat (-n)
           in pack ('-' :: natToCharsFuel (S k) k [])
      else let k = integerToNat n
           in pack (natToCharsFuel (S k) k [])

--------------------------------------------------------------------------------
-- 2. CANONICAL MULTISET RENDERER (EXACT PARITY WITH `Stage0.HereditaryMSet.show`)
--------------------------------------------------------------------------------

mutual
  ||| Renders a list of `(PureMultiset, BoxInt)` entries inside `{...}`.
  public export
  renderPureEntries : Nat -> List (PureMultiset, BoxInt) -> String
  renderPureEntries _ [] = ""
  renderPureEntries rem [(k, w)] =
    renderPureFuel rem k ++ ":[" ++ renderInteger (unwrapBox w) ++ "]"
  renderPureEntries rem ((k, w) :: rest) =
    renderPureFuel rem k ++ ":[" ++ renderInteger (unwrapBox w) ++ "], " ++ renderPureEntries rem rest

  ||| Renders a `PureMultiset` recursively bounded by fuel `rem`.
  public export
  renderPureFuel : Nat -> PureMultiset -> String
  renderPureFuel _ (MkHMSet BoxLeaf) = "[]"
  renderPureFuel Z _                 = "[...]"
  renderPureFuel (S rem) (MkHMSet b) =
    "{" ++ renderPureEntries rem (toAscListBox b) ++ "}"

||| Canonical total renderer producing identical text to `Stage0.HereditaryMSet.show`.
public export
renderPureMultiset : PureMultiset -> String
renderPureMultiset m = renderPureFuel (hmDepth m) m

--------------------------------------------------------------------------------
-- 3. TOTAL FUELED PARSER OVER `List Char`
--------------------------------------------------------------------------------

||| Parses a single ASCII digit `0..9`.
public export
charToDigit : Char -> Maybe Nat
charToDigit '0' = Just 0
charToDigit '1' = Just 1
charToDigit '2' = Just 2
charToDigit '3' = Just 3
charToDigit '4' = Just 4
charToDigit '5' = Just 5
charToDigit '6' = Just 6
charToDigit '7' = Just 7
charToDigit '8' = Just 8
charToDigit '9' = Just 9
charToDigit _   = Nothing

public export
skipSpaces : List Char -> List Char
skipSpaces (' ' :: cs) = skipSpaces cs
skipSpaces cs          = cs

public export
digitToInteger : Nat -> Integer
digitToInteger 0 = 0
digitToInteger 1 = 1
digitToInteger 2 = 2
digitToInteger 3 = 3
digitToInteger 4 = 4
digitToInteger 5 = 5
digitToInteger 6 = 6
digitToInteger 7 = 7
digitToInteger 8 = 8
digitToInteger 9 = 9
digitToInteger _ = 0

public export
parseDigitsAcc : Nat -> Integer -> Bool -> List Char -> Maybe (Integer, List Char)
parseDigitsAcc Z     acc hasDig cs = if hasDig then Just (acc, cs) else Nothing
parseDigitsAcc (S f) acc hasDig [] = if hasDig then Just (acc, []) else Nothing
parseDigitsAcc (S f) acc hasDig (c :: cs) =
  case charToDigit c of
    Just d  => parseDigitsAcc f (acc * 10 + digitToInteger d) True cs
    Nothing => if hasDig then Just (acc, c :: cs) else Nothing

public export
parseSignedInteger : Nat -> List Char -> Maybe (Integer, List Char)
parseSignedInteger fuel ('-' :: cs) =
  case parseDigitsAcc fuel 0 False cs of
    Just (mag, rest) => Just (-mag, rest)
    Nothing          => Nothing
parseSignedInteger fuel cs = parseDigitsAcc fuel 0 False cs

public export
parseBracketWeight : Nat -> List Char -> Maybe (BoxInt, List Char)
parseBracketWeight fuel ('[' :: cs) =
  case parseSignedInteger fuel (skipSpaces cs) of
    Just (v, rest1) =>
      case skipSpaces rest1 of
        (']' :: rest2) => Just (intToBoxInt v, rest2)
        _               => Nothing
    Nothing => Nothing
parseBracketWeight _ _ = Nothing

mutual
  public export
  parseEntriesFuel : Nat -> PureMultiset -> List Char -> Maybe (PureMultiset, List Char)
  parseEntriesFuel Z _ _ = Nothing
  parseEntriesFuel (S fuel) acc cs =
    case skipSpaces cs of
      ('}' :: rest) => Just (acc, rest)
      other =>
        case parseMSetFuel fuel other of
          Just (keyM, rest1) =>
            case skipSpaces rest1 of
              (':' :: rest2) =>
                case parseBracketWeight fuel (skipSpaces rest2) of
                  Just (w, rest3) =>
                    let (MkHMSet boxAcc) = acc
                        nextAcc = MkHMSet (addAtKeyBox keyM w boxAcc)
                    in case skipSpaces rest3 of
                         (',' :: more) => parseEntriesFuel fuel nextAcc more
                         ('}' :: rest4) => Just (nextAcc, rest4)
                         _ => Nothing
                  Nothing => Nothing
              _ => Nothing
          Nothing => Nothing

  public export
  parseMSetFuel : Nat -> List Char -> Maybe (PureMultiset, List Char)
  parseMSetFuel Z _ = Nothing
  parseMSetFuel (S fuel) cs =
    case skipSpaces cs of
      ('[' :: rest) =>
        case skipSpaces rest of
          (']' :: more) => Just (emptyPureMSet, more)
          _             => Nothing
      ('{' :: rest) =>
        case skipSpaces rest of
          ('}' :: more) => Just (emptyPureMSet, more)
          other         => parseEntriesFuel fuel emptyPureMSet other
      _ => Nothing

||| Parses canonical `Show` / `renderPureMultiset` text into a `PureMultiset`.
||| All keys are consolidated via `addAtKeyBox` so AVL ordering and zero-pruning are enforced.
public export
parsePureMultiset : String -> Maybe PureMultiset
parsePureMultiset s =
  let chars = unpack s
  in case parseMSetFuel (S (length chars)) chars of
       Just (m, rest) =>
         case skipSpaces rest of
           [] => Just m
           _  => Nothing
       Nothing => Nothing

--------------------------------------------------------------------------------
-- 4. CONSTRUCTIVIST `Dec` RECOGNIZER (`recognition-rule.md`)
--------------------------------------------------------------------------------

public export
isValidPureMultisetText : String -> Bool
isValidPureMultisetText s =
  case parsePureMultiset s of
    Just _  => True
    Nothing => False

public export
IsValidPureMultisetText : String -> Type
IsValidPureMultisetText s = (isValidPureMultisetText s = True)

||| Total constructivist `Dec` recognizer certifying a settings string parses cleanly.
public export
recognizePureMultisetText : (s : String) -> Dec (IsValidPureMultisetText s)
recognizePureMultisetText s = decideBoolTrue (isValidPureMultisetText s)

||| Decodes serialized multiset text and certifies recursive AVL canonical invariants.
public export
decodeCanonicalMultiset : (s : String) -> Maybe (Subset PureMultiset IsCanonicalHMSet)
decodeCanonicalMultiset s =
  case parsePureMultiset s of
    Nothing => Nothing
    Just m  => toCanonicalHMSet m

--------------------------------------------------------------------------------
-- 5. COMPILE-TIME QTT 0 CODEC ROUND-TRIP PROOFS
--------------------------------------------------------------------------------

public export
0 prfRenderEmpty :
  FiniteScience.MultisetCodec.renderPureMultiset Stage0.HereditaryMSet.emptyPureMSet = "[]"
prfRenderEmpty = Refl

public export
0 prfCodecRoundTripVacuum :
  (case FiniteScience.MultisetCodec.parsePureMultiset
          (FiniteScience.MultisetCodec.renderPureMultiset Stage0.HereditaryMSet.emptyPureMSet) of
     Just m  => m == Stage0.HereditaryMSet.emptyPureMSet
     Nothing => False) = True
prfCodecRoundTripVacuum = Refl

public export
0 prfCodecRoundTripBlack1 :
  (let b1 = Stage0.HereditaryMSet.scalarKeyHMSet 1
   in case FiniteScience.MultisetCodec.parsePureMultiset
             (FiniteScience.MultisetCodec.renderPureMultiset b1) of
        Just m  => m == b1
        Nothing => False) = True
prfCodecRoundTripBlack1 = Refl

public export
0 prfCodecRoundTripNeg1 :
  (let r1 = Stage0.HereditaryMSet.scalarKeyHMSet (-1)
   in case FiniteScience.MultisetCodec.parsePureMultiset
             (FiniteScience.MultisetCodec.renderPureMultiset r1) of
        Just m  => m == r1
        Nothing => False) = True
prfCodecRoundTripNeg1 = Refl
