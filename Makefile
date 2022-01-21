openmpi.sif: base.sif scripts/openmpi.sh src/mpi_hello.c

openmpi-base.sif:
openmpi-base.def:

openmpi-base-ucx.sif:
openmpi-base-ucx.def:

README.md: notes.md
	mv $< $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

%.md: %.org
	emacs $< --batch -f org-md-export-to-markdown --kill

%.def: %.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 > $@

.PHONY: clean
clean:
	rm -f base.sif
