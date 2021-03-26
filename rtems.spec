%define name rtems
%define version 5

%define release 1
%define arch noarch
%define repository gemdev
%define checkout %(git log --pretty=format:'%h' -n 1) 

%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-ldconfig %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

Name: %{name}%{version}
Version: %{version}
Release: 0%{?dist}
Summary: RTEMS installation for development on ppc.
License: Fixme
Source: %{name}-%{version}.tar.gz
#BuildRequires: yum-utils autoconf automake binutils gcc gcc-c++ gdb make patch bison flex xz unzip ncurses-devel texinfo zlib-devel git 
#BuildRequires: glibc-devel libtool pkgconf pkgconf-m4 pkgconf-pkg-config redhat-rpm-config rpm-build asciidoc byacc ctags
#BuildRequires: python3 python3-pip python3-setuptools python3-devel texinfo spax

%description
This is the %{name} RPM.

%prep
%setup -q

%build
#alternatives --set python /usr/bin/python3
#./rtems-setup.sh

#mkdir %{_builddir}/tmp
#podman build -t centos8:RTEMS -f Containerfile
#podman run --rm -v %{_builddir}/tmp:/home/user/tmp -w /home/user/tmp  -i -t -d --name rtems_builder centos8:RTEMS
#podman exec rtems_builder rsync -prv /gem_base .

%install
mkdir -p %{buildroot}/gem_base/RTEMS/rtems/
cp -r /gem_base/targetOS/RTEMS/rtems/%{version} %{buildroot}/gem_base/RTEMS/rtems/
#

#
## if you want to do something after installation uncomment the following
## and list the actions to perform:
# %post
## actions, e.g. /sbin/ldconfig

## If you want to have a devel-package to be generated and do some
## %post-stuff regarding it uncomment the following:
# %post devel

## if you want to do something after uninstallation uncomment the following
## and list the actions to perform. But be aware of e.g. deleting directories,
## see the example below how to do it:
# %postun
#if [ "$1" = "0" ]; then
#	rm -rf /gem_base/targetOS/RTEMS/rtems-4.10/
#fi

## If you want to have a devel-package to be generated and do some
## %postun-stuff regarding it uncomment the following:
# %postun devel

## Its similar for %pre, %preun, %pre devel, %preun devel.

%clean
## Usually you won't do much more here than
rm -rf %{buildroot}

#prefix is RTEMS_BASE
%files
%defattr(-,root,root)
%dir /gem_base/targetOS/RTEMS/rtems/%{version}
/gem_base/targetOS/RTEMS/rtems/%{version}/*

%changelog
* Thu Oct 08 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-4
- switched to new version/release scheme 
- switched to new yum repositories

* Thu Oct 08 2020 fkraemer <fkraemer@gemini.edu>
- switched to new version/release scheme 
- switched to new yum repositories

* Thu Oct 08 2020 fkraemer <fkraemer@gemini.edu>
- switched to new version/release scheme 
- switched to new yum repositories

* Wed Aug 05 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200805054114c4c8e
- Release tag enriched with hour and minute (%%H%%M) to be able to build
  several RPMs a day without messing up the repo (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722b2e2ccb
- corrected release tag again (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.498c0cb
- changed release tag (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.202007227b25acd
- changed Release tag in specfile (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.git2c319e4
- added binaries, also (fkraemer@gemini.edu)
- fix cp gem_base (fkraemer@gemini.edu)
- fix test (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.git02dbf3d
- some tests (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.git9c180b0
- added gem_base dir for now (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.git91b595d
- 

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1.20200722.gitcecac5c
- changed release tag (fkraemer@gemini.edu)
- basic rtems rpm packager wich expects a complete rtems installation under
  /gem_base which is rsynced (options -rp) to gem_base in the specfiles
  directory (fkraemer@gemini.edu)
- small adjustments (fkraemer@gemini.edu)
- some adjustments (fkraemer@gemini.edu)
- some small adjustments (fkraemer@gemini.edu)
- build container first (fkraemer@gemini.edu)
- some adjustments to specfile (fkraemer@gemini.edu)
- added podman dependency (fkraemer@gemini.edu)

* Wed Jul 22 2020 fkraemer <fkraemer@gemini.edu>
- basic rtems rpm packager wich expects a complete rtems installation under
  /gem_base which is rsynced (options -rp) to gem_base in the specfiles
  directory (fkraemer@gemini.edu)
- small adjustments (fkraemer@gemini.edu)
- some adjustments (fkraemer@gemini.edu)
- some small adjustments (fkraemer@gemini.edu)
- build container first (fkraemer@gemini.edu)
- some adjustments to specfile (fkraemer@gemini.edu)
- added podman dependency (fkraemer@gemini.edu)

* Tue Jul 21 2020 fkraemer <fkraemer@gemini.edu> 4.10.2-1
- new package built with tito

## Write changes here, e.g.
* Tue Jun 30 2020 Matt Rippa <mrippa@gemini.edu> 4.10.2-1
- initial release
