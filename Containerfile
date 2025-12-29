# SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 hyperpolymath

FROM rust:1.85-slim-bookworm AS builder

WORKDIR /build

COPY Cargo.toml Cargo.lock* ./
COPY src/ src/
COPY benches/ benches/

RUN cargo build --release --bin woke

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/woke /usr/local/bin/woke

ENTRYPOINT ["woke"]
CMD ["--help"]
