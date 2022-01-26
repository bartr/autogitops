# AutoGitOps CLI

![License](https://img.shields.io/badge/license-MIT-green.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

> AutoGitOps is a CLI that generates GitOps deployment files for Kubernetes clusters

## Installation

> If you have access to Codespaces, you can skip the installation

- AutoGitOps is packaged as a Docker image
  - `ghcr.io/bartr/autogitops:latest`

```bash

# clone this repo
git clone https://github.com/bartr/autogitops
cd autogitops

# pull docker container
docker pull ghcr.io/bartr/autogitops:latest

```

### Usage

```bash

# display help
docker run -it --rm ghcr.io/bartr/autogitops -h

```

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

> The `autogitops` folder should be in the application repo(s)

- AutoGitOps uses a config file to control the templating engine
  - The default location is `./autogitops/autogitops.json`
  - The location can be changed with `--template-dir`

- Json Fields
  - targets - Deployment targets (required)
    - These map to directories in the `output directory` of the GitOps repo
    - You can include directories explictly (i.e. "west" in the sample)
    - You can include a reference to json key(s) (i.e. "clusters" and "regions in the sample)
    - The result of the included `autogitops.json` is
      - west
      - nyc3
      - central
      - east
  - The remaining fields are user defined
    - name - Kubernetes app and deployment name
    - namespace - Kubernetes namespace
    - imageName - Docker image name
    - imageTag - Docker image tag
    - You can add additional fields

### Sample `autogitops.json` file

```json

{
  "targets": [ "clusters", "regions", "west" ],
  "clusters": [ "nyc3" ],
  "regions": [ "central", "east" ],
  "name": "tinybench",
  "namespace": "tiny",
  "imageName": "ghcr.io/cse-labs/tinybench",
  "imageTag": "latest"
}

```

## Deployment Target Config

- Each deployment target (directory in ./deploy) also contains a `config.json` file
- These are values for one or more clusters that are used by the templating engine
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
  - This example contains the `pre-prod` environment / directory
- Each directory contains one or more yaml `templates`
- These files can contain `substitution parameters`
  - i.e. `{{gitops.name}}` or `{{gitops.config.zone}}`
  - The templating engine will replace with actual values
  - Reference the `cluster config` values with `{{gitops.config.yourKey}}`
  - The templating engine will fail if it cannot find a substitution value for every parameter

### Example App Template

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
    spec:
      containers:
        - name: app
          image: {{gitops.imageName}}:{{gitops.imageTag}}
          imagePullPolicy: Always

          args: 
          - --zone
          - {{gitops.config.zone}}
          - --region
          - {{gitops.config.region}}

```

## Debugging

> This repo contains sample files that you can use for debugging

- You can debug using local files by specifying `--no-push`
- Default `template directory` is `./autogitops`
- Default `output directory` is `./deploy`

```bash

# run AutoGitOps with --no-push
# mount the current directory into the container
# this will use ./autogitops as the config
# this will use ./deploy as the output directory

docker run -it --rm \
--name ago \
-v $(pwd):/ago \
ghcr.io/bartr/autogitops --no-push

# check the changes to ./deploy
# a "tiny" directory will be created for each "target"
# "tiny" is from the namespace parameter

git status

```

### Results

- AutoGitOps applied the template and updated the yaml in the GitOps repo
- If this were a real repo
  - `add` `commit` and `push` the changes to git
  - `GitOps` will automatically deploy the changes to each cluster

```text

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        deploy/central/tiny/
        deploy/east/tiny/
        deploy/nyc3/tiny/
        deploy/west/tiny/

```

## Clean up changes

```bash

git clean -fd
git status

```

## GitOps Repo

- AutoGitOps is a templating engine that commits changes to a GitHub repo specified with the --ago-* parameters
- If the default GitHub user does not have access to the repo, you must specify the PAT parameter
  - git user.name defaults to `autogitops`
  - git user.email defaults to `autogitops@outlook.com`
- The `--no-push` option will make the changes to the repo but will not push to GitHub - this is useful for testing

## Running Locally

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

## Setting up Flux

- Create a GitOps repo
- Create the `deploy` tree
- Add `config.json` to each directory
- Add the repo and correct directory(s) to each cluster
  - Example
    - https://github.com/bartr/autogitops
    - /deploy/central

## Running via CI-CD

- Create and test your GitOps repo
- Configure `autogitops` for each application
- Run `ago` in your CI-CD for each application

```bash

# run ago
# change the repo and PAT parameters
# Note - this will fail on the git push because the PAT is invalid
docker run \
--name ago \
--rm \
-v $(pwd)/autogitops:/ago/autogitops \
ghcr.io/bartr/autogitops -r /bartr/autogitops -p Replace-Repo-and-PAT-with-your-values

```

## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
