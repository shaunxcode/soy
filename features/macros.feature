Feature: S-Expressions
	As a developer using soy
	I want to be able to write macros which get expanded at read time

	Scenario: writing the most basic macro
		Given the input "macro test (x) `(,x ,x ,x). test 6."
		When the input is parsed
		Then the output should be "(6 6 6)"