all: compatibility-grid.png

compatibility-grid.png: failure.log
	python3 ./scripts/plot.py $< $@

%.sif: %.def
	singularity build --fakeroot --force $@ $<

tests.sif: openmpi.sif

.PHONY: host
host:
	./scripts/build_all_openmpi.sh

failure.log: tests.sif
	bash ./scripts/run_all_tests.sh ./scripts/run_test.sh $@
