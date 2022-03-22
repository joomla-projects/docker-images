FROM golang:1.17-bullseye@sha256:8c9f292e2356680dadcbc05e53ca8a166ff1db39aadbab6bcd3e68e4042bd9eb

ENV TUF_VERSION=v0.1.0
ENV GIT_URL=https://github.com/joomla/updates.git
ENV GITHUB_CLI_VERSION=2.6.0
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

RUN echo "=> Install go-tuf" && \
    mkdir /tuf && \
    cd /tuf && \
    go install github.com/theupdateframework/go-tuf/cmd/tuf@$TUF_VERSION

COPY docker-entrypoint.sh /tuf/docker-entrypoint.sh
COPY git_env_password.sh /tuf/git_env_password.sh
RUN chmod +x /tuf/docker-entrypoint.sh

ENTRYPOINT ["/tuf/docker-entrypoint.sh"]
CMD ["/tuf/docker-entrypoint.sh"]
