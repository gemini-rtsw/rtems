#!/bin/bash 
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -x

## please edit to your needs
# RTEMS vesion
export RTEMS_VERSION=5

## There can be either a RTEMS_RELEASE or RTEMS_REVISION (i.e. specific git commit hash)
## RTEMS_RELEASE has precedence, meaning if set, this will be build
export RTEMS_RELEASE=5.2
## commit hashes
## comment out RTEMS_RELEASE if you want to build from git revision and
## specify the revision yhou want to be checked out
#export RTEMS_SOURCE_BUILDER_REVISION=3dc0431

# RTEMS-deploymeny revision (i.e. git hash)
export RTEMS_DEPLOYMENT_REVISION=d7baa5a
## either legacy or libbsd
export RTEMS_LEGACY_OR_LIBBSD="legacy"

export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems

export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_VERSION}

rm -rf rtems-source-builder rtems-deployment

if [ "$RTEMS_RELEASE" != "" ]; then
	curl https://ftp.rtems.org/pub/rtems/releases/${RTEMS_VERSION}/${RTEMS_RELEASE}/sources/rtems-source-builder-${RTEMS_RELEASE}.tar.xz | tar xJf -
	mv rtems-source-builder-${RTEMS_RELEASE} rtems-source-builder
else
	git clone git://git.rtems.org/rtems-source-builder.git
	cd rtems-source-builder/
	git checkout ${RTEMS_SOURCE_BUILDER_REVISION}
	cd ../
fi
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
