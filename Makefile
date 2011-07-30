NODE = nodejs
NODEINT = rlwrap nodejs

all: topaz/interpreter.js

tests: topaz/interpreter.js topaz/tests.topaz
	${NODE} topaz/interpreter.js topaz/tests.topaz

compile-next: topaz/interpreter.js topaz/compile-next.topaz
	${NODE} topaz/interpreter.js topaz/compile-next.topaz

repl: all
	${NODEINT} topaz/interpreter.js

topaz/interpreter.js: topaz/bootstrap.js topaz/interpreter.topaz topaz/init.topaz topaz/compile.topaz
	${NODE} topaz/bootstrap.js topaz/compile.topaz

topaz/bootstrap.js:
	wget -O topaz/bootstrap.js http://www.colellachiara.com/soft/topaz/bootstrap.js
