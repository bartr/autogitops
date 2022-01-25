#!/bin/bash

echo "on-create start" >> $HOME/status

# install AutoGitOps CLI
dotnet tool install -g autogitops

# pull docker image
docker pull ghcr.io/bartr/autogitops

echo "on-create complete" >> $HOME/status
