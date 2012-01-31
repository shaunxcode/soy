Feature: Runtime capabilities
	there are some things which have to be possible at run time
	
	Scenario: tail recursion
		Given the input "(let even: [n | if (= n 0) #t (odd (- n 1))] odd: [n | if (= n 0) #f (even (- n 1))] (even 666))"
		When the input is evaluated
		Then the output should be "true"