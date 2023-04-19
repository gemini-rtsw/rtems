#!/bin/bash
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -x

## please edit to your needs
# RTEMS vesion
export RTEMS_VERSION=6

## There can be either a RTEMS_RELEASE or RTEMS_REVISION (i.e. specific git commit hash)
## RTEMS_RELEASE has precedence, meaning if set, this will be build
#export RTEMS_RELEASE=6.0
## commit hashes
## comment out RTEMS_RELEASE if you want to build from git revision and
## specify the revision yhou want to be checked out
export RTEMS_SOURCE_BUILDER_REVISION=ae00c59541f21d8c459a33774efade80085c9b4a

export RTEMS_RELEASE_URL=https://ftp.rtems.org/pub/rtems/releases

# RTEMS-deploymeny revision (i.e. git hash)
export RTEMS_DEPLOYMENT_REVISION=b71866a9485ecfee8a3fc4684b280c20988e4405
## either legacy or libbsd
export RTEMS_LEGACY_OR_LIBBSD="legacy"

export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems

# options
while getopts 'V:R:u:b:' OPTION
do
	case "$OPTION" in
		V)
			RTEMS_VERSION="$OPTARG"
			;;
		R)
			RTEMS_RELEASE="$OPTARG"
			;;
		G)
			unset RTEMS_RELEASE
			;;
		u)
			RTEMS_RELEASE_URL="$OPTARG"
			;;
		b)
			RTEMS_BASE="$OPTARG"
			;;
		?)
			echo "Usage: $(basename $0) [-G] [-V RTEMS version] [-R RTEMS release] [-u RTEMS release URL] [-b RTEMS base]"
			echo " where:"
			echo "  -G : Use the git version branch and not a release"
			exit 1
			;;
	esac
done

export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_VERSION}

rm -rf rtems-source-builder rtems-deployment

if [ "$RTEMS_RELEASE" != "" ]; then
	curl ${RTEMS_RELEASE_URL}/${RTEMS_VERSION}/${RTEMS_RELEASE}/sources/rtems-source-builder-${RTEMS_RELEASE}.tar.xz | tar xJf -
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

#rpmbuild -bb out/gemini/gemini-powerpc-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
rpmbuild -bb out/gemini/gemini-powerpc-net-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
