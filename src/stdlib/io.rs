//! WokeLang Standard Library - I/O Module
//!
//! File I/O operations that require explicit consent through capabilities.

use crate::interpreter::Value;
use crate::security::{Capability, CapabilityRegistry};
use super::{check_arity, check_arity_range, expect_string, StdlibError};
use std::fs;
use std::io::{self, BufRead, Write};
use std::path::PathBuf;

/// Helper to require file read capability
fn require_read(path: &str, caps: &mut CapabilityRegistry) -> Result<(), StdlibError> {
    let cap = Capability::FileRead(Some(PathBuf::from(path)));
    if caps.request("stdlib", &cap).is_err() {
        Err(StdlibError::PermissionDenied(format!(
            "File read access denied: {}",
            path
        )))
    } else {
        Ok(())
    }
}

/// Helper to require file write capability
fn require_write(path: &str, caps: &mut CapabilityRegistry) -> Result<(), StdlibError> {
    let cap = Capability::FileWrite(Some(PathBuf::from(path)));
    if caps.request("stdlib", &cap).is_err() {
        Err(StdlibError::PermissionDenied(format!(
            "File write access denied: {}",
            path
        )))
    } else {
        Ok(())
    }
}

/// Read entire file contents as a string
pub fn read_file(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let path = expect_string(&args[0], "path")?;

    require_read(&path, caps)?;

    match fs::read_to_string(&path) {
        Ok(contents) => Ok(Value::String(contents)),
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// Write string contents to a file
pub fn write_file(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let path = expect_string(&args[0], "path")?;
    let contents = expect_string(&args[1], "contents")?;

    require_write(&path, caps)?;

    match fs::write(&path, &contents) {
        Ok(()) => Ok(Value::Bool(true)),
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// Append string contents to a file
pub fn append_file(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let path = expect_string(&args[0], "path")?;
    let contents = expect_string(&args[1], "contents")?;

    require_write(&path, caps)?;

    use std::fs::OpenOptions;
    match OpenOptions::new().create(true).append(true).open(&path) {
        Ok(mut file) => match file.write_all(contents.as_bytes()) {
            Ok(()) => Ok(Value::Bool(true)),
            Err(e) => Err(StdlibError::IoError(e.to_string())),
        },
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// Check if a file or directory exists
pub fn exists(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let path = expect_string(&args[0], "path")?;

    // exists only needs read capability to check
    require_read(&path, caps)?;

    Ok(Value::Bool(std::path::Path::new(&path).exists()))
}

/// Delete a file
pub fn delete(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let path = expect_string(&args[0], "path")?;

    require_write(&path, caps)?;

    match fs::remove_file(&path) {
        Ok(()) => Ok(Value::Bool(true)),
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// List directory contents
pub fn list_dir(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let path = expect_string(&args[0], "path")?;

    require_read(&path, caps)?;

    match fs::read_dir(&path) {
        Ok(entries) => {
            let files: Vec<Value> = entries
                .filter_map(|e| e.ok())
                .map(|e| Value::String(e.file_name().to_string_lossy().to_string()))
                .collect();
            Ok(Value::Array(files))
        }
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// Create a directory (and parents if needed)
pub fn create_dir(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let path = expect_string(&args[0], "path")?;

    require_write(&path, caps)?;

    match fs::create_dir_all(&path) {
        Ok(()) => Ok(Value::Bool(true)),
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

/// Read a line from stdin (interactive)
pub fn read_line(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 0, 1)?;

    // Print optional prompt
    if let Some(prompt) = args.first() {
        let prompt_str = expect_string(prompt, "prompt")?;
        print!("{}", prompt_str);
        io::stdout().flush().ok();
    }

    let stdin = io::stdin();
    let mut line = String::new();
    match stdin.lock().read_line(&mut line) {
        Ok(_) => Ok(Value::String(line.trim_end_matches('\n').to_string())),
        Err(e) => Err(StdlibError::IoError(e.to_string())),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    fn temp_file(name: &str) -> String {
        env::temp_dir()
            .join(format!("wokelang_test_{}", name))
            .to_string_lossy()
            .to_string()
    }

    #[test]
    fn test_write_and_read() {
        let mut caps = test_caps();
        let path = temp_file("io_test.txt");

        // Write
        let write_result = write_file(
            &[Value::String(path.clone()), Value::String("Hello, WokeLang!".to_string())],
            &mut caps,
        );
        assert!(write_result.is_ok());

        // Read
        let read_result = read_file(&[Value::String(path.clone())], &mut caps);
        assert_eq!(
            read_result.unwrap(),
            Value::String("Hello, WokeLang!".to_string())
        );

        // Cleanup
        let _ = fs::remove_file(&path);
    }

    #[test]
    fn test_exists() {
        let mut caps = test_caps();
        let path = temp_file("exists_test.txt");

        // Should not exist yet
        let result = exists(&[Value::String(path.clone())], &mut caps);
        assert_eq!(result.unwrap(), Value::Bool(false));

        // Create file
        fs::write(&path, "test").unwrap();

        // Should exist now
        let result = exists(&[Value::String(path.clone())], &mut caps);
        assert_eq!(result.unwrap(), Value::Bool(true));

        // Cleanup
        let _ = fs::remove_file(&path);
    }

    #[test]
    fn test_append() {
        let mut caps = test_caps();
        let path = temp_file("append_test.txt");

        // Write initial content
        write_file(
            &[Value::String(path.clone()), Value::String("Hello".to_string())],
            &mut caps,
        )
        .unwrap();

        // Append
        append_file(
            &[Value::String(path.clone()), Value::String(", World!".to_string())],
            &mut caps,
        )
        .unwrap();

        // Read and verify
        let result = read_file(&[Value::String(path.clone())], &mut caps);
        assert_eq!(
            result.unwrap(),
            Value::String("Hello, World!".to_string())
        );

        // Cleanup
        let _ = fs::remove_file(&path);
    }

    #[test]
    fn test_delete() {
        let mut caps = test_caps();
        let path = temp_file("delete_test.txt");

        // Create file
        fs::write(&path, "test").unwrap();
        assert!(std::path::Path::new(&path).exists());

        // Delete
        let result = delete(&[Value::String(path.clone())], &mut caps);
        assert!(result.is_ok());
        assert!(!std::path::Path::new(&path).exists());
    }

    #[test]
    fn test_create_dir_and_list() {
        let mut caps = test_caps();
        let dir_path = temp_file("test_dir");

        // Create directory
        create_dir(&[Value::String(dir_path.clone())], &mut caps).unwrap();
        assert!(std::path::Path::new(&dir_path).is_dir());

        // Create a file in the directory
        let file_path = format!("{}/test.txt", dir_path);
        fs::write(&file_path, "test").unwrap();

        // List directory
        let result = list_dir(&[Value::String(dir_path.clone())], &mut caps);
        match result.unwrap() {
            Value::Array(files) => {
                assert!(files.contains(&Value::String("test.txt".to_string())));
            }
            _ => panic!("Expected array"),
        }

        // Cleanup
        let _ = fs::remove_dir_all(&dir_path);
    }
}
