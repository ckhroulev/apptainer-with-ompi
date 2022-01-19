#!/bin/bash

# Install Open MPI in ${prefix}, using ${build_dir} as the build
# directory.
#
# Run as
#
# prefix=/path/to/use openmpi.sh
#
# to install in a different location.

set -e
set -u

prefix=${prefix:-/opt/ompi}
build_dir=${build_dir:-/tmp/build/ompi}
version=${version:-4.0.5}
version_major=$(echo ${version} | grep -oE "^[[:digit:]]\.[[:digit:]]")

mkdir -p ${build_dir}

cd ${build_dir}

set -x

wget -nc https://download.open-mpi.org/release/open-mpi/v${version_major}/openmpi-${version}.tar.gz

tar xzf openmpi-${version}.tar.gz
cd openmpi-${version}

./configure --prefix=${prefix}

make -j 8
make install
