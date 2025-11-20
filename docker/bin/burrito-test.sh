#!/bin/bash

set -e -o pipefail

SELFSERVICE_NAME="private"
PROVIDER_NAME="public"

NET_TYPES=('flat' 'vlan')
NET_TYPE=
VLANID=

function provider_settings() {
  PS3='Choose the openstack provider network type: '
  select opt in "${NET_TYPES[@]}"; do
    case $opt in
      "flat")
        echo "You have selected: \"${opt}\"".
        NET_TYPE='flat'
        break
        ;;
      "vlan")
        echo "You have selected: \"${opt}\"".
        NET_TYPE='vlan'
        while true; do
          read -p 'Type the provider network vlan id (e.g. 56): ' VLANID
          if grep -P -q "^\d+$" <<<"$VLANID"; then
            echo "Okay. I got the provider network vlan id: $VLANID"
            break
          fi
          echo "You should type the vlan id number. Type again."
        done
        break
        ;;
      *) echo "invalid type: $REPLY";;
    esac
  done
  while true; do
    read -p 'Type the provider network address (e.g. 192.168.22.0/24): ' PN
    if grep -P -q  "^\d+\.\d+\.\d+.\d+\/\d+" <<<"$PN"; then
      echo "Okay. I got the provider network address: $PN"
      break
    fi
    echo "You typed the wrong subnet address format. Type again."
  done
  while true; do
    read -p 'The first IP address to allocate (e.g. 192.168.22.100): ' FIP
    if (echo $FIP|grepcidr $PN) &>/dev/null; then
      echo "Okay. I got the first address in the pool: $FIP"
      break;
    fi
    echo "The first IP should be in the network range. Type again."
  done
  while true; do
    read -p 'The last IP address to allocate (e.g. 192.168.22.200): ' LIP
    if (echo $LIP|grepcidr $PN) &>/dev/null; then
      OLDIFS=$IFS
      IFS='.'
      l=($LIP)
      f=($FIP)
      IFS=$OLDIFS
      FDEC=$((${f[3]}+(${f[2]}*256)+(${f[1]}*256*256)+(${f[0]}*256*256*256)))
      LDEC=$((${l[3]}+(${l[2]}*256)+(${l[1]}*256*256)+(${l[0]}*256*256*256)))
      if [[ ${LDEC} -gt ${FDEC} ]]; then
          echo "Okay. I got the last address in the pool: $LIP"
          break;
      else
        echo "The last IP should be greater than the first IP."
      fi
    else
      echo "The last IP should be in the network range. Type again."
    fi
  done
}

function selfservice() {
  echo -n "Creating a selfservice network..."
  if ! openstack network show ${SELFSERVICE_NAME}-net >/dev/null 2>&1; then
    echo
    openstack network create ${SELFSERVICE_NAME}-net
  fi
  if ! openstack subnet show ${SELFSERVICE_NAME}-subnet >/dev/null 2>&1; then
    echo
    openstack subnet create \
        --network ${SELFSERVICE_NAME}-net \
        --subnet-range 172.30.1.0/24 \
        --dns-nameserver 8.8.8.8 \
        ${SELFSERVICE_NAME}-subnet
  fi
  echo "Done"
}

function router() {
  echo -n "Creating a router..."
  if ! openstack router show admin-router >/dev/null 2>&1; then
    echo
    openstack router create admin-router
    openstack router add subnet admin-router ${SELFSERVICE_NAME}-subnet
    openstack router set --external-gateway ${PROVIDER_NAME}-net admin-router
    openstack router show admin-router
  fi
  echo "Done"
}

function provider() {
  echo -n "Creating a provider network..."
  if ! openstack network show ${PROVIDER_NAME}-net >/dev/null 2>&1; then
    echo
    provider_settings
    SEGMENT_PARAMS=
    if [ ! -z "${VLANID}" ]; then
      SEGMENT_PARAMS="--provider-segment ${VLANID}"
    fi
    openstack network create \
        --external \
        --share \
        --provider-network-type ${NET_TYPE} \
        --provider-physical-network external ${SEGMENT_PARAMS} \
        ${PROVIDER_NAME}-net
  fi
  if ! openstack subnet show ${PROVIDER_NAME}-subnet >/dev/null 2>&1; then
    echo
    openstack subnet create --network ${PROVIDER_NAME}-net \
        --subnet-range ${PN} \
        --allocation-pool start=${FIP},end=${LIP} \
        --dns-nameserver 8.8.8.8 ${PROVIDER_NAME}-subnet
  fi
  echo "Done"
}

function image() {
  echo -n "Creating an image..."
  IMG="/cirros.img"
  if [ ! -f "$IMG" ]; then
    echo "Abort: cirros image(/cirros.img) not found."
    exit 1
  fi
  if ! openstack image show cirros >/dev/null 2>&1; then
    echo
    openstack image create \
        --disk-format qcow2 \
        --container-format bare \
        --file $IMG \
        --tag $CIRROS_VERSION \
        --public \
        cirros
    openstack image show cirros
  fi
  echo "Done"
}

function secgroup() {
  echo -n "Adding security group rules..."
  set +e +o pipefail
  ADMIN_PROJECT=$(openstack project show -c id -f value admin)
  ADMIN_SEC=$(openstack security group list --project $ADMIN_PROJECT -c ID -f value)
  if ! (openstack security group rule list $ADMIN_SEC | grep -q tcp); then
    echo
    openstack security group rule create --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 1:65535 --ingress  $ADMIN_SEC
  fi
  if (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*ingress'); then
    echo
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 $ADMIN_SEC
  fi
  if ! (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*egress'); then
    echo
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 --egress $ADMIN_SEC
  fi
  echo "Done"
  set -e -o pipefail
}

function flavor() {
  echo -n "Creating a flavor..."
  if ! openstack flavor show m1.tiny >/dev/null 2>&1; then
    echo
    openstack flavor create --vcpus 1 --ram 1024 --disk 10 m1.tiny
  fi
  echo "Done"
  if openstack server show test >/dev/null 2>&1; then
    echo -n "Removing an existing instance..."
    openstack server delete test
    echo "Done"
  fi
}

function instance() {
  # get the first argument
  NET=$1
  if [ -z "${NET}" ]; then
    echo "Abort: Network is not specified for the instance."
    echo 
    exit 1
  fi
  IMAGE=$(openstack image show cirros -f value -c id)
  FLAVOR=$(openstack flavor show m1.tiny -f value -c id)
  NETWORK=$(openstack network show ${NET}-net -f value -c id)
  
  echo -n "Creating an instance..."
  openstack server create \
      --image $IMAGE \
      --flavor $FLAVOR \
      --nic net-id=$NETWORK --wait \
      test >/dev/null
  echo "Done"
}

function fip() {
  echo -n "Adding a floating ip to the instance..."
  FLOATING_IP=$(openstack floating ip create -c floating_ip_address -f value public-net)
  openstack server add floating ip test $FLOATING_IP
  echo "Done"
}

function volume() {
  SLEEP=6
  LOOP=20
  if openstack volume show test_vol >/dev/null 2>&1; then
    echo -n "Removing an existing volume..."
    openstack volume delete test_vol
    echo "Done"
  fi
  echo -n "Creating a volume..."
  openstack volume create --size 5 --image $IMAGE test_vol >/dev/null
  echo "Done"
  i=0
  VOLUME_STATUS=""
  set +e +o pipefail
  until [ x"${VOLUME_STATUS}" = x"available" ]
  do
    echo "Waiting for the volume availability..."
    sleep $SLEEP
    VOLUME_STATUS=$(openstack volume show test_vol -f value -c status)
    if [ "$i" = "$LOOP" ]; then
      echo "Abort: Volume is not available so I give up."
      exit 1
    fi
    ((i++))
  done
  set -e -o pipefail
  echo "Attaching the volume to the instance..."
  openstack server add volume test test_vol
  echo "Done"
}

function end() {
  echo "Instance status"
  openstack server show test -c name -c addresses -c flavor \
      -c status -c image -c volumes_attached
}

function instance_with_selfservice() {
  selfservice
  provider
  router
  image
  secgroup
  flavor
  instance ${SELFSERVICE_NAME}
  fip
  volume
}
function instance_with_provider() {
  provider
  image
  secgroup
  flavor
  instance ${PROVIDER_NAME}
  volume
}
function USAGE() {
  echo "USAGE: $0 [-h|-s|-p]" 1>&2
  echo
  echo " -h --help        Display this help message."
  echo " -p --provider    Create a VM with provider network."
  echo " -s --selfservice Create a VM with selfservice network and floating ip."
  echo
}
if [ $# -lt 1 ]; then
  USAGE
  exit 1
fi

OPT=$1
shift
while true
do
  case "$OPT" in
    -h | --help)
      USAGE
      break
      ;;
    -p | --provider)
      instance_with_provider
      end
      break
      ;;
    -s | --selfservice)
      instance_with_selfservice
      end
      break
      ;;
    *)
      echo "Error: unknown option: $OPT" 1>&2
      echo
      USAGE
      break
      ;;
  esac
done
