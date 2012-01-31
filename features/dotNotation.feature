Feature: dot notation
	As a developer using soy
	I want to be able to write with dot notation

	Scenario: writing a bare dot
		Given the input "(.a)"
		When the input is parsed
		Then the output should be "((key a))"
		
	Scenario: writing with basic dot notation
		Given the input "(a.b.c x y)"
		When the input is parsed
		Then the output should be "(((a (key b)) (key c)) x y)"

	Scenario: writing with basic dot notation
		Given the input "(a.b)"
		When the input is parsed
		Then the output should be "((a (key b)))"

	Scenario: writing with basic dot notation as function application
		Given the input "(a.b c)"
		When the input is parsed
		Then the output should be "((a (key b)) c)"

	
	Scenario: writing with direct object 
		Given the input "(print {a:1 b:0 c:9}.a)"
		When the input is parsed
		Then the output should be "(print ((dict (key-value-pair a 1) (key-value-pair b 0) (key-value-pair c 9)) (key a)))"
		
	Scenario: multiple dot expressions as arguments 
		Given the input "(a.b c.d (+ 1 2) e.f 5)"
		When the input is parsed
		Then the output should be "((a (key b)) (c (key d)) (+ 1 2) (e (key f)) 5)"
		
	Scenario: key first arg second
		Given the input "(.b a)"
		When the input is parsed 
		Then the output should be "((key b) a)"