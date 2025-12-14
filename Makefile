setup:
	python3 -m venv .venv && \
	source .venv/bin/activate && \
	pip install numpy opencv-python sounddevice

screen:
	source .venv/bin/activate && python screen.py

audio:
	source .venv/bin/activate && python audio.py

run:
	rm -rf .channel
	mkdir -p .channel
	@trap 'stty sane' EXIT INT TERM
	stty raw -echo min 0 time 0
	zig build run
	stty sane

test:
	zig build test

clean:
	rm -rf .zig-cache
	rm -rf zig-out
	rm -rf .venv
	rm -rf .screen
	rm -rf .channel