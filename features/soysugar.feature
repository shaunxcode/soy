Feature: SoySugar
	As a developer using soy
	I want to be able to write with "SoySugar"
		
	Scenario: writing a barred expression
		Given the input "(a b | c d)"
		When the input is parsed
		Then the output should be "(a (b) (c d))"
		
	Scenario: writing a barred expression with no space between the bar and surrounding tokens
		Given the input "(a b|c d)"
		When the input is parsed
		Then the output should be "(a (b) (c d))"

	Scenario: writing a barred expression where the bar is attached immediately after a token should still work as if there is a space
		Given the input "(a b| c d)"
		When the input is parsed
		Then the output should be "(a (b) (c d))"

	Scenario: writing a barred expression where the bar is attached immediately before a token should still work as if there is a space
		Given the input "(a b |c d)"
		When the input is parsed
		Then the output should be "(a (b) (c d))"
		
	Scenario: writing a multi-barred expression where the bar is attached immediately before and after a token should still work as if the spaces are there
		Given the input "(a b|c|d e)"
		When the input is parsed
		Then the output should be "(a (b) (c () (d e)))"

	Scenario: writing a barred expression with only two tokens
		Given the input "(a|b)"
		When the input is parsed
		Then the output should be "(a () (b))"
		
	Scenario: writing a semi colon between attoms is a cascade shorthand
		Given the input "(a b; c ; d)"
		When the input is parsed
		Then the output should be "(((a b) c) d)"
		
	Scenario: writing a semicolon cascading expression where semicolons touch tokens
		Given the input "(a b;c;d)"
		When the input is parsed
		Then the output should be "(((a b) c) d)"

	Scenario: writing a p-expression starting with an s-expression 
		Given the input "((a b) c d)"
		When the input is parsed
		Then the output should be "((a b) c d)"