
FROM node:alpine

ENV PATH="/aarch64-linux-musl-cross/bin:/root/.cargo/bin:$PATH" \
  RUSTFLAGS="-C target-feature=-crt-static" \
  CC="clang" \
  CXX="clang++" \
  GN_EXE=gn

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk update && \
  apk add --no-cache \
  bash \
  build-base \
  ca-certificates \
  clang \
  curl \
  git \
  gn \
  gzip \
  llvm \
  musl-dev \
  readline \
  tar \
  unzip \
  wget \
  xz

RUN wget https://github.com/napi-rs/napi-rs/releases/download/linux-musl-cross%4010/aarch64-linux-musl-cross.tgz && \
  tar -xvf aarch64-linux-musl-cross.tgz && \
  rm aarch64-linux-musl-cross.tgz

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install tools via Proto
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto install cmake && \
  proto plugin add ninja "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/ninja/plugin.toml" && \
  proto install ninja && \
  proto install bun && \
  proto install python && \
  proto install rust

# Verify installed tools
RUN echo "----- Verifying installed tools -----" && \
  echo -n "Bun " && bun -v && which bun && \ 
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Ninja " && ninja --version && which ninja && \
  proto --version && which proto && \
  python --version && which python && \
  rustc --version | awk '{print $1, $2}' && which rustc && \
  echo "--------------------"