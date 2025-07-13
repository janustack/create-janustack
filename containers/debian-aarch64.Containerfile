FROM messense/manylinux2014-cross:aarch64

ENV CC=clang \
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
  bash \
  clang-18 \
  curl \
  git \
  gzip \
  libc++-18-dev \
  libc++abi-18-dev \
  lld-18 \
  llvm-18 \
  make \
  ninja-build \
  rcs \
  tar \
  unzip \
  xz-utils && \
  apt autoremove -y && \
  ln -sf /usr/bin/clang-18 /usr/bin/clang && \
  ln -sf /usr/bin/clang++-18 /usr/bin/clang++ && \
  ln -sf /usr/bin/lld-18 /usr/bin/lld && \
  ln -sf /usr/bin/clang-18 /usr/bin/cc

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | sh -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install tools via Proto
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto install cmake && \
  proto install node && \
  proto install rust

# Verify installed tools
RUN echo "----- Verifying installed tools -----" && \
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Node.js " && node -v && which node && \
  proto --version && which proto && \
  rustc --version | awk '{print $1, $2}' && which rustc && \
  echo "--------------------"