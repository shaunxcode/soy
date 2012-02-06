Feature: dictionary syntax
	As a developer using soy
	I want to be able to write with dictionary syntax

	Scenario: writing with basic dictionary/hash
		Given the input "{a: b c: d}"
		When the input is parsed
		Then the output should be "(dict (key-value-pair a b) (key-value-pair c d))"
		
	Scenario: arrays
		Given the input "{1 2 5.5}"
		When the input is parsed
		Then the output should be "(list 1 2 5.5)"
		
	#dictionary nesting
	
	#dictionary with manual keys
	
	#dictionary as function 