#!/bin/bash

set -u

test_script=${1:?Usage: $0 test_script.sh output.log}
output=${2:?Usage: $0 test_script.sh output.log}
ompi_prefix=${ompi_prefix:-${HOME}/opt/ompi}
testcase_prefix=${testcase_prefix:-${HOME}/opt/tests/}

# We use 'echo' here to take advantage of the brace expansion in Bash:
versions=$(echo 2.0.{0..4} 2.1.{0..6} 3.0.{0..6} 3.1.{0..6} 4.0.{0..7} 4.1.{0..2})

# Create the temporary file to hold the log:
output_tmp=$(mktemp ./failure-log.XXXX)

for host_version in $versions;
do
  for container_version in $versions;
  do
    bash ${test_script} ${ompi_prefix} ${host_version} ${container_version}

    if [[ $? == 0 ]];
    then
      echo "${host_version} ${container_version} 1" >> ${output_tmp}
      echo "Works: H:${host_version} C:${container_version}"
    else
      echo "${host_version} ${container_version} 0" >> ${output_tmp}
      echo "Fails: H:${host_version} C:${container_version}"
    fi
  done
done

mv ${output_tmp} ${output}
