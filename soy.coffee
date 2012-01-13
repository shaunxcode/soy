#Soy is a lisp dialect which allows for smalltalk esque syntax alongside normal lisp s-expressions.
#This current implementation is largely a port of norvigs lispy.py (and subsequently many of the comments
# are directly cribbed from http://norvig.com/lispy.py.
fs = require 'fs'

#This is the recomended approach for determining types even with in coffee.
type = do ->
	classToType = {}
	for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
		classToType["[object " + name + "]"] = name.toLowerCase()

	#Return the actual definition of type which takes any object and returns a string indicating the type.
	(obj) ->
		strType = Object::toString.call(obj)
		classToType[strType] or "object"
 
#Symbols are any token which we use when expanding and interpreting .
class Symbol
	constructor: (@str) ->

symbol_table = {}

sym = (s) ->
	if s not in symbol_table then symbol_table[s] = new Symbol(s)
	return symbol_table[s]

#We need to quickly define the main special forms, including the pipe and semicolon.
[_quote, _if, _set, _define, _lambda, _begin, _definemacro, _pipe, _semicolon, _colon] = 
"quote if set! define lambda begin define-macro | ; :".split(' ').map(sym)

#These symbols are for quasiquote support.
[_quasiquote, _unquote, _unquotesplicing] =
"quasiquote unquote unquote-splicing".split(',').map(sym)

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
			if @line in ['', undefined] then return eof_object
			[_, token, @line] = @line.match @tokenizer

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
				
			#We need to compensate for edge case of tokenizer e.g. "a|b".
			if "|" in token and token != "|"
				parts = token.split "|"
				token = parts.shift()
				@line = "| " + parts.join(" | ") + ' ' + @line
			
			#we need to compensate for colon as well e.g. "a:b"
			if ":" in token and token != ":"
				parts = token.split ":"
				token = parts.shift()
				@line = ": " + parts.join(" : ") + ' ' + @line
			
			#We need to compensate for tokens ending with . e.g. "abc.".
			if token[token.length-1] == '.'
				token = token[0..token.length-2]
				@line += ' . '
			
			return token unless token is ''

#We are emulating python StringIO.
class StringIO
	constructor: (string) ->
		@index = 0
		@lines = string.trim().split("\n")

	readline: -> @lines[@index++]

SyntaxError = (msg) -> msg

parse = (inport) ->
	if type(inport) is "string" then inport = new InPort(new StringIO(inport))
	expand read(inport), topLevel = true
 
#Read a Soy expression from an input port.
read = (inport) ->
	#is_first is a hack for allowing first token in expression to NOT begin with paren.
	read_ahead = (token, is_first = false) ->
		L = []
		if is_first and token != '('
			L.push(atom(token))
			token = '('

		#We should only see a closing paren once we are inside of a list.
		if token is ')' then throw SyntaxError('unexpected )')
		#If we find a quote then we should recurse into it.
		else if token in quotes then return [quotes[token], read(inport)]
		#The only time we should encounter the end of a file is when we are done parsing a list.
		else if token is eof_object then throw SyntaxError('unexpected EOF in list')
		#Start building a list
		else if token is '('
			while true
				token = inport.next_token()
				#Allow for ")" or "." to terminate list.
				if token in [')', '.'] then return L else L.push(read_ahead(token))
		#Anything else not caught by the above must be an atom
		else return atom(token)

	token1 = inport.next_token()
	if token1 is eof_object then return eof_object else read_ahead(token1, true)

quotes = {"'":_quote, "`":_quasiquote, ",":_unquote, ",@":_unquotesplicing}

string_escape = (string) -> string
string_encode = (string) -> string

isa = (x, testType) ->
	testType is "Symbol" and x instanceof Symbol \
	or testType is "String" and type(x) is "String" \
	or testType is "Number" and type(x) is "Number" \
	or testType is "List" and type(x) is "array"

#Numbers become numbers; #t and #f are booleans; "..." string; We also specifically match pipe and semicolon, otherwise Symbol.
atom = (token) ->
	return true if token is '#t'
	return false if token is '#f'
	return string_escape(token[1..-2]) if token[0] is '"'
	return Number(token) if type(token) is 'Number' 
	return _pipe if token is '|' 
	return _semicolon if token is ';'
	return _colon if token is ':'
	return sym token

#Convert an in-memory object back into a soy-readable string.
to_string = (x) ->
	return "#t" if x is true
	return "#f" if x is false
	return x.str if isa x, "Symbol"
	return string_encode(x) if isa x, "String"
	return '(' + x.map(to_string).join(' ') + ')' if isa x, "List"
	return Number(x) if isa x, "Number"
	return String(x)

#Walk tree of x, making optimizations/fixes, and signaling SyntaxError.
expand = (x, toplevel = false) ->
	#Expand any children first.
	for token, pos in x 
		if isa token, 'List'
			x[pos] = expand token
				
	#For these next two expansions we use a for loop as we need to match the first instance and retain its position.

	#If we find a semicolon this is where we transform to cascading form e.g. 
	
	#"a b;c." -> "((a b) c)".
	for token, pos in x
		if token is _semicolon
			return expand [x[0..pos-1]].concat(x[pos+1..-1])

	#If we find a pipe this is where we transform e.g. 
	

	unbox = (item) -> 
		if item.length is 1 and isa item[0], 'List' then item = item[0]
		item

	#"a b | c." -> "(a (b) (c))".	
	for token, pos in x 
		if token is _pipe
			return expand [x[0], unbox(x[1..pos-1]), unbox(x[pos+1..-1])]

	for token, pos in x
		if token is _colon
			return (if pos > 1 then x[0..pos-2] else []).concat([['key-value-pair', x[pos-1], x[pos+1]]]).concat(expand x[pos+2..-1]);
	return x

#We only want to expose the parts of the module which are necessary.
exports.parse = parse
exports.read = read
exports.to_string = to_string