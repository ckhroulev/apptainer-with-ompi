#!/bin/bash

set -e
set -u

# Note: defaults correspond to locations on the host
prefix=${prefix:-${HOME}/opt/ompi}
export build_dir=${build_dir:-${HOME}/local/build/ompi}

# We use 'echo' here to take advantage of the brace expansion in Bash:
versions=$(echo 2.0.{0..4} 2.1.{0..6} 3.0.{0..6} 3.1.{0..6} 4.0.{0..7} 4.1.{0..2})

for V in $versions;
do
  echo Building Open MPI version ${V}
  prefix=${prefix}-${V} version=${V} bash ./build_openmpi.sh
  echo Done building Open MPI version ${V}
done
