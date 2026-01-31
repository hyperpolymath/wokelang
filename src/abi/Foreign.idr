-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
-- Foreign.idr - FFI declarations for WokeLang

module WokeLang.ABI.Foreign

import WokeLang.ABI.Types
import WokeLang.ABI.Layout

%default total

-- | C string type
public export
CString : Type
CString = Ptr String

-- | C int type
public export
CInt : Type
CInt = Bits32

-- | C long long type
public export
CLongLong : Type
CLongLong = Bits64

-- | C double type
public export
CDouble : Type
CDouble = Double

-- ==== Interpreter Lifecycle ====

-- | Create a new WokeLang interpreter
-- Returns null on failure
%foreign "C:woke_interpreter_new,libwokelang"
export
woke_interpreter_new : PrimIO (Ptr InterpreterHandle)

-- | Free a WokeLang interpreter
%foreign "C:woke_interpreter_free,libwokelang"
export
woke_interpreter_free : Ptr InterpreterHandle -> PrimIO ()

-- ==== Execution ====

-- | Execute WokeLang source code
%foreign "C:woke_exec,libwokelang"
export
woke_exec : Ptr InterpreterHandle -> CString -> PrimIO CInt

-- | Execute and get return value
%foreign "C:woke_eval,libwokelang"
export
woke_eval : Ptr InterpreterHandle -> CString -> Ptr (Ptr ValueHandle) -> PrimIO CInt

-- ==== Value Operations ====

-- | Free a WokeLang value
%foreign "C:woke_value_free,libwokelang"
export
woke_value_free : Ptr ValueHandle -> PrimIO ()

-- | Get value type
%foreign "C:woke_value_type,libwokelang"
export
woke_value_type : Ptr ValueHandle -> PrimIO CInt

-- | Get integer from value
%foreign "C:woke_value_as_int,libwokelang"
export
woke_value_as_int : Ptr ValueHandle -> Ptr CLongLong -> PrimIO CInt

-- | Get float from value
%foreign "C:woke_value_as_float,libwokelang"
export
woke_value_as_float : Ptr ValueHandle -> Ptr CDouble -> PrimIO CInt

-- | Get boolean from value
%foreign "C:woke_value_as_bool,libwokelang"
export
woke_value_as_bool : Ptr ValueHandle -> Ptr CInt -> PrimIO CInt

-- | Get string from value (must free with woke_string_free)
%foreign "C:woke_value_as_string,libwokelang"
export
woke_value_as_string : Ptr ValueHandle -> PrimIO CString

-- | Free string returned by woke_value_as_string
%foreign "C:woke_string_free,libwokelang"
export
woke_string_free : CString -> PrimIO ()

-- ==== Value Creation ====

-- | Create integer value
%foreign "C:woke_value_from_int,libwokelang"
export
woke_value_from_int : CLongLong -> PrimIO (Ptr ValueHandle)

-- | Create float value
%foreign "C:woke_value_from_float,libwokelang"
export
woke_value_from_float : CDouble -> PrimIO (Ptr ValueHandle)

-- | Create boolean value
%foreign "C:woke_value_from_bool,libwokelang"
export
woke_value_from_bool : CInt -> PrimIO (Ptr ValueHandle)

-- | Create string value
%foreign "C:woke_value_from_string,libwokelang"
export
woke_value_from_string : CString -> PrimIO (Ptr ValueHandle)

-- ==== Utility ====

-- | Get version string
%foreign "C:woke_version,libwokelang"
export
woke_version : PrimIO CString

-- | Get last error message
%foreign "C:woke_last_error,libwokelang"
export
woke_last_error : PrimIO CString
