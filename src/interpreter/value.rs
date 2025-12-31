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
    /// Result success: `Okay(value)`
    Okay(Box<Value>),
    /// Result error: `Oops(message)`
    Oops(String),
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
            Value::Unit => write!(f, "()"),
            Value::Okay(v) => write!(f, "Okay({})", v),
            Value::Oops(e) => write!(f, "Oops(\"{}\")", e),
        }
    }
}
