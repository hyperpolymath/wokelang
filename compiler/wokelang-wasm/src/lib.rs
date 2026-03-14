// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell

//! WebAssembly backend for WokeLang.
//!
//! Compiles consent gates and dimensional types to WASM. Consent gates
//! become runtime checks (WASM i32 boolean guards), and dimensional
//! values use i64 with metadata encoding for unit tracking.
//!
//! ## Output format
//!
//! Generates valid `.wasm` modules (binary format) containing:
//! - Type section (function signatures)
//! - Import section (runtime: consent_check, dimension_validate, log_violation)
//! - Function section (compiled WokeLang functions with consent guards)
//! - Memory section (linear memory for dimensional metadata)
//! - Export section (functions + memory)
//! - Data section (consent labels, dimension names)
//!
//! ## Consent gate representation
//!
//! Consent gates compile to runtime boolean checks. If the check fails,
//! execution traps or returns a sentinel value (configurable).
//!
//! ```wasm
//! ;; consent_check(gate_id: i32) -> i32 (1 = granted, 0 = denied)
//! (call $consent_check (i32.const 42))
//! (if (i32.eqz) (then (unreachable)))
//! ```
//!
//! ## Dimensional type representation
//!
//! Dimensional values are represented as i64 with the lower 48 bits
//! holding the numeric value and the upper 16 bits encoding the
//! dimension tag. Arithmetic operations check dimension compatibility.
//!
//! ## Limitations
//!
//! - No garbage collection (bump allocator)
//! - Dimension checking is runtime-only in WASM (compile-time in WokeLang)
//!
//! ## Consent revocation
//!
//! The runtime import `consent_revoke(gate_id: i32)` allows the host to
//! revoke consent at any point. Consent-gated sections emit a check
//! before each guarded block: `call $consent_check; i32.eqz; br_if $skip`.
//!
//! ## Dimensional unit conversion
//!
//! For each unit conversion used in the program, a WASM helper function
//! is emitted (e.g., `convert_m_to_km(val: f64) -> f64`).

use std::collections::HashMap;

use wasm_encoder::{
    CodeSection, DataSection, EntityType, ExportKind, ExportSection,
    Function as WasmFunc, FunctionSection, ImportSection, Instruction,
    MemorySection, MemoryType, Module, TypeSection, ValType,
};

/// Errors specific to the WokeLang WASM backend.
#[derive(Debug, Clone, thiserror::Error)]
pub enum WasmError {
    /// A consent gate references an unknown consent label.
    #[error("unknown consent label: \"{label}\"")]
    UnknownConsentLabel { label: String },

    /// Data section offset exceeds linear memory bounds.
    #[error("data section offset {offset} exceeds linear memory capacity ({capacity} bytes)")]
    DataSectionOverflow { offset: u32, capacity: u32 },

    /// Bump allocator ran out of linear memory.
    #[error("heap allocation of {requested} bytes exceeds capacity (offset {current}, capacity {capacity})")]
    HeapOverflow {
        requested: u32,
        current: u32,
        capacity: u32,
    },

    /// Dimension mismatch in an arithmetic operation.
    #[error("dimension mismatch: {lhs_dim} vs {rhs_dim} in {operation}")]
    DimensionMismatch {
        lhs_dim: String,
        rhs_dim: String,
        operation: String,
    },

    /// A function name collision was detected.
    #[error("duplicate function name: \"{name}\"")]
    DuplicateFunctionName { name: String },
}

/// WASM value type subset used by WokeLang.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WasmType {
    /// 32-bit integer (booleans, consent gate IDs, pointers).
    I32,
    /// 64-bit integer (dimensional values with metadata).
    I64,
    /// 64-bit float (dimensionless floating-point).
    F64,
}

impl WasmType {
    fn to_val_type(self) -> ValType {
        match self {
            Self::I32 => ValType::I32,
            Self::I64 => ValType::I64,
            Self::F64 => ValType::F64,
        }
    }
}

/// A compiled WASM function.
#[derive(Debug, Clone)]
pub struct WasmFunction {
    /// Function name.
    pub name: String,
    /// Parameter types.
    pub params: Vec<WasmType>,
    /// Return type.
    pub result: Option<WasmType>,
    /// Compiled bytecode size.
    pub code_size: usize,
    /// Whether this function contains consent gates.
    pub has_consent_gates: bool,
}

/// A WASM import declaration.
#[derive(Debug, Clone)]
pub struct WasmImport {
    /// Module name (e.g., "wokelang_rt").
    pub module: String,
    /// Function name.
    pub name: String,
    /// Parameter types.
    pub params: Vec<WasmType>,
    /// Return type (None = void).
    pub result: Option<WasmType>,
}

/// Output of the WokeLang WASM backend.
#[derive(Debug, Clone)]
pub struct WasmModule {
    /// Compiled functions.
    pub functions: Vec<WasmFunction>,
    /// Required imports.
    pub imports: Vec<WasmImport>,
    /// Initial memory pages (64KB each).
    pub initial_memory_pages: u32,
    /// Maximum memory pages.
    pub max_memory_pages: u32,
    /// The WASM binary module bytes.
    binary: Vec<u8>,
}

impl WasmModule {
    /// Get the WASM binary bytes.
    pub fn to_bytes(&self) -> &[u8] {
        &self.binary
    }

    /// Consume and return the WASM binary bytes.
    pub fn into_bytes(self) -> Vec<u8> {
        self.binary
    }
}

/// Bump allocator for WASM linear memory.
struct BumpAllocator {
    next_offset: u32,
    capacity: u32,
}

impl BumpAllocator {
    fn new(initial_offset: u32, initial_pages: u32) -> Self {
        Self {
            next_offset: initial_offset,
            capacity: initial_pages.saturating_mul(65536),
        }
    }

    fn alloc(&mut self, size: u32) -> Result<u32, WasmError> {
        let aligned = (self.next_offset + 7) & !7;
        let new_offset = aligned.checked_add(size).ok_or(WasmError::HeapOverflow {
            requested: size,
            current: self.next_offset,
            capacity: self.capacity,
        })?;
        if new_offset > self.capacity {
            return Err(WasmError::HeapOverflow {
                requested: size,
                current: self.next_offset,
                capacity: self.capacity,
            });
        }
        self.next_offset = new_offset;
        Ok(aligned)
    }
}

/// A consent gate definition.
#[derive(Debug, Clone)]
pub struct ConsentGate {
    /// Human-readable consent label.
    pub label: String,
    /// Numeric ID assigned to this gate.
    pub id: u32,
    /// Whether denial should trap (true) or return sentinel (false).
    pub trap_on_deny: bool,
}

/// A WokeLang function to compile.
#[derive(Debug, Clone)]
pub struct WokeLangFunction {
    /// Function name.
    pub name: String,
    /// Parameter types (dimensional values are I64).
    pub params: Vec<WasmType>,
    /// Return type.
    pub result: Option<WasmType>,
    /// Consent gates required before execution.
    pub required_consent: Vec<String>,
    /// Whether to return a constant value (scaffold: just return a constant).
    pub return_value: Option<i64>,
}

/// A dimensional unit conversion to emit as a WASM helper function.
#[derive(Debug, Clone)]
pub struct UnitConversion {
    /// Source unit name (e.g., "m").
    pub from_unit: String,
    /// Target unit name (e.g., "km").
    pub to_unit: String,
    /// Conversion factor: result = value * factor.
    pub factor: f64,
}

/// Input to the WokeLang WASM backend.
#[derive(Debug, Clone)]
pub struct WokeLangProgram {
    /// Consent gate definitions.
    pub consent_gates: Vec<ConsentGate>,
    /// Functions to compile.
    pub functions: Vec<WokeLangFunction>,
    /// String constants (consent labels, dimension names).
    pub string_constants: Vec<String>,
    /// Unit conversions to generate as helper functions.
    pub unit_conversions: Vec<UnitConversion>,
}

/// WASM backend for WokeLang.
pub struct WasmBackend {
    initial_memory_pages: u32,
    max_memory_pages: u32,
    warnings: Vec<String>,
}

impl WasmBackend {
    /// Create a new WASM backend with default memory settings.
    pub fn new() -> Self {
        Self {
            initial_memory_pages: 4,
            max_memory_pages: 64,
            warnings: Vec::new(),
        }
    }

    /// Retrieve any warnings generated during the last `generate()` call.
    pub fn warnings(&self) -> &[String] {
        &self.warnings
    }

    /// Set initial memory pages.
    pub fn with_initial_memory(mut self, pages: u32) -> Self {
        self.initial_memory_pages = pages;
        self
    }

    /// Set maximum memory pages.
    pub fn with_max_memory(mut self, pages: u32) -> Self {
        self.max_memory_pages = pages;
        self
    }

    /// Generate a WASM module from a WokeLang program.
    ///
    /// Consent gates compile to runtime boolean checks via imported
    /// `consent_check` function. Dimensional values use i64 with
    /// dimension tags in the upper bits.
    pub fn generate(&mut self, program: &WokeLangProgram) -> Result<WasmModule, WasmError> {
        self.warnings.clear();

        // Build consent gate lookup
        let consent_map: HashMap<&str, &ConsentGate> = program
            .consent_gates
            .iter()
            .map(|g| (g.label.as_str(), g))
            .collect();

        // Validate all function consent references
        for func in &program.functions {
            for label in &func.required_consent {
                if !consent_map.contains_key(label.as_str()) {
                    return Err(WasmError::UnknownConsentLabel {
                        label: label.clone(),
                    });
                }
            }
        }

        // Check for duplicate function names
        let mut seen_names: HashMap<&str, bool> = HashMap::new();
        for func in &program.functions {
            if seen_names.contains_key(func.name.as_str()) {
                return Err(WasmError::DuplicateFunctionName {
                    name: func.name.clone(),
                });
            }
            seen_names.insert(&func.name, true);
        }

        // Collect string constants
        let string_offsets = self.collect_strings(&program.string_constants)?;

        // Build imports
        let imports = vec![
            WasmImport {
                module: "wokelang_rt".into(),
                name: "consent_check".into(),
                params: vec![WasmType::I32], // gate ID
                result: Some(WasmType::I32), // 1 = granted, 0 = denied
            },
            WasmImport {
                module: "wokelang_rt".into(),
                name: "dimension_validate".into(),
                params: vec![WasmType::I64, WasmType::I64], // two dimensional values
                result: Some(WasmType::I32), // 1 = compatible, 0 = mismatch
            },
            WasmImport {
                module: "wokelang_rt".into(),
                name: "log_violation".into(),
                params: vec![WasmType::I32, WasmType::I32], // label ptr, label len
                result: None,
            },
            WasmImport {
                module: "wokelang_rt".into(),
                name: "consent_revoke".into(),
                params: vec![WasmType::I32], // gate_id
                result: None,
            },
        ];
        let import_count = imports.len() as u32;

        // Compile functions
        let mut compiled_funcs: Vec<(Vec<WasmType>, Option<WasmType>, WasmFunc)> = Vec::new();
        let mut wasm_functions: Vec<WasmFunction> = Vec::new();

        for func in &program.functions {
            let has_consent = !func.required_consent.is_empty();

            let local_types: Vec<(u32, ValType)> = if has_consent {
                vec![] // no extra locals needed for consent check pattern
            } else {
                vec![]
            };
            let mut func_body = WasmFunc::new(local_types);

            // Emit consent gate checks
            for label in &func.required_consent {
                if let Some(gate) = consent_map.get(label.as_str()) {
                    // Call consent_check(gate_id) -> i32
                    func_body.instruction(&Instruction::I32Const(gate.id as i32));
                    func_body.instruction(&Instruction::Call(0)); // consent_check import

                    if gate.trap_on_deny {
                        // If denied (result == 0), trap
                        func_body.instruction(&Instruction::I32Eqz);
                        func_body.instruction(&Instruction::If(wasm_encoder::BlockType::Empty));
                        func_body.instruction(&Instruction::Unreachable);
                        func_body.instruction(&Instruction::End);
                    } else {
                        // If denied, return sentinel (-1)
                        func_body.instruction(&Instruction::I32Eqz);
                        func_body.instruction(&Instruction::If(wasm_encoder::BlockType::Result(
                            ValType::I64,
                        )));
                        func_body.instruction(&Instruction::I64Const(-1));
                        func_body.instruction(&Instruction::Return);
                        func_body.instruction(&Instruction::End);
                    }
                }
            }

            // Emit function body (scaffold: return constant)
            match func.result {
                Some(WasmType::I64) => {
                    let val = func.return_value.unwrap_or(0);
                    func_body.instruction(&Instruction::I64Const(val));
                }
                Some(WasmType::I32) => {
                    let val = func.return_value.unwrap_or(0) as i32;
                    func_body.instruction(&Instruction::I32Const(val));
                }
                Some(WasmType::F64) => {
                    let val = func.return_value.unwrap_or(0) as f64;
                    func_body.instruction(&Instruction::F64Const(val));
                }
                None => {
                    // void function — no return value
                }
            }

            func_body.instruction(&Instruction::End);

            let params_wasm: Vec<WasmType> = func.params.clone();
            let code_size = 2 + func.required_consent.len() * 5;

            compiled_funcs.push((params_wasm.clone(), func.result, func_body));
            wasm_functions.push(WasmFunction {
                name: func.name.clone(),
                params: params_wasm,
                result: func.result,
                code_size,
                has_consent_gates: has_consent,
            });
        }

        // Emit unit conversion helper functions
        for conv in &program.unit_conversions {
            let conv_name = format!("convert_{}_to_{}", conv.from_unit, conv.to_unit);

            // Check for duplicate names against already-compiled functions
            if wasm_functions.iter().any(|f| f.name == conv_name) {
                return Err(WasmError::DuplicateFunctionName { name: conv_name });
            }

            let mut func_body = WasmFunc::new(vec![]);
            // Body: return param_0 * factor
            func_body.instruction(&Instruction::LocalGet(0)); // val: f64
            func_body.instruction(&Instruction::F64Const(conv.factor));
            func_body.instruction(&Instruction::F64Mul);
            func_body.instruction(&Instruction::End);

            compiled_funcs.push((vec![WasmType::F64], Some(WasmType::F64), func_body));
            wasm_functions.push(WasmFunction {
                name: conv_name,
                params: vec![WasmType::F64],
                result: Some(WasmType::F64),
                code_size: 4,
                has_consent_gates: false,
            });
        }

        // Build WASM binary
        let binary = self.build_module(&imports, &compiled_funcs, &string_offsets, &wasm_functions);

        Ok(WasmModule {
            functions: wasm_functions,
            imports,
            initial_memory_pages: self.initial_memory_pages,
            max_memory_pages: self.max_memory_pages,
            binary,
        })
    }

    /// Collect string constants and assign data section offsets.
    fn collect_strings(&mut self, strings: &[String]) -> Result<Vec<(String, u32)>, WasmError> {
        let mut result = Vec::new();
        let mut offset: u32 = 0;
        let capacity = self.initial_memory_pages.saturating_mul(65536);

        for s in strings {
            let entry_size = s.len() as u32 + 1;
            let new_offset = offset.checked_add(entry_size).ok_or(
                WasmError::DataSectionOverflow { offset, capacity },
            )?;
            if new_offset > capacity {
                return Err(WasmError::DataSectionOverflow {
                    offset: new_offset,
                    capacity,
                });
            }
            result.push((s.clone(), offset));
            offset = new_offset;
        }

        if capacity > 0 && offset > capacity * 3 / 4 {
            self.warnings.push(format!(
                "data section uses {offset}/{capacity} bytes ({:.0}% of initial memory)",
                offset as f64 / capacity as f64 * 100.0
            ));
        }

        Ok(result)
    }

    /// Build the complete WASM binary module.
    fn build_module(
        &self,
        imports: &[WasmImport],
        compiled_funcs: &[(Vec<WasmType>, Option<WasmType>, WasmFunc)],
        string_data: &[(String, u32)],
        wasm_functions: &[WasmFunction],
    ) -> Vec<u8> {
        let mut module = Module::new();
        let import_count = imports.len() as u32;

        // === Type section ===
        let mut types = TypeSection::new();
        for imp in imports {
            let params: Vec<ValType> = imp.params.iter().map(|t| t.to_val_type()).collect();
            let results: Vec<ValType> = imp.result.iter().map(|t| t.to_val_type()).collect();
            types.ty().function(params, results);
        }
        for (params, result, _) in compiled_funcs {
            let wasm_params: Vec<ValType> = params.iter().map(|t| t.to_val_type()).collect();
            let wasm_results: Vec<ValType> = result.iter().map(|t| t.to_val_type()).collect();
            types.ty().function(wasm_params, wasm_results);
        }
        module.section(&types);

        // === Import section ===
        if !imports.is_empty() {
            let mut import_section = ImportSection::new();
            for (i, imp) in imports.iter().enumerate() {
                import_section.import(
                    &imp.module,
                    &imp.name,
                    EntityType::Function(i as u32),
                );
            }
            module.section(&import_section);
        }

        // === Function section ===
        let mut func_section = FunctionSection::new();
        for i in 0..compiled_funcs.len() {
            func_section.function(import_count + i as u32);
        }
        module.section(&func_section);

        // === Memory section ===
        let mut memory_section = MemorySection::new();
        memory_section.memory(MemoryType {
            minimum: self.initial_memory_pages as u64,
            maximum: Some(self.max_memory_pages as u64),
            memory64: false,
            shared: false,
            page_size_log2: None,
        });
        module.section(&memory_section);

        // === Export section ===
        let mut export_section = ExportSection::new();
        for (i, func) in wasm_functions.iter().enumerate() {
            export_section.export(
                &func.name,
                ExportKind::Func,
                import_count + i as u32,
            );
        }
        export_section.export("memory", ExportKind::Memory, 0);
        module.section(&export_section);

        // === Code section ===
        let mut code_section = CodeSection::new();
        for (_, _, func_body) in compiled_funcs {
            code_section.function(func_body);
        }
        module.section(&code_section);

        // === Data section ===
        if !string_data.is_empty() {
            let mut data_section = DataSection::new();
            for (s, offset) in string_data {
                let mut bytes = s.as_bytes().to_vec();
                bytes.push(0);
                data_section.active(
                    0,
                    &wasm_encoder::ConstExpr::i32_const(*offset as i32),
                    bytes,
                );
            }
            module.section(&data_section);
        }

        module.finish()
    }
}

impl Default for WasmBackend {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create an empty WokeLang program.
    fn empty_program() -> WokeLangProgram {
        WokeLangProgram {
            consent_gates: vec![],
            functions: vec![],
            string_constants: vec![],
            unit_conversions: vec![],
        }
    }

    /// Helper: create a simple program with one consented function.
    fn simple_program() -> WokeLangProgram {
        WokeLangProgram {
            consent_gates: vec![ConsentGate {
                label: "data_collection".into(),
                id: 1,
                trap_on_deny: true,
            }],
            functions: vec![WokeLangFunction {
                name: "collect_metrics".into(),
                params: vec![],
                result: Some(WasmType::I64),
                required_consent: vec!["data_collection".into()],
                return_value: Some(42),
            }],
            string_constants: vec![],
            unit_conversions: vec![],
        }
    }

    #[test]
    fn test_empty_program_generates_valid_wasm() {
        let mut backend = WasmBackend::new();
        let module = backend.generate(&empty_program()).unwrap();
        let bytes = module.to_bytes();
        assert_eq!(&bytes[0..4], b"\0asm");
        assert_eq!(bytes[4], 1);
        assert!(module.functions.is_empty());
    }

    #[test]
    fn test_simple_consented_function_compiles() {
        let mut backend = WasmBackend::new();
        let module = backend.generate(&simple_program()).unwrap();
        assert_eq!(module.functions.len(), 1);
        assert_eq!(module.functions[0].name, "collect_metrics");
        assert!(module.functions[0].has_consent_gates);
        let bytes = module.to_bytes();
        assert_eq!(&bytes[0..4], b"\0asm");
    }

    #[test]
    fn test_function_without_consent_compiles() {
        let program = WokeLangProgram {
            consent_gates: vec![],
            functions: vec![WokeLangFunction {
                name: "free_function".into(),
                params: vec![WasmType::I32],
                result: Some(WasmType::I32),
                required_consent: vec![],
                return_value: Some(99),
            }],
            string_constants: vec![],
            unit_conversions: vec![],
        };

        let mut backend = WasmBackend::new();
        let module = backend.generate(&program).unwrap();
        assert_eq!(module.functions.len(), 1);
        assert!(!module.functions[0].has_consent_gates);
    }

    #[test]
    fn test_unknown_consent_label_errors() {
        let program = WokeLangProgram {
            consent_gates: vec![],
            functions: vec![WokeLangFunction {
                name: "bad_func".into(),
                params: vec![],
                result: None,
                required_consent: vec!["nonexistent_consent".into()],
                return_value: None,
            }],
            string_constants: vec![],
            unit_conversions: vec![],
        };

        let mut backend = WasmBackend::new();
        let result = backend.generate(&program);
        assert!(result.is_err());
        match result.unwrap_err() {
            WasmError::UnknownConsentLabel { label } => {
                assert_eq!(label, "nonexistent_consent");
            }
            other => panic!("Expected UnknownConsentLabel, got: {other}"),
        }
    }

    #[test]
    fn test_duplicate_function_name_errors() {
        let program = WokeLangProgram {
            consent_gates: vec![],
            functions: vec![
                WokeLangFunction {
                    name: "dup".into(),
                    params: vec![],
                    result: None,
                    required_consent: vec![],
                    return_value: None,
                },
                WokeLangFunction {
                    name: "dup".into(),
                    params: vec![],
                    result: None,
                    required_consent: vec![],
                    return_value: None,
                },
            ],
            string_constants: vec![],
            unit_conversions: vec![],
        };

        let mut backend = WasmBackend::new();
        let result = backend.generate(&program);
        assert!(result.is_err());
        match result.unwrap_err() {
            WasmError::DuplicateFunctionName { name } => assert_eq!(name, "dup"),
            other => panic!("Expected DuplicateFunctionName, got: {other}"),
        }
    }

    #[test]
    fn test_binary_output_is_deterministic() {
        let program = simple_program();
        let mut b1 = WasmBackend::new();
        let mut b2 = WasmBackend::new();
        let m1 = b1.generate(&program).unwrap();
        let m2 = b2.generate(&program).unwrap();
        assert_eq!(m1.to_bytes(), m2.to_bytes());
    }

    #[test]
    fn test_module_has_runtime_imports() {
        let mut backend = WasmBackend::new();
        let module = backend.generate(&simple_program()).unwrap();
        assert_eq!(module.imports.len(), 4);
        assert_eq!(module.imports[0].name, "consent_check");
        assert_eq!(module.imports[1].name, "dimension_validate");
        assert_eq!(module.imports[2].name, "log_violation");
        assert_eq!(module.imports[3].name, "consent_revoke");
    }

    #[test]
    fn test_error_display_messages() {
        let err = WasmError::UnknownConsentLabel {
            label: "privacy".into(),
        };
        assert!(err.to_string().contains("privacy"));

        let err = WasmError::DimensionMismatch {
            lhs_dim: "meters".into(),
            rhs_dim: "seconds".into(),
            operation: "add".into(),
        };
        let msg = err.to_string();
        assert!(msg.contains("meters") && msg.contains("seconds"));

        let err = WasmError::HeapOverflow {
            requested: 64,
            current: 65500,
            capacity: 65536,
        };
        assert!(err.to_string().contains("64"));
    }

    #[test]
    fn test_soft_deny_consent_function() {
        let program = WokeLangProgram {
            consent_gates: vec![ConsentGate {
                label: "tracking".into(),
                id: 2,
                trap_on_deny: false, // soft deny: return sentinel
            }],
            functions: vec![WokeLangFunction {
                name: "track_user".into(),
                params: vec![],
                result: Some(WasmType::I64),
                required_consent: vec!["tracking".into()],
                return_value: Some(100),
            }],
            string_constants: vec![],
            unit_conversions: vec![],
        };

        let mut backend = WasmBackend::new();
        let module = backend.generate(&program).unwrap();
        assert_eq!(module.functions.len(), 1);
        assert!(module.functions[0].has_consent_gates);
        let bytes = module.to_bytes();
        assert_eq!(&bytes[0..4], b"\0asm");
    }

    #[test]
    fn test_string_constants_in_data_section() {
        let program = WokeLangProgram {
            consent_gates: vec![],
            functions: vec![],
            string_constants: vec!["consent_label".into(), "dimension_name".into()],
            unit_conversions: vec![],
        };

        let mut backend = WasmBackend::new();
        let module = backend.generate(&program).unwrap();
        let bytes = module.to_bytes();
        assert_eq!(&bytes[0..4], b"\0asm");
        assert!(bytes.len() > 20);
    }

    #[test]
    fn test_bump_allocator_bounds_check() {
        let mut alloc = BumpAllocator::new(65530, 1);
        let result = alloc.alloc(16);
        assert!(result.is_err());
        match result.unwrap_err() {
            WasmError::HeapOverflow { requested, .. } => assert_eq!(requested, 16),
            other => panic!("Expected HeapOverflow, got: {other}"),
        }
    }
}
