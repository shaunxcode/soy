Feature: S-Expressions
	As a developer using soy
	I want to be able to write macros which get expanded at read time

	Scenario: writing the most basic macro
		Given the input (defmacro test [x | `(+ ,x ,x)])
		When the input is evaluated
	 	And the input (test 6)
		And the input is evaluated
		Then the output should be "12"