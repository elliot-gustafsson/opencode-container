FROM almalinux:10-minimal


RUN microdnf update -y && \
    microdnf install -y \
    wget \
    git \
    tar \
    xz \
    gzip \
    unzip \
    which \
    vim-minimal \
    iproute \
    util-linux \
    libcap \
    gcc \
    lld \
    && \
    microdnf clean all

# Grant the 'ip' binary network capabilities
RUN setcap cap_net_admin+ep $(which ip)

RUN useradd -m -s /bin/bash opencode-user && \
    mkdir -p /workspace && \
    chown opencode-user:opencode-user /workspace

############# go #############

ARG GO_VERSION=go1.27.1
RUN wget -P /tmp https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/${GO_VERSION}.linux-amd64.tar.gz && \
    rm /tmp/${GO_VERSION}.linux-amd64.tar.gz

ENV GOPATH="/tmp/go"
ENV GOCACHE="/tmp/go/cache"
ENV GOMODCACHE="/tmp/go/modcache"

ENV PATH="/usr/local/go/bin:${PATH}"

############# zig #############

ARG ZIG_VERSION=0.16.0
RUN wget -O /tmp/zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz && \
    rm -rf /usr/local/zig && \
    mkdir /tmp/zig && \
    tar -C /tmp/zig -xf /tmp/zig.tar.xz && \
    mv /tmp/zig/zig-x86_64-linux-${ZIG_VERSION} /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig && \
    rm -rf /tmp/zig /tmp/zig.tar.xz

ENV ZIG_LOCAL_CACHE_DIR="/tmp/zig-cache"
ENV ZIG_GLOBAL_CACHE_DIR="/tmp/zig-global-cache"

############# rust #############

ARG RUST_VERSION=1.96.0
ENV RUSTUP_HOME="/usr/local/rustup"
RUN export CARGO_HOME="/usr/local/cargo" && \
    wget -qO- https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain ${RUST_VERSION} && \
    chmod -R a+rx /usr/local/rustup /usr/local/cargo

ENV CARGO_HOME="/tmp/cargo"
ENV CARGO_TARGET_DIR="/tmp/cargo/target"
ENV RUSTFLAGS="-C link-arg=-fuse-ld=lld"

ENV PATH="/tmp/cargo/bin:/usr/local/cargo/bin:${PATH}"

############# opencode #############

# Releases: https://github.com/anomalyco/opencode/tags
ARG OPENCODE_VERSION=2.0.27
RUN wget -O /tmp/install https://opencode.ai/v2/install && \
    HOME=/opt/opencode bash /tmp/install --version ${OPENCODE_VERSION} && \
    chmod 755 /opt/opencode/.opencode/bin/opencode && \
    rm -f /tmp/install

ENV PATH="/opt/opencode/.opencode/bin:${PATH}"


COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace

USER opencode-user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
