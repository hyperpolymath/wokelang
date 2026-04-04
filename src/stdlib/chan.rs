// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
//! WokeLang Standard Library - Channel Module
//!
//! Go-style channels for concurrent communication between workers.
//! Channels are typed, thread-safe communication primitives that
//! support buffered and unbuffered modes, timeouts, non-blocking
//! operations, and multi-channel select.
//!
//! ## Channel operations
//!
//! | Function      | Signature                            | Description                  |
//! |---------------|--------------------------------------|------------------------------|
//! | `make`        | `() -> Channel` or `(cap) -> Channel`| Create unbuffered/buffered   |
//! | `send`        | `(ch, value) -> Bool / Oops`         | Send a value                 |
//! | `recv`        | `(ch) -> Okay(value) / Oops`         | Blocking receive             |
//! | `tryRecv`     | `(ch) -> Okay(value) / Oops`         | Non-blocking receive         |
//! | `recvTimeout` | `(ch, ms) -> Okay(value) / Oops`     | Receive with timeout         |
//! | `close`       | `(ch) -> Bool`                       | Close a channel              |
//! | `isClosed`    | `(ch) -> Bool`                       | Check if closed              |
//! | `len`         | `(ch) -> Int`                        | Pending item count           |
//! | `select`      | `([ch1, ch2, ...], ms) -> Okay([idx, value]) / Oops` | Multi-channel receive |

use super::{check_arity, check_arity_range, expect_int, StdlibError};
use crate::interpreter::{ChannelHandle, Value};
use crate::security::CapabilityRegistry;

use std::thread;
use std::time::{Duration, Instant};

/// Maximum channel buffer size to prevent unbounded memory use.
const MAX_BUFFER_SIZE: usize = 10_000;

/// Default poll interval for select (microseconds).
/// Balances latency (lower = faster reaction) against CPU usage.
const SELECT_POLL_INTERVAL_US: u64 = 250;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Extract a `&ChannelHandle` from a `Value`, returning a typed error on
/// mismatch.
fn expect_channel(value: &Value) -> Result<&ChannelHandle, StdlibError> {
    match value {
        Value::Channel(ch) => Ok(ch),
        other => Err(StdlibError::TypeError {
            expected: "Channel".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

// ---------------------------------------------------------------------------
// Public stdlib functions
// ---------------------------------------------------------------------------

/// Create a new channel.
///
/// ```text
/// make_chan()          -> Channel   (unbuffered / rendezvous)
/// make_chan(capacity)  -> Channel   (buffered)
/// ```
///
/// Capacity must be in `0..=MAX_BUFFER_SIZE`. A capacity of `0` yields an
/// unbuffered channel where `send` will succeed only once a corresponding
/// `recv` is waiting (or the Rust mpsc approximation thereof).
pub fn make_chan(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity_range(args, 0, 1)?;

    let capacity = if args.is_empty() {
        0
    } else {
        let cap = expect_int(&args[0], "capacity")?;
        if cap < 0 {
            return Err(StdlibError::RuntimeError(
                "channel capacity cannot be negative".to_string(),
            ));
        }
        if cap as usize > MAX_BUFFER_SIZE {
            return Err(StdlibError::RuntimeError(format!(
                "channel capacity too large (max {})",
                MAX_BUFFER_SIZE
            )));
        }
        cap as usize
    };

    let channel = if capacity == 0 {
        ChannelHandle::new()
    } else {
        ChannelHandle::buffered(capacity)
    };

    Ok(Value::Channel(channel))
}

/// Send a value on a channel.
///
/// ```text
/// send(channel, value) -> Bool(true) on success
/// send(channel, value) -> Oops(msg)  on failure (closed / disconnected)
/// ```
pub fn send(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let channel = expect_channel(&args[0])?;

    match channel.send(args[1].clone()) {
        Ok(()) => Ok(Value::Bool(true)),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Receive a value from a channel (blocking).
///
/// Blocks until a value is available or the channel is disconnected.
///
/// ```text
/// recv(channel) -> Okay(value)
/// recv(channel) -> Oops(msg)
/// ```
pub fn recv(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let channel = expect_channel(&args[0])?;

    match channel.recv() {
        Ok(value) => Ok(Value::Okay(Box::new(value))),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Try to receive a value from a channel (non-blocking).
///
/// Returns immediately:
/// - `Okay(value)` if a value was available
/// - `Oops("channel empty")` if nothing is waiting
/// - `Oops(msg)` on channel error
pub fn try_recv(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let channel = expect_channel(&args[0])?;

    match channel.try_recv() {
        Ok(Some(value)) => Ok(Value::Okay(Box::new(value))),
        Ok(None) => Ok(Value::Oops("channel empty".to_string())),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Receive with timeout.
///
/// ```text
/// recv_timeout(channel, timeout_ms) -> Okay(value)
/// recv_timeout(channel, timeout_ms) -> Oops("timeout")
/// recv_timeout(channel, timeout_ms) -> Oops(msg)
/// ```
pub fn recv_timeout(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;
    let channel = expect_channel(&args[0])?;

    let timeout_ms = expect_int(&args[1], "timeout_ms")?;
    if timeout_ms < 0 {
        return Err(StdlibError::RuntimeError(
            "timeout cannot be negative".to_string(),
        ));
    }

    match channel.recv_timeout(timeout_ms as u64) {
        Ok(Some(value)) => Ok(Value::Okay(Box::new(value))),
        Ok(None) => Ok(Value::Oops("timeout".to_string())),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Close a channel, preventing further sends.
///
/// Values already buffered can still be received.
///
/// ```text
/// close(channel) -> Bool(true)
/// ```
pub fn close(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let channel = expect_channel(&args[0])?;

    channel.close();
    Ok(Value::Bool(true))
}

/// Check if a channel is closed.
///
/// ```text
/// is_closed(channel) -> Bool
/// ```
pub fn is_closed(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let channel = expect_channel(&args[0])?;

    Ok(Value::Bool(channel.is_closed()))
}

/// Get the number of pending (buffered, unread) items in a channel.
///
/// NOTE: This is an approximation when concurrent senders are active
/// because it must drain and refill the underlying `mpsc` receiver.
/// Prefer using it for diagnostics/logging rather than control flow.
///
/// ```text
/// len(channel) -> Int
/// ```
pub fn len(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;
    let channel = expect_channel(&args[0])?;

    Ok(Value::Int(channel.pending_count() as i64))
}

/// Multi-channel select: wait for the first value available on any of the
/// given channels.
///
/// Accepts an array of channels and a timeout in milliseconds. Polls all
/// channels in round-robin fashion until one produces a value or the
/// timeout expires.
///
/// ```text
/// select([ch1, ch2, ...], timeout_ms) -> Okay([index, value])
/// select([ch1, ch2, ...], timeout_ms) -> Oops("timeout")
/// select([ch1, ch2, ...], timeout_ms) -> Oops("all channels closed")
/// ```
///
/// - `index` is the zero-based position of the channel that fired.
/// - A timeout of `0` does a single non-blocking poll pass.
/// - A negative timeout is rejected.
pub fn select(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    // First argument: array of channels.
    let channels: Vec<&ChannelHandle> = match &args[0] {
        Value::Array(arr) => {
            if arr.is_empty() {
                return Err(StdlibError::RuntimeError(
                    "select requires at least one channel".to_string(),
                ));
            }
            let mut chs = Vec::with_capacity(arr.len());
            for (i, val) in arr.iter().enumerate() {
                match val {
                    Value::Channel(ch) => chs.push(ch),
                    other => {
                        return Err(StdlibError::TypeError {
                            expected: format!("Channel (at index {})", i),
                            got: format!("{:?}", other),
                        });
                    }
                }
            }
            chs
        }
        other => {
            return Err(StdlibError::TypeError {
                expected: "Array of Channels".to_string(),
                got: format!("{:?}", other),
            });
        }
    };

    // Second argument: timeout in milliseconds.
    let timeout_ms = expect_int(&args[1], "timeout_ms")?;
    if timeout_ms < 0 {
        return Err(StdlibError::RuntimeError(
            "select timeout cannot be negative".to_string(),
        ));
    }
    let deadline = if timeout_ms == 0 {
        None // single poll pass
    } else {
        Some(Instant::now() + Duration::from_millis(timeout_ms as u64))
    };

    let poll_sleep = Duration::from_micros(SELECT_POLL_INTERVAL_US);

    loop {
        let mut all_closed = true;

        // Round-robin poll each channel.
        for (idx, ch) in channels.iter().enumerate() {
            let ch: &ChannelHandle = ch;
            if ch.is_closed() {
                continue;
            }
            all_closed = false;

            match ch.try_recv() {
                Ok(Some(value)) => {
                    // Return [index, value] wrapped in Okay.
                    let result = Value::Array(vec![Value::Int(idx as i64), value]);
                    return Ok(Value::Okay(Box::new(result)));
                }
                Ok(None) => {
                    // Nothing available on this channel, try next.
                }
                Err(_) => {
                    // Channel disconnected; treat like closed for this
                    // iteration. It will be caught by is_closed next loop.
                }
            }
        }

        if all_closed {
            return Ok(Value::Oops("all channels closed".to_string()));
        }

        // Check deadline.
        match deadline {
            None => {
                // timeout_ms == 0: single pass only.
                return Ok(Value::Oops("timeout".to_string()));
            }
            Some(dl) if Instant::now() >= dl => {
                return Ok(Value::Oops("timeout".to_string()));
            }
            _ => {
                // Sleep briefly before polling again.
                thread::sleep(poll_sleep);
            }
        }
    }
}

// ===========================================================================
// Tests
// ===========================================================================

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create a permissive capability registry for tests.
    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    /// Helper: extract the inner `ChannelHandle` from a `Value::Channel`.
    fn unwrap_channel(val: &Value) -> &ChannelHandle {
        match val {
            Value::Channel(ch) => ch,
            _ => panic!("Expected Value::Channel, got {:?}", val),
        }
    }

    // -----------------------------------------------------------------------
    // make_chan
    // -----------------------------------------------------------------------

    #[test]
    fn test_make_unbuffered_channel() {
        let mut caps = test_caps();
        let result = make_chan(&[], &mut caps).unwrap();
        assert!(matches!(result, Value::Channel(_)));
        let ch = unwrap_channel(&result);
        assert_eq!(ch.capacity, 0);
    }

    #[test]
    fn test_make_buffered_channel() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(10)], &mut caps).unwrap();
        let ch = unwrap_channel(&result);
        assert_eq!(ch.capacity, 10);
    }

    #[test]
    fn test_make_chan_zero_capacity_is_unbuffered() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(0)], &mut caps).unwrap();
        let ch = unwrap_channel(&result);
        assert_eq!(ch.capacity, 0);
    }

    #[test]
    fn test_negative_capacity_rejected() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(-1)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_excessive_capacity_rejected() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(MAX_BUFFER_SIZE as i64 + 1)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_make_chan_wrong_type_rejected() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::String("ten".to_string())], &mut caps);
        assert!(result.is_err());
    }

    // -----------------------------------------------------------------------
    // send / recv / try_recv
    // -----------------------------------------------------------------------

    #[test]
    fn test_send_and_try_recv() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let ch = unwrap_channel(&channel);

        // Send via the stdlib function.
        let sent = send(&[channel.clone(), Value::Int(42)], &mut caps).unwrap();
        assert_eq!(sent, Value::Bool(true));

        // Receive via try_recv.
        let result = try_recv(&[channel], &mut caps).unwrap();
        match result {
            Value::Okay(boxed) => assert_eq!(*boxed, Value::Int(42)),
            other => panic!("Expected Okay(Int(42)), got {:?}", other),
        }
    }

    #[test]
    fn test_send_multiple_values() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        send(&[channel.clone(), Value::Int(1)], &mut caps).unwrap();
        send(&[channel.clone(), Value::Int(2)], &mut caps).unwrap();
        send(&[channel.clone(), Value::Int(3)], &mut caps).unwrap();

        // Receive in order.
        let r1 = try_recv(&[channel.clone()], &mut caps).unwrap();
        let r2 = try_recv(&[channel.clone()], &mut caps).unwrap();
        let r3 = try_recv(&[channel.clone()], &mut caps).unwrap();

        assert_eq!(r1, Value::Okay(Box::new(Value::Int(1))));
        assert_eq!(r2, Value::Okay(Box::new(Value::Int(2))));
        assert_eq!(r3, Value::Okay(Box::new(Value::Int(3))));
    }

    #[test]
    fn test_send_different_value_types() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        send(
            &[channel.clone(), Value::String("hello".to_string())],
            &mut caps,
        )
        .unwrap();
        send(&[channel.clone(), Value::Bool(true)], &mut caps).unwrap();
        send(&[channel.clone(), Value::Float(3.14)], &mut caps).unwrap();

        let r1 = try_recv(&[channel.clone()], &mut caps).unwrap();
        let r2 = try_recv(&[channel.clone()], &mut caps).unwrap();
        let r3 = try_recv(&[channel.clone()], &mut caps).unwrap();

        assert_eq!(
            r1,
            Value::Okay(Box::new(Value::String("hello".to_string())))
        );
        assert_eq!(r2, Value::Okay(Box::new(Value::Bool(true))));
        assert_eq!(r3, Value::Okay(Box::new(Value::Float(3.14))));
    }

    #[test]
    fn test_try_recv_empty() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let result = try_recv(&[channel], &mut caps).unwrap();
        assert!(matches!(result, Value::Oops(_)));
        if let Value::Oops(msg) = result {
            assert_eq!(msg, "channel empty");
        }
    }

    #[test]
    fn test_send_on_closed_channel() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        close(&[channel.clone()], &mut caps).unwrap();

        let result = send(&[channel, Value::Int(1)], &mut caps).unwrap();
        assert!(matches!(result, Value::Oops(_)));
    }

    #[test]
    fn test_recv_on_closed_channel() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        close(&[channel.clone()], &mut caps).unwrap();

        let result = try_recv(&[channel], &mut caps).unwrap();
        // Closed channel returns Oops (either "channel empty" or similar).
        assert!(matches!(result, Value::Oops(_)));
    }

    // -----------------------------------------------------------------------
    // recv_timeout
    // -----------------------------------------------------------------------

    #[test]
    fn test_recv_timeout_immediate_value() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let ch = unwrap_channel(&channel);
        ch.send(Value::Int(99)).unwrap();

        let result = recv_timeout(&[channel, Value::Int(1000)], &mut caps).unwrap();
        match result {
            Value::Okay(boxed) => assert_eq!(*boxed, Value::Int(99)),
            other => panic!("Expected Okay(99), got {:?}", other),
        }
    }

    #[test]
    fn test_recv_timeout_expires() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        let start = Instant::now();
        let result = recv_timeout(&[channel, Value::Int(50)], &mut caps).unwrap();
        let elapsed = start.elapsed();

        assert!(matches!(result, Value::Oops(_)));
        if let Value::Oops(msg) = result {
            assert_eq!(msg, "timeout");
        }
        // Should have waited roughly 50ms (allow generous margin).
        assert!(elapsed >= Duration::from_millis(30));
    }

    #[test]
    fn test_recv_timeout_negative_rejected() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let result = recv_timeout(&[channel, Value::Int(-10)], &mut caps);
        assert!(result.is_err());
    }

    // -----------------------------------------------------------------------
    // close / is_closed
    // -----------------------------------------------------------------------

    #[test]
    fn test_close_and_is_closed() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        // Not closed initially.
        let result = is_closed(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(result, Value::Bool(false));

        // Close.
        let result = close(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(result, Value::Bool(true));

        // Now closed.
        let result = is_closed(&[channel], &mut caps).unwrap();
        assert_eq!(result, Value::Bool(true));
    }

    #[test]
    fn test_close_idempotent() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        close(&[channel.clone()], &mut caps).unwrap();
        // Closing again should not panic.
        close(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(is_closed(&[channel], &mut caps).unwrap(), Value::Bool(true));
    }

    // -----------------------------------------------------------------------
    // len
    // -----------------------------------------------------------------------

    #[test]
    fn test_len_empty() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let result = len(&[channel], &mut caps).unwrap();
        assert_eq!(result, Value::Int(0));
    }

    #[test]
    fn test_len_after_send() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();

        send(&[channel.clone(), Value::Int(1)], &mut caps).unwrap();
        send(&[channel.clone(), Value::Int(2)], &mut caps).unwrap();

        let result = len(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(result, Value::Int(2));

        // Values should still be receivable after len().
        let r1 = try_recv(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(r1, Value::Okay(Box::new(Value::Int(1))));

        let result = len(&[channel], &mut caps).unwrap();
        assert_eq!(result, Value::Int(1));
    }

    #[test]
    fn test_len_closed_channel() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        close(&[channel.clone()], &mut caps).unwrap();

        let result = len(&[channel], &mut caps).unwrap();
        assert_eq!(result, Value::Int(0));
    }

    // -----------------------------------------------------------------------
    // select
    // -----------------------------------------------------------------------

    #[test]
    fn test_select_single_channel_with_value() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();

        // Pre-load a value.
        send(&[ch1.clone(), Value::Int(42)], &mut caps).unwrap();

        let channels_arr = Value::Array(vec![ch1]);
        let result = select(&[channels_arr, Value::Int(1000)], &mut caps).unwrap();

        match result {
            Value::Okay(boxed) => {
                if let Value::Array(arr) = *boxed {
                    assert_eq!(arr.len(), 2);
                    assert_eq!(arr[0], Value::Int(0)); // index 0
                    assert_eq!(arr[1], Value::Int(42)); // value
                } else {
                    panic!("Expected Array inside Okay");
                }
            }
            other => panic!("Expected Okay, got {:?}", other),
        }
    }

    #[test]
    fn test_select_multiple_channels() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();
        let ch2 = make_chan(&[], &mut caps).unwrap();
        let ch3 = make_chan(&[], &mut caps).unwrap();

        // Put a value on the second channel only.
        send(
            &[ch2.clone(), Value::String("picked".to_string())],
            &mut caps,
        )
        .unwrap();

        let channels_arr = Value::Array(vec![ch1, ch2, ch3]);
        let result = select(&[channels_arr, Value::Int(1000)], &mut caps).unwrap();

        match result {
            Value::Okay(boxed) => {
                if let Value::Array(arr) = *boxed {
                    assert_eq!(arr[0], Value::Int(1)); // index 1 (second channel)
                    assert_eq!(arr[1], Value::String("picked".to_string()));
                } else {
                    panic!("Expected Array inside Okay");
                }
            }
            other => panic!("Expected Okay, got {:?}", other),
        }
    }

    #[test]
    fn test_select_timeout_no_data() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();
        let ch2 = make_chan(&[], &mut caps).unwrap();

        let channels_arr = Value::Array(vec![ch1, ch2]);
        let start = Instant::now();
        let result = select(&[channels_arr, Value::Int(50)], &mut caps).unwrap();
        let elapsed = start.elapsed();

        assert!(matches!(result, Value::Oops(_)));
        if let Value::Oops(msg) = result {
            assert_eq!(msg, "timeout");
        }
        assert!(elapsed >= Duration::from_millis(30));
    }

    #[test]
    fn test_select_zero_timeout_polls_once() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();

        // No value available; timeout_ms = 0 should return immediately.
        let channels_arr = Value::Array(vec![ch1]);
        let start = Instant::now();
        let result = select(&[channels_arr, Value::Int(0)], &mut caps).unwrap();
        let elapsed = start.elapsed();

        assert!(matches!(result, Value::Oops(_)));
        assert!(elapsed < Duration::from_millis(50));
    }

    #[test]
    fn test_select_all_channels_closed() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();
        let ch2 = make_chan(&[], &mut caps).unwrap();

        close(&[ch1.clone()], &mut caps).unwrap();
        close(&[ch2.clone()], &mut caps).unwrap();

        let channels_arr = Value::Array(vec![ch1, ch2]);
        let result = select(&[channels_arr, Value::Int(100)], &mut caps).unwrap();

        match result {
            Value::Oops(msg) => assert_eq!(msg, "all channels closed"),
            other => panic!("Expected Oops('all channels closed'), got {:?}", other),
        }
    }

    #[test]
    fn test_select_empty_array_rejected() {
        let mut caps = test_caps();
        let channels_arr = Value::Array(vec![]);
        let result = select(&[channels_arr, Value::Int(100)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_select_non_array_rejected() {
        let mut caps = test_caps();
        let result = select(&[Value::Int(1), Value::Int(100)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_select_negative_timeout_rejected() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();
        let channels_arr = Value::Array(vec![ch1]);
        let result = select(&[channels_arr, Value::Int(-1)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_select_with_mixed_open_closed() {
        let mut caps = test_caps();
        let ch_closed = make_chan(&[], &mut caps).unwrap();
        let ch_open = make_chan(&[], &mut caps).unwrap();

        close(&[ch_closed.clone()], &mut caps).unwrap();
        send(&[ch_open.clone(), Value::Int(7)], &mut caps).unwrap();

        let channels_arr = Value::Array(vec![ch_closed, ch_open]);
        let result = select(&[channels_arr, Value::Int(100)], &mut caps).unwrap();

        match result {
            Value::Okay(boxed) => {
                if let Value::Array(arr) = *boxed {
                    assert_eq!(arr[0], Value::Int(1)); // index 1 (the open channel)
                    assert_eq!(arr[1], Value::Int(7));
                } else {
                    panic!("Expected Array");
                }
            }
            other => panic!("Expected Okay, got {:?}", other),
        }
    }

    // -----------------------------------------------------------------------
    // Cross-thread tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_send_recv_across_threads() {
        let mut caps = test_caps();
        let channel = make_chan(&[], &mut caps).unwrap();
        let ch = unwrap_channel(&channel).clone();

        let sender_handle = thread::spawn(move || {
            thread::sleep(Duration::from_millis(20));
            ch.send(Value::String("from-thread".to_string())).unwrap();
        });

        // recv should block until the other thread sends.
        let result = recv(&[channel], &mut caps).unwrap();
        match result {
            Value::Okay(boxed) => {
                assert_eq!(*boxed, Value::String("from-thread".to_string()));
            }
            other => panic!("Expected Okay, got {:?}", other),
        }

        sender_handle.join().unwrap();
    }

    #[test]
    fn test_select_with_delayed_sender() {
        let mut caps = test_caps();
        let ch1 = make_chan(&[], &mut caps).unwrap();
        let ch2 = make_chan(&[], &mut caps).unwrap();

        let ch2_handle = unwrap_channel(&ch2).clone();

        let sender = thread::spawn(move || {
            thread::sleep(Duration::from_millis(30));
            ch2_handle.send(Value::Int(99)).unwrap();
        });

        let channels_arr = Value::Array(vec![ch1, ch2]);
        let result = select(&[channels_arr, Value::Int(2000)], &mut caps).unwrap();

        match result {
            Value::Okay(boxed) => {
                if let Value::Array(arr) = *boxed {
                    assert_eq!(arr[0], Value::Int(1)); // ch2 is at index 1
                    assert_eq!(arr[1], Value::Int(99));
                } else {
                    panic!("Expected Array");
                }
            }
            other => panic!("Expected Okay, got {:?}", other),
        }

        sender.join().unwrap();
    }

    // -----------------------------------------------------------------------
    // Arity / type checking
    // -----------------------------------------------------------------------

    #[test]
    fn test_send_wrong_arity() {
        let mut caps = test_caps();
        assert!(send(&[], &mut caps).is_err());
        assert!(send(&[Value::Int(1)], &mut caps).is_err());
    }

    #[test]
    fn test_recv_wrong_arity() {
        let mut caps = test_caps();
        assert!(recv(&[], &mut caps).is_err());
    }

    #[test]
    fn test_send_non_channel_rejected() {
        let mut caps = test_caps();
        let result = send(&[Value::Int(1), Value::Int(2)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_recv_non_channel_rejected() {
        let mut caps = test_caps();
        let result = recv(&[Value::String("nope".to_string())], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_close_non_channel_rejected() {
        let mut caps = test_caps();
        let result = close(&[Value::Bool(false)], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_is_closed_non_channel_rejected() {
        let mut caps = test_caps();
        let result = is_closed(&[Value::Unit], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_len_non_channel_rejected() {
        let mut caps = test_caps();
        let result = len(&[Value::Array(vec![])], &mut caps);
        assert!(result.is_err());
    }

    #[test]
    fn test_select_array_with_non_channel_rejected() {
        let mut caps = test_caps();
        let channels_arr = Value::Array(vec![Value::Int(1)]);
        let result = select(&[channels_arr, Value::Int(100)], &mut caps);
        assert!(result.is_err());
    }
}
