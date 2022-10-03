#!/bin/bash 
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -x

export RTEMS_VERSION=5

if [ $# -lt 3 ]; then
echo "usage: $0 <RSB commit hash> <rtems-deployment commit hash> <legacy|libbsd> [<RTEMS install dir>]"
echo "too less arguments, exiting.."
exit 1
elif [ $# -eq 3 ]; then
    echo "no RTEMS installation path on the command line, using default"
    export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems
else
    export RTEMS_BASE=$1
fi
export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_VERSION}

rm -rf rtems-source-builder rtems-deployment

git clone git://git.rtems.org/rtems-source-builder.git
cd rtems-source-builder/
git checkout $1
cd ../
git clone https://git.rtems.org/chrisj/rtems-deployment.git
cd rtems-deployment
git checkout $2
sed -i "s#^%define\ name\ .*#%define name rtems#" pkg/rpm.spec.in
mkdir -p out/buildroot/BUILD
mkdir -p out/buildroot/RPMS/x86_64
./waf configure --prefix=${RTEMS_ROOT} --rsb=../rtems-source-builder --build=gemini
./waf rpmspec

cd ../
cp rtems-deployment/out/gemini/gemini-powerpc-$3-bsps.spec rtems.spec

#./rtems-5-bsp-flags-clean ${RTEMS_ROOT}
