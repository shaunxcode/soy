Feature: lambda - the ultimate

	Scenario: with args as list
		Given the input ((lambda x x) 6)
		When the input is evaluated
		Then the output should be "(6)"
	
	Scenario: args as value
		Given the input ((lambda (x) x) 6)
		When the input is evaluated
		Then the output should be "6"
	
	Scenario: let should expand into lambda
		Given the input (let x: 6 y: 7 + x y)
		When the input is parsed
		Then the output should be "((lambda (x y) (+ x y)) 6 7)"
	
	Scenario: let* should expand into nested lets
		Given the input (let* a: 1 b: (+ a 1) + a b)
		When the input is parsed
		Then the output should be "((lambda (a) ((lambda (b) (+ a b)) (+ a 1))) 1)"

	Scenario: let* should evaluate as expected
		Given the input (let* a: 1.2 b: (+ a 1.3) c: (* a b) + a (+ b c))
		When the input is evaluated
		Then the output should be "6.7"

	Scenario: args with rest params using &
		Given the input ((lambda (x y & others) others) 1 2 3 4 5 6)
		When the input is evaluated
		Then the output should be "(3 4 5 6)"
		
	Scenario: more complex use of rest params
		Given the input ([x y & args| {(apply x args) (apply y args)}] + - 8 9)
		When the input is evaluated
		Then the output should be "(17 -1)"