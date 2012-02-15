Feature: basic logical operators

	Scenario: and
		Given the input "(and #t #t)"
		When the input is evaluated
		Then the output should be "#t"

	Scenario: and
		Given the input "(and #t #f)"
		When the input is evaluated
		Then the output should be "#f"

	Scenario: or
		Given the input "(or #t #t)"
		When the input is evaluated
		Then the output should be "#t"

	Scenario: or
		Given the input "(or #t #f)"
		When the input is evaluated
		Then the output should be "#t"

	Scenario: or
		Given the input "(or #f #f)"
		When the input is evaluated
		Then the output should be "#f"
			
	Scenario: not
		Given the input "(not #f)"
		When the input is evaluated
		Then the output should be "#t"

	Scenario: not
		Given the input "(not #t)"
		When the input is evaluated
		Then the output should be "#f"