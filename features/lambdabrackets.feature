Feature: lambda brackets
	As a developer using soy
	I want to be able to write with lambda brackets

	Scenario: writing with lambda brackets with arguments
		Given the input "[a b | c d]"
		When the input is parsed
		Then the output should be "(lambda (a b) (c d))"
	
	Scenario: writing with lambda brackets without arguments
		Given the input "[a b c d]"
		When the input is parsed
		Then the output should be "(lambda () (a b c d))"
		
	Scenario: writing with lambda brackets that touch tokens
		Given the input "(b[a b c d]c)"
		When the input is parsed
		Then the output should be "(b (lambda () (a b c d)) c)"
		
	Scenario: writing with nested lambda brackets 
		Given the input "(b[a b | [c |+ c a b]]c)"
		When the input is parsed
		Then the output should be "(b (lambda (a b) (lambda (c) (+ c a b))) c)"
		
	Scenario: writing with default arguments
		Given the input "([a: 1 b: 2 | + a b])"
		When the input is evaluated
		Then the output should be "3"

	Scenario: writing with default arguments passing first arg
		Given the input "([a: 1 b: 2 | + a b] 2)"
		When the input is evaluated
		Then the output should be "4"