#!/bin/bash
#
# Builds Intel's MPI Benchmarks
#
# https://github.com/intel/mpi-benchmarks

set -e
set -x

wget -nc https://github.com/intel/mpi-benchmarks/archive/refs/tags/IMB-v2021.3.tar.gz
tar xzf IMB-v2021.3.tar.gz

cd mpi-benchmarks-IMB-v2021.3/

CC=mpicc CXX=mpicxx make all
cp IMB-* ..

cd ..

rm -rf mpi-benchmarks-IMB-v2021.3 IMB-v2021.3.tar.gz
