#!/bin/bash
#
# Builds the MPI-1 part of Intel's MPI Benchmark, IMB-MPI1
#
# https://github.com/intel/mpi-benchmarks

set -e
set -x

wget https://github.com/intel/mpi-benchmarks/archive/refs/tags/IMB-v2021.3.tar.gz

tar xzf IMB-v2021.3.tar.gz

pushd mpi-benchmarks-IMB-v2021.3/

CC=mpicc CXX=mpicxx make IMB-MPI1

popd

rm -rf mpi-benchmarks-IMB-v2021.3 IMB-v2021.3.tar.gz
