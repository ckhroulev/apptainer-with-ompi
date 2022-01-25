#!/bin/bash
#
# Builds Intel's MPI Benchmarks
#
# https://github.com/intel/mpi-benchmarks

set -e
set -x

wget https://github.com/intel/mpi-benchmarks/archive/refs/tags/IMB-v2021.3.tar.gz
tar xzf IMB-v2021.3.tar.gz

cd mpi-benchmarks-IMB-v2021.3/

CXX=mpicxx make IMB-MPI1 IMB-MPI2 IMB-MPI3
cp IMB-MPI{1,2,3} ..

cd ..

rm -rf mpi-benchmarks-IMB-v2021.3 IMB-v2021.3.tar.gz
