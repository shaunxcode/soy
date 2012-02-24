Feature: node package integration
	As a developer using soy
	I want to be able to easily utilize and export packages

	Scenario: Utilizing a package via require
		Given the input (define fs (require 'fs))
		When the input is evaluated
		Then the variable "fs" should contain "open"
		And the variable "fs" should contain "openSync"