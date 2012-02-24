Feature: special forms
	the special forms and their basic use cases
	
	Scenario: car
		Given the input (car (list 1 2 3))
		When the input is evaluated
		Then the output should be "1"
		
	Scenario: cdr
		Given the input (cdr (list 1 2 3))
		When the input is evaluated
		Then the output should be "(2 3)"
		
	Scenario: cons
		Given the input (cons 1 (list 2 3))
		When the input is evaluated
		Then the output should be "(1 2 3)"
	
	Scenario: nested cons
		Given the input (cons 1 (cons 2 (cons 3 (list))))
		When the input is evaluated
		Then the output should be "(1 2 3)"

	Scenario: define
		Given the input (define x 30)
		When the input is evaluated
		And the input x
		And the input is evaluated
		Then the output should be "30"
		
	Scenario: set! 
		Given the input (define x 30)
		When the input is evaluated
		And the input (set! x 40)
		And the input is evaluated
		And the input x
		And the input is evaluated
		Then the output should be "40"
		
			
	Scenario: cond

	Scenario: quote
		Given the input (define p (quote peter))
		When the input is evaluated
		And the input p
		When the input is evaluated
		Then the output should be "peter"
		
	Scenario: apply
		Given the input (apply + (list 5 6))
		When the input is evaluated
		Then the output should be "11"
		
	Scenario: list
		Given the input (list 1 2 3)
		When the input is evaluated
		Then the output should be "(1 2 3)"

	Scenario: list?
		Given the input (list? '(1 2 3))
		When the input is evaluated
		Then the output should be "#t"
		
	Scenario: eq?
		Given the input (eq? 5 5)
		When the input is evaluated
		Then the output should be "#t"