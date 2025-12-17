use std::fmt;

/// Runtime value in WokeLang
#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Int(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Array(Vec<Value>),
    Unit,
    /// Okay(value) - successful result
    Okay(Box<Value>),
    /// Oops(error_message) - error result
    Oops(std::string::String),
}

impl Value {
    /// Check if this is an Okay value
    pub fn is_okay(&self) -> bool {
        matches!(self, Value::Okay(_))
    }

    /// Check if this is an Oops value
    pub fn is_oops(&self) -> bool {
        matches!(self, Value::Oops(_))
    }

    /// Unwrap an Okay value, panics if Oops
    pub fn unwrap(self) -> Value {
        match self {
            Value::Okay(v) => *v,
            Value::Oops(e) => panic!("Called unwrap on Oops: {}", e),
            other => other, // Non-Result values pass through
        }
    }

    /// Get the inner value if Okay, or None if Oops
    pub fn okay(self) -> Option<Value> {
        match self {
            Value::Okay(v) => Some(*v),
            _ => None,
        }
    }

    /// Get the error message if Oops, or None if Okay
    pub fn oops(&self) -> Option<&str> {
        match self {
            Value::Oops(e) => Some(e),
            _ => None,
        }
    }
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
            Value::Unit => false,
            Value::Okay(_) => true,
            Value::Oops(_) => false,
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
            Value::Unit => write!(f, "()"),
            Value::Okay(v) => write!(f, "Okay({})", v),
            Value::Oops(e) => write!(f, "Oops(\"{}\")", e),
        }
    }
}
