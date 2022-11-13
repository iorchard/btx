#!/bin/bash

set -e -o pipefail

ask_public_net_settings () {
    
    while true; do
        read -p 'Type the provider network address (e.g. 192.168.22.0/24): ' PN
        # check if PN has the right format.
        if grep -P -q  "^\d+\.\d+\.\d+.\d+\/\d" <<<"$PN"; then
            echo "Okay. I got the provider network address: $PN"
            break
        fi
        echo "You typed the wrong subnet address format. Type again."
    done
    
    while true; do
        read -p 'The first IP address to allocate (e.g. 192.168.22.100): ' FIP
        # check if FIP is in PN range.
        FIP2=$(echo $FIP|cut -d'.' -f1,2,3)
        if [[ "$PN" =~ "$FIP2" ]];then
            echo "Okay. I got the first address in the pool: $FIP"
            break;
        fi
        echo "You typed the wrong IP address. Type again."
    done
    
    while true; do
        read -p 'The last IP address to allocate (e.g. 192.168.22.200): ' LIP
        # check if LIP is in PN range.
        LIP2=$(echo $LIP|cut -d'.' -f1,2,3)
        if [[ "$PN" =~ "$LIP2" ]];then
            # check if LIP is bigger than FIP
            OLDIFS=$IFS
            IFS='.'
            l=($LIP)
            f=($FIP)
            IFS=$OLDIFS
            if [[ ${l[3]} -gt ${f[3]} ]]; then
                echo "Okay. I got the last address in the pool: $LIP"
                break;
            fi
        fi
        echo "You typed the wrong IP address. Type again."
    done
}

echo -n "Creating private network..."
if ! openstack network show private-net >/dev/null 2>&1; then
    openstack network create private-net
    openstack subnet create \
        --network private-net \
        --subnet-range 172.30.1.0/24 \
        --dns-nameserver 8.8.8.8 \
        private-subnet
fi
echo "Done"

echo "Creating external network..."
if ! openstack network show public-net >/dev/null 2>&1; then
    ask_public_net_settings
    openstack network create \
        --external \
        --share \
        --provider-network-type flat \
        --provider-physical-network external \
        public-net
    openstack subnet create --network public-net \
        --subnet-range ${PN} \
        --allocation-pool start=${FIP},end=${LIP} \
        --dns-nameserver 8.8.8.8 public-subnet
fi
echo "Done"
echo "Creating router..."
if ! openstack router show admin-router >/dev/null 2>&1; then
    openstack router create admin-router
    openstack router add subnet admin-router private-subnet
    openstack router set --external-gateway public-net admin-router
    openstack router show admin-router
fi
echo "Done"

echo "Creating image..."
IMG="/cirros.img"
if [ ! -f "$IMG" ]; then
    echo "cirros image(/cirros.img) not found. Abort."
    exit 1
fi

if ! openstack image show cirros >/dev/null 2>&1; then
    openstack image create \
        --disk-format qcow2 \
        --container-format bare \
        --file $IMG \
        --tag $(cat /CIRROS_VERSION) \
        --public \
        cirros
    openstack image show cirros
fi
echo "Done"

echo -n "Adding security group rules for VM"
set +e +o pipefail
ADMIN_PROJECT=$(openstack project show -c id -f value admin)
ADMIN_SEC=$(openstack security group list --project $ADMIN_PROJECT -c ID -f value)
if ! (openstack security group rule list $ADMIN_SEC | grep -q tcp); then
    openstack security group rule create --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 1:65535 --ingress  $ADMIN_SEC
fi
if ! (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*ingress'); then
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 $ADMIN_SEC
fi
if ! (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*egress'); then
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 --egress $ADMIN_SEC
fi
echo "Done"

set -e -o pipefail
if openstack server show test >/dev/null 2>&1; then
    echo -n "Removing existing test VM..."
    openstack server delete test
    echo "Done"
fi

if ! openstack flavor show m1.tiny >/dev/null 2>&1; then
    echo -n "Create m1.tiny flavor."
    openstack flavor create --vcpus 1 --ram 1024 --disk 10 m1.tiny
    echo "Done"
fi

IMAGE=$(openstack image show cirros -f value -c id)
FLAVOR=$(openstack flavor show m1.tiny -f value -c id)
NETWORK=$(openstack network show private-net -f value -c id)

echo -n "Creating virtual machine..."
openstack server create \
    --image $IMAGE \
    --flavor $FLAVOR \
    --nic net-id=$NETWORK --wait \
    test >/dev/null
echo "Done"

echo -n "Adding external ip to vm..."
FLOATING_IP=$(openstack floating ip create -c floating_ip_address -f value public-net)
openstack server add floating ip test $FLOATING_IP
echo "Done"


if openstack volume show test_vol >/dev/null 2>&1; then
  echo -n "Removing existing test volume.."
  openstack volume delete test_vol
  echo "Done"
fi

echo -n "Creating test volume..."
openstack volume create --size 5 --image $IMAGE test_vol >/dev/null
echo "Done"
i=0
VOLUME_STATUS=""
set +e +o pipefail
until [ x"${VOLUME_STATUS}" = x"available" ]
do
  echo "Waiting for test volume availability..."
  sleep 1
  VOLUME_STATUS=$(openstack volume show test_vol -f value -c status)
  if [ "$i" = "10" ]; then
    echo "Abort: Volume is not available at least 10 seconds so I give up."
    exit 1
  fi
  ((i++))
done

set -e -o pipefail
echo -n "Attaching volume to vm..."
openstack server add volume test test_vol
echo "Done"

echo "VM status"
openstack server show test -c name -c addresses -c flavor \
    -c status -c image -c volumes_attached
