%define name rtems
%define arch noarch
%define repository gemdev
%define checkout %(git log --pretty=format:'%h' -n 1) 

%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-ldconfig %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

Name: %{name}
Version: 5.0
Release: 5%{?dist}
Summary: RTEMS installation for development on ppc.
License: Fixme
Source: %{name}-%{version}.tar.gz
#BuildRequires: yum-utils autoconf automake binutils gcc gcc-c++ gdb make patch bison flex xz unzip ncurses-devel texinfo zlib-devel git 
#BuildRequires: glibc-devel libtool pkgconf pkgconf-m4 pkgconf-pkg-config redhat-rpm-config rpm-build asciidoc byacc ctags
#BuildRequires: python3 python3-pip python3-setuptools python3-devel texinfo spax

%description
This is the %{name} RPM.

#%setup -q

%build
#alternatives --set python /usr/bin/python3
#./rtems-setup.sh

%install
mkdir -p %{buildroot}/gem_base/targetOS/RTEMS/rtems/%{checkout}
#cd %{_builddir}/%{?buildsubdir}
#echo user $USER
#ls -lisah %{buildroot}/gem_base/targetOS/RTEMS/rtems
#sh ./rtems-setup.sh %{buildroot}/gem_base/targetOS/RTEMS/rtems
cp -r /gem_base/targetOS/RTEMS/rtems/%{checkout} %{buildroot}/gem_base/targetOS/RTEMS/rtems/
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
%dir /gem_base/targetOS/RTEMS/rtems/%{checkout}
/gem_base/targetOS/RTEMS/rtems/%{checkout}/*


%changelog
