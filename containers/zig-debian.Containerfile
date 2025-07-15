FROM messense/manylinux2014-cross:x86_64

ARG NASM_VERSION=2.16.03

ENV CARGO_HOME=/usr/local/cargo \
  CC="zig cc" \
  CC_x86_64_unknown_linux_gnu=clang \
  CXX="zig c++" \
  CXX_x86_64_unknown_linux_gnu=clang++ \
  PATH=/usr/local/cargo/bin:/root/.proto/bin:/root/.proto/shims:$PATH \
  RUST_TARGET=x86_64-unknown-linux-gnu
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

RUN apt update && \
  apt install -y --no-install-recommends \
  ca-certificates \
  curl \
  gpg-agent \
  gnupg \
  openssl && \
  apt update && \
  # - Install build dependencies
  apt install -y --no-install-recommends \
  bash \
  curl \
  git \
  gzip \
  make \
  ninja-build \
  rcs \
  tar \
  unzip \
  xz-utils && \ 
  rm -rf /var/lib/apt/lists/*

RUN wget https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz && \
  tar -xf nasm-${NASM_VERSION}.tar.xz && \
  cd nasm-${NASM_VERSION} && \
  ./configure --prefix=/usr/ && \
  make && \
  make install && \
  cd / && \
  rm -rf nasm-${NASM_VERSION} && \
  rm nasm-${NASM_VERSION}.tar.xz

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Install tools via Proto
RUN proto plugin add cmake "https://raw.githubusercontent.com/Phault/proto-toml-plugins/main/cmake/plugin.toml" && \
  proto plugin add zig "github://konomae/zig-plugin" && \
  proto install cmake && \
  proto install node && \
  proto install rust && \
  proto install zig

# Verify installed tools
RUN echo "----- Verifying installed tools -----" && \
  cargo --version && which cargo && \
  cmake --version | head -n1 && which cmake && \
  echo -n "Node.js " && node -v && which node && \
  nasm -v && which nasm && \
  proto --version && which proto && \
  rustc --version | awk '{print $1, $2}' && which rustc && \
  echo -n "Zig " && zig version && which zig && \
  echo "--------------------"
