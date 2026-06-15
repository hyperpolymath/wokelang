// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Debug Adapter Protocol (DAP) implementation for WokeLang
//!
//! This module provides a minimal DAP adapter for WokeLang.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
pub struct DapRequest {
    pub seq: i64,
    pub r#type: String,
    pub command: String,
    pub arguments: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
pub struct DapResponse {
    pub seq: i64,
    pub r#type: String,
    pub request_seq: i64,
    pub command: String,
    pub success: bool,
    pub message: Option<String>,
    pub body: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
pub struct InitializeResponse {
    pub supports_configuration_done_request: bool,
    pub supports_function_breakpoints: bool,
    pub supports_conditional_breakpoints: bool,
    pub supports_evaluate_for_hovers: bool,
    pub exception_breakpoint_filters: Vec<ExceptionBreakpointFilter>,
}

#[derive(Debug, Serialize)]
pub struct ExceptionBreakpointFilter {
    pub filter: String,
    pub label: String,
    pub r#default: bool,
}

#[derive(Debug, Serialize)]
pub struct LaunchResponse {
    pub success: bool,
}

#[derive(Debug, Serialize)]
pub struct SetBreakpointsResponse {
    pub breakpoints: Vec<Breakpoint>,
}

#[derive(Debug, Serialize)]
pub struct Breakpoint {
    pub verified: bool,
    pub line: usize,
}

#[derive(Debug, Serialize)]
pub struct ThreadsResponse {
    pub threads: Vec<Thread>,
}

#[derive(Debug, Serialize)]
pub struct Thread {
    pub id: i64,
    pub name: String,
}

#[derive(Debug, Serialize)]
pub struct StackTraceResponse {
    pub stack_frames: Vec<StackFrame>,
}

#[derive(Debug, Serialize)]
pub struct StackFrame {
    pub id: i64,
    pub name: String,
    pub source: Option<Source>,
    pub line: i64,
    pub column: i64,
}

#[derive(Debug, Serialize)]
pub struct Source {
    pub path: Option<String>,
    pub source_reference: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct ScopesResponse {
    pub scopes: Vec<Scope>,
}

#[derive(Debug, Serialize)]
pub struct Scope {
    pub name: String,
    pub variables_reference: i64,
    pub expensive: bool,
}

#[derive(Debug, Serialize)]
pub struct VariablesResponse {
    pub variables: Vec<Variable>,
}

#[derive(Debug, Serialize)]
pub struct Variable {
    pub name: String,
    pub value: String,
    pub r#type: Option<String>,
}

pub struct DapServer {
    pub breakpoints: HashMap<String, Vec<usize>>,
    pub current_thread: i64,
    pub call_stack: Vec<String>,
    pub variables: HashMap<String, String>,
}

impl Default for DapServer {
    fn default() -> Self {
        Self::new()
    }
}

impl DapServer {
    pub fn new() -> Self {
        Self {
            breakpoints: HashMap::new(),
            current_thread: 1,
            call_stack: vec!["main".to_string()],
            variables: HashMap::new(),
        }
    }

    pub fn handle_request(&mut self, request: DapRequest) -> DapResponse {
        match request.command.as_str() {
            "initialize" => self.handle_initialize(request),
            "launch" => self.handle_launch(request),
            "configurationDone" => self.handle_configuration_done(request),
            "setBreakpoints" => self.handle_set_breakpoints(request),
            "threads" => self.handle_threads(request),
            "stackTrace" => self.handle_stack_trace(request),
            "scopes" => self.handle_scopes(request),
            "variables" => self.handle_variables(request),
            "continue" => self.handle_continue(request),
            "next" => self.handle_next(request),
            "stepIn" => self.handle_step_in(request),
            "stepOut" => self.handle_step_out(request),
            "disconnect" => self.handle_disconnect(request),
            _ => DapResponse {
                seq: 0,
                r#type: "response".to_string(),
                request_seq: request.seq,
                command: request.command,
                success: false,
                message: Some("Unknown command".to_string()),
                body: None,
            },
        }
    }

    fn handle_initialize(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 1,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "initialize".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(InitializeResponse {
                    supports_configuration_done_request: true,
                    supports_function_breakpoints: true,
                    supports_conditional_breakpoints: true,
                    supports_evaluate_for_hovers: true,
                    exception_breakpoint_filters: vec![],
                })
                .unwrap(),
            ),
        }
    }

    fn handle_launch(&mut self, _request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 2,
            r#type: "response".to_string(),
            request_seq: _request.seq,
            command: "launch".to_string(),
            success: true,
            message: None,
            body: Some(serde_json::to_value(LaunchResponse { success: true }).unwrap()),
        }
    }

    fn handle_configuration_done(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 3,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "configurationDone".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }

    fn handle_set_breakpoints(&mut self, request: DapRequest) -> DapResponse {
        if let Some(args) = request.arguments {
            if let Some(source) = args.get("source") {
                if let Some(path) = source.get("path") {
                    if let Some(bps) = args.get("breakpoints") {
                        if let Some(lines) = bps.as_array() {
                            let breakpoints = lines
                                .iter()
                                .filter_map(|line| line.get("line").and_then(|l| l.as_u64()))
                                .map(|line| line as usize)
                                .collect();
                            self.breakpoints
                                .insert(path.as_str().unwrap().to_string(), breakpoints);
                        }
                    }
                }
            }
        }

        DapResponse {
            seq: 4,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "setBreakpoints".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(SetBreakpointsResponse {
                    breakpoints: vec![],
                })
                .unwrap(),
            ),
        }
    }

    fn handle_threads(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 5,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "threads".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(ThreadsResponse {
                    threads: vec![Thread {
                        id: self.current_thread,
                        name: "main".to_string(),
                    }],
                })
                .unwrap(),
            ),
        }
    }

    fn handle_stack_trace(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 6,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "stackTrace".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(StackTraceResponse {
                    stack_frames: self
                        .call_stack
                        .iter()
                        .enumerate()
                        .map(|(i, name)| StackFrame {
                            id: i as i64,
                            name: name.clone(),
                            source: Some(Source {
                                path: Some("file.wl".to_string()),
                                source_reference: None,
                            }),
                            line: i as i64,
                            column: 0,
                        })
                        .collect(),
                })
                .unwrap(),
            ),
        }
    }

    fn handle_scopes(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 7,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "scopes".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(ScopesResponse {
                    scopes: vec![Scope {
                        name: "Locals".to_string(),
                        variables_reference: 1,
                        expensive: false,
                    }],
                })
                .unwrap(),
            ),
        }
    }

    fn handle_variables(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 8,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "variables".to_string(),
            success: true,
            message: None,
            body: Some(
                serde_json::to_value(VariablesResponse {
                    variables: self
                        .variables
                        .iter()
                        .map(|(name, value)| Variable {
                            name: name.clone(),
                            value: value.clone(),
                            r#type: None,
                        })
                        .collect(),
                })
                .unwrap(),
            ),
        }
    }

    fn handle_continue(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 9,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "continue".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }

    fn handle_next(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 10,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "next".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }

    fn handle_step_in(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 11,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "stepIn".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }

    fn handle_step_out(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 12,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "stepOut".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }

    fn handle_disconnect(&self, request: DapRequest) -> DapResponse {
        DapResponse {
            seq: 13,
            r#type: "response".to_string(),
            request_seq: request.seq,
            command: "disconnect".to_string(),
            success: true,
            message: None,
            body: None,
        }
    }
}
