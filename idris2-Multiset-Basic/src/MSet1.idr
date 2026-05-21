module MSet1

public export
data MSet1 : Type where
  Empty : MSet1
  Insert : MSet1 -> MSet1 -> MSet1

mutual
  export covering
  deleteFirst : MSet1 -> MSet1 -> Maybe MSet1
  deleteFirst _ Empty = Nothing
  deleteFirst a (Insert b bs) = if a == b then Just bs else
                                case deleteFirst a bs of
                                     Nothing => Nothing
                                     Just bs' => Just (Insert b bs')

  export covering
  Eq MSet1 where
    Empty == Empty = True
    Empty == Insert _ _ = False
    Insert _ _ == Empty = False
    (Insert a as) == b = case deleteFirst a b of
                              Nothing => False
                              Just b' => as == b'

mutual
  showMSet1 : MSet1 -> String
  showMSet1 Empty = "[]"
  showMSet1 (Insert x xs) = "[" ++ showList (Insert x xs) ++ "]"

  showList : MSet1 -> String
  showList Empty = ""
  showList (Insert x Empty) = showMSet1 x
  showList (Insert x (Insert y ys)) = showMSet1 x ++ " " ++ showList (Insert y ys)

export
Show MSet1 where
  show = showMSet1

export
zero : MSet1
zero = Empty

export
add : MSet1 -> MSet1 -> MSet1
add Empty b = b
add (Insert a as) b = Insert a (add as b)

export
mapMSet1 : (MSet1 -> MSet1) -> MSet1 -> MSet1
mapMSet1 f Empty = Empty
mapMSet1 f (Insert x xs) = Insert (f x) (mapMSet1 f xs)

export
concatMSet1 : MSet1 -> MSet1
concatMSet1 Empty = Empty
concatMSet1 (Insert x xs) = add x (concatMSet1 xs)

export
sigma : MSet1 -> MSet1
sigma = concatMSet1

export
mul : MSet1 -> MSet1 -> MSet1
mul a b = concatMSet1 (mapMSet1 (\x => mapMSet1 (\y => add x y) b) a)

export
carret : MSet1 -> MSet1 -> MSet1
carret a b = concatMSet1 (mapMSet1 (\x => mapMSet1 (\y => mul x y) b) a)

export
alphaPow : MSet1 -> MSet1
alphaPow x = Insert x Empty

export
fromList : List MSet1 -> MSet1
fromList [] = Empty
fromList (x::xs) = Insert x (fromList xs)

export
fromNat : Nat -> MSet1
fromNat Z = Empty
fromNat (S k) = Insert Empty (fromNat k)

export
fromInt : Integer -> MSet1
fromInt n = if n <= 0 then Empty else Insert Empty (fromInt (n - 1))

export
Num MSet1 where
  (+) = add
  (*) = mul
  fromInteger = fromInt

export
size : MSet1 -> Nat
size Empty = Z
size (Insert _ xs) = S (size xs)

export
truncate : Nat -> MSet1 -> MSet1
truncate k Empty = Empty
truncate k (Insert x xs) = 
  if size x <= k 
    then Insert x (truncate k xs)
    else truncate k xs
