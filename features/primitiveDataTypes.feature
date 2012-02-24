Feature: Primitive data types are the core of the system
	We need to ensure that they behave appropriately
	
	Scenario: booleans
		Given the input #t
		When the input is evaluated
		Then the output should be "#t"

	Scenario: booleans
		Given the input #f
		When the input is evaluated
		Then the output should be "#f"
