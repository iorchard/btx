FROM    debian:bookworm-slim
ARG     BTX_VERSION
%%ARG%%
ENV     BTX_VERSION ${BTX_VERSION}
%%ENV%%
ENV     KREW_ROOT /usr/local/krew
ADD     https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD     http://download.cirros-cloud.net/${CIRROS_VERSION}/cirros-${CIRROS_VERSION}-x86_64-disk.img /cirros.img
ADD     https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
COPY    bin/ /usr/local/bin/
RUN     apt update && apt -y install gnupg curl && \
        curl http://osbpo.debian.net/osbpo/dists/pubkey.gpg | \
            apt-key add - && \
        curl https://download.ceph.com/keys/release.gpg | \
            apt-key add -
COPY    openstack.list ceph.list /etc/apt/sources.list.d/
SHELL   ["/bin/bash", "-c"]
RUN     apt update && chmod 0644 /cirros.img && \
        DEBIAN_FRONTEND=noninteractive \
            apt -y install git less watch vim openssh-client \
                mariadb-client dnsutils iputils-ping bash-completion \
                ceph-common s3cmd qemu-utils grepcidr \
                python3-openstackclient \
                python3-cinderclient \
                python3-glanceclient \
                python3-keystoneclient \
                python3-neutronclient \
                python3-novaclient \
                python3-osc-placement \
                python3-secretstorage && \
        chmod +x /tini /usr/local/bin/kubectl && \
        kubectl completion bash | \
            tee /etc/bash_completion.d/kubectl >/dev/null && \
        /usr/local/bin/krew-linux_amd64 install krew && \
        cat /usr/local/bin/bashrc.txt >> ~/.bashrc && \
        . ~/.bashrc && \
        kubectl krew install ctx ns neat tail

ENTRYPOINT  ["/tini", "--", "/usr/local/bin/btx"]
CMD         ["--run"]
