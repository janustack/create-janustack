ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-alpine

ENV PATH="/aarch64-linux-musl-cross/bin:/usr/local/cargo/bin/rustup:/root/.cargo/bin:$PATH" \
  RUSTFLAGS="-C target-feature=-crt-static" \
  CC="clang" \
  CXX="clang++" \
  GN_EXE=gn

RUN apk add --update --no-cache bash wget cmake musl-dev clang llvm build-base python3 && \
  sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories && \
  apk add --update --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  rustup \
  git \
  gn \
  tar \
  ninja

RUN rustup-init -y && \
  rustup target add aarch64-unknown-linux-musl && \
  wget https://github.com/napi-rs/napi-rs/releases/download/linux-musl-cross%4010/aarch64-linux-musl-cross.tgz && \
  tar -xvf aarch64-linux-musl-cross.tgz && \
  rm aarch64-linux-musl-cross.tgz

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y