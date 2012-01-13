Feature: key/value pairs
	As a developer using soy
	I want to be able to write with key value pairs

	Scenario: writing with basic key value pair
		Given the input "a:b."
		When the input is parsed
		Then the output should be "((key-value-pair a b))"
		
	Scenario: writing with many key values
		Given the input "a: b c: d e: f."
		When the input is parsed
		Then the output should be "((key-value-pair a b) (key-value-pair c d) (key-value-pair e f))"