<?php

namespace Soy;

require_once 'runtime.php';

function tokenize($form) {
	return explode(' ', trim(preg_replace('/\s\s+/', ' ', str_replace(
		array('|', '(', ')', '{', '}', '[', ']', '\'', '`', '@', ',' , '.', "\n", "\t", ' list '), 
		array(' | ', ' ( ', ' ) ', ' { ', ' } ', ' [ ', ' ] ', ' \' ', ' ` ', ' @ ', ' , ', ' . ', ' ', ' ', ' _list '), 
		$form))));
}

function stripStrings($form) {
	$strings = array();

	$stringLength = strlen($form);
	
	$newForm = '';
	
	for($index = 0; $index < $stringLength; $index++) {
 		$char = $form[$index];

   		//handle comments
        if(!isset($subString) && !isset($comment) && $char == ';') {
			$comment = true;
		}
		
		if(isset($comment)) {
			if($char == "\n" || $char == "\r") {
				unset($comment);
			}
			continue;
		}        

    	//handle strings
		if(!isset($subString) && $char  == '"') {
			$escaped = false;
			$subString = '';
			continue;
		}
		
		if(isset($subString)) {
			if($char == '\\' && !$escaped) {
				$escaped = true;
				continue;
			}
			
			if($char == '"' && !$escaped) {
				$char = ' ' . chr(0) .'STRING' . count($strings) . ' ';

				$strings[$char] = $subString;
				
				unset($subString);
			} else {
				$subString .= $char;
				$escaped = false;
				continue;
			}
		}	
		
		//handle regular expressions
		if(!isset($regex) && $char == '/') {
			$escaped = false;
			$regex = '/';
			continue;
		}
		
		if(isset($regex)) {
			if($char == '\\' && !$escaped) {
				$escaped = true;
				continue;
			}
			
			if($char == '/' && !$escaped) {
				$char = ' ' . chr(0) . 'REGEX' . count($strings) . ' ';
				$strings[$char] = $regex . '/';
				unset($regex);
			} else {
				$regex .= $char;
				$escaped = false;
				continue;
			}
		}
		
		$newForm .= $char;
	}
		
	return array($newForm, $strings);
}

function cons($a, $b = array())
{
	array_unshift($b, $a);
	return $b;
}

class NativePHP
{
	private $code;
	
	public function __construct($code)
	{
		$this->code = $code;
	}
	
	public function __toString()
	{
		return $this->code;
	}
}

class SpecialForms { 
	static function apply($func, $args, &$env) {
		$mapped_args =  array_map(function($arg) use(&$env) { 			
			$result = process($arg, $env); 
			return is_array($result) ? process($result, $env) : $result;
		}, $args); 

		return  'Soy\apply(' . process($func, $env) . ', Soy\newList(' . 
				implode(',', $mapped_args). '))';
	}

	static function lambda($ast, &$env) {
		list($args, $body) = $ast;
			
		$uses = array();
		$body = process($body, $uses);

		$lambdaArgs = implode(',', array_map(
			function($arg) { 
				return '$' . $arg; }, 
			$args));

		$lambdaUses = array_map(
			function($use) use(&$env) { 
				$env[$use] = true;
				return '&$' . $use; }, 
			array_diff(array_keys($uses), 
					   array_merge($args, array_keys($env))));
			
		$func = 'function(' . $lambdaArgs . ')' . 
				(!empty($lambdaUses) ? (' use(' . implode(',', $lambdaUses) .') ') : '') .
				' { return ' . (is_array($body) ? implode(";\n", $body) : $body) . '; }';
						
		return 'Soy\Closure::create(' . $func . ')'; //arrayToSexpr(cons('lambda', $ast)) . '\', \'' . $func . '\')';
	}
	
	static function define($ast, &$env) {
		list($name, $value) = $ast;
		return process($name, $env) . ' = ' . process($value, $env) . ";\n";
	}
	
	private static function quoteList($list, &$env, $checkUnquote = false) {
		foreach($list as $i => &$el) {
			if(!($checkUnquote && is_array($el) && current($el) == 'unquote')) {
				$el = array('quote', $el);
			}
		}
		return $list;
	}
	
	static function quote($ast, &$env) {
		list($node) = $ast;
		if(is_array($node)) {
			$node = self::quoteList($node, $env); 
			array_unshift($node, '_list');
			return process($node, $env);
		} else {
			return "'$node'";
		}
	}

	static function _list($ast, &$env) {		
		return 'Soy\newList(' . implode(',', array_map(function($element) use(&$env) { return process($element, $env); }, $ast)) . ')';
	}
	
	static function unquote($ast, &$env) {
		list($form) = $ast;
		return process($form, $env);
	}
	
	static function splice($ast, &$env) {
		list($form) = $ast;
		return process($form, $env);
	}
	
	static function quasiquote($ast, &$env) {
		list($elements) = $ast; 

		//handle quoting of single element
		if(!is_array($elements)) {
			return process(array('quote', $elements), $env);
		}
		
		$arrayValue = array();
		$spliceList = array();
		$index = 0;		
		foreach($elements as $i => $element) {
			if(is_array($element)) {
				if(current($element) == 'unquote') {
					if(is_array($element[1]) && current($element[1]) == 'splice') {
						//add to splice list
						$spliceList[$index] = process($element, $env); 
						$element = 'null';
					} else {
						$element = process($element, $env);
					}
				} else {
					//treat as list of quoted elements
					$element = self::_list(self::quoteList($element, $env, true), $env);
				}
			} else {
				$element = "'$element'";
			}
			
			$arrayValue[$index++] = $element;
		}
			
		$val = 'Soy\newList(' . implode(',', $arrayValue) . ')';

		if(!empty($spliceList)) {
			$spliceList = array_reverse($spliceList, true);
			foreach($spliceList as $atIndex => $value) {
				$val = "arraySplice($val, $atIndex, 1, $value)";
			}
		}

		return $val;
	}
}

function processNode($node, &$env) {
	//echo json_encode($node) . "\n";
	if(is_scalar($node) || $node instanceof NativePHP) { 
		return (string)$node;
	}
	
	static $specialForms = array('define', 'lambda', 'cond', 'quote', 'get', 'set!', '_list', 'quasiquote', 'unquote', 'splice');
	$car = array_shift($node);
	return new NativePHP(in_array($car, $specialForms) ? SpecialForms::$car($node, $env) : SpecialForms::apply($car, $node, $env));	
}

function process($ast, &$env) { 
 	if(!is_array($ast)) {
		if($ast instanceof NativePHP) {
			return (string)$ast;
		} else if(is_numeric($ast)) {
			return $ast;
		} else {
			$env[$ast] = true;
			return '$' . $ast;
		}
	} else {
		return is_scalar(current($ast)) || current($ast) instanceof NativePHP ? 
			processNode($ast, $env) : array_map(function($node) use(&$env) { return processNode($node, $env); }, $ast);
	}
}

function group($tokens) {
	static $brackets = array('(' => ')', '{' => '}', '[' => ']');
	static $prepends = array('\'' => 'quote', '`' => 'quasiquote', ',' => 'unquote', '@' => 'splice');
	
	$ast = array();
	foreach($tokens as $i => $token) {
		if(!isset($numberTokens) && is_numeric($token) && isset($tokens[$i + 1]) && $tokens[$i + 1] == '.') {
			$numberTokens = array($token);
			continue;
		}
		
		if(isset($numberTokens)) {
			$numberTokens[] = $token;	
			if(count($numberTokens) == 3) {
				$token = implode('', $numberTokens);
				unset($numberTokens);
			} else {
				continue;
			}
		}
		
		if(isset($bracketTokens)) {
			if($token == $bracketType) {
				$bracketCount++;
			}
			
			if($token == $brackets[$bracketType]) {
				$bracketCount--;
			} 
			
			if($bracketCount == 0) {
				$token = group($bracketTokens);
				
				if($bracketType == '[') {
					if(!is_array(current($token))) {
						$token = array(array(), $token);
					}
					array_unshift($token, 'lambda'); ;
				}
				
				if($bracketType == '{') {
					array_unshift($token, is_array($token[0]) && $token[0][0] == 'keyword' ? 'dict' : 'list');
				}
				
				unset($bracketTokens);
			} else {
				$bracketTokens[] = $token;
				continue;
			}
		}
		
		if(is_scalar($token) && isset($brackets[$token])) {
			$bracketTokens = array();
			$bracketCount = 1;
			$bracketType = $token;
			continue;
		}

		if(is_scalar($token)) {
			if(is_string($token) && substr($token, -1) == '#') {
				$token = array('gensym', substr($token, 0, -1));
			}
			
			if(is_string($token) && $token[0] == ':' || substr($token, -1) == ':') {
				$token = array('keyword', str_replace(':', '', $token));
			}
			
			if(!isset($prepend) && $token == '|') {
				$prependArgs = $ast;
				$ast = array();
				continue;
			}
			
			if(is_scalar($token) && isset($prepends[$token])) {
				if(!isset($prepend)) {
					$prepend = array();
				}
				array_unshift($prepend, $prepends[$token]);
				continue;
			}
		}
	
		if(isset($prepend)) {
			foreach($prepend as $prependWith) {
				$token = array($prependWith, $token);
			}
			
			unset($prepend);
		}
		
		$ast[] = $token;
	}
	
	if(isset($prependArgs)) {
		$ast = array($prependArgs, $ast);
	}
	return $ast;
}

function parse($lispCode, &$env = array()) {
	list($lispCode, $strings) = stripStrings($lispCode); 

	$grouped = group(tokenize($lispCode));
	
	//pull out all macros, compile, require so they may be applied by parser
	
	//loop recursively, expand macros
	
	
	return implode(";\n", process($grouped, $env)) . ";\n";
}

if(isset($argv[1])) {
	echo parse(file_get_contents($argv[1]));
} else {
	echo "Expects first argument to be valid name of file containing lisp forms.\n";
} 
