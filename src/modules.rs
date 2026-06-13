// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Module System for WokeLang
//!
//! Handles file resolution, module loading, and namespace management.

use crate::ast::{ModuleImport, Program, QualifiedName};
use crate::lexer::Lexer;
use crate::parser::Parser;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};

/// Error type for module operations
#[derive(Debug, Clone)]
pub enum ModuleError {
    /// File not found
    FileNotFound(String),
    /// Parse error in module
    ParseError(String),
    /// Circular dependency detected
    CircularDependency(Vec<String>),
    /// I/O error
    IoError(String),
}

impl std::fmt::Display for ModuleError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ModuleError::FileNotFound(path) => write!(f, "Module not found: {}", path),
            ModuleError::ParseError(msg) => write!(f, "Parse error in module: {}", msg),
            ModuleError::CircularDependency(cycle) => {
                write!(f, "Circular dependency: {}", cycle.join(" -> "))
            }
            ModuleError::IoError(msg) => write!(f, "I/O error: {}", msg),
        }
    }
}

impl std::error::Error for ModuleError {}

/// Loaded module with its AST and metadata
#[derive(Debug, Clone)]
pub struct LoadedModule {
    pub path: PathBuf,
    pub name: String,
    pub program: Program,
}

/// Module loader handles file resolution and loading
pub struct ModuleLoader {
    /// Search paths for modules
    search_paths: Vec<PathBuf>,
    /// Cache of loaded modules (path -> module)
    cache: HashMap<PathBuf, LoadedModule>,
    /// Currently loading modules (for cycle detection)
    loading: HashSet<PathBuf>,
}

impl ModuleLoader {
    pub fn new() -> Self {
        let mut search_paths = vec![];

        // Add current directory
        if let Ok(cwd) = std::env::current_dir() {
            search_paths.push(cwd);
        }

        // Add standard library path if it exists
        if let Some(home) = dirs::home_dir() {
            let stdlib = home.join(".woke").join("lib");
            if stdlib.exists() {
                search_paths.push(stdlib);
            }
        }

        Self {
            search_paths,
            cache: HashMap::new(),
            loading: HashSet::new(),
        }
    }

    /// Add a search path for modules
    pub fn add_search_path(&mut self, path: PathBuf) {
        if !self.search_paths.contains(&path) {
            self.search_paths.push(path);
        }
    }

    /// Resolve a qualified name to a file path
    /// For example: "foo.bar.baz" becomes "foo/bar/baz.woke"
    fn resolve_path(&self, name: &QualifiedName) -> Option<PathBuf> {
        let mut relative_path = PathBuf::new();
        for part in &name.parts {
            relative_path.push(part);
        }
        relative_path.set_extension("woke");

        // Try each search path
        for search_path in &self.search_paths {
            let full_path = search_path.join(&relative_path);
            if full_path.exists() {
                return Some(full_path);
            }
        }

        None
    }

    /// Load a module by qualified name
    pub fn load_module(&mut self, name: &QualifiedName) -> Result<LoadedModule, ModuleError> {
        // Resolve to file path
        let path = self.resolve_path(name).ok_or_else(|| {
            ModuleError::FileNotFound(format!(
                "Could not find module: {}",
                name.parts.join(".")
            ))
        })?;

        // Check cache
        if let Some(module) = self.cache.get(&path) {
            return Ok(module.clone());
        }

        // Check for circular dependency
        if self.loading.contains(&path) {
            let mut cycle: Vec<String> = self
                .loading
                .iter()
                .map(|p| p.to_string_lossy().to_string())
                .collect();
            cycle.push(path.to_string_lossy().to_string());
            return Err(ModuleError::CircularDependency(cycle));
        }

        // Mark as loading
        self.loading.insert(path.clone());

        // Load and parse the file
        let source = fs::read_to_string(&path)
            .map_err(|e| ModuleError::IoError(format!("Failed to read {}: {}", path.display(), e)))?;

        let lexer = Lexer::new(&source);
        let tokens = lexer
            .tokenize()
            .map_err(|e| ModuleError::ParseError(format!("Tokenize error in {}: {}", path.display(), e)))?;

        let mut parser = Parser::new(tokens, &source);
        let program = parser
            .parse()
            .map_err(|e| ModuleError::ParseError(format!("Parse error in {}: {}", path.display(), e)))?;

        // Recursively load imported modules
        for item in &program.items {
            if let crate::ast::TopLevelItem::ModuleImport(import) = item {
                self.load_module(&import.path)?;
            }
        }

        // Create loaded module
        let module = LoadedModule {
            path: path.clone(),
            name: name.parts.join("."),
            program,
        };

        // Cache it
        self.cache.insert(path.clone(), module.clone());

        // Unmark as loading
        self.loading.remove(&path);

        Ok(module)
    }

    /// Load a module from a file path (for main entry point)
    pub fn load_from_path(&mut self, path: &Path) -> Result<LoadedModule, ModuleError> {
        let path = path.canonicalize().map_err(|e| {
            ModuleError::IoError(format!("Failed to canonicalize {}: {}", path.display(), e))
        })?;

        // Check cache
        if let Some(module) = self.cache.get(&path) {
            return Ok(module.clone());
        }

        // Load and parse
        let source = fs::read_to_string(&path)
            .map_err(|e| ModuleError::IoError(format!("Failed to read {}: {}", path.display(), e)))?;

        let lexer = Lexer::new(&source);
        let tokens = lexer
            .tokenize()
            .map_err(|e| ModuleError::ParseError(format!("Tokenize error in {}: {}", path.display(), e)))?;

        let mut parser = Parser::new(tokens, &source);
        let program = parser
            .parse()
            .map_err(|e| ModuleError::ParseError(format!("Parse error in {}: {}", path.display(), e)))?;

        // Recursively load imports
        for item in &program.items {
            if let crate::ast::TopLevelItem::ModuleImport(import) = item {
                self.load_module(&import.path)?;
            }
        }

        let module = LoadedModule {
            path: path.clone(),
            name: path
                .file_stem()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string(),
            program,
        };

        self.cache.insert(path.clone(), module.clone());

        Ok(module)
    }

    /// Get all loaded modules
    pub fn modules(&self) -> Vec<&LoadedModule> {
        self.cache.values().collect()
    }
}

impl Default for ModuleLoader {
    fn default() -> Self {
        Self::new()
    }
}
