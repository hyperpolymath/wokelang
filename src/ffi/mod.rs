// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Foreign Function Interface for WokeLang
//!
//! This module provides a C-compatible API that can be used from Zig, C, or any
//! language that supports the C ABI.

mod c_api;

pub use c_api::*;
