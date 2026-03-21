# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# WokeLang Containerfile - Security-hardened build

# Build stage
FROM rust:1.85-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy dependency manifests first (layer caching)
COPY Cargo.toml Cargo.lock* ./

# Copy source
COPY src/ src/
COPY benches/ benches/

# Build release binary with security optimizations
RUN cargo build --release --bin woke && \
    strip /build/target/release/woke

# Runtime stage
FROM debian:bookworm-slim

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN groupadd -r wokelang -g 1000 && \
    useradd -r -g wokelang -u 1000 -m -s /sbin/nologin wokelang

# Copy binary from builder
COPY --from=builder /build/target/release/woke /usr/local/bin/woke

# Set ownership
RUN chown root:root /usr/local/bin/woke && \
    chmod 755 /usr/local/bin/woke

# Create workspace directory
RUN mkdir -p /workspace && \
    chown wokelang:wokelang /workspace

# Switch to non-root user
USER wokelang
WORKDIR /workspace

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD woke --version || exit 1

# Use tini as init
ENTRYPOINT ["/usr/bin/tini", "--", "woke"]
CMD ["repl"]
