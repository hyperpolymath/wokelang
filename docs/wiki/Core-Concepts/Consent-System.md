# Consent System

WokeLang's consent system ensures sensitive operations require explicit permission.

---

## Philosophy

The consent system reflects WokeLang's core principle: **respect for user autonomy**. Before accessing sensitive resources or performing potentially impactful operations, programs must request consent.

---

## Basic Syntax

### Consent Blocks

```wokelang
only if okay "permission_name" {
    // Code that requires permission
}
```

**Components:**
- `only if okay` - Keyword phrase initiating consent request
- `"permission_name"` - String identifier for the permission
- `{ }` - Block of code requiring permission

---

## Example Usage

### File Access

```wokelang
to saveUserData(data: String) {
    only if okay "file_write" {
        writeFile("data.txt", data);
        print("Data saved successfully");
    }
}
```

### Camera Access

```wokelang
to takePhoto() → Maybe String {
    only if okay "camera_access" {
        remember photo = captureFromCamera();
        give back photo;
    }
    give back none;
}
```

### Network Access

```wokelang
to fetchData(url: String) {
    only if okay "network_access" {
        remember response = httpGet(url);
        processResponse(response);
    }
}
```

### Data Deletion

```wokelang
@cautious
to deleteAllUserData() {
    only if okay "delete_all_data" {
        clearDatabase();
        clearCache();
        resetSettings();
        print("All data deleted");
    }
}
```

---

## Permission Categories

### Standard Permissions

| Permission | Description | Risk Level |
|------------|-------------|------------|
| `file_read` | Read files from disk | Low |
| `file_write` | Write files to disk | Medium |
| `camera_access` | Access camera | Medium |
| `microphone_access` | Access microphone | Medium |
| `location_access` | Access location data | Medium |
| `network_access` | Make network requests | Medium |
| `clipboard_access` | Read/write clipboard | Low |
| `notification_send` | Send notifications | Low |
| `delete_data` | Delete user data | High |
| `system_settings` | Modify system settings | High |

### Custom Permissions

Define application-specific permissions:

```wokelang
only if okay "send_analytics" {
    reportUsageMetrics();
}

only if okay "share_with_third_party" {
    sendToPartnerAPI(data);
}

only if okay "enable_experimental_features" {
    activateBetaFeatures();
}
```

---

## Consent Behavior

### When Consent Is Requested

1. **Runtime prompt**: User sees a consent dialog
2. **Choice**: User can grant or deny
3. **Execution**: Block runs only if granted
4. **Else clause** (optional): Alternative code runs if denied

### With Fallback

```wokelang
only if okay "camera_access" {
    remember photo = takePhoto();
    displayPhoto(photo);
} otherwise {
    print("Camera access denied - showing placeholder");
    displayPlaceholder();
}
```

---

## Consent Storage

### Persistent Consent (Planned)

```wokelang
// Remember consent for future runs
only if okay "analytics" remember consent {
    sendAnalytics();
}

// Consent valid for this session only
only if okay "camera" session_only {
    takePhoto();
}
```

### Consent Management (Planned)

```wokelang
// Check consent status
remember hasConsent = checkConsent("camera_access");

// Revoke previously granted consent
revokeConsent("location_access");

// List all consents
remember consents = listConsents();
```

---

## Scoped Permissions (Planned)

### Time-Limited Consent

```wokelang
only if okay "location_access" for 1 hour {
    trackLocation();
}
```

### Operation-Limited Consent

```wokelang
only if okay "api_calls" limit 100 {
    makeAPIRequest();
}
```

---

## Nested Consent

```wokelang
to processUserData() {
    only if okay "read_user_data" {
        remember data = loadUserData();

        only if okay "send_to_cloud" {
            uploadToCloud(data);
        }

        only if okay "share_with_partners" {
            sendToPartners(data);
        }
    }
}
```

---

## Combining with Emote Tags

```wokelang
@cautious
@important
to deleteAccount() {
    only if okay "delete_account" {
        // User sees: "This action will permanently delete your account"
        deleteAllData();
        closeAccount();
        print("Account deleted");
    }
}

@experimental
to tryNewFeature() {
    only if okay "experimental_features" {
        // User sees: "This feature is experimental and may be unstable"
        runExperiment();
    }
}
```

---

## Error Handling with Consent

```wokelang
to saveImportantData(data: String) {
    attempt safely {
        only if okay "file_write" {
            writeFile("important.txt", data);
        }
    } or reassure "Could not save data - permission may have been denied";
}
```

---

## Testing with Consent

### Mock Consent in Tests (Planned)

```wokelang
test "file operations with consent" {
    // Auto-grant all consents in test mode
    withAutoConsent {
        remember result = saveUserData("test");
        assert(result == success);
    }
}

test "behavior when consent denied" {
    // Auto-deny specific consent
    withDeniedConsent("file_write") {
        remember result = saveUserData("test");
        assert(result == failure);
    }
}
```

---

## Implementation Details

### Current Implementation

```rust
Statement::Consent { permission, body } => {
    // Currently auto-grants (for development)
    self.print(&format!("[consent requested: {}]", permission));
    self.execute_block(body)
}
```

### Planned Implementation

```rust
Statement::Consent { permission, body, otherwise } => {
    let granted = self.request_consent(permission)?;

    if granted {
        self.execute_block(body)
    } else if let Some(else_block) = otherwise {
        self.execute_block(else_block)
    } else {
        Ok(ControlFlow::Continue)
    }
}
```

---

## Best Practices

### 1. Be Specific

```wokelang
// Good: Specific permission
only if okay "send_email_to_contacts" { ... }

// Bad: Too broad
only if okay "access_data" { ... }
```

### 2. Explain Purpose

```wokelang
// Permission string should be clear
only if okay "use_location_for_weather" {
    remember location = getLocation();
    showLocalWeather(location);
}
```

### 3. Graceful Degradation

```wokelang
to getPhoto() → Maybe Image {
    only if okay "camera" {
        give back capturePhoto();
    }
    // Falls through to return nothing if denied
    give back none;
}
```

### 4. Minimal Scope

```wokelang
// Good: Request only when needed
to shareIfWanted(data: String) {
    only if okay "share" {
        share(data);
    }
}

// Bad: Requesting permission for entire function
only if okay "share" {
    to shareIfWanted(data: String) {
        share(data);
    }
}
```

---

## Next Steps

- [Gratitude System](Gratitude.md)
- [Emote Tags](Emote-Tags.md)
- [Error Handling](../Language-Guide/Error-Handling.md)
