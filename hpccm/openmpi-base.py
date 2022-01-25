# We use CentOS 7 because we need glibc compatible with the Linux
# kernel 2.6.32 in CentOS 6.10.
#
# Note: I should update this after the OS upgrade on Chinook.
Stage0 += baseimage(image='centos:centos7', _as="devel")

# Use an old-ish version of the Mellanox OFED to support ConnectX-3.
#
# See https://www.mellanox.com/support/mlnx-ofed-matrix?mtag=linux_sw_drivers
# for hardware-software version compatibility info.
#
# Alternatively (to use packages from the OS specified in "baseimage" above):
# Stage0 += ofed()
Stage0 += mlnx_ofed(version='4.7-3.2.9.0')

compiler = gnu()
Stage0 += compiler

use_ucx = USERARG.get('ucx', None) is not None

if use_ucx:
    # UCX depends on KNEM (use latest versions as of 2022-01-22)
    Stage0 += knem(version='1.1.4')
    Stage0 += ucx(cuda=False, version='1.12.0')

# Build Open MPI 4.1.2.
Stage0 += openmpi(cuda=False,
                  infiniband=not use_ucx,
                  ucx=use_ucx,
                  toolchain=compiler.toolchain,
                  version='4.1.2')

if not use_ucx:
    Stage0 += shell(commands=[
        'echo "btl_openib_allow_ib = 1" >> /usr/local/openmpi/etc/openmpi-mca-params.conf'])

# Build "MPI Hello World" that can be used to test this image:
Stage0 += copy(src='src/mpi_hello.c', dest='/opt/mpi_hello.c')
Stage0 += shell(commands=[
    'mpicc -o /opt/mpi_hello /opt/mpi_hello.c'])

# Build the MPI-1 part of Intel's MPI Benchmarks:
Stage0 += shell(commands=[
    'mkdir -p /var/tmp'
    'cd /var/tmp/',
    'wget https://github.com/intel/mpi-benchmarks/archive/refs/tags/IMB-v2021.3.tar.gz',
    'tar xzf IMB-v2021.3.tar.gz',
    'cd mpi-benchmarks-IMB-v2021.3/',
    'CC=mpicc CXX=mpicxx make IMB-MPI1',
    'cp IMB-MPI1 /opt/',
    'cd /var/tmp',
    'rm -rf mpi-benchmarks-IMB-v2021.3 IMB-v2021.3.tar.gz'])

# Reduce the image size by starting from a blank base image:
Stage1 += baseimage(image='centos:centos7')
Stage1 += Stage0.runtime()
Stage1 += copy(_from="devel",
               src=['/opt/mpi_hello', '/opt/IMB-MPI1'],
               dest='/usr/local/bin/')
