FROM debian:latest

ARG ARCH=x86_64
ARG DISTRO=debian
ARG ABI=glibc
ARG TRIPLE=${ARCH}-unknown-linux-${ABI}

ARG NASM_VERSION=2.16.03

ENV \
  CC="zig cc -target ${TRIPLE}" \
  CXX="zig c++ -target ${TRIPLE}" \
  CARGO_HOME=/usr/local/cargo \
  PATH=/usr/local/cargo/bin:/root/.proto/bin:/root/.proto/shims:$PATH

RUN apt update && \
  apt install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  git \
  gnupg \
  gpg-agent \
  gzip \
  make \
  nasm \
  ninja-build \
  openssl \
  rcs \
  tar \
  unzip \
  xz-utils && \
  rm -rf /var/lib/apt/lists/*

# Install NASM
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
