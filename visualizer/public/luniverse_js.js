class IdrisError extends Error { }

function __prim_js2idris_array(x){
  let acc = { h:0 };

  for (let i = x.length-1; i>=0; i--) {
      acc = { a1:x[i], a2:acc };
  }
  return acc;
}

function __prim_idris2js_array(x){
  const result = Array();
  while (x.h === undefined) {
    result.push(x.a1); x = x.a2;
  }
  return result;
}

function __lazy(thunk) {
  let res;
  return function () {
    if (thunk === undefined) return res;
    res = thunk();
    thunk = undefined;
    return res;
  };
};

function __prim_stringIteratorNew(_str) {
  return 0
}

function __prim_stringIteratorToString(_, str, it, f) {
  return f(str.slice(it))
}

function __prim_stringIteratorNext(str, it) {
  if (it >= str.length)
    return {h: 0};
  else
    return {a1: str.charAt(it), a2: it + 1};
}

function __tailRec(f,ini) {
  let obj = ini;
  while(true){
    switch(obj.h){
      case 0: return obj.a1;
      default: obj = f(obj);
    }
  }
}

const _idrisworld = Symbol('idrisworld')

const _crashExp = x=>{throw new IdrisError(x)}

const _bigIntOfString = s=> {
  try {
    const idx = s.indexOf('.')
    return idx === -1 ? BigInt(s) : BigInt(s.slice(0, idx))
  } catch (e) { return 0n }
}

const _numberOfString = s=> {
  try {
    const res = Number(s);
    return isNaN(res) ? 0 : res;
  } catch (e) { return 0 }
}

const _intOfString = s=> Math.trunc(_numberOfString(s))

const _truncToChar = x=> String.fromCodePoint(
  (x >= 0 && x <= 55295) || (x >= 57344 && x <= 1114111) ? x : 0
)

// Int8
const _truncInt8 = x => {
  const res = x & 0xff;
  return res >= 0x80 ? res - 0x100 : res;
}

const _truncBigInt8 = x => Number(BigInt.asIntN(8, x))

// Euclidian Division
const _div = (a,b) => {
  const q = Math.trunc(a / b)
  const r = a % b
  return r < 0 ? (b > 0 ? q - 1 : q + 1) : q
}

const _divBigInt = (a,b) => {
  const q = a / b
  const r = a % b
  return r < 0n ? (b > 0n ? q - 1n : q + 1n) : q
}

// Euclidian Modulo
const _mod = (a,b) => {
  const r = a % b
  return r < 0 ? (b > 0 ? r + b : r - b) : r
}

const _modBigInt = (a,b) => {
  const r = a % b
  return r < 0n ? (b > 0n ? r + b : r - b) : r
}

const _add8s = (a,b) => _truncInt8(a + b)
const _sub8s = (a,b) => _truncInt8(a - b)
const _mul8s = (a,b) => _truncInt8(a * b)
const _div8s = (a,b) => _truncInt8(_div(a,b))
const _shl8s = (a,b) => _truncInt8(a << b)
const _shr8s = (a,b) => _truncInt8(a >> b)

// Int16
const _truncInt16 = x => {
  const res = x & 0xffff;
  return res >= 0x8000 ? res - 0x10000 : res;
}

const _truncBigInt16 = x => Number(BigInt.asIntN(16, x))

const _add16s = (a,b) => _truncInt16(a + b)
const _sub16s = (a,b) => _truncInt16(a - b)
const _mul16s = (a,b) => _truncInt16(a * b)
const _div16s = (a,b) => _truncInt16(_div(a,b))
const _shl16s = (a,b) => _truncInt16(a << b)
const _shr16s = (a,b) => _truncInt16(a >> b)

//Int32
const _truncInt32 = x => x & 0xffffffff

const _truncBigInt32 = x => Number(BigInt.asIntN(32, x))

const _add32s = (a,b) => _truncInt32(a + b)
const _sub32s = (a,b) => _truncInt32(a - b)
const _div32s = (a,b) => _truncInt32(_div(a,b))

const _mul32s = (a,b) => {
  const res = a * b;
  if (res <= Number.MIN_SAFE_INTEGER || res >= Number.MAX_SAFE_INTEGER) {
    return _truncInt32((a & 0xffff) * b + (b & 0xffff) * (a & 0xffff0000))
  } else {
    return _truncInt32(res)
  }
}

//Int64
const _truncBigInt64 = x => BigInt.asIntN(64, x)

const _add64s = (a,b) => _truncBigInt64(a + b)
const _sub64s = (a,b) => _truncBigInt64(a - b)
const _mul64s = (a,b) => _truncBigInt64(a * b)
const _shl64s = (a,b) => _truncBigInt64(a << b)
const _div64s = (a,b) => _truncBigInt64(_divBigInt(a,b))
const _shr64s = (a,b) => _truncBigInt64(a >> b)

//Bits8
const _truncUInt8 = x => x & 0xff

const _truncUBigInt8 = x => Number(BigInt.asUintN(8, x))

const _add8u = (a,b) => (a + b) & 0xff
const _sub8u = (a,b) => (a - b) & 0xff
const _mul8u = (a,b) => (a * b) & 0xff
const _div8u = (a,b) => Math.trunc(a / b)
const _shl8u = (a,b) => (a << b) & 0xff
const _shr8u = (a,b) => (a >> b) & 0xff

//Bits16
const _truncUInt16 = x => x & 0xffff

const _truncUBigInt16 = x => Number(BigInt.asUintN(16, x))

const _add16u = (a,b) => (a + b) & 0xffff
const _sub16u = (a,b) => (a - b) & 0xffff
const _mul16u = (a,b) => (a * b) & 0xffff
const _div16u = (a,b) => Math.trunc(a / b)
const _shl16u = (a,b) => (a << b) & 0xffff
const _shr16u = (a,b) => (a >> b) & 0xffff

//Bits32
const _truncUBigInt32 = x => Number(BigInt.asUintN(32, x))

const _truncUInt32 = x => {
  const res = x & -1;
  return res < 0 ? res + 0x100000000 : res;
}

const _add32u = (a,b) => _truncUInt32(a + b)
const _sub32u = (a,b) => _truncUInt32(a - b)
const _mul32u = (a,b) => _truncUInt32(_mul32s(a,b))
const _div32u = (a,b) => Math.trunc(a / b)

const _shl32u = (a,b) => _truncUInt32(a << b)
const _shr32u = (a,b) => _truncUInt32(a <= 0x7fffffff ? a >> b : (b == 0 ? a : (a >> b) ^ ((-0x80000000) >> (b-1))))
const _and32u = (a,b) => _truncUInt32(a & b)
const _or32u = (a,b)  => _truncUInt32(a | b)
const _xor32u = (a,b) => _truncUInt32(a ^ b)

//Bits64
const _truncUBigInt64 = x => BigInt.asUintN(64, x)

const _add64u = (a,b) => BigInt.asUintN(64, a + b)
const _mul64u = (a,b) => BigInt.asUintN(64, a * b)
const _div64u = (a,b) => a / b
const _shl64u = (a,b) => BigInt.asUintN(64, a << b)
const _shr64u = (a,b) => BigInt.asUintN(64, a >> b)
const _sub64u = (a,b) => BigInt.asUintN(64, a - b)

//String
const _strReverse = x => x.split('').reverse().join('')

const _substr = (o,l,x) => x.slice(o, o + l)

const JSBridge_prim_exportFunction4 = ((name, fn) => { globalThis[name] = fn; });
const JSBridge_prim_exportFunction = ((name, fn) => { globalThis[name] = fn; });
const Prelude_Types_fastUnpack = ((str)=>__prim_js2idris_array(Array.from(str)));
const Prelude_Types_fastPack = ((xs)=>__prim_idris2js_array(xs).join(''));
const Prelude_IO_prim__putStr = (x=>console.log(x));
/* {$tcOpt:1} */
function x24tcOpt_1($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:1} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue1:1} */, a1: $0.a1, a2: $0.a1($0.a2)($0.a3.a1), a3: $0.a3.a2};
 }
}

/* Prelude.Types.foldl */
function Prelude_Types_foldl_Foldable_List($0, $1, $2) {
 return __tailRec(x24tcOpt_1, {h: 1 /* {TcContinue1:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:2} */
function x24tcOpt_2($0) {
 switch($0.a1.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:2} */, a1: {a1: $0.a2}};
  case undefined: /* cons */ {
   let $5;
   switch(Prelude_EqOrd_x3ex3d_Ord_Char($0.a1.a1, '0')) {
    case 1: {
     $5 = Prelude_EqOrd_x3cx3d_Ord_Char($0.a1.a1, '9');
     break;
    }
    case 0: {
     $5 = 0;
     break;
    }
   }
   switch($5) {
    case 1: return {h: 1 /* {TcContinue2:1} */, a1: $0.a1.a2, a2: (($0.a2*10n)+BigInt(_sub32s(_truncInt32($0.a1.a1.codePointAt(0)), _truncInt32('0'.codePointAt(0)))))};
    case 0: return {h: 0 /* {TcDone:2} */, a1: {h: 0}};
   }
  }
 }
}

/* Data.String.parseNumWithoutSign : List Char -> Integer -> Maybe Integer */
function Data_String_parseNumWithoutSign($0, $1) {
 return __tailRec(x24tcOpt_2, {h: 1 /* {TcContinue2:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:3} */
function x24tcOpt_3($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ {
   const $3 = $0.a2($0.a3.a1);
   switch($3.h) {
    case undefined: /* just */ return {h: 1 /* {TcContinue3:1} */, a1: {a1: $0.a1, a2: $3.a1}, a2: $0.a2, a3: $0.a3.a2};
    case 0: /* nothing */ return {h: 1 /* {TcContinue3:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
  case 0: /* nil */ return {h: 0 /* {TcDone:3} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapMaybeAppend : SnocList b -> (a -> Maybe b) -> List a -> List b */
function Prelude_Types_List_mapMaybeAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_3, {h: 1 /* {TcContinue3:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:4} */
function x24tcOpt_4($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ return {h: 1 /* {TcContinue4:1} */, a1: {a1: $0.a1, a2: $0.a2($0.a3.a1)}, a2: $0.a2, a3: $0.a3.a2};
  case 0: /* nil */ return {h: 0 /* {TcDone:4} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapAppend : SnocList b -> (a -> b) -> List a -> List b */
function Prelude_Types_List_mapAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_4, {h: 1 /* {TcContinue4:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:5} */
function x24tcOpt_5($0) {
 switch($0.a1) {
  case '': {
   switch($0.a2.h) {
    case 0: /* Nil */ return {h: 0 /* {TcDone:5} */, a1: ''};
    default: {
     const $6 = ($0.a2.a1+$0.a2.a2);
     switch(Prelude_Types_isSpace($0.a2.a1)) {
      case 1: return {h: 1 /* {TcContinue5:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
      case 0: return {h: 0 /* {TcDone:5} */, a1: $6};
     }
    }
   }
  }
  default: {
   const $11 = ($0.a2.a1+$0.a2.a2);
   switch(Prelude_Types_isSpace($0.a2.a1)) {
    case 1: return {h: 1 /* {TcContinue5:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
    case 0: return {h: 0 /* {TcDone:5} */, a1: $11};
   }
  }
 }
}

/* Data.String.with block in ltrim */
function Data_String_with__ltrim_9864($0, $1) {
 return __tailRec(x24tcOpt_5, {h: 1 /* {TcContinue5:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:6} */
function x24tcOpt_6($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:6} */, a1: Prelude_Types_List_reverse($0.a2)};
  case undefined: /* cons */ return {h: 1 /* {TcContinue6:1} */, a1: $0.a1, a2: Prelude_Types_List_reverseOnto($0.a2, $0.a1($0.a3.a1)), a3: $0.a3.a2};
 }
}

/* Prelude.Types.listBindOnto : (a -> List b) -> List b -> List a -> List b */
function Prelude_Types_listBindOnto($0, $1, $2) {
 return __tailRec(x24tcOpt_6, {h: 1 /* {TcContinue6:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:7} */
function x24tcOpt_7($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:7} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue7:1} */, a1: {a1: $0.a2.a1, a2: $0.a1}, a2: $0.a2.a2};
 }
}

/* Prelude.Types.List.reverseOnto : List a -> List a -> List a */
function Prelude_Types_List_reverseOnto($0, $1) {
 return __tailRec(x24tcOpt_7, {h: 1 /* {TcContinue7:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:8} */
function x24tcOpt_8($0) {
 switch($0.a1.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:8} */, a1: $0.a1.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue8:1} */, a1: $0.a1.a2};
 }
}

/* Data.List.last : (l : List a) -> {auto 0 _ : NonEmpty l} -> a */
function Data_List_last($0) {
 return __tailRec(x24tcOpt_8, {h: 1 /* {TcContinue8:1} */, a1: $0});
}

/* {$tcOpt:9} */
function x24tcOpt_9($0) {
 switch($0.a2) {
  case 0n: return {h: 0 /* {TcDone:9} */, a1: Prelude_Num_abs_Abs_Integer($0.a1)};
  default: return {h: 1 /* {TcContinue9:1} */, a1: $0.a2, a2: Prelude_Num_mod_Integral_Integer($0.a1, $0.a2)};
 }
}

/* Simplex.Twist.gcd : Integer -> Integer -> Integer */
function Simplex_Twist_gcd($0, $1) {
 return __tailRec(x24tcOpt_9, {h: 1 /* {TcContinue9:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:10} */
function x24tcOpt_10($0) {
 switch($0.a2.h) {
  case 0: /* LEmptyM */ return {h: 0 /* {TcDone:10} */, a1: $0.a1};
  case 1: /* LAddM */ return {h: 1 /* {TcContinue10:1} */, a1: {a1: {a1: $0.a2.a1, a2: $0.a2.a2}, a2: $0.a1}, a2: $0.a2.a3};
 }
}

/* SigmaBridge.freezeLDepAcc : List (a, Integer) -> (1 _ : LDepMultiset a c) -> List (a, Integer) */
function SigmaBridge_freezeLDepAcc($0, $1) {
 return __tailRec(x24tcOpt_10, {h: 1 /* {TcContinue10:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:11} */
function x24tcOpt_11($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ {
   switch($0.a2($0.a3.a1)) {
    case 1: return {h: 1 /* {TcContinue11:1} */, a1: {a1: $0.a1, a2: $0.a3.a1}, a2: $0.a2, a3: $0.a3.a2};
    case 0: return {h: 1 /* {TcContinue11:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
  case 0: /* nil */ return {h: 0 /* {TcDone:11} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.filterAppend : SnocList a -> (a -> Bool) -> List a -> List a */
function Prelude_Types_List_filterAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_11, {h: 1 /* {TcContinue11:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:12} */
function x24tcOpt_12($0) {
 switch($0.a4.h) {
  case 0: /* ZeroM */ return {h: 0 /* {TcDone:12} */, a1: $0.a3};
  case 1: /* AddM */ return {h: 1 /* {TcContinue12:1} */, a1: $0.a1, a2: $0.a2, a3: Math_Multiset_insertItem($0.a1, $0.a4.a1, $0.a4.a2, $0.a3), a4: $0.a4.a3};
 }
}

/* Math.Multiset.3641:1260:go */
function Math_Multiset_n__3641_1260_go($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_12, {h: 1 /* {TcContinue12:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* {$tcOpt:13} */
function x24tcOpt_13($0) {
 switch($0.a1.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:13} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue13:1} */, a1: $0.a1.a1, a2: {a1: $0.a1.a2, a2: $0.a2}};
 }
}

/* Prelude.Types.SnocList.(<>>) : SnocList a -> List a -> List a */
function Prelude_Types_SnocList_x3cx3ex3e($0, $1) {
 return __tailRec(x24tcOpt_13, {h: 1 /* {TcContinue13:1} */, a1: $0, a2: $1});
}

/* {__mainExpression:0} */
function __mainExpression_0() {
 return PrimIO_unsafePerformIO($2 => JSBridge_main($2));
}

/* {csegen:0} */
const csegen_0 = __lazy(function () {
 return c => Prelude_EqOrd_x3dx3d_Eq_Char(c, ',');
});

/* {csegen:1} */
const csegen_1 = __lazy(function () {
 return c => Prelude_EqOrd_x3dx3d_Eq_Char(c, ';');
});

/* {csegen:4} */
const csegen_4 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_Integer($1, $2), a2: $7 => $8 => Prelude_EqOrd_x2fx3d_Eq_Integer($7, $8)};
});

/* {csegen:7} */
const csegen_7 = __lazy(function () {
 return {a1: $1 => $2 => Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $1, $2), a2: $9 => $a => Math_Pixel_x2fx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $9, $a)};
});

/* {csegen:10} */
const csegen_10 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_7(), csegen_7(), $1, $2), a2: $b => $c => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_7(), csegen_7(), $b, $c)};
});

/* {csegen:13} */
const csegen_13 = __lazy(function () {
 return {a1: $1 => $2 => (($1===$2)?1:0), a2: $6 => $7 => Prelude_Types_x2fx3d_Eq_Nat($6, $7)};
});

/* {csegen:16} */
const csegen_16 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_13(), csegen_13(), $1, $2), a2: $b => $c => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_13(), csegen_13(), $b, $c)};
});

/* {csegen:19} */
const csegen_19 = __lazy(function () {
 return {a1: $1 => $2 => Math_Multiset_x3dx3d_Eq_x28Multisetx20x24ax29(csegen_16(), $1, $2), a2: $9 => $a => Math_Multiset_x2fx3d_Eq_x28Multisetx20x24ax29(csegen_16(), $9, $a)};
});

/* {csegen:22} */
const csegen_22 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_7(), csegen_19(), $1, $2), a2: $b => $c => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_7(), csegen_19(), $b, $c)};
});

/* {csegen:23} */
const csegen_23 = __lazy(function () {
 return c => Prelude_EqOrd_x3dx3d_Eq_Char(c, ':');
});

/* {csegen:26} */
const csegen_26 = __lazy(function () {
 return {a1: $1 => $2 => ($1+$2), a2: $6 => $7 => ($6*$7), a3: $b => $b};
});

/* {csegen:42} */
const csegen_42 = __lazy(function () {
 return {a1: {a1: b => a => func => $2 => Prelude_Types_List_mapAppend({h: 0}, func, $2), a2: a => $8 => Prelude_Types_pure_Applicative_List($8), a3: b => a => $c => $d => Prelude_Types_x3cx2ax3e_Applicative_List($c, $d)}, a2: a => ({h: 0}), a3: a => $13 => $14 => Prelude_Types_List_tailRecAppend($13, $14())};
});

/* {csegen:43} */
const csegen_43 = __lazy(function () {
 return $0 => {
  const $4 = Math_Chromogeometry_spreadNL(0, $0.a1, $0.a2.a1, $0.a2.a2.a1);
  return {a1: ($4.a1*$0.a2.a2.a2), a2: $4.a2};
 };
});

/* {csegen:44} */
const csegen_44 = __lazy(function () {
 return $0 => $1 => Simplex_Twist_addRationalLocal($0, $1);
});

/* {csegen:47} */
const csegen_47 = __lazy(function () {
 return Math_SpreadPolynumber_scalarMul(2n, Math_SpreadPolynumber_sPoly());
});

/* {csegen:51} */
const csegen_51 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_Types_List_tailRecAppend($1, $2), a2: {h: 0}};
});

/* prim__sub_Integer : Integer -> Integer -> Integer */
function prim__sub_Integer($0, $1) {
 return ($0-$1);
}

/* JSBridge.case block in parseMaxelItem */
function JSBridge_case__parseMaxelItem_5322($0, $1) {
 switch($1.h) {
  case undefined: /* cons */ {
   switch($1.a2.h) {
    case undefined: /* cons */ {
     switch($1.a2.a2.h) {
      case undefined: /* cons */ {
       switch($1.a2.a2.a2.h) {
        case 0: /* nil */ {
         const $6 = JSBridge_splitList(csegen_0(), $1.a1);
         switch($6.h) {
          case undefined: /* cons */ {
           switch($6.a2.h) {
            case undefined: /* cons */ {
             switch($6.a2.a2.h) {
              case 0: /* nil */ {
               const $d = {a1: JSBridge_parseInt($6.a1), a2: JSBridge_parseInt($6.a2.a1)};
               const $14 = JSBridge_parseInt($1.a2.a1);
               const $17 = JSBridge_parseAmplitude($1.a2.a2.a1);
               return {a1: {a1: {a1: $d, a2: $17}, a2: $14}};
              }
              default: return {h: 0};
             }
            }
            default: return {h: 0};
           }
          }
          default: return {h: 0};
         }
        }
        default: return {h: 0};
       }
      }
      default: return {h: 0};
     }
    }
    default: return {h: 0};
   }
  }
  default: return {h: 0};
 }
}

/* JSBridge.case block in parseEdge */
function JSBridge_case__parseEdge_5106($0, $1) {
 switch($1.h) {
  case undefined: /* cons */ {
   switch($1.a2.h) {
    case undefined: /* cons */ {
     switch($1.a2.a2.h) {
      case 0: /* nil */ {
       const $5 = JSBridge_splitList(csegen_0(), $1.a1);
       switch($5.h) {
        case undefined: /* cons */ {
         switch($5.a2.h) {
          case undefined: /* cons */ {
           switch($5.a2.a2.h) {
            case undefined: /* cons */ {
             switch($5.a2.a2.a2.h) {
              case undefined: /* cons */ {
               switch($5.a2.a2.a2.a2.h) {
                case 0: /* nil */ return {a1: {a1: {a1: {a1: JSBridge_parseInt($5.a1), a2: JSBridge_parseInt($5.a2.a1)}, a2: {a1: JSBridge_parseInt($5.a2.a2.a1), a2: JSBridge_parseInt($5.a2.a2.a2.a1)}}, a2: JSBridge_parseInt($1.a2.a1)}};
                default: return {h: 0};
               }
              }
              default: return {h: 0};
             }
            }
            default: return {h: 0};
           }
          }
          default: return {h: 0};
         }
        }
        default: return {h: 0};
       }
      }
      default: return {h: 0};
     }
    }
    default: return {h: 0};
   }
  }
  default: return {h: 0};
 }
}

/* JSBridge.stepUniverseLocalizedBridge : String -> String -> String -> String -> String */
function JSBridge_stepUniverseLocalizedBridge($0, $1, $2, $3) {
 const $4 = JSBridge_parseInt($0);
 const $7 = JSBridge_parseInt($1);
 let $a;
 switch($7) {
  case 1n: {
   $a = 1;
   break;
  }
  case 2n: {
   $a = 2;
   break;
  }
  default: $a = 0;
 }
 const $c = JSBridge_parseSubstrate($2);
 const $f = JSBridge_parseSparseMaxel($3);
 const $12 = Evolution_SpreadPolynumber_stepUniverseLocalized($4, $a, $c, $f);
 const $18 = {a1: $12.a1, a2: $12.a2};
 return Simplex_Core_serializeUniverseState($18);
}

/* JSBridge.splitList : (Char -> Bool) -> String -> List String */
function JSBridge_splitList($0, $1) {
 return Data_String_split($0, $1);
}

/* JSBridge.runAdaptiveCycleBridge : String -> String -> String -> String -> String -> String */
function JSBridge_runAdaptiveCycleBridge($0, $1, $2, $3, $4) {
 const $5 = JSBridge_parseInt($0);
 const $8 = JSBridge_parseInt($1);
 let $b;
 switch($8) {
  case 1n: {
   $b = 1;
   break;
  }
  case 2n: {
   $b = 2;
   break;
  }
  default: $b = 0;
 }
 const $e = JSBridge_splitList(csegen_0(), $2);
 let $d;
 switch($e.h) {
  case undefined: /* cons */ {
   switch($e.a2.h) {
    case undefined: /* cons */ {
     switch($e.a2.a2.h) {
      case 0: /* nil */ {
       $d = {a1: JSBridge_parseInt($e.a1), a2: JSBridge_parseInt($e.a2.a1)};
       break;
      }
      default: $d = {a1: 0n, a2: 0n};
     }
     break;
    }
    default: $d = {a1: 0n, a2: 0n};
   }
   break;
  }
  default: $d = {a1: 0n, a2: 0n};
 }
 const $21 = JSBridge_parseSubstrate($3);
 const $24 = JSBridge_parseSparseMaxel($4);
 const $27 = {a1: $21, a2: $24};
 const $2a = Evolution_Cycle_runAdaptiveCycle($5, $b, $d, $27);
 return Simplex_Core_serializeUniverseState($2a);
}

/* JSBridge.parseTerms : List String -> List ((Nat, Nat), Integer) */
function JSBridge_parseTerms($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ {
   switch($0.a2.h) {
    case undefined: /* cons */ {
     switch($0.a2.a2.h) {
      case undefined: /* cons */ return {a1: {a1: {a1: JSBridge_parseNat($0.a1), a2: JSBridge_parseNat($0.a2.a1)}, a2: JSBridge_parseInt($0.a2.a2.a1)}, a2: JSBridge_parseTerms($0.a2.a2.a2)};
      default: return {h: 0};
     }
    }
    default: return {h: 0};
   }
  }
  default: return {h: 0};
 }
}

/* JSBridge.parseSubstrate : String -> Substrate */
function JSBridge_parseSubstrate($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, '')) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: {
   const $5 = JSBridge_splitList(csegen_1(), $0);
   const $a = Prelude_Types_List_mapMaybeAppend({h: 0}, $e => JSBridge_parseEdge($e), $5);
   return Math_Multiset_fromList(csegen_10(), $a);
  }
 }
}

/* JSBridge.parseSparseMaxel : String -> SparseMaxel */
function JSBridge_parseSparseMaxel($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, '')) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: {
   const $5 = JSBridge_splitList(csegen_1(), $0);
   const $a = Prelude_Types_List_mapMaybeAppend({h: 0}, $e => JSBridge_parseMaxelItem($e), $5);
   return Math_Multiset_fromList(csegen_22(), $a);
  }
 }
}

/* JSBridge.parseNat : String -> Nat */
function JSBridge_parseNat($0) {
 return Prelude_Types_prim__integerToNat(JSBridge_parseInt($0));
}

/* JSBridge.parseMaxelItem : String -> Maybe ((Geometry, Amplitude), Integer) */
function JSBridge_parseMaxelItem($0) {
 return JSBridge_case__parseMaxelItem_5322($0, JSBridge_splitList(csegen_23(), $0));
}

/* JSBridge.parseInt : String -> Integer */
function JSBridge_parseInt($0) {
 const $1 = Data_String_parseInteger(csegen_26(), {a1: csegen_26(), a2: $9 => (0n-$9), a3: $d => $e => ($d-$e)}, $0);
 switch($1.h) {
  case undefined: /* just */ return $1.a1;
  case 0: /* nothing */ return 0n;
 }
}

/* JSBridge.parseEdge : String -> Maybe ((Geometry, Geometry), Integer) */
function JSBridge_parseEdge($0) {
 return JSBridge_case__parseEdge_5106($0, JSBridge_splitList(csegen_23(), $0));
}

/* JSBridge.parseAmplitude : String -> Amplitude */
function JSBridge_parseAmplitude($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, '')) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: return Math_Multiset_fromList(csegen_16(), JSBridge_parseTerms(JSBridge_splitList(csegen_0(), $0)));
 }
}

/* JSBridge.main : IO () */
function JSBridge_main($0) {
 const $1 = JSBridge_prim_exportFunction('idris_runAdaptiveCycle', $5 => $6 => $7 => $8 => $9 => JSBridge_runAdaptiveCycleBridge($5, $6, $7, $8, $9), $0);
 const $11 = JSBridge_prim_exportFunction4('idris_stepUniverseLocalized', $15 => $16 => $17 => $18 => JSBridge_stepUniverseLocalizedBridge($15, $16, $17, $18), $0);
 return Prelude_IO_prim__putStr('Idris physics engine JSBridge initialized successfully!\n', $0);
}

/* Data.List1.map */
function Data_List1_map_Functor_List1($0, $1) {
 return {a1: $0($1.a1), a2: Prelude_Types_List_mapAppend({h: 0}, $0, $1.a2)};
}

/* Data.List1.singleton : a -> List1 a */
function Data_List1_singleton($0) {
 return {a1: $0, a2: {h: 0}};
}

/* Prelude.Types.pure */
function Prelude_Types_pure_Applicative_List($0) {
 return {a1: $0, a2: {h: 0}};
}

/* Prelude.Types.map */
function Prelude_Types_map_Functor_Maybe($0, $1) {
 switch($1.h) {
  case undefined: /* just */ return {a1: $0($1.a1)};
  case 0: /* nothing */ return {h: 0};
 }
}

/* Prelude.Types.foldMap */
function Prelude_Types_foldMap_Foldable_List($0, $1, $2) {
 return Prelude_Types_foldl_Foldable_List(acc => elem => $0.a1(acc)($1(elem)), $0.a2, $2);
}

/* Prelude.Types.<= */
function Prelude_Types_x3cx3d_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 2);
}

/* Prelude.Types.<*> */
function Prelude_Types_x3cx2ax3e_Applicative_List($0, $1) {
 return Prelude_Types_listBind($0, f => Prelude_Types_List_mapAppend({h: 0}, f, $1));
}

/* Prelude.Types./= */
function Prelude_Types_x2fx3d_Eq_Nat($0, $1) {
 switch((($0===$1)?1:0)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.Types.List.tailRecAppend : List a -> List a -> List a */
function Prelude_Types_List_tailRecAppend($0, $1) {
 return Prelude_Types_List_reverseOnto($1, Prelude_Types_List_reverse($0));
}

/* Prelude.Types.List.reverse : List a -> List a */
function Prelude_Types_List_reverse($0) {
 return Prelude_Types_List_reverseOnto({h: 0}, $0);
}

/* Prelude.Types.prim__integerToNat : Integer -> Nat */
function Prelude_Types_prim__integerToNat($0) {
 switch(((0n<=$0)?1:0)) {
  case 0: return 0n;
  default: return $0;
 }
}

/* Prelude.Types.listBind : List a -> (a -> List b) -> List b */
function Prelude_Types_listBind($0, $1) {
 return Prelude_Types_listBindOnto($1, {h: 0}, $0);
}

/* Prelude.Types.isSpace : Char -> Bool */
function Prelude_Types_isSpace($0) {
 switch($0) {
  case ' ': return 1;
  case '\u{9}': return 1;
  case '\r': return 1;
  case '\n': return 1;
  case '\u{c}': return 1;
  case '\u{b}': return 1;
  case '\u{a0}': return 1;
  default: return 0;
 }
}

/* Prelude.Num.mod */
function Prelude_Num_mod_Integral_Integer($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($1, 0n)) {
  case 0: return _modBigInt($0, $1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in mod at Prelude.Num:94:3--96:44');
 }
}

/* Prelude.Num.div */
function Prelude_Num_div_Integral_Integer($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($1, 0n)) {
  case 0: return _divBigInt($0, $1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in div at Prelude.Num:91:3--93:44');
 }
}

/* Prelude.Num.abs */
function Prelude_Num_abs_Abs_Integer($0) {
 switch(Prelude_EqOrd_x3c_Ord_Integer($0, 0n)) {
  case 1: return (0n-$0);
  case 0: return $0;
 }
}

/* Prelude.EqOrd.compare */
function Prelude_EqOrd_compare_Ord_Integer($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Integer($0, $1)) {
  case 1: return 0;
  case 0: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, $1)) {
    case 1: return 1;
    case 0: return 2;
   }
  }
 }
}

/* Prelude.EqOrd.> */
function Prelude_EqOrd_x3e_Ord_Integer($0, $1) {
 switch((($0>$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Integer($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Char($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_String($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Ordering($0, $1) {
 switch($0) {
  case 0: {
   switch($1) {
    case 0: return 1;
    default: return 0;
   }
  }
  case 1: {
   switch($1) {
    case 1: return 1;
    default: return 0;
   }
  }
  case 2: {
   switch($1) {
    case 2: return 1;
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Integer($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Char($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29($0, $1, $2, $3) {
 switch($0.a1($2.a1)($3.a1)) {
  case 1: return $1.a1($2.a2)($3.a2);
  case 0: return 0;
 }
}

/* Prelude.EqOrd.< */
function Prelude_EqOrd_x3c_Ord_Integer($0, $1) {
 switch((($0<$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.<= */
function Prelude_EqOrd_x3cx3d_Ord_Char($0, $1) {
 switch((($0<=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_Ordering($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Ordering($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_Integer($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29($0, $1, $2, $3) {
 switch(Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29($0, $1, $2, $3)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd.compareInteger : Integer -> Integer -> Ordering */
function Prelude_EqOrd_compareInteger($0, $1) {
 return Prelude_EqOrd_compare_Ord_Integer($0, $1);
}

/* Prelude.Interfaces.guard : Alternative f => Bool -> f () */
function Prelude_Interfaces_guard($0, $1) {
 switch($1) {
  case 1: return $0.a1.a2(undefined)(undefined);
  case 0: return $0.a2(undefined);
 }
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Nat($0) {
 return Prelude_Show_show_Show_Integer($0);
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Integer($0) {
 return Prelude_Show_showPrec_Show_Integer({h: 0 /* Open */}, $0);
}

/* Prelude.Show.showPrec */
function Prelude_Show_showPrec_Show_Integer($0, $1) {
 return Prelude_Show_primNumShow($4 => (''+$4), $0, $1);
}

/* Prelude.Show.compare */
function Prelude_Show_compare_Ord_Prec($0, $1) {
 switch($0.h) {
  case 4: /* User */ {
   switch($1.h) {
    case 4: /* User */ return Prelude_EqOrd_compare_Ord_Integer($0.a1, $1.a1);
    default: return Prelude_EqOrd_compare_Ord_Integer(Prelude_Show_precCon($0), Prelude_Show_precCon($1));
   }
  }
  default: return Prelude_EqOrd_compare_Ord_Integer(Prelude_Show_precCon($0), Prelude_Show_precCon($1));
 }
}

/* Prelude.Show.>= */
function Prelude_Show_x3ex3d_Ord_Prec($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_Show_compare_Ord_Prec($0, $1), 0);
}

/* Prelude.Show.showParens : Bool -> String -> String */
function Prelude_Show_showParens($0, $1) {
 switch($0) {
  case 0: return $1;
  case 1: return ('('+($1+')'));
 }
}

/* Prelude.Show.primNumShow : (a -> String) -> Prec -> a -> String */
function Prelude_Show_primNumShow($0, $1, $2) {
 const $3 = $0($2);
 let $7;
 switch(Prelude_Show_x3ex3d_Ord_Prec($1, {h: 5 /* PrefixMinus */})) {
  case 1: {
   $7 = Prelude_Show_firstCharIs($e => Prelude_EqOrd_x3dx3d_Eq_Char($e, '-'), $3);
   break;
  }
  case 0: {
   $7 = 0;
   break;
  }
 }
 return Prelude_Show_showParens($7, $3);
}

/* Prelude.Show.precCon : Prec -> Integer */
function Prelude_Show_precCon($0) {
 switch($0.h) {
  case 0: /* Open */ return 0n;
  case 1: /* Equal */ return 1n;
  case 2: /* Dollar */ return 2n;
  case 3: /* Backtick */ return 3n;
  case 4: /* User */ return 4n;
  case 5: /* PrefixMinus */ return 5n;
  case 6: /* App */ return 6n;
 }
}

/* Prelude.Show.firstCharIs : (Char -> Bool) -> String -> Bool */
function Prelude_Show_firstCharIs($0, $1) {
 switch($1) {
  case '': return 0;
  default: return $0(($1.charAt(0)));
 }
}

/* PrimIO.unsafePerformIO : IO a -> a */
function PrimIO_unsafePerformIO($0) {
 return PrimIO_unsafeCreateWorld(w => $0(w));
}

/* PrimIO.unsafeCreateWorld : (1 _ : ((1 _ : %World) -> a)) -> a */
function PrimIO_unsafeCreateWorld($0) {
 return $0(_idrisworld);
}

/* Data.List.split : (a -> Bool) -> List a -> List1 (List a) */
function Data_List_split($0, $1) {
 const $2 = Data_List_break$($0, $1);
 switch($2.a2.h) {
  case 0: /* nil */ return Data_List1_singleton($2.a1);
  case undefined: /* cons */ return {a1: $2.a1, a2: Data_List_split($0, $2.a2.a2)};
 }
}

/* Data.List.span : (a -> Bool) -> List a -> (List a, List a) */
function Data_List_span($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {a1: {h: 0}, a2: {h: 0}};
  case undefined: /* cons */ {
   switch($0($1.a1)) {
    case 1: {
     const $8 = Data_List_span($0, $1.a2);
     return {a1: {a1: $1.a1, a2: $8.a1}, a2: $8.a2};
    }
    case 0: return {a1: {h: 0}, a2: {a1: $1.a1, a2: $1.a2}};
   }
  }
 }
}

/* Data.List.partition : (a -> Bool) -> List a -> (List a, List a) */
function Data_List_partition($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {a1: {h: 0}, a2: {h: 0}};
  case undefined: /* cons */ {
   const $5 = Data_List_partition($0, $1.a2);
   switch($0($1.a1)) {
    case 1: return {a1: {a1: $1.a1, a2: $5.a1}, a2: $5.a2};
    case 0: return {a1: $5.a1, a2: {a1: $1.a1, a2: $5.a2}};
   }
  }
 }
}

/* Data.List.last' : List a -> Maybe a */
function Data_List_lastx27($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ return {a1: Data_List_last($0)};
 }
}

/* Data.List.break : (a -> Bool) -> List a -> (List a, List a) */
function Data_List_break$($0, $1) {
 const $3 = $4 => {
  switch($0($4)) {
   case 1: return 0;
   case 0: return 1;
  }
 };
 return Data_List_span($3, $1);
}

/* Math.Multiset.3804:1451:isEmpty */
function Math_Multiset_n__3804_1451_isEmpty($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* ZeroM */ return 1;
  default: return 0;
 }
}

/* Math.Multiset.3701:1311:go */
function Math_Multiset_n__3701_1311_go($0, $1, $2) {
 switch($2.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: $2.a1, a2: ($2.a2*$1), a3: Math_Multiset_n__3701_1311_go($0, $1, $2.a3)};
 }
}

/* Math.Multiset.== */
function Math_Multiset_x3dx3d_Eq_x28Multisetx20x24ax29($0, $1, $2) {
 const $3 = Math_Multiset_annihilateMultiset($0, Math_Multiset_addMultiset($1, Math_Multiset_negateMultiset($2)));
 return Math_Multiset_n__3804_1451_isEmpty($0, $2, $1, $3);
}

/* Math.Multiset./= */
function Math_Multiset_x2fx3d_Eq_x28Multisetx20x24ax29($0, $1, $2) {
 switch(Math_Multiset_x3dx3d_Eq_x28Multisetx20x24ax29($0, $1, $2)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Math.Multiset.subMultiset : Multiset a -> Multiset a -> Multiset a */
function Math_Multiset_subMultiset($0, $1) {
 return Math_Multiset_addMultiset($0, Math_Multiset_negateMultiset($1));
}

/* Math.Multiset.scaleMultiset : Integer -> Multiset a -> Multiset a */
function Math_Multiset_scaleMultiset($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, 0n)) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: return Math_Multiset_n__3701_1311_go($1, $0, $1);
 }
}

/* Math.Multiset.negateMultiset : Multiset a -> Multiset a */
function Math_Multiset_negateMultiset($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: $0.a1, a2: (0n-$0.a2), a3: Math_Multiset_negateMultiset($0.a3)};
 }
}

/* Math.Multiset.multisetToList : Multiset a -> List (a, Integer) */
function Math_Multiset_multisetToList($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return {h: 0};
  case 1: /* AddM */ return {a1: {a1: $0.a1, a2: $0.a2}, a2: Math_Multiset_multisetToList($0.a3)};
 }
}

/* Math.Multiset.multiplicityAll : Multiset a -> Integer */
function Math_Multiset_multiplicityAll($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return 0n;
  case 1: /* AddM */ return (Prelude_Num_abs_Abs_Integer($0.a2)+Math_Multiset_multiplicityAll($0.a3));
 }
}

/* Math.Multiset.insertItem : Eq a => a -> Integer -> Multiset a -> Multiset a */
function Math_Multiset_insertItem($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* ZeroM */ return {h: 1 /* AddM */, a1: $1, a2: $2, a3: {h: 0 /* ZeroM */}};
  case 1: /* AddM */ {
   switch($0.a1($1)($3.a1)) {
    case 1: {
     const $e = ($2+$3.a2);
     switch(Prelude_EqOrd_x3dx3d_Eq_Integer($e, 0n)) {
      case 1: return $3.a3;
      case 0: return {h: 1 /* AddM */, a1: $1, a2: $e, a3: $3.a3};
     }
    }
    case 0: return {h: 1 /* AddM */, a1: $3.a1, a2: $3.a2, a3: Math_Multiset_insertItem($0, $1, $2, $3.a3)};
   }
  }
 }
}

/* Math.Multiset.fromList : Eq a => List (a, Integer) -> Multiset a */
function Math_Multiset_fromList($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {h: 0 /* ZeroM */};
  case undefined: /* cons */ return Math_Multiset_insertItem($0, $1.a1.a1, $1.a1.a2, Math_Multiset_fromList($0, $1.a2));
 }
}

/* Math.Multiset.annihilateMultiset : Eq a => Multiset a -> Multiset a */
function Math_Multiset_annihilateMultiset($0, $1) {
 return Math_Multiset_n__3641_1260_go($0, $1, {h: 0 /* ZeroM */}, $1);
}

/* Math.Multiset.addMultiset : Multiset a -> Multiset a -> Multiset a */
function Math_Multiset_addMultiset($0, $1) {
 switch($0.h) {
  case 0: /* ZeroM */ return $1;
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: $0.a1, a2: $0.a2, a3: Math_Multiset_addMultiset($0.a3, $1)};
 }
}

/* Math.Pixel.== */
function Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29($0, $1, $2) {
 switch($0.a1($1.a1)($2.a1)) {
  case 1: return $0.a1($1.a2)($2.a2);
  case 0: return 0;
 }
}

/* Math.Pixel./= */
function Math_Pixel_x2fx3d_Eq_x28Pixelx20x24ax29($0, $1, $2) {
 switch(Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29($0, $1, $2)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Math.Chromogeometry.spreadNL : Metric -> Pixel Integer -> Pixel Integer -> Pixel Integer -> (Integer, Integer) */
function Math_Chromogeometry_spreadNL($0, $1, $2, $3) {
 const $4 = Math_Chromogeometry_quadranceNL($0, $1, $2);
 const $9 = Math_Chromogeometry_quadranceNL($0, $3, $1);
 const $e = Math_Chromogeometry_archimedesNL($0, $1, $2, $3);
 const $14 = (($4*4n)*$9);
 return {a1: $e, a2: $14};
}

/* Math.Chromogeometry.quadranceNL : Metric -> Pixel Integer -> Pixel Integer -> Integer */
function Math_Chromogeometry_quadranceNL($0, $1, $2) {
 const $3 = Math_Chromogeometry_boundaryNL($1, $2);
 switch($0) {
  case 0: return (($3.a1*$3.a1)+($3.a2*$3.a2));
  case 1: return (($3.a1*$3.a1)-($3.a2*$3.a2));
  case 2: return (($3.a1*2n)*$3.a2);
 }
}

/* Math.Chromogeometry.boundaryNL : Pixel Integer -> Pixel Integer -> Pixel Integer */
function Math_Chromogeometry_boundaryNL($0, $1) {
 return {a1: ($1.a1-$0.a1), a2: ($1.a2-$0.a2)};
}

/* Math.Chromogeometry.archimedesNL : Metric -> Pixel Integer -> Pixel Integer -> Pixel Integer -> Integer */
function Math_Chromogeometry_archimedesNL($0, $1, $2, $3) {
 switch($0) {
  case 0: return Math_Chromogeometry_archimedesBlueNL($1, $2, $3);
  case 1: return (0n-Math_Chromogeometry_archimedesBlueNL($1, $2, $3));
  case 2: return (0n-Math_Chromogeometry_archimedesBlueNL($1, $2, $3));
 }
}

/* Math.Chromogeometry.archimedesBlueNL : Pixel Integer -> Pixel Integer -> Pixel Integer -> Integer */
function Math_Chromogeometry_archimedesBlueNL($0, $1, $2) {
 const $3 = Math_Chromogeometry_quadranceNL(0, $0, $1);
 const $8 = Math_Chromogeometry_quadranceNL(0, $1, $2);
 const $d = Math_Chromogeometry_quadranceNL(0, $2, $0);
 const $12 = (($3+$8)+$d);
 return (($12*$12)-(((($3*$3)+($8*$8))+($d*$d))*2n));
}

/* Simplex.Twist.case block in case block in computeTwist */
function Simplex_Twist_case__casex20blockx20inx20computeTwist_1621($0, $1, $2, $3, $4, $5) {
 let $7;
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($5.a2, 0n)) {
  case 1: {
   $7 = 0n;
   break;
  }
  case 0: {
   $7 = Prelude_Num_div_Integral_Integer($5.a1, $5.a2);
   break;
  }
 }
 return Prelude_Types_prim__integerToNat(Prelude_Num_mod_Integral_Integer(Prelude_Num_abs_Abs_Integer($7), 137n));
}

/* Simplex.Twist.lcm : Integer -> Integer -> Integer */
function Simplex_Twist_lcm($0, $1) {
 let $2;
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, 0n)) {
  case 1: {
   $2 = 1;
   break;
  }
  case 0: {
   $2 = Prelude_EqOrd_x3dx3d_Eq_Integer($1, 0n);
   break;
  }
 }
 switch($2) {
  case 1: return 0n;
  case 0: return Prelude_Num_div_Integral_Integer(Prelude_Num_abs_Abs_Integer(($0*$1)), Simplex_Twist_gcd($0, $1));
 }
}

/* Simplex.Twist.computeTwist : Metric -> Substrate -> Nat */
function Simplex_Twist_computeTwist($0, $1) {
 const $2 = Math_Multiset_multisetToList($1);
 const $5 = Prelude_Types_listBind($2, $9 => Prelude_Types_listBind($2, $f => Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_42(), Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $9.a1.a2, $f.a1.a1)), $1e => Prelude_Types_pure_Applicative_List({a1: $9.a1.a1, a2: {a1: $9.a1.a2, a2: {a1: $f.a1.a2, a2: ($9.a2*$f.a2)}}}))));
 const $29 = Prelude_Types_List_mapAppend({h: 0}, csegen_43(), $5);
 return Simplex_Twist_case__casex20blockx20inx20computeTwist_1621($1, $0, $2, $5, $29, Prelude_Types_foldl_Foldable_List(csegen_44(), {a1: 0n, a2: 1n}, $29));
}

/* Simplex.Twist.addRationalLocal : (Integer, Integer) -> (Integer, Integer) -> (Integer, Integer) */
function Simplex_Twist_addRationalLocal($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0.a2, 0n)) {
  case 1: return {a1: $1.a1, a2: $1.a2};
  case 0: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Integer($1.a2, 0n)) {
    case 1: return {a1: $0.a1, a2: $0.a2};
    case 0: {
     const $10 = Simplex_Twist_lcm($0.a2, $1.a2);
     const $14 = ($0.a1*Prelude_Num_div_Integral_Integer($10, $0.a2));
     const $1a = ($1.a1*Prelude_Num_div_Integral_Integer($10, $1.a2));
     const $20 = ($14+$1a);
     const $23 = Simplex_Twist_gcd($20, $10);
     switch(Prelude_EqOrd_x3dx3d_Eq_Integer($23, 0n)) {
      case 1: return {a1: $20, a2: $10};
      case 0: return {a1: Prelude_Num_div_Integral_Integer($20, $23), a2: Prelude_Num_div_Integral_Integer($10, $23)};
     }
    }
   }
  }
 }
}

/* Simplex.Core.serializeUniverseState : UniverseState -> String */
function Simplex_Core_serializeUniverseState($0) {
 return ('{\"substrate\":'+(Simplex_Core_serializeSubstrate($0.a1)+(',\"stateVector\":'+(Simplex_Core_serializeSparseMaxel($0.a2)+'}'))));
}

/* Simplex.Core.serializeTerm : ((Nat, Nat), Integer) -> String */
function Simplex_Core_serializeTerm($0) {
 return ('{\"alpha\":'+(Prelude_Show_show_Show_Nat($0.a1.a1)+(',\"beta\":'+(Prelude_Show_show_Show_Nat($0.a1.a2)+(',\"count\":'+(Prelude_Show_show_Show_Integer($0.a2)+'}'))))));
}

/* Simplex.Core.serializeSubstrate : Substrate -> String */
function Simplex_Core_serializeSubstrate($0) {
 return ('['+(Simplex_Core_join(',', Prelude_Types_List_mapAppend({h: 0}, $a => Simplex_Core_serializeEdge($a), Math_Multiset_multisetToList($0)))+']'));
}

/* Simplex.Core.serializeSparseMaxel : SparseMaxel -> String */
function Simplex_Core_serializeSparseMaxel($0) {
 return ('['+(Simplex_Core_join(',', Prelude_Types_List_mapAppend({h: 0}, $a => Simplex_Core_serializeMaxelItem($a), Math_Multiset_multisetToList($0)))+']'));
}

/* Simplex.Core.serializeMaxelItem : ((Geometry, Amplitude), Integer) -> String */
function Simplex_Core_serializeMaxelItem($0) {
 return ('{\"geom\":'+(Simplex_Core_serializeGeometry($0.a1.a1)+(',\"amplitude\":'+(Simplex_Core_serializeAmplitude($0.a1.a2)+(',\"count\":'+(Prelude_Show_show_Show_Integer($0.a2)+'}'))))));
}

/* Simplex.Core.serializeGeometry : Geometry -> String */
function Simplex_Core_serializeGeometry($0) {
 return ('{\"src\":'+(Prelude_Show_show_Show_Integer($0.a1)+(',\"tgt\":'+(Prelude_Show_show_Show_Integer($0.a2)+'}'))));
}

/* Simplex.Core.serializeEdge : ((Geometry, Geometry), Integer) -> String */
function Simplex_Core_serializeEdge($0) {
 return ('{\"parent\":'+(Simplex_Core_serializeGeometry($0.a1.a1)+(',\"child\":'+(Simplex_Core_serializeGeometry($0.a1.a2)+(',\"count\":'+(Prelude_Show_show_Show_Integer($0.a2)+'}'))))));
}

/* Simplex.Core.serializeAmplitude : Amplitude -> String */
function Simplex_Core_serializeAmplitude($0) {
 return ('['+(Simplex_Core_join(',', Prelude_Types_List_mapAppend({h: 0}, $a => Simplex_Core_serializeTerm($a), Math_Multiset_multisetToList($0)))+']'));
}

/* Simplex.Core.join : String -> List String -> String */
function Simplex_Core_join($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return '';
  case undefined: /* cons */ {
   switch($1.a2.h) {
    case 0: /* nil */ return $1.a1;
    default: return ($1.a1+($0+Simplex_Core_join($0, $1.a2)));
   }
  }
 }
}

/* Math.IntPolynumber.3518:1105:mulOuter */
function Math_IntPolynumber_n__3518_1105_mulOuter($0, $1, $2, $3) {
 switch($2.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return Math_Multiset_addMultiset(Math_IntPolynumber_n__3518_1104_mulInner($0, $1, $2.a1, $2.a2, $3), Math_IntPolynumber_n__3518_1105_mulOuter($0, $1, $2.a3, $3));
 }
}

/* Math.IntPolynumber.3518:1104:mulInner */
function Math_IntPolynumber_n__3518_1104_mulInner($0, $1, $2, $3, $4) {
 switch($4.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: Math_IntPolynumber_n__3518_1103_mulBasis($0, $1, $2, $4.a1), a2: ($3*$4.a2), a3: Math_IntPolynumber_n__3518_1104_mulInner($0, $1, $2, $3, $4.a3)};
 }
}

/* Math.IntPolynumber.3518:1103:mulBasis */
function Math_IntPolynumber_n__3518_1103_mulBasis($0, $1, $2, $3) {
 return {a1: ($2.a1+$3.a1), a2: ($2.a2+$3.a2)};
}

/* Math.IntPolynumber.subIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_subIntPoly($0, $1) {
 return Math_Multiset_subMultiset($0, $1);
}

/* Math.IntPolynumber.posTerm : Nat -> Nat -> Integer -> IntPolynumber */
function Math_IntPolynumber_posTerm($0, $1, $2) {
 return {h: 1 /* AddM */, a1: {a1: $0, a2: $1}, a2: $2, a3: {h: 0 /* ZeroM */}};
}

/* Math.IntPolynumber.mulIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_mulIntPoly($0, $1) {
 return Math_Multiset_annihilateMultiset(csegen_16(), Math_IntPolynumber_n__3518_1105_mulOuter($1, $0, $0, $1));
}

/* Math.IntPolynumber.emptyIntPoly : IntPolynumber */
const Math_IntPolynumber_emptyIntPoly = __lazy(function () {
 return {h: 0 /* ZeroM */};
});

/* Math.IntPolynumber.annihilateIntPoly : IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_annihilateIntPoly($0) {
 return Math_Multiset_annihilateMultiset(csegen_16(), $0);
}

/* Math.IntPolynumber.addIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_addIntPoly($0, $1) {
 return Math_Multiset_addMultiset($0, $1);
}

/* Math.SpreadPolynumber.scalarMul : Nat -> IntPolynumber -> IntPolynumber */
function Math_SpreadPolynumber_scalarMul($0, $1) {
 switch($0) {
  case 0n: return Math_IntPolynumber_emptyIntPoly();
  default: {
   const $4 = ($0-1n);
   return Math_IntPolynumber_addIntPoly($1, Math_SpreadPolynumber_scalarMul($4, $1));
  }
 }
}

/* Math.SpreadPolynumber.sPoly : IntPolynumber */
const Math_SpreadPolynumber_sPoly = __lazy(function () {
 return Math_IntPolynumber_posTerm(1n, 0n, 1n);
});

/* Math.SpreadPolynumber.onePoly : IntPolynumber */
const Math_SpreadPolynumber_onePoly = __lazy(function () {
 return Math_IntPolynumber_posTerm(0n, 0n, 1n);
});

/* Math.SpreadPolynumber.makeSpreadPolyExpr : (n : Nat) -> SpreadPolyExpr n */
function Math_SpreadPolynumber_makeSpreadPolyExpr($0) {
 switch($0) {
  case 0n: return {h: 0 /* SZero */};
  default: {
   const $2 = ($0-1n);
   switch($2) {
    case 0n: return {h: 1 /* SOne */};
    default: {
     const $6 = ($2-1n);
     return {h: 2 /* SRec */, a1: $6, a2: Math_SpreadPolynumber_makeSpreadPolyExpr(($6+1n)), a3: Math_SpreadPolynumber_makeSpreadPolyExpr($6)};
    }
   }
  }
 }
}

/* Math.SpreadPolynumber.evalSpreadPolyExpr : SpreadPolyExpr n -> IntPolynumber */
function Math_SpreadPolynumber_evalSpreadPolyExpr($0) {
 switch($0.h) {
  case 0: /* SZero */ return Math_IntPolynumber_emptyIntPoly();
  case 1: /* SOne */ return Math_SpreadPolynumber_sPoly();
  case 2: /* SRec */ {
   const $4 = Math_SpreadPolynumber_evalSpreadPolyExpr($0.a2);
   const $7 = Math_SpreadPolynumber_evalSpreadPolyExpr($0.a3);
   const $a = Math_IntPolynumber_subIntPoly(Math_SpreadPolynumber_onePoly(), csegen_47());
   const $10 = Math_SpreadPolynumber_scalarMul(2n, Math_IntPolynumber_mulIntPoly($a, $4));
   const $17 = csegen_47();
   return Math_IntPolynumber_annihilateIntPoly(Math_IntPolynumber_addIntPoly(Math_IntPolynumber_subIntPoly($10, $7), $17));
  }
 }
}

/* Evolution.Cycle.case block in runAdaptiveCycle */
function Evolution_Cycle_case__runAdaptiveCycle_2151($0, $1, $2, $3, $4, $5) {
 let $7;
 switch(Evolution_Transform_canAscend($3, $5.a1, $5.a2)) {
  case 1: {
   $7 = Evolution_Cycle_sigmaGateAudit($5.a1, $5.a2);
   break;
  }
  case 0: {
   $7 = 0;
   break;
  }
 }
 switch($7) {
  case 1: {
   const $11 = Evolution_Transform_ascendScale($2, $5.a2);
   return {a1: $5.a1, a2: $11};
  }
  case 0: return {a1: $5.a1, a2: $5.a2};
 }
}

/* Evolution.Cycle.sigmaGateAudit : Substrate -> SparseMaxel -> Bool */
function Evolution_Cycle_sigmaGateAudit($0, $1) {
 const $2 = SigmaBridge_sigmaMeltChain($0);
 const $5 = Simplex_SigmaLinear_runBoundary($2);
 const $8 = SigmaBridge_sigmaFreezeGeometryMaxel($5);
 const $b = Math_Multiset_multiplicityAll($8);
 return Prelude_EqOrd_x3dx3d_Eq_Integer($b, 0n);
}

/* Evolution.Cycle.runAdaptiveCycle : Integer -> Metric -> Geometry -> UniverseState -> UniverseState */
function Evolution_Cycle_runAdaptiveCycle($0, $1, $2, $3) {
 return Evolution_Cycle_case__runAdaptiveCycle_2151($3.a2, $3.a1, $2, $1, $0, Evolution_SpreadPolynumber_stepUniverseLocalized($0, $1, $3.a1, $3.a2));
}

/* SigmaBridge.sigmaMeltChain : Substrate -> DynamicSubstrate */
function SigmaBridge_sigmaMeltChain($0) {
 const $1 = Math_Multiset_multisetToList($0);
 return {a1: $1, a2: SigmaBridge_buildLDep($1)};
}

/* SigmaBridge.sigmaFreezeGeometryMaxel : DynamicSparseMaxel -> SparseMaxel */
function SigmaBridge_sigmaFreezeGeometryMaxel($0) {
 const $2 = SigmaBridge_freezeLDep($0.a2);
 const $5 = Prelude_Types_List_mapAppend({h: 0}, $9 => ({a1: {a1: $9.a1, a2: {h: 0 /* ZeroM */}}, a2: $9.a2}), $2);
 return Math_Multiset_fromList(csegen_22(), $5);
}

/* SigmaBridge.freezeLDep : (1 _ : LDepMultiset a c) -> List (a, Integer) */
function SigmaBridge_freezeLDep($0) {
 return SigmaBridge_freezeLDepAcc({h: 0}, $0);
}

/* SigmaBridge.buildLDep : (c : List (a, Integer)) -> LDepMultiset a c */
function SigmaBridge_buildLDep($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 0 /* LEmptyM */};
  case undefined: /* cons */ return {h: 1 /* LAddM */, a1: $0.a1.a1, a2: $0.a1.a2, a3: SigmaBridge_buildLDep($0.a2)};
 }
}

/* Simplex.SigmaLinear.runBoundary : DynamicSubstrate -> DynamicSparseMaxel */
function Simplex_SigmaLinear_runBoundary($0) {
 return {a1: Simplex_SigmaLinear_computeBoundaryIndex($0.a1), a2: Simplex_SigmaLinear_applyBoundary($0.a2)};
}

/* Simplex.SigmaLinear.computeBoundaryIndex : List (Edge, Integer) -> List (Geometry, Integer) */
function Simplex_SigmaLinear_computeBoundaryIndex($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ return {a1: {a1: $0.a1.a1.a2, a2: $0.a1.a2}, a2: {a1: {a1: $0.a1.a1.a1, a2: (0n-$0.a1.a2)}, a2: Simplex_SigmaLinear_computeBoundaryIndex($0.a2)}};
 }
}

/* Simplex.SigmaLinear.applyBoundary : (1 _ : LDepSubstrate edges) -> LDepSparseMaxel (computeBoundaryIndex edges) */
function Simplex_SigmaLinear_applyBoundary($0) {
 switch($0.h) {
  case 0: /* LEmptyM */ return {h: 0 /* LEmptyM */};
  case 1: /* LAddM */ return {h: 1 /* LAddM */, a1: $0.a1.a2, a2: $0.a2, a3: {h: 1 /* LAddM */, a1: $0.a1.a1, a2: (0n-$0.a2), a3: Simplex_SigmaLinear_applyBoundary($0.a3)}};
 }
}

/* Evolution.Transform.shatterTerm : Integer -> ((Nat, Nat), Integer) -> ((Nat, Nat), Integer) */
function Evolution_Transform_shatterTerm($0, $1) {
 const $3 = Prelude_Num_mod_Integral_Integer($1.a2, $0);
 return {a1: $1.a1, a2: $3};
}

/* Evolution.Transform.partitionLogic : Integer -> Pixel Integer -> IntPolynumber -> (Multiset (Pixel Integer,
IntPolynumber),
Multiset (Pixel Integer, IntPolynumber)) */
function Evolution_Transform_partitionLogic($0, $1, $2) {
 const $3 = Data_List_partition($6 => Evolution_Transform_isLatentTerm($0, $6), Math_Multiset_multisetToList($2));
 const $d = Math_Multiset_fromList(csegen_16(), $3.a1);
 const $12 = Math_Multiset_fromList(csegen_16(), $3.a2);
 const $17 = Math_Multiset_fromList(csegen_22(), {a1: {a1: {a1: $1, a2: $d}, a2: 1n}, a2: {h: 0}});
 const $22 = Math_Multiset_fromList(csegen_22(), {a1: {a1: {a1: $1, a2: $12}, a2: 1n}, a2: {h: 0}});
 return {a1: $17, a2: $22};
}

/* Evolution.Transform.isLatentTerm : Integer -> ((Nat, Nat), Integer) -> Bool */
function Evolution_Transform_isLatentTerm($0, $1) {
 return Prelude_EqOrd_x3ex3d_Ord_Integer($1.a2, $0);
}

/* Evolution.Transform.evaluateResonance : Integer -> Integer -> Pixel Integer -> Multiset (Pixel Integer,
IntPolynumber) -> Multiset (Pixel Integer, IntPolynumber) */
function Evolution_Transform_evaluateResonance($0, $1, $2, $3) {
 const $4 = Math_Multiset_multiplicityAll($3);
 switch(Prelude_EqOrd_x3e_Ord_Integer($4, $0)) {
  case 1: {
   const $b = Prelude_Types_foldMap_Foldable_List(csegen_51(), $10 => Prelude_Types_List_mapAppend({h: 0}, $16 => ({a1: $16.a1, a2: ($16.a2*$10.a2)}), Math_Multiset_multisetToList($10.a1.a2)), Math_Multiset_multisetToList($3));
   const $22 = Prelude_Types_List_mapAppend({h: 0}, $26 => Evolution_Transform_shatterTerm($1, $26), $b);
   const $2b = Math_Multiset_fromList(csegen_16(), $22);
   return Math_Multiset_fromList(csegen_22(), {a1: {a1: {a1: $2, a2: $2b}, a2: 1n}, a2: {h: 0}});
  }
  case 0: return $3;
 }
}

/* Evolution.Transform.canAscend : Metric -> Substrate -> SparseMaxel -> Bool */
function Evolution_Transform_canAscend($0, $1, $2) {
 const $3 = Math_Multiset_multiplicityAll($2);
 const $6 = Math_Multiset_multiplicityAll($1);
 const $9 = Simplex_Twist_computeTwist($0, $1);
 const $d = (($3+$6)+$9);
 return Prelude_EqOrd_x3ex3d_Ord_Integer($d, 137n);
}

/* Evolution.Transform.ascendScale : Pixel Integer -> Multiset (Pixel Integer,
IntPolynumber) -> Multiset (Pixel Integer, IntPolynumber) */
function Evolution_Transform_ascendScale($0, $1) {
 const $2 = Prelude_Types_foldl_Foldable_List(acc => $5 => Math_Multiset_addMultiset(acc, Math_Multiset_scaleMultiset($5.a2, $5.a1.a2)), Math_IntPolynumber_emptyIntPoly(), Math_Multiset_multisetToList($1));
 return Math_Multiset_fromList(csegen_22(), {a1: {a1: {a1: $0, a2: $2}, a2: 1n}, a2: {h: 0}});
}

/* Evolution.Gate.selectGate : Nat -> FundamentalGate */
function Evolution_Gate_selectGate($0) {
 const $1 = Prelude_Types_List_filterAppend({h: 0}, g => Prelude_Types_x3cx3d_Ord_Nat(g.a2, $0), Evolution_Gate_adaptiveCycle());
 const $b = Data_List_lastx27($1);
 switch($b.h) {
  case undefined: /* just */ return $b.a1;
  case 0: /* nothing */ return Evolution_Gate_BackgroundGate();
 }
}

/* Evolution.Gate.adaptiveCycle : List FundamentalGate */
const Evolution_Gate_adaptiveCycle = __lazy(function () {
 return {a1: Evolution_Gate_BackgroundGate(), a2: {a1: Evolution_Gate_MatterGate(), a2: {a1: Evolution_Gate_BondGate(), a2: {a1: Evolution_Gate_ChargeGate(), a2: {a1: Evolution_Gate_TimeGate(), a2: {a1: Evolution_Gate_WeakForceGate(), a2: {a1: Evolution_Gate_ResonanceGate(), a2: {h: 0}}}}}}}};
});

/* Evolution.Gate.WeakForceGate : FundamentalGate */
const Evolution_Gate_WeakForceGate = __lazy(function () {
 return {a1: 'Weak Force', a2: 11n};
});

/* Evolution.Gate.TimeGate : FundamentalGate */
const Evolution_Gate_TimeGate = __lazy(function () {
 return {a1: 'Time Dilation', a2: 7n};
});

/* Evolution.Gate.ResonanceGate : FundamentalGate */
const Evolution_Gate_ResonanceGate = __lazy(function () {
 return {a1: 'Decoherence Resonance', a2: 13n};
});

/* Evolution.Gate.MatterGate : FundamentalGate */
const Evolution_Gate_MatterGate = __lazy(function () {
 return {a1: 'Matter', a2: 3n};
});

/* Evolution.Gate.ChargeGate : FundamentalGate */
const Evolution_Gate_ChargeGate = __lazy(function () {
 return {a1: 'Fractional Charge', a2: 5n};
});

/* Evolution.Gate.BondGate : FundamentalGate */
const Evolution_Gate_BondGate = __lazy(function () {
 return {a1: 'Molecular Bond', a2: 4n};
});

/* Evolution.Gate.BackgroundGate : FundamentalGate */
const Evolution_Gate_BackgroundGate = __lazy(function () {
 return {a1: 'Background', a2: 2n};
});

/* Evolution.SpreadPolynumber.case block in case block in generateLocalSpreadPoly */
function Evolution_SpreadPolynumber_case__casex20blockx20inx20generateLocalSpreadPoly_2920($0, $1, $2, $3, $4, $5, $6) {
 let $8;
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($6.a2, 0n)) {
  case 1: {
   $8 = 0n;
   break;
  }
  case 0: {
   $8 = Prelude_Num_div_Integral_Integer($6.a1, $6.a2);
   break;
  }
 }
 const $11 = Evolution_Gate_selectGate(Prelude_Types_prim__integerToNat(Prelude_Num_mod_Integral_Integer(Prelude_Num_abs_Abs_Integer($8), 137n)));
 const $10 = $11.a2;
 const $1b = Math_SpreadPolynumber_makeSpreadPolyExpr($10);
 return Math_SpreadPolynumber_evalSpreadPolyExpr($1b);
}

/* Evolution.SpreadPolynumber.3887:3019:getEnergy */
function Evolution_SpreadPolynumber_n__3887_3019_getEnergy($0, $1, $2, $3, $4) {
 const $5 = Prelude_Types_List_filterAppend({h: 0}, $9 => Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $9.a1.a1, $4), $3);
 switch($5.h) {
  case undefined: /* cons */ return $5.a1.a2;
  case 0: /* nil */ return 0n;
 }
}

/* Evolution.SpreadPolynumber.3887:3018:deformedEdges */
function Evolution_SpreadPolynumber_n__3887_3018_deformedEdges($0, $1, $2, $3) {
 const $6 = $7 => {
  const $a = Evolution_SpreadPolynumber_n__3887_3019_getEnergy($0, $1, $2, $3, $7.a1.a1);
  const $11 = Evolution_SpreadPolynumber_n__3887_3019_getEnergy($0, $1, $2, $3, $7.a1.a2);
  return {a1: {a1: $7.a1.a1, a2: $7.a1.a2}, a2: (($7.a2+$a)+$11)};
 };
 return Prelude_Types_List_mapAppend({h: 0}, $6, $2);
}

/* Evolution.SpreadPolynumber.stepUniverseLocalized : Integer -> Metric -> Substrate -> SparseMaxel -> (Substrate, SparseMaxel) */
function Evolution_SpreadPolynumber_stepUniverseLocalized($0, $1, $2, $3) {
 const $7 = $8 => {
  const $b = Evolution_SpreadPolynumber_generateLocalSpreadPoly($1, $2, $8.a1.a1);
  const $10 = Math_Multiset_scaleMultiset($8.a2, Math_IntPolynumber_mulIntPoly($8.a1.a2, $b));
  return {a1: {a1: $8.a1.a1, a2: $10}, a2: $8.a2};
 };
 const $4 = Prelude_Types_List_mapAppend({h: 0}, $7, Math_Multiset_multisetToList($3));
 const $22 = $23 => {
  const $26 = Evolution_Transform_partitionLogic(128n, $23.a1.a1, $23.a1.a2);
  const $2b = Evolution_Transform_evaluateResonance($0, 13n, $23.a1.a1, $26.a2);
  return Math_Multiset_multisetToList(Math_Multiset_addMultiset($26.a1, $2b));
 };
 const $1e = Prelude_Types_foldMap_Foldable_List(csegen_51(), $22, $4);
 const $37 = Math_Multiset_fromList(csegen_22(), $1e);
 const $3c = Evolution_SpreadPolynumber_deformSubstrate($2, $37);
 return {a1: $3c, a2: $37};
}

/* Evolution.SpreadPolynumber.generateLocalSpreadPoly : Metric -> Substrate -> Pixel Integer -> IntPolynumber */
function Evolution_SpreadPolynumber_generateLocalSpreadPoly($0, $1, $2) {
 const $3 = Math_Multiset_multisetToList($1);
 const $9 = $a => {
  const $f = $10 => {
   const $1e = $1f => {
    let $25;
    switch(Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $a.a1.a1, $2)) {
     case 1: {
      $25 = 1;
      break;
     }
     case 0: {
      switch(Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $a.a1.a2, $2)) {
       case 1: {
        $25 = 1;
        break;
       }
       case 0: {
        $25 = Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $10.a1.a2, $2);
        break;
       }
      }
      break;
     }
    }
    const $21 = Prelude_Interfaces_guard(csegen_42(), $25);
    return Prelude_Types_listBind($21, $38 => Prelude_Types_pure_Applicative_List({a1: $a.a1.a1, a2: {a1: $a.a1.a2, a2: {a1: $10.a1.a2, a2: ($a.a2*$10.a2)}}}));
   };
   return Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_42(), Math_Pixel_x3dx3d_Eq_x28Pixelx20x24ax29(csegen_4(), $a.a1.a2, $10.a1.a1)), $1e);
  };
  return Prelude_Types_listBind($3, $f);
 };
 const $6 = Prelude_Types_listBind($3, $9);
 const $43 = Prelude_Types_List_mapAppend({h: 0}, csegen_43(), $6);
 return Evolution_SpreadPolynumber_case__casex20blockx20inx20generateLocalSpreadPoly_2920($2, $1, $0, $3, $6, $43, Prelude_Types_foldl_Foldable_List(csegen_44(), {a1: 0n, a2: 1n}, $43));
}

/* Evolution.SpreadPolynumber.deformSubstrate : Substrate -> SparseMaxel -> Substrate */
function Evolution_SpreadPolynumber_deformSubstrate($0, $1) {
 const $2 = Math_Multiset_multisetToList($0);
 const $5 = Math_Multiset_multisetToList($1);
 return Math_Multiset_fromList(csegen_10(), Evolution_SpreadPolynumber_n__3887_3018_deformedEdges($1, $0, $2, $5));
}

/* Data.String.with block in parseInteger,parseIntTrimmed */
function Data_String_with__parseIntegerx2cparseIntTrimmed_10310($0, $1, $2, $3, $4, $5) {
 switch($4) {
  case '': {
   switch($5.h) {
    case 0: /* nil */ return {h: 0};
    default: {
     switch(Prelude_EqOrd_x3dx3d_Eq_Char($5.a1, '-')) {
      case 1: return Prelude_Types_map_Functor_Maybe(y => $2.a2($1.a3(y)), Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), 0n));
      case 0: {
       switch(Prelude_EqOrd_x3dx3d_Eq_Char($5.a1, '+')) {
        case 1: return Prelude_Types_map_Functor_Maybe($1.a3, Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), BigInt(0)));
        case 0: {
         let $29;
         switch(Prelude_EqOrd_x3ex3d_Ord_Char($5.a1, '0')) {
          case 1: {
           $29 = Prelude_EqOrd_x3cx3d_Ord_Char($5.a1, '9');
           break;
          }
          case 0: {
           $29 = 0;
           break;
          }
         }
         switch($29) {
          case 1: return Prelude_Types_map_Functor_Maybe($1.a3, Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), BigInt(_sub32s(_truncInt32($5.a1.codePointAt(0)), _truncInt32('0'.codePointAt(0))))));
          case 0: return {h: 0};
         }
        }
       }
      }
     }
    }
   }
  }
  default: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Char($5.a1, '-')) {
    case 1: return Prelude_Types_map_Functor_Maybe(y => $2.a2($1.a3(y)), Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), 0n));
    case 0: {
     switch(Prelude_EqOrd_x3dx3d_Eq_Char($5.a1, '+')) {
      case 1: return Prelude_Types_map_Functor_Maybe($1.a3, Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), BigInt(0)));
      case 0: {
       let $60;
       switch(Prelude_EqOrd_x3ex3d_Ord_Char($5.a1, '0')) {
        case 1: {
         $60 = Prelude_EqOrd_x3cx3d_Ord_Char($5.a1, '9');
         break;
        }
        case 0: {
         $60 = 0;
         break;
        }
       }
       switch($60) {
        case 1: return Prelude_Types_map_Functor_Maybe($1.a3, Data_String_parseNumWithoutSign(Prelude_Types_fastUnpack($5.a2), BigInt(_sub32s(_truncInt32($5.a1.codePointAt(0)), _truncInt32('0'.codePointAt(0))))));
        case 0: return {h: 0};
       }
      }
     }
    }
   }
  }
 }
}

/* Data.String.with block in asList */
function Data_String_with__asList_9840($0, $1) {
 switch($0) {
  case '': {
   switch($1.h) {
    case 0: /* nil */ return {h: 0 /* Nil */};
    default: return {h: 1 /* :: */, a1: $1.a1, a2: $1.a2, a3: () => Data_String_asList($1.a2)};
   }
  }
  default: return {h: 1 /* :: */, a1: $1.a1, a2: $1.a2, a3: () => Data_String_asList($1.a2)};
 }
}

/* Data.String.4569:10304:parseIntTrimmed */
function Data_String_n__4569_10304_parseIntTrimmed($0, $1, $2, $3) {
 return Data_String_with__parseIntegerx2cparseIntTrimmed_10310(undefined, $0, $1, $3, $3, Data_String_strM($3));
}

/* Data.String.trim : String -> String */
function Data_String_trim($0) {
 return Data_String_ltrim(Data_String_rtrim($0));
}

/* Data.String.strM : (x : String) -> StrM x */
function Data_String_strM($0) {
 switch($0) {
  case '': return {h: 0};
  default: return {a1: ($0.charAt(0)), a2: ($0.slice(1))};
 }
}

/* Data.String.split : (Char -> Bool) -> String -> List1 String */
function Data_String_split($0, $1) {
 return Data_List1_map_Functor_List1($4 => Prelude_Types_fastPack($4), Data_List_split($0, Prelude_Types_fastUnpack($1)));
}

/* Data.String.rtrim : String -> String */
function Data_String_rtrim($0) {
 return _strReverse(Data_String_ltrim(_strReverse($0)));
}

/* Data.String.parseInteger : Num a => Neg a => String -> Maybe a */
function Data_String_parseInteger($0, $1, $2) {
 return Data_String_n__4569_10304_parseIntTrimmed($0, $1, $2, Data_String_trim($2));
}

/* Data.String.ltrim : String -> String */
function Data_String_ltrim($0) {
 return Data_String_with__ltrim_9864($0, Data_String_asList($0));
}

/* Data.String.asList : (str : String) -> AsList str */
function Data_String_asList($0) {
 return Data_String_with__asList_9840($0, Data_String_strM($0));
}


try{__mainExpression_0()}catch(e){if(e instanceof IdrisError){console.log('ERROR: ' + e.message)}else{throw e} }
