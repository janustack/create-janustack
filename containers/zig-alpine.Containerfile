# Use the base image
FROM ghcr.io/janustack/create-janustack/napi-rs:alpine

RUN apk add --update --no-cache \
  --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  xz xz-dev \
  bash \
  ca-certificates \
  curl

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install Zig via Proto plugin
RUN proto plugin add zig "github://konomae/zig-plugin" && \
  proto install zig

# Verify Zig
RUN echo -n "Zig " && zig version && which zig