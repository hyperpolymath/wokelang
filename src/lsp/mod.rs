// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Language Server Protocol (LSP) implementation for WokeLang

pub mod backend;
pub mod document;
pub mod handlers;
pub mod stdlib_metadata;
pub mod symbols;
pub mod utils;

pub use backend::Backend;
pub use document::DocumentState;
pub use utils::{position_to_offset, span_to_range, LineIndex};
