INTERMEDIATE=base.sif build.sif base-ompi.sif
.INTERMEDIATE: ${INTERMEDIATE}

base.sif: base.def

openmpi.sif: base.sif scripts/openmpi.sh

%.sif: %.def
	singularity build --fakeroot --force $@ $<

.PHONY: clean
clean:
	rm -f ${INTERMEDIATE}
