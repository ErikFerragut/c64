.PHONY: build dev clean

build:
	npx elm make src/Main.elm --output=cdis.js

dev: build
	cd src-tauri && cargo tauri dev

clean:
	rm -f cdis.js
	cd src-tauri && cargo clean
