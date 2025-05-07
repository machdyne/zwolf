build-examples:
	mkdir -p output
	python3 tools/asm.py examples/counter.asm output/counter.bin
	python3 tools/b2h.py output/counter.bin > output/counter.asc

.PHONY: build-examples
