SHELL := /bin/zsh

setup:
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip install numpy opencv-python

screen:
	source .venv/bin/activate && python screen.py

run:
	@trap 'stty sane' EXIT INT TERM
	stty raw -echo min 0 time 0
	zig build run \
		3> >(sox -t raw -r 44100 -e signed -b 16 -c 1 - -d > /dev/null 2> /dev/null)
	stty sane

clean:
	rm -rf .zig-cache
	rm -rf zig-out
	rm -rf .venv
	rm -rf .screen