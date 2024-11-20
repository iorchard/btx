#!/bin/bash

. .env
curl -sLo trident.tar.gz https://github.com/NetApp/trident/releases/download/v${TRIDENT_VERSION}/trident-installer-${TRIDENT_VERSION}.tar.gz 
curl -sLo krew.tar.gz https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_amd64.tar.gz
curl -sLo helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz

tar xzf trident.tar.gz -C ./bin --strip-component 1 \
    trident-installer/tridentctl
tar xzf krew.tar.gz -C ./bin ./krew-linux_amd64
tar xzf helm.tar.gz -C ./bin --strip-component 1 linux-amd64/helm

rm -f trident.tar.gz krew.tar.gz helm.tar.gz


