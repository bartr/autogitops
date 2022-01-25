# AutoGitOps CLI

![License](https://img.shields.io/badge/license-MIT-green.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

> AutoGitOps is a CLI that generates GitOps deployment files for Kubernetes deployments

## Overview

`AutoGitOps` is packaged as a dotnet global tool and as a docker container

## Installation

```bash

# clone this repo
git clone https://github.com/bartr/autogitops
cd autogitops

# run from dotnet
# install AutoGitOps dotnet tool
dotnet tool install -g autogitops

# display usage
ago -h

# run from Docker
docker run -it ghcr.io/bartr/autogitops -h

```

### Usage

```text

AutoGitOps
  Generate GitOps files for Flux

Usage:
  ago [options]

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

## Configuration

> The `autogitops` folder should be in the application that you want to deploy

- AutoGitOps uses a config file to control the templating engine
  - The default location is `./autogitops/autogitops.json`
  - The location can be changed with `--template-dir`
  - You can add your own json fields

- Json Fields
  - name - Kubernetes app and deployment name
  - namespace - Kubernetes namespace
  - imageName - Docker image name
  - imageTag - Docker image tag
  - targets - Deployment targets
    - These map to directories in the `output directory` (default ./deploy)
    - You can include directories explictly (i.e. "west" in the sample)
    - You can include a reference to json key(s) (i.e. "clusters" and "regions in the sample)

### Sample `autogitops.json` file

```json

{
  "name": "tinybench",
  "namespace": "tiny",
  "imageName": "ghcr.io/cse-labs/tinybench",
  "imageTag": "latest",
  "targets": [ "clusters", "regions", "west" ],
  "clusters": [ "nyc3" ],
  "regions": [ "central", "east" ]
}

```

## Deployment Target Config

- Each deployment target (directory in ./deploy) also contains a `config.json` file
- These are values for that cluster that can be used by the templating engine
- `environment` is required and maps to the template to use
- You can define your own json fields
  - `zone` and `region` are examples of custom json fields

### Sample Cluster Config

```json

{
  "environment": "pre-prod",
  "zone": "az-centralus",
  "region": "Central"
}

```

## Templates

- The `autogitops` folder contains template(s) that the CLI uses to generate the yaml
- Each directory represents an `environment` that maps to the `environment` in the `Cluster config.json`
- Each directory contains one or more yaml `templates`
- These files can contain `substitution parameters`
  - i.e. `{{gitops.name}}` or `{{gitops.config.zone}}`
  - The templating engine will replace with actual values
  - Reference the `cluster config` values with `{{gitops.config.yourKey}}`

### Example template

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{gitops.name}}
  namespace: {{gitops.namespace}}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{gitops.name}}
  template:
    metadata:
      labels:
        app: {{gitops.name}}
        version: beta-{{gitops.version}}
        deploy: {{gitops.deploy}}
    spec:
      containers:
        - name: app
          image: {{gitops.imageName}}:{{gitops.imageTag}}
          imagePullPolicy: Always

          args: 
          - -p
          - "8080"

          ports:
            - name: http
              containerPort: 8080
              protocol: TCP

```

## Debugging

- You can debug using local files by specifying `--no-push`
- Default `template directory` is `./autogitops`
- Default `output directory` is `./deploy`

### Running on local files

```bash

# run AutoGitOps with --no-push
ago --no-push

# check the changes to ./deploy
git status

```

### Results

- AutoGitOps applied the template and updated the yaml in the GitOps repo
- If this were a real repo
  - `commit` and `push` the git changes
  - `GitOps` will automatically deploy the changes to each cluster

```text

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        deploy/central/tiny/
        deploy/east/tiny/
        deploy/nyc3/tiny/
        deploy/west/tiny/

```

## GitOps Repo

- AutoGitOps is a templating engine that commits changes to a GitHub repo specified with the --ago-* parameters
- If the default GitHub user does not have access to the repo, you must specify email, user and PAT parameters
- The `--no-push` option will make the changes to the repo but will not push to GitHub - this is useful for testing

```bash

# run AutoGitOps with a sample repo
ago --no-push -r /bartr/autogitops

# change to the cloned repo
cd ../run_autogitops

# see what was changed
git status

```

## Running with Docker

- The key to running with docker is to mount `autogitops` as a volume

```bash

# start the container in an almost endless loop so we can easily check results
# ago is the default entry point
docker run -d \
--name ago \
-v $(pwd)/autogitops:/ago/autogitops \
--entrypoint sleep \
ghcr.io/bartr/autogitops 300d

# execute ago in the container
docker exec -it ago ago --no-push -r /bartr/autogitops

# run git status in the container
docker exec -it ago git -C /run_autogitops status

# open a shell in the container (optional)
# cd /run_autogitops to see the results
# make sure to exit the shell
docker exec -it ago bash

# delete the container
docker rm -f ago

```

## Running with Docker and local output

```bash

docker run -it --rm \
--name ago \
-v $(pwd):/ago \
ghcr.io/bartr/autogitops --no-push

```

## Setting up Flux

- Create a repo
- Create the `deploy` tree
- Add the repo and correct directory to each cluster
  - Example
    - https://github.com/bartr/autogitops
    - /deploy/central

## Running via CI-CD

- Create and test your GitOps repo
- Configure `autogitops` for each application
- Run `ago` in your CI-CD for each application

```bash

# install dotnet global tool
# requires dotnet 5.x
dotnet tool install -g autogitops

# run AutoGitOps
ago -r /bartr/autogitops -b main -u bartr -e bartr@outlook.com -p 123MyPAT456

```

## Running CI-CD with Docker

- The key to running with docker is to mount `autogitops` as a volume

```bash

# run from Docker
docker run -it \
--name ago \
--rm \
-v $(pwd)/autogitops:/ago/autogitops \
ghcr.io/bartr/autogitops -r /bartr/autogitops -b main -u bartr -e bartr@outlook.com -p 123MyPAT456

```

## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
