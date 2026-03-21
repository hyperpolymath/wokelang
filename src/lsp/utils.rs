// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! LSP utility functions

use std::ops::Range as StdRange;
use tower_lsp::lsp_types::{Position, Range};

/// Line index for converting between byte offsets and line:column positions
pub struct LineIndex {
    /// Byte offset of the start of each line
    line_starts: Vec<usize>,
}

impl LineIndex {
    /// Create a new line index from source text
    pub fn new(source: &str) -> Self {
        let mut line_starts = vec![0];
        for (i, c) in source.char_indices() {
            if c == '\n' {
                line_starts.push(i + 1);
            }
        }
        Self { line_starts }
    }

    /// Convert LSP Position (line:column) to byte offset
    pub fn position_to_offset(&self, line: u32, character: u32) -> Option<usize> {
        let line = line as usize;
        if line >= self.line_starts.len() {
            return None;
        }

        let line_start = self.line_starts[line];
        Some(line_start + character as usize)
    }

    /// Convert byte offset to LSP Position (line:column)
    pub fn offset_to_position(&self, offset: usize) -> Position {
        // Binary search for the line
        let line = self
            .line_starts
            .binary_search(&offset)
            .unwrap_or_else(|i| i.saturating_sub(1));

        let line_start = self.line_starts[line];
        let character = offset - line_start;

        Position {
            line: line as u32,
            character: character as u32,
        }
    }
}

/// Convert WokeLang span (byte range) to LSP Range (line:column range)
pub fn span_to_range(span: &StdRange<usize>, source: &str) -> Range {
    let index = LineIndex::new(source);
    Range {
        start: index.offset_to_position(span.start),
        end: index.offset_to_position(span.end),
    }
}

/// Convert LSP Position to byte offset
pub fn position_to_offset(position: &Position, source: &str) -> usize {
    let index = LineIndex::new(source);
    index
        .position_to_offset(position.line, position.character)
        .unwrap_or(0)
}
