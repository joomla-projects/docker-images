# Joomla! TUF Docker

## Table Of Content

- [Jooma! Tuf Docker](#joomla-tuf-docker)- [Joomla! TUF Docker](#joomla-tuf-docker)
  - [Table Of Content](#table-of-content)
  - [VARS](#vars)
  - [Setup](#setup)
  - [Avaible TUF parameters for the Docker TUF Client](#avaible-tuf-parameters-for-the-docker-tuf-client)
    - [`prepare-release`](#prepare-release)
    - [`sign-release`](#sign-release)
    - [`release`](#release)
    - [`update-timestamp`](#update-timestamp)
    - [`bash`](#bash)

## VARS

| ⚠️ REQUIRED | VAR | DEFAULT | COMMENT |
| -- | ------------------ | -------- | -------------------------------------------------- |
| ⚠️ | GIT_BRANCH_NAME    |          | The Branch name to checkout in the Container       |
|    | TUF_VERSION        | `v0.1.0` | The go-tuf version insalled                        |
| ⚠️ | ACCESS_TOKEN       |          | Github Access token with access to the `GIT_RUL`   |
|    | GIT_URL            | <https://github.com/joomla/updates.git> | The Github Repo URL |
|    | GITHUB_CLI_VERSION | `2.6.0`  | The Github CLI Version to install                  |
| ⚠️ | GIT_USER_NAME      | ``       | git usernname for the gitconfig runtime |
| ⚠️ | GIT_USER_EMAIL     | ``       | git user.email for the gitconfig runtime |

## Setup

Build the Image

```bash
docker build -t joomla-tuf:latest -f Dockerfile .
```

Run your commands directly against tuf.
Use `-e` in `docker run` to pass ENV variables.

```bash
docker run -e ACCESS_TOKEN=REDACTED_TOKEN -e GIT_BRANCH_NAME=main joomla-tuf "help"
usage: tuf [-h|--help] [-d|--dir=<dir>] [--insecure-plaintext] <command> [<args>...]
```

## Avaible TUF parameters for the Docker TUF Client

This documents which paramters are avaible for the `sign.sh` script, when asked for `Parameter to be passed to TUF:`.

### prepare-release

The `prepare-release` parameter will generate from asked Inputs a `update-info.json` which thenn will be used by TUF and commited directly.

### sign-release

The sign-rlease parameter will sign all targets defined in the `targets.json` and push the changes directly.

### release

The `release` parameter is meant for CI integration.

The result will be a signed release in a Github Pullrequest.

### update-timestamp

The `update-timestamp` paramter is meant for a CRON like CI integration.

It will run `tuf timestamp` and `tuf commit` and push the changes directly.

### bash

This will open an interactive shell inside the Docker TUF Client so users can work with TUF directly.
