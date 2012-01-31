Feature: special forms
	the special forms and their basic use cases
	
	Scenario: car
		Given the input "(car (list 1 2 3))"
		When the input is evaluated
		Then the output should be "1"
		
	Scenario: cdr
		Given the input "(cdr (list 1 2 3))"
		When the input is evaluated
		Then the output should be "(2 3)"
		
	Scenario: cons
		Given the input "(cons 1 (list 2 3))"
		When the input is evaluated
		Then the output should be "(1 2 3)"
	
	Scenario: nested cons
		Given the input "(cons 1 (cons 2 (cons 3 (list))))"
		When the input is evaluated
		Then the output should be "(1 2 3)"

	Scenario: define
	
	Scenario: set! 
	
	Scenario: lambda

	Scenario: let
			
	Scenario: cond

	Scenario: quote
	
	Scenario: apply
	
	Scenario: list
	
	Scenario: list?
	
	Scenario: eq?
		

