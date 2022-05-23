# Build with meta-ewaol support

## Introduction
The Edge Workload Abstraction and Orchestration Layer (EWAOL) project provides
users with a standards based framework using containers.

The project provides a collection of meta-layers called
[meta-ewaol](https://gitlab.arm.com/ewaol/meta-ewaol/).

Documentation for the EWAOL can be found
[here](https://ewaol.sites.arm.com/meta-ewaol/).

This readme file includes instructions on how to build the Renesas RZ/G2 BSP with
support for meta-ewaol.

## Assumptions
It is assumed that the user is familiar with building Yocto/OpenEmbedded based
BSPs and that they have a suitable build environment configured.

The build instructions in this document have been tested with Ubuntu v20.04 for
the Renesas RZ/G2L smarc-rzg2l platform.

## Dependencies
URI: git://git.yoctoproject.org/poky \
layers: meta, meta-poky, meta-yocto-bsp \
branch: hardknott \
revision: 269265c00091fa65f93de6cad32bf24f1e7f72a3

URI: git://git.openembedded.org/meta-openembedded \
layers: meta-oe, meta-python, meta-multimedia, meta-filesystems,
meta-networking, meta-perl \
branch: hardknott \
revision: f44e1a2b575826e88b8cb2725e54a7c5d29cf94a

URI: git://git.yoctoproject.org/meta-virtualization \
layers: meta-virtualization \
branch: hardknott \
revision: 7f719ef40896b6c78893add8485fda995b00d51d

URI: git://git.yoctoproject.org/meta-security \
laters: meta-security \
branch: hardknott \
revision: 16c68aae0fdfc20c7ce5cf4da0a9fff8bdd75769

URI: git://git.gitlab.arm.com/ewaol/meta-ewaol \
layers: meta-ewaol-distro, meta-ewaol-tests \
branch: hardknott \
revision: 116cfb967ed6f97db2096c1de4d9f552ea2d8fbd

## Build Instructions
1. Checkout dependencies
```bash
git clone https://git.yoctoproject.org/git/poky
cd poky && git checkout 269265c00091fa65f93de6cad32bf24f1e7f72a3 && cd -

git clone https://github.com/openembedded/meta-openembedded
cd meta-openembedded && git checkout f44e1a2b575826e88b8cb2725e54a7c5d29cf94a
# Cherry-pick fix for bats QA issue
git cherry-pick e2a4d4add495f29fe6c5629c34472e2d76497b5a && cd -

git clone https://git.yoctoproject.org/meta-security
cd meta-security && git checkout 16c68aae0fdfc20c7ce5cf4da0a9fff8bdd75769 && cd -

git clone https://git.yoctoproject.org/meta-virtualization
cd meta-virtualization && git checkout 7f719ef40896b6c78893add8485fda995b00d51d && cd -

git clone https://git.gitlab.arm.com/ewaol/meta-ewaol.git
cd meta-ewaol && git checkout 116cfb967ed6f97db2096c1de4d9f552ea2d8fbd && cd -
```

2. Configure build environment
The example configuration provided for the smarc-rzg2l platform includes both
meta-ewaol-distro and meta-ewaol-tests. If a different configuration is required
then please update *bblayers.conf* and *local.conf* accordingly.

```bash
source poky/oe-init-build-env
cp ../meta-renesas/docs/template/conf/smarc-rzg2l/ewaol/*.conf conf/
```

3. Start build
```bash
# Docker target
bitbake ewaol-image-docker

# Podman target
bitbake ewaol-image-podman
```

4. Build output
Once the build is completed the bootloader, kernel and filesystem binaries
are available in the *build/tmp/deploy/images/* directory.

## Image Validation
EWAOL includes it's own suite of test suites included as part of
*meta-ewaol-tests*.

Full documentation is provided
[here](https://ewaol.sites.arm.com/meta-ewaol/validations.html).

There are cureently two validation test suites,
*container-engine-integration-tests* and *k3s-integration-tests*. These can be
run on both *ewaol-image-docker* and *ewaol-image-podman* images.

### container-engine-integration-tests
This test suite needs internet access so that it can download the required
containers. On the smarc-rzg2l platform this can be done using *eth1*, assuming
that *eth0* is being used for NFS.

First, configure DNS:
```bash
mv /etc/resolv.conf resolv.conf.bak
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
```

Bring up network and get IP:
```bash
ifconfig eth1 up
udhcpc -i eth1
```

Enable NTP to avoid certificate issues caused by incorrect time setting:
```bash
echo "server 0.europe.pool.ntp.org" >> /etc/ntp.conf
echo "server 1.europe.pool.ntp.org" >> /etc/ntp.conf
echo "server 2.europe.pool.ntp.org" >> /etc/ntp.conf
echo "server 3.europe.pool.ntp.org" >> /etc/ntp.conf
systemctl enable ntpd
systemctl restart ntpd
```

Run the validation tests:
```bash
ptest-runner container-engine-integration-tests
```

