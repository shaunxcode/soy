var Soy = {};

Soy.Bounce = function(proc) {
	this.proc = proc;
};

Soy.apply = function(proc, args) {
	var result = proc.apply({}, args);

	while(result instanceof Soy.Bounce) {
		result = result.proc();
	}

	return result
};

window._alert = window.alert;
window.alert = function(arg) { 
	return _alert(arg);
};