all: wiggle.min.js wiggle.js style.css

closure/compiler.jar:
	rm -fr closure
	mkdir closure
	cd closure && wget http://dl.google.com/closure-compiler/compiler-latest.zip && unzip compiler-latest.zip

%.js: %.coffee
	coffee  -o . -c $^

%.css: %.less
	lessc $^ > $@

wiggle.min.js: wiggle.js closure/compiler.jar
	java -jar closure/compiler.jar --js wiggle.js --js_output_file wiggle.min.js --compilation_level ADVANCED_OPTIMIZATIONS
