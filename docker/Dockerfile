FROM    debian:bullseye-slim
ENV     TINI_VERSION v0.19.0
ENV     CIRROS_VERSION 0.5.1
ENV     K8S_VERSION v1.24.7
ADD     https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD     http://download.cirros-cloud.net/${CIRROS_VERSION}/cirros-${CIRROS_VERSION}-x86_64-disk.img /cirros.img
ADD     https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY    btx burrito-test.sh helm /usr/local/bin/
RUN     apt update && apt -y install gnupg curl && \
        curl http://osbpo.debian.net/osbpo/dists/pubkey.gpg | \
            apt-key add - && \
        curl https://download.ceph.com/keys/release.gpg | \
            apt-key add -
COPY    openstack.list ceph.list /etc/apt/sources.list.d/
RUN     apt update && chmod 0644 /cirros.img && \
        DEBIAN_FRONTEND=noninteractive \
            apt -y install git less watch vim-tiny openssh-client \
                mariadb-client dnsutils iputils-ping \
                ceph-common s3cmd \
                python3-openstackclient \
                python3-cinderclient \
                python3-glanceclient \
                python3-keystoneclient \
                python3-neutronclient \
                python3-novaclient \
                python3-osc-placement \
                python3-secretstorage && \
        adduser --home /home/btx --shell /bin/bash --uid 1000 --gid 100 \
            --disabled-password --gecos "Burrito Toolbos User" btx && \
        chmod +x /tini /usr/local/bin/kubectl && \
        echo $CIRROS_VERSION > /CIRROS_VERSION

ENTRYPOINT  ["/tini", "--", "/usr/local/bin/btx"]
CMD         ["--run"]
