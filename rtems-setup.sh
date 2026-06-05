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

apply_semver_overrides() {
	local spec_file=$1
	local semver_version=${RPM_SEMVER_BASE:-}
	local derive_script=../gem-ci/scripts/derive-semver-rpm-env.sh
	local derived_env

	if [ -z "${semver_version}" ] && [ -n "${RTEMS_RELEASE}" ]; then
		semver_version="${RTEMS_RELEASE%%rc*}"
		semver_version="${semver_version%%-rc*}"
		semver_version="${semver_version}.0"
	fi

	if [ ! -x "${derive_script}" ]; then
		echo "INFO: semver derive script not found; leaving generated spec metadata unchanged"
		return 0
	fi

	derived_env=$(CI_PROJECT_DIR=.. RPM_SEMVER_BASE="${semver_version}" "${derive_script}")
	eval "${derived_env}"

	if [ -n "${RPM_VERSION_OVERRIDE}" ]; then
		sed -i -E "s/^(Version:[[:space:]]*).*/\\1${RPM_VERSION_OVERRIDE}/" "${spec_file}"
	fi

	if [ -n "${RPM_RELEASE_OVERRIDE}" ]; then
		sed -i -E "s/^(Release:[[:space:]]*).*/\\1${RPM_RELEASE_OVERRIDE}%{?dist}/" "${spec_file}"
	fi

	echo "INFO: semver overrides version=${RPM_VERSION_OVERRIDE:-<none>} release=${RPM_RELEASE_OVERRIDE:-<none>}"
}

ensure_python_command() {
	if command -v python >/dev/null 2>&1; then
		return 0
	fi

	if ! command -v python3 >/dev/null 2>&1; then
		echo "ERROR: neither python nor python3 is available in PATH" >&2
		exit 1
	fi

	mkdir -p /usr/local/bin
	ln -sf "$(command -v python3)" /usr/local/bin/python
	hash -r
	echo "INFO: installed python compatibility shim -> $(command -v python3)"
}

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

SPEC_FILE=out/gemini/gemini-powerpc-net-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
apply_semver_overrides "${SPEC_FILE}"
ensure_python_command

#rpmbuild -bb out/gemini/gemini-powerpc-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec

if [ "${RTEMS_RPM_WRAPPER}" = "1" ]; then
	## Wrapper mode: invoked from inside rtems.spec %build. We must NOT run
	## rpmbuild here (that would recurse). Instead reproduce what the generated
	## spec's %build/%install do: run the RSB builder to produce the deployment
	## bset tarball, then untar it into the buildroot the outer rpmbuild owns.
	bset="gemini/gemini-powerpc-net-${RTEMS_LEGACY_OR_LIBBSD}-bsps"
	tarfile="$(pwd)/tar/$(basename "${bset}").tar.bz2"

	../rtems-source-builder/source-builder/sb-set-builder \
		--prefix="${RTEMS_RSB_PREFIX:-${RTEMS_ROOT}}" \
		--bset-tar-file --trace \
		--log="out/gemini/$(basename "${bset}").txt" \
		--no-install "${bset}"

	if [ ! -f "${tarfile}" ]; then
		echo "ERROR: expected RSB tarball not found: ${tarfile}" >&2
		exit 1
	fi

	mkdir -p "${RTEMS_BUILDROOT}"
	tar jxf "${tarfile}" -C "${RTEMS_BUILDROOT}"
	echo "INFO: installed RTEMS deployment tarball into ${RTEMS_BUILDROOT}"
else
	## commenting out in favor of providing a container for epics core devs
	rpmbuild -bb "${SPEC_FILE}"
fi

## provide support for initial set of EPICS base BSPs for EPICS core devs
#rpmbuild -bb out/epics/net-${RTEMS_LEGACY_OR_LIBBSD}-bsps.spec
#rpmbuild -bb out/epics/net-legacy-bsps.spec
