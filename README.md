# Auto Git Ops

![License](https://img.shields.io/badge/license-MIT-green.svg)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

> AutoGitOps is a CLI that generates GitOps deployment files for Kubernetes clusters

- AutoGitOps is packaged as a Docker image
  - docker pull ghcr.io/bartr/autogitops:latest
  - docker pull ghcr.io/bartr/autogitops:beta
- AutoGitOps is mainly used in CI-CD pipelines (for CD)
- AutoGitOps is a `templating engine` that combines values from
  - Application config
  - Application template(s) (yaml files)
  - Cluster config
- AutoGitOps allows you to deploy to multiple clusters in your fleet
  - `Targets` are stored in each application config
  - `meta data` is stored in each cluster config
  - AutoGitops combines the config files and templates for each matching cluster
- Any error while applying the templates and the entire attempt is aborted
  - No partial updates

> This readme uses the :beta version for testing
>
> Version 0.4.0 has several breaking changes

## Open in Codespaces

- Open this repo in Codespaces
  - Click `Code`
    - Click `Create new Codespace`
- If you don't have access to Codespaces
  - I'm sorry :( - Codespaces is `AMAZING`
  - Any dev machine with Docker installed should work
  - But is not tested

### Usage

- From your terminal

```bash

# display help
docker run --rm ghcr.io/bartr/autogitops:beta -h

```

- Output

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

> The `autogitops` folder must be in each application repo
>
> The `autogitops` and `deploy` folders are included here for ease of evaluating

- AutoGitOps uses config files to control the templating engine
  - The location is `./autogitops/autogitops.json`
    - Note: each application will have a unique autogitops.json file
    - Note: each cluster will have a unique config.json file

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
  - targetDir - the target directory for this app (reserved)
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

  // specific cluster, metadata match
  "targets": [ "atx-101", "region:central" ],

  // all clusters
  // you cannot combine all - it must be the only target
  // "targets": [ "all" ],

  // reserved
  // in our example, bootstrap or apps
  "targetDir": "bootstrap",
  // "targetDir": "apps",

  // user defined
  "imageName": "ghcr.io/bartr/heartbeat",
  "imageTag": "latest",
  "author": "bartr",
  "args": [ "--server", "my-server" ]
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
  "store": "central-tx-atx-101",
  "tags:": [ "red", "blue", "green" ]
}

```

## Templates

- The `autogitops` folder contains template(s) that the CLI uses to generate the yaml
- Each directory represents an `environment` that maps to the `environment` in the `Cluster config.json`
  - This example uses the `dev` environment
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
    - If you fork the repo, you can update
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

## Change the Targets

- Open `autogitops/autogitops.json`
- change
  - "targets": [ "region:central" ]
- to
  - "targets": [ "all" ]
- Run `AutoGitOps`

  ```bash

  docker run -it --rm \
  -v $PWD:/ago \
  ghcr.io/bartr/autogitops:beta --no-push

  ```

## Clean Up

```bash

git clean -fd
git status

```

## Using a GitOps Repo

- The `--no-push` option will make the changes to the repo but will not push to GitHub - this is useful for testing
- You must specify the PAT parameter to push
  - git user.name defaults to `autogitops`
  - git user.email defaults to `autogitops@outlook.com`

## Running Locally

- You must mount a directory as a volume
  - `/ago` is an empty directory in the container
  - `/deploy` is an empty directory in the container

```bash

# start the container in an almost endless loop so we can easily check results
# ago is the default entry point
docker run -d \
--name ago \
-v $PWD:/ago \
--entrypoint sleep \
ghcr.io/bartr/autogitops:beta 300d

# execute ago in the container
# --repo (-r) is the org/name of your GitHub repo
#   use a full https address for non-GitHub repos
docker exec -it ago ago --no-push -r /bartr/autogitops

# run git status in the container
# the --repo gets cloned to /run_autogitops inside the container
docker exec -it ago git -C /run_autogitops status

# delete the container
docker rm -f ago

```

## Creating a GitOps Repo

> The easiest way is to copy this repo

- Create a repo
- Create `deploy/bootstrap` tree
- Create `deploy/apps` tree
  - Create a directory per cluster in each tree
    - Add `config.json` to each directory in both trees
- We automate this as part of our cluster bootstrap

## Setting up Flux

- Make sure flux has access to your repo(s)
- Run `flux bootstrap`
  - specify your repo
  - path = /deploy/bootstrap/clusterDirectory
- Create a `flux git source`
  - specify your repo
  - specify your branch (default: main)
  - path = /deploy/apps/clusterDirectory
- Create two `flux kustomization`
  - one for bootstrap
  - one for apps

### Sample Flux Setup Commands

- Update the export commands with your values
  - Flux pushes to the repo during bootstrap, so your PAT has to have push permissions

  ```bash

  # update with your values
  export MY_REPO="bartr/autogitops"
  export MY_CLUSTER="atx-101"
  export MY_BRANCH="main"
  export MY_PAT="my Personal Access Token"

  # bootstrap the cluster
  flux bootstrap git \
    --url "https://github.com/$MY_REPO" \
    --branch "$MY_BRANCH" \
    --password "$MY_PAT" \
    --token-auth true \
    --path "./deploy/bootstrap/$MY_CLUSTER"

  # create a git source
  flux create source git gitops \
    --url "https://github.com/$MY_REPO" \
    --branch "$MY_BRANCH" \
    --password "$MY_PAT" \

  # create the bootstrap kustomization (or helm)
  flux create kustomization bootstrap \
    --source GitRepository/gitops \
    --path "./deploy/bootstrap/$MY_CLUSTER" \
    --prune true \
    --interval 1m

  # create the apps kustomization (or helm)
  flux create kustomization apps \
    --source GitRepository/gitops \
    --path "./deploy/apps/$MY_CLUSTER" \
    --prune true \
    --interval 1m

  # force flux to reconcile (sync) with the GitOps repo
  flux reconcile source git gitops

  # check your results
  kubectl get pods -A

  ```

## Running via CI-CD

- Create and test your app(s) and GitOps repo locally
- Configure `autogitops` for each application
- Run `AutoGitOps` in your CI-CD for each application

```bash

# run autogtiops
# change the repo and PAT parameters
# Note - this will fail on the git push if the PAT is invalid
# We use a GitHub org secret for our github PAT
#  ${{ secrets.GHCR_PAT }}
docker run --rm \
-v $(pwd):/ago \
ghcr.io/bartr/autogitops:beta \
-r yourOrg/yourRepo \
-p yourPAT

```

## Sample GitHub Action

```yaml

name: AutoGitOps

on:
  push:
    paths:
    - 'your paths'

jobs:
  build:
    runs-on: ubuntu-20.04

    steps:
    - uses: actions/checkout@v2

    - name: Docker pull
      run: |
        docker pull ghcr.io/bartr/autogitops:beta

    - name: GitOps Deploy
      run: |
        docker run --rm \
        -v $(pwd):/ago \
        ghcr.io/bartr/autogitops:beta \
        -r yourOrg/yourRepo \
        -p ${{ secrets.GHCR_PAT }}

```

## Support

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new issue.

## Contributing

This project welcomes contributions and suggestions and has adopted the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).

For more information see [Contributing.md](./.github/CONTRIBUTING.md)

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.
