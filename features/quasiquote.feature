Feature: S-Expressions
	As a developer using soy
	I want to be able to write quasiquote expressions

	Scenario: writing the most basic quasiquote
		Given the input `(a b)
		When the input is parsed
		Then the output should be "(cons (quote a) (cons (quote b) (quote ())))"
		
	Scenario: writing an unquote expression
		Given the input `(a ,x b ,x)
		When the input is parsed
		Then the output should be "(cons (quote a) (cons x (cons (quote b) (cons x (quote ())))))"
		
	Scenario: writing a quasiquote with unquote
		Given the input (define x 6)
		When the input is evaluated
		 And the input `(a ,x b ,x)
		 And the input is evaluated
		Then the output should be "(a 6 b 6)"
		
	Scenario: writing a quasiquote with unquote splicing
		Given the input (define x {4 5 6})
		When the input is evaluated
		 And the input `(1 2 3 ,@x)
		 And the input is evaluated
		Then the output should be "(1 2 3 4 5 6)"
		
	Scenario: writing nested list quasiquotes should work
		Given the input (define x {'a 'b 'c}) 
		When the input is evaluated
		 And the input `(x y (,x (y ,@x)))
		 And the input is evaluated
		Then the output should be "(x y ((a b c) (y a b c)))"