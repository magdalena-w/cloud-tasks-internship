#!/bin/bash

PROJECT_ID="id"
DOCKER_IMAGE_NAME="gcp-petclinic"

# Install Docker on the VM
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -a -G docker ${USER}

# Authenticate Docker

# Run the Docker container from GCR
docker pull gcr.io/$PROJECT_ID/my-gcr-repo/$DOCKER_IMAGE_NAME:latest
docker tag gcr.io/$PROJECT_ID/my-gcr-repo/$DOCKER_IMAGE_NAME:latest petclinic
docker run -d -p 8080:8080 petclinic
