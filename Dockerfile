FROM golang:1.20-bullseye@sha256:4d4ba872594961e984692f8ae0bf7e893c83ed02f3191789fbd6e9bd524da15b

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

COPY Docker/tuf-scripts /usr/local/bin/

ENTRYPOINT ["/tuf/docker-entrypoint.sh"]
CMD ["/tuf/docker-entrypoint.sh"]
