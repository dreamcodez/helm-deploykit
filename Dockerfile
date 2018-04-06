FROM docker:stable-dind AS build

RUN apk add --no-cache \
  bash \
  build-base \
  curl \
  git

WORKDIR /tmp
RUN git clone https://github.com/sobolevn/git-secret.git git-secret

WORKDIR /tmp/git-secret
RUN make build && PREFIX="/usr/local" make install

WORKDIR /usr/local/bin

# kubectl binary
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

# helm binary
RUN curl -sL https://kubernetes-helm.storage.googleapis.com/helm-v2.8.2-linux-amd64.tar.gz | tar --strip 1 -xvz linux-amd64/helm

# RUNTIME IMAGE
FROM docker:stable-dind

COPY --from=build /usr/local/ /usr/local/

RUN apk add --no-cache \
  bash \
  git \
  python2 \
  py2-pip

RUN pip install --upgrade pip

RUN pip install awscli

ENTRYPOINT dockerd-entrypoint.sh
