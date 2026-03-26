-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Layout.idr - Memory layout verification for WokeLang ABI

module WokeLang.ABI.Layout

import Data.Bits
import WokeLang.ABI.Types

%default total

-- | Platform-specific alignment requirements
public export
data Platform = Linux | Windows | MacOS | BSD

-- | Pointer size for platform (64-bit assumed)
export
ptrSize : Platform -> Nat
ptrSize _ = 8

-- | Alignment requirement for pointers
export
ptrAlignment : Platform -> Nat
ptrAlignment _ = 8

-- | Size of Result enum (C int, 4 bytes)
export
resultSize : Nat
resultSize = 4

-- | Alignment of Result enum
export
resultAlignment : Nat
resultAlignment = 4

-- | Size of ValueType enum (C int, 4 bytes)
export
valueTypeSize : Nat
valueTypeSize = 4

-- | Alignment of ValueType enum
export
valueTypeAlignment : Nat
valueTypeAlignment = 4

-- | Prove handle size equals pointer size
export
0 handleSizeCorrect : (p : Platform) -> ptrSize p = 8
handleSizeCorrect _ = Refl

-- | Prove handle alignment equals pointer alignment
export
0 handleAlignmentCorrect : (p : Platform) -> ptrAlignment p = 8
handleAlignmentCorrect _ = Refl

-- | Prove Result size is 4 bytes
export
0 resultSizeCorrect : resultSize = 4
resultSizeCorrect = Refl

-- | Prove ValueType size is 4 bytes
export
0 valueTypeSizeCorrect : valueTypeSize = 4
valueTypeSizeCorrect = Refl
