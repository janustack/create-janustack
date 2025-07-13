FROM ghcr.io/janustack/create-janustack/napi-rs:debian

ARG ZIG_VERSION=0.14.1

RUN wget https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
  tar -xvf zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
  mv zig-linux-x86_64-${ZIG_VERSION} /usr/local/zig && \
  ln -sf /usr/local/zig/zig /usr/local/bin/zig && \
  rm zig-linux-x86_64-${ZIG_VERSION}.tar.xz