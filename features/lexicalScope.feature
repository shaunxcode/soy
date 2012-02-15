Feature: lexical scope

	Scenario: a previously define variable should not be overwritten by a function arg
		Given the input "(define x 30)"
		When the input is evaluated
		And the input "([x | x] 40)"
		And the input is evaluated
		And the input "x"
		And the input is evaluated
		Then the output should be "30"