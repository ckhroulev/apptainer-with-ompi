#!/bin/bash

set -e
set -u

ompi_prefix=${ompi_prefix:-${HOME}/opt/ompi}
prefix=${prefix:-${HOME}/opt/testcase}
source_file=testcase.c

# We use 'echo' here to take advantage of the brace expansion in Bash:
versions=$(echo 2.0.{0..4} 2.1.{0..6} 3.0.{0..6} 3.1.{0..6} 4.0.{0..7} 4.1.{0..2})

mkdir -p ${prefix}

for V in $versions;
do
  set -x
  ${ompi_prefix}-${V}/bin/mpicc ${source_file} -o ${prefix}/test-${V}
  set +x
done
