FROM golang:1.20-bookworm@sha256:fd8d0f8f05c0254d80cfb040e2c6351e477593b7dbf24b0d495ba1e97aa14146

ARG UID=1000 \
    GID=1000
ENV eUID=$UID \
    eGID=$GID

RUN groupadd $eGID && useradd --system -u $eUID -g $eGID -s /bin/bash -m --home-dir /go/ ihavenoname

# v0.5.2
ENV TUF_VERSION=91c85a09b56850c90201fa919efac8433bf4f907
ENV GIT_URL=https://github.com/joomla/updates.git
ENV GITHUB_CLI_VERSION=2.31.0
ENV GIT_ASKPASS=/tuf/git_env_password.sh

RUN echo "=> Running apt-get update" && \
    apt-get update && \
    apt-get install git jq -y && \
    echo "=> Install Github CLI" && \
    wget -O github-cli.deb https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.deb && \
    dpkg -i github-cli.deb && \
    apt-get install -f && \
    echo "=> Cleanup apt" && \
    rm -rf /var/cache/apt /var/lib/apt/lists github-cli.deb

ENV GOPATH=/tuf
ENV PATH="/tuf/bin:${PATH}"

RUN echo "=> Install go-tuf" && \
    mkdir /tuf && \
    cd /tuf && \
    go install github.com/theupdateframework/go-tuf/cmd/tuf@$TUF_VERSION

COPY docker-entrypoint.sh /tuf/docker-entrypoint.sh
COPY functions.inc.sh /tuf/functions.inc.sh
COPY git_env_password.sh /tuf/git_env_password.sh
RUN chmod +x /tuf/docker-entrypoint.sh

USER ihavenoname

WORKDIR /go/

ENTRYPOINT ["/tuf/docker-entrypoint.sh"]
CMD ["/tuf/docker-entrypoint.sh"]
