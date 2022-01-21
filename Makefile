openmpi.sif: base.sif scripts/openmpi.sh src/mpi_hello.c

openmpi-base.sif:
openmpi-base-ucx.sif:

openmpi-base.def: openmpi-base.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 > $@

openmpi-base-ucx.def: openmpi-base.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 --userarg ucx=1 > $@

README.md: notes.md
	mv $< $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

%.md: %.org
	emacs $< --batch -f org-md-export-to-markdown --kill

.PHONY: clean
clean:
	rm -f base.sif
