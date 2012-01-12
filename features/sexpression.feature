Feature: S-Expressions
	As a developer using soy
	I want to be able to write normal s-expressions

	Scenario: writing the most basic s-expression 
		Given the input "(a b)"
		When the input is parsed
		Then the output should be "(a b)"
		
	Scenario: writing a nested s-expression 
		Given the input "(a b (c d) (e (f (g h))))"
		When the input is parsed
		Then the output should be "(a b (c d) (e (f (g h))))"