FROM golang:1.20-bookworm@sha256:fd8d0f8f05c0254d80cfb040e2c6351e477593b7dbf24b0d495ba1e97aa14146

ARG UID=1000 \
    GID=1000

# v0.5.2
ENV TUF_VERSION=91c85a09b56850c90201fa919efac8433bf4f907 \
    GIT_URL=https://github.com/joomla/updates.git \
    GITHUB_CLI_VERSION=2.31.0 \
    GIT_ASKPASS=/tuf/git_env_password.sh \
    eUID=$UID \
    eGID=$GID \
    GOPATH=/tuf \
    PATH="/tuf/bin:${PATH}"

RUN echo "=> Running apt-get update" && \
    apt-get update && \
    apt-get install git jq -y && \
    echo "=> Install Github CLI" && \
    wget -O github-cli.deb https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.deb && \
    dpkg -i github-cli.deb && \
    apt-get install -f && \
    echo "=> Cleanup apt" && \
    rm -rf /var/cache/apt /var/lib/apt/lists github-cli.deb && \
    echo '=> Create User for Docker' && \
    groupadd $eGID && useradd --system -u $eUID -g $eGID -s /bin/bash -m --home-dir /go/ ihavenoname

RUN echo "=> Install go-tuf" && \
    mkdir /tuf && \
    cd /tuf && \
    go install github.com/theupdateframework/go-tuf/cmd/tuf@$TUF_VERSION

# The Docker folder hosts the same folder structure as the filesystem inside the container
COPY Docker/ /

USER ihavenoname
WORKDIR /go/

ENTRYPOINT ["/tuf/docker-entrypoint.sh"]
CMD ["/tuf/docker-entrypoint.sh"]
