FROM    debian:bullseye-slim
ARG     BTX_VERSION
ARG     TINI_VERSION
ARG     CIRROS_VERSION
ARG     K8S_VERSION
ARG     OPENSTACK_RELEASE
ARG     CEPH_RELEASE
ARG     HELM_VERSION
ARG     KREW_VERSION
ENV     BTX_VERSION ${BTX_VERSION}
ENV     TINI_VERSION ${TINI_VERSION}
ENV     CIRROS_VERSION ${CIRROS_VERSION}
ENV     K8S_VERSION ${K8S_VERSION}
ENV     OPENSTACK_RELEASE ${OPENSTACK_RELEASE}
ENV     CEPH_RELEASE ${CEPH_RELEASE}
ENV     HELM_VERSION ${HELM_VERSION}
ENV     KREW_VERSION ${KREW_VERSION}
ENV     KREW_ROOT /usr/local/krew
ADD     https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD     http://download.cirros-cloud.net/${CIRROS_VERSION}/cirros-${CIRROS_VERSION}-x86_64-disk.img /cirros.img
ADD     https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY    btx burrito-test.sh helm krew-linux_amd64 bashrc.txt /usr/local/bin/
RUN     apt update && apt -y install gnupg curl && \
        curl http://osbpo.debian.net/osbpo/dists/pubkey.gpg | \
            apt-key add - && \
        curl https://download.ceph.com/keys/release.gpg | \
            apt-key add -
COPY    openstack.list ceph.list /etc/apt/sources.list.d/
SHELL   ["/bin/bash", "-c"]
RUN     apt update && chmod 0644 /cirros.img && \
        DEBIAN_FRONTEND=noninteractive \
            apt -y install git less watch vim-tiny openssh-client \
                mariadb-client dnsutils iputils-ping bash-completion \
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
            --disabled-password --gecos "Burrito Toolbox User" btx && \
        chmod +x /tini /usr/local/bin/kubectl && \
        kubectl completion bash | \
            tee /etc/bash_completion.d/kubectl >/dev/null && \
        /usr/local/bin/krew-linux_amd64 install krew && \
        cat /usr/local/bin/bashrc.txt >> ~/.bashrc && \
        . ~/.bashrc && \
        kubectl krew install ctx ns neat tail && \
        echo $CIRROS_VERSION > /CIRROS_VERSION

ENTRYPOINT  ["/tini", "--", "/usr/local/bin/btx"]
CMD         ["--run"]
