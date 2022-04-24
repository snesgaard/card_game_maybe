build:
	make -C art

play: build
	love .
