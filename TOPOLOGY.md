<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Wokelang — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              USER / INPUT               │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           CORE LOGIC                    │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ Component │  │    Component      │  │
                        │  │     A     │  │       B           │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │          DATA / STORAGE                 │
                        └─────────────────────────────────────────┘
```
## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE LOGIC
  Main Application                  ████████░░  80%    Core functionality implemented
  Configuration                     ██████████ 100%    Config parsing stable
  CLI Interface                     ██████░░░░  60%    Basic commands available

INFRASTRUCTURE
  CI/CD                             ██████████ 100%    GitHub Actions / GitLab CI
  Documentation                     ████░░░░░░  40%    Initial README and guides
  Tests                             ██████░░░░  60%    Unit tests coverage increasing

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ███████░░░  ~70%   Functional prototype / MVP
```

## Key Dependencies

```
   User ──────► CLI / Interface ──────► Core Logic
                                            │
                                            ▼
                                     Data / State
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
