BTX (Burrito Toolbox)
========================

BTX is a Toolbox image for Burrito platform.

Build (Optional)
-------------------

Copy .env.sample to .env and edit it.::

   $ cp .env.sample .env
   $ vi .env
   TINI_VERSION="v0.19.0"
   CIRROS_VERSION="0.5.1"
   OPENSTACK_RELEASE="yoga"
   CEPH_RELEASE="quincy"
   K8S_VERSION="v1.24.8"
   HELM_VERSION="v3.11.1"
   KREW_VERSION="v0.4.3"

Build the image.::

   $ ./build.sh

