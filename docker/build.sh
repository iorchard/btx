#!/bin/bash
set -e 

CURRENT_DIR=$( dirname "$(readlink -f "$0")" )

. .env

dockerfile_envs=$(while read line;do k=${line%%=*};v=${line##*=};echo -e "ENV $k $v";done<.env)
perl -pe "s/%%ARG%%/${dockerfile_args}/;s/%%ENV%%/${dockerfile_envs}/" Dockerfile > Dockerfile.btx

# get the most recent git tag
set +e
BTX_VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "${BTX_VERSION}" ]; then
  echo "No git tag is found. I'll use the last commit id instead."
  BTX_VERSION=$(git rev-parse --short HEAD)
fi
set -e

cat <<EOF > openstack.list
deb http://osbpo.debian.net/osbpo bookworm-${OPENSTACK_RELEASE}-backports main
deb http://osbpo.debian.net/osbpo bookworm-${OPENSTACK_RELEASE}-backports-nochange main
EOF

cat <<EOF > ceph.list
deb https://download.ceph.com/debian-${CEPH_RELEASE} bookworm main
EOF

pushd ${CURRENT_DIR}/bin
  HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
  curl -sL ${HELM_URL} | tar --strip-components 1 -xz linux-amd64/helm
  
  KREW_URL="https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_amd64.tar.gz"
  curl -sL ${KREW_URL} | tar -xz ./krew-linux_amd64
  
  TRIDENT_URL="https://github.com/NetApp/trident/releases/download/v${TRIDENT_VERSION}/trident-installer-${TRIDENT_VERSION}.tar.gz"
  curl -sL ${TRIDENT_URL} | tar --strip-components 1 -xz trident-installer/tridentctl
popd

docker build \
  -t jijisa/btx:${BTX_VERSION} \
  --build-arg BTX_VERSION=${BTX_VERSION} \
  --file Dockerfile.btx \
  .

