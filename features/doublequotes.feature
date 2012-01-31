Feature: double quote strings
	As a developer using soy
	I want to be able to write double quoted strings
	
	Scenario: standard string
		Given the input: "hey I am a string" 
		When the input is parsed
		Then the output should be: "hey I am a string"