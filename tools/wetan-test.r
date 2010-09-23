#!/path/to/rebview -qws
REBOL [
Title: {Weave + Tangle - Literate programming with MakeDoc3} 
Version: 0.0.1 
Author: "Gabriele Santilli" 
File: %weave-tangle.r 
Date: 2-Mar-2006
] 
context [
action: [lit-word! | paren! | 'none] 
commands: [
some [
set arg1 lit-word! (arg1: reduce [arg1]) any ['or set arg2 lit-word! (append arg1 arg2)] 
(arg2: none) opt ['options set arg2 ['text | 'rebol]] 
set arg3 opt paren! 
(emit-command arg1 arg2 arg3)
]
] 
emit: func [value] [insert tail scanner-rules value] 
emit-block: func [value block] [insert/only insert tail scanner-rules value block] 
emit-strings: func [strings] [
while [not tail? next strings] [strings: insert next strings '|] 
insert/only tail scanner-rules head strings
] 
emit-action: func [action /with value] [
if 'none = :action [exit] 
value: any [value 'text] 
if word? :action [
action: make paren! compose [emit (action) (value)]
] 
insert/only tail scanner-rules action
] 
emit-cmd-inout: func [words opts action] [
action: any [
action 
make paren! compose [emit (to word! join last words "-in") (select [text [text] rebol [attempt [to block! text]]] opts)]
] 
until [
words/1: form words/1 
words: next words 
any [tail? words (words: insert words '| false)]
] 
words: head words 
insert insert/only insert insert/only tail cmd-in-block words either opts ['text-line] [[]] action '| 
insert insert/only insert/only tail cmd-out-block words make paren! compose [emit (to word! join last words "-out") none] '|
] 
emit-cmd: func [words opts action] [
action: any [action make paren! compose [emit (last words) (select [text [text] rebol [attempt [to block! text]]] opts)]] 
until [
words/1: form words/1 
words: next words 
any [tail? words (words: insert words '| false)]
] 
words: head words 
insert insert/only insert insert/only tail cmd-in-block words either opts ['text-line] [[]] action '|
] 
emit-quote: func [quote word] [
if not empty? quotes [insert tail quotes '|] 
insert tail quotes compose/deep [
(quote) 
some [
esc copy inchars skip (make paren! reduce ['inline-emit word 'inchars]) 
| 
copy inchars some wordchars (make paren! reduce ['inline-emit word 'inchars])
] 
copy inchars any nochar ([(inline-emit normal inchars)])
]
] 
emit-special: func [spec word] [
if not empty? specials [insert tail specials '|] 
insert tail specials compose/deep [
(spec) some [
esc copy inchars [skip any (complement charset reduce [first spec first esc])] (make paren! reduce ['inline-emit word 'inchars])
| 
(spec) [copy inchars [some nowchar any openchars] ([(inline-emit normal inchars)]) | end] break 
| 
copy inchars [chars any (complement charset reduce [first spec first esc])] (make paren! reduce ['inline-emit word 'inchars])
]
]
] 
definition: [
copy arg1 some string! [
'end (emit-strings arg1 emit [to end (emit end none) |]) 
| 
'line set arg2 action (emit-strings arg1 emit 'text-line emit-action arg2 emit '|) 
| 
'block set arg2 action (emit-strings arg1 emit 'text-block emit-action arg2 emit '|) 
| 
'define set arg2 string! ['line (arg3: 'text-line) | 'block (arg3: 'text-block)] set arg4 action (
emit-strings arg1 
emit compose [copy define to (arg2) (arg2) (arg3)] 
emit-action/with arg4 [reduce [scan-inline define scan-inline text]] 
emit '|
)
] 
| 
'default set default-action action 
| 
'unrecognized set unrec-action action 
| 
'indented set example-action action 
| 
'output set arg1 string! (
emit compose/deep [
(arg1) some space copy code thru newline 
any [(arg1) some space copy text thru newline ([(append code text)])] 
([(emit output trim/auto code)]) |
]
) 
| 
'sections 'in set arg1 string! 'out set arg2 string! (
emit-block arg1 cmd-in-block: make block! 16 emit '| 
emit-block arg2 cmd-out-block: make block! 16 emit '| 
emit-command: :emit-cmd-inout
) into commands (remove back tail cmd-in-block remove back tail cmd-out-block) 
| 
'commands set arg1 string! (
emit-block arg1 cmd-in-block: make block! 16 emit '| 
emit-command: :emit-cmd
) into commands (remove back tail cmd-in-block) 
| 
'verbatim copy verbatim some lit-word! (verbatim: reduce any [verbatim []]) 
| 
'inline into [
some [
'escape set esc string! 
| 
'quote set arg1 string! set arg2 lit-word! (emit-quote arg1 arg2) 
| 
set arg1 string! set arg2 lit-word! (emit-special arg1 arg2) 
| 
'rebol set rebol-in string! set rebol-out string!
]
]
] 
arg1: arg2: arg3: arg4: default-action: unrec-action: example-action: 
cmd-in-block: cmd-out-block: verbatim: esc: rebol-in: rebol-out: none 
rule: [some definition] 
scanner-rules: [] 
quotes: [] 
specials: [] 
scanner!: context [
syntax: [] 
verbose: no 
debug: func [data] [if verbose [print data]] 
text: none 
code: none 
define: none 
out: [] 
title: none 
verbatim: [] 
rules: [some [here: (debug mold copy/part here 256) commands]] 
commands: [] 
space: charset " ^-" 
nochar: charset " ^-^/" 
chars: complement nochar 
spaces: [any space] 
text-line: [any space copy text thru newline] 
text-block: [any space paragraph opt newline] 
paragraph: [copy text some [chars thru newline]] 
example: [copy text some [indented | some newline indented]] 
indented: [some space chars thru newline any [some space newline]] 
emit: func ['word data] [
debug ["===EMIT: " word mold data] 
if string? data [trim/tail data] 
if not any [find verbatim word word = 'output] [data: scan-inline data]
repend out [word data]
] 
nowchar: union nochar charset {!"')?-,.;:} 
nochar+: union nochar openchars: charset {"'(}
inline-out: [] 
inline-emit: func ['word text] [
either word = pick tail inline-out -2 [
append last inline-out text
] [
insert insert tail inline-out word text
]
] 
fix-rebol: does [
change/only back tail inline-out attempt [to block! pick tail inline-out -1]
] 
inline-rules: [some wstart] 
inchars: none 
wstart: [
esc copy inchars [skip any wordchars any nochar] (inline-emit normal inchars) 
| 
rebol-in some [
esc copy inchars skip (inline-emit rebol inchars) 
| 
rebol-out (inline-emit rebol "" fix-rebol) opt [copy inchars some nochar (inline-emit normal inchars)] break 
| 
copy inchars some rebchars (inline-emit rebol inchars)
] 
| 
quotes 
| 
specials 
| 
copy inchars [some wordchars any nochar+] (inline-emit normal inchars)
] 
esc: "\" 
rebol-in: "=[" 
rebol-out: "]" 
rebchars: complement charset reduce [first rebol-in first esc] 
wordchars: complement charset reduce [first esc " ^-^/"] 
quotes: [] 
specials: [] 
scan-inline: func [data] [
either string? data [
clear inline-out 
parse/all data inline-rules 
copy inline-out
] [
:data
]
] 
scan-doc: func [str /options block] [
clear out 
title: none 
init-scanner 
opts: make block! 16 
emit options opts 
parse/all detab str rules 
copy out
] 
init-scanner: none
] 
pretty-print: func [parse-block /local] [
new-line/all parse-block off 
if 4 > length? parse-block [exit] 
new-line parse-block on 
parse parse-block [
any [
local: '| (new-line next local on) | 
block! (pretty-print local/1) | 
skip
]
]
] 
set 'make-scanner 
func [code /local r loc] [
code: make scanner! code 
clear scanner-rules 
clear quotes 
clear specials 
verbatim: [] 
esc: "\" 
rebol-in: "=[" 
rebol-out: "]" 
emit [newline |] 
parse code/syntax rule 
emit 'example emit-action example-action 
emit [| paragraph] emit-action default-action 
emit [| skip] emit-action unrec-action 
code/commands: bind/copy scanner-rules code 
code/verbatim: verbatim 
code/esc: esc 
code/rebol-in: rebol-in 
code/rebol-out: rebol-out 
code/rebchars: complement charset reduce [first rebol-in first esc first rebol-out] 
code/wordchars: complement charset reduce [first esc " ^-^/"] 
code/quotes: bind/copy quotes code 
code/specials: bind/copy specials code 
parse code/specials r: [
any [
loc: bitset! (loc/1: exclude loc/1 charset reduce [first esc]) 
| 
into r 
| 
skip
]
] 
code
]
] 
{==============================================================================
=1 The stack-based finite state machine interpreter
This script implements an interpreter for stack-based finite state machines. The FSMs are defined by a simple dialect where each state is a =font[face: Arial black bold] REBOL = block. The interpreter is defined as an object.
The grammar for a state block is:
=example
state: [some event-directive]
event-directive: [
    handled-events opt action [
        ; make another state handle this event (must be followed by a state change directive)
        'continue
        |
        ; override event and make a new state handle it (must be followed by a state change directive)
        'override word!
        |
        none
    ] [
        ; return to previous state
        'return
        |
        ; attempt to rewind the state stack up to one of the specified states;
        ; each state is attempted in the given order; ignored if
        ; none of the given states is not on the stack.
        'rewind? some word!
        |
        ; go to a new state. a return action can be defined too
        word! opt return-action
        |
        ; continue or override not followed by a state change are ignored
        none
    ]
]
handled-events: [any [any-string! | set-word!]]
action: paren!
return-action: paren!
=example.
The =font[face: Trebuchet MS italic color: blue] default: = event can be used to catch any event not defined in the state block. Please refer to the =i QML = emitters for examples of state definitions.
The interpreter object contains the following functions:
===============================================================================} 
fsm!: context [
initial: state: none 
state-stack: [] 
goto-state: 
func [new-state [block!] retact [paren! none!]] [
insert/only insert/only state-stack: tail state-stack :state :retact 
state: new-state
] 
return-state: 
has [retact [paren! none!]] [
set [state retact] state-stack 
state: any [state initial] 
do retact 
state-stack: skip clear state-stack -2
] 
rewind-state: 
func [up-to [block!] /local retact stack] [
if empty? state-stack [return false] 
stack: tail state-stack 
retact: make block! 128 
until [
stack: skip stack -2 
append retact stack/2 
if same? up-to stack/1 [
state: up-to 
do retact 
state-stack: skip clear stack -2 
return true
] 
head? stack
] 
false
] 
{==============================================================================
=: =font[face: Trebuchet MS italic color: blue] event [evt]=font.
Processes one event with the current state. The state machine must be initialized before starting to process events.
===============================================================================} 
event: 
func [evt /local val ovr retact done?] [
if not block? state [exit] 
until [
done?: yes 
local: any [find state evt find state [default:]] 
if local [
parse local [
any [any-string! | set-word!] 
set val opt paren! (do val) [
'continue (done?: no) 
| 
'override set ovr word! (evt: to set-word! ovr done?: no) 
| 
none
] [
'return (return-state) 
| 
'rewind? copy val some word! (
if not foreach word val [
if block? get/any word [
if rewind-state get word [break/return true]
] 
false
] [
done?: yes
]
) 
| 
set val word! set retact opt paren! (
if block? get/any val [goto-state get val :retact]
) 
| 
none (done?: yes)
]
]
] 
done?
]
] 
{==============================================================================
=: =font[face: Trebuchet MS italic color: blue] init [initial-state [block!]]=font.
Initializes the state machine. You need to call this function first.
===============================================================================} 
init: 
func [initial-state [block!]] [
clear state-stack: head state-stack 
initial: state: initial-state
] 
{==============================================================================
=: =font[face: Trebuchet MS italic color: blue] end=font.
Terminates processing. Gets the state machine back to the initial state and stops it. Note that you must call =font[face: Trebuchet MS italic bold color: blue] init = again if you intend to reuse the state machine.
=:.
===============================================================================} 
end: 
does [
foreach [retact state] head reverse head state-stack [do retact]
]
] 
context [
emitter!: context [
initial: [] 
inline: [] 
out: "" 
data: word: none 
emit-inline: func [data' /local] [
if not block? :data' [emit :data exit] 
foreach [word txt] data' [
data: txt 
local: find inline to set-word! word 
either local [
parse local [any set-word! set val paren! (do val)]
] [
emit txt
]
]
] 
capture: func [code /local saveout] [
saveout: out 
local: out: make string! 256 
do code 
out: saveout 
local
] 
inherit: func [parent-state new-directives] [
append new-directives parent-state
] 
emit: func [value] [
insert tail out reduce value
] 
fsm: make fsm! [] 
fsm-do: func [doc [block!] state [block!]] [
fsm/init state 
forskip doc 2 [
set [word data] doc 
fsm/event to set-word! word
] 
fsm/end
] 
generate: func [doc [block!]] [
clear out 
init-emitter doc 
fsm-do doc initial 
build-doc out
] 
error: func [msg] [print ["Emitter error:" msg]] 
init-emitter: none 
build-doc: func [text] [copy text]
] 
set 'make-emitter 
func [code [block!]] [
make emitter! code
]
] 
default-scanner: make-scanner [
syntax: [
"###" end 
default (either title [emit para text] [emit title title: text]) 
unrecognized (debug "???WARN: Unrecognized") 
"===" "-1-" line 'sect1 
"---" "-2-" line 'sect2 
"+++" "-3-" line 'sect3 
"..." "-4-" line 'sect4 
"***" "*>>" block 'bullet3 
"**" "*>" block 'bullet2 
"*" block 'bullet 
"#>>" block 'enum3 
"#>" block 'enum2 
"#" block 'enum 
":" define " -" block 'define 
";" block none 
indented 'code 
output "==" 
sections in "\" out "/" [
'in or 'indent 
'note options text 
'table options text 
'group 
'center 
'column
] 
commands "=" [
'image options rebol 
'row or 'table-row 
'column 
'options options rebol (attempt [append opts to block! text]) 
'template options text (repend opts ['template as-file text]) 
'tangle options rebol
] 
verbatim 'code 
inline [
escape "\" 
quote "'" 'word 
"**" 'strong 
"*" 'emph 
"|" 'code 
rebol "=[" "]"
]
]
] 
wetan-emitter: make-emitter [
    emit-sect: func [level str /local sn] [
        sn: next-section level
        emit [{<h} level + 1 { id="section-} sn {">} sn pick [". " " "] level = 1]
        emit-inline str
        emit [{</h} level + 1 {>}]
    ]
code-sections: [] 
code-section!: context [
visited: no 
code: title: id: none
] 
header: none 
init-emitter: func [doc [block!]] [
clear code-sections 
clear-sects 
toc: capture [
emit [<div id="toc"> <h2> "Contents:" </h2> <ul>] 
fsm-do doc first-pass 
emit [</ul></div>]
] 
clear-sects
] 
toc: none 
title: none 
last-section-title: last-section-id: none 
first-pass: [
title: sect1: (title: capture [emit-inline data]) in-header 
options: () 
default: (title: "Untitled") continue in-header
] 
header: none 
header-template: context [
Title: "Untitled" 
File: %output.r
] 
in-header: [
code: (preprocess-header data) fp-normal 
options: () 
default: (header: make header-template []) continue fp-normal
] 
preprocess-header: func [text [string!]] [
header: attempt [to block! text] 
header: construct/with any [header []] header-template 
header/title: title
] 
fp-normal: [
code: (preprocess-code-section data) 
sect1: (set-last-section/emit 1 data) 
sect2: (emit <ul>) continue toc2 (emit </ul>) 
sect3: (set-last-section 3 data) 
sect4: (set-last-section 4 data)
] 
preprocess-code-section: func [code [string!] /local 
name section-data
] [
code: attempt [load/all code] 
if code [
parse code [[set name set-word! | (name: none)] code:] 
if name [
name: to word! name 
either section-data: select code-sections name [
append section-data/code code
] [
insert/only insert tail code-sections name section-data: make code-section! [
title: last-section-title 
id: last-section-id
] 
section-data/code: code
]
]
]
] 
toc2: inherit fp-normal [
sect1: continue return 
sect2: (set-last-section/emit 2 data)
] 
set-last-section: func [level data /emit] [
last-section-title: capture [emit-inline copy/deep data] 
last-section-id: either emit [emit-toc-item level last-section-title] [join "section-" next-section level]
] 
emit-toc-item: func [level title /local num] [
num: next-section level 
emit [<li> {<a href="#section-} num {">} num pick [". " " "] level = 1 title </a> </li>] 
join "section-" num
] 
initial: [
title: sect1: (emit-header) discard-header 
code: (emit-header) normal 
options: () 
default: (emit-header) continue normal
] 
discard-header: [
code: normal 
options: () 
default: continue normal
] 
inline: [
normal: (emit escape-html data) 
word: (format-code data) 
strong: (emit [<strong> escape-html data </strong>]) 
emph: (emit [<em> escape-html data </em>]) 
rebol: (process-rebol data) 
code: (format-code data)
] 
process-rebol: func [block] [
emit "[Not yet implemented]"
] 
tabs: [4 " " (emit {<span class="tab">&nbsp;</span>})] 
val: none 
rebol-code: [
any " " some [
newline (emit <br />) break 
| 
copy val [";" [to newline | to end]] (if val [emit [<span class="comment"> escape-html val </span>]]) 
opt [newline (emit <br />)] break 
| 
copy val ["[" | "#[" | "(" | ")" | "]"] (emit val) opt [some " " (emit " ")] 
| 
rebol-value opt [some " " (emit " ")]
]
] 
here: none 
rebol-value: [["#lit " | "#literal "] here: skip (set [val here] load/next here emit-value :val) :here 
| 
"#include " here: skip (set [val here] load/next here emit-include :val) :here 
| 
here: skip (set [val here] load/next here emit-value :val) :here
] 
emit-value: func [value /local 
special
] [
either special: in type-emitters type?/word :value [
do get special :value
] [
emit [{<span class="} form type? :value {">} escape-html mold :value </span>]
]
] 
emit-include: func [dest /local 
target
] [
either any [file? :dest url? :dest] [
target: copy dest 
if file? target [
either target: find/last target %. [
target: head change/part next target %html tail target
] [
target: join target %.html
] 
if not exists? target [target: dest]
] 
emit [
<span class="directive"> "#include " 
{<a href="} escape-html target {">}
] 
emit-value dest 
emit "</a></span>"
] [
emit [
<span class="include-error"> "Cannot use " 
<span class="directive"> "#include" </span> 
" with the value "
] 
emit-value mold :dest 
emit "!</span>"
]
] 
type-emitters: context [
word!: func [value /local section-data subclass title] [
if section-data: select code-sections value [
emit [
<span class="ref"> 
<span class="bra"> "&#9001;" </span> 
{<a href="#} section-data/id {">} 
section-data/title 
</a> 
<span class="bra"> "&#9002;" </span> 
</span>
] 
exit
] 
either set [subclass title] select keywords value [
subclass: join " " subclass 
title: rejoin [{title="} escape-html title {"}]
] [
subclass: title: ""
] 
emit [{<span class="word} subclass {"} title ">" escape-html mold value </span>]
] 
path!: func [value] [
emit <span class="path"> 
emit-value first value 
foreach element next value [
emit "/" 
emit-value element
] 
emit </span>
]
] 
keywords: [end! ["datatype" ""] unset! ["datatype" ""] error! ["datatype" ""] datatype! ["datatype" ""] native! ["datatype" ""] action! ["datatype" ""] routine! ["datatype" ""] op! ["datatype" ""] function! ["datatype" ""] object! ["datatype" ""] struct! ["datatype" ""] library! ["datatype" ""] port! ["datatype" ""] any-type! ["datatype" ""] any-word! ["datatype" ""] any-function! ["datatype" ""] number! ["datatype" ""] series! ["datatype" ""] any-string! ["datatype" ""] any-block! ["datatype" ""] symbol! ["datatype" ""] word! ["datatype" ""] set-word! ["datatype" ""] get-word! ["datatype" ""] lit-word! ["datatype" ""] refinement! ["datatype" ""] none! ["datatype" ""] logic! ["datatype" ""] integer! ["datatype" ""] decimal! ["datatype" ""] money! ["datatype" ""] time! ["datatype" ""] date! ["datatype" ""] char! ["datatype" ""] pair! ["datatype" ""] event! ["datatype" ""] tuple! ["datatype" ""] bitset! ["datatype" ""] string! ["datatype" ""] issue! ["datatype" ""] binary! ["datatype" ""] file! ["datatype" ""] email! ["datatype" ""] url! ["datatype" ""] tag! ["datatype" ""] image! ["datatype" ""] block! ["datatype" ""] paren! ["datatype" ""] path! ["datatype" ""] set-path! ["datatype" ""] lit-path! ["datatype" ""] hash! ["datatype" ""] list! ["datatype" ""] unset? ["key" "UNSET? value"] error? ["key" "ERROR? value"] datatype? ["key" "DATATYPE? value"] native? ["key" "NATIVE? value"] action? ["key" "ACTION? value"] routine? ["key" "ROUTINE? value"] op? ["key" "OP? value"] function? ["key" "FUNCTION? value"] object? ["key" "OBJECT? value"] struct? ["key" "STRUCT? value"] library? ["key" "LIBRARY? value"] port? ["key" "PORT? value"] any-type? ["key" "ANY-TYPE? value"] any-word? ["key" "ANY-WORD? value"] any-function? ["key" "ANY-FUNCTION? value"] number? ["key" "NUMBER? value"] series? ["key" "SERIES? value"] any-string? ["key" "ANY-STRING? value"] any-block? ["key" "ANY-BLOCK? value"] word? ["key" "WORD? value"] set-word? ["key" "SET-WORD? value"] get-word? ["key" "GET-WORD? value"] lit-word? ["key" "LIT-WORD? value"] refinement? ["key" "REFINEMENT? value"] none? ["key" "NONE? value"] logic? ["key" "LOGIC? value"] integer? ["key" "INTEGER? value"] decimal? ["key" "DECIMAL? value"] money? ["key" "MONEY? value"] time? ["key" "TIME? value"] date? ["key" "DATE? value"] char? ["key" "CHAR? value"] pair? ["key" "PAIR? value"] event? ["key" "EVENT? value"] tuple? ["key" "TUPLE? value"] bitset? ["key" "BITSET? value"] string? ["key" "STRING? value"] issue? ["key" "ISSUE? value"] binary? ["key" "BINARY? value"] file? ["key" "FILE? value"] email? ["key" "EMAIL? value"] url? ["key" "URL? value"] tag? ["key" "TAG? value"] image? ["key" "IMAGE? value"] block? ["key" "BLOCK? value"] paren? ["key" "PAREN? value"] path? ["key" "PATH? value"] set-path? ["key" "SET-PATH? value"] lit-path? ["key" "LIT-PATH? value"] hash? ["key" "HASH? value"] list? ["key" "LIST? value"] + ["key" "+ value1 value2"] - ["key" "- value1 value2"] * ["key" "* value1 value2"] / ["key" "/ value1 value2"] // ["key" "// value1 value2"] ** ["key" "** number exponent"] and ["key" "AND value1 value2"] or ["key" "OR value1 value2"] xor ["key" "XOR value1 value2"] =? ["key" "=? value1 value2"] = ["key" "= value1 value2"] == ["key" "== value1 value2"] <> ["key" "<> value1 value2"] < ["key" "< value1 value2"] > ["key" "> value1 value2"] <= ["key" "<= value1 value2"] >= ["key" ">= value1 value2"] add ["key" "ADD value1 value2"] subtract ["key" "SUBTRACT value1 value2"] multiply ["key" "MULTIPLY value1 value2"] divide ["key" "DIVIDE value1 value2"] remainder ["key" "REMAINDER value1 value2"] power ["key" "POWER number exponent"] and~ ["key" "AND~ value1 value2"] or~ ["key" "OR~ value1 value2"] xor~ ["key" "XOR~ value1 value2"] same? ["key" "SAME? value1 value2"] equal? ["key" "EQUAL? value1 value2"] strict-equal? ["key" "STRICT-EQUAL? value1 value2"] not-equal? ["key" "NOT-EQUAL? value1 value2"] strict-not-equal? ["key" "STRICT-NOT-EQUAL? value1 value2"] greater? ["key" "GREATER? value1 value2"] lesser? ["key" "LESSER? value1 value2"] greater-or-equal? ["key" "GREATER-OR-EQUAL? value1 value2"] lesser-or-equal? ["key" "LESSER-OR-EQUAL? value1 value2"] minimum ["key" "MINIMUM value1 value2"] maximum ["key" "MAXIMUM value1 value2"] negate ["key" "NEGATE number"] complement ["key" "COMPLEMENT value"] absolute ["key" "ABSOLUTE value"] random ["key" "RANDOM value /seed /secure /only"] odd? ["key" "ODD? number"] even? ["key" "EVEN? number"] negative? ["key" "NEGATIVE? number"] positive? ["key" "POSITIVE? number"] zero? ["key" "ZERO? number"] head ["key" "HEAD series"] tail ["key" "TAIL series"] head? ["key" "HEAD? series"] tail? ["key" "TAIL? series"] next ["key" "NEXT series"] back ["key" "BACK series"] skip ["key" "SKIP series offset"] at ["key" "AT series index"] index? ["key" "INDEX? series /xy"] length? ["key" "LENGTH? series"] pick ["key" "PICK series index"] first ["key" "FIRST series"] second ["key" "SECOND series"] third ["key" "THIRD series"] fourth ["key" "FOURTH series"] fifth ["key" "FIFTH series"] sixth ["key" "SIXTH series"] seventh ["key" "SEVENTH series"] eighth ["key" "EIGHTH series"] ninth ["key" "NINTH series"] tenth ["key" "TENTH series"] last ["key" "LAST series"] path ["key" "PATH value selector"] find ["key" {FIND series value /part range /only /case /any /with wild /skip size /match /tail /last /reverse}] select ["key" {SELECT series value /part range /only /case /any /with wild /skip size}] make ["key" "MAKE type spec"] to ["key" "TO type spec"] copy ["key" "COPY value /part range /deep"] insert ["key" "INSERT series value /part range /only /dup count"] remove ["key" "REMOVE series /part range"] change ["key" "CHANGE series value /part range /only /dup count"] poke ["key" "POKE value index data"] clear ["key" "CLEAR series"] trim ["key" {TRIM series /head /tail /auto /lines /all /with str}] sort ["key" {SORT series /case /skip size /compare comparator /part length /all /reverse}] native ["key" "NATIVE spec"] alias ["key" "ALIAS word name"] all ["key" "ALL block"] any ["key" "ANY block"] as-string ["key" "AS-STRING string"] as-binary ["key" "AS-BINARY string"] bind ["key" "BIND words known-word /copy"] bind? ["key" "BIND? words"] break ["key" "BREAK /return value"] case ["key" "CASE block /all"] catch ["key" "CATCH block /name word"] checksum ["key" {CHECKSUM data /tcp /secure /hash size /method word /key key-value}] comment ["key" "COMMENT value"] debase ["key" "DEBASE value /base base-value"] dehex ["key" "DEHEX value"] exclude ["key" "EXCLUDE set1 set2 /case /skip size"] difference ["key" "DIFFERENCE set1 set2 /case /skip size"] disarm ["key" "DISARM error"] do ["key" "DO value /args arg /next"] either ["key" "EITHER condition true-block false-block"] else ["key" "ELSE "] enbase ["key" "ENBASE value /base base-value"] exit ["key" "EXIT "] foreach ["key" "FOREACH 'word data body"] remove-each ["key" "REMOVE-EACH 'word data body"] form ["key" "FORM value"] free ["key" "FREE value"] get ["key" "GET word /any"] get-env ["key" "GET-ENV var"] halt ["key" "HALT "] if ["key" "IF condition then-block /else else-block"] in ["key" "IN object word"] intersect ["key" "INTERSECT ser1 ser2 /case /skip size"] load ["key" "LOAD source /header /next /library /markup /all"] source ["key" "SOURCE 'word"] loop ["key" "LOOP count block"] minimum-of ["key" "MINIMUM-OF series /skip size /case"] maximum-of ["key" "MAXIMUM-OF series /skip size /case"] mold ["key" "MOLD value /only /all /flat"] new-line ["key" "NEW-LINE block value /all /skip size"] new-line? ["key" "NEW-LINE? block"] not ["key" "NOT value"] now ["key" {NOW /year /month /day /time /zone /date /weekday /yearday /precise}] parse ["key" "PARSE input rules /all /case"] input ["key" "INPUT /hide"] prin ["key" "PRIN value"] print ["key" "PRINT value"] quit ["key" "QUIT /return value"] recycle ["key" "RECYCLE /off /on /torture"] reduce ["key" "REDUCE value /only words"] compose ["key" "COMPOSE value /deep /only"] construct ["key" "CONSTRUCT block /with object"] repeat ["key" "REPEAT 'word value body"] return ["key" "RETURN value"] reverse ["key" "REVERSE value /part range"] save ["key" {SAVE where value /header header-data /bmp /png /all}] script? ["key" "SCRIPT? value"] set ["key" "SET word value /any /pad"] throw ["key" "THROW value /name word"] to-hex ["key" "TO-HEX value"] trace ["key" "TRACE mode /net /function"] try ["key" "TRY block"] type? ["key" "TYPE? value /word"] union ["key" "UNION set1 set2 /case /skip size"] unique ["key" "UNIQUE set /case /skip size"] unless ["key" "UNLESS condition block"] unprotect ["key" "UNPROTECT value"] unset ["key" "UNSET word"] until ["key" "UNTIL block"] use ["key" "USE words body"] value? ["key" "VALUE? value"] while ["key" "WHILE cond-block body-block"] compress ["key" "COMPRESS data"] decompress ["key" "DECOMPRESS data"] secure ["key" "SECURE 'level"] open ["key" {OPEN spec /binary /string /direct /seek /new /read /write /no-wait /lines /with end-of-line /allow access /mode args /custom params /skip length}] close ["key" "CLOSE port"] read ["key" {READ source /binary /string /direct /no-wait /lines /part size /with end-of-line /mode args /custom params /skip length}] read-io ["key" "READ-IO port buffer length"] write-io ["key" "WRITE-IO port buffer length"] write ["key" {WRITE destination value /binary /string /direct /append /no-wait /lines /part size /with end-of-line /allow access /mode args /custom params}] update ["key" "UPDATE port"] query ["key" "QUERY target /clear"] wait ["key" "WAIT value /all"] input? ["key" "INPUT? "] exp ["key" "EXP power"] log-10 ["key" "LOG-10 value"] log-2 ["key" "LOG-2 value"] log-e ["key" "LOG-E value"] square-root ["key" "SQUARE-ROOT value"] cosine ["key" "COSINE value /radians"] sine ["key" "SINE value /radians"] tangent ["key" "TANGENT value /radians"] arccosine ["key" "ARCCOSINE value /radians"] arcsine ["key" "ARCSINE value /radians"] arctangent ["key" "ARCTANGENT value /radians"] protect ["key" "PROTECT value"] lowercase ["key" "LOWERCASE string /part range"] uppercase ["key" "UPPERCASE string /part range"] entab ["key" "ENTAB string /size number"] detab ["key" "DETAB string /size number"] connected? ["key" "CONNECTED? "] browse ["key" "BROWSE value /only"] launch ["key" {LAUNCH value /reboot /uninstall /link url /quit /secure-cmd /as-is /install}] run ["key" "RUN file /as suffix"] stats ["key" {STATS /pools /types /series /frames /recycle /evals /clear}] get-modes ["key" "GET-MODES target modes"] set-modes ["key" "SET-MODES target modes"] to-local-file ["key" "TO-LOCAL-FILE path"] to-rebol-file ["key" "TO-REBOL-FILE path"] encloak ["key" "ENCLOAK data key /with"] decloak ["key" "DECLOAK data key /with"] do-browser ["key" "DO-BROWSER code"] license ["key" "LICENSE "] help ["key" "HELP 'word"] install ["key" "INSTALL "] echo ["key" "ECHO target"] Usage ["key" "USAGE "] view ["key" {VIEW view-face /new /offset xy /options opts /title text}] func ["key" "FUNC spec body"] link? ["key" "LINK? "] q ["key" "Q /return value"] min ["key" "MIN value1 value2"] max ["key" "MAX value1 value2"] abs ["key" "ABS value"] empty? ["key" "EMPTY? series"] throw-on-error ["key" "THROW-ON-ERROR blk"] function ["key" "FUNCTION spec vars body"] does ["key" "DOES body"] has ["key" "HAS locals body"] context ["key" "CONTEXT blk"] probe ["key" "PROBE value"] ?? ["key" "?? 'name"] sign? ["key" "SIGN? number"] as-pair ["key" "AS-PAIR x y"] mod ["key" "MOD a b"] modulo ["key" "MODULO a b"] round ["key" {ROUND n /even /down /half-down /floor /ceiling /half-ceiling /to scale}] found? ["key" "FOUND? value"] component? ["key" "COMPONENT? name"] repend ["key" "REPEND series value /only"] about ["key" "ABOUT "] set-net ["key" "SET-NET settings"] offset? ["key" "OFFSET? series1 series2"] append ["key" "APPEND series value /only"] join ["key" "JOIN value rest"] rejoin ["key" "REJOIN block"] reform ["key" "REFORM value"] remold ["key" "REMOLD value"] charset ["key" "CHARSET chars"] array ["key" "ARRAY size /initial value"] replace ["key" "REPLACE target search replace /all /case"] extract ["key" "EXTRACT block width /index pos"] forskip ["key" "FORSKIP 'word skip-num body"] alter ["key" "ALTER series value"] forall ["key" "FORALL 'word body"] for ["key" "FOR 'word start end bump body"] forever ["key" "FOREVER body"] switch ["key" "SWITCH value cases /default case"] dispatch ["key" "DISPATCH port-block"] attempt ["key" "ATTEMPT value"] info? ["key" "INFO? target"] exists? ["key" "EXISTS? target"] size? ["key" "SIZE? target"] modified? ["key" "MODIFIED? target"] dir? ["key" "DIR? target"] what-dir ["key" "WHAT-DIR "] change-dir ["key" "CHANGE-DIR dir"] clean-path ["key" "CLEAN-PATH target"] list-dir ["key" "LIST-DIR dir"] dirize ["key" "DIRIZE path"] rename ["key" "RENAME old new"] split-path ["key" "SPLIT-PATH target"] delete ["key" "DELETE target /any"] make-dir ["key" "MAKE-DIR path /deep"] delete-dir ["key" "DELETE-DIR dir"] suffix? ["key" "SUFFIX? path"] to-file ["key" "TO-FILE value"] hide ["key" "HIDE face /show"] to-char ["key" "TO-CHAR value"] ask ["key" "ASK question /hide"] confirm ["key" "CONFIRM question /with choices"] to-error ["key" "TO-ERROR value"] to-datatype ["key" "TO-DATATYPE value"] to-library ["key" "TO-LIBRARY value"] to-port ["key" "TO-PORT value"] to-word ["key" "TO-WORD value"] to-set-word ["key" "TO-SET-WORD value"] to-get-word ["key" "TO-GET-WORD value"] to-lit-word ["key" "TO-LIT-WORD value"] to-refinement ["key" "TO-REFINEMENT value"] to-none ["key" "TO-NONE value"] to-logic ["key" "TO-LOGIC value"] to-integer ["key" "TO-INTEGER value"] to-decimal ["key" "TO-DECIMAL value"] to-money ["key" "TO-MONEY value"] to-time ["key" "TO-TIME value"] to-date ["key" "TO-DATE value"] to-pair ["key" "TO-PAIR value"] to-tuple ["key" "TO-TUPLE value"] to-bitset ["key" "TO-BITSET value"] to-string ["key" "TO-STRING value"] to-issue ["key" "TO-ISSUE value"] to-binary ["key" "TO-BINARY value"] to-email ["key" "TO-EMAIL value"] to-url ["key" "TO-URL value"] to-tag ["key" "TO-TAG value"] to-image ["key" "TO-IMAGE value"] to-block ["key" "TO-BLOCK value"] to-paren ["key" "TO-PAREN value"] to-path ["key" "TO-PATH value"] to-set-path ["key" "TO-SET-PATH value"] to-lit-path ["key" "TO-LIT-PATH value"] to-hash ["key" "TO-HASH value"] to-list ["key" "TO-LIST value"] dump-obj ["key" "DUMP-OBJ obj /match pat"] ? ["key" "? 'word"] upgrade ["key" "UPGRADE "] what ["key" "WHAT "] build-tag ["key" "BUILD-TAG values"] build-markup ["key" "BUILD-MARKUP content /quiet"] decode-cgi ["key" "DECODE-CGI args"] read-cgi ["key" "READ-CGI /limit size"] write-user ["key" "WRITE-USER "] save-user ["key" "SAVE-USER "] set-user-name ["key" "SET-USER-NAME str"] link-app? ["key" "LINK-APP? "] protect-system ["key" "PROTECT-SYSTEM "] parse-xml ["key" "PARSE-XML code"] cvs-date ["key" "CVS-DATE date"] cvs-version ["key" "CVS-VERSION str"] do-boot ["key" "DO-BOOT target args dependent"] get-net-info ["key" "GET-NET-INFO "] desktop ["key" "DESKTOP url /only"] draw ["key" "DRAW image commands"] layout ["key" {LAYOUT specs /size pane-size /offset where /parent new /origin pos /styles list /keep /tight}] scroll-para ["key" "SCROLL-PARA tf sf"] get-face ["key" "GET-FACE face"] call ["key" {CALL cmd /input in /output out /error err /wait /console /shell /info}] alert ["key" "ALERT str"] set-face ["key" "SET-FACE face value /no-show"] uninstall ["key" "UNINSTALL "] show ["key" "SHOW face"] unfocus ["key" "UNFOCUS "] request-dir ["key" {REQUEST-DIR /title title-line /dir where /keep /offset xy}] center-face ["key" "CENTER-FACE obj /with face"] do-events ["key" "DO-EVENTS "] cp ["key" "CP value /part range /deep"] copy* ["key" "COPY* value /part range /deep"] net-error ["key" "NET-ERROR info"] decode-url ["key" "DECODE-URL url"] to-itime ["key" "TO-ITIME time"] to-idate ["key" "TO-IDATE date"] parse-header ["key" "PARSE-HEADER parent data /multiple"] parse-header-date ["key" "PARSE-HEADER-DATE data"] parse-email-addrs ["key" "PARSE-EMAIL-ADDRS data"] import-email ["key" "IMPORT-EMAIL data /multiple parent"] send ["key" {SEND address message /only /header header-obj /attach files /subject subj /show}] build-attach-body ["key" "BUILD-ATTACH-BODY body files boundary"] resend ["key" "RESEND to from message"] size-text ["key" "SIZE-TEXT face"] textinfo ["key" "TEXTINFO face line-info line"] offset-to-caret ["key" "OFFSET-TO-CARET face offset"] caret-to-offset ["key" "CARET-TO-OFFSET face offset"] local-request-file ["key" "LOCAL-REQUEST-FILE parms"] rgb-to-hsv ["key" "RGB-TO-HSV rgb"] hsv-to-rgb ["key" "HSV-TO-RGB hsv"] show-popup ["key" "SHOW-POPUP face /window window-face /away"] hide-popup ["key" "HIDE-POPUP /timeout"] open-events ["key" "OPEN-EVENTS "] find-key-face ["key" "FIND-KEY-FACE face keycode"] do-face ["key" "DO-FACE face value"] inside? ["key" "INSIDE? p1 p2"] within? ["key" "WITHIN? point offset size"] win-offset? ["key" "WIN-OFFSET? face"] unview ["key" "UNVIEW /all /only face"] screen-offset? ["key" "SCREEN-OFFSET? face"] span? ["key" "SPAN? pane /part count"] confine ["key" "CONFINE offset size origin margin"] outside? ["key" "OUTSIDE? p1 p2"] brightness? ["key" "BRIGHTNESS? color"] overlap? ["key" "OVERLAP? f1 f2"] edge-size? ["key" "EDGE-SIZE? face"] viewed? ["key" "VIEWED? face"] find-window ["key" "FIND-WINDOW face"] insert-event-func ["key" "INSERT-EVENT-FUNC funct"] remove-event-func ["key" "REMOVE-EVENT-FUNC funct"] in-window? ["key" "IN-WINDOW? window face"] inform ["key" {INFORM panel /offset where /title ttl /timeout time}] dump-pane ["key" "DUMP-PANE face"] dump-face ["key" "DUMP-FACE face"] flag-face ["key" "FLAG-FACE face 'flag"] deflag-face ["key" "DEFLAG-FACE face 'flag"] flag-face? ["key" "FLAG-FACE? face 'flag"] clear-fields ["key" "CLEAR-FIELDS panel"] read-net ["key" "READ-NET url /progress callback"] vbug ["key" "VBUG msg"] path-thru ["key" "PATH-THRU url"] exists-thru? ["key" "EXISTS-THRU? url /check info"] read-thru ["key" {READ-THRU url /progress callback /update /expand /check info /to local-file}] load-thru ["key" {LOAD-THRU url /update /binary /to local-file /all /expand /check info}] do-thru ["key" "DO-THRU url /args arg /update /check info /boot"] launch-thru ["key" "LAUNCH-THRU url /update /check info"] load-image ["key" "LOAD-IMAGE image-file /update /clear"] request-download ["key" "REQUEST-DOWNLOAD url /to local-file"] do-face-alt ["key" "DO-FACE-ALT face value"] set-font ["key" "SET-FONT aface 'word val"] set-para ["key" "SET-PARA aface 'word val"] get-style ["key" "GET-STYLE name /styles ss"] set-style ["key" "SET-STYLE name new-face /styles ss"] make-face ["key" {MAKE-FACE style /styles ss /clone /size wh /spec blk /offset xy /keep}] stylize ["key" "STYLIZE specs /master /styles styls"] choose ["key" {CHOOSE choices function /style styl /window winf /offset xy /across}] hilight-text ["key" "HILIGHT-TEXT face begin end"] hilight-all ["key" "HILIGHT-ALL face"] unlight-text ["key" "UNLIGHT-TEXT "] focus ["key" "FOCUS face /no-show"] scroll-drag ["key" "SCROLL-DRAG face /back /page"] clear-face ["key" "CLEAR-FACE face /no-show"] reset-face ["key" "RESET-FACE face /no-show"] scroll-face ["key" "SCROLL-FACE face offset /x /y /no-show"] resize-face ["key" "RESIZE-FACE face size /x /y /no-show"] load-stock ["key" "LOAD-STOCK name /block size"] load-stock-block ["key" "LOAD-STOCK-BLOCK block"] notify ["key" "NOTIFY str"] request ["key" {REQUEST str /offset xy /ok /only /confirm /type icon /timeout time}] flash ["key" "FLASH val /with face /offset xy"] request-color ["key" "REQUEST-COLOR /color clr /offset xy"] request-pass ["key" {REQUEST-PASS /offset xy /user username /only /title title-text}] request-text ["key" {REQUEST-TEXT /offset xy /title title-text /default str}] request-list ["key" "REQUEST-LIST titl alist /offset xy"] request-date ["key" "REQUEST-DATE /offset xy /date when"] request-file ["key" {REQUEST-FILE /title title-line button-text /file name /filter filt /keep /only /path /save}] dbug ["key" "DBUG msg"] editor ["key" "EDITOR file /app app-word"] link-relative-path ["key" "LINK-RELATIVE-PATH file"] emailer ["key" "EMAILER /to target /subject what"] crypt-strength? ["key" "CRYPT-STRENGTH? "] dh-make-key ["key" "DH-MAKE-KEY /generate length generator"] dh-generate-key ["key" "DH-GENERATE-KEY obj"] dh-compute-key ["key" "DH-COMPUTE-KEY obj public-key"] dsa-make-key ["key" "DSA-MAKE-KEY /generate length"] dsa-generate-key ["key" "DSA-GENERATE-KEY obj"] dsa-make-signature ["key" "DSA-MAKE-SIGNATURE /sign obj data"] dsa-verify-signature ["key" "DSA-VERIFY-SIGNATURE obj data signature"] rsa-make-key ["key" "RSA-MAKE-KEY "] rsa-generate-key ["key" "RSA-GENERATE-KEY obj length generator"] rsa-encrypt ["key" {RSA-ENCRYPT obj data /decrypt /private /padding padding-type}] monitor ["key" "MONITOR "]] 
format-code-section: func [code [string!] /local 
name section-data
] [
trim/auto code
emit <div class="code"> 
set [name code] load/next code 
either all [set-word? :name section-data: select code-sections to word! name] [
emit [
<p class="sectdef"> 
<span class="bra"> "&#9001;" </span> 
section-data/title 
<span class="bra"> "&#9002;" </span> " " 
either section-data/visited ["+"] [""] 
"&#8801;" 
</p>
] 
section-data/visited: yes 
parse code [opt newline code:]
] [
code: head code
] 
emit <p> 
parse/all detab code [
some [any tabs rebol-code]
] 
emit </p> 
emit </div>
] 
format-code: func [code [string!]] [
emit <span class="code"> 
parse/all detab code rebol-code 
emit </span>
] 
emit-header: has [tmp] [
emit <div id="header"> 
if in header 'title [
emit [<h1 id="title"> header/title </h1>]
] 
if in header 'author [
emit [<h2 id="author"> escape-html copy header/author] 
if in header 'email [
emit [
" &lt;" 
{<a href="mailto:} tmp: escape-html copy header/email {">} tmp </a> 
"&gt;"
]
] 
emit </h2>
] 
if any [in header 'date in header 'version] [
emit <h2 id="dateversion"> 
if in header 'date [
emit escape-html form header/date
] 
if all [in header 'date in header 'version] [
emit ", "
] 
if in header 'version [
emit escape-html form header/version
] 
emit </h2>
] 
if in header 'purpose [
emit [<p id="purpose"> escape-html header/purpose </p>]
] 
if in header 'license [
emit [<div id="license"> escape-html header/license </div>]
] 
if all [in header 'history block? header/history] [
emit [
<table id="history"> 
<thead> 
<tr> <th> "Date" </th> <th> "Version" </th> 
<th> "Description" </th> <th> "Author" </th> </tr> 
</thead> 
<tbody>
] 
parse header/history [
some [
set tmp date! (emit [<tr> <td class="date"> escape-html form tmp </td>]) 
set tmp tuple! (emit [<td class="version"> escape-html form tmp </td>]) 
set tmp string! (emit [<td class="desc"> escape-html copy tmp </td>]) 
opt [set tmp word! (emit [<td class="name"> escape-html form tmp </td>])] (emit </tr>)
]
] 
emit [</tbody> </table>]
] 
emit </div>
emit toc
] 
normal: [
para: (emit <p> emit-inline data emit </p>) 
sect1: (emit <div class="section"> emit-sect 1 data) in-sect (emit </div>) 
sect2: (emit-sect 2 data) 
sect3: (emit-sect 3 data) 
sect4: (emit-sect 4 data) 
bullet: bullet2: bullet3: (emit <ul>) continue in-bul (emit </ul>) 
enum: enum2: enum3: (emit <ol>) continue in-enum (emit </ol>) 
code: (format-code-section data) 
output: (emit data) 
define: (emit <dl>) continue in-define (emit </dl>) 
image: (
emit [
either data/2 = 'center [<div class="image center">] [<div class="image">] 
{<img src="} data/1 {">} 
</div>
]
) 
center-in: (emit <div class="center">) 
in-center (emit </div>) 
center-out: (error "Unbalanced center-out") 
note-in: (emit [<div class="note"> <h2>] emit-inline data emit </h2>) 
in-note (emit </div>) 
note-out: (error "Unbalanced note-out") 
indent-in: (emit <blockquote>) 
in-indent (emit </blockquote>) 
indent-out: (error "Unbalanced indent-out")
] 
in-sect: inherit normal [
sect1: continue return
] 
in-bul: [
bullet: (emit <li> emit-inline data emit </li>) 
bullet2: bullet3: (emit <ul>) continue in-bul2 (emit </ul>) 
enum2: enum3: (emit <ol>) continue in-enum2 (emit </ol>) 
default: continue return
] 
in-bul2: [
bullet2: (emit <li> emit-inline data emit </li>) 
bullet3: (emit <ul>) continue in-bul3 (emit </ul>) 
enum3: (emit <ol>) continue in-enum3 (emit </ol>) 
default: continue return
] 
in-bul3: [
bullet3: (emit <li> emit-inline data emit </li>) 
default: continue return
] 
in-enum: [
enum: (emit <li> emit-inline data emit </li>) 
bullet2: bullet3: (emit <ul>) continue in-bul2 (emit </ul>) 
enum2: enum3: (emit <ol>) continue in-enum2 (emit </ol>) 
default: continue return
] 
in-enum2: [
enum2: (emit <li> emit-inline data emit </li>) 
bullet3: (emit <ul>) continue in-bul3 (emit </ul>) 
enum3: (emit <ol>) continue in-enum3 (emit </ol>) 
default: continue return
] 
in-enum3: [
enum3: (emit <li> emit-inline data emit </li>) 
default: continue return
] 
in-define: [
define: (emit-define data) 
default: continue return
] 
emit-define: func [data [block!]] [
if data/1 [
emit <dt> 
emit-inline data/1 
emit </dt>
] 
if data/2 [
emit <dd> 
emit-inline data/2 
emit <dd>
]
] 
in-center: inherit normal [
center-out: return
] 
in-note: inherit normal [
note-out: return
] 
in-indent: inherit normal [
indent-out: return
] 
escape-html: func [text] [
foreach [from to] html-codes [replace/all text from to] 
text
] 
html-codes: ["&" "&amp;" "<" "&lt;" ">" "&gt;"] 
sects: 0.0.0.0 
clear-sects: does [sects: 0.0.0.0] 
next-section: func [level /local bump mask] [
set [bump mask] pick [[1.0.0.0 1.0.0.0] [0.1.0.0 1.1.0.0] [0.0.1.0 1.1.1.0] [0.0.0.1 1.1.1.1]] level 
level: form sects: sects + bump * mask 
clear find level ".0" 
level
] 
parse-code-block: func [code [any-block!] /local result 
rule word value
] [
result: make :code length? :code 
parse :code rule: [
some [
set word word! (either code: select code-sections word [parse code/code rule] [append result word]) 
| 
[#lit | #literal] set value skip (append/only result :value) 
| 
#include set value [file! | url!] (append result load value) 
| 
set code [block! | paren!] (append/only result parse-code-block code) 
| 
set value skip (append/only result :value)
]
] 
result
] 
generate-code: func [start [word!] /local 
section-data
] [
if section-data: select code-sections start [
parse-code-block section-data/code
]
] 
template: read %wetan-template.html 
build-doc: func [text /local tmp] [
save/all/header header/file generate-code '-main- header 
either template [
tmp: copy template 
replace/all tmp "$title" title 
replace/all tmp "$date" now/date 
replace tmp "$content" text 
tmp
] [
copy text
]
]
] 
do-makedoc: has [in-view? file msg doc] [
in-view?: all [value? 'view? view?] 
file: system/script/args 
if string? file [file: to-rebol-file file] 
if all [
not file 
exists? %last-file.tmp
] [
file: load %last-file.tmp 
either confirm reform ["Reprocess" file "?"] [
system/script/args: none
] [
file: none
]
] 
if not file [
either in-view? [
file: request-file/only
] [
file: ask "Filename? " 
file: all [not empty? trim file to-file file]
]
] 
if not file [exit] 
if not exists? file [
msg: reform ["Error:" file "does not exist"] 
either in-view? [alert msg] [ask msg] 
exit
] 
save %last-file.tmp file 
change-dir first split-path file 
print ["Processing" file "..."]
doc: wetan-emitter/generate default-scanner/scan-doc read file 
append clear find/last file #"." ".html" 
print ["Writing documentation to" file "(" length? doc "bytes)..."]
write file doc 
if all [in-view? not system/script/args] [browse file] 
print "Done."
if system/version/4 = 3 [wait .7]
] 
if system/script/args <> 'load-only [do-makedoc]
