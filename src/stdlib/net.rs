//! WokeLang Standard Library - Network Module
//!
//! HTTP and network operations that require explicit consent.

use crate::interpreter::Value;
use crate::security::{Capability, CapabilityRegistry};
use super::{check_arity, check_arity_range, expect_string, StdlibError};
use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;
use std::time::Duration;

/// Helper to require network capability
fn require_network(host: &str, caps: &mut CapabilityRegistry) -> Result<(), StdlibError> {
    let cap = Capability::Network(Some(host.to_string()));
    if caps.request("stdlib", &cap).is_err() {
        Err(StdlibError::PermissionDenied(format!(
            "Network access denied: {}",
            host
        )))
    } else {
        Ok(())
    }
}

/// Parse a URL into components
fn parse_url(url: &str) -> Result<(String, String, u16, String), StdlibError> {
    let url = url.trim();

    // Remove protocol
    let (is_https, rest) = if url.starts_with("https://") {
        (true, &url[8..])
    } else if url.starts_with("http://") {
        (false, &url[7..])
    } else {
        (false, url)
    };

    // Split host and path
    let (host_port, path) = match rest.find('/') {
        Some(idx) => (&rest[..idx], &rest[idx..]),
        None => (rest, "/"),
    };

    // Parse host and port
    let (host, port) = match host_port.find(':') {
        Some(idx) => {
            let port: u16 = host_port[idx + 1..]
                .parse()
                .map_err(|_| StdlibError::NetworkError("Invalid port".to_string()))?;
            (&host_port[..idx], port)
        }
        None => {
            let default_port = if is_https { 443 } else { 80 };
            (host_port, default_port)
        }
    };

    Ok((
        if is_https { "https" } else { "http" }.to_string(),
        host.to_string(),
        port,
        path.to_string(),
    ))
}

/// Make an HTTP GET request
pub fn http_get(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 1, 2)?;
    let url = expect_string(&args[0], "url")?;

    let (protocol, host, port, path) = parse_url(&url)?;

    // Check capability
    require_network(&host, caps)?;

    // For HTTPS, we can't do it without TLS library - return error
    if protocol == "https" {
        return Err(StdlibError::NetworkError(
            "HTTPS not supported without TLS library. Use HTTP or compile with TLS support.".to_string(),
        ));
    }

    // Make HTTP request
    let response = http_request(&host, port, "GET", &path, None, None)?;
    Ok(Value::String(response))
}

/// Make an HTTP POST request
pub fn http_post(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 2, 3)?;
    let url = expect_string(&args[0], "url")?;
    let body = expect_string(&args[1], "body")?;

    let content_type = if args.len() > 2 {
        expect_string(&args[2], "content_type")?
    } else {
        "application/json".to_string()
    };

    let (protocol, host, port, path) = parse_url(&url)?;

    // Check capability
    require_network(&host, caps)?;

    // For HTTPS, we can't do it without TLS library
    if protocol == "https" {
        return Err(StdlibError::NetworkError(
            "HTTPS not supported without TLS library".to_string(),
        ));
    }

    // Make HTTP request
    let response = http_request(&host, port, "POST", &path, Some(&body), Some(&content_type))?;
    Ok(Value::String(response))
}

/// Download a file from a URL
pub fn download(args: &[Value], caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let url = expect_string(&args[0], "url")?;
    let dest_path = expect_string(&args[1], "path")?;

    let (protocol, host, port, path) = parse_url(&url)?;

    // Check network capability
    require_network(&host, caps)?;

    // Check file write capability
    let file_cap = Capability::FileWrite(Some(std::path::PathBuf::from(&dest_path)));
    if caps.request("stdlib", &file_cap).is_err() {
        return Err(StdlibError::PermissionDenied(format!(
            "File write access denied: {}",
            dest_path
        )));
    }

    // For HTTPS, we can't do it without TLS library
    if protocol == "https" {
        return Err(StdlibError::NetworkError(
            "HTTPS not supported without TLS library".to_string(),
        ));
    }

    // Make HTTP request
    let response = http_request_binary(&host, port, "GET", &path)?;

    // Write to file
    std::fs::write(&dest_path, response)
        .map_err(|e| StdlibError::IoError(e.to_string()))?;

    Ok(Value::Bool(true))
}

/// Make an HTTP request and return the response body as string
fn http_request(
    host: &str,
    port: u16,
    method: &str,
    path: &str,
    body: Option<&str>,
    content_type: Option<&str>,
) -> Result<String, StdlibError> {
    let bytes = http_request_binary_with_body(host, port, method, path, body, content_type)?;
    String::from_utf8(bytes).map_err(|e| StdlibError::NetworkError(e.to_string()))
}

/// Make an HTTP request and return the response body as bytes
fn http_request_binary(host: &str, port: u16, method: &str, path: &str) -> Result<Vec<u8>, StdlibError> {
    http_request_binary_with_body(host, port, method, path, None, None)
}

/// Make an HTTP request with optional body
fn http_request_binary_with_body(
    host: &str,
    port: u16,
    method: &str,
    path: &str,
    body: Option<&str>,
    content_type: Option<&str>,
) -> Result<Vec<u8>, StdlibError> {
    // Connect
    let addr = format!("{}:{}", host, port);
    let mut stream = TcpStream::connect(&addr)
        .map_err(|e| StdlibError::NetworkError(format!("Connection failed: {}", e)))?;

    stream
        .set_read_timeout(Some(Duration::from_secs(30)))
        .ok();
    stream
        .set_write_timeout(Some(Duration::from_secs(30)))
        .ok();

    // Build request
    let mut request = format!("{} {} HTTP/1.1\r\n", method, path);
    request.push_str(&format!("Host: {}\r\n", host));
    request.push_str("User-Agent: WokeLang/1.0\r\n");
    request.push_str("Connection: close\r\n");

    if let Some(body_content) = body {
        let content_type = content_type.unwrap_or("application/octet-stream");
        request.push_str(&format!("Content-Type: {}\r\n", content_type));
        request.push_str(&format!("Content-Length: {}\r\n", body_content.len()));
        request.push_str("\r\n");
        request.push_str(body_content);
    } else {
        request.push_str("\r\n");
    }

    // Send request
    stream
        .write_all(request.as_bytes())
        .map_err(|e| StdlibError::NetworkError(format!("Send failed: {}", e)))?;

    // Read response
    let mut reader = BufReader::new(&stream);

    // Read status line
    let mut status_line = String::new();
    reader
        .read_line(&mut status_line)
        .map_err(|e| StdlibError::NetworkError(format!("Read failed: {}", e)))?;

    // Parse status
    let status_parts: Vec<&str> = status_line.split_whitespace().collect();
    if status_parts.len() < 2 {
        return Err(StdlibError::NetworkError("Invalid HTTP response".to_string()));
    }
    let status_code: u16 = status_parts[1]
        .parse()
        .map_err(|_| StdlibError::NetworkError("Invalid status code".to_string()))?;

    // Read headers
    let mut content_length: Option<usize> = None;
    let mut chunked = false;

    loop {
        let mut header = String::new();
        reader
            .read_line(&mut header)
            .map_err(|e| StdlibError::NetworkError(format!("Read header failed: {}", e)))?;

        let header = header.trim();
        if header.is_empty() {
            break;
        }

        let lower = header.to_lowercase();
        if lower.starts_with("content-length:") {
            content_length = header[15..].trim().parse().ok();
        } else if lower.starts_with("transfer-encoding:") && lower.contains("chunked") {
            chunked = true;
        }
    }

    // Read body
    let body = if chunked {
        read_chunked_body(&mut reader)?
    } else if let Some(len) = content_length {
        let mut buf = vec![0u8; len];
        reader
            .read_exact(&mut buf)
            .map_err(|e| StdlibError::NetworkError(format!("Read body failed: {}", e)))?;
        buf
    } else {
        // Read until connection closes
        let mut buf = Vec::new();
        reader
            .read_to_end(&mut buf)
            .map_err(|e| StdlibError::NetworkError(format!("Read body failed: {}", e)))?;
        buf
    };

    // Check for error status codes
    if status_code >= 400 {
        let body_str = String::from_utf8_lossy(&body);
        return Err(StdlibError::NetworkError(format!(
            "HTTP {} error: {}",
            status_code, body_str
        )));
    }

    Ok(body)
}

/// Read chunked transfer encoding body
fn read_chunked_body<R: BufRead>(reader: &mut R) -> Result<Vec<u8>, StdlibError> {
    let mut body = Vec::new();

    loop {
        // Read chunk size line
        let mut size_line = String::new();
        reader
            .read_line(&mut size_line)
            .map_err(|e| StdlibError::NetworkError(format!("Read chunk size failed: {}", e)))?;

        let size = usize::from_str_radix(size_line.trim(), 16)
            .map_err(|_| StdlibError::NetworkError("Invalid chunk size".to_string()))?;

        if size == 0 {
            // Read trailing CRLF
            let mut trailing = String::new();
            reader.read_line(&mut trailing).ok();
            break;
        }

        // Read chunk data
        let mut chunk = vec![0u8; size];
        reader
            .read_exact(&mut chunk)
            .map_err(|e| StdlibError::NetworkError(format!("Read chunk failed: {}", e)))?;
        body.extend(chunk);

        // Read trailing CRLF
        let mut crlf = [0u8; 2];
        reader.read_exact(&mut crlf).ok();
    }

    Ok(body)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_url() {
        let (proto, host, port, path) = parse_url("http://example.com/path").unwrap();
        assert_eq!(proto, "http");
        assert_eq!(host, "example.com");
        assert_eq!(port, 80);
        assert_eq!(path, "/path");

        let (proto, host, port, path) = parse_url("https://example.com:8443/api/v1").unwrap();
        assert_eq!(proto, "https");
        assert_eq!(host, "example.com");
        assert_eq!(port, 8443);
        assert_eq!(path, "/api/v1");

        let (proto, host, port, path) = parse_url("example.com").unwrap();
        assert_eq!(host, "example.com");
        assert_eq!(port, 80);
        assert_eq!(path, "/");
    }

    // Network tests would require a test server, so we just test URL parsing
    #[test]
    fn test_require_network_denied() {
        let mut caps = CapabilityRegistry::new();
        caps.set_interactive(false);
        caps.set_default_consent(false);

        let result = require_network("example.com", &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_require_network_granted() {
        let mut caps = CapabilityRegistry::permissive();

        let result = require_network("example.com", &mut caps);
        assert!(result.is_ok());
    }
}
