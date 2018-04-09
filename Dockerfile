# Docker-in-Docker image so we can run the docker daemon inside a docker container.
# This is because AWS codebuild itself runs on docker, and we need to be able to utilize the daemon flexibly.
FROM docker:stable-dind AS build

# base alpine os dependencies (docker dnd is based on alpine)
# bash is because alpine only includes sh by default and I like the extra features for my shell scripts
RUN apk add --no-cache \
  bash \
  build-base \
  curl \
  git

# custom build of git-secret since package is not available in this alpine version
WORKDIR /tmp
RUN git clone https://github.com/sobolevn/git-secret.git git-secret

WORKDIR /tmp/git-secret
RUN make build && PREFIX="/usr/local" make install

# install various binaries into /usr/local/bin
WORKDIR /usr/local/bin

# kubectl binary
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

# helm binary
RUN curl -sL https://kubernetes-helm.storage.googleapis.com/helm-v2.8.2-linux-amd64.tar.gz | tar --strip 1 -xvz linux-amd64/helm

# RUNTIME IMAGE
# this image will copy only runtime-necessary components from the build image so that the size and number of layers is minimal
# starts from same base image as the build image for compatibility
FROM docker:stable-dind

# copy in custom installed components first
COPY --from=build /usr/local/ /usr/local/

# the python tools and gnupg are not needed until 'runtime' that is 'deploy-time'
RUN apk add --no-cache \
  bash \
  gawk \
  git \
  gnupg \
  python2 \
  py2-pip

# get rid of old version warning :)
RUN pip install --upgrade pip

# needed so i can log into ec container registry and potentially use s3 in the future
RUN pip install awscli

# same as base image
ENTRYPOINT dockerd-entrypoint.sh
