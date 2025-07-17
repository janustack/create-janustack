FROM debian:latest

ARG ARCH=aarch64
ARG OS=linux
ARG ABI=glibc
ARG TRIPLE=${ARCH}-unknown-${OS}-${ABI}

ENV \
  CC="zig cc -target ${TRIPLE}" \
  CXX="zig c++ -target ${TRIPLE}" \
  CFLAGS="/usr/${TRIPLE}/${TRIPLE}/sysroot" \
  CXXFLAGS="/usr/${TRIPLE}/${TRIPLE}/sysroot" \
  C_INCLUDE_PATH="/usr/${TRIPLE}/${TRIPLE}/sysroot/usr/include"


RUN apt-get update && \
  apt-get install -y --fix-missing --no-install-recommends curl gnupg gpg-agent ca-certificates openssl && \
  apt-get update && \
  apt-get install -y --fix-missing --no-install-recommends \
  xz-utils \
  rcs \
  bash \
  ca-certificates \
  curl \
  git \
  make \
  cmake \
  ninja-build && \
  apt-get autoremove -y

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

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