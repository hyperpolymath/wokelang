use crate::ast::{LambdaBody, Parameter};
use std::collections::HashMap;
use std::fmt;
use std::rc::Rc;
use std::cell::RefCell;
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, Sender, TryRecvError};
use std::sync::{Arc, Mutex};
use std::time::Duration;

/// Captured environment for closures
#[derive(Debug, Clone)]
pub struct CapturedEnv {
    pub bindings: HashMap<String, Value>,
}

impl CapturedEnv {
    pub fn new() -> Self {
        Self {
            bindings: HashMap::new(),
        }
    }

    pub fn from_map(bindings: HashMap<String, Value>) -> Self {
        Self { bindings }
    }
}

impl Default for CapturedEnv {
    fn default() -> Self {
        Self::new()
    }
}

/// A closure captures its environment at creation time
#[derive(Debug, Clone)]
pub struct Closure {
    pub params: Vec<Parameter>,
    pub body: LambdaBody,
    pub env: Rc<RefCell<CapturedEnv>>,
}

impl PartialEq for Closure {
    fn eq(&self, _other: &Self) -> bool {
        // Closures are never equal (like function identity)
        false
    }
}

/// Channel handle for Go-style channels
/// Channels allow typed, thread-safe communication between concurrent tasks
#[derive(Clone)]
pub struct ChannelHandle {
    /// Sender side
    sender: Sender<Value>,
    /// Receiver side (wrapped in Arc<Mutex> for sharing)
    receiver: Arc<Mutex<Receiver<Value>>>,
    /// Channel name (optional, for debugging)
    pub name: Option<String>,
    /// Whether the channel is closed
    closed: Arc<Mutex<bool>>,
    /// Buffer capacity (0 = unbuffered/sync)
    pub capacity: usize,
}

impl std::fmt::Debug for ChannelHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Channel")
            .field("name", &self.name)
            .field("capacity", &self.capacity)
            .field("closed", &*self.closed.lock().unwrap())
            .finish()
    }
}

impl PartialEq for ChannelHandle {
    fn eq(&self, _other: &Self) -> bool {
        // Channels are never equal (identity comparison would need Arc pointer comparison)
        false
    }
}

impl ChannelHandle {
    /// Create a new unbuffered channel
    pub fn new() -> Self {
        let (sender, receiver) = mpsc::channel();
        Self {
            sender,
            receiver: Arc::new(Mutex::new(receiver)),
            name: None,
            closed: Arc::new(Mutex::new(false)),
            capacity: 0,
        }
    }

    /// Create a new unbuffered channel with a name
    pub fn with_name(name: String) -> Self {
        let mut ch = Self::new();
        ch.name = Some(name);
        ch
    }

    /// Create a buffered channel
    pub fn buffered(capacity: usize) -> Self {
        let (sender, receiver) = mpsc::channel();
        Self {
            sender,
            receiver: Arc::new(Mutex::new(receiver)),
            name: None,
            closed: Arc::new(Mutex::new(false)),
            capacity,
        }
    }

    /// Send a value through the channel
    pub fn send(&self, value: Value) -> Result<(), String> {
        if *self.closed.lock().unwrap() {
            return Err("cannot send on closed channel".to_string());
        }
        self.sender
            .send(value)
            .map_err(|_| "channel send failed: receiver dropped".to_string())
    }

    /// Receive a value from the channel (blocking)
    pub fn recv(&self) -> Result<Value, String> {
        if *self.closed.lock().unwrap() {
            return Err("cannot receive on closed channel".to_string());
        }
        let receiver = self.receiver.lock().unwrap();
        receiver
            .recv()
            .map_err(|_| "channel receive failed: sender dropped".to_string())
    }

    /// Try to receive a value (non-blocking)
    pub fn try_recv(&self) -> Result<Option<Value>, String> {
        if *self.closed.lock().unwrap() {
            return Ok(None);
        }
        let receiver = self.receiver.lock().unwrap();
        match receiver.try_recv() {
            Ok(value) => Ok(Some(value)),
            Err(TryRecvError::Empty) => Ok(None),
            Err(TryRecvError::Disconnected) => Err("channel disconnected".to_string()),
        }
    }

    /// Receive with timeout
    pub fn recv_timeout(&self, timeout_ms: u64) -> Result<Option<Value>, String> {
        if *self.closed.lock().unwrap() {
            return Ok(None);
        }
        let receiver = self.receiver.lock().unwrap();
        match receiver.recv_timeout(Duration::from_millis(timeout_ms)) {
            Ok(value) => Ok(Some(value)),
            Err(RecvTimeoutError::Timeout) => Ok(None),
            Err(RecvTimeoutError::Disconnected) => Err("channel disconnected".to_string()),
        }
    }

    /// Close the channel
    pub fn close(&self) {
        *self.closed.lock().unwrap() = true;
    }

    /// Check if the channel is closed
    pub fn is_closed(&self) -> bool {
        *self.closed.lock().unwrap()
    }
}

impl Default for ChannelHandle {
    fn default() -> Self {
        Self::new()
    }
}

/// Runtime value in WokeLang
#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Int(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Array(Vec<Value>),
    /// Record/object/map with string keys
    Record(HashMap<String, Value>),
    Unit,
    /// Result success: `Okay(value)`
    Okay(Box<Value>),
    /// Result error: `Oops(message)`
    Oops(String),
    /// First-class function/closure
    Function(Closure),
    /// Go-style channel for concurrent communication
    Channel(ChannelHandle),
}

impl Value {
    /// Check if the value is truthy
    pub fn is_truthy(&self) -> bool {
        match self {
            Value::Bool(b) => *b,
            Value::Int(n) => *n != 0,
            Value::Float(f) => *f != 0.0,
            Value::String(s) => !s.is_empty(),
            Value::Array(a) => !a.is_empty(),
            Value::Record(m) => !m.is_empty(),
            Value::Unit => false,
            Value::Okay(_) => true,
            Value::Oops(_) => false,
            Value::Function(_) => true,
            Value::Channel(ch) => !ch.is_closed(),
        }
    }

    /// Check if this is an Okay result
    pub fn is_okay(&self) -> bool {
        matches!(self, Value::Okay(_))
    }

    /// Check if this is an Oops result
    pub fn is_oops(&self) -> bool {
        matches!(self, Value::Oops(_))
    }

    /// Unwrap an Okay value, or return the error
    pub fn unwrap(self) -> Result<Value, String> {
        match self {
            Value::Okay(v) => Ok(*v),
            Value::Oops(e) => Err(e),
            other => Ok(other), // Non-result values pass through
        }
    }
}

impl fmt::Display for Value {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Value::Int(n) => write!(f, "{}", n),
            Value::Float(n) => write!(f, "{}", n),
            Value::String(s) => write!(f, "{}", s),
            Value::Bool(b) => write!(f, "{}", b),
            Value::Array(elements) => {
                write!(f, "[")?;
                for (i, elem) in elements.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", elem)?;
                }
                write!(f, "]")
            }
            Value::Record(fields) => {
                write!(f, "{{")?;
                for (i, (key, val)) in fields.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}: {}", key, val)?;
                }
                write!(f, "}}")
            }
            Value::Unit => write!(f, "()"),
            Value::Okay(v) => write!(f, "Okay({})", v),
            Value::Oops(e) => write!(f, "Oops(\"{}\")", e),
            Value::Function(closure) => {
                let param_names: Vec<_> = closure.params.iter().map(|p| p.name.as_str()).collect();
                write!(f, "|{}| -> <closure>", param_names.join(", "))
            }
            Value::Channel(ch) => {
                let status = if ch.is_closed() { "closed" } else { "open" };
                match &ch.name {
                    Some(name) => write!(f, "<chan:{} {}>", name, status),
                    None => write!(f, "<chan {}>", status),
                }
            }
        }
    }
}
