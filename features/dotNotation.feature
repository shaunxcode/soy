Feature: dot notation
	As a developer using soy
	I want to be able to write with dot notation

	Scenario: writing a bare dot
		Given the input (.a)
		When the input is parsed
		Then the output should be "((quote a))"
		
	Scenario: writing with basic dot notation
		Given the input (a.b.c x y)
		When the input is parsed
		Then the output should be "((enum-at (enum-at a (quote b)) (quote c)) x y)"

	Scenario: writing with basic dot notation
		Given the input (a.b)
		When the input is parsed
		Then the output should be "((enum-at a (quote b)))"

	Scenario: writing with basic dot notation as function application
		Given the input (a.b c)
		When the input is parsed
		Then the output should be "((enum-at a (quote b)) c)"

	
	Scenario: writing with direct object 
		Given the input (value {a:1 b:0 c:9}.a)
		When the input is evaluated
		Then the output should be "1"
		
	Scenario: multiple dot expressions as arguments 
		Given the input (a.b c.d (+ 1 2) e.f 5)
		When the input is parsed
		Then the output should be "((enum-at a (quote b)) (enum-at c (quote d)) (+ 1 2) (enum-at e (quote f)) 5)"
		
	Scenario: key first arg second
		Given the input (.b a)
		When the input is parsed 
		Then the output should be "((quote b) a)"
		
	Scenario: a decimal should not parse as dot notation
		Given the input (+ 5.5 -10.03)
		When the input is parsed 
		Then the output should be "(+ 5.5 -10.03)"
	
	Scenario: accessing an object member
		Given the input (value {a:1 b:0 c:0}.a)
		When the input is evaluated 
		Then the output should be "1"
	
	Scenario: execute a function which is an object member
		Given the input ({square: [x | * x x]}.square 5)
		When the input is evaluated
		Then the output should be "25"
		
	Scenario: pass object member as arg
		Given the input ({square: [x | * x x]}.square {x: 5 y: 7}.y)
		When the input is evaluated
		Then the output should be "49"