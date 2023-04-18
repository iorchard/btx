#!/bin/bash
set -e 

. .env

# get the most recent git tag
set +e
BTX_VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "${BTX_VERSION}" ]; then
  echo "No git tag is found. I'll use the last commit id instead."
  BTX_VERSION=$(git rev-parse --short HEAD)
fi
set -e

cat <<EOF > openstack.list
deb http://osbpo.debian.net/osbpo bullseye-${OPENSTACK_RELEASE}-backports main
deb http://osbpo.debian.net/osbpo bullseye-${OPENSTACK_RELEASE}-backports-nochange main
EOF

cat <<EOF > ceph.list
deb https://download.ceph.com/debian-${CEPH_RELEASE} bullseye main
EOF

HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
curl -sL ${HELM_URL} | tar --strip-components 1 -xz linux-amd64/helm

KREW_URL="https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_amd64.tar.gz"
curl -sL ${KREW_URL} | tar -xz ./krew-linux_amd64

TRIDENT_URL="https://github.com/NetApp/trident/releases/download/v${TRIDENT_VERSION}/trident-installer-${TRIDENT_VERSION}.tar.gz"
curl -sL ${TRIDENT_URL} | tar --strip-components 1 -xz trident-installer/tridentctl

docker build \
  -t jijisa/btx:${BTX_VERSION} \
  --build-arg BTX_VERSION=${BTX_VERSION} \
  --build-arg TINI_VERSION=${TINI_VERSION} \
  --build-arg CIRROS_VERSION=${CIRROS_VERSION} \
  --build-arg K8S_VERSION=${K8S_VERSION} \
  --build-arg OPENSTACK_RELEASE=${OPENSTACK_RELEASE} \
  --build-arg CEPH_RELEASE=${CEPH_RELEASE} \
  --build-arg HELM_VERSION=${HELM_VERSION} \
  --build-arg KREW_VERSION=${KREW_VERSION} \
  --build-arg TRIDENT_VERSION=${TRIDENT_VERSION} \
  .

docker tag jijisa/btx:${BTX_VERSION} jijisa/btx:latest
docker push jijisa/btx:${BTX_VERSION}
docker push jijisa/btx:latest
