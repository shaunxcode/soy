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
	
	Scenario: nested dictionary
		Given the input "(value {peter: {age: 30 height: 6.5}}.peter.height)"
		When the input is evaluated
		Then the output should be "6.5"

	Scenario: nested list in dictionary
		Given the input "(car {peter: {age: 30 height: 6.5 scores: {99 100 1543}}}.peter.scores)"
		When the input is evaluated
		Then the output should be "99"

	Scenario: list access via index
		Given the input "({1 2 3} 0)"
		When the input is evaluated
		Then the output should be "1"
	
	Scenario: list access end
		Given the input "({1 2 3} -1)"
		When the input is evaluated
		Then the output should be "3"
	
	Scenario: list access via nested dot notation
		Given the input "({{+ *} {/ -}}.-1.-1 5 6)"
		When the input is evaluated 
		Then the output should be "-1"