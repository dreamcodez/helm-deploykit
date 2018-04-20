# Docker-in-Docker image so we can run the docker daemon inside a docker container.
# This is because AWS codebuild itself runs on docker, and we need to be able to utilize the daemon flexibly.
FROM docker:stable-dind AS build

WORKDIR /usr/local/bin

# one layer for better size, remove build deps before its done :)
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
RUN \
  apk add --no-cache \
    bash \
    build-base \
    curl \
    gawk \
    libffi-dev \
    openssl-dev \
    python2-dev \
    py2-pip \
    tzdata \
    xz

RUN pip install --upgrade pip
RUN pip install awscli credstash

RUN \
  echo Downloading kubectl binary... && \
  curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
  chmod a+x kubectl

RUN \
  echo Downloading helm binary... && \
  (curl -sL https://kubernetes-helm.storage.googleapis.com/helm-v2.8.2-linux-amd64.tar.gz | tar --strip 1 -xvz linux-amd64/helm) && \
  chmod a+x helm

# removing buildtime deps
RUN apk del --no-cache \
  build-base \
  curl \
  gawk \
  libffi-dev \
  openssl-dev \
  python2-dev

# add just runtime lib deps back in
RUN apk add --no-cache \
    libffi \
    openssl \
    python2

# one output layer
FROM scratch

COPY --from=build / /

# same as base image
#ENTRYPOINT dockerd-entrypoint.sh
