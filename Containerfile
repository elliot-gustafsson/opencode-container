FROM almalinux:10-minimal


RUN microdnf update -y && \
    microdnf install -y \
    wget \
    git \
    tar \
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

ENV PATH="/usr/local/go/bin:/opt/opencode/.opencode/bin:${PATH}"

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace

USER opencode-user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
