NODE = nodejs
NODEINT = rlwrap nodejs

all: topaz/topaz.js

tests: topaz/topaz.js topaz/tests.topaz
	${NODE} topaz/topaz.js topaz/tests.topaz

repl: all
	${NODEINT} topaz/topaz.js

topaz/topaz.js: topaz/bootstrap.js topaz/actions.topaz topaz/compiler.topaz topaz/init.topaz topaz/load.topaz topaz/natives.topaz topaz/support.topaz topaz/typesets.topaz topaz/types/* topaz/compile-topaz.topaz
	${NODE} topaz/bootstrap.js topaz/compile-topaz.topaz

topaz/bootstrap.js:
	wget -O topaz/bootstrap.js http://www.colellachiara.com/soft/topaz/bootstrap.js
