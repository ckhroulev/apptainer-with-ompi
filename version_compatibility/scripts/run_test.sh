#!/bin/bash

set -e
set -u

ompi_prefix=${1:?Usage: $0 ompi_prefix host_version container_version}
host_version=${2:?Usage: $0 ompi_prefix host_version container_version}
container_version=${3:?Usage: $0 ompi_prefix host_version container_version}

# Note: we use "timeout" from coreutils to handle version combinations
# that hang.
${ompi_prefix}-${host_version}/bin/mpiexec -n 2 \
              timeout 5 \
              singularity exec tests.sif \
              /opt/tests/test-${container_version} 2>&1 | grep -qE "Size: 2"
