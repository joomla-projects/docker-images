FROM golang:1.21.5-bookworm@sha256:4e2551bdfcc449e1363284ddba11e89607d88e915674b6f654a7a5bf47a83200

ARG UID=1000 \
    GID=1000

# v0.7.0
ENV TUF_VERSION=6ad7fe593e4042db3544c4b0fedbe66bac371c42 \
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
