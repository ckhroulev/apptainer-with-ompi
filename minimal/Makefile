openmpi-base.sif: base.sif build-openmpi.sh mpi_hello.c

%.sif: %.def
	singularity build --fakeroot --force $@ $<

.PHONY: clean
clean:
	rm -f base.sif
