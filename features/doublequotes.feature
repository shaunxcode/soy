Feature: double quote strings
	As a developer using soy
	I want to be able to write double quoted strings
	
	Scenario: standard string
		Given the input: "hey I am a string" 
		When the input is parsed
		Then the output should be {"hey I am a string"}

	Scenario: string building
		Given the input: {(str "hey the number is " (+ 5 (+ 1 2)) " ya dingus")}
		When the input is evaluated
		Then the output should be {"hey the number is 8 ya dingus"}