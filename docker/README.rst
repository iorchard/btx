BTX (Burrito Toolbox)
========================

BTX is a Toolbox image for Burrito platform.

Build (Optional)
-------------------

Edit .env if you want to change versions.::

   $ cp .env.sample .env
   $ vi .env
   TINI_VERSION="v0.19.0"
   CIRROS_VERSION="0.6.2"
   OPENSTACK_RELEASE="antelope"
   CEPH_RELEASE="18.2.1"
   K8S_VERSION="v1.28.5"
   HELM_VERSION="v3.13.1"
   KREW_VERSION="v0.4.3"
   TRIDENT_VERSION="22.10.0"
   OS_COMPUTE_API_VERSION=2.95
   OS_IDENTITY_API_VERSION=3
   OS_IMAGE_API_VERSION=2
   OS_NETWORK_API_VERSION=2.0
   OS_VOLUME_API_VERSION=3.70


Build the image.::

   $ ./build.sh

