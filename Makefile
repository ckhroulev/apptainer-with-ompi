openmpi.sif: base.sif scripts/openmpi.sh

README.md:

%.sif: %.def
	singularity build --fakeroot --force $@ $<

%.md: %.org
	emacs $< --batch -f org-md-export-to-markdown --kill

.PHONY: clean
clean:
	rm -f base.sif
