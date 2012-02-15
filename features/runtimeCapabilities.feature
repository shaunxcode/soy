Feature: Runtime capabilities
	there are some things which have to be possible at run time
	
	Scenario: tail recursion
		Given the input "(define even [n | if (= n 0) #t (odd (- n 1))])"
		When the input is evaluated
		And the input "(define odd [n | if (= n 0) #f (even (- n 1))])"
		And the input is evaluated
		And the input "(even 666))"
		And the input is evaluated
		Then the output should be "#t"