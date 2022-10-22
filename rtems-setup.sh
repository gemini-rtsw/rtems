#!/bin/bash 
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -x

## please edit to your needs
# RTEMS vesion
export RTEMS_VERSION=5
# commit hashes
export RTEMS_SOURCE_BUILDER_REVISION=3dc0431
export RTEMS_DEPLOYMENT_REVISION=d7baa5a
# either legacy or libbsd
export RTEMS_LEGACY_OR_LIBBSD="legacy"

export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems

export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_VERSION}

rm -rf rtems-source-builder rtems-deployment

git clone git://git.rtems.org/rtems-source-builder.git
cd rtems-source-builder/
git checkout ${RTEMS_SOURCE_BUILDER_REVISION}
cd ../
git clone https://git.rtems.org/chrisj/rtems-deployment.git
cd rtems-deployment
git checkout ${RTEMS_DEPLOYMENT_REVISION}
#sed -i -e "s#^%define\ name\ .*#%define name rtems#" \
#       -e "s#^Release:\ .*#Release: ${checkout}.%{rsb_revision}%{?dist}#" pkg/rpm.spec.in
mkdir -p out/buildroot/BUILD
mkdir -p out/buildroot/RPMS/x86_64
./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder --rpm-config=../gemini-config.ini --rpm-config-value=gemini_version=${checkout}
#./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder --build=gemini
./waf rpmspec

rpmbuild -bb out/gemini/gemini-powerpc-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
#./rtems-5-bsp-flags-clean ${RTEMS_ROOT}
