#!/bin/bash
export RTEMS_VERSION=5
export RTEMS_ARCH=powerpc-rtems${RTEMS_VERSION}
export RTEMS_BSP=beatnik
export RTEMS_BASE=/gem_base/targetOS/RTEMS/
export RTEMS_INSTALL_DIR=rtems
export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_INSTALL_DIR}/${RTEMS_VERSION}
export PATH=${RTEMS_ROOT}/bin:${PATH}
export RTEMS_MAKEFILE_PATH=${RTEMS_ROOT}/${RTEMS_ARCH}/${RTEMS_BSP}
export RTEMS_SHARE_PATH=${RTEMS_ROOT}/share/rtems${RTEMS_VERSION}

mkdir -p ${RTEMS_BASE}/${RTEMS_INSTALL_DIR}
cd ${RTEMS_BASE}
#install rsb and rtems powerpc tools
git clone https://github.com/RTEMS/rtems-source-builder.git rsb
cd rsb
git pull --all
git checkout 5
cd rtems
../source-builder/sb-set-builder --prefix=${RTEMS_ROOT} ${RTEMS_VERSION}/rtems-powerpc
cd ../../rtems

# building kernel
mkdir kernel
cd kernel/
git clone git://git.rtems.org/rtems.git rtems
cd rtems
git pull --all
git checkout 5

# build and install bsp
./bootstrap -c && ./rtems-bootstrap
cd ..
mkdir ${RTEMS_BSP}
cd ${RTEMS_BSP}
../rtems/configure --prefix=${RTEMS_ROOT} --target=powerpc-rtems5 --enable-rtemsbsp=${RTEMS_BSP} --enable-posix --enable-c++ --enable-networking --enable-tests
make -j8 all
make install

#cd ../../../bin/
#./mk-mvme2307-img /gem_base/targetOS/RTEMS/MVME2700/rtems/kernel/mvme2307-legacy/powerpc-rtems5/c/mvme2307/testsuites/sptests/spconsole01.exe /gem_base/fkraemer/spconsole01-legacy.img

