module.exports = ->
	@World = require("../support/world").World 

	@Given /^the input: ("[^"]*")$/, (input, next) ->
		@input = input
		next()
		
	@Given /^the input "([^"]*)"$/, (input, next) ->
		@input = input
		next()

	@When /^the input is parsed/, (next) ->
		@output = @soy.to_string @soy.parse(@input)
		next()
		
	@Then /^the output should be "([^"]*)"$/, (expected_output, next) -> 
		if @output is expected_output
			next()
		else 
			throw "Failure Input: #{@input} Expected: #{expected_output} Got: #{@output}"
	
	@Then /^the output should be: ("[^"]*")$/, (output, next) ->
		
		next()
		
	@Given /^the macro "([^"]*)"$/, (macro, next) ->
		next.pending()
		
	@When /^the input is compiled to javascript$/, (next) ->
		next.pending()
	
	@When /^the input is evaluated$/, (next) ->
		next.pending()
		
	@Then /^the variable "([^"]*)" should contain "([^"]*)"$/, (varName, property, next) -> 
		next.pending()
	
	@When /^the macro is expanded$/, (next) ->
		next.pending()