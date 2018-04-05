FROM docker:stable-dind

RUN apk add --no-cache \
  curl \
  py2-pip

RUN pip install --upgrade pip

RUN pip install awscli

WORKDIR /usr/local/bin

# kubectl binary
RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

# helm binary
RUN curl -sL https://kubernetes-helm.storage.googleapis.com/helm-v2.8.2-linux-amd64.tar.gz | tar --strip 1 -xvz linux-amd64/helm

WORKDIR /

ENTRYPOINT dockerd-entrypoint.sh
