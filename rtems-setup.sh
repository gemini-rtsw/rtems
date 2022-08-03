#!/bin/bash 

set -e
set -x
export RTEMS_VERSION=5
export RTEMS_ARCH=powerpc-rtems${RTEMS_VERSION}
export RTEMS_BSPS="mvme2307 beatnik mvme3100"
#production 
#export RTEMS_BASE=/gem_base/targetOS/RTEMS/
#testing
export RTEMS_BASE=/gem_base/test/targetOS/RTEMS
export RTEMS_INSTALL_DIR=rtems
export RTEMS_ROOT=${RTEMS_BASE}/${RTEMS_INSTALL_DIR}/${RTEMS_VERSION}
export PATH=${RTEMS_ROOT}/bin:${PATH}
export RTEMS_MAKEFILE_PATH=${RTEMS_ROOT}/${RTEMS_ARCH}/${RTEMS_BSP}
export RTEMS_SHARE_PATH=${RTEMS_ROOT}/share/rtems${RTEMS_VERSION}

echo "installing bison, flex, texinfo, python2-devel, spax"
echo "sudo permissions needed..."
sudo dnf install -y bison flex texinfo python2-devel spax

sudo alternatives --set python /usr/bin/python3

#Need install location
if [ ! -d ${RTEMS_BASE}/${RTEMS_INSTALL_DIR} ]
then
    mkdir -p ${RTEMS_BASE}/${RTEMS_INSTALL_DIR}
else
    echo "Install path exists and Ready!" 
fi

cd ${RTEMS_BASE}

if [ ! -d "rsb" ] 
then
    git clone https://github.com/RTEMS/rtems-source-builder.git rsb
else
    echo "RSB path exists and Ready!" 
fi
cd rsb
git pull --ff-only --all
git checkout 5

cd rtems
../source-builder/sb-set-builder --prefix=${RTEMS_ROOT} 5/rtems-powerpc
cd ../../${RTEMS_INSTALL_DIR}

# building kernel
mkdir kernel
cd kernel
git clone git://git.rtems.org/rtems.git rtems
cd rtems
git pull --all
git checkout 5

# build and install bsp
./bootstrap -c && ./rtems-bootstrap

# For building libbsd we need to use the disable-networking flag
# For building legacy we need to use the enable-networking flag
for bsp in $RTEMS_BSPS; do
    cd ..
    mkdir ${bsp}
    cd ${bsp}
    #../rtems/configure --prefix=${RTEMS_ROOT} --target=powerpc-rtems5 --enable-rtemsbsp=${bsp} --enable-posix --enable-c++ --enable-networking --enable-tests
    ../rtems/configure --prefix=${RTEMS_ROOT} --target=powerpc-rtems5 --enable-rtemsbsp=${bsp}  --enable-posix --enable-c++ --enable-networking --enable-tests
    make -j16 all
    make install
done


