module.exports = ->
	@World = require("../support/world").World 

	@Given /^the input "([^"]*)"$/, (input, next) ->
		@input = input
		next()

	@When /^the input is parsed/, (next) ->
		@output = @soy.to_string @soy.parse(@input)
		next()
		
	@Then /^the output should be "([^"]*)"$/, (expected_output, next) -> 
		if @output is expected_output then next()

		throw "Failure got " +  @output + " Should have been " + expected_output