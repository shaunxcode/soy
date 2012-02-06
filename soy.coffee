#Soy is a lisp dialect which allows for smalltalk esque syntax alongside normal lisp s-expressions.
#This current implementation is largely a port of norvigs lispy.py (and subsequently many of the comments
# are directly cribbed from http://norvig.com/lispy.py.
fs = require 'fs'

None = undefined
 
#Symbols are any token which we use when expanding and interpreting .
class Symbol
	constructor: (@str) ->

symbol_table = {}

sym = (s) ->
	if not symbol_table[s] then symbol_table[s] = new Symbol(s)
	symbol_table[s]


#We need to quickly define the main special forms, including the pipe and semicolon.
specialForms = "compile key dict quote if set! define lambda key-value-pair begin define-macro | ; : . , ~ & % ^ # ,@".split(' ')
[_compile, _key, _dict, _quote, _if, _set, _define, _lambda, _key_value_pair, 
_begin, _definemacro, _pipe, _semicolon, _colon, _period, 
_comma, _tilda, _and, _percent, _hat, _hash, _commaat] = specialForms.map sym

#These symbols are for quasiquote support.
[_quasiquote, _unquote, _unquotesplicing] =
"quasiquote unquote unquote-splicing".split(' ').map(sym)

quotes = "'": _quote, "`": _quasiquote, ",": _unquote, ",@": _unquotesplicing

isQuote = (token) ->

eof_object = new Symbol('#<eof-object>')

#An input port. Retains a line of chars.
class InPort
	tokenizer: /\s*(,@|[('`,)]|"(?:[\\].|[^\\"])*"|;|[^\s('"`,;)]*)(.*)/

	constructor: (file) ->
		@file = file
		@line = ''

	next_token: ->
		while true
			if @line is '' then @line = @file.readline()
			if @line is '' or @line is undefined then return eof_object
			oldLine = @line
			[_, token, @line] = @line.match @tokenizer
			
			#if we do not find any token e.g. we have an open quote dangling, we treat this as EOF
			if oldLine is @line then return eof_object 
			
			#if we have a string, early return so we avoid further special token treatement 
			if token[0] is '"' then return token
			
			#if we have a number return early
			if "#{parseFloat(token)}" is token then return token
			
			#Squiggly brackets
			if "{" in token and token != "{"
				#{a: b}
				if token[0] is "{"
					@line = token[1..-1] + @line
					token = "{"
				#a{b: c}
				else
					parts = token.split "{"
					token = parts.shift()
					@line = "{" + parts.join(" { ") + " " + @line

			if "}" in token and token != "}"
				# a]
				if token[-1] is "}"
					token = token[0..-2]
					@line += " } "
				# a]b
				else
					parts = token.split "}"
					token = parts.shift()
					@line = " } " + parts.join(" } ") + " " + @line

			#Compensation for square brackets not being tokenized
			if "[" in token and token != "["
				# [b | c d]
				if token[0] is "["
					@line =  token[1..-1] + @line
					token = "["
				# a[a b | c d]
				else 
					parts = token.split "["
					token = parts.shift()
					@line = "[" + parts.join(" [ ") + " " + @line
			
			if "]" in token and token != "]"
				# a]
				if token[-1] is "]"
					token = token[0..-2]
					@line += " ] "
				# a]b
				else
					parts = token.split "]"
					token = parts.shift()
					@line = " ] " + parts.join(" ] ") + " " + @line

			if token is "["
				token = "("
				@line = "lambda " + @line
			
			if token is "]" 
				token = ")"
			
			if token is "{"
				token = "("
				@line = "dict " + @line
				
			if token is "}"
				token = ")"

			for specialChar in ['|', ';', ':', '.', ',@', ',', '~', '&', '%', '^', '#', ]
				#e.g. if we are ,@ don't keep going and find , 
				if token is specialChar then break
				
				if specialChar in token and token != specialChar
					parts = token.split specialChar
					token = parts.shift()
					@line =  specialChar + " " + parts.join(" " + specialChar + " ") + " " + @line
					break

			return token unless token is ''

#We are emulating python StringIO.
class StringIO
	constructor: (string) ->
		@index = 0
		@lines = string.trim().split("\n")

	readline: -> @lines[@index++]

class Env
	constructor: (parms = [], args = [], outer = false) ->
		@values = {}
		@outer = outer
		if isa parms, "Symbol"
			@setAt parms, args
		else
			if args.length isnt parms.length
  				throw "Expected #{to_string(parms)}, given #{to_string(args)}"

			if parms.length > 0
				@update zip parms, args
	toString: ->
		to_string(for key, val of @values
			push([key, "#{to_string val}\n"]))
		
	update: (values) ->
		@setAt key, val for key, val of values
		@
	
	find: (key, couldBeNew = false) ->
		if @values[to_string key] then return @

		if not @outer and not couldBeNew
			throw "Could not find #{to_string key}"
		if @outer
			try
				return @outer.find key
			catch e
				if couldBeNew
					return @
				else
					throw e

	at: (key) ->
		if @values[to_string key] then return @values[to_string key]
		throw "Could not find #{to_string key} in #{to_string dict_keys @values}"

	setAt: (key, val) ->
		if @outer and @outer.values[to_string key]
			@outer.values[to_string key] = val
		else
			@values[to_string key] = val

class Procedure
	constructor: (@parms, @exp, @env) ->
	
	toString: ->
		to_string [_lambda, @parms, @exp]

SyntaxError = (msg) -> msg

parse = (inport) ->
	if type(inport) is "string" then inport = new InPort(new StringIO(inport))
	read inport
 
#Read a Soy expression from an input port.
read = (inport) ->
	read_ahead = (token) ->
		#Start building a list
		if token is '('
			L = []
			while true
				token = inport.next_token()
				#Allow for ")" or "." to terminate list.
				if token is ')' then return L else L.push(read_ahead(token))
		#We should only see a closing paren once we are inside of a list.
		else if token is ')' then throw SyntaxError('unexpected )')
		#If we find a quote then we should recurse into it.
		else if quotes[token] then return [quotes[token], read(inport)]
		#The only time we should encounter the end of a file is when we are done parsing a list.
		else if token is eof_object then throw SyntaxError('unexpected EOF in list')
		#Anything else not caught by the above must be an atom
		else return atom(token)

	token1 = inport.next_token()
	if token1 is eof_object then return eof_object else read_ahead(token1)

string_escape = (string) -> "\"#{string}\""
string_encode = (string) -> string

#This is the recomended approach for determining types even with in coffee.
type = do ->
	classToType = {}
	for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
		classToType["[object " + name + "]"] = name.toLowerCase()

	#Return the actual definition of type which takes any object and returns a string indicating the type.
	(obj) ->
		strType = Object::toString.call(obj)
		classToType[strType] or "object"
			
isa = (x, testType) ->
	testType is "Symbol" and x instanceof Symbol \
	or testType is "Procedure" and x instanceof Procedure \
	or testType is "String" and type(x) is "string" \
	or testType is "Number" and type(x) is "number" \
	or testType is "List" and type(x) is "array" \
	or testType is "Object" and type(x) is "object"

#Numbers become numbers; #t and #f are booleans; "..." string; We also specifically match pipe and semicolon, otherwise Symbol.
atom = (token) ->
	return true if token is '#t'
	return false if token is '#f'
	return string_escape(token[1..-2]) if token[0] is '"'
	return Number(token) if String(Number token) is token
	return sym token

dict_keys = (x) ->
	keys = []
	for k, v of x
		keys.push k
	keys

dict_to_string = (x) ->
	"{#{(for k,v of x 
		"#{to_string k}: #{if isa(v, "Object") then "<DICT>" else to_string(v)}").join " "}}"

#Convert an in-memory object back into a soy-readable string.
to_string = (x) ->
	return "#t" if x is true
	return "#f" if x is false
	return x.str if isa x, "Symbol"
	return string_encode(x) if isa x, "String"
	return '(' + x.map(to_string).join(' ') + ')' if isa x, "List"
	return Number(x) if isa x, "Number"
	return x.toString() if isa x, "Procedure"
	return dict_to_string(x) if isa x, "Object"
	return String(x)

unbox = (item) -> 
	if item.length is 1 and isa item[0], 'List' then item = item[0]
	item

demand = (x, predicate, msg = 'wrong length') ->
	if not predicate
		throw "#{to_string(x)}: #{msg}"

all = (pred, items) ->
	for item in items
		if not pred(item) then return false
	return true

is_pair = (x) ->
	isa(x, "List") and x.length is 2

cons = (x, y) -> 
	[x].concat y

macro_table = {}

add_globals = (env) ->
	env.update
		'+': (x, y) -> x + y
		'-': (x, y) -> x - y
		'*': (x, y) -> x * y
		'/': (x, y) -> x / y
		'not': (x) -> not x
		'>': (x, y) -> x > y
		'<': (x, y) -> x < y
		'>=': (x, y) -> x >= y
		'<=': (x, y) -> x <= y
		'=': (x, y) -> x is y
		'sqrt': (x) -> Math.sqrt x
		'abs': (x) -> Math.abs x
		'equal?': (x, y) -> x is y
		'eq?': (x, y) -> x is y
		'length': (x) -> x.length
		'cons': (x, y) -> cons x, y
		'car': (x) -> x[0]
		'cdr': (x) -> x[1..-1]
		'append': (x, y) -> x.concat y
		'list': (args...) -> args
		'list?': (x) -> isa x, "List"
		'null?': (x) -> x.length is 0
		'symbol?': (x) -> isa x, "Symbol"
		'boolean?': (x) -> isa x, "Boolean"
		'pair?': (x) -> is_pair x
		'port?': (x) -> isa x, "File"
		'apply': (args...) -> args[0].call {}, args[1..-1]
		'eval': (x) -> _eval expand(x)
		'load': (x) -> load x 
		'compile': (x) -> compile expand(x)
		'compile-file': (file) -> compile parse(new InPort(new FileIn(file)))
		'call/cc': (x) -> callcc x
		'open-input-file': (f) -> new FileIn(f)
		'close-input-port': (p) -> p.close()
		'open-output-file': (f) -> new FileOut(f)
		'close-output-port': (p) -> p.close()
		'eof-object?': (x) -> x is _eof_object
		'read-char': -> readchar()
		'read': -> read()
		'value': (x) -> to_string x
		'print': (x) -> to_string x
		'write': (x, port) -> port.pr to_string(x)
		'display': (x, port) -> port.pr if isa(x, "String") then x else to_string(x)

compile = (ast) -> 

global_env = add_globals new Env()

_eval = (x, env = false) ->
	env or= global_env

	while true
		if isa x, "Symbol"
			return env.find(x).at(x)
		else if not isa x, "List"
			return x
		else if x[0] is _quote
			[_, exp] = x
			return exp
		else if x[0] is _compile
			return compile x[1]
		else if x[0] is _dict
			dict = {}
			console.log x[1..-1]
			for kvp in x[1..-1]
				do (kvp) ->
					dict[to_string kvp[1]] = _eval kvp[2]
			return dict
		else if x[0] is _if
			[_, test, conseq, alt] = x
			return _eval((if _eval(test, env) then conseq else alt), env)
		else if x[0] is _set
			[_, key, exp] = x
			env.find(key, true).setAt(key, _eval(exp, env))
			return None
		else if x[0] is _define
			[_, key, exp] = x
			env.setAt(key, _eval(exp, env))
			return None
		else if x[0] is _lambda
			[_, vars, exp] = x
			return new Procedure(vars, exp, env)
		else if x[0] is _begin
			val = false
			for exp in x[1..-1]
				val = _eval exp, env
			return val
		else 
			exps = (_eval(exp, env) for exp in x)
			proc = exps.shift()
			if isa proc, "Procedure"
				x = proc.exp
				env = new Env(proc.parms, exps, proc.env)
			else if proc.apply
				return proc.apply {}, exps
			else
				dkey = to_string exps.shift()
				return proc[dkey]

	
desugar = (x) ->
	#desugarization 
	#if x[0] is '"'
	#desguar any children first.
	for token, pos in x 
		if isa token, 'List'
			x[pos] = desugar token

	#For these next two expansions we use a for loop as we need to match the first instance and retain its position.
	#If we find a semicolon this is where we transform to cascading form e.g. 
	#"(a b;c)" -> "(do (a b) (a c))".
	for token, pos in x
		if token is _semicolon
			return desugar [x[0..pos-1]].concat(x[pos+1..-1])

	#(a.b c) -> ((a (key b)) c)
	#(a.b c.d e.f) -> ((a (key b)) (c (key d)) (e (key f)))
	#(.b a) -> ((key b) a)
	#(a b c.d) -> (a b (c (key d)))
	#(a . (get-key 3) arg1 arg2) -> (a (key (get-key 3)) arg1 arg2)
	#error if (a.) or (a b .)
	for token, pos in x
		if token is _period
			if pos is 0 
				if !x[1] then throw "Missing param for dot expression "
				return desugar [[_key, x[1]]].concat(x[2..-1]) 
			else
				return desugar (if pos > 1 then x[0..(pos - 2)] else []).concat([[x[pos-1], [_key, x[pos+1]]]]).concat(x[pos+2..-1])

	#(a b,c) -> ((a b) c)
	for token, pos in x
		if token is _comma
			return desugar [x[0..pos-1]].concat(x[pos+1..-1])

	#"(a b | c)" -> "(a (b) (c))"	
	for token, pos in x 
		if token is _pipe
			return desugar [x[0], unbox(x[1..pos-1]), unbox(x[pos+1..-1])]

	for token, pos in x
		if token is _colon
			return (if pos > 1 then x[0..pos-2] else []).concat([[_key_value_pair, x[pos-1], x[pos+1]]]).concat(desugar x[pos+2..-1]);

	return x

#Walk tree of x, making optimizations/fixes, and signaling SyntaxError.
expand = (x, toplevel = false) ->
	if isa x, "List"
		demand x, x.length > 0

	if not isa x, "List"
		return x
	else if x[0] is _quote
		demand x, x.length is 2
		return x
	else if x[0] is _key
		return [_quote, x[1]]
	else if x[0] is _if
		if x.length is 3
			x.push None
		demand x, x.length is 4
		return (expand item for item in x) 
	else if x[0] is _set
		demand x, x.length is 3
		v = x[1]
		demand x, isa(v, "Symbol"), "Can set! only a symbol"
		return [_set, v, expand(x[2])]
	else if x[0] is _define or x[0] is _definemacro
		demand x, x.length >= 3
		[def, v, body...] = x
		if isa v, "List"
			[f, args...] = v[0]
			return expand [_define, f, [_lambda, args, body]]
		else
			demand x, x.length is 3
			demand x, isa(v, "Symbol"), "can define only a symbol"
			exp = expand x[2]
			if def is _definemacro
				demand x, toplevel, "define-macro only allowed at top level"
				proc = _eval(exp)
				demand x, type(proc) is "Function", "macro must be a procedure"
				macro_table[v] = proc
				return None
			else 
				return [_define, v, exp]
	else if x[0] is _begin
		if x.length is 1
			return None
		else
			return expand(xi, toplevel) for xi in x
	else if x[0] is _lambda
		demand x, x.length >= 3
		[lam, vars, body...] = x
		demand x, ((isa(vars, "List") and all(((v) -> isa v, "Symbol"), vars)) or isa(vars, "Symbol")), "illegal lambda argument list"
		exp = if body.length is 1 then body[0] else [_begin].concat(body)
		return [_lambda, vars, expand(exp)]
	else if x[0] is _quasiquote
		demand x, x.length is 2
		return expand_quasiquote x[1]
	else if isa(x[0], "Symbol") and macro_table[x[0]]
		return expand macro_table[x[0]].apply({}, x[1..-1]), toplevel
	else
		return (expand leaf for leaf in x)

expand_quasiquote = (x) ->
	return [_quote, x] if not is_pair x
	
	demand x, x[0] isnt _unquotesplicing, "can't splice here"
	
	if x[0] is unquote
		demand x, x.length is 2
		return x[1]
	else if is_pair(x[0]) and x[0][0] is _unquotesplicing
		demand x[0], x[0].length is 2
		return [_append, x[0][1], expand_quasiquote x[1..-1]]
	else
		return if x[0] is quasiquote then expand_quasiquote(expand_quasiquote(x[1..-1])[1]) else [_cons, expand_quasiquote(x[0]), expand_quasiquote(x[1..-1])]

zip = (a, b) ->
	result = {}
	for x, i in a
		do (x, i) ->
			result[to_string x] = b[i]
	result

unzip = (arr) ->
	a = []
	b = []
	for x in arr
		a.push x[0]
		b.push x[1]
	[a, b]

llet = (args...) ->
	x = cons _let, args
	demand x, args.length > 1
	bindings = args[0]
	body = args[1..-1]
	demand x, all(((b) -> isa(b, "List") and b.length is 2 and isa(b[0], "Symbol")), bindings), "illegal binding list"
	[vars, vals] = unzip bindings
	[[lambda, vars, (expand(b) for b in body)]].concat(expand val for val in bindings)

#We only want to expose the parts of the module which are necessary.
exports.topLevel = global_env
exports.parse = parse
exports.read = read
exports.desugar = desugar
exports.expand = expand
exports.eval = _eval
exports.to_string = to_string
exports.compile = compile