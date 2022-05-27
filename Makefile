build:
	make -C art

play: build
	love .

test: build
	love . test
