openmpi-base.sif:

openmpi-base.def: openmpi-base.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 > $@

openmpi-base-ucx.def: openmpi-base.py
	hpccm --recipe $< --format singularity --singularity-version 3.8 --userarg ucx=1 > $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

.PHONY: clean
clean:
	rm -f *.sif *.def

.INTERMEDIATE: openmpi-base.def
