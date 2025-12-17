//! Persistent Consent Storage for WokeLang
//!
//! This module provides persistent storage for consent decisions,
//! allowing users to remember their choices across sessions.

use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::time::SystemTime;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConsentError {
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Parse error: {0}")]
    ParseError(String),

    #[error("Consent file corrupted")]
    CorruptedFile,
}

type Result<T> = std::result::Result<T, ConsentError>;

/// A stored consent decision
#[derive(Debug, Clone)]
pub struct StoredConsent {
    pub scope: String,
    pub capability: String,
    pub granted: bool,
    pub timestamp: u64,
    pub remember: ConsentDuration,
}

/// How long to remember a consent decision
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ConsentDuration {
    /// Remember for this session only
    Session,
    /// Remember for a day
    Day,
    /// Remember for a week
    Week,
    /// Remember forever
    Forever,
    /// Don't remember (ask every time)
    Once,
}

impl ConsentDuration {
    pub fn to_seconds(&self) -> Option<u64> {
        match self {
            ConsentDuration::Session => None,
            ConsentDuration::Day => Some(86400),
            ConsentDuration::Week => Some(604800),
            ConsentDuration::Forever => Some(u64::MAX),
            ConsentDuration::Once => Some(0),
        }
    }
}

/// Persistent consent storage
pub struct ConsentStore {
    /// Path to the consent file
    path: PathBuf,
    /// Cached consents
    consents: HashMap<String, StoredConsent>,
    /// Whether to auto-save on changes
    auto_save: bool,
}

impl ConsentStore {
    /// Create a new consent store at the given path
    pub fn new(path: PathBuf) -> Self {
        Self {
            path,
            consents: HashMap::new(),
            auto_save: true,
        }
    }

    /// Create a consent store in the user's config directory
    pub fn default_path() -> PathBuf {
        // Use ~/.config/wokelang/consent.db on Unix
        // or %APPDATA%/wokelang/consent.db on Windows
        if let Some(config_dir) = dirs::config_dir() {
            config_dir.join("wokelang").join("consent.db")
        } else {
            PathBuf::from(".wokelang-consent.db")
        }
    }

    /// Load consents from file
    pub fn load(&mut self) -> Result<()> {
        if !self.path.exists() {
            return Ok(());
        }

        let content = fs::read_to_string(&self.path)?;

        for line in content.lines() {
            if line.trim().is_empty() || line.starts_with('#') {
                continue;
            }

            if let Some(consent) = self.parse_line(line) {
                let key = format!("{}:{}", consent.scope, consent.capability);
                self.consents.insert(key, consent);
            }
        }

        Ok(())
    }

    /// Save consents to file
    pub fn save(&self) -> Result<()> {
        // Ensure directory exists
        if let Some(parent) = self.path.parent() {
            fs::create_dir_all(parent)?;
        }

        let mut content = String::new();
        content.push_str("# WokeLang Consent Storage\n");
        content.push_str("# Format: scope|capability|granted|timestamp|duration\n\n");

        for consent in self.consents.values() {
            let line = format!(
                "{}|{}|{}|{}|{}\n",
                consent.scope,
                consent.capability,
                if consent.granted { "yes" } else { "no" },
                consent.timestamp,
                match consent.remember {
                    ConsentDuration::Session => "session",
                    ConsentDuration::Day => "day",
                    ConsentDuration::Week => "week",
                    ConsentDuration::Forever => "forever",
                    ConsentDuration::Once => "once",
                }
            );
            content.push_str(&line);
        }

        fs::write(&self.path, content)?;
        Ok(())
    }

    /// Parse a consent line from the file
    fn parse_line(&self, line: &str) -> Option<StoredConsent> {
        let parts: Vec<&str> = line.split('|').collect();
        if parts.len() != 5 {
            return None;
        }

        let scope = parts[0].to_string();
        let capability = parts[1].to_string();
        let granted = parts[2] == "yes";
        let timestamp: u64 = parts[3].parse().ok()?;
        let remember = match parts[4] {
            "session" => ConsentDuration::Session,
            "day" => ConsentDuration::Day,
            "week" => ConsentDuration::Week,
            "forever" => ConsentDuration::Forever,
            "once" => ConsentDuration::Once,
            _ => return None,
        };

        Some(StoredConsent {
            scope,
            capability,
            granted,
            timestamp,
            remember,
        })
    }

    /// Store a consent decision
    pub fn store(&mut self, scope: &str, capability: &str, granted: bool, duration: ConsentDuration) -> Result<()> {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        let consent = StoredConsent {
            scope: scope.to_string(),
            capability: capability.to_string(),
            granted,
            timestamp: now,
            remember: duration,
        };

        let key = format!("{}:{}", scope, capability);
        self.consents.insert(key, consent);

        if self.auto_save {
            self.save()?;
        }

        Ok(())
    }

    /// Check if consent was previously granted
    pub fn check(&self, scope: &str, capability: &str) -> Option<bool> {
        let key = format!("{}:{}", scope, capability);
        let consent = self.consents.get(&key)?;

        // Check if consent has expired
        if consent.remember == ConsentDuration::Once {
            return None;
        }

        if let Some(duration_secs) = consent.remember.to_seconds() {
            let now = SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0);

            if now - consent.timestamp > duration_secs {
                return None;
            }
        }

        Some(consent.granted)
    }

    /// Revoke a stored consent
    pub fn revoke(&mut self, scope: &str, capability: &str) -> Result<()> {
        let key = format!("{}:{}", scope, capability);
        self.consents.remove(&key);

        if self.auto_save {
            self.save()?;
        }

        Ok(())
    }

    /// Revoke all consents for a scope
    pub fn revoke_all(&mut self, scope: &str) -> Result<()> {
        let keys: Vec<String> = self
            .consents
            .keys()
            .filter(|k| k.starts_with(&format!("{}:", scope)))
            .cloned()
            .collect();

        for key in keys {
            self.consents.remove(&key);
        }

        if self.auto_save {
            self.save()?;
        }

        Ok(())
    }

    /// Clear all stored consents
    pub fn clear(&mut self) -> Result<()> {
        self.consents.clear();

        if self.auto_save {
            self.save()?;
        }

        Ok(())
    }

    /// List all stored consents
    pub fn list(&self) -> Vec<&StoredConsent> {
        self.consents.values().collect()
    }

    /// Set auto-save behavior
    pub fn set_auto_save(&mut self, auto_save: bool) {
        self.auto_save = auto_save;
    }
}

impl Default for ConsentStore {
    fn default() -> Self {
        Self::new(Self::default_path())
    }
}

// Optional: Use 'dirs' crate for cross-platform config directories
// If not available, provide a fallback
mod dirs {
    use std::path::PathBuf;

    pub fn config_dir() -> Option<PathBuf> {
        #[cfg(target_os = "linux")]
        {
            std::env::var("XDG_CONFIG_HOME")
                .map(PathBuf::from)
                .ok()
                .or_else(|| std::env::var("HOME").map(|h| PathBuf::from(h).join(".config")).ok())
        }

        #[cfg(target_os = "macos")]
        {
            std::env::var("HOME")
                .map(|h| PathBuf::from(h).join("Library/Application Support"))
                .ok()
        }

        #[cfg(target_os = "windows")]
        {
            std::env::var("APPDATA").map(PathBuf::from).ok()
        }

        #[cfg(not(any(target_os = "linux", target_os = "macos", target_os = "windows")))]
        {
            None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    fn temp_path(name: &str) -> PathBuf {
        env::temp_dir().join(format!("wokelang_test_{}.db", name))
    }

    #[test]
    fn test_store_and_check() {
        let path = temp_path("store_check");
        let mut store = ConsentStore::new(path);
        store.set_auto_save(false);

        store.store("main", "file:read", true, ConsentDuration::Forever).unwrap();

        assert_eq!(store.check("main", "file:read"), Some(true));
        assert_eq!(store.check("main", "file:write"), None);
    }

    #[test]
    fn test_revoke() {
        let path = temp_path("revoke");
        let mut store = ConsentStore::new(path);
        store.set_auto_save(false);

        store.store("main", "network", true, ConsentDuration::Forever).unwrap();
        assert_eq!(store.check("main", "network"), Some(true));

        store.revoke("main", "network").unwrap();
        assert_eq!(store.check("main", "network"), None);
    }

    #[test]
    fn test_save_and_load() {
        let path = temp_path("save_load");
        // Clean up any previous test file
        let _ = fs::remove_file(&path);

        // Store some consents
        {
            let mut store = ConsentStore::new(path.clone());
            store.store("main", "file:read", true, ConsentDuration::Forever).unwrap();
            store.store("main", "network", false, ConsentDuration::Day).unwrap();
        }

        // Load in a new store
        {
            let mut store = ConsentStore::new(path.clone());
            store.load().unwrap();

            assert_eq!(store.check("main", "file:read"), Some(true));
            assert_eq!(store.check("main", "network"), Some(false));
        }

        // Clean up
        let _ = fs::remove_file(&path);
    }

    #[test]
    fn test_once_duration() {
        let path = temp_path("once");
        let mut store = ConsentStore::new(path);
        store.set_auto_save(false);

        store.store("main", "temp", true, ConsentDuration::Once).unwrap();

        // Once consents should never be returned from check
        assert_eq!(store.check("main", "temp"), None);
    }
}
