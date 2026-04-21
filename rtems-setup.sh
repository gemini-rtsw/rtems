#!/bin/bash
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -o pipefail
set -x

## please edit to your needs
# RTEMS version
export RTEMS_VERSION=6

## There can be either a RTEMS_RELEASE or RTEMS_SOURCE_BUILDER_REVISION 
## (i.e. specific git commit hash).
## RTEMS_RELEASE has precedence, meaning if set, this will be built.
## For a non-rc release, use the release tarballs instead of git hashes.
export RTEMS_RELEASE=6.2

## RSB commit hash. Used only when RTEMS_RELEASE is unset, e.g. via -G.
## comment out RTEMS_RELEASE if you want to build from git revision and
## specify the revision you want to be checked out
export RTEMS_SOURCE_BUILDER_REVISION=3814cb0e7f86cca2be403eac831f9bf571984659

export RTEMS_RELEASE_URL=https://ftp.rtems.org/pub/rtems/releases

# RTEMS-deployment revision (i.e. git hash). Used only when RTEMS_RELEASE is unset.
export RTEMS_DEPLOYMENT_REVISION=612fc665fa49c49a37b00dd84664261da74f6fc5
## either legacy or libbsd
export RTEMS_LEGACY_OR_LIBBSD="legacy"

export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems

# The RPM spec rebuilds the packaged RTEMS set itself. Keep the standalone
# toolchain prebuild opt-in so CI does not pay for the same work twice.
export RTEMS_PREBUILD_TOOLCHAIN=${RTEMS_PREBUILD_TOOLCHAIN:-0}

# options
while getopts 'GV:R:u:b:' OPTION
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

if [[ "$RTEMS_RELEASE" == *"rc"* ]]; then
	curl -fsSL ${RTEMS_RELEASE_URL}/${RTEMS_VERSION}/rc/${RTEMS_RELEASE}/sources/rtems-source-builder-${RTEMS_RELEASE}.tar.xz | tar xJf -
	mv rtems-source-builder-${RTEMS_RELEASE} rtems-source-builder
elif [ "$RTEMS_RELEASE" != "" ]; then
	curl -fsSL ${RTEMS_RELEASE_URL}/${RTEMS_VERSION}/${RTEMS_RELEASE}/sources/rtems-source-builder-${RTEMS_RELEASE}.tar.xz | tar xJf -
	mv rtems-source-builder-${RTEMS_RELEASE} rtems-source-builder
else
	git clone https://gitlab.rtems.org/rtems/tools/rtems-source-builder.git
	cd rtems-source-builder
	git checkout ${RTEMS_SOURCE_BUILDER_REVISION}
    
    # temporary patch to increase FD_SETSIZE to 256, will be upstream soon
    # FIXME: please check if still neccessary
    #git apply ../0001-rtems-newlib-Increase-FD_SETSIZE-to-256.patch

	cd ../
fi

if [[ "$RTEMS_RELEASE" == *"rc"* ]]; then
	curl -fsSL ${RTEMS_RELEASE_URL}/${RTEMS_VERSION}/rc/${RTEMS_RELEASE}/sources/rtems-deployment-${RTEMS_RELEASE}.tar.xz | tar xJf -
	mv rtems-deployment-${RTEMS_RELEASE} rtems-deployment
elif [ "$RTEMS_RELEASE" != "" ]; then
	curl -fsSL ${RTEMS_RELEASE_URL}/${RTEMS_VERSION}/${RTEMS_RELEASE}/sources/rtems-deployment-${RTEMS_RELEASE}.tar.xz | tar xJf -
	mv rtems-deployment-${RTEMS_RELEASE} rtems-deployment
else
	git clone https://gitlab.rtems.org/rtems/tools/rtems-deployment.git
	cd rtems-deployment
	git checkout ${RTEMS_DEPLOYMENT_REVISION}
	cd ../
fi

cd rtems-deployment
#sed -i -e "s#^%define\ name\ .*#%define name rtems#" \
#       -e "s#^Release:\ .*#Release: ${checkout}.%{rsb_revision}%{?dist}#" pkg/rpm.spec.in
mkdir -p out/buildroot/BUILD
mkdir -p out/buildroot/RPMS/x86_64

## Enable for local toolchain-only prep; the RPM build path runs RSB itself.
if [ "${RTEMS_PREBUILD_TOOLCHAIN}" = "1" ]; then
	../rtems-source-builder/source-builder/sb-set-builder --url=https://ftp.rtems.org/pub/rtems/cache/rsb/main ${RTEMS_VERSION}/rtems-powerpc
fi
./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder --rpm-config=../gemini-config.ini --rpm-config-value=gemini_version=${checkout}

## .. and use this one for EPICS core devs
#./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder/source-builder
#./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder/source-builder --build=gemini

./waf rpmspec

#rpmbuild -bb out/gemini/gemini-powerpc-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec

## commenting out in favor of providing a container for epics core devs
rpmbuild -bb out/gemini/gemini-powerpc-net-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec

## provide support for initial set of EPICS base BSPs for EPICS core devs
#rpmbuild -bb out/epics/net-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
#rpmbuild -bb out/epics/net-legacy-bsps.spec
