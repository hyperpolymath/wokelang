-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Types.idr - Type definitions with proofs for WokeLang ABI

module WokeLang.ABI.Types

import Data.Bits
import Data.So

%default total

-- | Opaque handle to WokeLang interpreter
-- Guarantees non-null at type level
public export
data InterpreterHandle : Type where
  MkInterpreterHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> InterpreterHandle

-- | Opaque handle to WokeLang value
-- Guarantees non-null at type level
public export
data ValueHandle : Type where
  MkValueHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> ValueHandle

-- | Result codes for FFI operations
public export
data Result : Type where
  Ok           : Result
  Error        : Result
  ParseError   : Result
  RuntimeError : Result
  NullPointer  : Result

-- Prove Result fits in 32 bits
export
resultToC : Result -> Bits32
resultToC Ok           = 0
resultToC Error        = 1
resultToC ParseError   = 2
resultToC RuntimeError = 3
resultToC NullPointer  = 4

-- | Value type tags
public export
data ValueType : Type where
  IntType    : ValueType
  FloatType  : ValueType
  StringType : ValueType
  BoolType   : ValueType
  ArrayType  : ValueType
  UnitType   : ValueType

-- Prove ValueType fits in 32 bits
export
valueTypeToC : ValueType -> Bits32
valueTypeToC IntType    = 0
valueTypeToC FloatType  = 1
valueTypeToC StringType = 2
valueTypeToC BoolType   = 3
valueTypeToC ArrayType  = 4
valueTypeToC UnitType   = 5

-- | Null pointer representation (for error returns)
public export
nullPtr : Bits64
nullPtr = 0

-- Prove null pointer is indeed null
export
0 nullPtrIsNull : nullPtr = 0
nullPtrIsNull = Refl
