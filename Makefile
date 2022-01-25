README.md: notes.md
	mv $< $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

%.md: %.org
	emacs $< --batch -f org-md-export-to-markdown --kill

.PHONY: clean
clean:
	rm -f base.sif
