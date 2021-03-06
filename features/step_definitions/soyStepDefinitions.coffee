module.exports = ->
	@World = require("../support/world").World 

	@Given /^the input: ("[^"]*")$/, (input, next) ->
		@input = input
		next()

	@Given /^the input: \{(.*)\}$/, (input, next) ->
		@input = input
		next()
			
	@Given /^the input "([^"]*)"$/, (input, next) ->
		@input = input
		next()

	@Given /^the input (.*)$/, (input, next) ->
		@input = input
		next()
		
	@When /^the input is parsed/, (next) ->
		@output = @soy.to_string @soy.expand @soy.desugar @soy.parse @input
		next()
		
	@Then /^the output should be "([^"]*)"$/, (expected_output, next) -> 
		if String(@output) is String(expected_output)
			next()
		else 
			throw "Failure Input: #{@input} Expected: #{expected_output} Got: #{@output}"

	@Then /^the output should be \{(.*)\}$/, (expected_output, next) -> 
		if String(@output) is String(expected_output)
			next()
		else 
			throw "Failure Input: #{@input} Expected: #{expected_output} Got: #{@output}"
		
	@Given /^the macro "([^"]*)"$/, (macro, next) ->
		next.pending()
		
	@When /^the input is compiled to javascript$/, (next) ->
		next.pending()
	
	@When /^the input is evaluated$/, (next) ->
		@output = @soy.to_string @soy.eval @soy.expand(@soy.desugar(@soy.parse @input), true)
		next()
		
	@Then /^the variable "([^"]*)" should contain "([^"]*)"$/, (varName, property, next) -> 
		if not @soy.topLevel.find(varName).at(varName)
			throw "Could not found #{varName}"
		else
			next()
	
	@When /^the macro is expanded$/, (next) ->
		next.pending()