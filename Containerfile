FROM registry.fedoraproject.org/fedora-toolbox:44

# renovate: datasource=github-release-attachments depName=git-ecosystem/git-credential-manager versioning=semver
ARG GCM_VERSION=3.0.2
ARG GCM_SHA256=b8e59e22a830006ca4d93e34513effbb2d9fc0c45d9ccf40395eaab7c4c1b97e
ARG GCM_ARCH=x64

LABEL org.opencontainers.image.title="git-toolbox"
LABEL org.opencontainers.image.description="Git development toolbox for Fedora CoreOS"

RUN dnf5 install -y \
    git \
    git-filter-repo git-lfs git-revise git-delta \
    gnupg2 \
    pass \
    pgp-tools \
    libicu \
    pinentry \
    openssh-clients \
    curl \
    && dnf5 clean all

RUN curl \
    --fail \
    --show-error \
    --location \
    --retry 10 \
    --retry-all-errors \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 300 \
    "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux-${GCM_ARCH}-${GCM_VERSION}.tar.gz" \
    -o /tmp/gcm.tar.gz \
    && echo "${GCM_SHA256}  /tmp/gcm.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/gcm.tar.gz -C /usr/local/bin \
    && rm /tmp/gcm.tar.gz

COPY bin/git-wrapper /usr/local/bin/git-wrapper
RUN chmod 0755 /usr/local/bin/git-wrapper

CMD ["/bin/bash"]
