FROM messense/manylinux2014-cross:x86_64

ARG NASM_VERSION=2.16.03

ENV CC=clang \
  CXX=clang++ \
  CC_x86_64_unknown_linux_gnu=clang \
  CXX_x86_64_unknown_linux_gnu=clang++ \
  RUST_TARGET=x86_64-unknown-linux-gnu \
  CARGO_HOME=/usr/local/cargo \
  CARGO_HOME=/usr/local/cargo \
  PATH=/usr/local/cargo/bin:/root/.proto/bin:/root/.proto/shims:$PATH

RUN apt update && \
  apt install -y --fix-missing --no-install-recommends curl gnupg gpg-agent ca-certificates openssl && \
  mkdir -p /etc/apt/keyrings && \
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

RUN wget https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz && \
  tar -xf nasm-${NASM_VERSION}.tar.xz && \
  cd nasm-${NASM_VERSION} && \
  ./configure --prefix=/usr/ && \
  make && \
  make install && \
  cd / && \
  rm -rf nasm-${NASM_VERSION} && \
  rm nasm-${NASM_VERSION}.tar.xz

ENV LDFLAGS="-fuse-ld=lld --sysroot=/usr/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/sysroot" \
  CFLAGS="--sysroot=/usr/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/sysroot" \
  CXXFLAGS="--sysroot=/usr/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/sysroot" \
  C_INCLUDE_PATH="/usr/x86_64-unknown-linux-gnu/x86_64-unknown-linux-gnu/sysroot/usr/include"

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Install tools via Proto
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto install cmake && \
  proto install node && \
  proto install rust

# Show versions and locations for verificiation
RUN echo "----- Verifying installed tools -----" && \
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Node.js " && node -v && which node && \
  nasm -v && which nasm && \
  proto --version && which proto && \
  rustc --version | awk '{print $1, $2}' && which rustc && \
  echo "--------------------"
