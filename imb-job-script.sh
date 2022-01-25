#!/bin/bash
#SBATCH --partition=debug
#SBATCH --ntasks=2
#SBATCH --tasks-per-node=1
#SBATCH --output=imb-%j.log

# Runs IMB-MPI1 in a container and on the host to compare performance.
#
# Note: it is important to run this on two nodes with 1 task each (2
# tasks total).
#
# Note: you can use build-imb.sh to build IMB-MPI1 on the host.

set -e
set -u

ulimit -s unlimited
ulimit -l unlimited

module load singularity

cd $SLURM_SUBMIT_DIR

# Generate a list of allocated nodes; will serve as a hostfile for mpirun
srun -l /bin/hostname | sort -n | awk '{print $2}' > ./nodes.$SLURM_JOB_ID

options="-n 2 --hostfile ./nodes.$SLURM_JOB_ID --mca btl_base_verbose 100"
container="singularity exec openmpi-base.sif"
host=""

set -x

mpirun ${options} ${container} IMB-MPI1 Sendrecv > imb-container.log

mpirun ${options} ${host} IMB-MPI1 Sendrecv > imb-host.log

# Clean up the hostfile
rm ./nodes.$SLURM_JOB_ID
