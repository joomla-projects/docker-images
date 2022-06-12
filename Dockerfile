FROM golang:1.18-bullseye@sha256:5417b4917fa7ed3ad2678a3ce6378a00c95bfd430c2ffa39936fce55130b5f2c

ENV TUF_VERSION=ae904d2bb977a54e6a5527513c4d398c8d9cc285
ENV GIT_URL=https://github.com/joomla/updates.git
ENV GITHUB_CLI_VERSION=2.12.1
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

ENTRYPOINT ["/tuf/docker-entrypoint.sh"]
CMD ["/tuf/docker-entrypoint.sh"]
