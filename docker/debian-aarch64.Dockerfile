FROM messense/manylinux2014-cross:aarch64

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

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install Node.js via Proto
RUN proto install node

# Install Rust via Proto
RUN proto install Rust

# Show versions and locations for verificiation
RUN cargo --version && which cargo && \
    echo -n "Node.js: " && node -v && which node && \
    proto --version && which proto && \
    rustc --version && which rustc