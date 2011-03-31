<?php

namespace Soy;

require_once 'system.php';

class Closure {
	private $func; 
	private $lisp;
	private $php;
	
	public function __construct($func, $lisp = false, $php = false) 
	{
		$this->func = $func;
		$this->lisp = $lisp;
		$this->php = $php;
	}
	
	public function __invoke()
	{
		return call_user_func_array($this->func, func_get_args());
	}

	public static function create($func, $lisp = false, $php = false)
	{
		$instance = new Closure($func, $lisp, $php);
		return $instance;
	}
}

class Bounce { 
	private $func; 
	
	public function __construct($func) {
		$this->func = $func;
	}
	
	public function __invoke() {
		return call_user_func_array($this->func, array());
	}
}

function apply($func, $args) { 
	$return = call_user_func_array($func, (array)$args);
	while($return instanceof Bounce) {
		$return = $return();
	}
	return $return;
}

class LispList extends \ArrayObject {
        public function __invoke() {
                $args = func_get_args();
                if(count($args) == 1) {
                        return $this[current($args)];
                } else {
                        $this[array_shift($args)] = current($args);
                        return current($args);
                }
        }
}

function newList() {
        $obj = new LispList(func_get_args());
        return $obj;
}

function arraySplice($array, $pos, $len, $value) {
        $array = (array)$array;
        array_splice($array, $pos, $len, $value);
        $new = new LispList($array);
        return $new;
}

function arrayAt($array, $key) {
	return $array[$key];
}

function arrayToSexpr($array) {
	return '(' . implode(' ', array_map(function($atom) { return is_array($atom) ? arrayToSexpr($atom) : $atom;}, $array)) . ')';
}
