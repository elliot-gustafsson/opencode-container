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
    rust \
    cargo \
    && \
    microdnf clean all

# Grant the 'ip' binary network capabilities
RUN setcap cap_net_admin+ep $(which ip)

RUN useradd -m -s /bin/bash opencode-user && \
    mkdir -p /workspace && \
    chown opencode-user:opencode-user /workspace

RUN wget -O /tmp/install https://opencode.ai/install && \
    HOME=/opt/opencode bash /tmp/install && \
    chmod 755 /opt/opencode/.opencode/bin/opencode && \
    rm -f /tmp/install

ARG GO_VERSION=go1.26.3
RUN wget -P /tmp https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/${GO_VERSION}.linux-amd64.tar.gz && \
    rm /tmp/${GO_VERSION}.linux-amd64.tar.gz

ARG ZIG_VERSION=0.16.0
RUN wget -O /tmp/zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz && \
    rm -rf /usr/local/zig && \
    mkdir /tmp/zig && \
    tar -C /tmp/zig -xf /tmp/zig.tar.xz && \
    mv /tmp/zig/zig-x86_64-linux-${ZIG_VERSION} /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig && \
    rm -rf /tmp/zig /tmp/zig.tar.xz

ENV GOPATH="/tmp/go"
ENV GOCACHE="/tmp/go/cache"
ENV GOMODCACHE="/tmp/go/modcache"

ENV PATH="/usr/local/go/bin:/opt/opencode/.opencode/bin:${PATH}"

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace

USER opencode-user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
