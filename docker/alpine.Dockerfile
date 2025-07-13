ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-alpine

ENV PATH="/aarch64-linux-musl-cross/bin:/usr/local/cargo/bin/rustup:/root/.cargo/bin:$PATH" \
  RUSTFLAGS="-C target-feature=-crt-static" \
  CC="clang" \
  CXX="clang++" \
  GN_EXE=gn

RUN apk add --update --no-cache bash wget musl-dev clang llvm build-base && \
  sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories && \
  apk add --update --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  bash \
  curl \
  git \
  gn \
  rustup \
  tar

RUN wget https://github.com/napi-rs/napi-rs/releases/download/linux-musl-cross%4010/aarch64-linux-musl-cross.tgz && \
  tar -xvf aarch64-linux-musl-cross.tgz && \
  rm aarch64-linux-musl-cross.tgz

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install Bun via Proto
RUN proto install bun

# Install CMake via Proto plugin
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto install cmake

# Install Ninja via Proto plugin
RUN proto plugin add ninja "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/ninja/plugin.toml" && \
  proto install ninja

# Install Python via Proto
RUN proto install python

# Install Rust via Proto
RUN proto install rust

# Show versions and locations for verificiation
RUN echo -n "Bun " && bun -v && which bun && \ 
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Ninja " && ninja --version && which ninja && \
  proto --version && which proto && \
  python --version && which python && \
  rustc --version | awk '{print $1, $2}' && which rustc