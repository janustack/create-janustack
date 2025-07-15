
FROM alpine:latest

ENV PATH="$CARGO_HOME/bin:/root/.proto/bin:/root/.proto/shims:$PATH" \
  RUSTFLAGS="-C target-feature=-crt-static" \
  TARGET=aarch64-unknown-linux-musl \
  CC="zig cc" \
  CXX="zig c++" \
  GN_EXE=gn

RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk update && \
  apk add --no-cache \
  bash \
  build-base \
  ca-certificates \
  curl \
  git \
  gn \
  gzip \
  musl-dev \
  nasm \
  readline \
  tar \
  unzip \
  wget \
  xz-dev \
  xz

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install tools via Proto
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto plugin add ninja "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/ninja/plugin.toml" && \
  proto plugin add zig "github://konomae/zig-plugin" && \
  proto install cmake && \
  proto install ninja && \
  proto install bun && \
  proto install python && \
  proto install rust && \
  proto install zig

# Verify installed tools
RUN echo "----- Verifying installed tools -----" && \
  echo -n "Bun " && bun -v && which bun && \
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Ninja " && ninja --version && which ninja && \
  proto --version && which proto && \
  python --version && which python && \
  rustc --version | awk '{print $1, $2}' && which rustc && \
  echo -n "Zig " && zig version && which zig && \
  echo "--------------------"