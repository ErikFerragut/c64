(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

console.warn('Compiled in DEV mode. Follow the advice at https://elm-lang.org/0.19.1/optimize for better performance and smaller assets.');


// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**_UNUSED/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**_UNUSED/
	if (typeof x.$ === 'undefined')
	//*/
	/**/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0_UNUSED = 0;
var _Utils_Tuple0 = { $: '#0' };

function _Utils_Tuple2_UNUSED(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3_UNUSED(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr_UNUSED(c) { return c; }
function _Utils_chr(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil_UNUSED = { $: 0 };
var _List_Nil = { $: '[]' };

function _List_Cons_UNUSED(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log_UNUSED = F2(function(tag, value)
{
	return value;
});

var _Debug_log = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString_UNUSED(value)
{
	return '<internals>';
}

function _Debug_toString(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash_UNUSED(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.start.line === region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'on lines ' + region.start.line + ' through ' + region.end.line;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap(value) { return { $: 0, a: value }; }
function _Json_unwrap(value) { return value.a; }

function _Json_wrap_UNUSED(value) { return value; }
function _Json_unwrap_UNUSED(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**_UNUSED/
	var node = args['node'];
	//*/
	/**/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**_UNUSED/''//*//**/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		message: func(record.message),
		stopPropagation: record.stopPropagation,
		preventDefault: record.preventDefault
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.message;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.stopPropagation;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.preventDefault) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var view = impl.view;
			/**_UNUSED/
			var domNode = args['node'];
			//*/
			/**/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.setup && impl.setup(sendToApp)
			var view = impl.view;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.body);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.title) && (_VirtualDom_doc.title = title = doc.title);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.onUrlChange;
	var onUrlRequest = impl.onUrlRequest;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		setup: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.protocol === next.protocol
							&& curr.host === next.host
							&& curr.port_.a === next.port_.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		init: function(flags)
		{
			return A3(impl.init, flags, _Browser_getUrl(), key);
		},
		view: impl.view,
		update: impl.update,
		subscriptions: impl.subscriptions
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { hidden: 'hidden', change: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { hidden: 'mozHidden', change: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { hidden: 'msHidden', change: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { hidden: 'webkitHidden', change: 'webkitvisibilitychange' }
		: { hidden: 'hidden', change: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		scene: _Browser_getScene(),
		viewport: {
			x: _Browser_window.pageXOffset,
			y: _Browser_window.pageYOffset,
			width: _Browser_doc.documentElement.clientWidth,
			height: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		width: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		height: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			scene: {
				width: node.scrollWidth,
				height: node.scrollHeight
			},
			viewport: {
				x: node.scrollLeft,
				y: node.scrollTop,
				width: node.clientWidth,
				height: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			scene: _Browser_getScene(),
			viewport: {
				x: x,
				y: y,
				width: _Browser_doc.documentElement.clientWidth,
				height: _Browser_doc.documentElement.clientHeight
			},
			element: {
				x: x + rect.left,
				y: y + rect.top,
				width: rect.width,
				height: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});
var $elm$core$Basics$EQ = {$: 'EQ'};
var $elm$core$Basics$GT = {$: 'GT'};
var $elm$core$Basics$LT = {$: 'LT'};
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0.a;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (node.$ === 'SubTree') {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 'Err', a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 'Failure', a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 'Index', a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 'Ok', a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 'OneOf', a: a};
};
var $elm$core$Basics$False = {$: 'False'};
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 'Just', a: a};
};
var $elm$core$Maybe$Nothing = {$: 'Nothing'};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 'Field':
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 'Nothing') {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'Index':
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'OneOf':
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 'Array_elm_builtin', a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 'Leaf', a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 'SubTree', a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.nodeListSize) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.tail);
		} else {
			var treeLen = builder.nodeListSize * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.nodeList) : builder.nodeList;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.nodeListSize);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.tail);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{nodeList: nodeList, nodeListSize: (len / $elm$core$Array$branchFactor) | 0, tail: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = {$: 'True'};
var $elm$core$Result$isOk = function (result) {
	if (result.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 'Normal':
			return 0;
		case 'MayStopPropagation':
			return 1;
		case 'MayPreventDefault':
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 'External', a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 'Internal', a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = function (a) {
	return {$: 'NotFound', a: a};
};
var $elm$url$Url$Http = {$: 'Http'};
var $elm$url$Url$Https = {$: 'Https'};
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {fragment: fragment, host: host, path: path, port_: port_, protocol: protocol, query: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 'Nothing') {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Http,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Https,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0.a;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = function (a) {
	return {$: 'Perform', a: a};
};
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(_Utils_Tuple0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0.a;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return _Utils_Tuple0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(_Utils_Tuple0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0.a;
		return $elm$core$Task$Perform(
			A2($elm$core$Task$map, tagger, task));
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2($elm$core$Task$map, toMessage, task)));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$Main$GotViewport = function (a) {
	return {$: 'GotViewport', a: a};
};
var $elm$browser$Browser$Dom$getViewport = _Browser_withWindow(_Browser_getViewport);
var $elm$core$Dict$RBEmpty_elm_builtin = {$: 'RBEmpty_elm_builtin'};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$core$Set$Set_elm_builtin = function (a) {
	return {$: 'Set_elm_builtin', a: a};
};
var $elm$core$Set$empty = $elm$core$Set$Set_elm_builtin($elm$core$Dict$empty);
var $author$project$Types$initModel = {bytes: $elm$core$Array$empty, comments: $elm$core$Dict$empty, confirmQuit: false, dirty: false, editingComment: $elm$core$Maybe$Nothing, editingLabel: $elm$core$Maybe$Nothing, editingMajorComment: $elm$core$Maybe$Nothing, fileName: '', gotoError: false, gotoInput: '', gotoMode: false, helpExpanded: false, jumpHistory: _List_Nil, labels: $elm$core$Dict$empty, loadAddress: 0, majorComments: $elm$core$Dict$empty, mark: $elm$core$Maybe$Nothing, outlineMode: false, outlineSelection: 0, regions: _List_Nil, restartPoints: $elm$core$Set$empty, segments: _List_Nil, selectedOffset: $elm$core$Maybe$Nothing, viewLines: 25, viewStart: 0};
var $author$project$Main$init = function (_v0) {
	return _Utils_Tuple2(
		$author$project$Types$initModel,
		A2($elm$core$Task$perform, $author$project$Main$GotViewport, $elm$browser$Browser$Dom$getViewport));
};
var $author$project$Main$CdisSaved = {$: 'CdisSaved'};
var $author$project$Main$ErrorOccurred = function (a) {
	return {$: 'ErrorOccurred', a: a};
};
var $author$project$Main$PrgFileOpened = function (a) {
	return {$: 'PrgFileOpened', a: a};
};
var $author$project$Main$WindowResized = F2(
	function (a, b) {
		return {$: 'WindowResized', a: a, b: b};
	});
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$json$Json$Decode$null = _Json_decodeNull;
var $author$project$Main$cdisSaved = _Platform_incomingPort(
	'cdisSaved',
	$elm$json$Json$Decode$null(_Utils_Tuple0));
var $elm$browser$Browser$Events$Window = {$: 'Window'};
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 'MySub', a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {pids: pids, subs: subs};
	});
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (node.$ === 'Document') {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Dict$Black = {$: 'Black'};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: 'RBNode_elm_builtin', a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = {$: 'Red'};
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Red')) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) && (left.d.$ === 'RBNode_elm_builtin')) && (left.d.a.$ === 'Red')) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1.$) {
				case 'LT':
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 'EQ':
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {event: event, key: key};
	});
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (node.$ === 'Document') {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.pids,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (_v0.$ === 'Just') {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.key;
		var event = _v0.event;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.subs);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onResize = function (func) {
	return A3(
		$elm$browser$Browser$Events$on,
		$elm$browser$Browser$Events$Window,
		'resize',
		A2(
			$elm$json$Json$Decode$field,
			'target',
			A3(
				$elm$json$Json$Decode$map2,
				func,
				A2($elm$json$Json$Decode$field, 'innerWidth', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'innerHeight', $elm$json$Json$Decode$int))));
};
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Main$prgFileOpened = _Platform_incomingPort('prgFileOpened', $elm$json$Json$Decode$value);
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Main$showError = _Platform_incomingPort('showError', $elm$json$Json$Decode$string);
var $author$project$Main$subscriptions = function (_v0) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$author$project$Main$prgFileOpened($author$project$Main$PrgFileOpened),
				$author$project$Main$cdisSaved(
				function (_v1) {
					return $author$project$Main$CdisSaved;
				}),
				$author$project$Main$showError($author$project$Main$ErrorOccurred),
				$elm$browser$Browser$Events$onResize($author$project$Main$WindowResized)
			]));
};
var $author$project$Types$ByteRegion = {$: 'ByteRegion'};
var $author$project$Main$CancelGoto = {$: 'CancelGoto'};
var $author$project$Main$CancelOutline = {$: 'CancelOutline'};
var $author$project$Main$CancelQuit = {$: 'CancelQuit'};
var $author$project$Main$ClearByteRegion = function (a) {
	return {$: 'ClearByteRegion', a: a};
};
var $author$project$Main$ClearSegment = function (a) {
	return {$: 'ClearSegment', a: a};
};
var $author$project$Main$ClearTextRegion = function (a) {
	return {$: 'ClearTextRegion', a: a};
};
var $author$project$Main$ClickAddress = function (a) {
	return {$: 'ClickAddress', a: a};
};
var $author$project$Main$ConfirmQuit = {$: 'ConfirmQuit'};
var $author$project$Main$EnterGotoMode = {$: 'EnterGotoMode'};
var $author$project$Main$EnterOutlineMode = {$: 'EnterOutlineMode'};
var $author$project$Main$ExecuteGoto = {$: 'ExecuteGoto'};
var $author$project$Main$ExportAsm = {$: 'ExportAsm'};
var $author$project$Main$FocusResult = {$: 'FocusResult'};
var $author$project$Main$GotLinesElement = function (a) {
	return {$: 'GotLinesElement', a: a};
};
var $author$project$Main$JumpBack = {$: 'JumpBack'};
var $author$project$Main$MarkSelectionAsBytes = {$: 'MarkSelectionAsBytes'};
var $author$project$Main$MarkSelectionAsSegment = {$: 'MarkSelectionAsSegment'};
var $author$project$Main$MarkSelectionAsText = {$: 'MarkSelectionAsText'};
var $author$project$Main$NoOp = {$: 'NoOp'};
var $author$project$Main$OutlineNext = {$: 'OutlineNext'};
var $author$project$Main$OutlinePrev = {$: 'OutlinePrev'};
var $author$project$Main$OutlineSelect = {$: 'OutlineSelect'};
var $author$project$Main$PageDown = {$: 'PageDown'};
var $author$project$Main$PageUp = {$: 'PageUp'};
var $author$project$Main$RequestQuit = {$: 'RequestQuit'};
var $author$project$Main$RestartDisassembly = {$: 'RestartDisassembly'};
var $author$project$Main$SaveProject = {$: 'SaveProject'};
var $author$project$Main$SelectNextLine = {$: 'SelectNextLine'};
var $author$project$Main$SelectPrevLine = {$: 'SelectPrevLine'};
var $author$project$Main$StartEditComment = function (a) {
	return {$: 'StartEditComment', a: a};
};
var $author$project$Main$StartEditLabel = function (a) {
	return {$: 'StartEditLabel', a: a};
};
var $author$project$Main$StartEditMajorComment = function (a) {
	return {$: 'StartEditMajorComment', a: a};
};
var $author$project$Types$TextRegion = {$: 'TextRegion'};
var $author$project$Main$ToggleHelp = {$: 'ToggleHelp'};
var $author$project$Main$ToggleMark = {$: 'ToggleMark'};
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$core$Task$onError = _Scheduler_onError;
var $elm$core$Task$attempt = F2(
	function (resultToMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2(
					$elm$core$Task$onError,
					A2(
						$elm$core$Basics$composeL,
						A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
						$elm$core$Result$Err),
					A2(
						$elm$core$Task$andThen,
						A2(
							$elm$core$Basics$composeL,
							A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
							$elm$core$Result$Ok),
						task))));
	});
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Basics$clamp = F3(
	function (low, high, number) {
		return (_Utils_cmp(number, low) < 0) ? low : ((_Utils_cmp(number, high) > 0) ? high : number);
	});
var $elm$core$Array$length = function (_v0) {
	var len = _v0.a;
	return len;
};
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Main$centerSelectedLine = function (model) {
	var _v0 = model.selectedOffset;
	if (_v0.$ === 'Just') {
		var offset = _v0.a;
		var targetStart = offset - ((model.viewLines / 2) | 0);
		var maxOffset = A2(
			$elm$core$Basics$max,
			0,
			$elm$core$Array$length(model.bytes) - model.viewLines);
		var newStart = A3($elm$core$Basics$clamp, 0, maxOffset, targetStart);
		return _Utils_Tuple2(
			_Utils_update(
				model,
				{viewStart: newStart}),
			$elm$core$Platform$Cmd$none);
	} else {
		return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
	}
};
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $author$project$Project$SaveData = F8(
	function (version, fileName, loadAddress, comments, labels, regions, segments, majorComments) {
		return {comments: comments, fileName: fileName, labels: labels, loadAddress: loadAddress, majorComments: majorComments, regions: regions, segments: segments, version: version};
	});
var $author$project$Project$currentVersion = 4;
var $elm$core$Tuple$pair = F2(
	function (a, b) {
		return _Utils_Tuple2(a, b);
	});
var $author$project$Project$decodeComment = A3(
	$elm$json$Json$Decode$map2,
	$elm$core$Tuple$pair,
	A2($elm$json$Json$Decode$field, 'offset', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'text', $elm$json$Json$Decode$string));
var $author$project$Project$decodeLabel = A3(
	$elm$json$Json$Decode$map2,
	$elm$core$Tuple$pair,
	A2($elm$json$Json$Decode$field, 'address', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'name', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$list = _Json_decodeList;
var $elm$json$Json$Decode$map8 = _Json_map8;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Project$optionalField = F3(
	function (field, dec, _default) {
		return A2(
			$elm$json$Json$Decode$map,
			$elm$core$Maybe$withDefault(_default),
			$elm$json$Json$Decode$maybe(
				A2($elm$json$Json$Decode$field, field, dec)));
	});
var $author$project$Project$decodeV1 = A9(
	$elm$json$Json$Decode$map8,
	$author$project$Project$SaveData,
	$elm$json$Json$Decode$succeed($author$project$Project$currentVersion),
	A2($elm$json$Json$Decode$field, 'fileName', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'loadAddress', $elm$json$Json$Decode$int),
	A3(
		$author$project$Project$optionalField,
		'comments',
		$elm$json$Json$Decode$list($author$project$Project$decodeComment),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'labels',
		$elm$json$Json$Decode$list($author$project$Project$decodeLabel),
		_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil));
var $author$project$Project$decodeV2 = A9(
	$elm$json$Json$Decode$map8,
	$author$project$Project$SaveData,
	$elm$json$Json$Decode$succeed($author$project$Project$currentVersion),
	A2($elm$json$Json$Decode$field, 'fileName', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'loadAddress', $elm$json$Json$Decode$int),
	A3(
		$author$project$Project$optionalField,
		'comments',
		$elm$json$Json$Decode$list($author$project$Project$decodeComment),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'labels',
		$elm$json$Json$Decode$list($author$project$Project$decodeLabel),
		_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil));
var $author$project$Project$decodeDataRegionAsRegion = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (s, e) {
			return {end: e, regionType: 'byte', start: s};
		}),
	A2($elm$json$Json$Decode$field, 'start', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'end', $elm$json$Json$Decode$int));
var $author$project$Project$decodeV3 = A9(
	$elm$json$Json$Decode$map8,
	$author$project$Project$SaveData,
	$elm$json$Json$Decode$succeed($author$project$Project$currentVersion),
	A2($elm$json$Json$Decode$field, 'fileName', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'loadAddress', $elm$json$Json$Decode$int),
	A3(
		$author$project$Project$optionalField,
		'comments',
		$elm$json$Json$Decode$list($author$project$Project$decodeComment),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'labels',
		$elm$json$Json$Decode$list($author$project$Project$decodeLabel),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'dataRegions',
		$elm$json$Json$Decode$list($author$project$Project$decodeDataRegionAsRegion),
		_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil),
	$elm$json$Json$Decode$succeed(_List_Nil));
var $author$project$Project$decodeMajorComment = A3(
	$elm$json$Json$Decode$map2,
	$elm$core$Tuple$pair,
	A2($elm$json$Json$Decode$field, 'offset', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'text', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$map3 = _Json_map3;
var $author$project$Project$decodeRegion = A4(
	$elm$json$Json$Decode$map3,
	F3(
		function (s, e, t) {
			return {end: e, regionType: t, start: s};
		}),
	A2($elm$json$Json$Decode$field, 'start', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'end', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'regionType', $elm$json$Json$Decode$string));
var $author$project$Project$decodeSegment = A3(
	$elm$json$Json$Decode$map2,
	F2(
		function (s, e) {
			return {end: e, start: s};
		}),
	A2($elm$json$Json$Decode$field, 'start', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'end', $elm$json$Json$Decode$int));
var $author$project$Project$decodeV4 = A9(
	$elm$json$Json$Decode$map8,
	$author$project$Project$SaveData,
	$elm$json$Json$Decode$succeed($author$project$Project$currentVersion),
	A2($elm$json$Json$Decode$field, 'fileName', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'loadAddress', $elm$json$Json$Decode$int),
	A3(
		$author$project$Project$optionalField,
		'comments',
		$elm$json$Json$Decode$list($author$project$Project$decodeComment),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'labels',
		$elm$json$Json$Decode$list($author$project$Project$decodeLabel),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'regions',
		$elm$json$Json$Decode$list($author$project$Project$decodeRegion),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'segments',
		$elm$json$Json$Decode$list($author$project$Project$decodeSegment),
		_List_Nil),
	A3(
		$author$project$Project$optionalField,
		'majorComments',
		$elm$json$Json$Decode$list($author$project$Project$decodeMajorComment),
		_List_Nil));
var $elm$json$Json$Decode$fail = _Json_fail;
var $author$project$Project$decoderForVersion = function (version) {
	switch (version) {
		case 1:
			return $author$project$Project$decodeV1;
		case 2:
			return $author$project$Project$decodeV2;
		case 3:
			return $author$project$Project$decodeV3;
		case 4:
			return $author$project$Project$decodeV4;
		default:
			return $elm$json$Json$Decode$fail(
				'Unknown save file version: ' + $elm$core$String$fromInt(version));
	}
};
var $author$project$Project$decoder = A2(
	$elm$json$Json$Decode$andThen,
	$author$project$Project$decoderForVersion,
	A2($elm$json$Json$Decode$field, 'version', $elm$json$Json$Decode$int));
var $elm$core$String$fromList = _String_fromList;
var $elm$core$Char$fromCode = _Char_fromCode;
var $elm$core$Basics$ge = _Utils_ge;
var $author$project$Disassembler$toPetscii = function (_byte) {
	return ((_byte >= 32) && (_byte <= 63)) ? $elm$core$Char$fromCode(_byte) : (((_byte >= 64) && (_byte <= 90)) ? $elm$core$Char$fromCode(_byte) : (((_byte >= 91) && (_byte <= 95)) ? $elm$core$Char$fromCode(_byte) : (((_byte >= 96) && (_byte <= 127)) ? $elm$core$Char$fromCode(57408 + (_byte - 96)) : (((_byte >= 160) && (_byte <= 191)) ? $elm$core$Char$fromCode(57440 + (_byte - 160)) : (((_byte >= 193) && (_byte <= 218)) ? $elm$core$Char$fromCode(97 + (_byte - 193)) : ((_byte === 192) ? $elm$core$Char$fromCode(57408) : (((_byte >= 219) && (_byte <= 223)) ? $elm$core$Char$fromCode(57435 + (_byte - 219)) : (((_byte >= 224) && (_byte <= 255)) ? $elm$core$Char$fromCode(57440 + (_byte - 224)) : _Utils_chr('·')))))))));
};
var $author$project$Disassembler$bytesToPetscii = function (byteList) {
	return $elm$core$String$fromList(
		A2($elm$core$List$map, $author$project$Disassembler$toPetscii, byteList));
};
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$core$Array$bitMask = 4294967295 >>> (32 - $elm$core$Array$shiftStep);
var $elm$core$Elm$JsArray$unsafeGet = _JsArray_unsafeGet;
var $elm$core$Array$getHelp = F3(
	function (shift, index, tree) {
		getHelp:
		while (true) {
			var pos = $elm$core$Array$bitMask & (index >>> shift);
			var _v0 = A2($elm$core$Elm$JsArray$unsafeGet, pos, tree);
			if (_v0.$ === 'SubTree') {
				var subTree = _v0.a;
				var $temp$shift = shift - $elm$core$Array$shiftStep,
					$temp$index = index,
					$temp$tree = subTree;
				shift = $temp$shift;
				index = $temp$index;
				tree = $temp$tree;
				continue getHelp;
			} else {
				var values = _v0.a;
				return A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, values);
			}
		}
	});
var $elm$core$Bitwise$shiftLeftBy = _Bitwise_shiftLeftBy;
var $elm$core$Array$tailIndex = function (len) {
	return (len >>> 5) << 5;
};
var $elm$core$Array$get = F2(
	function (index, _v0) {
		var len = _v0.a;
		var startShift = _v0.b;
		var tree = _v0.c;
		var tail = _v0.d;
		return ((index < 0) || (_Utils_cmp(index, len) > -1)) ? $elm$core$Maybe$Nothing : ((_Utils_cmp(
			index,
			$elm$core$Array$tailIndex(len)) > -1) ? $elm$core$Maybe$Just(
			A2($elm$core$Elm$JsArray$unsafeGet, $elm$core$Array$bitMask & index, tail)) : $elm$core$Maybe$Just(
			A3($elm$core$Array$getHelp, startShift, index, tree)));
	});
var $author$project$Disassembler$collectTextBytes = F4(
	function (current, end, bytes, acc) {
		collectTextBytes:
		while (true) {
			if (_Utils_cmp(current, end) > 0) {
				return $elm$core$List$reverse(acc);
			} else {
				var _v0 = A2($elm$core$Array$get, current, bytes);
				if (_v0.$ === 'Just') {
					var _byte = _v0.a;
					var $temp$current = current + 1,
						$temp$end = end,
						$temp$bytes = bytes,
						$temp$acc = A2($elm$core$List$cons, _byte, acc);
					current = $temp$current;
					end = $temp$end;
					bytes = $temp$bytes;
					acc = $temp$acc;
					continue collectTextBytes;
				} else {
					return $elm$core$List$reverse(acc);
				}
			}
		}
	});
var $author$project$Disassembler$computeTargetAddress = F5(
	function (mode, operand, instrAddress, loadAddress, endAddress) {
		var inRange = function (addr) {
			return ((_Utils_cmp(addr, loadAddress) > -1) && (_Utils_cmp(addr, endAddress) < 0)) ? $elm$core$Maybe$Just(addr) : $elm$core$Maybe$Nothing;
		};
		switch (mode.$) {
			case 'Implied':
				return $elm$core$Maybe$Nothing;
			case 'Accumulator':
				return $elm$core$Maybe$Nothing;
			case 'Immediate':
				return $elm$core$Maybe$Nothing;
			case 'ZeroPage':
				return inRange(operand);
			case 'ZeroPageX':
				return inRange(operand);
			case 'ZeroPageY':
				return inRange(operand);
			case 'Absolute':
				return inRange(operand);
			case 'AbsoluteX':
				return inRange(operand);
			case 'AbsoluteY':
				return inRange(operand);
			case 'Indirect':
				return inRange(operand);
			case 'IndirectX':
				return inRange(operand);
			case 'IndirectY':
				return inRange(operand);
			default:
				var signedOffset = (operand > 127) ? (operand - 256) : operand;
				return inRange((instrAddress + 2) + signedOffset);
		}
	});
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$String$cons = _String_cons;
var $elm$core$String$fromChar = function (_char) {
	return A2($elm$core$String$cons, _char, '');
};
var $elm$core$Bitwise$shiftRightBy = _Bitwise_shiftRightBy;
var $elm$core$String$repeatHelp = F3(
	function (n, chunk, result) {
		return (n <= 0) ? result : A3(
			$elm$core$String$repeatHelp,
			n >> 1,
			_Utils_ap(chunk, chunk),
			(!(n & 1)) ? result : _Utils_ap(result, chunk));
	});
var $elm$core$String$repeat = F2(
	function (n, chunk) {
		return A3($elm$core$String$repeatHelp, n, chunk, '');
	});
var $elm$core$String$padLeft = F3(
	function (n, _char, string) {
		return _Utils_ap(
			A2(
				$elm$core$String$repeat,
				n - $elm$core$String$length(string),
				$elm$core$String$fromChar(_char)),
			string);
	});
var $elm$core$Basics$modBy = _Basics_modBy;
var $elm$core$Basics$not = _Basics_not;
var $author$project$Disassembler$toHexHelper = F2(
	function (n, acc) {
		toHexHelper:
		while (true) {
			if ((!n) && (!$elm$core$String$isEmpty(acc))) {
				return acc;
			} else {
				if (!n) {
					return '0';
				} else {
					var digit = A2($elm$core$Basics$modBy, 16, n);
					var _char = function () {
						switch (digit) {
							case 10:
								return 'A';
							case 11:
								return 'B';
							case 12:
								return 'C';
							case 13:
								return 'D';
							case 14:
								return 'E';
							case 15:
								return 'F';
							default:
								return $elm$core$String$fromInt(digit);
						}
					}();
					var $temp$n = (n / 16) | 0,
						$temp$acc = _Utils_ap(_char, acc);
					n = $temp$n;
					acc = $temp$acc;
					continue toHexHelper;
				}
			}
		}
	});
var $elm$core$String$toUpper = _String_toUpper;
var $author$project$Disassembler$toHex = F2(
	function (width, n) {
		var hex = A2($author$project$Disassembler$toHexHelper, n, '');
		var padded = A3(
			$elm$core$String$padLeft,
			width,
			_Utils_chr('0'),
			hex);
		return $elm$core$String$toUpper(padded);
	});
var $author$project$Disassembler$formatByte = function (n) {
	return '$' + A2($author$project$Disassembler$toHex, 2, n);
};
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1.$) {
					case 'LT':
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 'EQ':
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Symbols$symbolTable = $elm$core$Dict$fromList(
	_List_fromArray(
		[
			_Utils_Tuple2(
			1,
			{description: 'Processor port data direction and data registers', name: 'CPU_PORT'}),
			_Utils_Tuple2(
			3,
			{description: 'Vector to convert FAC to integer', name: 'ADRAY1'}),
			_Utils_Tuple2(
			5,
			{description: 'Vector to convert integer to FAC', name: 'ADRAY2'}),
			_Utils_Tuple2(
			20,
			{description: 'Pointer to current BASIC text character', name: 'TXTPTR'}),
			_Utils_Tuple2(
			43,
			{description: 'Pointer to start of BASIC program', name: 'TXTTAB'}),
			_Utils_Tuple2(
			45,
			{description: 'Pointer to start of BASIC variables', name: 'VARTAB'}),
			_Utils_Tuple2(
			49,
			{description: 'Pointer to start of string storage', name: 'STRTAB'}),
			_Utils_Tuple2(
			51,
			{description: 'Pointer to top of string free space', name: 'FRETOP'}),
			_Utils_Tuple2(
			55,
			{description: 'Pointer to highest BASIC RAM address', name: 'MEMSIZ'}),
			_Utils_Tuple2(
			57,
			{description: 'Current BASIC line number', name: 'CURLIN'}),
			_Utils_Tuple2(
			61,
			{description: 'Pointer to current FOR/NEXT variable', name: 'FORPNT'}),
			_Utils_Tuple2(
			97,
			{description: 'Floating point accumulator 1', name: 'FAC1'}),
			_Utils_Tuple2(
			105,
			{description: 'Floating point accumulator 2', name: 'FAC2'}),
			_Utils_Tuple2(
			122,
			{description: 'Get next BASIC character subroutine', name: 'CHRGET'}),
			_Utils_Tuple2(
			139,
			{description: 'Get current BASIC character subroutine', name: 'CHRGOT'}),
			_Utils_Tuple2(
			144,
			{description: 'I/O operation status byte', name: 'STATUS'}),
			_Utils_Tuple2(
			145,
			{description: 'STOP key flag', name: 'STKEY'}),
			_Utils_Tuple2(
			147,
			{description: 'Load/verify flag (0=load, 1=verify)', name: 'VERCK'}),
			_Utils_Tuple2(
			148,
			{description: 'IEEE output character buffer flag', name: 'C3PO'}),
			_Utils_Tuple2(
			151,
			{description: 'Temp storage for X register', name: 'XSAV'}),
			_Utils_Tuple2(
			157,
			{description: 'Direct mode flag (bit 7) / error msg flag (bit 6)', name: 'MSGFLG'}),
			_Utils_Tuple2(
			160,
			{description: '60Hz jiffy clock (3 bytes, approx 24hr)', name: 'JIFFY_CLOCK'}),
			_Utils_Tuple2(
			163,
			{description: 'Bit count for serial I/O', name: 'BESSION'}),
			_Utils_Tuple2(
			164,
			{description: 'Physical line number', name: 'TLNIDX'}),
			_Utils_Tuple2(
			178,
			{description: 'End address (low byte) for load/save', name: 'EAL'}),
			_Utils_Tuple2(
			183,
			{description: 'Length of current filename', name: 'FNLEN'}),
			_Utils_Tuple2(
			186,
			{description: 'Current device number', name: 'FA'}),
			_Utils_Tuple2(
			187,
			{description: 'Pointer to current filename', name: 'FNADR'}),
			_Utils_Tuple2(
			197,
			{description: 'Matrix coordinate of last keypress', name: 'LSTX'}),
			_Utils_Tuple2(
			198,
			{description: 'Number of characters in keyboard buffer', name: 'NDX'}),
			_Utils_Tuple2(
			203,
			{description: 'Current key pressed (matrix value)', name: 'SFDX'}),
			_Utils_Tuple2(
			204,
			{description: 'Cursor blink enable (0=blink)', name: 'BLNSW'}),
			_Utils_Tuple2(
			206,
			{description: 'Character under cursor', name: 'GDBLN'}),
			_Utils_Tuple2(
			211,
			{description: 'Cursor column position', name: 'PNTR'}),
			_Utils_Tuple2(
			214,
			{description: 'Max columns on current line', name: 'LNMX'}),
			_Utils_Tuple2(
			1024,
			{description: 'Default screen memory (1000 bytes)', name: 'SCREEN_RAM'}),
			_Utils_Tuple2(
			40960,
			{description: 'BASIC cold start entry point', name: 'BASIC_COLD_START'}),
			_Utils_Tuple2(
			40972,
			{description: 'BASIC warm start entry point', name: 'BASIC_WARM_START'}),
			_Utils_Tuple2(
			42291,
			{description: 'Print string routine', name: 'BASIC_PRINT'}),
			_Utils_Tuple2(
			42336,
			{description: 'Print integer routine', name: 'BASIC_PRINT_INT'}),
			_Utils_Tuple2(
			43256,
			{description: 'Get byte value from BASIC expression', name: 'BASIC_GETBYT'}),
			_Utils_Tuple2(
			44446,
			{description: 'Evaluate numeric expression', name: 'BASIC_FRMNUM'}),
			_Utils_Tuple2(
			44675,
			{description: 'Get 16-bit address from FAC', name: 'BASIC_GETADR'}),
			_Utils_Tuple2(
			47095,
			{description: 'Move FAC to memory', name: 'BASIC_MOVMF'}),
			_Utils_Tuple2(
			48589,
			{description: 'Print string from (Y,A)', name: 'BASIC_PRINTSTR'}),
			_Utils_Tuple2(
			58624,
			{description: 'Initialize screen editor', name: 'CINT'}),
			_Utils_Tuple2(
			58648,
			{description: 'Initialize I/O and screen', name: 'IOINIT_SCREEN'}),
			_Utils_Tuple2(
			58692,
			{description: 'Clear screen', name: 'CLEAR_SCREEN'}),
			_Utils_Tuple2(
			58726,
			{description: 'Move cursor to home position', name: 'HOME'}),
			_Utils_Tuple2(
			58784,
			{description: 'Set cursor position', name: 'SET_CURSOR'}),
			_Utils_Tuple2(
			59626,
			{description: 'Scroll screen up', name: 'SCROLL_UP'}),
			_Utils_Tuple2(
			59953,
			{description: 'Default IRQ handler', name: 'IRQ_HANDLER'}),
			_Utils_Tuple2(
			60039,
			{description: 'Scan keyboard', name: 'SCNKEY'}),
			_Utils_Tuple2(
			62622,
			{description: 'Load file to RAM', name: 'LOAD_RAM'}),
			_Utils_Tuple2(
			62957,
			{description: 'Save memory to file', name: 'SAVE'}),
			_Utils_Tuple2(
			63131,
			{description: 'Set tape header', name: 'SETHDR'}),
			_Utils_Tuple2(
			64789,
			{description: 'Restore I/O vectors to default', name: 'RESTOR'}),
			_Utils_Tuple2(
			64848,
			{description: 'RAM test and set', name: 'RAMTAS'}),
			_Utils_Tuple2(
			64931,
			{description: 'Initialize I/O devices', name: 'IOINIT'}),
			_Utils_Tuple2(
			65017,
			{description: 'Set kernel message control', name: 'SETMSG'}),
			_Utils_Tuple2(
			65061,
			{description: 'Default NMI handler', name: 'NMI_HANDLER'}),
			_Utils_Tuple2(
			65347,
			{description: 'IRQ entry point (after push)', name: 'IRQ_ENTRY'}),
			_Utils_Tuple2(
			65352,
			{description: 'NMI entry point', name: 'NMI_ENTRY'}),
			_Utils_Tuple2(
			65409,
			{description: 'Initialize screen editor', name: 'CINT_JUMP'}),
			_Utils_Tuple2(
			65412,
			{description: 'Initialize I/O devices', name: 'IOINIT_JUMP'}),
			_Utils_Tuple2(
			65415,
			{description: 'RAM test and set pointers', name: 'RAMTAS_JUMP'}),
			_Utils_Tuple2(
			65418,
			{description: 'Restore default I/O vectors', name: 'RESTOR_JUMP'}),
			_Utils_Tuple2(
			65421,
			{description: 'Read/set I/O vector table', name: 'VECTOR'}),
			_Utils_Tuple2(
			65424,
			{description: 'Control OS messages', name: 'SETMSG_JUMP'}),
			_Utils_Tuple2(
			65427,
			{description: 'Send secondary address after LISTEN', name: 'SECOND'}),
			_Utils_Tuple2(
			65430,
			{description: 'Send secondary address after TALK', name: 'TKSA'}),
			_Utils_Tuple2(
			65433,
			{description: 'Read/set top of memory', name: 'MEMTOP'}),
			_Utils_Tuple2(
			65436,
			{description: 'Read/set bottom of memory', name: 'MEMBOT'}),
			_Utils_Tuple2(
			65439,
			{description: 'Scan keyboard', name: 'SCNKEY_JUMP'}),
			_Utils_Tuple2(
			65442,
			{description: 'Set IEEE timeout', name: 'SETTMO'}),
			_Utils_Tuple2(
			65445,
			{description: 'Input byte from serial bus', name: 'ACPTR'}),
			_Utils_Tuple2(
			65448,
			{description: 'Output byte to serial bus', name: 'CIOUT'}),
			_Utils_Tuple2(
			65451,
			{description: 'Command serial bus device to stop talking', name: 'UNTLK'}),
			_Utils_Tuple2(
			65454,
			{description: 'Command serial bus device to stop listening', name: 'UNLSN'}),
			_Utils_Tuple2(
			65457,
			{description: 'Command device to listen', name: 'LISTEN'}),
			_Utils_Tuple2(
			65460,
			{description: 'Command device to talk', name: 'TALK'}),
			_Utils_Tuple2(
			65463,
			{description: 'Read I/O status byte', name: 'READST'}),
			_Utils_Tuple2(
			65466,
			{description: 'Set file parameters (logical/device/secondary)', name: 'SETLFS'}),
			_Utils_Tuple2(
			65469,
			{description: 'Set filename', name: 'SETNAM'}),
			_Utils_Tuple2(
			65472,
			{description: 'Open logical file', name: 'OPEN'}),
			_Utils_Tuple2(
			65475,
			{description: 'Close logical file', name: 'CLOSE'}),
			_Utils_Tuple2(
			65478,
			{description: 'Set input channel', name: 'CHKIN'}),
			_Utils_Tuple2(
			65481,
			{description: 'Set output channel', name: 'CHKOUT'}),
			_Utils_Tuple2(
			65484,
			{description: 'Restore default I/O channels', name: 'CLRCHN'}),
			_Utils_Tuple2(
			65487,
			{description: 'Input character from channel', name: 'CHRIN'}),
			_Utils_Tuple2(
			65490,
			{description: 'Output character to channel', name: 'CHROUT'}),
			_Utils_Tuple2(
			65493,
			{description: 'Load RAM from device', name: 'LOAD'}),
			_Utils_Tuple2(
			65496,
			{description: 'Save RAM to device', name: 'SAVE'}),
			_Utils_Tuple2(
			65499,
			{description: 'Set jiffy clock', name: 'SETTIM'}),
			_Utils_Tuple2(
			65502,
			{description: 'Read jiffy clock', name: 'RDTIM'}),
			_Utils_Tuple2(
			65505,
			{description: 'Check STOP key', name: 'STOP'}),
			_Utils_Tuple2(
			65508,
			{description: 'Get character from keyboard buffer', name: 'GETIN'}),
			_Utils_Tuple2(
			65511,
			{description: 'Close all files', name: 'CLALL'}),
			_Utils_Tuple2(
			65514,
			{description: 'Update jiffy clock', name: 'UDTIM'}),
			_Utils_Tuple2(
			65517,
			{description: 'Get screen size (columns/rows)', name: 'SCREEN'}),
			_Utils_Tuple2(
			65520,
			{description: 'Read/set cursor position', name: 'PLOT'}),
			_Utils_Tuple2(
			65523,
			{description: 'Get I/O base address', name: 'IOBASE'}),
			_Utils_Tuple2(
			65530,
			{description: 'Non-maskable interrupt vector', name: 'NMI_VECTOR'}),
			_Utils_Tuple2(
			65532,
			{description: 'Reset vector', name: 'RESET_VECTOR'}),
			_Utils_Tuple2(
			65534,
			{description: 'Interrupt request vector', name: 'IRQ_VECTOR'}),
			_Utils_Tuple2(
			53248,
			{description: 'Sprite 0 X position (bits 0-7)', name: 'VIC_SPRITE0_X'}),
			_Utils_Tuple2(
			53249,
			{description: 'Sprite 0 Y position', name: 'VIC_SPRITE0_Y'}),
			_Utils_Tuple2(
			53250,
			{description: 'Sprite 1 X position (bits 0-7)', name: 'VIC_SPRITE1_X'}),
			_Utils_Tuple2(
			53251,
			{description: 'Sprite 1 Y position', name: 'VIC_SPRITE1_Y'}),
			_Utils_Tuple2(
			53252,
			{description: 'Sprite 2 X position (bits 0-7)', name: 'VIC_SPRITE2_X'}),
			_Utils_Tuple2(
			53253,
			{description: 'Sprite 2 Y position', name: 'VIC_SPRITE2_Y'}),
			_Utils_Tuple2(
			53254,
			{description: 'Sprite 3 X position (bits 0-7)', name: 'VIC_SPRITE3_X'}),
			_Utils_Tuple2(
			53255,
			{description: 'Sprite 3 Y position', name: 'VIC_SPRITE3_Y'}),
			_Utils_Tuple2(
			53256,
			{description: 'Sprite 4 X position (bits 0-7)', name: 'VIC_SPRITE4_X'}),
			_Utils_Tuple2(
			53257,
			{description: 'Sprite 4 Y position', name: 'VIC_SPRITE4_Y'}),
			_Utils_Tuple2(
			53258,
			{description: 'Sprite 5 X position (bits 0-7)', name: 'VIC_SPRITE5_X'}),
			_Utils_Tuple2(
			53259,
			{description: 'Sprite 5 Y position', name: 'VIC_SPRITE5_Y'}),
			_Utils_Tuple2(
			53260,
			{description: 'Sprite 6 X position (bits 0-7)', name: 'VIC_SPRITE6_X'}),
			_Utils_Tuple2(
			53261,
			{description: 'Sprite 6 Y position', name: 'VIC_SPRITE6_Y'}),
			_Utils_Tuple2(
			53262,
			{description: 'Sprite 7 X position (bits 0-7)', name: 'VIC_SPRITE7_X'}),
			_Utils_Tuple2(
			53263,
			{description: 'Sprite 7 Y position', name: 'VIC_SPRITE7_Y'}),
			_Utils_Tuple2(
			53264,
			{description: 'Sprites 0-7 X position bit 8', name: 'VIC_SPRITES_X_MSB'}),
			_Utils_Tuple2(
			53265,
			{description: 'Screen control: Y scroll, screen height, mode, raster bit 8', name: 'VIC_CONTROL1'}),
			_Utils_Tuple2(
			53266,
			{description: 'Raster line (bits 0-7, read) / IRQ trigger line (write)', name: 'VIC_RASTER'}),
			_Utils_Tuple2(
			53267,
			{description: 'Light pen X position', name: 'VIC_LIGHT_PEN_X'}),
			_Utils_Tuple2(
			53268,
			{description: 'Light pen Y position', name: 'VIC_LIGHT_PEN_Y'}),
			_Utils_Tuple2(
			53269,
			{description: 'Sprite enable bits (1=enabled)', name: 'VIC_SPRITE_ENABLE'}),
			_Utils_Tuple2(
			53270,
			{description: 'Screen control: X scroll, screen width, multicolor mode', name: 'VIC_CONTROL2'}),
			_Utils_Tuple2(
			53271,
			{description: 'Sprite Y expansion (1=double height)', name: 'VIC_SPRITE_EXPAND_Y'}),
			_Utils_Tuple2(
			53272,
			{description: 'Screen and character memory pointers', name: 'VIC_MEMORY_SETUP'}),
			_Utils_Tuple2(
			53273,
			{description: 'Interrupt status (raster, sprite collision, etc.)', name: 'VIC_IRQ_STATUS'}),
			_Utils_Tuple2(
			53274,
			{description: 'Interrupt enable mask', name: 'VIC_IRQ_ENABLE'}),
			_Utils_Tuple2(
			53275,
			{description: 'Sprite-to-background priority (0=sprite in front)', name: 'VIC_SPRITE_PRIORITY'}),
			_Utils_Tuple2(
			53276,
			{description: 'Sprite multicolor mode (1=multicolor)', name: 'VIC_SPRITE_MULTICOLOR'}),
			_Utils_Tuple2(
			53277,
			{description: 'Sprite X expansion (1=double width)', name: 'VIC_SPRITE_EXPAND_X'}),
			_Utils_Tuple2(
			53278,
			{description: 'Sprite-sprite collision (read to clear)', name: 'VIC_SPRITE_COLLISION'}),
			_Utils_Tuple2(
			53279,
			{description: 'Sprite-background collision (read to clear)', name: 'VIC_SPRITE_BG_COLLISION'}),
			_Utils_Tuple2(
			53280,
			{description: 'Border color (0-15)', name: 'VIC_BORDER_COLOR'}),
			_Utils_Tuple2(
			53281,
			{description: 'Background color 0 (0-15)', name: 'VIC_BG_COLOR0'}),
			_Utils_Tuple2(
			53282,
			{description: 'Background color 1 for multicolor (0-15)', name: 'VIC_BG_COLOR1'}),
			_Utils_Tuple2(
			53283,
			{description: 'Background color 2 for multicolor (0-15)', name: 'VIC_BG_COLOR2'}),
			_Utils_Tuple2(
			53284,
			{description: 'Background color 3 for ECM mode (0-15)', name: 'VIC_BG_COLOR3'}),
			_Utils_Tuple2(
			53285,
			{description: 'Sprite multicolor 0 (shared color 1)', name: 'VIC_SPRITE_MC0'}),
			_Utils_Tuple2(
			53286,
			{description: 'Sprite multicolor 1 (shared color 3)', name: 'VIC_SPRITE_MC1'}),
			_Utils_Tuple2(
			53287,
			{description: 'Sprite 0 color', name: 'VIC_SPRITE0_COLOR'}),
			_Utils_Tuple2(
			53288,
			{description: 'Sprite 1 color', name: 'VIC_SPRITE1_COLOR'}),
			_Utils_Tuple2(
			53289,
			{description: 'Sprite 2 color', name: 'VIC_SPRITE2_COLOR'}),
			_Utils_Tuple2(
			53290,
			{description: 'Sprite 3 color', name: 'VIC_SPRITE3_COLOR'}),
			_Utils_Tuple2(
			53291,
			{description: 'Sprite 4 color', name: 'VIC_SPRITE4_COLOR'}),
			_Utils_Tuple2(
			53292,
			{description: 'Sprite 5 color', name: 'VIC_SPRITE5_COLOR'}),
			_Utils_Tuple2(
			53293,
			{description: 'Sprite 6 color', name: 'VIC_SPRITE6_COLOR'}),
			_Utils_Tuple2(
			53294,
			{description: 'Sprite 7 color', name: 'VIC_SPRITE7_COLOR'}),
			_Utils_Tuple2(
			54272,
			{description: 'Voice 1 frequency low byte', name: 'SID_V1_FREQ_LO'}),
			_Utils_Tuple2(
			54273,
			{description: 'Voice 1 frequency high byte', name: 'SID_V1_FREQ_HI'}),
			_Utils_Tuple2(
			54274,
			{description: 'Voice 1 pulse width low byte', name: 'SID_V1_PW_LO'}),
			_Utils_Tuple2(
			54275,
			{description: 'Voice 1 pulse width high nybble (bits 0-3)', name: 'SID_V1_PW_HI'}),
			_Utils_Tuple2(
			54276,
			{description: 'Voice 1 control: gate, sync, ring, waveform', name: 'SID_V1_CONTROL'}),
			_Utils_Tuple2(
			54277,
			{description: 'Voice 1 attack (hi nybble) / decay (lo nybble)', name: 'SID_V1_ATTACK_DECAY'}),
			_Utils_Tuple2(
			54278,
			{description: 'Voice 1 sustain (hi nybble) / release (lo nybble)', name: 'SID_V1_SUSTAIN_RELEASE'}),
			_Utils_Tuple2(
			54279,
			{description: 'Voice 2 frequency low byte', name: 'SID_V2_FREQ_LO'}),
			_Utils_Tuple2(
			54280,
			{description: 'Voice 2 frequency high byte', name: 'SID_V2_FREQ_HI'}),
			_Utils_Tuple2(
			54281,
			{description: 'Voice 2 pulse width low byte', name: 'SID_V2_PW_LO'}),
			_Utils_Tuple2(
			54282,
			{description: 'Voice 2 pulse width high nybble (bits 0-3)', name: 'SID_V2_PW_HI'}),
			_Utils_Tuple2(
			54283,
			{description: 'Voice 2 control: gate, sync, ring, waveform', name: 'SID_V2_CONTROL'}),
			_Utils_Tuple2(
			54284,
			{description: 'Voice 2 attack (hi nybble) / decay (lo nybble)', name: 'SID_V2_ATTACK_DECAY'}),
			_Utils_Tuple2(
			54285,
			{description: 'Voice 2 sustain (hi nybble) / release (lo nybble)', name: 'SID_V2_SUSTAIN_RELEASE'}),
			_Utils_Tuple2(
			54286,
			{description: 'Voice 3 frequency low byte', name: 'SID_V3_FREQ_LO'}),
			_Utils_Tuple2(
			54287,
			{description: 'Voice 3 frequency high byte', name: 'SID_V3_FREQ_HI'}),
			_Utils_Tuple2(
			54288,
			{description: 'Voice 3 pulse width low byte', name: 'SID_V3_PW_LO'}),
			_Utils_Tuple2(
			54289,
			{description: 'Voice 3 pulse width high nybble (bits 0-3)', name: 'SID_V3_PW_HI'}),
			_Utils_Tuple2(
			54290,
			{description: 'Voice 3 control: gate, sync, ring, waveform', name: 'SID_V3_CONTROL'}),
			_Utils_Tuple2(
			54291,
			{description: 'Voice 3 attack (hi nybble) / decay (lo nybble)', name: 'SID_V3_ATTACK_DECAY'}),
			_Utils_Tuple2(
			54292,
			{description: 'Voice 3 sustain (hi nybble) / release (lo nybble)', name: 'SID_V3_SUSTAIN_RELEASE'}),
			_Utils_Tuple2(
			54293,
			{description: 'Filter cutoff frequency low byte (bits 0-2)', name: 'SID_FILTER_FREQ_LO'}),
			_Utils_Tuple2(
			54294,
			{description: 'Filter cutoff frequency high byte', name: 'SID_FILTER_FREQ_HI'}),
			_Utils_Tuple2(
			54295,
			{description: 'Filter resonance / voice routing', name: 'SID_FILTER_RESONANCE'}),
			_Utils_Tuple2(
			54296,
			{description: 'Master volume (lo nybble) / filter mode (hi nybble)', name: 'SID_VOLUME_FILTER'}),
			_Utils_Tuple2(
			54297,
			{description: 'Paddle X position (active joystick port)', name: 'SID_POT_X'}),
			_Utils_Tuple2(
			54298,
			{description: 'Paddle Y position (active joystick port)', name: 'SID_POT_Y'}),
			_Utils_Tuple2(
			54299,
			{description: 'Voice 3 oscillator output / random number', name: 'SID_OSC3_RANDOM'}),
			_Utils_Tuple2(
			54300,
			{description: 'Voice 3 envelope output', name: 'SID_ENV3'}),
			_Utils_Tuple2(
			56320,
			{description: 'Port A: keyboard column / joystick 2', name: 'CIA1_PORT_A'}),
			_Utils_Tuple2(
			56321,
			{description: 'Port B: keyboard row / joystick 1', name: 'CIA1_PORT_B'}),
			_Utils_Tuple2(
			56322,
			{description: 'Port A data direction (1=output)', name: 'CIA1_DDR_A'}),
			_Utils_Tuple2(
			56323,
			{description: 'Port B data direction (1=output)', name: 'CIA1_DDR_B'}),
			_Utils_Tuple2(
			56324,
			{description: 'Timer A low byte', name: 'CIA1_TIMER_A_LO'}),
			_Utils_Tuple2(
			56325,
			{description: 'Timer A high byte', name: 'CIA1_TIMER_A_HI'}),
			_Utils_Tuple2(
			56326,
			{description: 'Timer B low byte', name: 'CIA1_TIMER_B_LO'}),
			_Utils_Tuple2(
			56327,
			{description: 'Timer B high byte', name: 'CIA1_TIMER_B_HI'}),
			_Utils_Tuple2(
			56328,
			{description: 'Time of day: tenths of seconds', name: 'CIA1_TOD_TENTHS'}),
			_Utils_Tuple2(
			56329,
			{description: 'Time of day: seconds (BCD)', name: 'CIA1_TOD_SEC'}),
			_Utils_Tuple2(
			56330,
			{description: 'Time of day: minutes (BCD)', name: 'CIA1_TOD_MIN'}),
			_Utils_Tuple2(
			56331,
			{description: 'Time of day: hours (BCD, bit 7=PM)', name: 'CIA1_TOD_HR'}),
			_Utils_Tuple2(
			56332,
			{description: 'Serial shift register', name: 'CIA1_SERIAL'}),
			_Utils_Tuple2(
			56333,
			{description: 'Interrupt control/status (timer, TOD, serial)', name: 'CIA1_IRQ_CONTROL'}),
			_Utils_Tuple2(
			56334,
			{description: 'Timer A control (start, mode, etc.)', name: 'CIA1_CONTROL_A'}),
			_Utils_Tuple2(
			56335,
			{description: 'Timer B control (start, mode, etc.)', name: 'CIA1_CONTROL_B'}),
			_Utils_Tuple2(
			56576,
			{description: 'Port A: VIC bank, serial bus, RS-232', name: 'CIA2_PORT_A'}),
			_Utils_Tuple2(
			56577,
			{description: 'Port B: user port', name: 'CIA2_PORT_B'}),
			_Utils_Tuple2(
			56578,
			{description: 'Port A data direction (1=output)', name: 'CIA2_DDR_A'}),
			_Utils_Tuple2(
			56579,
			{description: 'Port B data direction (1=output)', name: 'CIA2_DDR_B'}),
			_Utils_Tuple2(
			56580,
			{description: 'Timer A low byte', name: 'CIA2_TIMER_A_LO'}),
			_Utils_Tuple2(
			56581,
			{description: 'Timer A high byte', name: 'CIA2_TIMER_A_HI'}),
			_Utils_Tuple2(
			56582,
			{description: 'Timer B low byte', name: 'CIA2_TIMER_B_LO'}),
			_Utils_Tuple2(
			56583,
			{description: 'Timer B high byte', name: 'CIA2_TIMER_B_HI'}),
			_Utils_Tuple2(
			56584,
			{description: 'Time of day: tenths of seconds', name: 'CIA2_TOD_TENTHS'}),
			_Utils_Tuple2(
			56585,
			{description: 'Time of day: seconds (BCD)', name: 'CIA2_TOD_SEC'}),
			_Utils_Tuple2(
			56586,
			{description: 'Time of day: minutes (BCD)', name: 'CIA2_TOD_MIN'}),
			_Utils_Tuple2(
			56587,
			{description: 'Time of day: hours (BCD, bit 7=PM)', name: 'CIA2_TOD_HR'}),
			_Utils_Tuple2(
			56588,
			{description: 'Serial shift register', name: 'CIA2_SERIAL'}),
			_Utils_Tuple2(
			56589,
			{description: 'NMI control/status (timer, TOD, serial)', name: 'CIA2_NMI_CONTROL'}),
			_Utils_Tuple2(
			56590,
			{description: 'Timer A control (start, mode, etc.)', name: 'CIA2_CONTROL_A'}),
			_Utils_Tuple2(
			56591,
			{description: 'Timer B control (start, mode, etc.)', name: 'CIA2_CONTROL_B'}),
			_Utils_Tuple2(
			55296,
			{description: 'Color memory (1000 nybbles, bits 0-3)', name: 'COLOR_RAM'})
		]));
var $author$project$Symbols$getSymbol = function (addr) {
	return A2(
		$elm$core$Maybe$map,
		function ($) {
			return $.name;
		},
		A2($elm$core$Dict$get, addr, $author$project$Symbols$symbolTable));
};
var $author$project$Disassembler$formatByteWithSymbol = function (addr) {
	var _v0 = $author$project$Symbols$getSymbol(addr);
	if (_v0.$ === 'Just') {
		var sym = _v0.a;
		return sym;
	} else {
		return $author$project$Disassembler$formatByte(addr);
	}
};
var $author$project$Disassembler$formatWord = function (n) {
	return '$' + A2($author$project$Disassembler$toHex, 4, n);
};
var $author$project$Disassembler$formatWordWithSymbol = function (addr) {
	var _v0 = $author$project$Symbols$getSymbol(addr);
	if (_v0.$ === 'Just') {
		var sym = _v0.a;
		return sym;
	} else {
		return $author$project$Disassembler$formatWord(addr);
	}
};
var $author$project$Disassembler$formatOperand = F3(
	function (mode, operand, instrAddress) {
		switch (mode.$) {
			case 'Implied':
				return '';
			case 'Accumulator':
				return 'A';
			case 'Immediate':
				return '#' + $author$project$Disassembler$formatByte(operand);
			case 'ZeroPage':
				return $author$project$Disassembler$formatByteWithSymbol(operand);
			case 'ZeroPageX':
				return $author$project$Disassembler$formatByteWithSymbol(operand) + ',X';
			case 'ZeroPageY':
				return $author$project$Disassembler$formatByteWithSymbol(operand) + ',Y';
			case 'Absolute':
				return $author$project$Disassembler$formatWordWithSymbol(operand);
			case 'AbsoluteX':
				return $author$project$Disassembler$formatWordWithSymbol(operand) + ',X';
			case 'AbsoluteY':
				return $author$project$Disassembler$formatWordWithSymbol(operand) + ',Y';
			case 'Indirect':
				return '(' + ($author$project$Disassembler$formatWordWithSymbol(operand) + ')');
			case 'IndirectX':
				return '(' + ($author$project$Disassembler$formatByteWithSymbol(operand) + ',X)');
			case 'IndirectY':
				return '(' + ($author$project$Disassembler$formatByteWithSymbol(operand) + '),Y');
			default:
				var signedOffset = (operand > 127) ? (operand - 256) : operand;
				var target = (instrAddress + 2) + signedOffset;
				return $author$project$Disassembler$formatWordWithSymbol(target);
		}
	});
var $author$project$Disassembler$formatInstruction = F3(
	function (info, operand, address) {
		var operandStr = A3($author$project$Disassembler$formatOperand, info.mode, operand, address);
		var mnemonic = info.undocumented ? ('*' + info.mnemonic) : info.mnemonic;
		return $elm$core$String$isEmpty(operandStr) ? mnemonic : (mnemonic + (' ' + operandStr));
	});
var $author$project$Disassembler$getInstructionBytes = F3(
	function (offset, numBytes, bytes) {
		return A2(
			$elm$core$List$filterMap,
			function (i) {
				return A2($elm$core$Array$get, i, bytes);
			},
			A2($elm$core$List$range, offset, (offset + numBytes) - 1));
	});
var $author$project$Types$Absolute = {$: 'Absolute'};
var $author$project$Types$AbsoluteX = {$: 'AbsoluteX'};
var $author$project$Types$AbsoluteY = {$: 'AbsoluteY'};
var $author$project$Types$Accumulator = {$: 'Accumulator'};
var $author$project$Types$Immediate = {$: 'Immediate'};
var $author$project$Types$Implied = {$: 'Implied'};
var $author$project$Types$Indirect = {$: 'Indirect'};
var $author$project$Types$IndirectX = {$: 'IndirectX'};
var $author$project$Types$IndirectY = {$: 'IndirectY'};
var $author$project$Types$OpcodeInfo = F5(
	function (mnemonic, mode, bytes, cycles, undocumented) {
		return {bytes: bytes, cycles: cycles, mnemonic: mnemonic, mode: mode, undocumented: undocumented};
	});
var $author$project$Types$Relative = {$: 'Relative'};
var $author$project$Types$ZeroPage = {$: 'ZeroPage'};
var $author$project$Types$ZeroPageX = {$: 'ZeroPageX'};
var $author$project$Types$ZeroPageY = {$: 'ZeroPageY'};
var $elm$core$Array$fromListHelp = F3(
	function (list, nodeList, nodeListSize) {
		fromListHelp:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, list);
			var jsArray = _v0.a;
			var remainingItems = _v0.b;
			if (_Utils_cmp(
				$elm$core$Elm$JsArray$length(jsArray),
				$elm$core$Array$branchFactor) < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					true,
					{nodeList: nodeList, nodeListSize: nodeListSize, tail: jsArray});
			} else {
				var $temp$list = remainingItems,
					$temp$nodeList = A2(
					$elm$core$List$cons,
					$elm$core$Array$Leaf(jsArray),
					nodeList),
					$temp$nodeListSize = nodeListSize + 1;
				list = $temp$list;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue fromListHelp;
			}
		}
	});
var $elm$core$Array$fromList = function (list) {
	if (!list.b) {
		return $elm$core$Array$empty;
	} else {
		return A3($elm$core$Array$fromListHelp, list, _List_Nil, 0);
	}
};
var $author$project$Opcodes$opcodeTable = $elm$core$Array$fromList(
	_List_fromArray(
		[
			A5($author$project$Types$OpcodeInfo, 'BRK', $author$project$Types$Implied, 1, 7, false),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPage, 2, 3, true),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'ASL', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'PHP', $author$project$Types$Implied, 1, 3, false),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ASL', $author$project$Types$Accumulator, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ANC', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Absolute, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ASL', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BPL', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ASL', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'CLC', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'ORA', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ASL', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'SLO', $author$project$Types$AbsoluteX, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'JSR', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'BIT', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'ROL', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'PLP', $author$project$Types$Implied, 1, 4, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ROL', $author$project$Types$Accumulator, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ANC', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'BIT', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROL', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BMI', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROL', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'SEC', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'AND', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROL', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'RLA', $author$project$Types$AbsoluteX, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'RTI', $author$project$Types$Implied, 1, 6, false),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPage, 2, 3, true),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'LSR', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'PHA', $author$project$Types$Implied, 1, 3, false),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LSR', $author$project$Types$Accumulator, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ALR', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'JMP', $author$project$Types$Absolute, 3, 3, false),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LSR', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BVC', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LSR', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'CLI', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'EOR', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LSR', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'SRE', $author$project$Types$AbsoluteX, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'RTS', $author$project$Types$Implied, 1, 6, false),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPage, 2, 3, true),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'ROR', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'PLA', $author$project$Types$Implied, 1, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ROR', $author$project$Types$Accumulator, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ARR', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'JMP', $author$project$Types$Indirect, 3, 5, false),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROR', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BVS', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROR', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'SEI', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'ADC', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'ROR', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'RRA', $author$project$Types$AbsoluteX, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SAX', $author$project$Types$IndirectX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'STY', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'STX', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'SAX', $author$project$Types$ZeroPage, 2, 3, true),
			A5($author$project$Types$OpcodeInfo, 'DEY', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'TXA', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'ANE', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'STY', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'STX', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'SAX', $author$project$Types$Absolute, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'BCC', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$IndirectY, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'SHA', $author$project$Types$IndirectY, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'STY', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'STX', $author$project$Types$ZeroPageY, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'SAX', $author$project$Types$ZeroPageY, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'TYA', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$AbsoluteY, 3, 5, false),
			A5($author$project$Types$OpcodeInfo, 'TXS', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'TAS', $author$project$Types$AbsoluteY, 3, 5, true),
			A5($author$project$Types$OpcodeInfo, 'SHY', $author$project$Types$AbsoluteX, 3, 5, true),
			A5($author$project$Types$OpcodeInfo, 'STA', $author$project$Types$AbsoluteX, 3, 5, false),
			A5($author$project$Types$OpcodeInfo, 'SHX', $author$project$Types$AbsoluteY, 3, 5, true),
			A5($author$project$Types$OpcodeInfo, 'SHA', $author$project$Types$AbsoluteY, 3, 5, true),
			A5($author$project$Types$OpcodeInfo, 'LDY', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'LDX', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$IndirectX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'LDY', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'LDX', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$ZeroPage, 2, 3, true),
			A5($author$project$Types$OpcodeInfo, 'TAY', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'TAX', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LXA', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'LDY', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDX', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$Absolute, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'BCS', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$IndirectY, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'LDY', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDX', $author$project$Types$ZeroPageY, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$ZeroPageY, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'CLV', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'TSX', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'LAS', $author$project$Types$AbsoluteY, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'LDY', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDA', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LDX', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'LAX', $author$project$Types$AbsoluteY, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'CPY', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'CPY', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'DEC', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'INY', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'DEX', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBX', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'CPY', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'DEC', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BNE', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'DEC', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'CLD', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'CMP', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'DEC', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'DCP', $author$project$Types$AbsoluteX, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'CPX', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$IndirectX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$IndirectX, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'CPX', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$ZeroPage, 2, 3, false),
			A5($author$project$Types$OpcodeInfo, 'INC', $author$project$Types$ZeroPage, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$ZeroPage, 2, 5, true),
			A5($author$project$Types$OpcodeInfo, 'INX', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$Immediate, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$Immediate, 2, 2, true),
			A5($author$project$Types$OpcodeInfo, 'CPX', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$Absolute, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'INC', $author$project$Types$Absolute, 3, 6, false),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$Absolute, 3, 6, true),
			A5($author$project$Types$OpcodeInfo, 'BEQ', $author$project$Types$Relative, 2, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$IndirectY, 2, 5, false),
			A5($author$project$Types$OpcodeInfo, 'JAM', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$IndirectY, 2, 8, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$ZeroPageX, 2, 4, true),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$ZeroPageX, 2, 4, false),
			A5($author$project$Types$OpcodeInfo, 'INC', $author$project$Types$ZeroPageX, 2, 6, false),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$ZeroPageX, 2, 6, true),
			A5($author$project$Types$OpcodeInfo, 'SED', $author$project$Types$Implied, 1, 2, false),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$AbsoluteY, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$Implied, 1, 2, true),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$AbsoluteY, 3, 7, true),
			A5($author$project$Types$OpcodeInfo, 'NOP', $author$project$Types$AbsoluteX, 3, 4, true),
			A5($author$project$Types$OpcodeInfo, 'SBC', $author$project$Types$AbsoluteX, 3, 4, false),
			A5($author$project$Types$OpcodeInfo, 'INC', $author$project$Types$AbsoluteX, 3, 7, false),
			A5($author$project$Types$OpcodeInfo, 'ISC', $author$project$Types$AbsoluteX, 3, 7, true)
		]));
var $author$project$Opcodes$unknownOpcode = A5($author$project$Types$OpcodeInfo, '???', $author$project$Types$Implied, 1, 2, true);
var $author$project$Opcodes$getOpcode = function (_byte) {
	return A2(
		$elm$core$Maybe$withDefault,
		$author$project$Opcodes$unknownOpcode,
		A2($elm$core$Array$get, _byte, $author$project$Opcodes$opcodeTable));
};
var $author$project$Disassembler$getOperandValue = function (instrBytes) {
	_v0$2:
	while (true) {
		if (instrBytes.b && instrBytes.b.b) {
			if (!instrBytes.b.b.b) {
				var _v1 = instrBytes.b;
				var lo = _v1.a;
				return lo;
			} else {
				if (!instrBytes.b.b.b.b) {
					var _v2 = instrBytes.b;
					var lo = _v2.a;
					var _v3 = _v2.b;
					var hi = _v3.a;
					return (hi * 256) + lo;
				} else {
					break _v0$2;
				}
			}
		} else {
			break _v0$2;
		}
	}
	return 0;
};
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Disassembler$isInByteRegion = F2(
	function (offset, regions) {
		return A2(
			$elm$core$List$any,
			function (r) {
				return _Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
			},
			regions);
	});
var $author$project$Disassembler$isInSegment = F2(
	function (offset, segments) {
		return A2(
			$elm$core$List$any,
			function (s) {
				return (_Utils_cmp(offset, s.start) > -1) && (_Utils_cmp(offset, s.end) < 1);
			},
			segments);
	});
var $author$project$Disassembler$isInTextRegion = F2(
	function (offset, regions) {
		return A2(
			$elm$core$List$any,
			function (r) {
				return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
			},
			regions);
	});
var $author$project$Disassembler$disassembleLine = F8(
	function (loadAddress, offset, bytes, comments, labels, regions, segments, majorComments) {
		var majorComment = A2($elm$core$Dict$get, offset, majorComments);
		var inSeg = A2($author$project$Disassembler$isInSegment, offset, segments);
		var address = loadAddress + offset;
		var labelAtAddr = A2($elm$core$Dict$get, address, labels);
		var _v0 = A2($elm$core$Array$get, offset, bytes);
		if (_v0.$ === 'Nothing') {
			return {
				address: address,
				bytes: _List_Nil,
				comment: A2($elm$core$Dict$get, offset, comments),
				disassembly: '; end of file',
				inSegment: inSeg,
				isData: false,
				isText: false,
				label: labelAtAddr,
				majorComment: majorComment,
				offset: offset,
				targetAddress: $elm$core$Maybe$Nothing
			};
		} else {
			var _byte = _v0.a;
			if (A2($author$project$Disassembler$isInTextRegion, offset, regions)) {
				var textRegion = $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						function (r) {
							return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
						},
						regions));
				var regionEnd = A2(
					$elm$core$Maybe$withDefault,
					offset,
					A2(
						$elm$core$Maybe$map,
						function ($) {
							return $.end;
						},
						textRegion));
				var textBytes = A4($author$project$Disassembler$collectTextBytes, offset, regionEnd, bytes, _List_Nil);
				var textStr = $author$project$Disassembler$bytesToPetscii(textBytes);
				return {
					address: address,
					bytes: textBytes,
					comment: A2($elm$core$Dict$get, offset, comments),
					disassembly: '.text \"' + (textStr + '\"'),
					inSegment: inSeg,
					isData: false,
					isText: true,
					label: labelAtAddr,
					majorComment: majorComment,
					offset: offset,
					targetAddress: $elm$core$Maybe$Nothing
				};
			} else {
				if (A2($author$project$Disassembler$isInByteRegion, offset, regions)) {
					return {
						address: address,
						bytes: _List_fromArray(
							[_byte]),
						comment: A2($elm$core$Dict$get, offset, comments),
						disassembly: '.byte ' + $author$project$Disassembler$formatByte(_byte),
						inSegment: inSeg,
						isData: true,
						isText: false,
						label: labelAtAddr,
						majorComment: majorComment,
						offset: offset,
						targetAddress: $elm$core$Maybe$Nothing
					};
				} else {
					var info = $author$project$Opcodes$getOpcode(_byte);
					var instrBytes = A3($author$project$Disassembler$getInstructionBytes, offset, info.bytes, bytes);
					var operandValue = $author$project$Disassembler$getOperandValue(instrBytes);
					var endAddress = loadAddress + $elm$core$Array$length(bytes);
					var targetAddr = A5($author$project$Disassembler$computeTargetAddress, info.mode, operandValue, address, loadAddress, endAddress);
					var disasm = A3($author$project$Disassembler$formatInstruction, info, operandValue, address);
					return {
						address: address,
						bytes: instrBytes,
						comment: A2($elm$core$Dict$get, offset, comments),
						disassembly: disasm,
						inSegment: inSeg,
						isData: false,
						isText: false,
						label: labelAtAddr,
						majorComment: majorComment,
						offset: offset,
						targetAddress: targetAddr
					};
				}
			}
		}
	});
var $author$project$Disassembler$disassemble = F8(
	function (loadAddress, offset, bytes, comments, labels, regions, segments, majorComments) {
		return A8($author$project$Disassembler$disassembleLine, loadAddress, offset, bytes, comments, labels, regions, segments, majorComments);
	});
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$String$dropRight = F2(
	function (n, string) {
		return (n < 1) ? string : A3($elm$core$String$slice, 0, -n, string);
	});
var $elm$json$Json$Encode$int = _Json_wrap;
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(_Utils_Tuple0),
			pairs));
};
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Project$encodeComment = function (_v0) {
	var offset = _v0.a;
	var text = _v0.b;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'offset',
				$elm$json$Json$Encode$int(offset)),
				_Utils_Tuple2(
				'text',
				$elm$json$Json$Encode$string(text))
			]));
};
var $author$project$Project$encodeLabel = function (_v0) {
	var addr = _v0.a;
	var name = _v0.b;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'address',
				$elm$json$Json$Encode$int(addr)),
				_Utils_Tuple2(
				'name',
				$elm$json$Json$Encode$string(name))
			]));
};
var $author$project$Project$encodeMajorComment = function (_v0) {
	var offset = _v0.a;
	var text = _v0.b;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'offset',
				$elm$json$Json$Encode$int(offset)),
				_Utils_Tuple2(
				'text',
				$elm$json$Json$Encode$string(text))
			]));
};
var $author$project$Project$encodeRegion = function (region) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'start',
				$elm$json$Json$Encode$int(region.start)),
				_Utils_Tuple2(
				'end',
				$elm$json$Json$Encode$int(region.end)),
				_Utils_Tuple2(
				'regionType',
				$elm$json$Json$Encode$string(region.regionType))
			]));
};
var $author$project$Project$encodeSegment = function (segment) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'start',
				$elm$json$Json$Encode$int(segment.start)),
				_Utils_Tuple2(
				'end',
				$elm$json$Json$Encode$int(segment.end))
			]));
};
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(_Utils_Tuple0),
				entries));
	});
var $author$project$Project$encode = function (data) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'version',
				$elm$json$Json$Encode$int(data.version)),
				_Utils_Tuple2(
				'fileName',
				$elm$json$Json$Encode$string(data.fileName)),
				_Utils_Tuple2(
				'loadAddress',
				$elm$json$Json$Encode$int(data.loadAddress)),
				_Utils_Tuple2(
				'comments',
				A2($elm$json$Json$Encode$list, $author$project$Project$encodeComment, data.comments)),
				_Utils_Tuple2(
				'labels',
				A2($elm$json$Json$Encode$list, $author$project$Project$encodeLabel, data.labels)),
				_Utils_Tuple2(
				'regions',
				A2($elm$json$Json$Encode$list, $author$project$Project$encodeRegion, data.regions)),
				_Utils_Tuple2(
				'segments',
				A2($elm$json$Json$Encode$list, $author$project$Project$encodeSegment, data.segments)),
				_Utils_Tuple2(
				'majorComments',
				A2($elm$json$Json$Encode$list, $author$project$Project$encodeMajorComment, data.majorComments))
			]));
};
var $author$project$Opcodes$opcodeBytes = function (_byte) {
	return $author$project$Opcodes$getOpcode(_byte).bytes;
};
var $author$project$Main$findInstructionBoundariesHelper = F6(
	function (bytes, regions, offset, prevStart, prevPrevStart, targetOffset) {
		findInstructionBoundariesHelper:
		while (true) {
			if (_Utils_cmp(
				offset,
				$elm$core$Array$length(bytes)) > -1) {
				return _Utils_Tuple2(prevStart, prevPrevStart);
			} else {
				var textRegion = $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						function (r) {
							return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
						},
						regions));
				var inByteRegion = A2(
					$elm$core$List$any,
					function (r) {
						return _Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
					},
					regions);
				var instrLen = function () {
					if (textRegion.$ === 'Just') {
						var tr = textRegion.a;
						return (tr.end - offset) + 1;
					} else {
						return inByteRegion ? 1 : A2(
							$elm$core$Maybe$withDefault,
							1,
							A2(
								$elm$core$Maybe$map,
								$author$project$Opcodes$opcodeBytes,
								A2($elm$core$Array$get, offset, bytes)));
					}
				}();
				var nextOffset = offset + instrLen;
				if (_Utils_cmp(nextOffset, targetOffset) > 0) {
					return _Utils_Tuple2(offset, prevStart);
				} else {
					var $temp$bytes = bytes,
						$temp$regions = regions,
						$temp$offset = nextOffset,
						$temp$prevStart = offset,
						$temp$prevPrevStart = prevStart,
						$temp$targetOffset = targetOffset;
					bytes = $temp$bytes;
					regions = $temp$regions;
					offset = $temp$offset;
					prevStart = $temp$prevStart;
					prevPrevStart = $temp$prevPrevStart;
					targetOffset = $temp$targetOffset;
					continue findInstructionBoundariesHelper;
				}
			}
		}
	});
var $author$project$Main$findInstructionBoundaries = F3(
	function (bytes, regions, targetOffset) {
		return A6($author$project$Main$findInstructionBoundariesHelper, bytes, regions, 0, 0, 0, targetOffset);
	});
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Main$ensureSelectionVisible = function (model) {
	var _v0 = model.selectedOffset;
	if (_v0.$ === 'Just') {
		var offset = _v0.a;
		var snapToInstructionStart = function (rawOffset) {
			var _v1 = A3($author$project$Main$findInstructionBoundaries, model.bytes, model.regions, rawOffset);
			var instrStart = _v1.a;
			return instrStart;
		};
		var maxViewStart = A2(
			$elm$core$Basics$max,
			0,
			$elm$core$Array$length(model.bytes) - model.viewLines);
		var margin = 2;
		var tooHigh = _Utils_cmp(offset, model.viewStart + margin) < 0;
		var tooLow = _Utils_cmp(offset, (model.viewStart + model.viewLines) - margin) > -1;
		if (tooHigh) {
			var rawStart = A2($elm$core$Basics$max, 0, offset - margin);
			return _Utils_update(
				model,
				{
					viewStart: snapToInstructionStart(rawStart)
				});
		} else {
			if (tooLow) {
				var rawStart = A2($elm$core$Basics$min, maxViewStart, ((offset - model.viewLines) + margin) + 1);
				return _Utils_update(
					model,
					{
						viewStart: snapToInstructionStart(rawStart)
					});
			} else {
				return model;
			}
		}
	} else {
		return model;
	}
};
var $author$project$Main$exportAsmFile = _Platform_outgoingPort('exportAsmFile', $elm$json$Json$Encode$string);
var $elm$core$String$filter = _String_filter;
var $elm$browser$Browser$Dom$focus = _Browser_call('focus');
var $author$project$Project$regionTypeToString = function (rt) {
	if (rt.$ === 'ByteRegion') {
		return 'byte';
	} else {
		return 'text';
	}
};
var $author$project$Project$fromModel = function (model) {
	return {
		comments: $elm$core$Dict$toList(model.comments),
		fileName: model.fileName,
		labels: $elm$core$Dict$toList(model.labels),
		loadAddress: model.loadAddress,
		majorComments: $elm$core$Dict$toList(model.majorComments),
		regions: A2(
			$elm$core$List$map,
			function (r) {
				return {
					end: r.end,
					regionType: $author$project$Project$regionTypeToString(r.regionType),
					start: r.start
				};
			},
			model.regions),
		segments: A2(
			$elm$core$List$map,
			function (s) {
				return {end: s.end, start: s.start};
			},
			model.segments),
		version: $author$project$Project$currentVersion
	};
};
var $author$project$Main$toHexHelper = F2(
	function (n, acc) {
		toHexHelper:
		while (true) {
			if ((!n) && (!$elm$core$String$isEmpty(acc))) {
				return acc;
			} else {
				if (!n) {
					return '0';
				} else {
					var digit = A2($elm$core$Basics$modBy, 16, n);
					var _char = function () {
						switch (digit) {
							case 10:
								return 'A';
							case 11:
								return 'B';
							case 12:
								return 'C';
							case 13:
								return 'D';
							case 14:
								return 'E';
							case 15:
								return 'F';
							default:
								return $elm$core$String$fromInt(digit);
						}
					}();
					var $temp$n = (n / 16) | 0,
						$temp$acc = _Utils_ap(_char, acc);
					n = $temp$n;
					acc = $temp$acc;
					continue toHexHelper;
				}
			}
		}
	});
var $author$project$Main$toHex = F2(
	function (width, n) {
		var hex = A2($author$project$Main$toHexHelper, n, '');
		var padded = A3(
			$elm$core$String$padLeft,
			width,
			_Utils_chr('0'),
			hex);
		return $elm$core$String$toUpper(padded);
	});
var $author$project$Main$generateOperand = F3(
	function (model, offset, info) {
		var labelOrHex = F2(
			function (addr, width) {
				var _v1 = A2($elm$core$Dict$get, addr, model.labels);
				if (_v1.$ === 'Just') {
					var labelName = _v1.a;
					return labelName;
				} else {
					return '$' + A2($author$project$Main$toHex, width, addr);
				}
			});
		var getByte = function (off) {
			return A2(
				$elm$core$Maybe$withDefault,
				0,
				A2($elm$core$Array$get, off, model.bytes));
		};
		var hi = getByte(offset + 2);
		var lo = getByte(offset + 1);
		var wordValue = (hi * 256) + lo;
		var address = model.loadAddress + offset;
		var relativeTarget = function () {
			var signedOffset = (lo > 127) ? (lo - 256) : lo;
			return (address + 2) + signedOffset;
		}();
		var _v0 = info.mode;
		switch (_v0.$) {
			case 'Implied':
				return '';
			case 'Accumulator':
				return '';
			case 'Immediate':
				return '#$' + A2($author$project$Main$toHex, 2, lo);
			case 'ZeroPage':
				return A2(labelOrHex, lo, 2);
			case 'ZeroPageX':
				return A2(labelOrHex, lo, 2) + ',X';
			case 'ZeroPageY':
				return A2(labelOrHex, lo, 2) + ',Y';
			case 'Absolute':
				return A2(labelOrHex, wordValue, 4);
			case 'AbsoluteX':
				return A2(labelOrHex, wordValue, 4) + ',X';
			case 'AbsoluteY':
				return A2(labelOrHex, wordValue, 4) + ',Y';
			case 'Indirect':
				return '(' + (A2(labelOrHex, wordValue, 4) + ')');
			case 'IndirectX':
				return '(' + (A2(labelOrHex, lo, 2) + ',X)');
			case 'IndirectY':
				return '(' + (A2(labelOrHex, lo, 2) + '),Y');
			default:
				return A2(labelOrHex, relativeTarget, 4);
		}
	});
var $author$project$Main$generateCodeLine = F2(
	function (model, offset) {
		var _v0 = A2($elm$core$Array$get, offset, model.bytes);
		if (_v0.$ === 'Nothing') {
			return _Utils_Tuple2('; end of file', 1);
		} else {
			var opcodeByte = _v0.a;
			var info = $author$project$Opcodes$getOpcode(opcodeByte);
			var mnemonic = info.undocumented ? ('*' + info.mnemonic) : info.mnemonic;
			var operandStr = A3($author$project$Main$generateOperand, model, offset, info);
			return $elm$core$String$isEmpty(operandStr) ? _Utils_Tuple2(mnemonic, info.bytes) : _Utils_Tuple2(mnemonic + (' ' + operandStr), info.bytes);
		}
	});
var $author$project$Main$generateDataLine = F2(
	function (model, offset) {
		var _v0 = A2($elm$core$Array$get, offset, model.bytes);
		if (_v0.$ === 'Just') {
			var _byte = _v0.a;
			return _Utils_Tuple2(
				'.byte $' + A2($author$project$Main$toHex, 2, _byte),
				1);
		} else {
			return _Utils_Tuple2('; end of file', 1);
		}
	});
var $author$project$Main$generateTextLine = F3(
	function (model, offset, regionEnd) {
		var collectBytes = F3(
			function (off, endOff, accBytes) {
				collectBytes:
				while (true) {
					if (_Utils_cmp(off, endOff) > 0) {
						return $elm$core$List$reverse(accBytes);
					} else {
						var _v0 = A2($elm$core$Array$get, off, model.bytes);
						if (_v0.$ === 'Just') {
							var b = _v0.a;
							var $temp$off = off + 1,
								$temp$endOff = endOff,
								$temp$accBytes = A2($elm$core$List$cons, b, accBytes);
							off = $temp$off;
							endOff = $temp$endOff;
							accBytes = $temp$accBytes;
							continue collectBytes;
						} else {
							return $elm$core$List$reverse(accBytes);
						}
					}
				}
			});
		var textBytes = A3(collectBytes, offset, regionEnd, _List_Nil);
		var textStr = $elm$core$String$fromList(
			A2($elm$core$List$map, $author$project$Disassembler$toPetscii, textBytes));
		var bytesConsumed = (regionEnd - offset) + 1;
		return _Utils_Tuple2('.text \"' + (textStr + '\"'), bytesConsumed);
	});
var $elm$core$String$words = _String_words;
var $author$project$Main$getSegmentName = F2(
	function (model, segment) {
		var _v0 = A2($elm$core$Dict$get, segment.start, model.majorComments);
		if (_v0.$ === 'Just') {
			var comment = _v0.a;
			return A2(
				$elm$core$Maybe$withDefault,
				'SEG_' + A2($author$project$Main$toHex, 4, model.loadAddress + segment.start),
				$elm$core$List$head(
					$elm$core$String$words(comment)));
		} else {
			return 'SEG_' + A2($author$project$Main$toHex, 4, model.loadAddress + segment.start);
		}
	});
var $elm$core$String$lines = _String_lines;
var $author$project$Main$generateAsmLines = F3(
	function (model, offset, acc) {
		generateAsmLines:
		while (true) {
			if (_Utils_cmp(
				offset,
				$elm$core$Array$length(model.bytes)) > -1) {
				return $elm$core$List$reverse(acc);
			} else {
				var textRegion = $elm$core$List$head(
					A2(
						$elm$core$List$filter,
						function (r) {
							return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
						},
						model.regions));
				var segmentStartLine = function () {
					var _v5 = A2(
						$elm$core$List$filter,
						function (s) {
							return _Utils_eq(s.start, offset);
						},
						model.segments);
					if (_v5.b) {
						var seg = _v5.a;
						var segName = A2($author$project$Main$getSegmentName, model, seg);
						return _List_fromArray(
							['', '; === ' + (segName + ' ===')]);
					} else {
						return _List_Nil;
					}
				}();
				var majorCommentLines = function () {
					var _v4 = A2($elm$core$Dict$get, offset, model.majorComments);
					if (_v4.$ === 'Just') {
						var mc = _v4.a;
						return A2(
							$elm$core$List$map,
							function (l) {
								return ';; ' + l;
							},
							$elm$core$String$lines(mc));
					} else {
						return _List_Nil;
					}
				}();
				var inByteRegion = A2(
					$elm$core$List$any,
					function (r) {
						return _Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
					},
					model.regions);
				var commentText = function () {
					var _v3 = A2($elm$core$Dict$get, offset, model.comments);
					if (_v3.$ === 'Just') {
						var cmt = _v3.a;
						return ' ; ' + cmt;
					} else {
						return '';
					}
				}();
				var address = model.loadAddress + offset;
				var labelLine = function () {
					var _v2 = A2($elm$core$Dict$get, address, model.labels);
					if (_v2.$ === 'Just') {
						var labelName = _v2.a;
						return _List_fromArray(
							[labelName + ':']);
					} else {
						return _List_Nil;
					}
				}();
				var _v0 = function () {
					if (textRegion.$ === 'Just') {
						var tr = textRegion.a;
						return A3($author$project$Main$generateTextLine, model, offset, tr.end);
					} else {
						return inByteRegion ? A2($author$project$Main$generateDataLine, model, offset) : A2($author$project$Main$generateCodeLine, model, offset);
					}
				}();
				var lineText = _v0.a;
				var bytesConsumed = _v0.b;
				var fullLine = '    ' + (lineText + commentText);
				var newAcc = _Utils_ap(
					A2($elm$core$List$cons, fullLine, labelLine),
					_Utils_ap(
						majorCommentLines,
						_Utils_ap(segmentStartLine, acc)));
				var $temp$model = model,
					$temp$offset = offset + bytesConsumed,
					$temp$acc = newAcc;
				model = $temp$model;
				offset = $temp$offset;
				acc = $temp$acc;
				continue generateAsmLines;
			}
		}
	});
var $author$project$Main$generateAsm = function (model) {
	var header = _List_fromArray(
		[
			'; Disassembly of ' + model.fileName,
			'; Generated by CDis',
			'',
			'* = $' + A2($author$project$Main$toHex, 4, model.loadAddress),
			''
		]);
	var asmLines = A3($author$project$Main$generateAsmLines, model, 0, _List_Nil);
	return A2(
		$elm$core$String$join,
		'\n',
		_Utils_ap(header, asmLines));
};
var $elm$browser$Browser$Dom$getElement = _Browser_getElement;
var $elm$core$Array$isEmpty = function (_v0) {
	var len = _v0.a;
	return !len;
};
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $elm$core$Char$isHexDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return ((48 <= code) && (code <= 57)) || (((65 <= code) && (code <= 70)) || ((97 <= code) && (code <= 102)));
};
var $elm$core$List$sortBy = _List_sortBy;
var $author$project$Main$mergeRegion = F2(
	function (newRegion, regions) {
		var merge = F2(
			function (r1, r2) {
				return {
					end: A2($elm$core$Basics$max, r1.end, r2.end),
					regionType: r1.regionType,
					start: A2($elm$core$Basics$min, r1.start, r2.start)
				};
			});
		var canMerge = F2(
			function (r1, r2) {
				return _Utils_eq(r1.regionType, r2.regionType) && (!((_Utils_cmp(r1.end, r2.start - 1) < 0) || (_Utils_cmp(r2.end, r1.start - 1) < 0)));
			});
		var insertAndMerge = F2(
			function (region, acc) {
				insertAndMerge:
				while (true) {
					if (!acc.b) {
						return _List_fromArray(
							[region]);
					} else {
						var r = acc.a;
						var rest = acc.b;
						if (A2(canMerge, region, r)) {
							var $temp$region = A2(merge, region, r),
								$temp$acc = rest;
							region = $temp$region;
							acc = $temp$acc;
							continue insertAndMerge;
						} else {
							return A2(
								$elm$core$List$cons,
								region,
								A2($elm$core$List$cons, r, rest));
						}
					}
				}
			});
		return A2(
			$elm$core$List$sortBy,
			function ($) {
				return $.start;
			},
			A2(
				insertAndMerge,
				newRegion,
				A2(
					$elm$core$List$sortBy,
					function ($) {
						return $.start;
					},
					regions)));
	});
var $author$project$Main$mergeSegment = F2(
	function (newSegment, segments) {
		var merge = F2(
			function (s1, s2) {
				return {
					end: A2($elm$core$Basics$max, s1.end, s2.end),
					start: A2($elm$core$Basics$min, s1.start, s2.start)
				};
			});
		var canMerge = F2(
			function (s1, s2) {
				return !((_Utils_cmp(s1.end, s2.start - 1) < 0) || (_Utils_cmp(s2.end, s1.start - 1) < 0));
			});
		var insertAndMerge = F2(
			function (segment, acc) {
				insertAndMerge:
				while (true) {
					if (!acc.b) {
						return _List_fromArray(
							[segment]);
					} else {
						var s = acc.a;
						var rest = acc.b;
						if (A2(canMerge, segment, s)) {
							var $temp$segment = A2(merge, segment, s),
								$temp$acc = rest;
							segment = $temp$segment;
							acc = $temp$acc;
							continue insertAndMerge;
						} else {
							return A2(
								$elm$core$List$cons,
								segment,
								A2($elm$core$List$cons, s, rest));
						}
					}
				}
			});
		return A2(
			$elm$core$List$sortBy,
			function ($) {
				return $.start;
			},
			A2(
				insertAndMerge,
				newSegment,
				A2(
					$elm$core$List$sortBy,
					function ($) {
						return $.start;
					},
					segments)));
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Main$hexDigitValue = function (c) {
	switch (c.valueOf()) {
		case '0':
			return $elm$core$Maybe$Just(0);
		case '1':
			return $elm$core$Maybe$Just(1);
		case '2':
			return $elm$core$Maybe$Just(2);
		case '3':
			return $elm$core$Maybe$Just(3);
		case '4':
			return $elm$core$Maybe$Just(4);
		case '5':
			return $elm$core$Maybe$Just(5);
		case '6':
			return $elm$core$Maybe$Just(6);
		case '7':
			return $elm$core$Maybe$Just(7);
		case '8':
			return $elm$core$Maybe$Just(8);
		case '9':
			return $elm$core$Maybe$Just(9);
		case 'A':
			return $elm$core$Maybe$Just(10);
		case 'B':
			return $elm$core$Maybe$Just(11);
		case 'C':
			return $elm$core$Maybe$Just(12);
		case 'D':
			return $elm$core$Maybe$Just(13);
		case 'E':
			return $elm$core$Maybe$Just(14);
		case 'F':
			return $elm$core$Maybe$Just(15);
		default:
			return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Main$parseHexHelper = F2(
	function (chars, acc) {
		parseHexHelper:
		while (true) {
			if (!chars.b) {
				return (acc > 0) ? $elm$core$Maybe$Just(acc) : $elm$core$Maybe$Nothing;
			} else {
				var c = chars.a;
				var rest = chars.b;
				var _v1 = $author$project$Main$hexDigitValue(c);
				if (_v1.$ === 'Just') {
					var v = _v1.a;
					var $temp$chars = rest,
						$temp$acc = (acc * 16) + v;
					chars = $temp$chars;
					acc = $temp$acc;
					continue parseHexHelper;
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$core$String$replace = F3(
	function (before, after, string) {
		return A2(
			$elm$core$String$join,
			after,
			A2($elm$core$String$split, before, string));
	});
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $elm$core$String$trim = _String_trim;
var $author$project$Main$parseHex = function (str) {
	var cleaned = A3(
		$elm$core$String$replace,
		'0X',
		'',
		A3(
			$elm$core$String$replace,
			'$',
			'',
			$elm$core$String$toUpper(
				$elm$core$String$trim(str))));
	return A2(
		$author$project$Main$parseHexHelper,
		$elm$core$String$toList(cleaned),
		0);
};
var $author$project$Main$PrgFileData = F3(
	function (fileName, bytes, cdisContent) {
		return {bytes: bytes, cdisContent: cdisContent, fileName: fileName};
	});
var $elm$json$Json$Decode$nullable = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder)
			]));
};
var $author$project$Main$prgFileDecoder = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Main$PrgFileData,
	A2($elm$json$Json$Decode$field, 'fileName', $elm$json$Json$Decode$string),
	A2(
		$elm$json$Json$Decode$field,
		'bytes',
		$elm$json$Json$Decode$list($elm$json$Json$Decode$int)),
	A2(
		$elm$json$Json$Decode$field,
		'cdisContent',
		$elm$json$Json$Decode$nullable($elm$json$Json$Decode$string)));
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$Main$quitApp = _Platform_outgoingPort(
	'quitApp',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.e.d.$ === 'RBNode_elm_builtin') && (dict.e.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.d.d.$ === 'RBNode_elm_builtin') && (dict.d.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Black')) {
					if (right.d.$ === 'RBNode_elm_builtin') {
						if (right.d.a.$ === 'Black') {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor.$ === 'Black') {
			if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === 'RBNode_elm_builtin') {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Black')) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === 'RBNode_elm_builtin') {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBNode_elm_builtin') {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === 'RBNode_elm_builtin') {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $author$project$Main$requestPrgFile = _Platform_outgoingPort(
	'requestPrgFile',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Main$saveCdisFile = _Platform_outgoingPort('saveCdisFile', $elm$json$Json$Encode$string);
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $author$project$Project$stringToRegionType = function (s) {
	if (s === 'text') {
		return $author$project$Types$TextRegion;
	} else {
		return $author$project$Types$ByteRegion;
	}
};
var $author$project$Project$toModel = F2(
	function (data, model) {
		return _Utils_update(
			model,
			{
				comments: $elm$core$Dict$fromList(data.comments),
				fileName: data.fileName,
				labels: $elm$core$Dict$fromList(data.labels),
				loadAddress: data.loadAddress,
				majorComments: $elm$core$Dict$fromList(data.majorComments),
				regions: A2(
					$elm$core$List$map,
					function (r) {
						return {
							end: r.end,
							regionType: $author$project$Project$stringToRegionType(r.regionType),
							start: r.start
						};
					},
					data.regions),
				segments: A2(
					$elm$core$List$map,
					function (s) {
						return {end: s.end, start: s.start};
					},
					data.segments)
			});
	});
var $author$project$Main$update = F2(
	function (msg, model) {
		update:
		while (true) {
			switch (msg.$) {
				case 'FocusResult':
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				case 'RequestFile':
					return _Utils_Tuple2(
						model,
						$author$project$Main$requestPrgFile(_Utils_Tuple0));
				case 'PrgFileOpened':
					var value = msg.a;
					var _v1 = A2($elm$json$Json$Decode$decodeValue, $author$project$Main$prgFileDecoder, value);
					if (_v1.$ === 'Ok') {
						var data = _v1.a;
						var programBytes = A2($elm$core$List$drop, 2, data.bytes);
						var loadAddr = A2(
							$elm$core$Maybe$withDefault,
							0,
							$elm$core$List$head(data.bytes)) + (A2(
							$elm$core$Maybe$withDefault,
							0,
							$elm$core$List$head(
								A2($elm$core$List$drop, 1, data.bytes))) * 256);
						var baseModel = _Utils_update(
							$author$project$Types$initModel,
							{
								bytes: $elm$core$Array$fromList(programBytes),
								fileName: data.fileName,
								loadAddress: loadAddr,
								selectedOffset: $elm$core$Maybe$Just(0),
								viewStart: 0
							});
						var finalModel = function () {
							var _v3 = data.cdisContent;
							if (_v3.$ === 'Just') {
								var jsonStr = _v3.a;
								var _v4 = A2($elm$json$Json$Decode$decodeString, $author$project$Project$decoder, jsonStr);
								if (_v4.$ === 'Ok') {
									var saveData = _v4.a;
									return A2($author$project$Project$toModel, saveData, baseModel);
								} else {
									return baseModel;
								}
							} else {
								return baseModel;
							}
						}();
						return _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(finalModel),
							$elm$core$Platform$Cmd$batch(
								_List_fromArray(
									[
										A2(
										$elm$core$Task$attempt,
										function (_v2) {
											return $author$project$Main$FocusResult;
										},
										$elm$browser$Browser$Dom$focus('cdis-main')),
										A2(
										$elm$core$Task$attempt,
										$author$project$Main$GotLinesElement,
										$elm$browser$Browser$Dom$getElement('lines-container'))
									])));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'Scroll':
					var delta = msg.a;
					var maxOffset = A2(
						$elm$core$Basics$max,
						0,
						$elm$core$Array$length(model.bytes) - model.viewLines);
					var newStart = A3($elm$core$Basics$clamp, 0, maxOffset, model.viewStart + delta);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{viewStart: newStart}),
						$elm$core$Platform$Cmd$none);
				case 'EnterGotoMode':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{gotoInput: '', gotoMode: true}),
						$elm$core$Platform$Cmd$none);
				case 'UpdateGotoInput':
					var str = msg.a;
					var filtered = A2(
						$elm$core$String$filter,
						function (c) {
							return $elm$core$Char$isHexDigit(c);
						},
						$elm$core$String$toUpper(str));
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								gotoInput: A2($elm$core$String$left, 4, filtered)
							}),
						$elm$core$Platform$Cmd$none);
				case 'ExecuteGoto':
					var _v5 = $author$project$Main$parseHex(model.gotoInput);
					if (_v5.$ === 'Just') {
						var addr = _v5.a;
						var offset = addr - model.loadAddress;
						return ((offset >= 0) && (_Utils_cmp(
							offset,
							$elm$core$Array$length(model.bytes)) < 0)) ? _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										gotoError: false,
										gotoInput: '',
										gotoMode: false,
										selectedOffset: $elm$core$Maybe$Just(offset),
										viewStart: offset
									})),
							A2(
								$elm$core$Task$attempt,
								function (_v6) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main'))) : _Utils_Tuple2(
							_Utils_update(
								model,
								{gotoError: true}),
							$elm$core$Platform$Cmd$none);
					} else {
						return $elm$core$String$isEmpty(model.gotoInput) ? _Utils_Tuple2(
							_Utils_update(
								model,
								{gotoError: false, gotoInput: '', gotoMode: false}),
							A2(
								$elm$core$Task$attempt,
								function (_v7) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main'))) : _Utils_Tuple2(
							_Utils_update(
								model,
								{gotoError: true}),
							$elm$core$Platform$Cmd$none);
					}
				case 'CancelGoto':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{gotoError: false, gotoInput: '', gotoMode: false}),
						A2(
							$elm$core$Task$attempt,
							function (_v8) {
								return $author$project$Main$FocusResult;
							},
							$elm$browser$Browser$Dom$focus('cdis-main')));
				case 'ClickAddress':
					var addr = msg.a;
					var offset = addr - model.loadAddress;
					var newHistory = function () {
						var _v9 = model.selectedOffset;
						if (_v9.$ === 'Just') {
							var currentOffset = _v9.a;
							return A2(
								$elm$core$List$take,
								50,
								A2($elm$core$List$cons, currentOffset, model.jumpHistory));
						} else {
							return model.jumpHistory;
						}
					}();
					return ((offset >= 0) && (_Utils_cmp(
						offset,
						$elm$core$Array$length(model.bytes)) < 0)) ? _Utils_Tuple2(
						$author$project$Main$ensureSelectionVisible(
							_Utils_update(
								model,
								{
									jumpHistory: newHistory,
									selectedOffset: $elm$core$Maybe$Just(offset),
									viewStart: offset
								})),
						$elm$core$Platform$Cmd$none) : _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				case 'SelectLine':
					var offset = msg.a;
					return _Utils_Tuple2(
						$author$project$Main$ensureSelectionVisible(
							_Utils_update(
								model,
								{
									selectedOffset: $elm$core$Maybe$Just(offset)
								})),
						$elm$core$Platform$Cmd$none);
				case 'StartEditComment':
					var offset = msg.a;
					var existingComment = A2(
						$elm$core$Maybe$withDefault,
						'',
						A2($elm$core$Dict$get, offset, model.comments));
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								editingComment: $elm$core$Maybe$Just(
									_Utils_Tuple2(offset, existingComment))
							}),
						A2(
							$elm$core$Task$attempt,
							function (_v10) {
								return $author$project$Main$NoOp;
							},
							$elm$browser$Browser$Dom$focus('comment-input')));
				case 'UpdateEditComment':
					var text = msg.a;
					var _v11 = model.editingComment;
					if (_v11.$ === 'Just') {
						var _v12 = _v11.a;
						var offset = _v12.a;
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									editingComment: $elm$core$Maybe$Just(
										_Utils_Tuple2(offset, text))
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'SaveComment':
					var _v13 = model.editingComment;
					if (_v13.$ === 'Just') {
						var _v14 = _v13.a;
						var offset = _v14.a;
						var text = _v14.b;
						var newComments = $elm$core$String$isEmpty(
							$elm$core$String$trim(text)) ? A2($elm$core$Dict$remove, offset, model.comments) : A3($elm$core$Dict$insert, offset, text, model.comments);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{comments: newComments, dirty: true, editingComment: $elm$core$Maybe$Nothing}),
							A2(
								$elm$core$Task$attempt,
								function (_v15) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main')));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'CancelEditComment':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{editingComment: $elm$core$Maybe$Nothing}),
						A2(
							$elm$core$Task$attempt,
							function (_v16) {
								return $author$project$Main$FocusResult;
							},
							$elm$browser$Browser$Dom$focus('cdis-main')));
				case 'StartEditLabel':
					var address = msg.a;
					var existingLabel = A2(
						$elm$core$Maybe$withDefault,
						'',
						A2($elm$core$Dict$get, address, model.labels));
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								editingLabel: $elm$core$Maybe$Just(
									_Utils_Tuple2(address, existingLabel))
							}),
						A2(
							$elm$core$Task$attempt,
							function (_v17) {
								return $author$project$Main$NoOp;
							},
							$elm$browser$Browser$Dom$focus('label-input')));
				case 'UpdateEditLabel':
					var text = msg.a;
					var _v18 = model.editingLabel;
					if (_v18.$ === 'Just') {
						var _v19 = _v18.a;
						var address = _v19.a;
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									editingLabel: $elm$core$Maybe$Just(
										_Utils_Tuple2(address, text))
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'SaveLabel':
					var _v20 = model.editingLabel;
					if (_v20.$ === 'Just') {
						var _v21 = _v20.a;
						var address = _v21.a;
						var text = _v21.b;
						var newLabels = $elm$core$String$isEmpty(
							$elm$core$String$trim(text)) ? A2($elm$core$Dict$remove, address, model.labels) : A3(
							$elm$core$Dict$insert,
							address,
							$elm$core$String$trim(text),
							model.labels);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{dirty: true, editingLabel: $elm$core$Maybe$Nothing, labels: newLabels}),
							A2(
								$elm$core$Task$attempt,
								function (_v22) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main')));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'CancelEditLabel':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{editingLabel: $elm$core$Maybe$Nothing}),
						A2(
							$elm$core$Task$attempt,
							function (_v23) {
								return $author$project$Main$FocusResult;
							},
							$elm$browser$Browser$Dom$focus('cdis-main')));
				case 'KeyPressed':
					var event = msg.a;
					if ((!_Utils_eq(model.editingComment, $elm$core$Maybe$Nothing)) || ((!_Utils_eq(model.editingLabel, $elm$core$Maybe$Nothing)) || (!_Utils_eq(model.editingMajorComment, $elm$core$Maybe$Nothing)))) {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					} else {
						if (model.gotoMode) {
							var _v24 = event.key;
							switch (_v24) {
								case 'Enter':
									var $temp$msg = $author$project$Main$ExecuteGoto,
										$temp$model = model;
									msg = $temp$msg;
									model = $temp$model;
									continue update;
								case 'Escape':
									var $temp$msg = $author$project$Main$CancelGoto,
										$temp$model = model;
									msg = $temp$msg;
									model = $temp$model;
									continue update;
								case 'Backspace':
									return _Utils_Tuple2(
										_Utils_update(
											model,
											{
												gotoError: false,
												gotoInput: A2($elm$core$String$dropRight, 1, model.gotoInput)
											}),
										$elm$core$Platform$Cmd$none);
								default:
									var key = _v24;
									if (($elm$core$String$length(key) === 1) && ($elm$core$String$length(model.gotoInput) < 4)) {
										var _char = $elm$core$String$toUpper(key);
										var isHex = A2($elm$core$String$all, $elm$core$Char$isHexDigit, _char);
										return isHex ? _Utils_Tuple2(
											_Utils_update(
												model,
												{
													gotoError: false,
													gotoInput: _Utils_ap(model.gotoInput, _char)
												}),
											$elm$core$Platform$Cmd$none) : _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
									} else {
										return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
									}
							}
						} else {
							if (model.outlineMode) {
								var _v25 = event.key;
								switch (_v25) {
									case 'ArrowLeft':
										var $temp$msg = $author$project$Main$OutlinePrev,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									case 'ArrowRight':
										var $temp$msg = $author$project$Main$OutlineNext,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									case 'Enter':
										var $temp$msg = $author$project$Main$OutlineSelect,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									case 'Escape':
										var $temp$msg = $author$project$Main$CancelOutline,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									default:
										return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
								}
							} else {
								if (model.confirmQuit) {
									if (event.key === 'q') {
										var $temp$msg = $author$project$Main$ConfirmQuit,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									} else {
										var $temp$msg = $author$project$Main$CancelQuit,
											$temp$model = model;
										msg = $temp$msg;
										model = $temp$model;
										continue update;
									}
								} else {
									var _v26 = event.key;
									switch (_v26) {
										case ' ':
											if (event.ctrl) {
												var $temp$msg = $author$project$Main$ToggleMark,
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case 'g':
											var $temp$msg = $author$project$Main$EnterGotoMode,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'l':
											return event.ctrl ? $author$project$Main$centerSelectedLine(model) : _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
										case ';':
											var _v27 = model.selectedOffset;
											if (_v27.$ === 'Just') {
												var offset = _v27.a;
												var $temp$msg = $author$project$Main$StartEditComment(offset),
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case ':':
											var _v28 = model.selectedOffset;
											if (_v28.$ === 'Just') {
												var offset = _v28.a;
												var address = model.loadAddress + offset;
												var $temp$msg = $author$project$Main$StartEditLabel(address),
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case '\"':
											var _v29 = model.selectedOffset;
											if (_v29.$ === 'Just') {
												var offset = _v29.a;
												var $temp$msg = $author$project$Main$StartEditMajorComment(offset),
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case 's':
											var $temp$msg = $author$project$Main$MarkSelectionAsSegment,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'S':
											var _v30 = model.selectedOffset;
											if (_v30.$ === 'Just') {
												var offset = _v30.a;
												if (A2(
													$elm$core$List$any,
													function (seg) {
														return (_Utils_cmp(offset, seg.start) > -1) && (_Utils_cmp(offset, seg.end) < 1);
													},
													model.segments)) {
													var $temp$msg = $author$project$Main$ClearSegment(offset),
														$temp$model = model;
													msg = $temp$msg;
													model = $temp$model;
													continue update;
												} else {
													var $temp$msg = $author$project$Main$SaveProject,
														$temp$model = model;
													msg = $temp$msg;
													model = $temp$model;
													continue update;
												}
											} else {
												var $temp$msg = $author$project$Main$SaveProject,
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											}
										case 'a':
											var $temp$msg = $author$project$Main$ExportAsm,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'q':
											var $temp$msg = $author$project$Main$RequestQuit,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'o':
											var $temp$msg = $author$project$Main$EnterOutlineMode,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'j':
											var _v31 = model.selectedOffset;
											if (_v31.$ === 'Just') {
												var offset = _v31.a;
												var line = A8($author$project$Disassembler$disassemble, model.loadAddress, offset, model.bytes, model.comments, model.labels, model.regions, model.segments, model.majorComments);
												var _v32 = line.targetAddress;
												if (_v32.$ === 'Just') {
													var addr = _v32.a;
													var $temp$msg = $author$project$Main$ClickAddress(addr),
														$temp$model = model;
													msg = $temp$msg;
													model = $temp$model;
													continue update;
												} else {
													return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
												}
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case 'b':
											var $temp$msg = $author$project$Main$MarkSelectionAsBytes,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'B':
											var _v33 = model.selectedOffset;
											if (_v33.$ === 'Just') {
												var offset = _v33.a;
												var $temp$msg = $author$project$Main$ClearByteRegion(offset),
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case 't':
											var $temp$msg = $author$project$Main$MarkSelectionAsText,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'T':
											var _v34 = model.selectedOffset;
											if (_v34.$ === 'Just') {
												var offset = _v34.a;
												var $temp$msg = $author$project$Main$ClearTextRegion(offset),
													$temp$model = model;
												msg = $temp$msg;
												model = $temp$model;
												continue update;
											} else {
												return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
											}
										case 'r':
											var $temp$msg = $author$project$Main$RestartDisassembly,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'Escape':
											return _Utils_Tuple2(
												_Utils_update(
													model,
													{mark: $elm$core$Maybe$Nothing}),
												$elm$core$Platform$Cmd$none);
										case '?':
											var $temp$msg = $author$project$Main$ToggleHelp,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'J':
											var $temp$msg = $author$project$Main$JumpBack,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'PageUp':
											var $temp$msg = $author$project$Main$PageUp,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'PageDown':
											var $temp$msg = $author$project$Main$PageDown,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'ArrowDown':
											var $temp$msg = $author$project$Main$SelectNextLine,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										case 'ArrowUp':
											var $temp$msg = $author$project$Main$SelectPrevLine,
												$temp$model = model;
											msg = $temp$msg;
											model = $temp$model;
											continue update;
										default:
											return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
									}
								}
							}
						}
					}
				case 'ToggleHelp':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{helpExpanded: !model.helpExpanded}),
						$elm$core$Platform$Cmd$none);
				case 'SelectNextLine':
					var _v35 = model.selectedOffset;
					if (_v35.$ === 'Just') {
						var offset = _v35.a;
						var textRegion = $elm$core$List$head(
							A2(
								$elm$core$List$filter,
								function (r) {
									return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
								},
								model.regions));
						var maxOffset = $elm$core$Array$length(model.bytes) - 1;
						var inByteRegion = A2(
							$elm$core$List$any,
							function (r) {
								return _Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
							},
							model.regions);
						var instrLen = function () {
							if (textRegion.$ === 'Just') {
								var tr = textRegion.a;
								return (tr.end - offset) + 1;
							} else {
								return inByteRegion ? 1 : A2(
									$elm$core$Maybe$withDefault,
									1,
									A2(
										$elm$core$Maybe$map,
										$author$project$Opcodes$opcodeBytes,
										A2($elm$core$Array$get, offset, model.bytes)));
							}
						}();
						var newOffset = offset + instrLen;
						return (_Utils_cmp(newOffset, maxOffset) < 1) ? _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										selectedOffset: $elm$core$Maybe$Just(newOffset)
									})),
							$elm$core$Platform$Cmd$none) : _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										selectedOffset: $elm$core$Maybe$Just(0)
									})),
							$elm$core$Platform$Cmd$none);
					}
				case 'SelectPrevLine':
					var _v37 = model.selectedOffset;
					if (_v37.$ === 'Just') {
						var offset = _v37.a;
						if (offset > 0) {
							var _v38 = A3($author$project$Main$findInstructionBoundaries, model.bytes, model.regions, offset);
							var currentStart = _v38.a;
							var prevStart = _v38.b;
							var newOffset = (_Utils_cmp(currentStart, offset) < 0) ? currentStart : prevStart;
							return _Utils_Tuple2(
								$author$project$Main$ensureSelectionVisible(
									_Utils_update(
										model,
										{
											selectedOffset: $elm$core$Maybe$Just(newOffset)
										})),
								$elm$core$Platform$Cmd$none);
						} else {
							return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
						}
					} else {
						return _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										selectedOffset: $elm$core$Maybe$Just(0)
									})),
							$elm$core$Platform$Cmd$none);
					}
				case 'SaveProject':
					if ($elm$core$Array$isEmpty(model.bytes)) {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					} else {
						var saveData = $author$project$Project$fromModel(model);
						var json = A2(
							$elm$json$Json$Encode$encode,
							2,
							$author$project$Project$encode(saveData));
						return _Utils_Tuple2(
							model,
							$author$project$Main$saveCdisFile(json));
					}
				case 'CdisSaved':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{dirty: false}),
						$elm$core$Platform$Cmd$none);
				case 'ErrorOccurred':
					var errorMsg = msg.a;
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				case 'ToggleMark':
					var _v39 = model.selectedOffset;
					if (_v39.$ === 'Just') {
						var offset = _v39.a;
						return _Utils_eq(
							model.mark,
							$elm$core$Maybe$Just(offset)) ? _Utils_Tuple2(
							_Utils_update(
								model,
								{mark: $elm$core$Maybe$Nothing}),
							$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
							_Utils_update(
								model,
								{
									mark: $elm$core$Maybe$Just(offset)
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'MarkSelectionAsBytes':
					var _v40 = _Utils_Tuple2(model.mark, model.selectedOffset);
					if ((_v40.a.$ === 'Just') && (_v40.b.$ === 'Just')) {
						var markOffset = _v40.a.a;
						var cursorOffset = _v40.b.a;
						var startOff = A2($elm$core$Basics$min, markOffset, cursorOffset);
						var endOff = A2($elm$core$Basics$max, markOffset, cursorOffset);
						var newRegion = {end: endOff, regionType: $author$project$Types$ByteRegion, start: startOff};
						var newRegions = A2($author$project$Main$mergeRegion, newRegion, model.regions);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{dirty: true, mark: $elm$core$Maybe$Nothing, regions: newRegions}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'MarkSelectionAsText':
					var _v41 = _Utils_Tuple2(model.mark, model.selectedOffset);
					if ((_v41.a.$ === 'Just') && (_v41.b.$ === 'Just')) {
						var markOffset = _v41.a.a;
						var cursorOffset = _v41.b.a;
						var startOff = A2($elm$core$Basics$min, markOffset, cursorOffset);
						var endOff = A2($elm$core$Basics$max, markOffset, cursorOffset);
						var newRegion = {end: endOff, regionType: $author$project$Types$TextRegion, start: startOff};
						var newRegions = A2($author$project$Main$mergeRegion, newRegion, model.regions);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{dirty: true, mark: $elm$core$Maybe$Nothing, regions: newRegions}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'ClearByteRegion':
					var offset = msg.a;
					var newRegions = A2(
						$elm$core$List$filter,
						function (r) {
							return !(_Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1)));
						},
						model.regions);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{dirty: true, regions: newRegions}),
						$elm$core$Platform$Cmd$none);
				case 'ClearTextRegion':
					var offset = msg.a;
					var newRegions = A2(
						$elm$core$List$filter,
						function (r) {
							return !(_Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1)));
						},
						model.regions);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{dirty: true, regions: newRegions}),
						$elm$core$Platform$Cmd$none);
				case 'MarkSelectionAsSegment':
					var _v42 = _Utils_Tuple2(model.mark, model.selectedOffset);
					if ((_v42.a.$ === 'Just') && (_v42.b.$ === 'Just')) {
						var markOffset = _v42.a.a;
						var cursorOffset = _v42.b.a;
						var startOff = A2($elm$core$Basics$min, markOffset, cursorOffset);
						var endOff = A2($elm$core$Basics$max, markOffset, cursorOffset);
						var newSegment = {end: endOff, start: startOff};
						var newSegments = A2($author$project$Main$mergeSegment, newSegment, model.segments);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{dirty: true, mark: $elm$core$Maybe$Nothing, segments: newSegments}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'ClearSegment':
					var offset = msg.a;
					var newSegments = A2(
						$elm$core$List$filter,
						function (s) {
							return !((_Utils_cmp(offset, s.start) > -1) && (_Utils_cmp(offset, s.end) < 1));
						},
						model.segments);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{dirty: true, segments: newSegments}),
						$elm$core$Platform$Cmd$none);
				case 'StartEditMajorComment':
					var offset = msg.a;
					var existingComment = A2(
						$elm$core$Maybe$withDefault,
						'',
						A2($elm$core$Dict$get, offset, model.majorComments));
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								editingMajorComment: $elm$core$Maybe$Just(
									_Utils_Tuple2(offset, existingComment))
							}),
						A2(
							$elm$core$Task$attempt,
							function (_v43) {
								return $author$project$Main$NoOp;
							},
							$elm$browser$Browser$Dom$focus('major-comment-input')));
				case 'UpdateEditMajorComment':
					var text = msg.a;
					var _v44 = model.editingMajorComment;
					if (_v44.$ === 'Just') {
						var _v45 = _v44.a;
						var offset = _v45.a;
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									editingMajorComment: $elm$core$Maybe$Just(
										_Utils_Tuple2(offset, text))
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'SaveMajorComment':
					var _v46 = model.editingMajorComment;
					if (_v46.$ === 'Just') {
						var _v47 = _v46.a;
						var offset = _v47.a;
						var text = _v47.b;
						var newMajorComments = $elm$core$String$isEmpty(
							$elm$core$String$trim(text)) ? A2($elm$core$Dict$remove, offset, model.majorComments) : A3($elm$core$Dict$insert, offset, text, model.majorComments);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{dirty: true, editingMajorComment: $elm$core$Maybe$Nothing, majorComments: newMajorComments}),
							A2(
								$elm$core$Task$attempt,
								function (_v48) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main')));
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'CancelEditMajorComment':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{editingMajorComment: $elm$core$Maybe$Nothing}),
						A2(
							$elm$core$Task$attempt,
							function (_v49) {
								return $author$project$Main$FocusResult;
							},
							$elm$browser$Browser$Dom$focus('cdis-main')));
				case 'EnterOutlineMode':
					if ($elm$core$List$isEmpty(model.segments)) {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					} else {
						var currentOffset = A2($elm$core$Maybe$withDefault, 0, model.selectedOffset);
						var segmentIndex = A2(
							$elm$core$Maybe$withDefault,
							0,
							A2(
								$elm$core$Maybe$map,
								$elm$core$Tuple$first,
								$elm$core$List$head(
									A2(
										$elm$core$List$filter,
										function (_v50) {
											var s = _v50.b;
											return (_Utils_cmp(currentOffset, s.start) > -1) && (_Utils_cmp(currentOffset, s.end) < 1);
										},
										A2($elm$core$List$indexedMap, $elm$core$Tuple$pair, model.segments)))));
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{outlineMode: true, outlineSelection: segmentIndex}),
							$elm$core$Platform$Cmd$none);
					}
				case 'OutlineNext':
					var maxIdx = $elm$core$List$length(model.segments) - 1;
					var newIdx = A2($elm$core$Basics$min, maxIdx, model.outlineSelection + 1);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{outlineSelection: newIdx}),
						$elm$core$Platform$Cmd$none);
				case 'OutlinePrev':
					var newIdx = A2($elm$core$Basics$max, 0, model.outlineSelection - 1);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{outlineSelection: newIdx}),
						$elm$core$Platform$Cmd$none);
				case 'OutlineSelect':
					var maybeSegment = $elm$core$List$head(
						A2($elm$core$List$drop, model.outlineSelection, model.segments));
					if (maybeSegment.$ === 'Just') {
						var segment = maybeSegment.a;
						return _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										outlineMode: false,
										selectedOffset: $elm$core$Maybe$Just(segment.start),
										viewStart: segment.start
									})),
							A2(
								$elm$core$Task$attempt,
								function (_v52) {
									return $author$project$Main$FocusResult;
								},
								$elm$browser$Browser$Dom$focus('cdis-main')));
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{outlineMode: false}),
							$elm$core$Platform$Cmd$none);
					}
				case 'CancelOutline':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{outlineMode: false}),
						A2(
							$elm$core$Task$attempt,
							function (_v53) {
								return $author$project$Main$FocusResult;
							},
							$elm$browser$Browser$Dom$focus('cdis-main')));
				case 'RestartDisassembly':
					var _v54 = model.selectedOffset;
					if (_v54.$ === 'Just') {
						var offset = _v54.a;
						if (_Utils_cmp(
							offset,
							$elm$core$Array$length(model.bytes) - 1) < 0) {
							var newRegion = {end: offset, regionType: $author$project$Types$ByteRegion, start: offset};
							var newRegions = A2($author$project$Main$mergeRegion, newRegion, model.regions);
							var newOffset = offset + 1;
							return _Utils_Tuple2(
								$author$project$Main$ensureSelectionVisible(
									_Utils_update(
										model,
										{
											dirty: true,
											regions: newRegions,
											selectedOffset: $elm$core$Maybe$Just(newOffset)
										})),
								$elm$core$Platform$Cmd$none);
						} else {
							return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
						}
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'JumpBack':
					var _v55 = model.jumpHistory;
					if (_v55.b) {
						var prevOffset = _v55.a;
						var rest = _v55.b;
						return _Utils_Tuple2(
							$author$project$Main$ensureSelectionVisible(
								_Utils_update(
									model,
									{
										jumpHistory: rest,
										selectedOffset: $elm$core$Maybe$Just(prevOffset),
										viewStart: prevOffset
									})),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				case 'PageUp':
					var newViewStart = A2($elm$core$Basics$max, 0, model.viewStart - model.viewLines);
					var _v56 = A3($author$project$Main$findInstructionBoundaries, model.bytes, model.regions, newViewStart);
					var instrStart = _v56.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								selectedOffset: $elm$core$Maybe$Just(instrStart),
								viewStart: instrStart
							}),
						$elm$core$Platform$Cmd$none);
				case 'PageDown':
					var maxOffset = $elm$core$Array$length(model.bytes) - 1;
					var newViewStart = A2($elm$core$Basics$min, maxOffset, model.viewStart + model.viewLines);
					var _v57 = A3($author$project$Main$findInstructionBoundaries, model.bytes, model.regions, newViewStart);
					var instrStart = _v57.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								selectedOffset: $elm$core$Maybe$Just(instrStart),
								viewStart: instrStart
							}),
						$elm$core$Platform$Cmd$none);
				case 'RequestQuit':
					return model.dirty ? _Utils_Tuple2(
						_Utils_update(
							model,
							{confirmQuit: true}),
						$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
						model,
						$author$project$Main$quitApp(_Utils_Tuple0));
				case 'ConfirmQuit':
					return _Utils_Tuple2(
						model,
						$author$project$Main$quitApp(_Utils_Tuple0));
				case 'CancelQuit':
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{confirmQuit: false}),
						$elm$core$Platform$Cmd$none);
				case 'ExportAsm':
					if ($elm$core$Array$isEmpty(model.bytes)) {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					} else {
						var asmContent = $author$project$Main$generateAsm(model);
						return _Utils_Tuple2(
							model,
							$author$project$Main$exportAsmFile(asmContent));
					}
				case 'WindowResized':
					return _Utils_Tuple2(
						model,
						A2(
							$elm$core$Task$attempt,
							$author$project$Main$GotLinesElement,
							$elm$browser$Browser$Dom$getElement('lines-container')));
				case 'GotViewport':
					return _Utils_Tuple2(
						model,
						A2(
							$elm$core$Task$attempt,
							$author$project$Main$GotLinesElement,
							$elm$browser$Browser$Dom$getElement('lines-container')));
				case 'GotLinesElement':
					var result = msg.a;
					if (result.$ === 'Ok') {
						var element = result.a;
						var lineHeight = 24;
						var availableHeight = element.element.height;
						var newViewLines = A2(
							$elm$core$Basics$max,
							5,
							($elm$core$Basics$floor(availableHeight) / lineHeight) | 0);
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{viewLines: newViewLines}),
							$elm$core$Platform$Cmd$none);
					} else {
						return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
					}
				default:
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			}
		}
	});
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $author$project$Main$KeyEvent = F4(
	function (key, ctrl, alt, shift) {
		return {alt: alt, ctrl: ctrl, key: key, shift: shift};
	});
var $author$project$Main$KeyPressed = function (a) {
	return {$: 'KeyPressed', a: a};
};
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $elm$json$Json$Decode$map4 = _Json_map4;
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm$virtual_dom$VirtualDom$MayPreventDefault = function (a) {
	return {$: 'MayPreventDefault', a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$preventDefaultOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayPreventDefault(decoder));
	});
var $author$project$Main$onKeyDownPreventDefault = function () {
	var decoder = A2(
		$elm$json$Json$Decode$map,
		function (event) {
			var shouldPrevent = A2(
				$elm$core$List$member,
				event.key,
				_List_fromArray(
					['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'PageUp', 'PageDown'])) || ((event.key === ' ') && event.ctrl);
			var msg = $author$project$Main$KeyPressed(event);
			return _Utils_Tuple2(msg, shouldPrevent);
		},
		A5(
			$elm$json$Json$Decode$map4,
			$author$project$Main$KeyEvent,
			A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string),
			A2($elm$json$Json$Decode$field, 'ctrlKey', $elm$json$Json$Decode$bool),
			A2($elm$json$Json$Decode$field, 'altKey', $elm$json$Json$Decode$bool),
			A2($elm$json$Json$Decode$field, 'shiftKey', $elm$json$Json$Decode$bool)));
	return A2($elm$html$Html$Events$preventDefaultOn, 'keydown', decoder);
}();
var $elm$html$Html$Attributes$tabindex = function (n) {
	return A2(
		_VirtualDom_attribute,
		'tabIndex',
		$elm$core$String$fromInt(n));
};
var $author$project$Opcodes$addressingModeString = function (mode) {
	switch (mode.$) {
		case 'Implied':
			return 'Implied';
		case 'Accumulator':
			return 'Accumulator';
		case 'Immediate':
			return 'Immediate';
		case 'ZeroPage':
			return 'Zero Page';
		case 'ZeroPageX':
			return 'Zero Page,X';
		case 'ZeroPageY':
			return 'Zero Page,Y';
		case 'Absolute':
			return 'Absolute';
		case 'AbsoluteX':
			return 'Absolute,X';
		case 'AbsoluteY':
			return 'Absolute,Y';
		case 'Indirect':
			return 'Indirect';
		case 'IndirectX':
			return 'Indirect,X';
		case 'IndirectY':
			return 'Indirect,Y';
		default:
			return 'Relative';
	}
};
var $author$project$Opcodes$getOpcodeDescription = function (mnemonic) {
	var _v0 = $elm$core$String$toUpper(mnemonic);
	switch (_v0) {
		case 'LDA':
			return 'Load Accumulator from memory';
		case 'LDX':
			return 'Load X register from memory';
		case 'LDY':
			return 'Load Y register from memory';
		case 'STA':
			return 'Store Accumulator to memory';
		case 'STX':
			return 'Store X register to memory';
		case 'STY':
			return 'Store Y register to memory';
		case 'TAX':
			return 'Transfer Accumulator to X';
		case 'TAY':
			return 'Transfer Accumulator to Y';
		case 'TXA':
			return 'Transfer X to Accumulator';
		case 'TYA':
			return 'Transfer Y to Accumulator';
		case 'TSX':
			return 'Transfer Stack Pointer to X';
		case 'TXS':
			return 'Transfer X to Stack Pointer';
		case 'PHA':
			return 'Push Accumulator to stack';
		case 'PHP':
			return 'Push Processor Status to stack';
		case 'PLA':
			return 'Pull Accumulator from stack';
		case 'PLP':
			return 'Pull Processor Status from stack';
		case 'ADC':
			return 'Add to Accumulator with Carry';
		case 'SBC':
			return 'Subtract from Accumulator with Borrow';
		case 'INC':
			return 'Increment memory by one';
		case 'INX':
			return 'Increment X by one';
		case 'INY':
			return 'Increment Y by one';
		case 'DEC':
			return 'Decrement memory by one';
		case 'DEX':
			return 'Decrement X by one';
		case 'DEY':
			return 'Decrement Y by one';
		case 'AND':
			return 'Logical AND with Accumulator';
		case 'ORA':
			return 'Logical OR with Accumulator';
		case 'EOR':
			return 'Exclusive OR with Accumulator';
		case 'BIT':
			return 'Test bits in memory with Accumulator';
		case 'ASL':
			return 'Arithmetic Shift Left (C <- [76543210] <- 0)';
		case 'LSR':
			return 'Logical Shift Right (0 -> [76543210] -> C)';
		case 'ROL':
			return 'Rotate Left (C <- [76543210] <- C)';
		case 'ROR':
			return 'Rotate Right (C -> [76543210] -> C)';
		case 'CMP':
			return 'Compare Accumulator with memory';
		case 'CPX':
			return 'Compare X with memory';
		case 'CPY':
			return 'Compare Y with memory';
		case 'BCC':
			return 'Branch if Carry Clear (C=0)';
		case 'BCS':
			return 'Branch if Carry Set (C=1)';
		case 'BEQ':
			return 'Branch if Equal (Z=1)';
		case 'BMI':
			return 'Branch if Minus (N=1)';
		case 'BNE':
			return 'Branch if Not Equal (Z=0)';
		case 'BPL':
			return 'Branch if Plus (N=0)';
		case 'BVC':
			return 'Branch if Overflow Clear (V=0)';
		case 'BVS':
			return 'Branch if Overflow Set (V=1)';
		case 'JMP':
			return 'Jump to address';
		case 'JSR':
			return 'Jump to Subroutine (push return address)';
		case 'RTS':
			return 'Return from Subroutine';
		case 'RTI':
			return 'Return from Interrupt';
		case 'BRK':
			return 'Force Break (software interrupt)';
		case 'CLC':
			return 'Clear Carry flag';
		case 'CLD':
			return 'Clear Decimal mode';
		case 'CLI':
			return 'Clear Interrupt Disable';
		case 'CLV':
			return 'Clear Overflow flag';
		case 'SEC':
			return 'Set Carry flag';
		case 'SED':
			return 'Set Decimal mode';
		case 'SEI':
			return 'Set Interrupt Disable';
		case 'NOP':
			return 'No Operation';
		case 'LAX':
			return 'LDA + LDX (load A and X)';
		case 'SAX':
			return 'Store A AND X to memory';
		case 'DCP':
			return 'DEC + CMP (decrement then compare)';
		case 'ISC':
			return 'INC + SBC (increment then subtract)';
		case 'SLO':
			return 'ASL + ORA (shift left then OR)';
		case 'RLA':
			return 'ROL + AND (rotate left then AND)';
		case 'SRE':
			return 'LSR + EOR (shift right then XOR)';
		case 'RRA':
			return 'ROR + ADC (rotate right then add)';
		case 'ANC':
			return 'AND + set Carry from bit 7';
		case 'ALR':
			return 'AND + LSR (AND then shift right)';
		case 'ARR':
			return 'AND + ROR (AND then rotate right)';
		case 'SBX':
			return '(A AND X) minus operand -> X';
		case 'ANE':
			return 'A = (A OR magic) AND X AND operand';
		case 'LXA':
			return 'A = X = (A OR magic) AND operand';
		case 'SHA':
			return 'Store A AND X AND (addr_hi + 1)';
		case 'SHX':
			return 'Store X AND (addr_hi + 1)';
		case 'SHY':
			return 'Store Y AND (addr_hi + 1)';
		case 'TAS':
			return 'S = A AND X; store S AND (addr_hi + 1)';
		case 'LAS':
			return 'A = X = S = memory AND S';
		case 'JAM':
			return 'Halt processor (freeze/crash)';
		default:
			return 'Unknown opcode';
	}
};
var $author$project$Opcodes$getOpcodeFlags = function (mnemonic) {
	var _v0 = $elm$core$String$toUpper(mnemonic);
	switch (_v0) {
		case 'LDA':
			return 'N Z';
		case 'LDX':
			return 'N Z';
		case 'LDY':
			return 'N Z';
		case 'STA':
			return '-';
		case 'STX':
			return '-';
		case 'STY':
			return '-';
		case 'TAX':
			return 'N Z';
		case 'TAY':
			return 'N Z';
		case 'TXA':
			return 'N Z';
		case 'TYA':
			return 'N Z';
		case 'TSX':
			return 'N Z';
		case 'TXS':
			return '-';
		case 'PHA':
			return '-';
		case 'PHP':
			return '-';
		case 'PLA':
			return 'N Z';
		case 'PLP':
			return 'all';
		case 'ADC':
			return 'N V Z C';
		case 'SBC':
			return 'N V Z C';
		case 'INC':
			return 'N Z';
		case 'INX':
			return 'N Z';
		case 'INY':
			return 'N Z';
		case 'DEC':
			return 'N Z';
		case 'DEX':
			return 'N Z';
		case 'DEY':
			return 'N Z';
		case 'AND':
			return 'N Z';
		case 'ORA':
			return 'N Z';
		case 'EOR':
			return 'N Z';
		case 'BIT':
			return 'N V Z';
		case 'ASL':
			return 'N Z C';
		case 'LSR':
			return 'N Z C';
		case 'ROL':
			return 'N Z C';
		case 'ROR':
			return 'N Z C';
		case 'CMP':
			return 'N Z C';
		case 'CPX':
			return 'N Z C';
		case 'CPY':
			return 'N Z C';
		case 'BCC':
			return '-';
		case 'BCS':
			return '-';
		case 'BEQ':
			return '-';
		case 'BMI':
			return '-';
		case 'BNE':
			return '-';
		case 'BPL':
			return '-';
		case 'BVC':
			return '-';
		case 'BVS':
			return '-';
		case 'JMP':
			return '-';
		case 'JSR':
			return '-';
		case 'RTS':
			return '-';
		case 'RTI':
			return 'all';
		case 'BRK':
			return 'B I';
		case 'CLC':
			return 'C';
		case 'CLD':
			return 'D';
		case 'CLI':
			return 'I';
		case 'CLV':
			return 'V';
		case 'SEC':
			return 'C';
		case 'SED':
			return 'D';
		case 'SEI':
			return 'I';
		case 'NOP':
			return '-';
		case 'LAX':
			return 'N Z';
		case 'SAX':
			return '-';
		case 'DCP':
			return 'N Z C';
		case 'ISC':
			return 'N V Z C';
		case 'SLO':
			return 'N Z C';
		case 'RLA':
			return 'N Z C';
		case 'SRE':
			return 'N Z C';
		case 'RRA':
			return 'N V Z C';
		case 'ANC':
			return 'N Z C';
		case 'ALR':
			return 'N Z C';
		case 'ARR':
			return 'N V Z C';
		case 'SBX':
			return 'N Z C';
		case 'ANE':
			return 'N Z';
		case 'LXA':
			return 'N Z';
		case 'SHA':
			return '-';
		case 'SHX':
			return '-';
		case 'SHY':
			return '-';
		case 'TAS':
			return '-';
		case 'LAS':
			return 'N Z';
		case 'JAM':
			return '-';
		default:
			return '?';
	}
};
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 'Nothing') {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 'Nothing') {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $author$project$Main$getOperandAddress = F3(
	function (model, offset, info) {
		var getByte = function (off) {
			return A2($elm$core$Array$get, off, model.bytes);
		};
		var hi = getByte(offset + 2);
		var lo = getByte(offset + 1);
		var _v0 = info.mode;
		switch (_v0.$) {
			case 'ZeroPage':
				return lo;
			case 'ZeroPageX':
				return lo;
			case 'ZeroPageY':
				return lo;
			case 'Absolute':
				return A3(
					$elm$core$Maybe$map2,
					F2(
						function (l, h) {
							return (h * 256) + l;
						}),
					lo,
					hi);
			case 'AbsoluteX':
				return A3(
					$elm$core$Maybe$map2,
					F2(
						function (l, h) {
							return (h * 256) + l;
						}),
					lo,
					hi);
			case 'AbsoluteY':
				return A3(
					$elm$core$Maybe$map2,
					F2(
						function (l, h) {
							return (h * 256) + l;
						}),
					lo,
					hi);
			case 'Indirect':
				return A3(
					$elm$core$Maybe$map2,
					F2(
						function (l, h) {
							return (h * 256) + l;
						}),
					lo,
					hi);
			case 'IndirectX':
				return lo;
			case 'IndirectY':
				return lo;
			case 'Relative':
				return A2(
					$elm$core$Maybe$map,
					function (_byte) {
						var signedOffset = (_byte > 127) ? (_byte - 256) : _byte;
						return ((model.loadAddress + offset) + 2) + signedOffset;
					},
					lo);
			default:
				return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Symbols$getSymbolInfo = function (addr) {
	return A2($elm$core$Dict$get, addr, $author$project$Symbols$symbolTable);
};
var $elm$html$Html$span = _VirtualDom_node('span');
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Main$viewCheatsheet = function (model) {
	var _v0 = model.selectedOffset;
	if (_v0.$ === 'Nothing') {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('cheatsheet')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('cheatsheet-empty')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Select a line to see opcode info')
						]))
				]));
	} else {
		var offset = _v0.a;
		var inTextRegion = A2(
			$elm$core$List$any,
			function (r) {
				return _Utils_eq(r.regionType, $author$project$Types$TextRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
			},
			model.regions);
		var inByteRegion = A2(
			$elm$core$List$any,
			function (r) {
				return _Utils_eq(r.regionType, $author$project$Types$ByteRegion) && ((_Utils_cmp(offset, r.start) > -1) && (_Utils_cmp(offset, r.end) < 1));
			},
			model.regions);
		if (inTextRegion) {
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('cheatsheet')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cheatsheet-mnemonic')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('.text')
							])),
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cheatsheet-sep')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(' | ')
							])),
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cheatsheet-desc')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Text data (PETSCII)')
							]))
					]));
		} else {
			if (inByteRegion) {
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('cheatsheet')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$span,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('cheatsheet-mnemonic')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('.byte')
								])),
							A2(
							$elm$html$Html$span,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('cheatsheet-sep')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(' | ')
								])),
							A2(
							$elm$html$Html$span,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('cheatsheet-desc')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Data byte (not code)')
								]))
						]));
			} else {
				var _v1 = A2($elm$core$Array$get, offset, model.bytes);
				if (_v1.$ === 'Nothing') {
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cheatsheet')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('cheatsheet-empty')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('End of file')
									]))
							]));
				} else {
					var opcodeByte = _v1.a;
					var info = $author$project$Opcodes$getOpcode(opcodeByte);
					var mnemonic = info.undocumented ? ('*' + info.mnemonic) : info.mnemonic;
					var mode = $author$project$Opcodes$addressingModeString(info.mode);
					var operandAddr = A3($author$project$Main$getOperandAddress, model, offset, info);
					var symbolInfoPart = function () {
						if (operandAddr.$ === 'Just') {
							var addr = operandAddr.a;
							var _v3 = $author$project$Symbols$getSymbolInfo(addr);
							if (_v3.$ === 'Just') {
								var symInfo = _v3.a;
								return _List_fromArray(
									[
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('cheatsheet-sep')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(' | ')
											])),
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('cheatsheet-symbol')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(symInfo.name)
											])),
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('cheatsheet-sep')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(': ')
											])),
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('cheatsheet-symbol-desc')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(symInfo.description)
											]))
									]);
							} else {
								return _List_Nil;
							}
						} else {
							return _List_Nil;
						}
					}();
					var flags = $author$project$Opcodes$getOpcodeFlags(info.mnemonic);
					var description = $author$project$Opcodes$getOpcodeDescription(info.mnemonic);
					var cycles = $elm$core$String$fromInt(info.cycles);
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cheatsheet')
							]),
						_Utils_ap(
							_List_fromArray(
								[
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-mnemonic')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(mnemonic)
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-sep')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(' | ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-mode')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(mode)
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-sep')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(' | ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-desc')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(description)
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-sep')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(' | ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-label')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('Flags: ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-flags')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(flags)
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-sep')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(' | ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-label')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('Cycles: ')
										])),
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('cheatsheet-cycles')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(cycles)
										]))
								]),
							symbolInfoPart));
				}
			}
		}
	}
};
var $author$project$Main$Scroll = function (a) {
	return {$: 'Scroll', a: a};
};
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Disassembler$disassembleHelper = function (loadAddress) {
	return function (offset) {
		return function (remaining) {
			return function (bytes) {
				return function (comments) {
					return function (labels) {
						return function (regions) {
							return function (segments) {
								return function (majorComments) {
									return function (acc) {
										disassembleHelper:
										while (true) {
											if ((remaining <= 0) || (_Utils_cmp(
												offset,
												$elm$core$Array$length(bytes)) > -1)) {
												return $elm$core$List$reverse(acc);
											} else {
												var newRemaining = remaining - 1;
												var line = A8($author$project$Disassembler$disassembleLine, loadAddress, offset, bytes, comments, labels, regions, segments, majorComments);
												var newOffset = offset + $elm$core$List$length(line.bytes);
												var $temp$loadAddress = loadAddress,
													$temp$offset = newOffset,
													$temp$remaining = newRemaining,
													$temp$bytes = bytes,
													$temp$comments = comments,
													$temp$labels = labels,
													$temp$regions = regions,
													$temp$segments = segments,
													$temp$majorComments = majorComments,
													$temp$acc = A2($elm$core$List$cons, line, acc);
												loadAddress = $temp$loadAddress;
												offset = $temp$offset;
												remaining = $temp$remaining;
												bytes = $temp$bytes;
												comments = $temp$comments;
												labels = $temp$labels;
												regions = $temp$regions;
												segments = $temp$segments;
												majorComments = $temp$majorComments;
												acc = $temp$acc;
												continue disassembleHelper;
											}
										}
									};
								};
							};
						};
					};
				};
			};
		};
	};
};
var $author$project$Disassembler$disassembleRange = F9(
	function (loadAddress, startOffset, count, bytes, comments, labels, regions, segments, majorComments) {
		return $author$project$Disassembler$disassembleHelper(loadAddress)(startOffset)(count)(bytes)(comments)(labels)(regions)(segments)(majorComments)(_List_Nil);
	});
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 'Normal', a: a};
};
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $author$project$Main$onWheel = function (toMsg) {
	return A2(
		$elm$html$Html$Events$on,
		'wheel',
		A2(
			$elm$json$Json$Decode$map,
			function (dy) {
				return (dy > 0) ? toMsg(3) : toMsg(-3);
			},
			A2($elm$json$Json$Decode$field, 'deltaY', $elm$json$Json$Decode$float)));
};
var $author$project$Main$viewDisassemblyHeader = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			$elm$html$Html$Attributes$class('disasm-header')
		]),
	_List_fromArray(
		[
			A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('col-address')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Address')
				])),
			A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('col-bytes')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Bytes')
				])),
			A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('col-disasm')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Disassembly')
				])),
			A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('col-comment')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Comment')
				]))
		]));
var $author$project$Main$SelectLine = function (a) {
	return {$: 'SelectLine', a: a};
};
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Main$viewLabelLine = F2(
	function (labelText, line) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('line label-line'),
					$elm$html$Html$Events$onClick(
					$author$project$Main$SelectLine(line.offset))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('label-text')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(labelText + ':')
						]))
				]));
	});
var $author$project$Main$SaveLabel = {$: 'SaveLabel'};
var $author$project$Main$UpdateEditLabel = function (a) {
	return {$: 'UpdateEditLabel', a: a};
};
var $elm$json$Json$Encode$bool = _Json_wrap;
var $elm$html$Html$Attributes$boolProperty = F2(
	function (key, bool) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$bool(bool));
	});
var $elm$html$Html$Attributes$autofocus = $elm$html$Html$Attributes$boolProperty('autofocus');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$html$Html$Events$onBlur = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'blur',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 'MayStopPropagation', a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $author$project$Main$CancelEditLabel = {$: 'CancelEditLabel'};
var $author$project$Main$onKeyDownLabel = A2(
	$elm$html$Html$Events$stopPropagationOn,
	'keydown',
	A2(
		$elm$json$Json$Decode$map,
		function (key) {
			return (key === 'Enter') ? _Utils_Tuple2($author$project$Main$SaveLabel, true) : ((key === 'Escape') ? _Utils_Tuple2($author$project$Main$CancelEditLabel, true) : _Utils_Tuple2($author$project$Main$NoOp, true));
		},
		A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string)));
var $elm$html$Html$Attributes$placeholder = $elm$html$Html$Attributes$stringProperty('placeholder');
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Main$viewLabelLineEditing = F2(
	function (currentText, line) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('line label-line editing')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Attributes$value(currentText),
							$elm$html$Html$Events$onInput($author$project$Main$UpdateEditLabel),
							$elm$html$Html$Events$onBlur($author$project$Main$SaveLabel),
							$author$project$Main$onKeyDownLabel,
							$elm$html$Html$Attributes$id('label-input'),
							$elm$html$Html$Attributes$autofocus(true),
							$elm$html$Html$Attributes$placeholder('label name'),
							$elm$html$Html$Attributes$class('label-input')
						]),
					_List_Nil),
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('label-colon')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(':')
						]))
				]));
	});
var $author$project$Main$formatBytes = function (bytes) {
	return A2(
		$elm$core$String$join,
		' ',
		A2(
			$elm$core$List$map,
			$author$project$Main$toHex(2),
			bytes));
};
var $elm$html$Html$Events$onDoubleClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'dblclick',
		$elm$json$Json$Decode$succeed(msg));
};
var $author$project$Main$SaveComment = {$: 'SaveComment'};
var $author$project$Main$UpdateEditComment = function (a) {
	return {$: 'UpdateEditComment', a: a};
};
var $author$project$Main$CancelEditComment = {$: 'CancelEditComment'};
var $author$project$Main$onKeyDownComment = A2(
	$elm$html$Html$Events$stopPropagationOn,
	'keydown',
	A2(
		$elm$json$Json$Decode$map,
		function (key) {
			return (key === 'Enter') ? _Utils_Tuple2($author$project$Main$SaveComment, true) : ((key === 'Escape') ? _Utils_Tuple2($author$project$Main$CancelEditComment, true) : _Utils_Tuple2($author$project$Main$NoOp, true));
		},
		A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string)));
var $author$project$Main$viewCommentText = function (maybeComment) {
	return A2(
		$elm$html$Html$span,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('col-comment')
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(
				A2(
					$elm$core$Maybe$withDefault,
					'',
					A2(
						$elm$core$Maybe$map,
						function (c) {
							return '; ' + c;
						},
						maybeComment)))
			]));
};
var $author$project$Main$viewComment = F2(
	function (model, line) {
		var _v0 = model.editingComment;
		if (_v0.$ === 'Just') {
			var _v1 = _v0.a;
			var offset = _v1.a;
			var text_ = _v1.b;
			return _Utils_eq(offset, line.offset) ? A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('col-comment editing')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$input,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$type_('text'),
								$elm$html$Html$Attributes$value(text_),
								$elm$html$Html$Events$onInput($author$project$Main$UpdateEditComment),
								$elm$html$Html$Events$onBlur($author$project$Main$SaveComment),
								$author$project$Main$onKeyDownComment,
								$elm$html$Html$Attributes$id('comment-input'),
								$elm$html$Html$Attributes$autofocus(true)
							]),
						_List_Nil)
					])) : $author$project$Main$viewCommentText(line.comment);
		} else {
			return $author$project$Main$viewCommentText(line.comment);
		}
	});
var $author$project$Main$viewDisasm = F2(
	function (line, labels) {
		var _v0 = line.targetAddress;
		if (_v0.$ === 'Nothing') {
			return A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('col-disasm')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text(line.disassembly)
					]));
		} else {
			var addr = _v0.a;
			var parts = $elm$core$String$words(line.disassembly);
			var labelName = A2($elm$core$Dict$get, addr, labels);
			if (parts.b) {
				var mnemonic = parts.a;
				var operandParts = parts.b;
				var operand = function () {
					if (labelName.$ === 'Just') {
						var lbl = labelName.a;
						return lbl;
					} else {
						return A2($elm$core$String$join, ' ', operandParts);
					}
				}();
				return A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('col-disasm')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(mnemonic + ' '),
							A2(
							$elm$html$Html$span,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('operand-link'),
									A2(
									$elm$html$Html$Events$stopPropagationOn,
									'click',
									$elm$json$Json$Decode$succeed(
										_Utils_Tuple2(
											$author$project$Main$ClickAddress(addr),
											true)))
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(operand)
								]))
						]));
			} else {
				return A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('col-disasm')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(line.disassembly)
						]));
			}
		}
	});
var $author$project$Main$viewLine = F2(
	function (model, line) {
		var isSelected = _Utils_eq(
			model.selectedOffset,
			$elm$core$Maybe$Just(line.offset));
		var isInSelection = function () {
			var _v0 = _Utils_Tuple2(model.mark, model.selectedOffset);
			if ((_v0.a.$ === 'Just') && (_v0.b.$ === 'Just')) {
				var markOffset = _v0.a.a;
				var cursorOffset = _v0.b.a;
				var selStart = A2($elm$core$Basics$min, markOffset, cursorOffset);
				var selEnd = A2($elm$core$Basics$max, markOffset, cursorOffset);
				return (_Utils_cmp(line.offset, selStart) > -1) && (_Utils_cmp(line.offset, selEnd) < 1);
			} else {
				return false;
			}
		}();
		var lineClass = A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$filter,
				$elm$core$Basics$neq(''),
				_List_fromArray(
					[
						'line',
						isSelected ? 'selected' : '',
						isInSelection ? 'in-selection' : '',
						line.isData ? 'data-region' : '',
						line.isText ? 'text-region' : '',
						line.inSegment ? 'in-segment' : ''
					])));
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class(lineClass),
					$elm$html$Html$Events$onClick(
					$author$project$Main$SelectLine(line.offset)),
					$elm$html$Html$Events$onDoubleClick(
					$author$project$Main$StartEditComment(line.offset))
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('col-address')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(
							'$' + A2($author$project$Main$toHex, 4, line.address))
						])),
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('col-bytes')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(
							$author$project$Main$formatBytes(line.bytes))
						])),
					A2($author$project$Main$viewDisasm, line, model.labels),
					A2($author$project$Main$viewComment, model, line)
				]));
	});
var $author$project$Main$SaveMajorComment = {$: 'SaveMajorComment'};
var $author$project$Main$UpdateEditMajorComment = function (a) {
	return {$: 'UpdateEditMajorComment', a: a};
};
var $author$project$Main$CancelEditMajorComment = {$: 'CancelEditMajorComment'};
var $author$project$Main$onKeyDownMajorComment = A2(
	$elm$html$Html$Events$stopPropagationOn,
	'keydown',
	A2(
		$elm$json$Json$Decode$map,
		function (_v0) {
			var key = _v0.a;
			var shift = _v0.b;
			return ((key === 'Enter') && (!shift)) ? _Utils_Tuple2($author$project$Main$SaveMajorComment, true) : (((key === 'Enter') && shift) ? _Utils_Tuple2($author$project$Main$NoOp, false) : ((key === 'Escape') ? _Utils_Tuple2($author$project$Main$CancelEditMajorComment, true) : _Utils_Tuple2($author$project$Main$NoOp, false)));
		},
		A3(
			$elm$json$Json$Decode$map2,
			$elm$core$Tuple$pair,
			A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string),
			A2($elm$json$Json$Decode$field, 'shiftKey', $elm$json$Json$Decode$bool))));
var $elm$html$Html$Attributes$rows = function (n) {
	return A2(
		_VirtualDom_attribute,
		'rows',
		$elm$core$String$fromInt(n));
};
var $elm$html$Html$textarea = _VirtualDom_node('textarea');
var $author$project$Main$viewMajorCommentEditing = F2(
	function (currentText, line) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('line major-comment-line editing')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$textarea,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$value(currentText),
							$elm$html$Html$Events$onInput($author$project$Main$UpdateEditMajorComment),
							$elm$html$Html$Events$onBlur($author$project$Main$SaveMajorComment),
							$author$project$Main$onKeyDownMajorComment,
							$elm$html$Html$Attributes$id('major-comment-input'),
							$elm$html$Html$Attributes$autofocus(true),
							$elm$html$Html$Attributes$placeholder('Major comment (first word = segment name)'),
							$elm$html$Html$Attributes$class('major-comment-input'),
							$elm$html$Html$Attributes$rows(3)
						]),
					_List_Nil)
				]));
	});
var $author$project$Main$viewMajorCommentLine = F2(
	function (commentText, line) {
		var commentLines = $elm$core$String$lines(commentText);
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('line major-comment-line'),
					$elm$html$Html$Events$onClick(
					$author$project$Main$SelectLine(line.offset))
				]),
			A2(
				$elm$core$List$map,
				function (l) {
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('major-comment-text')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(';; ' + l)
							]));
				},
				commentLines));
	});
var $author$project$Main$viewLineWithLabel = F2(
	function (model, line) {
		var majorCommentLines = function () {
			var _v6 = model.editingMajorComment;
			if (_v6.$ === 'Just') {
				var _v7 = _v6.a;
				var editOffset = _v7.a;
				var editText = _v7.b;
				if (_Utils_eq(editOffset, line.offset)) {
					return _List_fromArray(
						[
							A2($author$project$Main$viewMajorCommentEditing, editText, line)
						]);
				} else {
					var _v8 = line.majorComment;
					if (_v8.$ === 'Just') {
						var mc = _v8.a;
						return _List_fromArray(
							[
								A2($author$project$Main$viewMajorCommentLine, mc, line)
							]);
					} else {
						return _List_Nil;
					}
				}
			} else {
				var _v9 = line.majorComment;
				if (_v9.$ === 'Just') {
					var mc = _v9.a;
					return _List_fromArray(
						[
							A2($author$project$Main$viewMajorCommentLine, mc, line)
						]);
				} else {
					return _List_Nil;
				}
			}
		}();
		var labelLines = function () {
			var _v0 = _Utils_Tuple2(line.label, model.editingLabel);
			if (_v0.b.$ === 'Just') {
				var _v1 = _v0.b.a;
				var editAddr = _v1.a;
				var editText = _v1.b;
				if (_Utils_eq(editAddr, line.address)) {
					return _List_fromArray(
						[
							A2($author$project$Main$viewLabelLineEditing, editText, line)
						]);
				} else {
					var _v2 = line.label;
					if (_v2.$ === 'Just') {
						var labelText = _v2.a;
						return _List_fromArray(
							[
								A2($author$project$Main$viewLabelLine, labelText, line)
							]);
					} else {
						return _List_Nil;
					}
				}
			} else {
				if (_v0.a.$ === 'Just') {
					var labelText = _v0.a.a;
					var _v3 = _v0.b;
					return _List_fromArray(
						[
							A2($author$project$Main$viewLabelLine, labelText, line)
						]);
				} else {
					var _v4 = _v0.a;
					var _v5 = _v0.b;
					return _List_Nil;
				}
			}
		}();
		return _Utils_ap(
			majorCommentLines,
			_Utils_ap(
				labelLines,
				_List_fromArray(
					[
						A2($author$project$Main$viewLine, model, line)
					])));
	});
var $author$project$Main$viewDisassembly = function (model) {
	var lines = A9($author$project$Disassembler$disassembleRange, model.loadAddress, model.viewStart, model.viewLines, model.bytes, model.comments, model.labels, model.regions, model.segments, model.majorComments);
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('disassembly'),
				$author$project$Main$onWheel($author$project$Main$Scroll)
			]),
		_List_fromArray(
			[
				$author$project$Main$viewDisassemblyHeader,
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('lines'),
						$elm$html$Html$Attributes$id('lines-container')
					]),
				A2(
					$elm$core$List$concatMap,
					$author$project$Main$viewLineWithLabel(model),
					lines))
			]));
};
var $author$project$Main$RequestFile = {$: 'RequestFile'};
var $elm$html$Html$button = _VirtualDom_node('button');
var $elm$html$Html$h1 = _VirtualDom_node('h1');
var $elm$html$Html$p = _VirtualDom_node('p');
var $author$project$Main$viewFilePrompt = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			$elm$html$Html$Attributes$class('cdis-app file-prompt')
		]),
	_List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('prompt-content')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$h1,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('CDis')
						])),
					A2(
					$elm$html$Html$p,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('C64 Disassembler')
						])),
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('load-button'),
							$elm$html$Html$Events$onClick($author$project$Main$RequestFile)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Open PRG File')
						]))
				]))
		]));
var $elm$html$Html$footer = _VirtualDom_node('footer');
var $elm$core$List$intersperse = F2(
	function (sep, xs) {
		if (!xs.b) {
			return _List_Nil;
		} else {
			var hd = xs.a;
			var tl = xs.b;
			var step = F2(
				function (x, rest) {
					return A2(
						$elm$core$List$cons,
						sep,
						A2($elm$core$List$cons, x, rest));
				});
			var spersed = A3($elm$core$List$foldr, step, _List_Nil, tl);
			return A2($elm$core$List$cons, hd, spersed);
		}
	});
var $author$project$Main$viewFooter = function (model) {
	if (model.confirmQuit) {
		return A2(
			$elm$html$Html$footer,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('cdis-footer quit-confirm')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('quit-warning')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Unsaved changes! ')
						])),
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('quit-prompt')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Press Q to quit, any other key to cancel')
						]))
				]));
	} else {
		if (model.gotoMode) {
			var hint = model.gotoError ? A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('goto-error-msg')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('  Address out of range!')
					])) : A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('goto-hint')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('  (Enter to jump, Esc to cancel)')
					]));
			var footerClass = model.gotoError ? 'cdis-footer goto-mode goto-error' : 'cdis-footer goto-mode';
			return A2(
				$elm$html$Html$footer,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class(footerClass)
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('goto-prompt')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('GOTO: $')
							])),
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('goto-input')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(model.gotoInput)
							])),
						A2(
						$elm$html$Html$span,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('goto-cursor')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('_')
							])),
						hint
					]));
		} else {
			if (model.outlineMode) {
				var separator = A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('outline-sep')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(' | ')
						]));
				var segmentItems = A2(
					$elm$core$List$indexedMap,
					F2(
						function (idx, seg) {
							var segName = A2($author$project$Main$getSegmentName, model, seg);
							var isSelected = _Utils_eq(idx, model.outlineSelection);
							var itemClass = isSelected ? 'outline-item selected' : 'outline-item';
							return A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class(itemClass)
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(segName)
									]));
						}),
					model.segments);
				var segmentCount = $elm$core$List$length(model.segments);
				var itemsWithSeparators = A2($elm$core$List$intersperse, separator, segmentItems);
				return A2(
					$elm$html$Html$footer,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('cdis-footer outline-mode')
						]),
					_Utils_ap(
						_List_fromArray(
							[
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('outline-label')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('OUTLINE: ')
									]))
							]),
						_Utils_ap(
							itemsWithSeparators,
							_List_fromArray(
								[
									A2(
									$elm$html$Html$span,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('outline-hint')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('  (←→ navigate, Enter select, Esc cancel)')
										]))
								]))));
			} else {
				if (model.helpExpanded) {
					return A2(
						$elm$html$Html$footer,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cdis-footer expanded')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('help-grid')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('help-section')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-title')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Navigation')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('↑ / ↓')
															])),
														$elm$html$Html$text('Prev/Next line')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('PgUp / PgDn')
															])),
														$elm$html$Html$text('Page up/down')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('G')
															])),
														$elm$html$Html$text('Go to address')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('J / Shift+J')
															])),
														$elm$html$Html$text('Jump to address / back')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('O')
															])),
														$elm$html$Html$text('Outline (segment picker)')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Ctrl+L')
															])),
														$elm$html$Html$text('Center selected line')
													]))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('help-section')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-title')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Editing')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Click')
															])),
														$elm$html$Html$text('Select line')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(';')
															])),
														$elm$html$Html$text('Edit comment')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(':')
															])),
														$elm$html$Html$text('Edit label')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('\"')
															])),
														$elm$html$Html$text('Edit major comment')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Enter')
															])),
														$elm$html$Html$text('Save (Ctrl+Enter for major)')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Escape')
															])),
														$elm$html$Html$text('Cancel / Clear mark')
													]))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('help-section')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-title')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Regions & Segments')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Ctrl+Space')
															])),
														$elm$html$Html$text('Set/Clear mark')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('B / Shift+B')
															])),
														$elm$html$Html$text('Mark/Clear bytes')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('T / Shift+T')
															])),
														$elm$html$Html$text('Mark/Clear text')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('S / Shift+S')
															])),
														$elm$html$Html$text('Mark/Clear segment')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('R')
															])),
														$elm$html$Html$text('Restart (peel byte)')
													]))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('help-section')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-title')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('File')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Shift+S')
															])),
														$elm$html$Html$text('Save project')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('A')
															])),
														$elm$html$Html$text('Export as .asm')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$span,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('key')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('?')
															])),
														$elm$html$Html$text('Toggle this help')
													]))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('help-section')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-title')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Credits')
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('help-row')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('PETSCII font: Pet Me 64 by Kreative Software')
													]))
											]))
									]))
							]));
				} else {
					return A2(
						$elm$html$Html$footer,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('cdis-footer')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$span,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('?: Help | '),
										$elm$html$Html$text('↑↓: Navigate | '),
										$elm$html$Html$text('G: Goto | '),
										$elm$html$Html$text('J: Jump | '),
										$elm$html$Html$text('O: Outline | '),
										$elm$html$Html$text(';/:/\": Comments | '),
										$elm$html$Html$text('B/T/S: Regions | '),
										$elm$html$Html$text('Shift+S: Save | '),
										$elm$html$Html$text('A: Asm')
									]))
							]));
				}
			}
		}
	}
};
var $elm$html$Html$header = _VirtualDom_node('header');
var $author$project$Main$viewHeader = function (model) {
	var dirtyIndicator = model.dirty ? ' *' : '';
	return A2(
		$elm$html$Html$header,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('cdis-header')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$h1,
				_List_Nil,
				_List_fromArray(
					[
						$elm$html$Html$text('CDis')
					])),
				A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('subtitle')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('C64 Disassembler')
					])),
				$elm$core$String$isEmpty(model.fileName) ? $elm$html$Html$text('') : A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('filename')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text(' - ' + (model.fileName + dirtyIndicator))
					]))
			]));
};
var $author$project$Main$viewToolbar = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('toolbar')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$span,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('info')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text(
						'Load: $' + A2($author$project$Main$toHex, 4, model.loadAddress)),
						$elm$html$Html$text(
						' | Size: ' + ($elm$core$String$fromInt(
							$elm$core$Array$length(model.bytes)) + ' bytes'))
					]))
			]));
};
var $author$project$Main$view = function (model) {
	return $elm$core$Array$isEmpty(model.bytes) ? $author$project$Main$viewFilePrompt : A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('cdis-app'),
				$elm$html$Html$Attributes$tabindex(0),
				$elm$html$Html$Attributes$id('cdis-main'),
				$author$project$Main$onKeyDownPreventDefault
			]),
		_List_fromArray(
			[
				$author$project$Main$viewHeader(model),
				$author$project$Main$viewToolbar(model),
				$author$project$Main$viewDisassembly(model),
				$author$project$Main$viewCheatsheet(model),
				$author$project$Main$viewFooter(model)
			]));
};
var $author$project$Main$main = $elm$browser$Browser$element(
	{init: $author$project$Main$init, subscriptions: $author$project$Main$subscriptions, update: $author$project$Main$update, view: $author$project$Main$view});
_Platform_export({'Main':{'init':$author$project$Main$main(
	$elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});}(this));