Feature: dictionary syntax
	As a developer using soy
	I want to be able to write with dictionary syntax

	Scenario: writing with basic dictionary/hash
		Given the input (define d {a: 1 b: 2})
		When the input is evaluated
		 And the input (value d.a)
		 And the input is evaluated
		Then the output should be "1"
		
	Scenario: arrays
		Given the input {1 2 5.5}
		When the input is parsed
		Then the output should be "(list 1 2 5.5)"
	
	Scenario: nested dictionary
		Given the input (value {peter: {age: 30 height: 6.5}}.peter.height)
		When the input is evaluated
		Then the output should be "6.5"

	Scenario: nested list in dictionary
		Given the input (car {peter: {age: 30 height: 6.5 scores: {99 100 1543}}}.peter.scores)
		When the input is evaluated
		Then the output should be "99"

	Scenario: list access via index
		Given the input ({1 2 3} 0)
		When the input is evaluated
		Then the output should be "1"
	
	Scenario: list access end
		Given the input ({1 2 3} -1)
		When the input is evaluated
		Then the output should be "3"
	
	Scenario: list access via nested dot notation
		Given the input ({{+ *} {/ -}}.-1.-1 5 6)
		When the input is evaluated 
		Then the output should be "-1"
	
	Scenario: dict should not evaluate value til runtime
		Given the input (let x: (+ 5 6) {key: x})
		When the input is evaluated
		Then the output should be {{"key": 11}} 
		
	Scenario: key-value-pair used in the raw
		Given the input (define x (key-value-pair a 5))
		When the input is evaluated
		 And the input (value x.key)
		 And the input is evaluated
		Then the output should be {"a"}
		
	Scenario: set a key 
		Given the input (define x '())
		When the input is evaluated
		And the input (set! (x 0) 'cat)
		And the input is evaluated
		And the input (value x.0)
		And the input is evaluated
		Then the output should be "cat"
		