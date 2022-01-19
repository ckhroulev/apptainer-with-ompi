
# Table of Contents

1.  [Software compatibility](#org734f7b8)
    1.  [Open MPI](#org59f4537)
        1.  [Compatibility between Open MPI and its dependencies](#orgf27bccb)
    2.  [Compatibility between the host kernel and the container OS](#org7b0e951)
2.  [InfiniBand and RDMA support](#org2761db3)
    1.  [Checking if IB devices are available](#org853eb91)
    2.  [Checking inter-node communication using IB](#org98935ef)
3.  [Building Open MPI](#org34ba292)
    1.  [Configuring Open MPI](#orgb9ef682)
        1.  [Finding Open MPI's configuration files](#orga11e81e)
        2.  [Useful MCA parameters](#org594215d)
    2.  [Testing an Open MPI installation](#org519c5b9)
        1.  [Using `mpirun` in the container](#org36d676e)
        2.  [Using `mpirun` on the host](#orga84df4a)
4.  [To do](#orgae23723)

These notes document my attempt to build an [Apptainer](https://apptainer.org/) (or
[SingularityCE](https://sylabs.io/singularity/)) base container that can be used to run MPI-based
software in "hybrid" mode.

Proper MPI support requires attention to two issues:

1.  compatibility between MPI libraries in the container and on a host
2.  supporting network hardware

Apptainer supports both widely used MPI implementations ([Open MPI](https://www.open-mpi.org/) and
[MPICH](https://www.mpich.org/)), but these notes focus on Open MPI.

My hope is that this write up may save you some time; at least it
should make it easier to ask the right questions when talking to HPC
support staff.

Edits (however minor), corrections, improvements, etc are always
welcome.


<a id="org734f7b8"></a>

# Software compatibility


<a id="org59f4537"></a>

## Open MPI

The standard advice is "use the version installed on the host", but
this is not always practical: we may want to support multiple hosts or
the host may not have Open MPI installed.

Moreover, we need to try to do what we can to support reproducible
research and that may require using more current Open MPI versions
than a certain host provides.

The plot below shows which Open MPI version combinations appear to be
compatible. (See [github.com/ckhroulev/apptainer-with-ompi](https://github.com/ckhroulev/apptainer-with-ompi) for the
setup used to produce it.)

![img](compatibility-grid.png "Compatibility between container and host Open MPI versions")

Based on this I would recommend using Open MPI version 4.0.0 or newer
in the container because these versions are compatible with Open MPI
3.0.3 and newer on the host.


<a id="orgf27bccb"></a>

### Compatibility between Open MPI and its dependencies

It is worth pointing out that Open MPI relies on external libraries
for some of its features and we need to use versions of these that are
compatible with the chosen Open MPI version.

In particular, we might have to build some libraries from source
instead of using a package system if our container is based on a
distribution that is significantly older than the chosen Open MPI
version.


<a id="org7b0e951"></a>

## Compatibility between the host kernel and the container OS

If you run a container and it fails with the error message saying
`FATAL: kernel too old`, it is likely that the *host* kernel is not
supported by `glibc` in the container.

The relevant threshold is this: *glibc 2.26 and newer require Linux
3.2.*

For example, given a host that runs CentOS 6.10, [this DistroWatch.com
 page](https://distrowatch.com/table.php?distribution=centos) shows that it uses Linux 2.6.32.

To build a container that would run on this host we need to pick a
Linux distribution version that

-   uses `glibc` older than 2.26,
-   is not past its end-of-life,
-   includes software versions (such as compilers) that are recent enough
    for our purposes.

In this particular case CentOS 7 should work: it uses `glibc` 2.17 and
is supported until June of 2024.


<a id="org2761db3"></a>

# InfiniBand and RDMA support

Supporting InfiniBand in a container is not any different from the
same task on a host. Your HPC support should be able to tell you which
support libraries are needed.

RHEL 7 documentation lists [InfiniBand and RDMA related software
packages](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-infiniband_and_rdma_related_software_packages).

    # Required
    yum -y install rdma-core libibverbs opensm
    
    # Install headers needed to build an MPI stack
    yum -y install \
       opensm-devel \
       rdma-core-devel \
       ;
    
    # Recommended
    #
    # ibutils, perftest, and qperf are recommended as well, but they
    # pull in a long list of dependencies and so I removed them from
    # the list to reduce the size of the image.
    yum -y install \
        ibacm \
        infiniband-diags \
        libibverbs-utils \
        librdmacm \
        librdmacm-utils \
        ;

Note: recommended packages `libibverbs-utils` and `infiniband-diags`
are used to test InfiniBand support below.


<a id="org853eb91"></a>

## Checking if IB devices are available

Running `ibv_devices` from `libibverbs-utils` should produce output
similar to this:

    % singularity exec mpi.sif ibv_devices
        device                 node GUID
        ------              ----------------
        mlx4_0              7cfe900300c40490

Running the same command on a laptop that does not have IB devices
gives this:

    % singularity exec mpi.sif ibv_devices
    Failed to get IB devices list: Unknown error -38

Alternatively, run `ibstat` from `infiniband-diags`:

    % singularity exec mpi.sif ibstat
    CA 'mlx4_0'
            CA type: MT4099
            Number of ports: 1
            Firmware version: 2.42.5000
            Hardware version: 1
            Node GUID: 0x7cfe900300c40490
            System image GUID: 0x7cfe900300c40493
            Port 1:
                    State: Active
                    Physical state: LinkUp
                    Rate: 40
                    Base lid: 49
                    LMC: 0
                    SM lid: 1
                    Capability mask: 0x02514868
                    Port GUID: 0x7cfe900300c40491
                    Link layer: InfiniBand

Without IB devices:

    % singularity exec mpi.sif ibstat
    ibpanic: [2137592] main: stat of IB device 'mthca0' failed: No such file or directory


<a id="org98935ef"></a>

## Checking inter-node communication using IB

Here we use `ibv_rc_pingpong` from `libibverbs-utils`:

Start an interactive job. On a system using [Slurm](https://slurm.schedmd.com/) this would require
something like

    srun -p debug --nodes=1 --exclusive -I --pty /bin/bash

Then, run this on a compute node to start `ibv_rc_pingpong` in its
*server* mode:

    % hostname && singularity exec mpi.sif ibv_rc_pingpong
    n2
      local address:  LID 0x0091, QPN 0x03006b, PSN 0x5a83c9, GID ::
      remote address: LID 0x0031, QPN 0x002962, PSN 0x850520, GID ::
    8192000 bytes in 0.01 seconds = 9496.59 Mbit/sec
    1000 iters in 0.01 seconds = 6.90 usec/iter

Next, use the `hostname` output from above (here: `n2`) to run
`ibv_rc_pingpong` on the login node:

    % singularity exec mpi.sif ibv_rc_pingpong n2
      local address:  LID 0x0031, QPN 0x002962, PSN 0x850520, GID ::
      remote address: LID 0x0091, QPN 0x03006b, PSN 0x5a83c9, GID ::
    8192000 bytes in 0.01 seconds = 9630.57 Mbit/sec
    1000 iters in 0.01 seconds = 6.80 usec/iter


<a id="org34ba292"></a>

# Building Open MPI

To be able to re-use a container we need to build Open MPI with
support for all types of network hardware we intend to support.

Installing support libraries in standard should be enough to get Open
MPI to use them: it will [try to find support for all hardware and
environments by looking for support libraries and header files in
standard locations; skip them if not found](https://www-lb.open-mpi.org/faq/?category=building#default-build).

The standard sequence

    configure --prefix=${prefix} && make && make install

is likely to be sufficient, however one could use flags such as
`--with-verbs` to force `configure` to stop if a required dependency
was not found. See [How do I build Open MPI with support for {my
favorite network type}?](https://www-lb.open-mpi.org/faq/?category=building#build-p2p) for more details.

Run

    ompi_info --parsable | grep :openib

*after* the build is complete to check if `openib` support was included.


<a id="orgb9ef682"></a>

## Configuring Open MPI

Open MPI uses a [Modular Component Architecture (MCA)](https://www.open-mpi.org/faq/?category=tuning#mca-def), i.e. a set of
framework components and modules. Much of its behavior can be adjusted
using MCA parameters that can be set using command-line options *or*
configuration files.

A comment in such a file says the following

> Note that this file is only applicable where it is visible (in a
> filesystem sense). Specifically, MPI processes each read this file
> during their startup to determine what default values for MCA
> parameters should be used. mpirun does not bundle up the values in
> this file from the node where it was run and send them to all nodes;
> the default value decisions are effectively distributed. Hence, these
> values are only applicable on nodes that "see" this file. If $sysconf
> is a directory on a local disk, it is likely that changes to this file
> will need to be propagated to other nodes. If $sysconf is a directory
> that is shared via a networked filesystem, changes to this file will
> be visible to all nodes that share this $sysconf.

This means that configuration files on the host will not be seen by
Open MPI in a container.

*We may need to modify a container to use settings appropriate on a
given host.*


<a id="orga11e81e"></a>

### Finding Open MPI's configuration files

Here's a way to find the system-wide configuration file:

    % ompi_info --all --parsable | grep mca_base_param_files:value
    mca:mca:base:param:mca_base_param_files:value:/home/username/.openmpi/mca-params.conf,/opt/scyld/openmpi/4.0.5/intel/etc/openmpi-mca-params.conf

Here `/opt/scyld/openmpi/4.0.5/intel/etc/openmpi-mca-params.conf` is a
system-wide configuration file that we may need to examine to find
settings for this host.

The following command will print system-wide MCA settings (assuming
your module system sets `MPI_HOME`):

    cat ${MPI_HOME}/etc/openmpi-mca-params.conf | grep -Ev "^#|^$"


<a id="org594215d"></a>

### Useful MCA parameters

Open MPI 4.x without UCX:

    # disable the TCP byte transport layer
    btl = vader,self,openib
    # Use openib without UCX in Open MPI 4.0 and later:
    btl_openib_allow_ib = 1

Open MPI 4.x with UCX (from <https://docs.hpc.udel.edu/technical/whitepaper/darwin_ucx_openmpi>).

    # Don't use the openib BTL
    btl = ^openib
    # Use UCX as the "pml"
    pml = ucx
    
    # Never use the IPoIB interfaces for TCP communications:
    oob_tcp_if_exclude = ib0
    btl_tcp_if_exclude = ib0

Increasing verbosity for testing:

    mpirun \
      --mca btl_base_verbose 100 \
      --mca mca_base_verbose stdout ...


<a id="org519c5b9"></a>

## Testing an Open MPI installation

It is useful to include a simple "MPI Hello World" program in the base
image. It looks like most compatibility and hardware support issues
crop up during initialization (in the `MPI_Init()` call), so a test
program as simple as that seems to do the job.

The two recommended test steps are

1.  try using `mpirun` *in the container*
2.  try using `mpirun` *on the host*.


<a id="org36d676e"></a>

### Using `mpirun` in the container

    % singularity exec mpi.sif mpirun -n 4 /opt/mpi_hello
    Hello from process 0/4!
    Hello from process 1/4!
    Hello from process 2/4!
    Hello from process 3/4!

We can also increase verbosity to check if Open MPI succeeded at
initializing InfiniBand devices:

    % singularity exec mpi.sif mpirun --mca btl_base_verbose 100 --mca mca_base_verbose stdout -n 1 /opt/mpi_hello | grep openib
    [hostname:pid] mca: base: components_register: found loaded component openib
    [hostname:pid] mca: base: components_register: component openib register function successful
    [hostname:pid] mca: base: components_open: found loaded component openib
    [hostname:pid] mca: base: components_open: component openib open function successful
    [hostname:pid] select: initializing btl component openib
    [hostname:pid] openib BTL: rdmacm CPC unavailable for use on mlx4_0:1; skipped
    [hostname:pid] [rank=0] openib: using port mlx4_0:1
    [hostname:pid] select: init of component openib returned success
    [hostname:pid] mca: base: close: component openib closed
    [hostname:pid] mca: base: close: unloading component openib

with `hostname` and `pid` replaced with the host name and `pid` with
the process ID.


<a id="orga84df4a"></a>

### Using `mpirun` on the host

A successful run looks like this:

    % mpirun -n 4 singularity exec mpi.sif /opt/mpi_hello
    Hello from process 0/4!
    Hello from process 1/4!
    Hello from process 2/4!
    Hello from process 3/4!

When MPI initialization fails you may see

-   `Hello from process 0/1!` repeated 4 times,
-   an error message from Open MPI,
-   no output (process hangs).

To check IB initialization:

    mpirun -n 1 \
           --mca btl_base_verbose 100 \
           --mca mca_base_verbose stdout \
           singularity exec mpi.sif /opt/mpi_hello | grep openib

This command should produce the same output as the one above (`mpirun`
in the container).


<a id="orgae23723"></a>

# To do

-   Supporting hosts that use Slurm (e.g. installing the appropriate
    PMIx version).
-   Using MPICH (probably [MVAPICH](https://mvapich.cse.ohio-state.edu/)).
-   Update to use UCX and `libfabric`

