Feature: soy macros
	the core macros included with soy

	Scenario: def
		Given the input "(def x y)"
		When the input is parsed
		Then the output should be "(define x y)"

	Scenario: def implicit dictionary
		Given the input "(def x a: 1 b: 2)"
		When the input is parsed
		Then the output should be "(define x (dict (key-value-pair a 1) (key-value-pair b 2)))"

	Scenario: def implicit lambda with args
		Given the input "(def x a b | + a b)"
		When the input is parsed
		Then the output should be "(define x (lambda (a b) (+ a b)))"

	Scenario: def lambda with no args
		Given the input "(def x | + 1 2)"
		When the input is parsed
		Then the output should be "(define x (lambda () (+ 1 2)))"
