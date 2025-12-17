//! Capability-based Security System for WokeLang
//!
//! This module implements "superpowers" - a capability-based security model
//! that requires explicit consent for sensitive operations.

pub mod consent;

pub use consent::{ConsentDuration, ConsentStore, StoredConsent};

use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::time::{Duration, SystemTime};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SecurityError {
    #[error("Permission denied: {0}")]
    PermissionDenied(String),

    #[error("Capability not granted: {0}")]
    CapabilityNotGranted(String),

    #[error("Capability expired: {0}")]
    CapabilityExpired(String),

    #[error("Capability revoked: {0}")]
    CapabilityRevoked(String),

    #[error("Invalid capability: {0}")]
    InvalidCapability(String),
}

type Result<T> = std::result::Result<T, SecurityError>;

/// Types of capabilities (superpowers) in WokeLang
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Capability {
    /// Read files from the filesystem
    FileRead(Option<PathBuf>),
    /// Write files to the filesystem
    FileWrite(Option<PathBuf>),
    /// Execute system commands
    Execute(Option<String>),
    /// Network access (HTTP, sockets, etc.)
    Network(Option<String>),
    /// Environment variable access
    Environment(Option<String>),
    /// Create child processes
    Process,
    /// Access system information
    SystemInfo,
    /// Use cryptographic functions
    Crypto,
    /// Access clipboard
    Clipboard,
    /// Use notifications
    Notify,
    /// Custom capability with name
    Custom(String),
}

impl std::fmt::Display for Capability {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Capability::FileRead(path) => {
                if let Some(p) = path {
                    write!(f, "file:read:{}", p.display())
                } else {
                    write!(f, "file:read:*")
                }
            }
            Capability::FileWrite(path) => {
                if let Some(p) = path {
                    write!(f, "file:write:{}", p.display())
                } else {
                    write!(f, "file:write:*")
                }
            }
            Capability::Execute(cmd) => {
                if let Some(c) = cmd {
                    write!(f, "execute:{}", c)
                } else {
                    write!(f, "execute:*")
                }
            }
            Capability::Network(host) => {
                if let Some(h) = host {
                    write!(f, "network:{}", h)
                } else {
                    write!(f, "network:*")
                }
            }
            Capability::Environment(var) => {
                if let Some(v) = var {
                    write!(f, "env:{}", v)
                } else {
                    write!(f, "env:*")
                }
            }
            Capability::Process => write!(f, "process"),
            Capability::SystemInfo => write!(f, "system_info"),
            Capability::Crypto => write!(f, "crypto"),
            Capability::Clipboard => write!(f, "clipboard"),
            Capability::Notify => write!(f, "notify"),
            Capability::Custom(name) => write!(f, "custom:{}", name),
        }
    }
}

/// A granted capability with metadata
#[derive(Debug, Clone)]
pub struct GrantedCapability {
    pub capability: Capability,
    pub granted_at: SystemTime,
    pub expires_at: Option<SystemTime>,
    pub granted_by: String,
    pub reason: Option<String>,
    pub revoked: bool,
}

impl GrantedCapability {
    pub fn new(capability: Capability, granted_by: String) -> Self {
        Self {
            capability,
            granted_at: SystemTime::now(),
            expires_at: None,
            granted_by,
            reason: None,
            revoked: false,
        }
    }

    pub fn with_expiry(mut self, duration: Duration) -> Self {
        self.expires_at = Some(SystemTime::now() + duration);
        self
    }

    pub fn with_reason(mut self, reason: String) -> Self {
        self.reason = Some(reason);
        self
    }

    pub fn is_valid(&self) -> bool {
        if self.revoked {
            return false;
        }
        if let Some(expires) = self.expires_at {
            if SystemTime::now() > expires {
                return false;
            }
        }
        true
    }
}

/// Audit log entry
#[derive(Debug, Clone)]
pub struct AuditEntry {
    pub timestamp: SystemTime,
    pub capability: Capability,
    pub action: AuditAction,
    pub context: String,
    pub success: bool,
}

#[derive(Debug, Clone)]
pub enum AuditAction {
    Requested,
    Granted,
    Denied,
    Used,
    Revoked,
    Expired,
}

/// The capability registry that manages all superpowers
pub struct CapabilityRegistry {
    /// Granted capabilities
    capabilities: HashMap<String, Vec<GrantedCapability>>,
    /// Pending consent requests
    pending_requests: HashSet<Capability>,
    /// Audit log
    audit_log: Vec<AuditEntry>,
    /// Whether to allow interactive consent prompts
    interactive: bool,
    /// Default consent decision (for non-interactive mode)
    default_consent: bool,
}

impl CapabilityRegistry {
    pub fn new() -> Self {
        Self {
            capabilities: HashMap::new(),
            pending_requests: HashSet::new(),
            audit_log: Vec::new(),
            interactive: true,
            default_consent: false,
        }
    }

    /// Create a registry that auto-grants all capabilities (for testing)
    pub fn permissive() -> Self {
        Self {
            capabilities: HashMap::new(),
            pending_requests: HashSet::new(),
            audit_log: Vec::new(),
            interactive: false,
            default_consent: true,
        }
    }

    /// Grant a capability to a scope (e.g., function name)
    pub fn grant(&mut self, scope: &str, capability: Capability, granted_by: &str) {
        let entry = GrantedCapability::new(capability.clone(), granted_by.to_string());

        self.capabilities
            .entry(scope.to_string())
            .or_insert_with(Vec::new)
            .push(entry);

        self.audit(capability, AuditAction::Granted, scope, true);
    }

    /// Grant a capability with expiration
    pub fn grant_temporary(&mut self, scope: &str, capability: Capability, duration: Duration, granted_by: &str) {
        let entry = GrantedCapability::new(capability.clone(), granted_by.to_string())
            .with_expiry(duration);

        self.capabilities
            .entry(scope.to_string())
            .or_insert_with(Vec::new)
            .push(entry);

        self.audit(capability, AuditAction::Granted, scope, true);
    }

    /// Revoke a capability from a scope
    pub fn revoke(&mut self, scope: &str, capability: &Capability) {
        if let Some(caps) = self.capabilities.get_mut(scope) {
            for cap in caps.iter_mut() {
                if &cap.capability == capability {
                    cap.revoked = true;
                }
            }
        }
        self.audit(capability.clone(), AuditAction::Revoked, scope, true);
    }

    /// Check if a capability is granted for a scope
    pub fn has_capability(&self, scope: &str, capability: &Capability) -> bool {
        // Check exact scope
        if let Some(caps) = self.capabilities.get(scope) {
            for cap in caps {
                if &cap.capability == capability && cap.is_valid() {
                    return true;
                }
                // Check wildcard capabilities
                if self.capability_matches(&cap.capability, capability) && cap.is_valid() {
                    return true;
                }
            }
        }

        // Check global scope
        if let Some(caps) = self.capabilities.get("*") {
            for cap in caps {
                if self.capability_matches(&cap.capability, capability) && cap.is_valid() {
                    return true;
                }
            }
        }

        false
    }

    /// Check if a wildcard capability matches a specific one
    fn capability_matches(&self, granted: &Capability, requested: &Capability) -> bool {
        match (granted, requested) {
            (Capability::FileRead(None), Capability::FileRead(_)) => true,
            (Capability::FileWrite(None), Capability::FileWrite(_)) => true,
            (Capability::Execute(None), Capability::Execute(_)) => true,
            (Capability::Network(None), Capability::Network(_)) => true,
            (Capability::Environment(None), Capability::Environment(_)) => true,
            _ => granted == requested,
        }
    }

    /// Request a capability (prompts user if interactive)
    pub fn request(&mut self, scope: &str, capability: &Capability) -> Result<()> {
        // Check if already granted
        if self.has_capability(scope, capability) {
            self.audit(capability.clone(), AuditAction::Used, scope, true);
            return Ok(());
        }

        self.audit(capability.clone(), AuditAction::Requested, scope, true);

        // If non-interactive, use default consent
        if !self.interactive {
            if self.default_consent {
                self.grant(scope, capability.clone(), "auto");
                return Ok(());
            } else {
                self.audit(capability.clone(), AuditAction::Denied, scope, false);
                return Err(SecurityError::CapabilityNotGranted(capability.to_string()));
            }
        }

        // Interactive consent prompt
        println!("🔐 Capability request: {}", capability);
        println!("   Scope: {}", scope);
        print!("   Grant this capability? (y/n): ");

        use std::io::{self, Write};
        io::stdout().flush().ok();

        let mut input = String::new();
        if io::stdin().read_line(&mut input).is_ok() {
            let input = input.trim().to_lowercase();
            if input == "y" || input == "yes" {
                self.grant(scope, capability.clone(), "user");
                return Ok(());
            }
        }

        self.audit(capability.clone(), AuditAction::Denied, scope, false);
        Err(SecurityError::CapabilityNotGranted(capability.to_string()))
    }

    /// Add an audit log entry
    fn audit(&mut self, capability: Capability, action: AuditAction, context: &str, success: bool) {
        self.audit_log.push(AuditEntry {
            timestamp: SystemTime::now(),
            capability,
            action,
            context: context.to_string(),
            success,
        });
    }

    /// Get the audit log
    pub fn get_audit_log(&self) -> &[AuditEntry] {
        &self.audit_log
    }

    /// Clear expired capabilities
    pub fn cleanup_expired(&mut self) {
        for (scope, caps) in self.capabilities.iter_mut() {
            caps.retain(|cap| {
                if !cap.is_valid() {
                    // Log expiration if it was due to time
                    if let Some(expires) = cap.expires_at {
                        if SystemTime::now() > expires && !cap.revoked {
                            // Can't borrow self here, so we just mark it
                        }
                    }
                    false
                } else {
                    true
                }
            });
        }
    }

    /// List all granted capabilities for a scope
    pub fn list_capabilities(&self, scope: &str) -> Vec<&GrantedCapability> {
        self.capabilities
            .get(scope)
            .map(|caps| caps.iter().filter(|c| c.is_valid()).collect())
            .unwrap_or_default()
    }

    /// Set interactive mode
    pub fn set_interactive(&mut self, interactive: bool) {
        self.interactive = interactive;
    }

    /// Set default consent for non-interactive mode
    pub fn set_default_consent(&mut self, consent: bool) {
        self.default_consent = consent;
    }
}

impl Default for CapabilityRegistry {
    fn default() -> Self {
        Self::new()
    }
}

/// A superpower declaration that can be stored in WokeLang code
#[derive(Debug, Clone)]
pub struct SuperpowerDeclaration {
    pub name: String,
    pub capabilities: Vec<Capability>,
    pub description: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_capability_grant() {
        let mut registry = CapabilityRegistry::permissive();
        let cap = Capability::FileRead(Some(PathBuf::from("/tmp")));

        registry.grant("main", cap.clone(), "test");
        assert!(registry.has_capability("main", &cap));
    }

    #[test]
    fn test_capability_revoke() {
        let mut registry = CapabilityRegistry::permissive();
        let cap = Capability::Network(None);

        registry.grant("main", cap.clone(), "test");
        assert!(registry.has_capability("main", &cap));

        registry.revoke("main", &cap);
        assert!(!registry.has_capability("main", &cap));
    }

    #[test]
    fn test_wildcard_capability() {
        let mut registry = CapabilityRegistry::permissive();
        let wildcard = Capability::FileRead(None);
        let specific = Capability::FileRead(Some(PathBuf::from("/etc/passwd")));

        registry.grant("main", wildcard, "test");
        assert!(registry.has_capability("main", &specific));
    }

    #[test]
    fn test_capability_expiry() {
        let mut registry = CapabilityRegistry::permissive();
        let cap = Capability::Crypto;

        registry.grant_temporary("main", cap.clone(), Duration::from_secs(0), "test");

        // Should expire immediately
        std::thread::sleep(Duration::from_millis(10));
        assert!(!registry.has_capability("main", &cap));
    }

    #[test]
    fn test_global_scope() {
        let mut registry = CapabilityRegistry::permissive();
        let cap = Capability::SystemInfo;

        registry.grant("*", cap.clone(), "test");
        assert!(registry.has_capability("main", &cap));
        assert!(registry.has_capability("other_function", &cap));
    }

    #[test]
    fn test_audit_log() {
        let mut registry = CapabilityRegistry::permissive();
        let cap = Capability::Notify;

        registry.grant("main", cap.clone(), "test");

        let log = registry.get_audit_log();
        assert!(!log.is_empty());
        assert!(matches!(log.last().unwrap().action, AuditAction::Granted));
    }
}
