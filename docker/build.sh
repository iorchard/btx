#!/bin/bash
set -e 

. .env

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

docker build \
  -t jijisa/btx:${OPENSTACK_RELEASE}-${K8S_VERSION}-${CEPH_RELEASE} \
  --build-arg TINI_VERSION=${TINI_VERSION} \
  --build-arg CIRROS_VERSION=${CIRROS_VERSION} \
  --build-arg K8S_VERSION=${K8S_VERSION} \
  --build-arg KREW_VERSION=${KREW_VERSION} \
  .

docker tag jijisa/btx:${OPENSTACK_RELEASE}-${K8S_VERSION}-${CEPH_RELEASE} \
  jijisa/btx:latest
docker push jijisa/btx:${OPENSTACK_RELEASE}-${K8S_VERSION}-${CEPH_RELEASE}
docker push jijisa/btx:latest
