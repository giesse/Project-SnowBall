NODE = nodejs
NODEINT = rlwrap nodejs

all: topaz/interpreter.js

tests: all
	${NODE} topaz/interpreter.js topaz/tests.topaz

repl: all
	${NODEINT} topaz/interpreter.js

compile: all
	${NODE} topaz/interpreter.js topaz/compile.topaz

topaz/interpreter.js: topaz/bootstrap.js topaz/interpreter.topaz
	${NODE} topaz/bootstrap.js
