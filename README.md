# AutoGitOps CLI

![License](https://img.shields.io/badge/license-MIT-green.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

> AutoGitOps is a CLI that generates GitOps deployment files for Kubernetes clusters

- AutoGitOps is packaged as a Docker image
  - `ghcr.io/bartr/autogitops:latest`
  - `ghcr.io/bartr/autogitops:beta`

> This readme uses the :beta version for testing

## Open in Codespaces

- Open this repo in Codespaces
  - Click `Code`
  - Create new Codespace

### Usage

```bash

# display help
docker run -it --rm ghcr.io/bartr/autogitops:beta -h

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
  -c, --container-version <container-version>  Container version number [default: yy-mm-dd-yy-mm-ss]
  -o, --output                   Output directory [default: deploy]
  --no-push                      Don't push changes to repo
  -d, --dry-run                  Validates and displays configuration
  --version                      Show version information
  -h, --help                     Show help and usage information

```

## Configuration

> The `autogitops` folder should be in the application repo(s)
>
> The `autogitops` and `deploy` folders are included here for ease of evaluating

- AutoGitOps uses a config file to control the templating engine
  - The location is `./autogitops/autogitops.json`
    - Note: each application will have a unique autogitops.json file

- Json Fields
  - name - Kubernetes app and deployment name (required)
  - namespace - Kubernetes namespace (required)
  - targets - Deployment targets (required)
    - The values map to one of three options
      - Clusters (directories) in the `output directory` of the GitOps repo
      - "all" - keyword to deploy to all clusters (directories)
      - "key:value" - AGO will check each cluster's config.json file for a match
        - you can use simple values or arrays in the config.json
          - "region": "central"
          - "tags": [ "red", "blue", "green" ]
          - complex objects are not supported
  - targetDir - the target directory for this app
    - this is appended to the output directory (default: deploy)
    - in our example, heartbeat will be deployed to the `deploy/bootstrap` directory
    - we recommend you have at least 2 directories - bootstrap and apps in our case
      - you may want to add directories by "app suite" and/or "app team"
  - The remaining fields are user defined
    - imageName - Docker image name
    - imageTag - Docker image tag
    - You can add additional fields for use in the templating engine

### Sample `autogitops.json` file

```json

{
  // required
  "name": "heartbeat",
  "namespace": "heartbeat",
  "targets": [ "region:central" ],

  // reserved
  "targetDir": "bootstrap",

  // user defined
  "imageName": "ghcr.io/bartr/heartbeat",
  "imageTag": "latest",
  "author": "bartr",
  "foo": "bar"
}

```

## Deployment Target Config

- Each deployment target (directory in ./deploy/[apps | bootstrap]) also contains a `config.json` file
- Each directory maps to one cluster and can contain cluster specific infomation such as `store`
- `environment` is required and maps to the template to use
- You can define your own json fields
  - `zone` `region` `store` are examples of custom json fields

### Sample Cluster Config

```json

{
  // required
  "environment": "dev",

  // user defined
  "zone": "az-southcentral",
  "region": "central",
  "store": "central-tx-atx-101"
}

```

## Templates

- The `autogitops` folder contains template(s) that the CLI uses to generate the yaml
- Each directory represents an `environment` that maps to the `environment` in the `Cluster config.json`
  - This example contains the `dev` environment
- Each directory contains one or more yaml `templates`
- These files can contain `substitution parameters`
  - i.e. `{{gitops.name}}` - application value
  - i.e. `{{gitops.config.zone}}` - cluster value (gitops.config.*)
  - The templating engine will replace with actual values for each cluster
  - The templating engine will fail if it cannot find a substitution value for every parameter in the template(s)

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

- You can debug by specifying `--no-push`
  - This will allow you to see the changes without updating the repo
- Default `output directory` is `./deploy`
  - `targetDir` is set to `bootstrap` in the heartbeat app
    - the results will show up in `./deploy/bootstrap/atx-101`

```bash

# run AutoGitOps with --no-push
# mount the current directory into the container

docker run -it --rm \
-v $PWD:/ago \
ghcr.io/bartr/autogitops:beta --no-push

# check the changes to ./deploy/bootstrap
# a "heartbeat" directory will be created for the atx-101 cluster

git status

```

### Results

- AutoGitOps applied the template and updated the yaml in the GitOps repo
- If this were a real repo
  - `add` `commit` and `push` the changes to git
  - `GitOps` will automatically pull the changes to each cluster

```text

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        deploy/bootstrap/atx-101/heartbeat/

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

- The key to running with docker is to mount the current directory as a volume

```bash

# start the container in an almost endless loop so we can easily check results
# ago is the default entry point
docker run -d \
--name ago \
-v $(pwd):/ago \
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
    - /deploy/bootstrap

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
-v $(pwd):/ago \
ghcr.io/bartr/autogitops:beta -r yourOrg/yourRepo -p yourPAT

```

## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
