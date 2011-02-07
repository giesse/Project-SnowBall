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
    throw 'Parse error: ' + text_cursor.toString();
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
    while (!text_cursor.isTail() && !text_cursor.match(/^]/)) {
        if (parsed = TParseValue(text_cursor)) {
            text_cursor.skipSpaces();
            values.append(parsed);
        } else {
            TParseError(text_cursor);
        }
    }
    return values;
}

function TParseValue(text_cursor) {
    return TParseNumber(text_cursor) ||
        TParseWord(text_cursor) ||
        TParseLitWord(text_cursor) ||
        TParseString(text_cursor) ||
        TParseBlock(text_cursor);
}

function TParseNumber(text_cursor) {
    var match = text_cursor.matchAndSkip(/^[-+]?[0-9]+(\.[0-9]*)?([Ee][+-]?[0-9]{1,3})?/);
    return match && new TNumber(parseFloat(match));
}

function TParseWord(text_cursor) {
    var match = TParseWordChars(text_cursor);
    return match && new TWord(match);
}

function TParseWordChars(text_cursor) {
    return text_cursor.matchAndSkip(/^[!&*+\-.<=>?A-Z^_`a-z|~-ÿ]['!&*+\-.0-9<=>?A-Z^_`a-z|~-ÿ]*/);
}

function TParseLitWord(text_cursor) {
    var match;
    return text_cursor.matchAndSkip(/^'/) && (match = TParseWordChars(text_cursor)) && new TLitWord(match);
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

function TParseBlock(text_cursor) {
    if (text_cursor.matchAndSkip(/^\[/)) {
        var values = TParseValues(text_cursor);
        if (!text_cursor.matchAndSkip(/^]/)) {
            throw 'Missing ]: ' + text_cursor.toString();
        }
        return values;
    } else return null;
}

function TCompile(block) {
    if (block.isEmpty())
        return new JSEmptyExpr();
    else {
        var compiled = block.first().compile(block), expr = compiled.expr;
        block = compiled.next;
        while (!block.isEmpty()) {
            compiled = block.first().compile(block);
            expr = new JSCompound(expr, compiled.expr);
            block = compiled.next;
        }
        return new JSCompound(expr, new JSEmptyExpr());
    }
}

// TValue

function TValue() {}

TValue.prototype.typename = '*this should not happen*';

function TInternalError(action) {
    return function() {
        throw 'Internal error - this should not happen. (' + action + ' on a ' + this.typename + ' value)';
    };
}

TValue.prototype.compile = TInternalError('compile()');
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

TBlock.prototype = new TValue;
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

// TNumber

function TNumber(n) {
    this.num = n;
}

TNumber.prototype = new TValue;
TNumber.prototype.typename = 'number!';
TNumber.prototype.compile = function(block) {
    return {expr: new JSNumber(this.num), next: block.next()};
}

// TString

function TString(s) {
    this.str = s;
}

TString.prototype = new TValue;
TString.prototype.typename = 'string!';
TString.prototype.compile = function(block) {
    return {expr: new JSString(this.str), next: block.next()};
}

// TWord

function TWord(w) {
    this.word = w.toLowerCase();
}

TWord.prototype = new TValue;
TWord.prototype.typename = 'word!';
TWord.prototype.compile = function(block) {
    var f = TFunctions[this.word];
    return f ? f(block.next()) : {expr: new JSGetVariable(this.word), next: block.next()};
}

// TLitWord

function TLitWord(w) {
    this.word = w.toLowerCase();
}

TLitWord.prototype = new TValue;
TLitWord.prototype.typename = 'lit-word!';

// TFunctions

TFunctions = {
    print: function(block) {
        if (block.isEmpty()) {
            throw 'PRINT is missing its argument';
        }
        var compiled = block.first().compile(block);
        return {
            expr: new JSFunCall(new JSDot(new JSGetVariable('sys'), 'print'), compiled.expr),
            next: compiled.next
        }
    }
};

// JSEmptyExpr

function JSEmptyExpr() {}

JSEmptyExpr.prototype.toString = function() {
    return '';
}

// JSNumber

function JSNumber(n) {
    this.num = n;
}

JSNumber.prototype.toString = function() {
    return this.num.toString();
}

// JSCompound

function JSCompound(expr1, expr2) {
    this.expr1 = expr1;
    this.expr2 = expr2;
}

JSCompound.prototype.toString = function() {
    return this.expr1.toString() + ';' + this.expr2.toString();
}

// JSGetVariable

function JSGetVariable(name) {
    this.name = name;
}

JSGetVariable.prototype.toString = function() {
    return this.name;
}

// JSDot

function JSDot(expr, name) {
    this.expr = expr;
    this.name = name;
}

JSDot.prototype.toString = function() {
    return this.expr.toString() + '.' + this.name;
}

// JSFunCall

function JSFunCall(expr /* , ... */) {
    this.funcExpr = expr;
    this.args     = Array.prototype.slice.call(arguments, 1);
}

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

JSString.prototype.toString = function() {
    return JSON.stringify(this.str);
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
    var spaces = /^\s*/g;
    spaces.test(this.text);
    this.skip(spaces.lastIndex);
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

sys = require('sys');
code = 'print "hello world"';
try {
    sys.print('>> ' + code + '\n== ' + Topaz2JS(code) + '\n');
} catch (e) {
    sys.print('ERROR: ' + e + '\n');
}
