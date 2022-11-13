BTX (Burrito Toolbox)
========================

This is a Toolbox for Burrito platform.

Build (Optional)
-------------------

There is a BTX image(jijisa/btx) in docker hub but if you want to build
it, read docker/README.rst.

Run
-----

Edit statefulset.yaml and configmap.yaml to modify 
pvc size and OS_PASSWORD value.::

    $ vi statefulset.yaml
    ...
     volumeClaimTemplates:
     - metadata:
         name: btx-pvc
       spec:
         accessModes: ["ReadWriteOnce"]
         resources:
           requests:
             storage: <put_pvc_size_here ex) 100Gi>
    $ vi configmap.yaml
    ...
      OS_PASSWORD: <put_openstack_admin_password_here>


Apply all manifest files.::

   $ kubectl apply -f /path/to/btx/k8s

Copy the env file.::

   $ cp btx.env ~/.btx.env
   $ source ~/.btx.env

commands
----------

If you want to go into btx shell, run btx.::

   $ bts
   root@a5cc02a304c6:/# 

If you want to connect to OpenStack mariadb, run btx with -d option.::

   $ btx -d
   Enter password: 
   MariaDB [(none)]>

Test
-----

There is a simple OpenStack test script burrito-test.sh.

It creates network, router, vm, volume, etc...

To run a test::

   $ btx --test
   Creating private network...Done
   Creating external network...Done
   Creating router...Done
   Creating image...Done
   ...
   Removing existing test VM...Done
   Creating virtual machine...Done
   Adding external ip to vm...Done
   Removing existing test volume..Done
   Creating volume...Done
   Waiting for test_bfv volume availability...
   Attaching volume to vm...Done
   VM status
   +------------------+------------------------------------------------+
   | Field            | Value                                          |
   +------------------+------------------------------------------------+
   | addresses        | private-net=172.30.1.141, 192.168.22.214       |
   | flavor           | m1.tiny (f86115a7-6f4d-44a5-9bfc-df269086d385) |
   | image            | cirros (990eeda4-c88c-4ab2-8819-66dfc12511cd)  |
   | name             | test                                           |
   | status           | ACTIVE                                         |
   | volumes_attached | id='8c6f79ec-931b-4faf-9368-eee8d5c317b2'      |
   +------------------+------------------------------------------------+

