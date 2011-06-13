NODE = nodejs
NODEINT = rlwrap nodejs

all: topaz/interpreter.js

tests: all
	${NODE} topaz/interpreter.js topaz/tests.topaz

repl: all
	${NODEINT} topaz/interpreter.js

topaz/interpreter.js: topaz/bootstrap.js topaz/interpreter.topaz
	${NODE} topaz/bootstrap.js topaz/compile.topaz

topaz/bootstrap.js:
	wget http://www.colellachiara.com/soft/topaz/bootstrap.js
