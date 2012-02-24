#Soy is a lisp dialect which allows for smalltalk esque syntax alongside normal lisp s-expressions.
#This current implementation is largely a port of norvigs lispy.py (and subsequently many of the comments
# are directly cribbed from http://norvig.com/lispy.py.
fs = require 'fs'

None = undefined

current_dir = './'

#Symbols are any token which we use when expanding and interpreting .
class Symbol
	constructor: (@str) ->

symbol_table = {}

sym = (s) ->
	if s instanceof Symbol then return s
	
	if not symbol_table[s] then symbol_table[s] = new Symbol(s)
	symbol_table[s]


#We need to quickly define the main special forms, including the pipe and semicolon.
specialForms = "load enum-at compile key dict cons append list quote if set! define lambda key-value-pair begin defmacro | ; : . , ~ & % ^ # ,@".split(' ')
[_load, _enum_at, _compile, _key, _dict, _cons, _append, _list, _quote, _if, _set, _define, _lambda, _key_value_pair, 
_begin, _defmacro, _pipe, _semicolon, _colon, _period, 
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
				@line = "squarelambda " + @line
			
			if token is "]" 
				token = ")"
			
			if token is "{"
				token = "("
				@line = "dict " + @line
				
			if token is "}"
				token = ")"

			for specialChar in ['|', ';', ':', '.', ',@', ',', '~', '&', '%', '^']
				#e.g. if we are ,@ don't keep going and find , 
				if String(Number token) is token then break
				
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

	readline: -> 
		line = 	@lines[@index++]
		if line.trim().length is 0 and @index < @lines.length
			return @readline()
		else 
			return line

class Env
	constructor: (parms = [], args = [], outer = false) ->
		@values = {}
		@outer = outer
		if isa parms, "Symbol"
			@values[to_string parms] = args
		else
			if args.length isnt parms.length
  				throw "Expected #{to_string(parms)}, given #{to_string(args)}"

			if parms.length > 0
				@values = zip parms, args

	toString: ->
		to_string(for key, val of @values
			push([key, "#{to_string val}"]))
		
	update: (values) ->
		@values = values
		@
	
	find: (key, couldBeNew = false) ->
		if isa(key, "Symbol") then key = to_string key
		
		if @values[key]? then return @

		if not @outer and not couldBeNew
			throw "Could not find #{key}"
		if @outer
			try
				return @outer.find key
			catch e
				if couldBeNew
					return @
				else
					throw e
		@

	at: (key) ->
		if isa(key, "Symbol") then key = to_string key
		
		if @values[key]? then return @values[key]
		throw "Could not find #{key} in #{to_string dict_keys @values}"

	setAt: (key, val, couldBeNew = false) ->
		if isa(key, "Symbol") then key = to_string key

		@find(key, couldBeNew).values[key] = val

class Procedure
	constructor: (@parms, @exp, @env) ->
	
	toString: ->
		to_string [_lambda, @parms, @exp]
	
	applyProc: (args) ->
		_eval @exp, new Env(@parms, args, @env)
	
	apply: (ctx, args) ->
		@applyProc args
	
	arity: ->
		@parms.length

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
	if token1 is eof_object then return eof_object else return read_ahead(token1)

string_escape = (string) -> string
string_encode = (string) -> "\"#{string}\""

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
	or testType is "Func" and (x instanceof Procedure or type(x) is "function")\
	or testType is "Procedure" and x instanceof Procedure \
	or testType is "Boolean" and type(x) is "boolean" \
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

dict_values = (x) ->
	vals = []
	for k, v of x
		vals.push v
	vals

dict_to_string = (x, haveSeen = []) ->
	
	"{#{(for k,v of x 
		"#{to_string k}: #{if isa(v, "Object") then (if v in haveSeen then "<CIRCULAR>" else dict_to_string(v, haveSeen.concat([v]))) else to_string(v)}").join(" ")}}"

#Convert an in-memory object back into a soy-readable string.
to_string = (x) ->
	return "#t" if x is true
	return "#f" if x is false
	return x.str if isa x, "Symbol"
	return string_encode(x) if isa x, "String"
	return "(#{x.map(to_string).join(' ')})" if isa x, "List"
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
	isa(x, "List") and x.length > 0

is_key_value_pair = (x) ->
	return if (isa(x, "Object") and x.key and x.value) then true else false

cons = (x, y) -> 
	[x].concat y

macro_table = {}
macro_table['let'] = applyProc: (args) ->
	vars = []
	vals = []
	for atom, pos in args
		if not(is_pair atom) or not(atom[0] is _key_value_pair) then break
		vars.push atom[1]
		vals.push atom[2]
	
	body = args[pos..-1]
	if not(is_pair body[0]) and body.length is 1
		body = body[0]
	else 
		body = unbox body

	[[_lambda, vars, body]].concat vals
	
macro_table['let*'] = applyProc: (args) ->
	if is_pair(args[0]) and args[0][0] is _key_value_pair
		return [[_lambda, [args[0][1]], macro_table['let*'].applyProc args[1..-1]], args[0][2]]
	else
		return args
		
gensymid = 0

add_globals = (env) ->
	env.update
		'gensym': -> sym "__SGENSYM__#{gensymid++}"
		'enum-at': (d, dkey) -> 
			dkey = to_string dkey

			if isa(dkey, "Number") then dkey = parseInt(dkey)

			if isa(dkey, "Number") and dkey < 0
				dkey = d.length + dkey
			
			d[dkey]
			
		'+': (x, y) -> Number(x) + Number(y)
		'-': (x, y) -> x - y
		'*': (x, y) -> x * y
		'/': (x, y) -> x / y
		'and': (args...) -> 
			result = true
			for arg in args when not(arg)
				result = false
			result
		'or': (args...) ->
			result = false
			for arg in args when arg
				result = true
			result
		'string->symbol': (x) -> sym x
		'string-encode': (x) -> (if isa(x, "Symbol") then x.str else JSON.stringify x)
		'key': (x) -> x
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
		'cdr': (x) -> if x.slice? && x.length then return x[1..-1] else return undefined
		'append': (x, y) -> x.concat y
		'list': (args...) -> args
		'list?': (x) -> isa x, "List"
		'key-value-pair': (k, v) -> key: k, value: v
		'key-value-pair?': (x) -> is_key_value_pair x
		'dict': (args...) -> 
			d = {}
			for kv in args
				d[kv.key] = kv.value
			d
		'atom?': (x) -> not(is_pair x) and (not (x.length is 0))
		'null?': (x) -> x.length is 0
		'symbol?': (x) -> isa x, "Symbol"
		'boolean?': (x) -> isa x, "Boolean"

		'pair?': (x) -> is_pair x
		'port?': (x) -> isa x, "File"
		'map': (fn, arr) -> fn.apply({}, [item]) for item in arr
		'filter': (fn, arr) -> (item for item in arr when fn.apply({}, [item]))
		'join': (tok, arr) -> arr.join tok
		'map-dict': (fn, dict) -> 
			result = []
			result.push(fn.apply {}, [key, val]) for key, val of dict
			result
		'str': (args...) -> args.join("")
		'apply': (func, args) -> func.apply {}, args
		'eval': (x) -> _eval expand(x)
		'load': (x) -> load x 
		'compile': (lang, x) -> compile lang, expand(x)
		'compile-file': (file) -> compile parse(new InPort(new FileIn(file)))
		'call/cc': (x) -> callcc x
		'open-input-file': (f) -> new FileIn(f)
		'close-input-port': (p) -> p.close()
		'open-output-file': (f) -> new FileOut(f)
		'close-output-port': (p) -> p.close()
		'eof-object?': (x) -> x is _eof_object
		'read-char': -> readchar()
		'read': -> read()
		'value': (x) -> x
		'print': (x) -> console.log to_string x
		'file-write': (name, content) -> require("fs").writeFileSync(name, content, "UTF-8")
		'display': (x, port) -> port.pr if isa(x, "String") then x else to_string(x)
		'require': (f) -> require to_string f
		'file-contents': (f) -> require("fs").readFileSync(f, "UTF-8")

global_env = add_globals new Env()

arity = (x) ->
	if isa(x, "Procedure") then x.arity() else x.length
	
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
		else if x[0] is _if
			[_, test, conseq, alt] = x
			return _eval((if _eval(test, env) then conseq else alt), env)
		else if x[0] is _set
			[_, key, exp] = x
			env.find(key, true).setAt(key, _eval(exp, env))
			return None
		else if x[0] is _define
			[_, key, exp] = x
			env.setAt(key, _eval(exp, env), true)
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
				#true or false - missing second arg becomes false
				if isa(proc, "Boolean") 
					return if proc then exps[0] else (if exps[1]? then exps[1] else false)
				
				#int or float
				if isa(proc, "Number") 
					result = proc
					for term, i in exps 
						if applyTerm
							result = applyTerm.apply {}, [result, term]
							applyTerm = false
						else if isa(term, "Number")
							result *= term
						else
							if isa(term, "Func")
								if arity(term) is 1
									result = term.apply {}, [result]
								else
									applyTerm = term
							else
								throw new Error "encountered #{term} when evaluating application of Number expected Number of Func"
					if applyTerm
						result = ((r, t) -> ((y) -> t.apply {}, [r, y]))(result, applyTerm)
						applyTerm = false
					return result
				
				#anything will get to here so long as proc is a prim and first arg is a func
				if exps.length and isa(exps[0], "Func")
					return exps[0].apply({}, [proc].concat(exps[1..-1]))

				#assume it is a dict, list or string
				#single index look up
				if exps.length is 1
					dkey = to_string exps.shift()
					
					if isa(dkey, "Number") then dkey = parseInt(dkey)

					if isa(dkey, "Number") and dkey < 0
						dkey = proc.length + dkey

					return proc[dkey]

				#range based look up
				if exps.length is 2
					dkey1 = to_string exps.shift()
					dkey2 = to_string exps.shift()
					if isa(dkey1, "Number") then dkey1 = parseInt(dkey1)
					if isa(dkey2, "Number") then dkey2 = parseInt(dkey2)
					
					return proc[dkey1..dkey2]

				throw (to_string proc) + " can not be used as function"
	
desugar = (x) ->
	#desugarization 
	#if x[0] is '"'
	#desguar any children first.
	for token, pos in x 
		if isa token, 'List'
			x[pos] = desugar token

	if x[0] is sym("squarelambda")
		if not(_pipe in x)
			return desugar [_lambda, _pipe].concat x[1..-1]
		else 
			return desugar [_lambda].concat x[1..-1]
		
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
				return desugar (if pos > 1 then x[0..(pos - 2)] else []).concat([[_enum_at, x[pos-1], [_key, x[pos+1]]]]).concat(x[pos+2..-1])

	#(a b,c) -> ((a b) c)
	for token, pos in x
		if token is _comma
			return desugar [x[0..pos-1]].concat(x[pos+1..-1])

	#"(a b | c)" -> "(a (b) (c))"	
	for token, pos in x 
		if token is _pipe
			body = x[pos+1..-1]
			if not(is_pair body[0]) and body.length is 1
				body = body[0]
			else 
				body = unbox body
			return desugar [x[0], unbox(x[1..pos-1]), body]

	for token, pos in x
		if token is _colon
			return (if pos > 1 then x[0..pos-2] else []).concat([[_key_value_pair, x[pos-1], x[pos+1]]]).concat(desugar x[pos+2..-1]);

	return x

load = (filename) ->
	filename = (if filename[0] in ['.', '/'] then '' else current_dir) + filename
	if filename[-4..-1] isnt ".soy"
		filename += ".soy"
	
	loadDir = filename.split('/')[0..-2].join('/') + '/'
	oldDir = current_dir
	
	current_dir = loadDir
	parsed = parse("(begin #{require("fs").readFileSync(filename, "UTF-8").trim()})")
	current_dir = oldDir

	parsed
	
#Walk tree of x, making optimizations/fixes, and signaling SyntaxError.
expand = (x, toplevel = false) ->
	if isa x, "List"
		demand x, x.length > 0
		
	if not isa x, "List"
		return x
	else if x[0] is _quote
		demand x, x.length is 2
		return x
	else if x[0] is _load
		return expand(desugar(load(expand x[1])))
	else if x[0] is _key
		return [_quote, x[1]]
	else if x[0] is _key_value_pair
		return [_key_value_pair, (if isa(x[1], "Symbol") then x[1].str else expand x[1]), expand(x[2])]
	else if x[0] is _dict
		for atom, pos in x[1..-1] 
			if not(isa atom, "List") or (isa(atom, "List") and atom[0] isnt _key_value_pair)
				x[0] = _list
			x[pos+1] = expand atom
		return x
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
	else if x[0] is _define or x[0] is _defmacro
		demand x, x.length >= 3
		[def, v, body...] = x
		if isa v, "List"
			[f, args...] = v[0]
			return expand [_define, f, [_lambda, args, body]]
		else
			demand x, x.length is 3
			demand x, isa(v, "Symbol"), "can define only a symbol"
			exp = expand x[2]
			if def is _defmacro
				#demand x, toplevel, "define-macro only allowed at top level"
				proc = _eval(exp)
				demand x, isa(proc, "Procedure"), "macro must be a procedure"
				macro_table[to_string v] = proc
				return None
			else 
				return [_define, v, exp]
	else if x[0] is _begin
		if x.length is 1
			return None
		else
			result = []
			result.push(expand xi, toplevel) for xi in x
			return result
	else if x[0] is _lambda
		demand x, x.length >= 3
		[lam, vars, body...] = x
		demand x, ((isa(vars, "List") and all(((v) -> isa v, "Symbol"), vars)) or isa(vars, "Symbol")), "illegal lambda argument list"

		bodyExp = expand(if body.length is 1 then body[0] else [_begin].concat(body))
				
		if _and in vars
			if vars[vars.length - 2] isnt _and then throw "& must be before last arg"
			newBody = []
			for arg, pos in vars
				if arg is _and then break
				newBody.push [_key_value_pair, arg, [sym("_s_args"), pos]]
			newBody.push [_key_value_pair, vars[pos + 1], [sym("_s_args"), pos, -1]]
			newBody.push bodyExp
			vars = sym("_s_args")
			bodyExp = macro_table["let"].applyProc newBody

		return [_lambda, vars, bodyExp]
	else if x[0] is _quasiquote
		demand x, x.length is 2
		return expand expand_quasiquote x[1]
	else if isa(x[0], "Symbol") and macro_table[to_string x[0]]
		macroed = macro_table[to_string x[0]].applyProc(x[1..-1])
		return expand macroed, toplevel
	else
		return (expand leaf for leaf in x)

expand_quasiquote = (x) ->
	return [_quote, x] if not is_pair x
	
	demand x, x[0] isnt _unquotesplicing, "can't splice here"
	
	if x[0] is _unquote
		demand x, x.length is 2
		return x[1]
	else if is_pair(x[0]) and x[0][0] is _unquotesplicing
		demand x[0], x[0].length is 2
		return [_append, x[0][1], expand_quasiquote x[1..-1]]
	else
		if x[0] is _quasiquote
			return expand_quasiquote(expand_quasiquote(x[1..-1])[1]) 
		else 
			return [_cons, expand_quasiquote(x[0]), expand_quasiquote(x[1..-1])]

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


getVar = (sym) -> 
	newVar = ''
	for c in sym.str.split()
		ord = (c + '').charCodeAt(0)
		if (ord >= 65 and ord <= 90) or (ord >= 97 and ord <= 122)
			newVar += c
		else 
			newVar += "_#{ord}_"
			
	return newVar

class CompileEnv 
	constructor: (parent = None, defs = []) ->
		@_defs = {}
		@_uses = []
		
		if defs.length
			@defs defs

		if parent is None 
			@_sets = dict_keys global_env.values
		else
			parent.child = @
			
	defs: (vname) ->
		for v in (if type(vname) is "array" then vname else [v])
			@_defs[to_string v] = true
		@
	
	uses: (vname) ->
		for v in (if type(vname) is "array" then vname else [v])
			if not @_defs[to_string v]
				@_uses[to_string v] = true
		@
	
	removeUse: (vname) ->
		if @_uses[vname]
			delete @_uses[vname]
		@
	
	getLexicalUses: ->
		if @child
			@uses @child.getLexicalUses()
			
		dict_keys @_uses
	

compile = (targetLang, x, env = false) -> 
	env or= new CompileEnv

	if isa x, "Symbol"
		env.uses x
		return getVar x
	else if not (isa x, "List")
		return to_string x
	else if x[0] is _quote
		[_, exp] = x
		return if exp instanceof Symbol then exp.str else to_string x
	else if x[0] is _if
		[_, test, conseq, alt] = x
		return "(#{compile(targetLang, test, env)}) ? (#{compile(targetLang, conseq, env)}) : (#{compile(targetLang, alt, env)})"
	else if x[0] is _set
		[_, v, exp] = x
		env.uses v
		return "#{getVar(v)} = #{compile(targetLang, exp, env)};"
	else if x[0] is _define
		[_, v, exp] = x
		env.defs v
		return "var #{getVar(v)} = #{compile(targetLang, exp, env)};"
	else if x[0] is _lambda
		[_, vars, exp] = x
		cexp = compile(targetLang, [_begin, exp], new CompileEnv(env, vars))
		return "function(#{(getVar(v) for v in vars).join(",")}){#{cexp}}"
	else if x[0] is _enum_at
		return "#{compile targetLang, x[1], env}.#{compile targetLang, x[2], env}"
	else if x[0] is _begin
		val = []
		last = x.pop()
		
		val.push(compile(targetLang, exp, env)) for exp in x[1..-1]
		
		if isa(last, "List")
			cexp = compile(targetLang, last, new CompileEnv(env))
			last = "new Soy.Bounce(function() {return #{cexp}})"
		else
			last = compile(targetLang, last, env)
		
		return "#{val.join("#{'\n'}")} return #{last}"
	else  
		exps = (compile(targetLang, exp, env) for exp in x)
		
		if exps[0] is 'apply'
			env.removeUse('apply')
			exps.shift()
		
		return "Soy.apply(#{exps[0]}, [#{exps[1..-1].join(',')}])";
		 	
#We only want to expose the parts of the module which are necessary.
exports.setCurrentDir = (d) -> current_dir = d
exports.topLevel = global_env
exports.load = load
exports.parse = parse
exports.read = read
exports.desugar = desugar
exports.expand = expand
exports.eval = _eval
exports.to_string = to_string
exports.compile = compile