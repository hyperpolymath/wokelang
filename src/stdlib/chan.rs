//! WokeLang Standard Library - Channel Module
//!
//! Go-style channels for concurrent communication.
//! Channels are typed, thread-safe communication primitives.

use crate::interpreter::{ChannelHandle, Value};
use crate::security::CapabilityRegistry;
use super::{check_arity, check_arity_range, expect_int, StdlibError};

/// Maximum channel buffer size
const MAX_BUFFER_SIZE: usize = 10000;

/// Create a new channel
/// make_chan() -> Channel (unbuffered)
/// make_chan(capacity) -> Channel (buffered)
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

/// Send a value on a channel
/// send(channel, value) -> Bool
pub fn send(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    match channel.send(args[1].clone()) {
        Ok(()) => Ok(Value::Bool(true)),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Receive a value from a channel (blocking)
/// recv(channel) -> Result
pub fn recv(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    match channel.recv() {
        Ok(value) => Ok(Value::Okay(Box::new(value))),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Try to receive a value from a channel (non-blocking)
/// try_recv(channel) -> Result (Okay(value) or Oops("empty"))
pub fn try_recv(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    match channel.try_recv() {
        Ok(Some(value)) => Ok(Value::Okay(Box::new(value))),
        Ok(None) => Ok(Value::Oops("channel empty".to_string())),
        Err(e) => Ok(Value::Oops(e)),
    }
}

/// Receive with timeout
/// recv_timeout(channel, timeout_ms) -> Result
pub fn recv_timeout(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 2)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

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

/// Close a channel
/// close(channel) -> Bool
pub fn close(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    channel.close();
    Ok(Value::Bool(true))
}

/// Check if a channel is closed
/// is_closed(channel) -> Bool
pub fn is_closed(args: &[Value], _caps: &mut CapabilityRegistry) -> Result<Value, StdlibError> {
    check_arity(args, 1)?;

    let channel = match &args[0] {
        Value::Channel(ch) => ch,
        other => {
            return Err(StdlibError::TypeError {
                expected: "Channel".to_string(),
                got: format!("{:?}", other),
            })
        }
    };

    Ok(Value::Bool(channel.is_closed()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_caps() -> CapabilityRegistry {
        CapabilityRegistry::permissive()
    }

    #[test]
    fn test_make_unbuffered_channel() {
        let mut caps = test_caps();
        let result = make_chan(&[], &mut caps).unwrap();
        assert!(matches!(result, Value::Channel(_)));
    }

    #[test]
    fn test_make_buffered_channel() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(10)], &mut caps).unwrap();
        if let Value::Channel(ch) = result {
            assert_eq!(ch.capacity, 10);
        } else {
            panic!("Expected channel");
        }
    }

    #[test]
    fn test_send_try_recv() {
        let mut caps = test_caps();

        // Create channel
        let channel = make_chan(&[], &mut caps).unwrap();

        // Get the channel handle for sending
        let channel_handle = if let Value::Channel(ch) = &channel {
            ch.clone()
        } else {
            panic!("Expected channel");
        };

        // Send a value directly using the handle
        channel_handle.send(Value::Int(42)).unwrap();

        // Now try_recv should work
        let result = try_recv(&[channel], &mut caps).unwrap();

        if let Value::Okay(boxed) = result {
            assert_eq!(*boxed, Value::Int(42));
        } else {
            panic!("Expected Okay result, got {:?}", result);
        }
    }

    #[test]
    fn test_try_recv_empty() {
        let mut caps = test_caps();

        let channel = make_chan(&[], &mut caps).unwrap();
        let result = try_recv(&[channel], &mut caps).unwrap();

        // Should be Oops("channel empty")
        assert!(matches!(result, Value::Oops(_)));
    }

    #[test]
    fn test_close_channel() {
        let mut caps = test_caps();

        let channel = make_chan(&[], &mut caps).unwrap();

        // Close
        let result = close(&[channel.clone()], &mut caps).unwrap();
        assert_eq!(result, Value::Bool(true));

        // Check closed
        let result = is_closed(&[channel], &mut caps).unwrap();
        assert_eq!(result, Value::Bool(true));
    }

    #[test]
    fn test_negative_capacity_rejected() {
        let mut caps = test_caps();
        let result = make_chan(&[Value::Int(-1)], &mut caps);
        assert!(result.is_err());
    }
}
