#!/bin/bash

echo "on-create start" >> "$HOME/status"

# pull docker image
docker pull ghcr.io/bartr/autogitops:latest
docker pull ghcr.io/bartr/autogitops:beta

echo "on-create complete" >> "$HOME/status"
