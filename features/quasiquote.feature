Feature: S-Expressions
	As a developer using soy
	I want to be able to write quasiquote expressions

	Scenario: writing the most basic quasiquote
		Given the input "`(a b)"
		When the input is parsed
		Then the output should be "(list a b)"
		
	Scenario: writing a quasiquote with unquote
		Given the input "(def x 6) `(a ,x b ,x)"
		When the input is evaluated
		Then the output should be "(list a 6 b 6)"
		
	Scenario: writing a quasiquote with unquote splicing
		Given the input "(def x {4 5 6}) `(1 2 3 ,@x)"
		When the input is evaluated
		Then the output should be "(list 1 2 3 4 5 6)"
		
	Scenario: writing nested quasiquotes should work
		Given the input "(def x {a b c}) `(x y (,x (y ,@x)))"
		When the input is parsed
		Then the output should be "(list x y ((a b c) (y a b c)))"