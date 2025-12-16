//! Foreign Function Interface for WokeLang
//!
//! This module provides a C-compatible API that can be used from Zig, C, or any
//! language that supports the C ABI.

mod c_api;

pub use c_api::*;
