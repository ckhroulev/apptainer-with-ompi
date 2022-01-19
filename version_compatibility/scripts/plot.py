#!/usr/bin/env python3

"""Create a "spy" plot showing which Singularity container-host Open
MPI version combinations appear to work.
"""

import sys
import numpy as np
from matplotlib import pyplot as plt
plt.rc("font", size=20)

input_file = sys.argv[1]
output_file = sys.argv[2]

data = np.loadtxt(input_file, dtype=str)

versions = np.unique(data[:, 0])
nv = len(versions)

flags = np.array(data[:, 2], dtype=int).reshape(nv, nv)

fig, ax = plt.subplots()
fig.set_size_inches(20, 20)
fig.set_dpi(50)

ax.set_title("Apptainer (Singularity) and Open MPI: host-container version compatibility")
ax.spy(flags, origin="lower", marker=".", markersize=40)
ax.grid()

ax.set_xlabel("Container Open MPI version")
ax.set_xticks(np.arange(nv))
ax.set_xticklabels(versions)
ax.tick_params(axis='x', rotation=90)

ax.set_ylabel("Host Open MPI version")
ax.set_yticks(np.arange(nv))
ax.set_yticklabels(versions)

fig.savefig(output_file)
