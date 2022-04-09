#!/bin/bash

echo "post-start start" >> "$HOME/status"

# this runs each time the container starts

# pull latest docker image
docker pull ghcr.io/bartr/autogitops:latest
docker pull ghcr.io/bartr/autogitops:beta

echo "post-start complete" >> "$HOME/status"
