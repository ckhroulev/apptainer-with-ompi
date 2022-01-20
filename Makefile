openmpi.sif: base.sif scripts/openmpi.sh src/mpi_hello.c

README.md: notes.md
	mv $< $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

%.md: %.org
	emacs $< --batch -f org-md-export-to-markdown --kill

hpccm-ompi-base.sif:
hpccm-ompi-base.def:

%.def: %.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 > $@

.PHONY: clean
clean:
	rm -f base.sif
