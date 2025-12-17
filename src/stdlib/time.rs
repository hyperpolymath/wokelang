//! WokeLang Standard Library - Time Module
//!
//! Date and time handling functions.

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use super::{check_arity, expect_int, expect_string, StdlibError};
use std::collections::HashMap;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

// Thread-local storage for elapsed time tracking
thread_local! {
    static START_TIMES: std::cell::RefCell<HashMap<String, Instant>> = std::cell::RefCell::new(HashMap::new());
}

/// Get current timestamp as milliseconds since epoch
pub fn now(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 0)?;

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0);

    Ok(Value::Int(timestamp))
}

/// Get current timestamp as seconds since epoch
pub fn timestamp(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 0)?;

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);

    Ok(Value::Int(timestamp))
}

/// Format a timestamp to a string
/// format(timestamp, format_string)
/// Format tokens: %Y=year, %m=month, %d=day, %H=hour, %M=minute, %S=second
pub fn format(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let timestamp_ms = expect_int(&args[0], "timestamp")?;
    let format_str = expect_string(&args[1], "format")?;

    // Convert milliseconds to components
    let total_secs = timestamp_ms / 1000;
    let (year, month, day, hour, minute, second) = timestamp_to_components(total_secs);

    // Simple format replacement
    let result = format_str
        .replace("%Y", &format!("{:04}", year))
        .replace("%m", &format!("{:02}", month))
        .replace("%d", &format!("{:02}", day))
        .replace("%H", &format!("{:02}", hour))
        .replace("%M", &format!("{:02}", minute))
        .replace("%S", &format!("{:02}", second));

    Ok(Value::String(result))
}

/// Parse a date string to timestamp
/// parse(date_string, format_string)
pub fn parse(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let date_str = expect_string(&args[0], "date")?;
    let format_str = expect_string(&args[1], "format")?;

    // Simple parsing for ISO-like formats
    let result = parse_date_string(&date_str, &format_str)?;
    Ok(Value::Int(result))
}

/// Sleep for a given number of milliseconds
pub fn sleep(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let ms = expect_int(&args[0], "milliseconds")?;

    if ms > 0 {
        std::thread::sleep(Duration::from_millis(ms as u64));
    }

    Ok(Value::Unit)
}

/// Start or get elapsed time for a named timer
/// elapsed("start", "timer_name") - starts a timer
/// elapsed("stop", "timer_name") - returns elapsed milliseconds
pub fn elapsed(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let action = expect_string(&args[0], "action")?;
    let name = expect_string(&args[1], "name")?;

    match action.as_str() {
        "start" => {
            START_TIMES.with(|times| {
                times.borrow_mut().insert(name, Instant::now());
            });
            Ok(Value::Unit)
        }
        "stop" | "get" => {
            let elapsed = START_TIMES.with(|times| {
                times
                    .borrow()
                    .get(&name)
                    .map(|start| start.elapsed().as_millis() as i64)
            });

            match elapsed {
                Some(ms) => Ok(Value::Int(ms)),
                None => Err(StdlibError::RuntimeError(format!(
                    "Timer '{}' not started",
                    name
                ))),
            }
        }
        "reset" => {
            START_TIMES.with(|times| {
                times.borrow_mut().remove(&name);
            });
            Ok(Value::Unit)
        }
        _ => Err(StdlibError::RuntimeError(format!(
            "Unknown timer action: {}. Use 'start', 'stop', 'get', or 'reset'",
            action
        ))),
    }
}

/// Convert timestamp (seconds since epoch) to date components
fn timestamp_to_components(total_secs: i64) -> (i32, u32, u32, u32, u32, u32) {
    // Simple conversion (ignores leap seconds)
    let days_since_epoch = total_secs / 86400;
    let time_of_day = total_secs % 86400;

    let hour = (time_of_day / 3600) as u32;
    let minute = ((time_of_day % 3600) / 60) as u32;
    let second = (time_of_day % 60) as u32;

    // Convert days to year/month/day
    // Using a simplified algorithm (not accounting for all edge cases)
    let (year, month, day) = days_to_ymd(days_since_epoch as i32);

    (year, month, day, hour, minute, second)
}

/// Convert days since epoch to year/month/day
fn days_to_ymd(days: i32) -> (i32, u32, u32) {
    // Days from 1970-01-01
    let mut remaining = days;
    let mut year = 1970;

    // Find year
    loop {
        let days_in_year = if is_leap_year(year) { 366 } else { 365 };
        if remaining < days_in_year {
            break;
        }
        remaining -= days_in_year;
        year += 1;
    }

    // Find month
    let days_in_months = if is_leap_year(year) {
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    } else {
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    };

    let mut month = 1u32;
    for days_in_month in days_in_months.iter() {
        if remaining < *days_in_month {
            break;
        }
        remaining -= days_in_month;
        month += 1;
    }

    let day = (remaining + 1) as u32;

    (year, month, day)
}

fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

/// Parse a date string given a format
fn parse_date_string(date_str: &str, format_str: &str) -> Result<i64, StdlibError> {
    // Support common formats
    let date_str = date_str.trim();

    // Try ISO 8601 format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS
    if format_str.contains("%Y") && format_str.contains("%m") && format_str.contains("%d") {
        let parts: Vec<&str> = date_str.split(|c| c == '-' || c == 'T' || c == ':' || c == ' ')
            .collect();

        if parts.len() >= 3 {
            let year: i32 = parts[0]
                .parse()
                .map_err(|_| StdlibError::ParseError("Invalid year".to_string()))?;
            let month: u32 = parts[1]
                .parse()
                .map_err(|_| StdlibError::ParseError("Invalid month".to_string()))?;
            let day: u32 = parts[2]
                .parse()
                .map_err(|_| StdlibError::ParseError("Invalid day".to_string()))?;

            let hour: u32 = parts.get(3).and_then(|s| s.parse().ok()).unwrap_or(0);
            let minute: u32 = parts.get(4).and_then(|s| s.parse().ok()).unwrap_or(0);
            let second: u32 = parts.get(5).and_then(|s| s.parse().ok()).unwrap_or(0);

            let timestamp = ymd_to_timestamp(year, month, day, hour, minute, second);
            return Ok(timestamp * 1000); // Return milliseconds
        }
    }

    Err(StdlibError::ParseError(format!(
        "Could not parse date '{}' with format '{}'",
        date_str, format_str
    )))
}

/// Convert year/month/day to timestamp
fn ymd_to_timestamp(year: i32, month: u32, day: u32, hour: u32, minute: u32, second: u32) -> i64 {
    // Days from 1970 to start of year
    let mut days: i64 = 0;

    if year >= 1970 {
        for y in 1970..year {
            days += if is_leap_year(y) { 366 } else { 365 };
        }
    } else {
        for y in year..1970 {
            days -= if is_leap_year(y) { 366 } else { 365 };
        }
    }

    // Days in current year
    let days_in_months = if is_leap_year(year) {
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    } else {
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    };

    for m in 0..(month - 1) as usize {
        days += days_in_months[m] as i64;
    }
    days += (day - 1) as i64;

    // Convert to seconds
    days * 86400 + (hour as i64) * 3600 + (minute as i64) * 60 + (second as i64)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    #[test]
    fn test_now() {
        let mut caps = test_caps();
        let result = now(&[], &mut caps).unwrap();
        match result {
            Value::Int(ts) => assert!(ts > 0),
            _ => panic!("Expected integer"),
        }
    }

    #[test]
    fn test_timestamp() {
        let mut caps = test_caps();
        let result = timestamp(&[], &mut caps).unwrap();
        match result {
            Value::Int(ts) => assert!(ts > 0),
            _ => panic!("Expected integer"),
        }
    }

    #[test]
    fn test_format() {
        let mut caps = test_caps();
        // 2024-01-15 12:30:45 UTC
        let ts = 1705322445000i64; // milliseconds

        let result = format(
            &[Value::Int(ts), Value::String("%Y-%m-%d".to_string())],
            &mut caps,
        )
        .unwrap();

        assert_eq!(result, Value::String("2024-01-15".to_string()));
    }

    #[test]
    fn test_parse() {
        let mut caps = test_caps();

        let result = parse(
            &[
                Value::String("2024-01-15".to_string()),
                Value::String("%Y-%m-%d".to_string()),
            ],
            &mut caps,
        )
        .unwrap();

        match result {
            Value::Int(ts) => {
                // Should be midnight UTC on 2024-01-15
                assert!(ts > 0);
            }
            _ => panic!("Expected integer"),
        }
    }

    #[test]
    fn test_sleep() {
        let mut caps = test_caps();
        let start = Instant::now();

        sleep(&[Value::Int(50)], &mut caps).unwrap();

        let elapsed = start.elapsed().as_millis();
        assert!(elapsed >= 50);
    }

    #[test]
    fn test_elapsed() {
        let mut caps = test_caps();

        // Start timer
        elapsed(
            &[
                Value::String("start".to_string()),
                Value::String("test_timer".to_string()),
            ],
            &mut caps,
        )
        .unwrap();

        // Sleep a bit
        std::thread::sleep(Duration::from_millis(20));

        // Get elapsed
        let result = elapsed(
            &[
                Value::String("stop".to_string()),
                Value::String("test_timer".to_string()),
            ],
            &mut caps,
        )
        .unwrap();

        match result {
            Value::Int(ms) => assert!(ms >= 20),
            _ => panic!("Expected integer"),
        }

        // Reset
        elapsed(
            &[
                Value::String("reset".to_string()),
                Value::String("test_timer".to_string()),
            ],
            &mut caps,
        )
        .unwrap();
    }

    #[test]
    fn test_days_to_ymd() {
        // 1970-01-01
        assert_eq!(days_to_ymd(0), (1970, 1, 1));
        // 2000-01-01 (10957 days from epoch)
        assert_eq!(days_to_ymd(10957), (2000, 1, 1));
    }
}
