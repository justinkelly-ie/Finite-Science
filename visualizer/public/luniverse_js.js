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

const JSBridge_prim_pushMaxel = ((x, y, alpha, beta, count) => { if (globalThis.pushMaxel) globalThis.pushMaxel(x, y, alpha, beta, count); });
const JSBridge_prim_pushEdge = ((px, py, cx, cy, count) => { if (globalThis.pushEdge) globalThis.pushEdge(px, py, cx, cy, count); });
const JSBridge_prim_exportFunction4 = ((name, fn) => { globalThis[name] = (a) => (b) => (c) => (d) => { fn(a)(b)(c)(d)(); return 0; }; });
const JSBridge_prim_exportFunction = ((name, fn) => { globalThis[name] = (a) => (b) => (c) => (d) => (e) => { fn(a)(b)(c)(d)(e)(); return 0; }; });
const JSBridge_prim_clearBuffers = (() => { if (globalThis.clearUniverseBuffers) globalThis.clearUniverseBuffers(); });
const Prelude_Types_fastUnpack = ((str)=>__prim_js2idris_array(Array.from(str)));
const Prelude_Types_fastPack = ((xs)=>__prim_idris2js_array(xs).join(''));
const Prelude_IO_prim__putStr = (x=>console.log(x));
/* {$tcOpt:1} */
function x24tcOpt_1($0) {
 switch($0.a4) {
  case 0n: return {h: 0 /* {TcDone:1} */, a1: $0.a5};
  default: {
   const $4 = ($0.a4-1n);
   const $8 = Math_SpreadPolynumber_scalarMul(2n, Math_IntPolynumber_mulIntPoly($0.a2, $0.a5.a1));
   const $f = Math_IntPolynumber_annihilateIntPoly(Math_IntPolynumber_addIntPoly(Math_IntPolynumber_subIntPoly($8, $0.a5.a2), $0.a3));
   return {h: 1 /* {TcContinue1:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $4, a5: {a1: $f, a2: $0.a5.a1}};
  }
 }
}

/* Math.SpreadPolynumber.3613:2590:step */
function Math_SpreadPolynumber_n__3613_2590_step($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_1, {h: 1 /* {TcContinue1:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
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
  case 0: /* nil */ return {h: 0 /* {TcDone:3} */, a1: {h: 0}};
  case undefined: /* cons */ {
   switch(Prelude_Types_elemBy(csegen_73(), $0.a2, $0.a3.a1)($0.a1)) {
    case 1: return {h: 1 /* {TcContinue3:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
    case 0: return {h: 0 /* {TcDone:3} */, a1: {a1: $0.a3.a1, a2: Data_List_n__4934_5733_nubByx27({a1: $0.a3.a1, a2: $0.a1}, $0.a2, $0.a3.a2)}};
   }
  }
 }
}

/* Data.List.4934:5733:nubBy' */
function Data_List_n__4934_5733_nubByx27($0, $1, $2) {
 return __tailRec(x24tcOpt_3, {h: 1 /* {TcContinue3:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:4} */
function x24tcOpt_4($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ {
   const $3 = $0.a2($0.a3.a1);
   switch($3.h) {
    case undefined: /* just */ return {h: 1 /* {TcContinue4:1} */, a1: {a1: $0.a1, a2: $3.a1}, a2: $0.a2, a3: $0.a3.a2};
    case 0: /* nothing */ return {h: 1 /* {TcContinue4:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
  case 0: /* nil */ return {h: 0 /* {TcDone:4} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapMaybeAppend : SnocList b -> (a -> Maybe b) -> List a -> List b */
function Prelude_Types_List_mapMaybeAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_4, {h: 1 /* {TcContinue4:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:5} */
function x24tcOpt_5($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ return {h: 1 /* {TcContinue5:1} */, a1: {a1: $0.a1, a2: $0.a2($0.a3.a1)}, a2: $0.a2, a3: $0.a3.a2};
  case 0: /* nil */ return {h: 0 /* {TcDone:5} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapAppend : SnocList b -> (a -> b) -> List a -> List b */
function Prelude_Types_List_mapAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_5, {h: 1 /* {TcContinue5:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:6} */
function x24tcOpt_6($0) {
 switch($0.a1) {
  case '': {
   switch($0.a2.h) {
    case 0: /* Nil */ return {h: 0 /* {TcDone:6} */, a1: ''};
    default: {
     const $6 = ($0.a2.a1+$0.a2.a2);
     switch(Prelude_Types_isSpace($0.a2.a1)) {
      case 1: return {h: 1 /* {TcContinue6:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
      case 0: return {h: 0 /* {TcDone:6} */, a1: $6};
     }
    }
   }
  }
  default: {
   const $11 = ($0.a2.a1+$0.a2.a2);
   switch(Prelude_Types_isSpace($0.a2.a1)) {
    case 1: return {h: 1 /* {TcContinue6:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
    case 0: return {h: 0 /* {TcDone:6} */, a1: $11};
   }
  }
 }
}

/* Data.String.with block in ltrim */
function Data_String_with__ltrim_9864($0, $1) {
 return __tailRec(x24tcOpt_6, {h: 1 /* {TcContinue6:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:7} */
function x24tcOpt_7($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:7} */, a1: Prelude_Types_List_reverse($0.a2)};
  case undefined: /* cons */ return {h: 1 /* {TcContinue7:1} */, a1: $0.a1, a2: Prelude_Types_List_reverseOnto($0.a2, $0.a1($0.a3.a1)), a3: $0.a3.a2};
 }
}

/* Prelude.Types.listBindOnto : (a -> List b) -> List b -> List a -> List b */
function Prelude_Types_listBindOnto($0, $1, $2) {
 return __tailRec(x24tcOpt_7, {h: 1 /* {TcContinue7:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:8} */
function x24tcOpt_8($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:8} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue8:1} */, a1: {a1: $0.a2.a1, a2: $0.a1}, a2: $0.a2.a2};
 }
}

/* Prelude.Types.List.reverseOnto : List a -> List a -> List a */
function Prelude_Types_List_reverseOnto($0, $1) {
 return __tailRec(x24tcOpt_8, {h: 1 /* {TcContinue8:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:9} */
function x24tcOpt_9($0) {
 switch($0.a1.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:9} */, a1: $0.a1.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue9:1} */, a1: $0.a1.a2};
 }
}

/* Data.List.last : (l : List a) -> {auto 0 _ : NonEmpty l} -> a */
function Data_List_last($0) {
 return __tailRec(x24tcOpt_9, {h: 1 /* {TcContinue9:1} */, a1: $0});
}

/* {$tcOpt:10} */
function x24tcOpt_10($0) {
 switch($0.a2) {
  case 0n: return {h: 0 /* {TcDone:10} */, a1: Prelude_Num_abs_Abs_Integer($0.a1)};
  default: return {h: 1 /* {TcContinue10:1} */, a1: $0.a2, a2: Prelude_Num_mod_Integral_Integer($0.a1, $0.a2)};
 }
}

/* Simplex.Twist.gcd : Integer -> Integer -> Integer */
function Simplex_Twist_gcd($0, $1) {
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
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:12} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue12:1} */, a1: $0.a1, a2: $0.a1($0.a2)($0.a3.a1), a3: $0.a3.a2};
 }
}

/* Prelude.Types.foldl */
function Prelude_Types_foldl_Foldable_List($0, $1, $2) {
 return __tailRec(x24tcOpt_12, {h: 1 /* {TcContinue12:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:13} */
function x24tcOpt_13($0) {
 switch($0.a4.h) {
  case 0: /* ZeroM */ return {h: 0 /* {TcDone:13} */, a1: $0.a3};
  case 1: /* AddM */ return {h: 1 /* {TcContinue13:1} */, a1: $0.a1, a2: $0.a2, a3: Math_Multiset_insertItem($0.a1, $0.a4.a1, $0.a4.a2, $0.a3), a4: $0.a4.a3};
 }
}

/* Math.Multiset.3702:1564:go */
function Math_Multiset_n__3702_1564_go($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_13, {h: 1 /* {TcContinue13:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* {$tcOpt:14} */
function x24tcOpt_14($0) {
 switch($0.a1.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:14} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue14:1} */, a1: $0.a1.a1, a2: {a1: $0.a1.a2, a2: $0.a2}};
 }
}

/* Prelude.Types.SnocList.(<>>) : SnocList a -> List a -> List a */
function Prelude_Types_SnocList_x3cx3ex3e($0, $1) {
 return __tailRec(x24tcOpt_14, {h: 1 /* {TcContinue14:1} */, a1: $0, a2: $1});
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
 return {a1: Math_BoxInt_intToBoxInt(0n), a2: Math_BoxInt_intToBoxInt(0n)};
});

/* {csegen:2} */
const csegen_2 = __lazy(function () {
 return c => Prelude_EqOrd_x3dx3d_Eq_Char(c, ';');
});

/* {csegen:8} */
const csegen_8 = __lazy(function () {
 return {a1: $1 => $2 => ($1+$2), a2: $6 => $7 => ($6*$7), a3: $b => $b};
});

/* {csegen:10} */
const csegen_10 = __lazy(function () {
 return {a1: csegen_8(), a2: $3 => (0n-$3), a3: $7 => $8 => ($7-$8)};
});

/* {csegen:14} */
const csegen_14 = __lazy(function () {
 return {a1: csegen_8(), a2: {a1: $4 => $5 => Prelude_EqOrd_x3dx3d_Eq_Integer($4, $5), a2: $a => $b => Prelude_EqOrd_x2fx3d_Eq_Integer($a, $b)}};
});

/* {csegen:16} */
const csegen_16 = __lazy(function () {
 return {a1: {a1: $2 => $3 => Math_BoxInt_x3dx3d_Eq_SignedUnit($2, $3), a2: $8 => $9 => Math_BoxInt_x2fx3d_Eq_SignedUnit($8, $9)}, a2: {a1: csegen_10(), a2: csegen_14()}};
});

/* {csegen:19} */
const csegen_19 = __lazy(function () {
 return {a1: $1 => $2 => Math_Multiset_x3dx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29(csegen_16(), $1, $2), a2: $9 => $a => Math_Multiset_x2fx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29(csegen_16(), $9, $a)};
});

/* {csegen:22} */
const csegen_22 = __lazy(function () {
 return {a1: $1 => $2 => Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $1, $2), a2: $9 => $a => Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $9, $a)};
});

/* {csegen:25} */
const csegen_25 = __lazy(function () {
 return {a1: $1 => $2 => (($1===$2)?1:0), a2: $6 => $7 => Prelude_Types_x2fx3d_Eq_Nat($6, $7)};
});

/* {csegen:28} */
const csegen_28 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_25(), csegen_25(), $1, $2), a2: $b => $c => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_25(), csegen_25(), $b, $c)};
});

/* {csegen:31} */
const csegen_31 = __lazy(function () {
 return {a1: $1 => $2 => Math_BoxInt_boxAdd($1, $2), a2: $7 => $8 => Math_BoxInt_boxMult($7, $8), a3: $d => Math_BoxInt_intToBoxInt($d)};
});

/* {csegen:33} */
const csegen_33 = __lazy(function () {
 return {a1: csegen_31(), a2: $3 => Math_BoxInt_boxNegate($3), a3: $7 => $8 => Math_BoxInt_boxSub($7, $8)};
});

/* {csegen:34} */
const csegen_34 = __lazy(function () {
 return {a1: csegen_31(), a2: csegen_19()};
});

/* {csegen:36} */
const csegen_36 = __lazy(function () {
 return {a1: csegen_28(), a2: {a1: csegen_33(), a2: csegen_34()}};
});

/* {csegen:39} */
const csegen_39 = __lazy(function () {
 return {a1: $1 => $2 => Math_Multiset_x3dx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29(csegen_36(), $1, $2), a2: $9 => $a => Math_Multiset_x2fx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29(csegen_36(), $9, $a)};
});

/* {csegen:43} */
const csegen_43 = __lazy(function () {
 return {a1: {a1: $2 => $3 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_22(), csegen_39(), $2, $3), a2: $c => $d => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_22(), csegen_39(), $c, $d)}, a2: csegen_14()};
});

/* {csegen:46} */
const csegen_46 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_22(), csegen_22(), $1, $2), a2: $b => $c => Prelude_EqOrd_x2fx3d_Eq_x28x7cx28x28Builtinx2ePairx20x24ax29x20x24bx29x2cx28x28Builtinx2eMkPairx20x24ax29x20x24bx29x7cx29(csegen_22(), csegen_22(), $b, $c)};
});

/* {csegen:47} */
const csegen_47 = __lazy(function () {
 return {a1: csegen_46(), a2: csegen_14()};
});

/* {csegen:48} */
const csegen_48 = __lazy(function () {
 return c => Prelude_EqOrd_x3dx3d_Eq_Char(c, ':');
});

/* {csegen:49} */
const csegen_49 = __lazy(function () {
 return {a1: csegen_28(), a2: csegen_34()};
});

/* {csegen:58} */
const csegen_58 = __lazy(function () {
 const $a = b => a => $b => $c => $d => {
  const $e = $b($d);
  const $11 = $c($d);
  return $e($11);
 };
 return {a1: b => a => func => $1 => $2 => Prelude_IO_map_Functor_IO(func, $1, $2), a2: a => $8 => $9 => $8, a3: $a};
});

/* {csegen:73} */
const csegen_73 = __lazy(function () {
 return {a1: acc => elem => func => init => input => Prelude_Types_foldr_Foldable_List(func, init, input), a2: elem => acc => func => init => input => Prelude_Types_foldl_Foldable_List(func, init, input), a3: elem => $b => Prelude_Types_null_Foldable_List($b), a4: elem => acc => m => $f => funcM => init => input => Prelude_Types_foldlM_Foldable_List($f, funcM, init, input), a5: elem => $16 => $16, a6: a => m => $18 => f => $19 => Prelude_Types_foldMap_Foldable_List($18, f, $19)};
});

/* {csegen:79} */
const csegen_79 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_Interfaces_Bool_Semigroup_x3cx2bx3e_Semigroup_AnyBool($1, $2), a2: 0};
});

/* {csegen:82} */
const csegen_82 = __lazy(function () {
 return $0 => $1 => Simplex_Twist_addRationalLocal($0, $1);
});

/* {csegen:93} */
const csegen_93 = __lazy(function () {
 return {a1: {a1: b => a => func => $2 => Prelude_Types_List_mapAppend({h: 0}, func, $2), a2: a => $8 => Prelude_Types_pure_Applicative_List($8), a3: b => a => $c => $d => Prelude_Types_x3cx2ax3e_Applicative_List($c, $d)}, a2: a => ({h: 0}), a3: a => $13 => $14 => Prelude_Types_List_tailRecAppend($13, $14())};
});

/* {csegen:95} */
const csegen_95 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_Types_List_tailRecAppend($1, $2), a2: {h: 0}};
});

/* {csegen:99} */
const csegen_99 = __lazy(function () {
 return Math_SpreadPolynumber_scalarMul(2n, Math_SpreadPolynumber_sPoly());
});

/* {csegen:100} */
const csegen_100 = __lazy(function () {
 return Math_IntPolynumber_subIntPoly(Math_SpreadPolynumber_onePoly(), csegen_99());
});

/* {csegen:103} */
const csegen_103 = __lazy(function () {
 return {a1: csegen_8(), a2: {a1: csegen_8(), a2: $6 => Prelude_Num_abs_Abs_Integer($6)}};
});

/* prim__sub_Integer : Integer -> Integer -> Integer */
function prim__sub_Integer($0, $1) {
 return ($0-$1);
}

/* JSBridge.case block in parseMaxelItem */
function JSBridge_case__parseMaxelItem_5391($0, $1) {
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
               const $d = {a1: Math_BoxInt_intToBoxInt(JSBridge_parseInt($6.a1)), a2: Math_BoxInt_intToBoxInt(JSBridge_parseInt($6.a2.a1))};
               const $18 = JSBridge_parseInt($1.a2.a1);
               const $1b = JSBridge_parseAmplitude($1.a2.a2.a1);
               return {a1: {a1: {a1: $d, a2: $1b}, a2: $18}};
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
                case 0: /* nil */ return {a1: {a1: {a1: {a1: Math_BoxInt_intToBoxInt(JSBridge_parseInt($5.a1)), a2: Math_BoxInt_intToBoxInt(JSBridge_parseInt($5.a2.a1))}, a2: {a1: Math_BoxInt_intToBoxInt(JSBridge_parseInt($5.a2.a2.a1)), a2: Math_BoxInt_intToBoxInt(JSBridge_parseInt($5.a2.a2.a2.a1))}}, a2: JSBridge_parseInt($1.a2.a1)}};
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

/* JSBridge.stepUniverseLocalizedBridge : String -> String -> String -> String -> IO () */
function JSBridge_stepUniverseLocalizedBridge($0, $1, $2, $3) {
 const $4 = JSBridge_parseNat($0);
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
 const $f = JSBridge_parseVexel($3);
 const $12 = Evolution_LocalSpreadPolynumber_stepUniverseLocalized($4, $a, $c, $f);
 const $18 = {a1: $12.a1, a2: $12.a2};
 return $1b => JSBridge_exportUniverseState($18, $1b);
}

/* JSBridge.splitList : (Char -> Bool) -> String -> List String */
function JSBridge_splitList($0, $1) {
 return Data_String_split($0, $1);
}

/* JSBridge.runAdaptiveCycleBridge : String -> String -> String -> String -> String -> IO () */
function JSBridge_runAdaptiveCycleBridge($0, $1, $2, $3, $4) {
 const $5 = JSBridge_parseNat($0);
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
       $d = {a1: Math_BoxInt_intToBoxInt(JSBridge_parseInt($e.a1)), a2: Math_BoxInt_intToBoxInt(JSBridge_parseInt($e.a2.a1))};
       break;
      }
      default: $d = csegen_1();
     }
     break;
    }
    default: $d = csegen_1();
   }
   break;
  }
  default: $d = csegen_1();
 }
 const $22 = JSBridge_parseSubstrate($3);
 const $25 = JSBridge_parseVexel($4);
 const $28 = {a1: $22, a2: $25};
 const $2b = Evolution_Cycle_runAdaptiveCycle($5, $b, $d, $28);
 return $31 => JSBridge_exportUniverseState($2b, $31);
}

/* JSBridge.pushMaxel : Integer -> Integer -> Nat -> Nat -> Integer -> IO () */
function JSBridge_pushMaxel($0, $1, $2, $3, $4, $5) {
 return JSBridge_prim_pushMaxel(Number(_truncBigInt32($0)), Number(_truncBigInt32($1)), Number(_truncBigInt32($2)), Number(_truncBigInt32($3)), Number(_truncBigInt32($4)), $5);
}

/* JSBridge.pushEdge : Integer -> Integer -> Integer -> Integer -> Integer -> IO () */
function JSBridge_pushEdge($0, $1, $2, $3, $4, $5) {
 return JSBridge_prim_pushEdge(Number(_truncBigInt32($0)), Number(_truncBigInt32($1)), Number(_truncBigInt32($2)), Number(_truncBigInt32($3)), Number(_truncBigInt32($4)), $5);
}

/* JSBridge.parseVexel : String -> Vexel */
function JSBridge_parseVexel($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, '')) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: {
   const $5 = JSBridge_splitList(csegen_2(), $0);
   const $a = Prelude_Types_List_mapMaybeAppend({h: 0}, $e => JSBridge_parseMaxelItem($e), $5);
   return Math_Multiset_fromList(csegen_43(), $a);
  }
 }
}

/* JSBridge.parseTerms : List String -> List ((Nat, Nat), BoxInt) */
function JSBridge_parseTerms($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ {
   switch($0.a2.h) {
    case undefined: /* cons */ {
     switch($0.a2.a2.h) {
      case undefined: /* cons */ return {a1: {a1: {a1: JSBridge_parseNat($0.a1), a2: JSBridge_parseNat($0.a2.a1)}, a2: Math_BoxInt_intToBoxInt(JSBridge_parseInt($0.a2.a2.a1))}, a2: JSBridge_parseTerms($0.a2.a2.a2)};
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
   const $5 = JSBridge_splitList(csegen_2(), $0);
   const $a = Prelude_Types_List_mapMaybeAppend({h: 0}, $e => JSBridge_parseEdge($e), $5);
   return Math_Multiset_fromList(csegen_47(), $a);
  }
 }
}

/* JSBridge.parseNat : String -> Nat */
function JSBridge_parseNat($0) {
 return Prelude_Types_prim__integerToNat(JSBridge_parseInt($0));
}

/* JSBridge.parseMaxelItem : String -> Maybe ((Geometry, Amplitude), Integer) */
function JSBridge_parseMaxelItem($0) {
 return JSBridge_case__parseMaxelItem_5391($0, JSBridge_splitList(csegen_48(), $0));
}

/* JSBridge.parseInt : String -> Integer */
function JSBridge_parseInt($0) {
 const $1 = Data_String_parseInteger(csegen_8(), csegen_10(), $0);
 switch($1.h) {
  case undefined: /* just */ return $1.a1;
  case 0: /* nothing */ return 0n;
 }
}

/* JSBridge.parseEdge : String -> Maybe ((Geometry, Geometry), Integer) */
function JSBridge_parseEdge($0) {
 return JSBridge_case__parseEdge_5106($0, JSBridge_splitList(csegen_48(), $0));
}

/* JSBridge.parseAmplitude : String -> Amplitude */
function JSBridge_parseAmplitude($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, '')) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: return Math_Multiset_fromList(csegen_49(), JSBridge_parseTerms(JSBridge_splitList(csegen_0(), $0)));
 }
}

/* JSBridge.main : IO () */
function JSBridge_main($0) {
 const $1 = JSBridge_prim_exportFunction('idris_runAdaptiveCycle', a => b => c => d => e => JSBridge_runAdaptiveCycleBridge(a, b, c, d, e), $0);
 const $c = JSBridge_prim_exportFunction4('idris_stepUniverseLocalized', a => b => c => d => JSBridge_stepUniverseLocalizedBridge(a, b, c, d), $0);
 return Prelude_IO_prim__putStr('Idris physics engine JSBridge initialized successfully!\n', $0);
}

/* JSBridge.exportVexel : Vexel -> IO () */
function JSBridge_exportVexel($0) {
 const $7 = $8 => {
  const $c = Math_BoxInt_boxToInt($8.a1.a1.a1);
  const $f = Math_BoxInt_boxToInt($8.a1.a1.a2);
  const $18 = $19 => {
   const $1c = Math_BoxInt_boxToInt($19.a2);
   return $1f => JSBridge_pushMaxel($c, $f, $19.a1.a1, $19.a1.a2, ($1c*$8.a2), $1f);
  };
  const $12 = Prelude_Interfaces_traverse_(csegen_58(), csegen_73(), $18);
  return $12(Math_Multiset_multisetToList($8.a1.a2));
 };
 const $1 = Prelude_Interfaces_traverse_(csegen_58(), csegen_73(), $7);
 return $1(Math_Multiset_multisetToList($0));
}

/* JSBridge.exportUniverseState : UniverseState -> IO () */
function JSBridge_exportUniverseState($0, $1) {
 const $3 = JSBridge_clearBuffers($1);
 const $6 = JSBridge_exportSubstrate($0.a1)($1);
 return JSBridge_exportVexel($0.a2)($1);
}

/* JSBridge.exportSubstrate : Substrate -> IO () */
function JSBridge_exportSubstrate($0) {
 const $7 = $8 => {
  const $d = Math_BoxInt_boxToInt($8.a1.a1.a1);
  const $10 = Math_BoxInt_boxToInt($8.a1.a1.a2);
  const $13 = Math_BoxInt_boxToInt($8.a1.a2.a1);
  const $16 = Math_BoxInt_boxToInt($8.a1.a2.a2);
  return $19 => JSBridge_pushEdge($d, $10, $13, $16, $8.a2, $19);
 };
 const $1 = Prelude_Interfaces_traverse_(csegen_58(), csegen_73(), $7);
 return $1(Math_Multiset_multisetToList($0));
}

/* JSBridge.clearBuffers : IO () */
function JSBridge_clearBuffers($0) {
 return JSBridge_prim_clearBuffers($0);
}

/* Data.List1.map */
function Data_List1_map_Functor_List1($0, $1) {
 return {a1: $0($1.a1), a2: Prelude_Types_List_mapAppend({h: 0}, $0, $1.a2)};
}

/* Data.List1.singleton : a -> List1 a */
function Data_List1_singleton($0) {
 return {a1: $0, a2: {h: 0}};
}

/* Prelude.Basics.flip : (a -> b -> c) -> b -> a -> c */
function Prelude_Basics_flip($0, $1, $2) {
 return $0($2)($1);
}

/* Builtin.snd : (a, b) -> b */
function Builtin_snd($0) {
 return $0.a2;
}

/* Builtin.fst : (a, b) -> a */
function Builtin_fst($0) {
 return $0.a1;
}

/* Prelude.Types.pure */
function Prelude_Types_pure_Applicative_List($0) {
 return {a1: $0, a2: {h: 0}};
}

/* Prelude.Types.null */
function Prelude_Types_null_Foldable_List($0) {
 switch($0.h) {
  case 0: /* nil */ return 1;
  case undefined: /* cons */ return 0;
 }
}

/* Prelude.Types.max */
function Prelude_Types_max_Ord_Nat($0, $1) {
 switch(Prelude_Types_x3e_Ord_Nat($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.Types.map */
function Prelude_Types_map_Functor_Maybe($0, $1) {
 switch($1.h) {
  case undefined: /* just */ return {a1: $0($1.a1)};
  case 0: /* nothing */ return {h: 0};
 }
}

/* Prelude.Types.foldr */
function Prelude_Types_foldr_Foldable_List($0, $1, $2) {
 switch($2.h) {
  case 0: /* nil */ return $1;
  case undefined: /* cons */ return $0($2.a1)(Prelude_Types_foldr_Foldable_List($0, $1, $2.a2));
 }
}

/* Prelude.Types.foldlM */
function Prelude_Types_foldlM_Foldable_List($0, $1, $2, $3) {
 return Prelude_Types_foldl_Foldable_List(ma => b => $0.a2(undefined)(undefined)(ma)($f => Prelude_Basics_flip($1, b, $f)), $0.a1.a2(undefined)($2), $3);
}

/* Prelude.Types.foldMap */
function Prelude_Types_foldMap_Foldable_List($0, $1, $2) {
 return Prelude_Types_foldl_Foldable_List(acc => elem => $0.a1(acc)($1(elem)), $0.a2, $2);
}

/* Prelude.Types.> */
function Prelude_Types_x3e_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x3dx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 2);
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

/* Prelude.Types.elemBy : Foldable t => (a -> a -> Bool) -> a -> t a -> Bool */
function Prelude_Types_elemBy($0, $1, $2) {
 return $0.a6(undefined)(undefined)(csegen_79())($1($2));
}

/* Prelude.Types.elem : Foldable t => Eq a => a -> t a -> Bool */
function Prelude_Types_elem($0, $1, $2) {
 return Prelude_Types_elemBy($0, $1.a1, $2);
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
function Prelude_EqOrd_x3cx3d_Ord_Integer($0, $1) {
 switch((($0<=$1)?1:0)) {
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

/* Prelude.Interfaces.Bool.Semigroup.<+> */
function Prelude_Interfaces_Bool_Semigroup_x3cx2bx3e_Semigroup_AnyBool($0, $1) {
 switch($0) {
  case 1: return 1;
  case 0: return $1;
 }
}

/* Prelude.Interfaces.traverse_ : Applicative f => Foldable t => (a -> f b) -> t a -> f () */
function Prelude_Interfaces_traverse_($0, $1, $2) {
 return $1.a1(undefined)(undefined)($b => $c => Prelude_Interfaces_x2ax3e($0, $2($b), $c))($0.a2(undefined)(undefined));
}

/* Prelude.Interfaces.guard : Alternative f => Bool -> f () */
function Prelude_Interfaces_guard($0, $1) {
 switch($1) {
  case 1: return $0.a1.a2(undefined)(undefined);
  case 0: return $0.a2(undefined);
 }
}

/* Prelude.Interfaces.(*>) : Applicative f => f a -> f b -> f b */
function Prelude_Interfaces_x2ax3e($0, $1, $2) {
 const $d = $0.a1;
 const $c = $d(undefined)(undefined);
 const $b = $c($14 => $15 => $15);
 const $a = $b($1);
 const $4 = $0.a3(undefined)(undefined)($a);
 return $4($2);
}

/* Prelude.IO.map */
function Prelude_IO_map_Functor_IO($0, $1, $2) {
 const $3 = $1($2);
 return $0($3);
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

/* Data.List.nubBy : (a -> a -> Bool) -> List a -> List a */
function Data_List_nubBy($0, $1) {
 return Data_List_n__4934_5733_nubByx27({h: 0}, $0, $1);
}

/* Data.List.nub : Eq a => List a -> List a */
function Data_List_nub($0, $1) {
 return Data_List_nubBy($0.a1, $1);
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

/* Math.Multiset.3952:1854:isEmpty */
function Math_Multiset_n__3952_1854_isEmpty($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* ZeroM */ return 1;
  default: return 0;
 }
}

/* Math.Multiset.3788:1647:go */
function Math_Multiset_n__3788_1647_go($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ {
   const $7 = Builtin_fst($0);
   const $6 = $7.a2($3.a2)($1);
   return {h: 1 /* AddM */, a1: $3.a1, a2: $6, a3: Math_Multiset_n__3788_1647_go($0, $1, $2, $3.a3)};
  }
 }
}

/* Math.Multiset.== */
function Math_Multiset_x3dx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29($0, $1, $2) {
 const $3 = Math_Multiset_annihilateMultiset({a1: Builtin_fst($0), a2: Builtin_snd(Builtin_snd($0))}, Math_Multiset_addMultiset($1, Math_Multiset_negateMultiset(Builtin_fst(Builtin_snd($0)), $2)));
 return Math_Multiset_n__3952_1854_isEmpty($0, $2, $1, $3);
}

/* Math.Multiset./= */
function Math_Multiset_x2fx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29($0, $1, $2) {
 switch(Math_Multiset_x3dx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29($0, $1, $2)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Math.Multiset.subMultiset : Neg c => Multiset c a -> Multiset c a -> Multiset c a */
function Math_Multiset_subMultiset($0, $1, $2) {
 return Math_Multiset_addMultiset($1, Math_Multiset_negateMultiset($0, $2));
}

/* Math.Multiset.scaleMultiset : (Num c, Eq c) => c -> Multiset c a -> Multiset c a */
function Math_Multiset_scaleMultiset($0, $1, $2) {
 const $4 = Builtin_snd($0);
 const $b = Builtin_fst($0);
 const $a = $b.a3(0n);
 const $3 = $4.a1($1)($a);
 switch($3) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: return Math_Multiset_n__3788_1647_go($0, $1, $2, $2);
 }
}

/* Math.Multiset.negateMultiset : Neg c => Multiset c a -> Multiset c a */
function Math_Multiset_negateMultiset($0, $1) {
 switch($1.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: $1.a1, a2: $0.a2($1.a2), a3: Math_Multiset_negateMultiset($0, $1.a3)};
 }
}

/* Math.Multiset.multisetToList : Multiset c a -> List (a, c) */
function Math_Multiset_multisetToList($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return {h: 0};
  case 1: /* AddM */ return {a1: {a1: $0.a1, a2: $0.a2}, a2: Math_Multiset_multisetToList($0.a3)};
 }
}

/* Math.Multiset.multiplicityAll : (Num c, Abs c) => Multiset c a -> c */
function Math_Multiset_multiplicityAll($0, $1) {
 switch($1.h) {
  case 0: /* ZeroM */ {
   const $3 = Builtin_fst($0);
   return $3.a3(0n);
  }
  case 1: /* AddM */ {
   const $8 = Builtin_fst($0);
   const $e = Builtin_snd($0);
   const $d = $e.a2($1.a2);
   const $b = $8.a1($d);
   return $b(Math_Multiset_multiplicityAll($0, $1.a3));
  }
 }
}

/* Math.Multiset.insertItem : (Eq a, (Num c, Eq c)) => a -> c -> Multiset c a -> Multiset c a */
function Math_Multiset_insertItem($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* ZeroM */ return {h: 1 /* AddM */, a1: $1, a2: $2, a3: {h: 0 /* ZeroM */}};
  case 1: /* AddM */ {
   const $9 = Builtin_fst($0);
   const $8 = $9.a1($1)($3.a1);
   switch($8) {
    case 1: {
     const $11 = Builtin_fst(Builtin_snd($0));
     const $10 = $11.a1($2)($3.a2);
     const $1b = Builtin_snd(Builtin_snd($0));
     const $24 = Builtin_fst(Builtin_snd($0));
     const $23 = $24.a3(0n);
     const $1a = $1b.a1($10)($23);
     switch($1a) {
      case 1: return $3.a3;
      case 0: return {h: 1 /* AddM */, a1: $1, a2: $10, a3: $3.a3};
     }
    }
    case 0: return {h: 1 /* AddM */, a1: $3.a1, a2: $3.a2, a3: Math_Multiset_insertItem($0, $1, $2, $3.a3)};
   }
  }
 }
}

/* Math.Multiset.fromList : (Eq a, (Num c, Eq c)) => List (a, c) -> Multiset c a */
function Math_Multiset_fromList($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {h: 0 /* ZeroM */};
  case undefined: /* cons */ return Math_Multiset_insertItem($0, $1.a1.a1, $1.a1.a2, Math_Multiset_fromList($0, $1.a2));
 }
}

/* Math.Multiset.annihilateMultiset : (Eq a, (Num c, Eq c)) => Multiset c a -> Multiset c a */
function Math_Multiset_annihilateMultiset($0, $1) {
 return Math_Multiset_n__3702_1564_go($0, $1, {h: 0 /* ZeroM */}, $1);
}

/* Math.Multiset.addMultiset : Multiset c a -> Multiset c a -> Multiset c a */
function Math_Multiset_addMultiset($0, $1) {
 switch($0.h) {
  case 0: /* ZeroM */ return $1;
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: $0.a1, a2: $0.a2, a3: Math_Multiset_addMultiset($0.a3, $1)};
 }
}

/* Math.Pixel.== */
function Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29($0, $1, $2) {
 switch($0.a1($1.a1)($2.a1)) {
  case 1: return $0.a1($1.a2)($2.a2);
  case 0: return 0;
 }
}

/* Math.Pixel./= */
function Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29($0, $1, $2) {
 switch(Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29($0, $1, $2)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Math.Chromogeometry.spreadNL : (metric : Metric) ->
Pixel metric BoxInt -> Pixel metric BoxInt -> Pixel metric BoxInt -> (BoxInt,
BoxInt) */
function Math_Chromogeometry_spreadNL($0, $1, $2, $3) {
 const $4 = Math_Chromogeometry_quadranceNL($0, $1, $2);
 const $9 = Math_Chromogeometry_quadranceNL($0, $3, $1);
 const $e = Math_Chromogeometry_archimedesNL($0, $1, $2, $3);
 const $14 = Math_BoxInt_boxMult(Math_BoxInt_boxMult(Math_BoxInt_intToBoxInt(4n), $4), $9);
 return {a1: $e, a2: $14};
}

/* Math.Chromogeometry.quadranceNL : (metric : Metric) -> Pixel metric BoxInt -> Pixel metric BoxInt -> BoxInt */
function Math_Chromogeometry_quadranceNL($0, $1, $2) {
 const $3 = Math_Chromogeometry_boundaryNL($0, $1, $2);
 switch($0) {
  case 0: return Math_BoxInt_boxAdd(Math_BoxInt_boxMult($3.a1, $3.a1), Math_BoxInt_boxMult($3.a2, $3.a2));
  case 1: return Math_BoxInt_boxSub(Math_BoxInt_boxMult($3.a1, $3.a1), Math_BoxInt_boxMult($3.a2, $3.a2));
  case 2: return Math_BoxInt_boxMult(Math_BoxInt_boxMult(Math_BoxInt_intToBoxInt(2n), $3.a1), $3.a2);
 }
}

/* Math.Chromogeometry.boundaryNL : Pixel metric BoxInt -> Pixel metric BoxInt -> Pixel metric BoxInt */
function Math_Chromogeometry_boundaryNL($0, $1, $2) {
 return {a1: Math_BoxInt_boxSub($2.a1, $1.a1), a2: Math_BoxInt_boxSub($2.a2, $1.a2)};
}

/* Math.Chromogeometry.archimedesNL : (metric : Metric) ->
Pixel metric BoxInt -> Pixel metric BoxInt -> Pixel metric BoxInt -> BoxInt */
function Math_Chromogeometry_archimedesNL($0, $1, $2, $3) {
 switch($0) {
  case 0: return Math_Chromogeometry_archimedesBlueNL($1, $2, $3);
  case 1: return Math_BoxInt_boxNegate(Math_Chromogeometry_archimedesBlueNL($1, $2, $3));
  case 2: return Math_BoxInt_boxNegate(Math_Chromogeometry_archimedesBlueNL($1, $2, $3));
 }
}

/* Math.Chromogeometry.archimedesBlueNL : Pixel Blue BoxInt -> Pixel Blue BoxInt -> Pixel Blue BoxInt -> BoxInt */
function Math_Chromogeometry_archimedesBlueNL($0, $1, $2) {
 const $3 = Math_Chromogeometry_quadranceNL(0, $0, $1);
 const $8 = Math_Chromogeometry_quadranceNL(0, $1, $2);
 const $d = Math_Chromogeometry_quadranceNL(0, $2, $0);
 const $12 = Math_BoxInt_boxAdd(Math_BoxInt_boxAdd($3, $8), $d);
 return Math_BoxInt_boxSub(Math_BoxInt_boxMult($12, $12), Math_BoxInt_boxMult(Math_BoxInt_intToBoxInt(2n), Math_BoxInt_boxAdd(Math_BoxInt_boxAdd(Math_BoxInt_boxMult($3, $3), Math_BoxInt_boxMult($8, $8)), Math_BoxInt_boxMult($d, $d))));
}

/* Math.BoxInt.compare */
function Math_BoxInt_compare_Ord_BoxInt($0, $1) {
 const $2 = Math_BoxInt_boxToInt($0);
 const $5 = Math_BoxInt_boxToInt($1);
 return Prelude_EqOrd_compare_Ord_Integer($2, $5);
}

/* Math.BoxInt.>= */
function Math_BoxInt_x3ex3d_Ord_BoxInt($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Math_BoxInt_compare_Ord_BoxInt($0, $1), 0);
}

/* Math.BoxInt.== */
function Math_BoxInt_x3dx3d_Eq_SignedUnit($0, $1) {
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
  default: return 0;
 }
}

/* Math.BoxInt./= */
function Math_BoxInt_x2fx3d_Eq_SignedUnit($0, $1) {
 switch(Math_BoxInt_x3dx3d_Eq_SignedUnit($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Math.BoxInt.normalizeBoxInt : BoxInt -> BoxInt */
function Math_BoxInt_normalizeBoxInt($0) {
 const $1 = Math_Multiset_multisetToList($0);
 const $6 = acc => $7 => {
  switch(Math_BoxInt_x3dx3d_Eq_SignedUnit($7.a1, 0)) {
   case 1: return (acc+$7.a2);
   case 0: return acc;
  }
 };
 const $4 = Prelude_Types_foldl_Foldable_List($6, 0n, $1);
 const $13 = acc => $14 => {
  switch(Math_BoxInt_x3dx3d_Eq_SignedUnit($14.a1, 1)) {
   case 1: return (acc+$14.a2);
   case 0: return acc;
  }
 };
 const $11 = Prelude_Types_foldl_Foldable_List($13, 0n, $1);
 const $1e = ($4-$11);
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($1e, 0n)) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: {
   switch(Prelude_EqOrd_x3e_Ord_Integer($1e, 0n)) {
    case 1: return {h: 1 /* AddM */, a1: 0, a2: $1e, a3: {h: 0 /* ZeroM */}};
    case 0: return {h: 1 /* AddM */, a1: 1, a2: (0n-$1e), a3: {h: 0 /* ZeroM */}};
   }
  }
 }
}

/* Math.BoxInt.intToBoxInt : Integer -> BoxInt */
function Math_BoxInt_intToBoxInt($0) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, 0n)) {
  case 1: return {h: 0 /* ZeroM */};
  case 0: {
   switch(Prelude_EqOrd_x3e_Ord_Integer($0, 0n)) {
    case 1: return {h: 1 /* AddM */, a1: 0, a2: $0, a3: {h: 0 /* ZeroM */}};
    case 0: return {h: 1 /* AddM */, a1: 1, a2: (0n-$0), a3: {h: 0 /* ZeroM */}};
   }
  }
 }
}

/* Math.BoxInt.boxToInt : (1 _ : BoxInt) -> Ur Integer */
function Math_BoxInt_boxToInt($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return 0n;
  case 1: /* AddM */ {
   switch($0.a1) {
    case 0: {
     const $3 = Math_BoxInt_boxToInt($0.a3);
     return ($0.a2+$3);
    }
    case 1: {
     const $8 = Math_BoxInt_boxToInt($0.a3);
     return ((0n-$0.a2)+$8);
    }
   }
  }
 }
}

/* Math.BoxInt.boxSub : BoxInt -> BoxInt -> BoxInt */
function Math_BoxInt_boxSub($0, $1) {
 return Math_BoxInt_boxAdd($0, Math_BoxInt_boxNegate($1));
}

/* Math.BoxInt.boxNegate : BoxInt -> BoxInt */
function Math_BoxInt_boxNegate($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ {
   switch($0.a1) {
    case 0: return {h: 1 /* AddM */, a1: 1, a2: $0.a2, a3: Math_BoxInt_boxNegate($0.a3)};
    case 1: return {h: 1 /* AddM */, a1: 0, a2: $0.a2, a3: Math_BoxInt_boxNegate($0.a3)};
   }
  }
 }
}

/* Math.BoxInt.boxMult : BoxInt -> BoxInt -> BoxInt */
function Math_BoxInt_boxMult($0, $1) {
 const $2 = Math_BoxInt_boxToInt($0);
 const $5 = Math_BoxInt_boxToInt($1);
 return Math_BoxInt_intToBoxInt(($2*$5));
}

/* Math.BoxInt.boxAdd : BoxInt -> BoxInt -> BoxInt */
function Math_BoxInt_boxAdd($0, $1) {
 return Math_BoxInt_normalizeBoxInt(Math_Multiset_addMultiset($0, $1));
}

/* Simplex.Twist.case block in chromogeometricHorizon,loopAtHorizon */
function Simplex_Twist_case__chromogeometricHorizonx2cloopAtHorizon_6427($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b, $c) {
 switch(Prelude_EqOrd_x3cx3d_Ord_Integer($c.a2, 0n)) {
  case 1: return 0;
  case 0: return Prelude_EqOrd_x3ex3d_Ord_Integer($c.a1, ($c.a2*2n));
 }
}

/* Simplex.Twist.case block in recipSpreadNL */
function Simplex_Twist_case__recipSpreadNL_6039($0, $1, $2, $3) {
 const $5 = Math_BoxInt_boxToInt($3.a1);
 const $8 = Math_BoxInt_boxToInt($3.a2);
 switch(Prelude_EqOrd_x3dx3d_Eq_Integer($5, 0n)) {
  case 1: return {a1: 0n, a2: 1n};
  case 0: return {a1: $8, a2: $5};
 }
}

/* Simplex.Twist.7813:6366:loopAtHorizon */
function Simplex_Twist_n__7813_6366_loopAtHorizon($0, $1, $2, $3, $4) {
 const $8 = Simplex_Twist_recipSpreadNL($4.a1, $4.a2.a2.a2, $4.a2.a1);
 const $d = Simplex_Twist_recipSpreadNL($4.a2.a1, $4.a1, $4.a2.a2.a1);
 const $12 = Simplex_Twist_recipSpreadNL($4.a2.a2.a1, $4.a2.a1, $4.a2.a2.a2);
 const $17 = Simplex_Twist_recipSpreadNL($4.a2.a2.a2, $4.a2.a2.a1, $4.a1);
 return Simplex_Twist_case__chromogeometricHorizonx2cloopAtHorizon_6427($0, $1, $2, $3, $4.a1, $4.a2.a1, $4.a2.a2.a1, $4.a2.a2.a2, $8, $d, $12, $17, Prelude_Types_foldl_Foldable_List(csegen_82(), {a1: 0n, a2: 1n}, {a1: $8, a2: {a1: $d, a2: {a1: $12, a2: {a1: $17, a2: {h: 0}}}}}));
}

/* Simplex.Twist.recipSpreadNL : Geometry -> Geometry -> Geometry -> (Integer, Integer) */
function Simplex_Twist_recipSpreadNL($0, $1, $2) {
 return Simplex_Twist_case__recipSpreadNL_6039($2, $1, $0, Math_Chromogeometry_spreadNL(0, $0, $1, $2));
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

/* Simplex.Twist.connected : List (Geometry, Geometry) -> Geometry -> Geometry -> Bool */
function Simplex_Twist_connected($0, $1, $2) {
 switch(Prelude_Types_elem(csegen_73(), csegen_46(), {a1: $1, a2: $2})($0)) {
  case 1: return 1;
  case 0: return Prelude_Types_elem(csegen_73(), csegen_46(), {a1: $2, a2: $1})($0);
 }
}

/* Simplex.Twist.chromogeometricHorizon : Substrate -> Bool */
function Simplex_Twist_chromogeometricHorizon($0) {
 const $1 = Prelude_Types_List_mapAppend({h: 0}, $5 => Builtin_fst($5), Math_Multiset_multisetToList($0));
 const $b = Simplex_Core_substrateNodes($0);
 const $11 = p1 => {
  const $14 = p2 => {
   const $17 = p3 => {
    const $1a = p4 => {
     let $20;
     switch(Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p1, p2)) {
      case 1: {
       switch(Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p2, p3)) {
        case 1: {
         switch(Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p3, p4)) {
          case 1: {
           switch(Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p4, p1)) {
            case 1: {
             switch(Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p1, p3)) {
              case 1: {
               $20 = Math_Pixel_x2fx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), p2, p4);
               break;
              }
              case 0: {
               $20 = 0;
               break;
              }
             }
             break;
            }
            case 0: {
             $20 = 0;
             break;
            }
           }
           break;
          }
          case 0: {
           $20 = 0;
           break;
          }
         }
         break;
        }
        case 0: {
         $20 = 0;
         break;
        }
       }
       break;
      }
      case 0: {
       $20 = 0;
       break;
      }
     }
     const $1c = Prelude_Interfaces_guard(csegen_93(), $20);
     return Prelude_Types_listBind($1c, $45 => Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_93(), Simplex_Twist_connected($1, p1, p2)), $51 => Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_93(), Simplex_Twist_connected($1, p2, p3)), $5d => Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_93(), Simplex_Twist_connected($1, p3, p4)), $69 => Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_93(), Simplex_Twist_connected($1, p4, p1)), $75 => Prelude_Types_pure_Applicative_List({a1: p1, a2: {a1: p2, a2: {a1: p3, a2: p4}}}))))));
    };
    return Prelude_Types_listBind($b, $1a);
   };
   return Prelude_Types_listBind($b, $17);
  };
  return Prelude_Types_listBind($b, $14);
 };
 const $e = Prelude_Types_listBind($b, $11);
 return Prelude_Types_foldMap_Foldable_List(csegen_79(), $82 => Simplex_Twist_n__7813_6366_loopAtHorizon($0, $1, $b, $e, $82), $e);
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

/* Simplex.Core.substrateNodes : Substrate -> List Geometry */
function Simplex_Core_substrateNodes($0) {
 return Data_List_nub(csegen_22(), Prelude_Types_foldMap_Foldable_List(csegen_95(), $9 => ({a1: $9.a1.a1, a2: {a1: $9.a1.a2, a2: {h: 0}}}), Math_Multiset_multisetToList($0)));
}

/* Math.IntPolynumber.3641:1384:mulOuter */
function Math_IntPolynumber_n__3641_1384_mulOuter($0, $1, $2, $3) {
 switch($2.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return Math_Multiset_addMultiset(Math_IntPolynumber_n__3641_1383_mulInner($0, $1, $2.a1, $2.a2, $3), Math_IntPolynumber_n__3641_1384_mulOuter($0, $1, $2.a3, $3));
 }
}

/* Math.IntPolynumber.3641:1383:mulInner */
function Math_IntPolynumber_n__3641_1383_mulInner($0, $1, $2, $3, $4) {
 switch($4.h) {
  case 0: /* ZeroM */ return {h: 0 /* ZeroM */};
  case 1: /* AddM */ return {h: 1 /* AddM */, a1: Math_IntPolynumber_n__3641_1382_mulBasis($0, $1, $2, $4.a1), a2: Math_BoxInt_boxMult($3, $4.a2), a3: Math_IntPolynumber_n__3641_1383_mulInner($0, $1, $2, $3, $4.a3)};
 }
}

/* Math.IntPolynumber.3641:1382:mulBasis */
function Math_IntPolynumber_n__3641_1382_mulBasis($0, $1, $2, $3) {
 return {a1: ($2.a1+$3.a1), a2: ($2.a2+$3.a2)};
}

/* Math.IntPolynumber.subIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_subIntPoly($0, $1) {
 return Math_Multiset_subMultiset(csegen_33(), $0, $1);
}

/* Math.IntPolynumber.posTerm : Nat -> Nat -> BoxInt -> IntPolynumber */
function Math_IntPolynumber_posTerm($0, $1, $2) {
 return {h: 1 /* AddM */, a1: {a1: $0, a2: $1}, a2: $2, a3: {h: 0 /* ZeroM */}};
}

/* Math.IntPolynumber.mulIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_mulIntPoly($0, $1) {
 return Math_Multiset_annihilateMultiset(csegen_49(), Math_IntPolynumber_n__3641_1384_mulOuter($1, $0, $0, $1));
}

/* Math.IntPolynumber.emptyIntPoly : IntPolynumber */
const Math_IntPolynumber_emptyIntPoly = __lazy(function () {
 return {h: 0 /* ZeroM */};
});

/* Math.IntPolynumber.annihilateIntPoly : IntPolynumber -> IntPolynumber */
function Math_IntPolynumber_annihilateIntPoly($0) {
 return Math_Multiset_annihilateMultiset(csegen_49(), $0);
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
 return Math_IntPolynumber_posTerm(1n, 0n, {h: 1 /* AddM */, a1: 0, a2: 1n, a3: {h: 0 /* ZeroM */}});
});

/* Math.SpreadPolynumber.onePoly : IntPolynumber */
const Math_SpreadPolynumber_onePoly = __lazy(function () {
 return Math_IntPolynumber_posTerm(0n, 0n, {h: 1 /* AddM */, a1: 0, a2: 1n, a3: {h: 0 /* ZeroM */}});
});

/* Math.SpreadPolynumber.memoSpreadPoly : Nat -> IntPolynumber */
function Math_SpreadPolynumber_memoSpreadPoly($0) {
 switch($0) {
  case 0n: return Math_IntPolynumber_emptyIntPoly();
  default: {
   const $3 = ($0-1n);
   switch($3) {
    case 0n: return Math_SpreadPolynumber_sPoly();
    default: {
     const $8 = ($3-1n);
     const $b = csegen_100();
     const $d = csegen_99();
     return Builtin_fst(Math_SpreadPolynumber_n__3613_2590_step($8, $b, $d, ($8+1n), {a1: Math_SpreadPolynumber_sPoly(), a2: Math_IntPolynumber_emptyIntPoly()}));
    }
   }
  }
 }
}

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
   const $a = csegen_100();
   const $c = Math_SpreadPolynumber_scalarMul(2n, Math_IntPolynumber_mulIntPoly($a, $4));
   const $13 = csegen_99();
   return Math_IntPolynumber_annihilateIntPoly(Math_IntPolynumber_addIntPoly(Math_IntPolynumber_subIntPoly($c, $7), $13));
  }
 }
}

/* Evolution.Cycle.case block in runAdaptiveCycle */
function Evolution_Cycle_case__runAdaptiveCycle_3845($0, $1, $2, $3, $4, $5) {
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

/* Evolution.Cycle.sigmaGateAudit : Substrate -> Vexel -> Bool */
function Evolution_Cycle_sigmaGateAudit($0, $1) {
 const $2 = Evolution_Cycle_computeBoundaryNL($0);
 const $5 = Math_Multiset_multiplicityAll(csegen_103(), $2);
 return Prelude_EqOrd_x3dx3d_Eq_Integer($5, 0n);
}

/* Evolution.Cycle.runAdaptiveCycle : Nat -> Metric -> Geometry -> UniverseState -> UniverseState */
function Evolution_Cycle_runAdaptiveCycle($0, $1, $2, $3) {
 return Evolution_Cycle_case__runAdaptiveCycle_3845($3.a2, $3.a1, $2, $1, $0, Evolution_LocalSpreadPolynumber_stepUniverseLocalized($0, $1, $3.a1, $3.a2));
}

/* Evolution.Cycle.computeBoundaryNL : Substrate -> Vexel */
function Evolution_Cycle_computeBoundaryNL($0) {
 const $1 = Math_Multiset_multisetToList($0);
 const $4 = Prelude_Types_foldMap_Foldable_List(csegen_95(), $9 => ({a1: {a1: {a1: $9.a1.a2, a2: {h: 0 /* ZeroM */}}, a2: $9.a2}, a2: {a1: {a1: {a1: $9.a1.a1, a2: {h: 0 /* ZeroM */}}, a2: (0n-$9.a2)}, a2: {h: 0}}}), $1);
 return Math_Multiset_fromList(csegen_43(), $4);
}

/* Evolution.CosmicPartition.power : Nat -> Nat -> Nat */
function Evolution_CosmicPartition_power($0, $1) {
 switch($1) {
  case 0n: return 1n;
  default: {
   const $3 = ($1-1n);
   return ($0*Evolution_CosmicPartition_power($0, $3));
  }
 }
}

/* Evolution.CosmicPartition.extractGeometrySize : Geometry -> Nat */
function Evolution_CosmicPartition_extractGeometrySize($0) {
 switch($0.a2.h) {
  case 0: /* nothing */ return Evolution_CosmicPartition_power($0.a1, $0.a1);
  case undefined: /* just */ return $0.a2.a1;
 }
}

/* Evolution.CosmicPartition.darkEnergyStates : Nat */
const Evolution_CosmicPartition_darkEnergyStates = __lazy(function () {
 return Evolution_CosmicPartition_extractGeometrySize({a1: 2n, a2: {a1: 128n}});
});

/* Evolution.Gate.selectGate : Nat -> FundamentalGate */
function Evolution_Gate_selectGate($0) {
 const $1 = Prelude_Types_List_filterAppend({h: 0}, g => Prelude_Types_x3cx3d_Ord_Nat(Evolution_Gate_degree(g), $0), Evolution_Gate_adaptiveCycle());
 const $c = Data_List_lastx27($1);
 switch($c.h) {
  case undefined: /* just */ return $c.a1;
  case 0: /* nothing */ return Evolution_Gate_BackgroundGate();
 }
}

/* Evolution.Gate.mkFundamentalGate : String -> (n : Nat) -> GatePrime n -> FundamentalGate */
function Evolution_Gate_mkFundamentalGate($0, $1, $2) {
 return {a1: $1, a2: {a1: $0, a2: $2}};
}

/* Evolution.Gate.degree : FundamentalGate -> Nat */
function Evolution_Gate_degree($0) {
 return $0.a1;
}

/* Evolution.Gate.adaptiveCycle : List FundamentalGate */
const Evolution_Gate_adaptiveCycle = __lazy(function () {
 return {a1: Evolution_Gate_BackgroundGate(), a2: {a1: Evolution_Gate_MatterGate(), a2: {a1: Evolution_Gate_BondGate(), a2: {a1: Evolution_Gate_ChargeGate(), a2: {a1: Evolution_Gate_TimeGate(), a2: {a1: Evolution_Gate_WeakForceGate(), a2: {a1: Evolution_Gate_ResonanceGate(), a2: {h: 0}}}}}}}};
});

/* Evolution.Gate.WeakForceGate : FundamentalGate */
const Evolution_Gate_WeakForceGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Weak Force', 11n, {h: 6 /* WeakForce */});
});

/* Evolution.Gate.TimeGate : FundamentalGate */
const Evolution_Gate_TimeGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Time Dilation', 7n, {h: 5 /* Time */});
});

/* Evolution.Gate.ResonanceGate : FundamentalGate */
const Evolution_Gate_ResonanceGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Decoherence Resonance', 13n, {h: 7 /* Resonance */});
});

/* Evolution.Gate.MatterGate : FundamentalGate */
const Evolution_Gate_MatterGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Matter', 3n, {h: 2 /* Matter */});
});

/* Evolution.Gate.ChargeGate : FundamentalGate */
const Evolution_Gate_ChargeGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Fractional Charge', 5n, {h: 4 /* Charge */});
});

/* Evolution.Gate.BondGate : FundamentalGate */
const Evolution_Gate_BondGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Molecular Bond', 4n, {h: 3 /* Bond */});
});

/* Evolution.Gate.BackgroundGate : FundamentalGate */
const Evolution_Gate_BackgroundGate = __lazy(function () {
 return Evolution_Gate_mkFundamentalGate('Background', 2n, {h: 1 /* Background */});
});

/* Evolution.Transform.shatterTerm : BoxInt -> ((Nat, Nat), BoxInt) -> ((Nat, Nat), BoxInt) */
function Evolution_Transform_shatterTerm($0, $1) {
 const $3 = Math_BoxInt_boxToInt($1.a2);
 const $6 = Math_BoxInt_boxToInt($0);
 const $9 = Prelude_Num_mod_Integral_Integer($3, $6);
 return {a1: $1.a1, a2: Math_BoxInt_intToBoxInt($9)};
}

/* Evolution.Transform.polyDegree : IntPolynumber -> Nat */
function Evolution_Transform_polyDegree($0) {
 switch($0.h) {
  case 0: /* ZeroM */ return 0n;
  case 1: /* AddM */ return Prelude_Types_max_Ord_Nat($0.a1.a1, Evolution_Transform_polyDegree($0.a3));
 }
}

/* Evolution.Transform.partitionLogic : Nat -> Geometry -> IntPolynumber -> (Vexel, Vexel) */
function Evolution_Transform_partitionLogic($0, $1, $2) {
 const $3 = Math_BoxInt_intToBoxInt($0);
 const $6 = Data_List_partition($9 => Evolution_Transform_isLatentTerm($3, $9), Math_Multiset_multisetToList($2));
 const $10 = Math_Multiset_fromList(csegen_49(), $6.a1);
 const $15 = Math_Multiset_fromList(csegen_49(), $6.a2);
 const $1a = Math_Multiset_fromList(csegen_43(), {a1: {a1: {a1: $1, a2: $10}, a2: 1n}, a2: {h: 0}});
 const $25 = Math_Multiset_fromList(csegen_43(), {a1: {a1: {a1: $1, a2: $15}, a2: 1n}, a2: {h: 0}});
 return {a1: $1a, a2: $25};
}

/* Evolution.Transform.isLatentTerm : BoxInt -> ((Nat, Nat), BoxInt) -> Bool */
function Evolution_Transform_isLatentTerm($0, $1) {
 return Math_BoxInt_x3ex3d_Ord_BoxInt($1.a2, $0);
}

/* Evolution.Transform.gohFactorisationHorizon : Vexel -> Bool */
function Evolution_Transform_gohFactorisationHorizon($0) {
 const $1 = Evolution_Transform_extractVexelPoly($0);
 const $4 = Evolution_Transform_polyDegree($1);
 switch(Prelude_Types_x3e_Ord_Nat($4, 0n)) {
  case 1: return Math_Multiset_x3dx3d_Eq_x28x28Multisetx20x24cx29x20x24ax29(csegen_36(), $1, Math_SpreadPolynumber_memoSpreadPoly($4));
  case 0: return 0;
 }
}

/* Evolution.Transform.extractVexelPoly : Vexel -> IntPolynumber */
function Evolution_Transform_extractVexelPoly($0) {
 return Prelude_Types_foldl_Foldable_List(acc => $3 => Math_IntPolynumber_addIntPoly(acc, Math_Multiset_scaleMultiset(csegen_34(), Math_BoxInt_intToBoxInt($3.a2), $3.a1.a2)), Math_IntPolynumber_emptyIntPoly(), Math_Multiset_multisetToList($0));
}

/* Evolution.Transform.evaluateResonance : Nat -> Integer -> Geometry -> Vexel -> Vexel */
function Evolution_Transform_evaluateResonance($0, $1, $2, $3) {
 const $4 = Math_Multiset_multiplicityAll(csegen_103(), $3);
 switch(Prelude_EqOrd_x3e_Ord_Integer($4, $0)) {
  case 1: {
   const $d = Prelude_Types_foldMap_Foldable_List(csegen_95(), $12 => Prelude_Types_List_mapAppend({h: 0}, $18 => ({a1: $18.a1, a2: Math_BoxInt_boxMult($18.a2, Math_BoxInt_intToBoxInt($12.a2))}), Math_Multiset_multisetToList($12.a1.a2)), Math_Multiset_multisetToList($3));
   const $27 = Math_BoxInt_intToBoxInt($1);
   const $2a = Prelude_Types_List_mapAppend({h: 0}, $2e => Evolution_Transform_shatterTerm($27, $2e), $d);
   const $33 = Math_Multiset_fromList(csegen_49(), $2a);
   return Math_Multiset_fromList(csegen_43(), {a1: {a1: {a1: $2, a2: $33}, a2: 1n}, a2: {h: 0}});
  }
  case 0: return $3;
 }
}

/* Evolution.Transform.canAscend : Metric -> Substrate -> Vexel -> Bool */
function Evolution_Transform_canAscend($0, $1, $2) {
 switch(Simplex_Twist_chromogeometricHorizon($1)) {
  case 1: return 1;
  case 0: return Evolution_Transform_gohFactorisationHorizon($2);
 }
}

/* Evolution.Transform.ascendScale : Geometry -> Vexel -> Vexel */
function Evolution_Transform_ascendScale($0, $1) {
 const $2 = Prelude_Types_foldl_Foldable_List(acc => $5 => Math_Multiset_addMultiset(acc, Math_Multiset_scaleMultiset(csegen_34(), Math_BoxInt_intToBoxInt($5.a2), $5.a1.a2)), Math_IntPolynumber_emptyIntPoly(), Math_Multiset_multisetToList($1));
 return Math_Multiset_fromList(csegen_43(), {a1: {a1: {a1: $0, a2: $2}, a2: 1n}, a2: {h: 0}});
}

/* Evolution.LocalSpreadPolynumber.case block in case block in generateLocalSpreadPolyList */
function Evolution_LocalSpreadPolynumber_case__casex20blockx20inx20generateLocalSpreadPolyList_5714($0, $1, $2, $3, $4, $5) {
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
 const $f = Evolution_Gate_degree(Evolution_Gate_selectGate(Prelude_Types_prim__integerToNat(Prelude_Num_mod_Integral_Integer(Prelude_Num_abs_Abs_Integer($7), 137n))));
 const $1b = Math_SpreadPolynumber_makeSpreadPolyExpr($f);
 return Math_SpreadPolynumber_evalSpreadPolyExpr($1b);
}

/* Evolution.LocalSpreadPolynumber.case block in case block in case block in generateLocalSpreadPolyList */
function Evolution_LocalSpreadPolynumber_case__casex20blockx20inx20casex20blockx20inx20generateLocalSpreadPolyList_5598($0, $1, $2, $3, $4, $5, $6, $7, $8, $9) {
 const $b = Math_BoxInt_boxToInt($9.a1);
 const $e = Math_BoxInt_boxToInt($9.a2);
 return {a1: ($b*$7), a2: $e};
}

/* Evolution.LocalSpreadPolynumber.4691:5822:getEnergy */
function Evolution_LocalSpreadPolynumber_n__4691_5822_getEnergy($0, $1, $2) {
 const $3 = Prelude_Types_List_filterAppend({h: 0}, $7 => Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $7.a1.a1, $2), $0);
 switch($3.h) {
  case undefined: /* cons */ return $3.a1.a2;
  case 0: /* nil */ return 0n;
 }
}

/* Evolution.LocalSpreadPolynumber.4691:5821:deformedEdges */
function Evolution_LocalSpreadPolynumber_n__4691_5821_deformedEdges($0, $1) {
 const $4 = $5 => {
  const $8 = Evolution_LocalSpreadPolynumber_n__4691_5822_getEnergy($0, $1, $5.a1.a1);
  const $d = Evolution_LocalSpreadPolynumber_n__4691_5822_getEnergy($0, $1, $5.a1.a2);
  return {a1: {a1: $5.a1.a1, a2: $5.a1.a2}, a2: (($5.a2+$8)+$d)};
 };
 return Prelude_Types_List_mapAppend({h: 0}, $4, $1);
}

/* Evolution.LocalSpreadPolynumber.stepUniverseLocalized : Nat -> Metric -> Substrate -> Vexel -> (Substrate, Vexel) */
function Evolution_LocalSpreadPolynumber_stepUniverseLocalized($0, $1, $2, $3) {
 const $4 = Evolution_LocalSpreadPolynumber_stepUniverseList($0, $1, Math_Multiset_multisetToList($2), Math_Multiset_multisetToList($3));
 const $e = Math_Multiset_fromList(csegen_47(), $4.a1);
 const $13 = Math_Multiset_fromList(csegen_43(), $4.a2);
 return {a1: $e, a2: $13};
}

/* Evolution.LocalSpreadPolynumber.stepUniverseList : Nat -> Metric -> List ((Geometry, Geometry), Integer) -> List ((Geometry,
Amplitude),
Integer) -> (List ((Geometry, Geometry), Integer),
List ((Geometry, Amplitude), Integer)) */
function Evolution_LocalSpreadPolynumber_stepUniverseList($0, $1, $2, $3) {
 const $7 = $8 => {
  const $b = Evolution_LocalSpreadPolynumber_generateLocalSpreadPolyList($1, $2, $8.a1.a1);
  const $10 = Math_Multiset_scaleMultiset(csegen_34(), Math_BoxInt_intToBoxInt($8.a2), Math_IntPolynumber_mulIntPoly($8.a1.a2, $b));
  return {a1: {a1: $8.a1.a1, a2: $10}, a2: $8.a2};
 };
 const $4 = Prelude_Types_List_mapAppend({h: 0}, $7, $3);
 const $24 = $25 => {
  const $28 = Evolution_Transform_partitionLogic(Evolution_CosmicPartition_darkEnergyStates(), $25.a1.a1, $25.a1.a2);
  const $2e = Evolution_Transform_evaluateResonance($0, Evolution_Gate_degree(Evolution_Gate_ResonanceGate()), $25.a1.a1, $28.a2);
  return Math_Multiset_multisetToList(Math_Multiset_addMultiset($28.a1, $2e));
 };
 const $20 = Prelude_Types_foldMap_Foldable_List(csegen_95(), $24, $4);
 const $3d = Evolution_LocalSpreadPolynumber_n__4691_5821_deformedEdges($4, $2);
 return {a1: $3d, a2: $20};
}

/* Evolution.LocalSpreadPolynumber.generateLocalSpreadPolyList : Metric -> List ((Geometry, Geometry), Integer) -> Geometry -> IntPolynumber */
function Evolution_LocalSpreadPolynumber_generateLocalSpreadPolyList($0, $1, $2) {
 const $6 = $7 => {
  const $c = $d => {
   const $1b = $1c => {
    let $22;
    switch(Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $7.a1.a1, $2)) {
     case 1: {
      $22 = 1;
      break;
     }
     case 0: {
      switch(Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $7.a1.a2, $2)) {
       case 1: {
        $22 = 1;
        break;
       }
       case 0: {
        $22 = Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $d.a1.a2, $2);
        break;
       }
      }
      break;
     }
    }
    const $1e = Prelude_Interfaces_guard(csegen_93(), $22);
    return Prelude_Types_listBind($1e, $35 => Prelude_Types_pure_Applicative_List({a1: $7.a1.a1, a2: {a1: $7.a1.a2, a2: {a1: $d.a1.a2, a2: ($7.a2*$d.a2)}}}));
   };
   return Prelude_Types_listBind(Prelude_Interfaces_guard(csegen_93(), Math_Pixel_x3dx3d_Eq_x28x28Pixelx20x24metricx29x20x24ax29(csegen_19(), $7.a1.a2, $d.a1.a1)), $1b);
  };
  return Prelude_Types_listBind($1, $c);
 };
 const $3 = Prelude_Types_listBind($1, $6);
 const $43 = $44 => {
  const $48 = {a1: $44.a1, a2: {a1: $44.a2.a1, a2: {a1: $44.a2.a2.a1, a2: $44.a2.a2.a2}}};
  return Evolution_LocalSpreadPolynumber_case__casex20blockx20inx20casex20blockx20inx20generateLocalSpreadPolyList_5598($2, $1, $0, $3, $44.a1, $44.a2.a1, $44.a2.a2.a1, $44.a2.a2.a2, $48, Math_Chromogeometry_spreadNL(0, $44.a1, $44.a2.a1, $44.a2.a2.a1));
 };
 const $40 = Prelude_Types_List_mapAppend({h: 0}, $43, $3);
 return Evolution_LocalSpreadPolynumber_case__casex20blockx20inx20generateLocalSpreadPolyList_5714($2, $1, $0, $3, $40, Prelude_Types_foldl_Foldable_List(csegen_82(), {a1: 0n, a2: 1n}, $40));
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
