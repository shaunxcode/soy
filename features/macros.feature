Feature: S-Expressions
	As a developer using soy
	I want to be able to write macros which get expanded at read time

	Scenario: writing the most basic macro
		Given the macro "(defmacro test (x) `(,x ,x ,x))"
	 	And the input "(test 6)"
		When the macro is expanded
		Then the output should be "(6 6 6)"