/***
 * Topaz > JS bootstrap compiler
 *
 * Copyright 2011 Gabriele Santilli
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 ***/

function Topaz2JS(topaz_text) {
    return TCompile(TLoad(topaz_text, true)).toString();
}

function TParseError(text_cursor) {
    throw 'Parse error: ' + sys.inspect(text_cursor.toString());
}

function TLoad(topaz_text, all) {
    var text_cursor = new TTextCursor(topaz_text), values = TParseValues(text_cursor);
    if (!text_cursor.isTail()) {
        TParseError(text_cursor);
    }
    //TBind(values, TSystemWords);
    if (!all && values.length() == 1) return values.first();
    else return values;
}

function TParseValues(text_cursor) {
    var values = new TBlock(), parsed;
    text_cursor.skipSpaces();
    while (!text_cursor.isTail() && !text_cursor.match(/^[\]\)]/)) {
        if (parsed = TParseValue(text_cursor)) {
            text_cursor.skipSpaces();
            values.append(parsed);
        } else {
            TParseError(text_cursor);
        }
    }
    return values;
}

function TParsePathElement(text_cursor) {
    return TParseNumber(text_cursor) ||
        TParseWord(text_cursor) ||
        TParseString(text_cursor) ||
        TParseBlock(text_cursor) ||
        TParseParen(text_cursor) ||
        TParseChar(text_cursor);
}

function TParseValue(text_cursor) {
    return TParseNumber(text_cursor) ||
        TParseSetWord(text_cursor) ||
        TParsePath(text_cursor) ||
        TParseWord(text_cursor) ||
        TParseLitWord(text_cursor) ||
        TParseString(text_cursor) ||
        TParseBlock(text_cursor) ||
        TParseParen(text_cursor) ||
        TParseChar(text_cursor);
}

function TParseChar(text_cursor) {
    var match = text_cursor.matchAndSkip(/^#"(\^?.|\^\([0-9A-Fa-f]+\))"/, 1);
    return match && new TChar(match);
}

function TParseNumber(text_cursor) {
    var match = text_cursor.matchAndSkip(/^[-+]?[0-9]+(\.[0-9]*)?([Ee][+-]?[0-9]{1,3})?/);
    return match && new TNumber(parseFloat(match));
}

function TParseWord(text_cursor) {
    var match;
    return (match = text_cursor.matchAndSkip(/^[!&*+\-.<=>?A-Z^_`a-z|~-ÿ]['!&*+\-.0-9<=>?A-Z^_`a-z|~-ÿ]*/)) &&
        new TWord(match);
}

function TParseLitWord(text_cursor) {
    var match;
    return (match = text_cursor.matchAndSkip(/^'([!&*+\-.<=>?A-Z^_`a-z|~-ÿ]['!&*+\-.0-9<=>?A-Z^_`a-z|~-ÿ]*)/, 1)) &&
        new TLitWord(match);
}

function TParseSetWord(text_cursor) {
    var match;
    return (match = text_cursor.matchAndSkip(/^([!&*+\-.<=>?A-Z^_`a-z|~-ÿ]['!&*+\-.0-9<=>?A-Z^_`a-z|~-ÿ]*):/, 1)) &&
        new TSetWord(match);
}

function TParsePath(text_cursor) {
    var lit = text_cursor.match(/^'/),
        match = text_cursor.matchAndSkip(/^'?([!&*+\-.<=>?A-Z^_`a-z|~-ÿ]['!&*+\-.0-9<=>?A-Z^_`a-z|~-ÿ]*)\//, 1), value,
        element;
    if (match) {
        value = new TPath();
        value.append(new TWord(match));
        if (!text_cursor.isTail()) {
            if (element = TParsePathElement(text_cursor)) {
                value.append(element);
            } else {
                TParseError(text_cursor);
            }
        }
        while (!text_cursor.isTail() && text_cursor.matchAndSkip(/^\//)) {
            if (element = TParsePathElement(text_cursor)) {
                value.append(element);
            } else {
                TParseError(text_cursor);
            }
        }
        return lit ? value.toLitPath() : (text_cursor.matchAndSkip(/^:/) ? value.toSetPath() : value);
    }
    return null;
}

function TParseString(text_cursor) {
    var match = text_cursor.matchAndSkip(/^"(([^"^\f\n\r]*|\^\([0-9A-Fa-f]+\)|\^[^\f\n\r])*)"/, 1);
    if (match) {
        return new TString(TUnescape(match));
    } else if (text_cursor.match(/^"/)) {
        throw 'Missing ": ' + text_cursor.toString();
    } else return null;
}

function TUnescape(str) {
    var result = '', i = 0, j, ch, p;
    while ((j = str.indexOf('^', i)) >= 0) {
        result += str.substr(i, j - i);
        ch = str[j + 1];
        if (ch == '/') {
            result += '\n';
            i = j + 2;
        } else if (ch == '-') {
            result += '\t';
            i = j + 2;
        } else if (ch == '^') {
            result += '^';
            i = j + 2;
        } else if (ch == '!') {
            result += String.fromCharCode(30);
            i = j + 2;
        } else if (ch >= '@' && ch <= '_') {
            result += String.fromCharCode(ch.charCodeAt(0) - 64);
            i = j + 2;
        } else if (ch == '(' && (p = /^\(([0-9A-Fa-f]+)\)/.exec(str.substr(j + 1)))) {
            result += String.fromCharCode(parseInt(p[1], 16));
            i = j + p[0].length + 1;
        } else {
            result += ch;
            i = j + 2;
        }
    }
    return i == 0 ? str : result + str.substr(i);
}

function TParseAnyBlock(text_cursor, open, close, closestr) {
    if (text_cursor.matchAndSkip(open)) {
        var values = TParseValues(text_cursor);
        if (!text_cursor.matchAndSkip(close)) {
            throw 'Missing ' + closestr + ': ' + text_cursor.toString();
        }
        return values;
    } else return null;
}

function TParseBlock(text_cursor) {
    return TParseAnyBlock(text_cursor, /^\[/, /^]/, ']');
}

function TParseParen(text_cursor) {
    var paren = TParseAnyBlock(text_cursor, /^\(/, /^\)/, ')');
    return paren && paren.toParen();
}

function TCompile(block) {
    if (block.isEmpty())
        return new JSEmptyExpr();
    else {
        var compiled = TCompileStep(block), expr = compiled.expr;
        block = compiled.next;
        while (!block.isEmpty()) {
            compiled = TCompileStep(block);
            expr = new JSCompound(expr, compiled.expr);
            block = compiled.next;
        }
        return new JSStatement(expr);
    }
}

function TCompileStep(block) {
    var compiled = block.first().compile(block), op;
    block = compiled.next;
    while (!block.isEmpty() && (op = block.first()) && op instanceof TWord && (op = TOps[op.word])) {
        block = block.next();
        if (block.isEmpty()) throw 'Operator missing its second argument';
        var arg2 = block.first().compile(block);
        compiled.next = block = arg2.next;
        compiled.expr = new JSOp(op, compiled.expr, arg2.expr);
    }
    return compiled;
}

TOps = {
    "+": "+",
    "=": "==",
    "-": "-",
    ">": ">",
    "<": "<",
    "<>": "!="
}

// TValue

function TValue() {}

TValue.prototype.typename = '*this should not happen*';

function TInternalError(action) {
    return function() {
        throw 'Internal error - this should not happen. (' + action + ' on a ' + this.typename + ' value)';
    };
}

TValue.prototype.compile = function(block) {
    return {expr: new JSDummy(this), next: block.next()};
}
TValue.prototype.isEmpty = TInternalError('isEmpty()');
TValue.prototype.first   = TInternalError('first()');
TValue.prototype.length  = TInternalError('length()');
TValue.prototype.append  = TInternalError('append()');
TValue.prototype.next    = TInternalError('next()');

// TBlock

function TBlock(values, pos) {
    this.values = values || [];
    this.pos    = pos    || 0;
}

TBlock.prototype.__proto__ = TValue.prototype;
TBlock.prototype.typename = 'block!';
TBlock.prototype.isEmpty = function() {
    return this.values.length == this.pos;
}
TBlock.prototype.first = function() {
    return this.values[this.pos];
}
TBlock.prototype.length = function() {
    return this.values.length - this.pos;
}
TBlock.prototype.append = function(value) {
    this.values.push(value);
}
TBlock.prototype.next = function() {
    return new TBlock(this.values, this.pos + 1);
}
TBlock.prototype.toParen = function() {
    return new TParen(this.values, this.pos);
}

// TParen

function TParen(values, pos) {
    TBlock.call(this, values, pos);
}

TParen.prototype.__proto__ = TBlock.prototype;
TParen.prototype.typename = 'paren!';
TParen.prototype.compile = function(block) {
    if (this.isEmpty()) throw 'Cannot compile empty paren!';
    var compiled = TCompileStep(this);
    if (!compiled.next.isEmpty()) throw 'Cannot compile paren!s with more than one expression';
    return {expr: compiled.expr, next: block.next()};
}

// TPath

function TPath(values, pos) {
    TBlock.call(this, values, pos);
}

TPath.prototype.__proto__ = TBlock.prototype;
TPath.prototype.typename = 'path!';
TPath.prototype.toSetPath = function() {
    return new TSetPath(this.values, this.pos);
}
TPath.prototype.toLitPath = function() {
    return new TLitPath(this.values, this.pos);
}
TPath.prototype.compile = function(block) {
    return {expr: this.toExpr(), next: block.next()};
}
TPath.prototype.toExpr = function() {
    if (this.values.length < 2) throw 'Internal error, this should not happen. (path! with less than two values)';
    var expr = new JSDot(this.values[0].toExpr(), this.values[1].word);
    for (var i = 2; i < this.values.length; i++) {
        expr = new JSDot(expr, this.values[i].word);
    }
    return expr;
}

// TSetPath

function TSetPath(values, pos) {
    TBlock.call(this, values, pos);
}

TSetPath.prototype.__proto__ = TBlock.prototype;
TSetPath.prototype.typename = 'set-path!';
TSetPath.prototype.compile = function(block) {
    block = block.next();
    var compiled = TCompileStep(block);
    return {expr: new JSAssignment(this.toExpr(), compiled.expr), next: compiled.next};
}
TSetPath.prototype.toExpr = TPath.prototype.toExpr;

// TLitPath

function TLitPath(values, pos) {
    TBlock.call(this, values, pos);
}

TLitPath.prototype.__proto__ = TBlock.prototype;
TLitPath.prototype.typename = 'lit-path!';
TLitPath.prototype.toExpr = TPath.prototype.toExpr;

// TNumber

function TNumber(n) {
    this.num = n;
}

TNumber.prototype.__proto__ = TValue.prototype;
TNumber.prototype.typename = 'number!';
TNumber.prototype.compile = function(block) {
    return {expr: new JSNumber(this.num), next: block.next()};
}

// TString

function TString(s) {
    this.str = s;
}

TString.prototype.__proto__ = TValue.prototype;
TString.prototype.typename = 'string!';
TString.prototype.compile = function(block) {
    return {expr: new JSString(this.str), next: block.next()};
}

// TChar

function TChar(c) {
    this.chr = TUnescape(c);
}

TChar.prototype.__proto__ = TValue.prototype;
TChar.prototype.typename = 'char!';
TChar.prototype.compile = function(block) {
    return {expr: new JSChar(this.chr), next: block.next()};
}

// TWord

function TWord(w) {
    this.word = w.toLowerCase();
}

TWord.prototype.__proto__ = TValue.prototype;
TWord.prototype.typename = 'word!';
TWord.prototype.compile = function(block) {
    var f = TFunctions[this.word];
    return f ? f(block.next()) : {expr: this.toExpr(), next: block.next()};
}
TWord.prototype.toExpr = function() {
    return new JSVariable(this.word);
}

// TSetWord

function TSetWord(w) {
    this.word = w.toLowerCase();
}

TSetWord.prototype.__proto__ = TWord.prototype;
TSetWord.prototype.typename = 'set-word!';
TSetWord.prototype.compile = function(block) {
    block = block.next();
    var compiled = TCompileStep(block);
    return {expr: new JSAssignment(this.toExpr(), compiled.expr), next: compiled.next};
}

// TLitWord

function TLitWord(w) {
    this.word = w.toLowerCase();
}

TLitWord.prototype.__proto__ = TValue.prototype;
TLitWord.prototype.typename = 'lit-word!';
TLitWord.prototype.toExpr = function() {
    return new JSVariable(this.word);
}

// TFunctions

function TCollectArguments(name, block, nargs) {
    var args = [], compiled;
    for (var i = 0; i < nargs; i++) {
        if (block.isEmpty()) {
            throw 'Not enough arguments for ' + name.toUpperCase();
        }
        compiled = TCompileStep(block);
        args.push(compiled.expr);
        block = compiled.next;
    }
    return {args: args, next: block};
}
function TMakeFunction(name, f) {
    var nargs = f.length;
    return function(block) {
        var collected = TCollectArguments(name, block, nargs);
        return {expr: f.apply(null, collected.args), next: collected.next};
    }
}

TFunctions = {
    print: TMakeFunction('print', function(expr) {
        return new JSFunCall(new JSDot(new JSVariable('sys'), 'print'), [expr]);
    }),
    "function": TMakeFunction('function', function(args, locals, body) {
        if (args instanceof JSDummy && args.value instanceof TBlock &&
            locals instanceof JSDummy && locals.value instanceof TBlock &&
            body instanceof JSDummy && body.value instanceof TBlock) {
            return new JSFunDef(TBlock2Vars(args.value), TBlock2Vars(locals.value), TCompile(body.value).toJSReturn());
        } else {
            throw 'FUNCTION wants three literal blocks';
        }
    }),
    none: TMakeFunction('none', function() {return new JSNull();}),
    "true": TMakeFunction('true', function() {return new JSTrue();}),
    "false": TMakeFunction('false', function() {return new JSFalse();}),
    "throw": TMakeFunction('throw', function(expr) {return new JSThrow(expr);}),
    join: TMakeFunction('join', function(arg1, arg2) {return new JSOp('+', arg1, arg2);}),
    set: TMakeFunction('set', function(word, value) {
        if (word instanceof JSDummy) {
            word = word.value;
            if (word instanceof TLitWord) {
                return new JSAssignment(new JSVariable(word.name), value);
            } else if (word instanceof TBlock) {
                return new JSMultiAssignment(TBlock2Vars(word), value);
            } else {
                throw 'SET wants a literal lit-word! or literal block!';
            }
        } else {
            throw 'SET wants a literal lit-word! or literal block!';
        }
    }),
    "if": TMakeFunction('if', function(cond, body) {
        if (body instanceof JSDummy && body.value instanceof TBlock) {
            return new JSIfElse(cond, TCompile(body.value), null);
        } else {
            throw 'IF wants a literal block! for its body';
        }
    }),
    either: TMakeFunction('either', function(cond, truebody, falsebody) {
        if (truebody instanceof JSDummy && truebody.value instanceof TBlock &&
            falsebody instanceof JSDummy && falsebody.value instanceof TBlock) {
            return new JSIfElse(cond, TCompile(truebody.value), TCompile(falsebody.value));
        } else {
            throw 'EITHER wants a literal block! for both its body arguments';
        }
    }),
    not: TMakeFunction('not', function(expr) {return new JSNegate(expr);}),
    "length-of-array": TMakeFunction('length-of-array', function(expr) {return new JSDot(expr, 'length');}),
    "first-of-array": TMakeFunction('first-of-array', function(expr) {return new JSPick(expr, new JSNumber(0));}),
    "make-struct": TMakeFunction('make-struct', function(spec) {
        if (!(spec instanceof JSDummy) || !(spec.value instanceof TBlock))
            throw 'MAKE-STRUCT wants a literal block for its spec argument';
        return new JSObject(TParseStructSpec(spec.value));
    }),
    apply: TMakeFunction('apply', function(fname, args) {
        if (!(fname instanceof JSDummy) || !(fname.value instanceof TLitWord || fname.value instanceof TLitPath))
            throw 'APPLY wants a literal lit-word! or lit-path! for the function name';
        if (!(args instanceof JSDummy) || !(args.value instanceof TBlock))
            throw 'APPLY wants a literal block! for the function arguments';
        return new JSFunCall(fname.value.toExpr(), TReduce(args.value));
    }),
    reduce: TMakeFunction('reduce', function(block) {
        if (!(block instanceof JSDummy) || !(block.value instanceof TBlock))
            throw 'REDUCE wants a literal block! for its argument';
        return new JSArray(TReduce(block.value));
    }),
    "while": TMakeFunction('while', function(condblock, body) {
        if (condblock instanceof JSDummy && condblock.value instanceof TBlock &&
            body instanceof JSDummy && body.value instanceof TBlock) {
            if (condblock.value.isEmpty()) throw 'WHILE\'s condition block cannot be empty';
            var compiled = TCompileStep(condblock.value);
            if (!compiled.next.isEmpty()) throw 'WHILE\'s condition block can only have one expression';
            return new JSWhile(compiled.expr, TCompile(body.value));
        } else {
            throw 'WHILE wants a literal block! for both its arguments';
        }
    }),
    until: TMakeFunction('until', function(body) {
        if (body instanceof JSDummy && body.value instanceof TBlock) {
            if (body.value.isEmpty()) throw 'UNTIL\'s block cannot be empty';
            return TCompile(body.value).toJSUntil();
        } else {
            throw 'UNTIL wants a literal block! for its argument';
        }
    }),
    "insert-array": TMakeFunction('insert-array', function(arr, pos, value) {
        return new JSFunCall(new JSDot(arr, 'splice'), [pos, new JSNumber(0), value]);
    }),
    "make-array": TMakeFunction('make-array', function() {return new JSArray([]);}),
    "poke-array": TMakeFunction('poke-array', function(arr, pos, value) {
        return new JSAssignment(new JSPick(arr, pos), value);
    }),
    "pick-array": TMakeFunction('pick-array', function(arr, pos) {return new JSPick(arr, pos);}),
    all: TMakeFunction('all', function(block) {
        if (!(block instanceof JSDummy) || !(block.value instanceof TBlock))
            throw 'ALL wants a literal block! for its argument';
        block = block.value;
        if (block.isEmpty()) throw 'ALL needs at least one expression';
        var compiled = TCompileStep(block), expr = compiled.expr;
        block = compiled.next;
        while (!block.isEmpty()) {
            compiled = TCompileStep(block);
            expr = new JSOp('&&', expr, compiled.expr);
            block = compiled.next;
        }
        return expr;
    }),
    any: TMakeFunction('any', function(block) {
        if (!(block instanceof JSDummy) || !(block.value instanceof TBlock))
            throw 'ANY wants a literal block! for its argument';
        block = block.value;
        if (block.isEmpty()) throw 'ANY needs at least one expression';
        var compiled = TCompileStep(block), expr = compiled.expr;
        block = compiled.next;
        while (!block.isEmpty()) {
            compiled = TCompileStep(block);
            expr = new JSOp('||', expr, compiled.expr);
            block = compiled.next;
        }
        return expr;
    }),
    "regexp": TMakeFunction('regexp', function(expr) {
        if (!(expr instanceof JSString))
            throw 'REGEXP wants a literal string! as its argument';
        return new JSRegExp(expr.str);
    })
};

function TParseStructSpec(block) {
    var struct = {};
    while (!block.isEmpty()) {
        var name = block.first();
        if (!(name instanceof TSetWord))
            throw 'Invalid struct spec, expected set-word! not ' + name.typename;
        block = block.next();
        if (block.isEmpty())
            throw 'Struct field ' + name.word.toUpperCase() + ' is missing its value';
        var compiled = TCompileStep(block);
        block = compiled.next;
        struct[name.word] = compiled.expr;
    }
    return struct;
}

function TReduce(block) {
    var exprs = [];
    while (!block.isEmpty()) {
        var compiled = TCompileStep(block);
        exprs.push(compiled.expr);
        block = compiled.next;
    }
    return exprs;
}

function TUserFuncCompiler(name, nargs) {
    return function(block) {
        var collected = TCollectArguments(name, block, nargs);
        return {
            expr: new JSFunCall(new JSVariable(name), collected.args),
            next: collected.next
        }
    }
}

function TBlock2Vars(block) {
    var vars = [], v;
    while (!block.isEmpty()) {
        v = block.first();
        if (!(v instanceof TWord)) {
            throw 'Expected block of words';
        }
        vars.push(JSConvertVarName(v.word));
        block = block.next();
    }
    return vars;
}

// JSExpr

function JSExpr() {}

JSExpr.prototype.toString = function() {
    return '';
}
JSExpr.prototype.toJSReturn = function() {
    return new JSReturn(this);
}
JSExpr.prototype.toJSUntil = function() {
    return new JSDoWhile(new JSEmptyExpr, new JSNegate(this));
}

// JSExprNoReturn

function JSExprNoReturn() {}

JSExprNoReturn.prototype.__proto__ = JSExpr.prototype;
JSExprNoReturn.prototype.toJSReturn = function() {
    return this;
}

// JSEmptyExpr

function JSEmptyExpr() {}

JSEmptyExpr.prototype.__proto__ = JSExprNoReturn.prototype;

// JSNumber

function JSNumber(n) {
    this.num = n;
}

JSNumber.prototype.__proto__ = JSExpr.prototype;
JSNumber.prototype.toString = function() {
    return this.num.toString();
}

// JSCompound

function JSCompound(expr1, expr2) {
    this.expr1 = expr1;
    this.expr2 = expr2;
}

JSCompound.prototype.__proto__ = JSExpr.prototype;
JSCompound.prototype.toString = function() {
    if (this.expr1 instanceof JSAssignment) this.expr1.statement = true;
    if (this.expr2 instanceof JSAssignment) this.expr2.statement = true;
    return this.expr1.toString() + ';' + this.expr2.toString();
}
JSCompound.prototype.toJSReturn = function() {
    return new JSCompound(this.expr1, this.expr2.toJSReturn());
}
JSCompound.prototype.toJSUntil = function() {
    return new JSDoWhile(this.expr1, new JSNegate(this.expr2));
}

// JSVariable

function JSConvertVarName(name) {
    name = JSReservedNames[name] || name;
    return name.replace(/-(.)/g, function(match, chr) {return chr.toUpperCase();}).replace(/^(.)(.*)\?$/,
            function(match, chr, rest) {return 'is' + chr.toUpperCase() + rest;}).replace('!', '_type');
}
JSReservedNames = {
    "arguments": '_arguments'
}
function JSVariable(name) {
    this.topaz_name = name;
    this.name = JSConvertVarName(name);
}

JSVariable.prototype.__proto__ = JSExpr.prototype;
JSVariable.prototype.toString = function() {
    return this.name;
}
JSVariable.prototype.rememberFunction = function(nargs) {
    TFunctions[this.topaz_name] = TUserFuncCompiler(this.topaz_name, nargs);
}

// JSDot

function JSDot(expr, name) {
    this.expr = expr;
    this.name = JSConvertVarName(name);
}

JSDot.prototype.__proto__ = JSExpr.prototype;
JSDot.prototype.toString = function() {
    return this.expr.toString() + '.' + this.name;
}

// JSFunCall

function JSFunCall(expr, args) {
    this.funcExpr = expr;
    this.args     = args;
}

JSFunCall.prototype.__proto__ = JSExpr.prototype;
JSFunCall.prototype.toString = function() {
    var result = this.funcExpr.toString() + '(';
    if (this.args.length > 0) {
        result += this.args[0].toString();
        for (var i = 1; i < this.args.length; i++) {
            result += ',' + this.args[i].toString();
        }
    }
    result += ')';
    return result;
}

// JSString

function JSString(s) {
    this.str = s;
}

JSString.prototype.__proto__ = JSExpr.prototype;
JSString.prototype.toString = function() {
    return JSON.stringify(this.str);
}

// JSChar

function JSChar(c) {
    JSString.call(this, c);
}

JSChar.prototype.__proto__ = JSString.prototype;

// JSAssignment

function JSAssignment(expr1, expr2) {
    this.expr1 = expr1;
    this.expr2 = expr2;
    this.statement = false;
    // special case - remember it's a function
    if (expr1 instanceof JSVariable && expr2 instanceof JSFunDef) {
        expr1.rememberFunction(expr2.getNargs());
    }
}

JSAssignment.prototype.__proto__ = JSExpr.prototype;
JSAssignment.prototype.toString = function() {
    if (this.statement) {
        return this.expr1.toString() + '=' + this.expr2.toString();
    } else {
        return '(' + this.expr1.toString() + '=' + this.expr2.toString() + ')';
    }
}

// JSFunDef

function JSFunDef(args, locals, body) {
    this.args   = args;
    this.locals = locals;
    this.body   = body;
}

JSFunDef.prototype.__proto__ = JSExpr.prototype;
JSFunDef.prototype.toString = function() {
    var res = 'function(';
    if (this.args.length > 0) {
        res += this.args[0];
        for (var i = 1; i < this.args.length; i++) {
            res += ',' + this.args[i];
        }
    }
    res += '){';
    if (this.locals.length > 0) {
        res += 'var ' + this.locals[0];
        for (var i = 1; i < this.locals.length; i++) {
            res += ',' + this.locals[i];
        }
        res += ';';
    }
    return res + this.body.toString() + '}';
}
JSFunDef.prototype.getNargs = function() {
    return this.args.length;
}

// JSNull

function JSNull() {}

JSNull.prototype.__proto__ = JSExpr.prototype;
JSNull.prototype.toString = function() {
    return 'null';
}

// JSTrue

function JSTrue() {}

JSTrue.prototype.__proto__ = JSExpr.prototype;
JSTrue.prototype.toString = function() {
    return 'true';
}

// JSFalse

function JSFalse() {}

JSFalse.prototype.__proto__ = JSExpr.prototype;
JSFalse.prototype.toString = function() {
    return 'false';
}

// JSThrow

function JSThrow(expr) {
    this.expr = expr;
}

JSThrow.prototype.__proto__ = JSExprNoReturn.prototype;
JSThrow.prototype.toString = function() {
    return 'throw ' + this.expr.toString();
}

// JSOp

function JSOp(name, expr1, expr2) {
    this.name  = name;
    this.expr1 = expr1;
    this.expr2 = expr2;
}

JSOp.prototype.__proto__ = JSExpr.prototype;
JSOp.prototype.toString = function() {
    return '(' + this.expr1.toString() + this.name + this.expr2.toString() + ')';
}

// JSMultiAssignment

function JSMultiAssignment(vars, expr) {
    if (vars.length < 2) throw 'MultiAssignment with less than 2 vars?';
    this.vars = vars;
    this.expr = expr;
}

JSMultiAssignment.prototype.__proto__ = JSExpr.prototype;
JSMultiAssignment.prototype.toString = function() {
    var res = 'var _tmp=' + this.expr.toString() + ';' + this.vars[0] + '=_tmp[0]';
    for (var i = 1; i < this.vars.length; i++) {
        res += ';' + this.vars[i] + '=_tmp[' + i + ']';
    }
    return res;
}
JSMultiAssignment.prototype.toJSReturn = function() {
    return new JSCompound(this, new JSReturn(new JSVariable('_tmp')));
}

// JSIfElse

function JSIfElse(cond, truebody, falsebody) {
    this.cond      = cond;
    this.truebody  = truebody;
    this.falsebody = falsebody;
}

JSIfElse.prototype.__proto__ = JSExpr.prototype;
JSIfElse.prototype.toString = function() {
    var res = 'if(' + this.cond.toString() + '){' + this.truebody.toString() + '}';
    if (this.falsebody) res += 'else{' + this.falsebody.toString() + '}';
    return res;
}
JSIfElse.prototype.toJSReturn = function() {
    return new JSIfElse(this.cond, this.truebody.toJSReturn(),
            (this.falsebody && this.falsebody.toJSReturn()) || new JSStatement(new JSReturn(new JSNull())));
}

// JSWhile

function JSWhile(cond, body) {
    this.cond = cond;
    this.body = body;
}

JSWhile.prototype.__proto__ = JSExpr.prototype;
JSWhile.prototype.toString = function() {
    return 'while(' + this.cond.toString() + '){' + this.body.toString() + '}';
}
JSWhile.prototype.toJSReturn = function() {
    throw 'Problem: toJSReturn on JSWhile';
}

// JSNegate

function JSNegate(expr) {
    this.expr = expr;
}

JSNegate.prototype.__proto__ = JSExpr.prototype;
JSNegate.prototype.toString = function() {
    if (this.expr instanceof JSNegate) {
        return this.expr.expr.toString();
    } else {
        return '!' + this.expr.toString();
    }
}

// JSPick

function JSPick(expr, index) {
    this.expr  = expr;
    this.index = index;
}

JSPick.prototype.__proto__ = JSExpr.prototype;
JSPick.prototype.toString = function() {
    return this.expr.toString() + '[' + this.index.toString() + ']';
}

// JSStatement

function JSStatement(expr) {
    this.expr = expr;
    if (expr instanceof JSAssignment) expr.statement = true;
}

JSStatement.prototype.__proto__ = JSExpr.prototype;
JSStatement.prototype.toString = function() {
    return this.expr.toString() + ';';
}
JSStatement.prototype.toJSReturn = function() {
    return new JSStatement(this.expr.toJSReturn());
}
JSStatement.prototype.toJSUntil = function() {
    return new JSStatement(this.expr.toJSUntil());
}

// JSReturn

function JSReturn(expr) {
    this.expr = expr;
    if (expr instanceof JSAssignment) expr.statement = false;
}

JSReturn.prototype.__proto__ = JSExprNoReturn.prototype; // oh the irony
JSReturn.prototype.toString = function() {
    return 'return ' + this.expr.toString();
}

// JSDummy

function JSDummy(value) {
    this.value = value;
}

JSDummy.prototype.__proto__ = JSExprNoReturn.prototype;
JSDummy.prototype.toString = function() {
    throw 'Internal error - this should not happen. (toString() on JSDummy)';
}

// JSArray

function JSArray(exprs) {
    this.exprs = exprs;
}

JSArray.prototype.__proto__ = JSExpr.prototype;
JSArray.prototype.toString = function() {
    var res = '[';
    if (this.exprs.length > 0) {
        res += this.exprs[0].toString();
    }
    for (var i = 1; i < this.exprs.length; i++) {
        res += ',' + this.exprs[i].toString();
    }
    res += ']';
    return res;
}

// JSObject

function JSObject(struct) {
    this.struct = struct;
}

JSObject.prototype.__proto__ = JSExpr.prototype;
JSObject.prototype.toString = function() {
    var res = '{', keys = Object.keys(this.struct);
    if (keys.length > 0) {
        res += JSConvertVarName(keys[0]) + ':' + this.struct[keys[0]].toString();
    }
    for (var i = 1; i < keys.length; i++) {
        res += ',' + JSConvertVarName(keys[i]) + ':' + this.struct[keys[i]].toString();
    }
    res += '}';
    return res;
}

// JSDoWhile

function JSDoWhile(body, cond) {
    this.cond = cond;
    this.body = body;
}

JSDoWhile.prototype.__proto__ = JSExpr.prototype;
JSDoWhile.prototype.toString = function() {
    return 'do{' + this.body.toString() + '}while(' + this.cond.toString() + ')';
}
JSDoWhile.prototype.toJSReturn = function() {
    throw 'Problem: toJSReturn on JSDoWhile';
}

// JSRegExp

function JSRegExp(re) {
    this.re = re;
}

JSRegExp.prototype.__proto__ = JSExpr.prototype;
JSRegExp.prototype.toString = function() {
    return '/' + this.re + '/';
}

// TTextCursor (because regular expressions suck)

function TTextCursor(text) {
    this.text = text;
}

TTextCursor.prototype.isTail = function() {
    return this.text.length == 0;
}
TTextCursor.prototype.toString = function() {
    return this.text;
}
TTextCursor.prototype.skipSpaces = function() {
    var spaces = /^\s+/g;
    spaces.lastIndex = 0;
    if (spaces.test(this.text)) {
        this.skip(spaces.lastIndex);
    }
}
TTextCursor.prototype.skip = function(n) {
    this.text = this.text.substr(n);
    return this;
}
TTextCursor.prototype.match = function(re) {
    return re.test(this.text);
}
TTextCursor.prototype.matchAndSkip = function(re, item) {
    var match = re.exec(this.text);
    if (match) {
        this.skip(match[0].length);
        return match[item || 0];
    } else {
        return null;
    }
}


// tests

var sys = require('sys'), stdin = process.openStdin(), fs = require('fs');
stdin.setEncoding('utf8');
sys.puts('Topaz Bootstrap Compiler test prompt. Type "quit" to exit.');
stdin.addListener('data', function(chunk) {
        var res;
        if (chunk == 'quit\n') stdin.destroy();
        else if (res = /^compile (.*)\n$/.exec(chunk)) {
            res = res[1];
            try {
                sys.print('** Compiling ' + res + ' **\n');
                sys.print('===========================\n' + Topaz2JS(fs.readFileSync(res, 'utf8')) +
                    '\n===========================\n>> ');
            } catch (e) {
                sys.print('ERROR: ' + e + '\n>> ');
            }
        } else {
            try {
                sys.print('== ' + Topaz2JS(chunk) + '\n>> ');
            } catch (e) {
                sys.print('ERROR: ' + e + '\n>> ');
            }
        }
    });
sys.print('>> ');
