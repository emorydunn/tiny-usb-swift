all: build run

.PHONY: build
build:
	cmake --build build

.PHONY: build
clean:
	rm -fr build
	mkdir build
	cmake -S Swift -B build -G Ninja .

run:
	picotool load -vx build/*.uf2
