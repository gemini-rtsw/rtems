#!/bin/bash 
checkout=$(git log --pretty=format:'%h' -n 1)

set -e
set -x

export RTEMS_VERSION=5
export RTEMS_ARCH=powerpc-rtems${RTEMS_VERSION}
export RTEMS_BSPS="mvme2307 beatnik mvme3100"
#production 
#export RTEMS_BASE=/gem_base/targetOS/RTEMS/
#testing
if [ $# -eq 0 ]; then
    echo "no RTEMS installation path on the command line, using default"
    export RTEMS_BASE=/gem_base/targetOS/RTEMS/rtems/${checkout}
else
    export RTEMS_BASE=$1
fi
export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_VERSION}
export PATH=${RTEMS_ROOT}/bin:${PATH}

## Uncomment to install dependencies
#echo "installing bison, flex, texinfo, python2-devel, spax"
#echo "sudo permissions needed..."
#sudo dnf install -y bison flex texinfo python2-devel spax
#
#sudo alternatives --set python /usr/bin/python3

#Need install location
if [ ! -d ${RTEMS_BASE} ]
then
    mkdir -p ${RTEMS_BASE}
else
    echo "Install path exists and Ready!" 
fi

git submodule init
git submodule update

pushd vendor/rtems-source-builder

cd rtems
../source-builder/sb-set-builder --prefix=${RTEMS_ROOT} 5/rtems-powerpc

# building kernel
popd
pushd vendor/rtems

# build and install bsp
./bootstrap -c && ./rtems-bootstrap

# For building libbsd we need to use the disable-networking flag
# For building legacy we need to use the enable-networking flag
for bsp in $RTEMS_BSPS; do
    cd ..
    mkdir ${bsp}
    cd ${bsp}
    ../rtems/configure --prefix=${RTEMS_ROOT} --target=powerpc-rtems5 --enable-rtemsbsp=${bsp}  --enable-posix --enable-c++ --enable-networking --enable-tests
    make -j16 all
    make install
done

# apply Chris Johns' patch to let gcc not us -ffunction-section -fdata-section
popd
./rtems-5-bsp-flags-clean ${RTEMS_ROOT}
