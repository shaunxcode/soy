Feature: Single Quotes
	I need to be able to quote atoms
	
	Scenario: quote an atom
		Given the input 'a
		When the input is parsed
		Then the output should be "(quote a)"
