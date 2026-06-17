# rtems.spec -- Gemini RTEMS 6 PowerPC cross-toolchain + BSPs
#
# This is a thin wrapper spec for the gemini-rtsw-ci pipeline. The real build
# logic lives in rtems-setup.sh (which drives the RTEMS Source Builder and the
# rtems-deployment waf project). Historically the spec was generated on the fly
# by `./waf rpmspec`; that generated spec embedded absolute /tmp build paths and
# could not be committed verbatim. Instead we commit this static spec and let
# %build delegate to rtems-setup.sh so there is a single source of truth that
# still tracks the upstream RSB/deployment templates.
#
# Produces a package named "rtems" installing the toolchain under
#   /gem_base/targetOS/RTEMS/rtems/<RTEMS_VERSION>
# which is what epics-base-7 (BuildRequires/Requires: rtems) consumes.

%global _enable_debug_package 0
%global debug_package %{nil}
# RSB builds its own binaries; skip the usual post-install processing that
# assumes native ELF and would otherwise fail on the cross-compiled tree.
%global __os_install_post %{nil}
%global _missing_build_ids_terminate_build 0
# The package is noarch by convention (it is a self-contained tree under
# /gem_base) but contains x86_64 host binaries (the cross-gcc etc.); disable
# the arch-dependent-binaries-in-noarch check that would otherwise fail.
%global _binaries_in_noarch_packages_terminate_build 0

%define name    rtems
# Keep in sync with RTEMS_RELEASE in rtems-setup.sh.
# version is kept as a literal define (not derived) so that the CI build script,
# which greps for the version define, derives the matching source tarball name
# rtems-6.2 and the autosetup step below unpacks it cleanly.
%define version 6.2
%define rtems_major   6
%define rsb_prefix    /gem_base/targetOS/RTEMS/rtems/%{rtems_major}
# Short git hash of the repo commit this RPM was built from, embedded in
# Release. build_rpm.sh exports GIT_HASH into the build container; fall back
# to asking git directly (rpmbuild runs from the repo root) or "nogit".
%define git_hash %(if [ -n "$GIT_HASH" ]; then echo "$GIT_HASH"; else git rev-parse --short HEAD 2>/dev/null || echo nogit; fi)

Name:           %{name}
Version:        %{version}
Release:        0.%{git_hash}%{?dist}
Summary:        RTEMS %{rtems_major} PowerPC cross-toolchain and board support packages
License:        GPLv2 and GPLv3 and BSD-2-Clause
URL:            https://www.rtems.org/
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

# Tools needed by the RTEMS Source Builder and rtems-deployment's waf build.
# bison/flex/texinfo/m4 are enforced by RSB's host environment check; the
# remaining entries cover sources unpack, configure, and rpm-build itself.
BuildRequires:  bash git python3 python3-devel curl tar xz findutils diffutils which
BuildRequires:  gcc gcc-c++ make patch bzip2 gzip unzip
BuildRequires:  bison flex texinfo m4 autoconf automake libtool pkgconfig gettext
BuildRequires:  rpm-build

%description
RTEMS %{rtems_major} (release %{version}) PowerPC cross development tools
and the Gemini "net-legacy" board support packages, installed under
%{rsb_prefix}. Built from the RTEMS Source Builder via rtems-setup.sh.

# The whole RTEMS package IS the cross-development toolchain (headers, libs,
# cross-gcc) -- there is no separate runtime vs devel split. The -devel
# subpackage exists so downstream specs and the dev container can depend on
# "rtems-devel" uniformly; it just pulls in the full package.
%package devel
Summary:        RTEMS %{rtems_major} PowerPC cross-development toolchain (meta)
Requires:       %{name} = %{version}-%{release}
%description devel
Development metapackage for RTEMS %{rtems_major}. Installs the full RTEMS
cross-toolchain (%{name}); provided so consumers can BuildRequire/Require
rtems-devel like other modules.

%prep
%autosetup -n %{name}-%{version}

%build
# Provide a `python` alias; rtems-deployment's waf invokes `python`.
if ! command -v python >/dev/null 2>&1; then
    mkdir -p %{_builddir}/.bin
    ln -sf "$(command -v python3)" %{_builddir}/.bin/python
    export PATH="%{_builddir}/.bin:$PATH"
fi

# Build the toolchain only (RSB + waf); do NOT let rtems-setup.sh run its own
# rpmbuild -- that is this spec's job. RTEMS_RPM_WRAPPER tells the script to
# stop after the RSB bset tarball is produced; the install stage unpacks it.
# (It must not be unpacked here: rpmbuild wipes the buildroot right before
# the install stage runs, deleting anything staged during the build stage.
# NB: spell section names like "install" without the percent sign in spec
# comments -- rpm expands macros in comments and a literal percent-install
# token here would be parsed as a duplicate section.)
export RTEMS_RPM_WRAPPER=1
export RTEMS_RSB_PREFIX="%{rsb_prefix}"
chmod +x ./rtems-setup.sh
./rtems-setup.sh

%install
# Unpack the RSB deployment tarball produced during the build stage. Its
# contents are rooted at the rsb_prefix path already, so untar straight
# into the buildroot.
tar jxf rtems-deployment/tar/gemini-powerpc-net-legacy-bsps.tar.bz2 -C "%{buildroot}"
test -d "%{buildroot}%{rsb_prefix}"

%files
%defattr(-,root,root,-)
%dir %{rsb_prefix}
%{rsb_prefix}/*

%files devel
# No files of its own; it depends on the main package (the full toolchain).

%changelog
* Fri Jun 05 2026 Gemini RTSW <rtsw@noirlab.edu> - 6.2-0
- Initial committed wrapper spec for the gemini-rtsw-ci GitHub pipeline.
- Delegates the RSB/waf toolchain build to rtems-setup.sh.
