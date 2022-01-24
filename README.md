# AutoGitOps CLI

![License](https://img.shields.io/badge/license-MIT-green.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

> AutoGitOps is a CLI that generates GitOps deployment files for Kubernetes deployments

## Overview

`AutoGitOps` is packaged as a dotnet global tool and as a docker container

### Usage

```text

AutoGitOps
  Generate GitOps files for Flux

Usage:
  AutoGitOps [options]

Options:
  -u, --ago-user                 GitHub User Name
  -e, --ago-email                GitHub Email
  -p, --ago-pat                  GitHub Personal Access Token
  -r, --ago-repo                 GitOps Repo (i.e. /bartr/auto-gitops)
  -b, --ago-branch               GitOps branch [default: main]
  -t, --template-dir             Template directory [default: autogitops]
  -o, --output                   Output directory [default: deploy]
  --no-push                      Don't push changes to repo
  -d, --dry-run                  Validates and displays configuration
  --version                      Show version information
  -h, --help                     Show help and usage information

```

### GitOps Repo

- AutoGitOps is a templating engine that commits changes to a GitHub repo specified with the --ago-* parameters
- If the default GitHub user does not have access to the repo, you must specify email, user and PAT parameters
- The `--no-push` option will make the changes to the repo but will not push to GitHub - this is useful for testing

## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
