# Use the base image
FROM ghcr.io/janustack/create-janustack/napi-rs:debian

# Install Proto toolchain
RUN curl -fsSL https://moonrepo.dev/install/proto.sh | bash -s -- --yes

# Expose Proto on PATH
ENV PATH="/root/.proto/bin:/root/.proto/shims:$PATH"

# Install Zig via Proto plugin
RUN proto plugin add zig "github://konomae/zig-plugin" && \
  proto install zig

# Verify Zig
RUN echo -n "Zig " && zig version && which zig