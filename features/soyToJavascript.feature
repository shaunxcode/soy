Feature: Soy to javascript
	As a developer using soy
	I want to be able to compile to javascript
	
	Scenario: lambda
		Given the input "[x | + x 6]"
		When the input is compiled to javascript
		Then the output should be "(function(x) { return x + 6; })"
