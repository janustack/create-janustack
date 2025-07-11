FROM messense/manylinux2014-cross:aarch64

ARG NODE_VERSION=24

ENV RUSTUP_HOME=/usr/local/rustup \
  CARGO_HOME=/usr/local/cargo \
  PATH=/usr/local/cargo/bin:$PATH \
  CC=clang \
  CC_aarch64_unknown_linux_gnu=clang \
  CXX=clang++ \
  CXX_aarch64_unknown_linux_gnu=clang++ \
  CFLAGS="--sysroot=/usr/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot" \
  CXXFLAGS="--sysroot=/usr/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot" \
  C_INCLUDE_PATH="/usr/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot/usr/include" \
  LDFLAGS="-L/usr/aarch64-unknown-linux-gnu/lib/llvm-18/lib"

ADD ./lib/llvm-18 /usr/aarch64-unknown-linux-gnu/lib/llvm-18

RUN apt update && \
  apt install -y --fix-missing --no-install-recommends curl gnupg gpg-agent ca-certificates openssl && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm-snapshot.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/llvm-snapshot.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" >> /etc/apt/sources.list && \
  echo "deb-src [signed-by=/etc/apt/keyrings/llvm-snapshot.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" >> /etc/apt/sources.list && \
  apt update && \
  apt install -y --fix-missing --no-install-recommends \
  llvm-18 \
  clang-18 \
  lld-18 \
  libc++-18-dev \
  libc++abi-18-dev \
  xz-utils \
  rcs \
  git \
  make \
  cmake \
  ninja-build && \
  apt autoremove -y && \
  rustup target add aarch64-unknown-linux-gnu && \
  corepack enable && \
  ln -sf /usr/bin/clang-18 /usr/bin/clang && \
  ln -sf /usr/bin/clang++-18 /usr/bin/clang++ && \
  ln -sf /usr/bin/lld-18 /usr/bin/lld && \
  ln -sf /usr/bin/clang-18 /usr/bin/cc

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Node.js from Nodesource
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x -o nodesource_setup.sh && \
  bash nodesource_setup.sh && \
  apt install -y nodejs && \
  rm nodesource_setup.sh

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y