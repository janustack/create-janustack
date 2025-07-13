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

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install Bun via Proto
RUN proto install bun

# Install Rust via Proto
RUN proto install rust

# Show versions and locations for verificiation
RUN echo -n "Bun: " && bun -v && which bun && \ 
    cargo --version && which cargo && \
    proto --version && which proto && \
    rustc --version && which rustc