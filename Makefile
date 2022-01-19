INTERMEDIATE=base.sif build.sif base-ompi.sif
.INTERMEDIATE: ${INTERMEDIATE}

build.sif: base.sif

base.sif: base.def

base-ompi.sif: build.sif scripts/openmpi.sh

%.sif: %.def
	singularity build --fakeroot --force $@ $<

.PHONY: clean
clean:
	rm -f ${INTERMEDIATE}
