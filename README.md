
# Table of Contents

1.  [Apptainer (Singularity) containers with Open MPI and InfiniBand](#orgfabc331)
2.  [Building a minimal base image "by hand"](#orgc626db8)
    1.  [Installing support libraries](#orgc114d9f)
    2.  [Testing InfiniBand devices](#org11b9854)
        1.  [Checking if IB devices are available](#org598d3f2)
        2.  [Checking inter-node communication using IB](#org50d9375)
    3.  [Installing Open MPI](#orged8fbaa)
    4.  [Checking if IB support in Open MPI is present](#org33e56a7)
    5.  [Configuring Open MPI in the container](#org6bd0f22)
        1.  [Finding Open MPI's configuration files](#org06888ce)
        2.  [Useful MCA parameters](#org9024ddb)
    6.  [The "MPI Hello world" test](#org17300e5)
        1.  [Using `mpirun` in the container](#org20211a2)
        2.  [Using `mpirun` on the host](#org2229b27)
    7.  [Comparing MPI performance (container vs host)](#orgbc1d766)
3.  [Using HPC Container Maker](#org0ea8265)
4.  [Regarding software compatibility](#org615158a)
    1.  [Open MPI in the container vs the host version](#org4fcf172)
        1.  [Compatibility between Open MPI and its dependencies](#org00c109d)
    2.  [Compatibility between the host kernel and the container OS](#org7172b6d)
5.  [Acknowledgments](#org3432c73)

These notes document my attempt to build an [Apptainer](https://apptainer.org/) (or
[SingularityCE](https://sylabs.io/singularity/)) base container that can be used to run MPI-based
software in "hybrid" mode.

My hope is that this may save you some time; at least it should make
it easier to ask the right questions when talking to HPC support
staff.

Edits (however minor), corrections, improvements, etc are always
welcome. See [`todo.org`](todo.md) for a list of topics that are missing and
known issues.


<a id="orgfabc331"></a>

# Apptainer (Singularity) containers with Open MPI and InfiniBand

Apptainer supports widely used open source MPI implementations ([Open
MPI](https://www.open-mpi.org/) and [MPICH](https://www.mpich.org/) as well as its derivatives such as [MVAPICH](https://mvapich.cse.ohio-state.edu/)), but these
notes focus on Open MPI.

Proper MPI support requires attention to two issues:

1.  compatibility between MPI libraries in the container and on a host,
2.  supporting network hardware.

The goal is to build an image that should

-   be minimal in terms of both content and complexity,
-   contain tools needed to check if it works on a particular host.

The whole process follows these steps:

1.  Install libraries needed to support network hardware we want to be
    able to use.
2.  Test if the container can use the interconnect *without* Open MPI.
3.  Install Open MPI with InfiniBand support.
4.  Configure Open MPI in the container (if necessary).
5.  Check if support for IB devices is included in Open MPI.
6.  Check if we can run a simple "MPI Hello world" program in the container.
7.  Install benchmarks and compare MPI performance (host vs container).

In this setup the first step corresponds to building an image using
the definition file [`minimal/base.def`](minimal/base.def).

Steps 3, 4 (and the installation part of 7) correspond to building the
second (final) image using [`minimal/openmpi-base.def`](minimal/openmpi-base.def).

This split makes it easier to separate issues related to version
compatibility from ones related to hardware support.

You should be able to run `make -C minimal` to build
`openmpi-base.sif` and *then* use it to perform steps 2, 5, and 6.

> The definition files `minimal/base.def` and `minimal/openmpi-base.def`
> should have no unnecessary software packages, no extra environment
> variables. They document a minimal working setup.


<a id="orgc626db8"></a>

# Building a minimal base image "by hand"


<a id="orgc114d9f"></a>

## Installing support libraries

Supporting InfiniBand in a container is not that different from the
same task on a host: we need all the same user-space libraries.
However, we do **not** need configuration tools, tools for updating
firmware, etc.

See [Mellanox OpenFabrics Enterprise Distribution for Linux](https://www.mellanox.com/products/infiniband-drivers/linux/mlnx_ofed) for
binary packages provided by NVIDIA and [`MLNX_OFED`: Firmware -
Driver Compatibility Matrix](https://www.mellanox.com/support/mlnx-ofed-matrix?mtag=linux_sw_drivers) to see which driver version is needed
for a particular model of the interconnect.

RHEL 7 documentation contains a list of [InfiniBand and RDMA related
software packages](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-infiniband_and_rdma_related_software_packages) that we use here.

See [`minimal/base.def`](minimal/base.def) for details.


<a id="org11b9854"></a>

## Testing InfiniBand devices

Commands listed below assume that `base.sif` was built using the
definition file from the previous step.

We install `libibverbs-utils` and use

-   `ibv_devices` to check if IB devices are available, and
-   `ibv_rc_pingpong` to test inter-node communication.


<a id="org598d3f2"></a>

### Checking if IB devices are available

Running `ibv_devices` should produce output similar to this:

    % singularity exec base.sif ibv_devices
        device                 node GUID
        ------              ----------------
        mlx4_0              7cfe900300c40490

Running the same command on a laptop that does not have IB devices
gives this:

    % singularity exec base.sif ibv_devices
    Failed to get IB devices list: Unknown error -38

Alternatively, run `ibstat` from `infiniband-diags`:

    % singularity exec base.sif ibstat
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

    % singularity exec base.sif ibstat
    ibpanic: [2137592] main: stat of IB device 'mthca0' failed: No such file or directory


<a id="org50d9375"></a>

### Checking inter-node communication using IB

Start an interactive job. On a system using [Slurm](https://slurm.schedmd.com/) this would require
something like

    srun -p debug --nodes=1 --exclusive -I --pty /bin/bash

Then, run this on a compute node to start `ibv_rc_pingpong` in its
*server* mode:

    % hostname && singularity exec openmpi.sif ibv_rc_pingpong
    n2
      local address:  LID 0x0091, QPN 0x03006b, PSN 0x5a83c9, GID ::
      remote address: LID 0x0031, QPN 0x002962, PSN 0x850520, GID ::
    8192000 bytes in 0.01 seconds = 9496.59 Mbit/sec
    1000 iters in 0.01 seconds = 6.90 usec/iter

Next, use the `hostname` output from above (here: `n2`) to run
`ibv_rc_pingpong` on the login node:

    % singularity exec openmpi.sif ibv_rc_pingpong n2
      local address:  LID 0x0031, QPN 0x002962, PSN 0x850520, GID ::
      remote address: LID 0x0091, QPN 0x03006b, PSN 0x5a83c9, GID ::
    8192000 bytes in 0.01 seconds = 9630.57 Mbit/sec
    1000 iters in 0.01 seconds = 6.80 usec/iter

The throughput reported should be close to numbers advertised for the
interconnect used by the host. (You can also run `ibv_rc_pingpong`
*directly on the host* &#x2014; without the container &#x2014; and compare
results.)


<a id="orged8fbaa"></a>

## Installing Open MPI

Installing support libraries in standard locations should be enough to
get Open MPI to use them: it will [try to find support for all hardware
and environments by looking for support libraries and header files in
standard locations; skip them if not found](https://www-lb.open-mpi.org/faq/?category=building#default-build).

The standard sequence

    configure --prefix=${prefix} && make && make install

is likely to be sufficient. However, it may be a good idea to use flags
such as `--with-verbs` to force `configure` to stop if a required
dependency was not found. See [How do I build Open MPI with support for
{my favorite network type}?](https://www-lb.open-mpi.org/faq/?category=building#build-p2p) for more details.

> Open MPI versions from 4.0 onward recommend installing [UCX](https://openucx.readthedocs.io/en/master/index.html) to
> support Mellanox IB cards, but these notes (so far) use the older
> `openib` BTL (byte transfer layer).
> 
> I may fix this later.


<a id="org33e56a7"></a>

## Checking if IB support in Open MPI is present

Run

    ompi_info --parsable | grep openib

*after* the build is complete to check if `openib` support was included.


<a id="org6bd0f22"></a>

## Configuring Open MPI in the container

Open MPI uses a [Modular Component Architecture (MCA)](https://www.open-mpi.org/faq/?category=tuning#mca-def), i.e. a set of
framework components and modules. Much of its behavior can be adjusted
using MCA parameters that can be set using command-line options *or*
configuration files.

A comment in such a file says

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

This means that *configuration files on the host will not be seen by
Open MPI in a container*.

We may need to modify a container to use settings appropriate on a
given host.


<a id="org06888ce"></a>

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


<a id="org9024ddb"></a>

### Useful MCA parameters

Open MPI 4.x without UCX:

    # disable the TCP byte transport layer
    btl = vader,self,openib
    # Use openib without UCX in Open MPI 4.0 and later:
    btl_openib_allow_ib = 1

Increasing verbosity for testing:

    mpirun --mca btl_base_verbose 100 --mca mca_base_verbose stdout \
           ...


<a id="org17300e5"></a>

## The "MPI Hello world" test

It is useful to include a simple "MPI Hello world" program in a base
image. It looks like most software compatibility and hardware support
issues crop up during initialization (in the `MPI_Init()` call), so a
test program as simple as that seems to do the job.

The two recommended test steps are

1.  try using `mpirun` *in the container*
2.  try using `mpirun` *on the host*.


<a id="org20211a2"></a>

### Using `mpirun` in the container

A successful run looks like this:

    % singularity exec openmpi.sif mpirun -n 4 mpi_hello
    Hello from process 0/4!
    Hello from process 1/4!
    Hello from process 2/4!
    Hello from process 3/4!

We can also increase verbosity to check if Open MPI succeeded at
initializing InfiniBand devices:

    % singularity exec openmpi.sif mpirun --mca btl_base_verbose 100 --mca mca_base_verbose stdout -n 1 mpi_hello | grep openib
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


<a id="org2229b27"></a>

### Using `mpirun` on the host

A successful run looks like this:

    % mpirun -n 4 singularity exec openmpi.sif mpi_hello
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
           singularity exec openmpi.sif mpi_hello | grep openib

This command should produce the same output as the one above (`mpirun`
in the container).


<a id="orgbc1d766"></a>

## Comparing MPI performance (container vs host)

We use [Intel(R) MPI Benchmarks 2021.3](https://github.com/intel/mpi-benchmarks) to compare Open MPI performance
when using the container versus the host MPI.

It is easy to build using MPI wrappers for the C++ compiler (see
[`benchmarking/build-imb.sh`](benchmarking/build-imb.sh)):

    wget -nc https://github.com/intel/mpi-benchmarks/archive/refs/tags/IMB-v2021.3.tar.gz
    tar xzf IMB-v2021.3.tar.gz
    
    cd mpi-benchmarks-IMB-v2021.3/
    
    CC=mpicc CXX=mpicxx make all
    cp IMB-* ..
    
    cd ..
    
    rm -rf mpi-benchmarks-IMB-v2021.3 # IMB-v2021.3.tar.gz

For a basic performance check it should be enough to run

    mpirun -n 2 IMB-MPI1 Sendrecv > imb-host.log
    mpirun -n 2 singularity exec openmpi-base.sif IMB-MPI1 Sendrecv > imb-container.log

and compare the logs this produces.

For large message sizes the thoughput reported by the benchmark should
be close to what's listed in the specs and to the number obtained
using `ibv_rc_pingpong` above.

> Similarly to `ibv_rc_pingpong`, it is important to run `mpirun -n 2
> IMB-MPI1 Sendrecv` on **two separate nodes**. See
> [`benchmarking/imb-job-script.sh`](benchmarking/imb-job-script.sh) for a way to do this on a system that
> uses Slurm.
> 
> (When executed on a single node this benchmark is likely to use shared
> memory instead of the network interconnect.)


<a id="org0ea8265"></a>

# Using HPC Container Maker

The [HPC Container Maker](https://github.com/NVIDIA/hpc-container-maker) (a Python command-line tool and a module)
simplifies building containers that need to use NVIDIA devices &#x2013; both
Mellanox InfiniBand cards (since NVIDIA owns Mellanox) and GPUs.

A very basic Open MPI base image with IB support can be created using
a recipe as simple as this:

    Stage0 += baseimage(image='centos:centos7', _as="devel")
    Stage0 += ofed()
    compiler = gnu()
    Stage0 += compiler
    Stage0 += openmpi(cuda=False, infiniband=True, toolchain=compiler.toolchain, version='4.1.2')

See [HPCCM documentation](https://github.com/NVIDIA/hpc-container-maker/tree/master/docs#readme) for more.

See [`hpccm/openmpi-base.py`](hpccm/openmpi-base.py) for a recipe that builds an image roughly
equivalent to the "minimal" one above. This recipe is converted to
`hpccm/openmpi-base.def` using [this `Makefile`](hpccm/Makefile).


<a id="org615158a"></a>

# Regarding software compatibility


<a id="org4fcf172"></a>

## Open MPI in the container vs the host version

The standard advice is "use the version installed on the host", but
this is not always practical: we may want to support multiple hosts or
the host may not have Open MPI installed.

Moreover, we need to try to do what we can to simplify reproducible
research and that may require using more current Open MPI versions
than a certain host provides.

The plot below shows which Open MPI version combinations appear to be
compatible. (See [`version_compatibility`](version_compatibility/README.md) for the
setup used to produce it.)

![img](version_compatibility/grid.png "Compatibility between container and host Open MPI versions")

Based on this I would recommend using Open MPI version 4.0.0 or newer
in the container because these versions are compatible with Open MPI
3.0.3 and newer on the host. Your mileage may vary.

> A better advice may be "convince your HPC support staff to install
> Slurm with PMIx on the host and configure Open MPI in the container to
> use PMIx."

> Note, also, that [Open MPI 4.1.x is ABI compatible with 4.0.x and 4.0.x
> is ABI compatible with 3.1.x and 3.0.x](https://www.open-mpi.org/software/ompi/major-changes.php).


<a id="org00c109d"></a>

### Compatibility between Open MPI and its dependencies

It is worth pointing out that Open MPI relies on external libraries
for some of its features and we need to use versions of these that are
compatible with the chosen Open MPI version.

In particular, we might have to build some libraries from source
instead of using a package system if our container is based on a
distribution that is significantly older than the chosen Open MPI
version.


<a id="org7172b6d"></a>

## Compatibility between the host kernel and the container OS

If you run a container and it fails with the error message saying
`FATAL: kernel too old`, it is likely that the *host* kernel is not
supported by `glibc` in the container.

The relevant threshold is this: *glibc 2.26 and newer require Linux
3.2 or newer.*

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


<a id="org3432c73"></a>

# Acknowledgments

This work was inspired by [a blog post by Magnus Hagdorn](https://blogs.ed.ac.uk/mhagdorn/2020/08/14/using-singularity-to-containerise-a-scientific-model/).

I'd like to thank [Research Computing Systems staff at UAF](https://www.gi.alaska.edu/services/research-computing-systems) and [NASA
Advanced Supercomputing (NAS) Division support staff](https://nas.nasa.gov/) for their help.

The specific output of "MPI Hello World" used here is inspired by
Singularity docs and the [recording of the 2022-1-6 Singularity CE
community meeting](https://youtu.be/jl2cT9gkxwo). Details regarding building Open MPI in a way that
supports Slurm come from the same recording.

Some of the ideas come from the discussion of the
[Apptainer/singularity issue 876](https://github.com/apptainer/singularity/issues/876).

