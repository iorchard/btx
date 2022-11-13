#!/bin/bash
# build jijisa/btx

REL=${1:-yoga}

cat <<EOF > openstack.list
deb http://osbpo.debian.net/osbpo bullseye-${REL}-backports main
deb http://osbpo.debian.net/osbpo bullseye-${REL}-backports-nochange main
EOF

HELM_VERSION="v3.10.2"
HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
curl -sL ${HELM_URL} | tar --strip-components 1 -xz linux-amd64/helm

docker build -t jijisa/btx:${REL} .
