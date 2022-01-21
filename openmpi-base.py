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

# Build Open MPI 4.1.2 with UCX. Note that we set 'infiniband=True'
# to use the openib BTL.
Stage0 += openmpi(cuda=False,
                  infiniband=True,
                  ucx=False,
                  toolchain=compiler.toolchain,
                  version='4.1.2')

# Build "MPI Hello World" that can be used to test this image:
Stage0 += copy(src='src/mpi_hello.c', dest='/opt/mpi_hello.c')
Stage0 += shell(commands=[
    'mpicc -o /opt/mpi_hello /opt/mpi_hello.c'])

# Reduce the image size by starting from a blank base image:
Stage1 += baseimage(image='centos:centos7')
Stage1 += Stage0.runtime()
Stage1 += copy(_from="devel",
               src='/opt/mpi_hello',
               dest='/usr/local/bin/')
