- Supporting hosts that use Slurm (install `munge` and PMIx 3.2.2 or
  newer `--with-munge`).
- Document building containers using MPICH instead of Open MPI
  (probably [MVAPICH](https://mvapich.cse.ohio-state.edu/)).
- Update to use
  [UCX](https://openucx.readthedocs.io/en/master/running.html#openmpi-with-ucx)
  (and `libfabric`?).

  See [Running UCX](https://openucx.readthedocs.io/en/master/running.html#running-mpi) for more info.

  Add `--mca pml_base_verbose 100` to verbosity options (to check if
  UCX **is** actually used).

  Explain the use of `ucx_info -d` and setting environment variables
  to force it to use a certain device.

  Build Open MPI `--without-verbs` to [avoid an error message about
  device
  initialization](https://www.open-mpi.org/faq/?category=openfabrics#ofa-device-error):

```
    --------------------------------------------------------------------------
    WARNING: There was an error initializing an OpenFabrics device.

      Local host:   chinook01
      Local device: mlx4_0
    --------------------------------------------------------------------------
```
- Make sure that the list of packages in `base.def` does not include
  anything unnecessary.
