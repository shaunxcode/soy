#!/usr/bin/env coffee
exec = require('child_process').exec;

count = 0
require('watchr').watch './', -> 
	count++
	console.log "Start build #{count}"
	exec "./build.sh", (error, stdout, stderr) ->
		console.log if error then stderr else stdout
		console.log "Finished build #{count}"