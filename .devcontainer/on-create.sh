#!/bin/bash

echo "on-create start" >> $HOME/status

# pull docker image
docker pull ghcr.io/bartr/autogitops

echo "on-create complete" >> $HOME/status
