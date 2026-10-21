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
    podman \
    fuse-overlayfs \
	&& \
    microdnf clean all

############# php #############
RUN microdnf install -y epel-release && \
    rpm -Uvh https://rpms.remirepo.net/enterprise/remi-release-10.rpm && \
    microdnf module enable -y php:remi-8.5 && \
    microdnf install -y \
        php-cli \
        php-bcmath \
        php-gd \
        php-intl \
        php-ldap \
        php-mbstring \
        php-mysqlnd \
        php-pgsql \
        php-soap \
        php-xml \
        php-pecl-grpc \
        php-pecl-opentelemetry \
        php-pecl-redis6 \
        php-pecl-ssh2 \
        php-pecl-xdebug3 \
        php-pecl-yaml \
        php-pecl-zip && \
    microdnf clean all && \
    wget -O /usr/local/bin/composer https://getcomposer.org/download/latest-stable/composer.phar && \
    chmod 755 /usr/local/bin/composer

ENV COMPOSER_HOME="/tmp/composer"
ENV COMPOSER_CACHE_DIR="/tmp/composer/cache"
ENV PATH="/tmp/composer/vendor/bin:${PATH}"

# Grant the 'ip' binary network capabilities
RUN setcap cap_net_admin+ep $(which ip)

RUN useradd -m -s /bin/bash opencode-user && \
    echo "opencode-user:1001:64535" > /etc/subuid && \
    echo "opencode-user:1001:64535" > /etc/subgid && \
    setcap cap_setuid+ep /usr/bin/newuidmap && \
    setcap cap_setgid+ep /usr/bin/newgidmap && \
    mkdir -p /workspace /etc/containers /home/opencode-user/.local/share /home/opencode-user/.config/opencode && \
    ln -s /tmp/containers /home/opencode-user/.local/share/containers && \
    chown -R opencode-user:opencode-user /workspace /home/opencode-user/.local /home/opencode-user/.config && \
    printf '[storage]\ndriver = "overlay"\nrunroot = "/tmp/containers/run"\ngraphroot = "/tmp/containers/storage"\n\n[storage.options.overlay]\nmount_program = "/usr/bin/fuse-overlayfs"\n' > /etc/containers/storage.conf && \
    printf '[containers]\npidns = "host"\ncgroups = "no-conmon"\ndefault_sysctls = []\n\n[engine]\ncgroup_manager = "cgroupfs"\nevents_logger = "file"\n' > /etc/containers/containers.conf

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
