Feature: There is some notion of primitive types in soy
	Specifically int, float, string, boolean, func, dict, and list
	When these are applied as functions they should actually do 
	(for now) runtime look up to determine the consequence
	
	Scenario: when a type is applied it transforms to applying self to first arg 
		Given the input (define px [n | str n "px"])
		When the input is evaluated
		And the input (5 px)
		And the input is evaluated
		Then the output should be {"5px"}
		
	Scenario: when an int or float is applied to an argument it is multiplied
		Given the input (5 10)
		When the input is evaluated
		Then the output should be "50"
		
	Scenario: when an type is applied against more than one arg it should apply all
		Given the input (5 5 5 5)
		When the input is evaluated
		Then the output should be "625"
		
	Scenario: when a boolean is applied with one argument if it is true it should return the arg and default to false for second
		Given the input ((5 = 5) "yeah boy" "nope")
		When the input is evaluated 
		Then the output should be {"yeah boy"}