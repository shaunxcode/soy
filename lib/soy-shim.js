window.require = function() {}
window.Soy = {
	apply: function(func, args) { 
		var result = func.apply({}, args);
		
		while(result instanceof Soy.Bounce) {
			result = result.proc();
		}
		
		return result;
	},
	
	Bounce: function(func) {
		this.func = func;
	}, 
	
	env: {}
}

window.exports = window.Soy

$(function(){
	var repl = $(".repl");
	var replHandle = $(".repl-handle").toggle(function(){
		repl.animate({height: 22});
	}, function(){
		repl.animate({height: 300}, "normal", function(){
			replInput.focus();
		});
	});
	
	var replText = $('.repl-text').click(function(){
		replInput.focus();
	});
	var replHistory = [];
	var replHistoryAt = 0;
	var replInput = $('.repl-input').keydown(function(e) {
		//enter
		if(e.keyCode == 13) {
			var input = replInput.val();
			replText.append("<div>soy> " + input + "</div>");
			replHistory.push(input);
			replHistoryAt = replHistory.length;
			
			try { 
				if(input[0] != "(" && input[0] != "{" && input[0] != '"' && input[0] != "`" && input[0] != "'") {
					input = "(value (" + input + "))";
				}
				
				var output = Soy.to_string(Soy.readEval(input));
			} catch (e) {
				var output = e;
			}
			
			replText.append("<div>" + output + "</div>");
			replText.scrollTop(replText.prop('scrollHeight'));
			replInput.val('');
		}
		
		//up
		if(e.keyCode == 38) {
			replHistoryAt--;
			if(replHistoryAt < 0) {
				replHistoryAt = 0;
			}
			replInput.val(replHistory[replHistoryAt]).focus();
		}
		
		//down
		if(e.keyCode == 40) {
			replHistoryAt++; 
			if(replHistoryAt > (replHistory.length - 1)) {
				replHistoryAt = replHistory.length - 1;
			}
			replInput.val(replHistory[replHistoryAt]).focus();
		}
	}).focus();
});
