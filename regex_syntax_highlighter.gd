class_name RegexSyntaxHighlighter
extends SyntaxHighlighter
# a regex based on PCRE2 standard.(The one godot used)
# only implement basic rules

# These lines must be put before declaration of grammar tree because the order members are instantiated
## The color of normal characters
@export var normal_color: Color = Color.WHITE
## The color of escape characters
@export var escape_color: Color = Color.TURQUOISE
## The color of a character class that is declared by a bracket
@export var char_class_color: Color = Color.LIGHT_SALMON
## The color of errors
@export var error_color: Color = Color.RED
## The color of quantifiers
@export var quantifier_color: Color = Color.CORNFLOWER_BLUE
## The color of anchors
@export var anchor_color: Color = Color.GOLD
## The color of comments
@export var comment_color: Color = Color.LIGHT_STEEL_BLUE
## The color of groups
@export var group_color: Color = Color.GREEN_YELLOW
## The color of back reference
@export var back_ref_color: Color = Color.DARK_SEA_GREEN
## The color of sub routine
@export var sub_routine_color: Color = Color.WEB_GREEN
## The color of verbs
@export var verb_color: Color = Color.MEDIUM_PURPLE


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	_text = get_text_edit().get_line(line)
	set_text(_text)
	highlight()
	return _result


#analyze and highlight the regex
func highlight():
	check_multiple_tokens(Verb.start)

	while true:
		var c := _read()
		if c == "":  # meet the end
			set_color(normal_color)
			if is_char_class_mode():  # unfinished square bracket
				_open_parentheses.append(_char_class_start)  # all opening brackets (now including round and square ones)

			for position in _open_parentheses:  # handle the unfinished brackets
				_token_start = position
				set_color(error_color, 0)

			for position in _group_idx_refs:
				var back_ref_info := _group_idx_refs[position]
				var back_ref_string: String = back_ref_info[0].get_string("index")
				if not back_ref_string:
					continue
				var signed := back_ref_string[0] in "+-"
				var group_idx: int = int(back_ref_string) + (back_ref_info[1] if signed else 0)
				if (signed and int(back_ref_string) == 0) or (group_idx > _closed_parentheses or group_idx < 0):
					_token_start = position - back_ref_info[0].get_string().length() + 1
					set_color(escape_color if back_ref_info[-1] else error_color, 0)  # there is no such group

			break

		elif c == "\\":  # escape
			escape()

		elif not is_char_class_mode():
			if c in "+*?{":  # May be a quantifier!
				var quantified := check_rules(Quantifier.rule)
				if quantified:
					if quantified in [Quantifier.min_max, Quantifier.less, Quantifier.greater]:
						var left = int(_regex_match.get_string("l"))
						var right = int(_regex_match.get_string("r"))
						if left > right or min(left, right) > 65535:
							# {2,1}			#exceed max range
							_token_start -= _regex_match.get_end()
							set_error()  # wrong range quantifier e.g. a{2,1}
					no_more_quantifier()

			elif c == "#" and _extended_mode:
				check_rule(Comment.extended_rule)

			elif c == "|":
				var color = group_color
				if _open_parentheses:
					if _is_open_parentheses_condition[-1] == 0:
						color = error_color
					if _is_open_parentheses_condition[-1] > 0:
						_is_open_parentheses_condition[-1] -= 1

				mark_current(color)
				no_more_quantifier()

			elif c in "$^":  # Must be a anchor(assertion)!
				mark_current(anchor_color)
				no_more_quantifier()

			elif c == "[":  # char class set begin
				mark_current(char_class_color)
				_char_class_start = _pointer

			elif c == "(":
				if check_rule(Verb.common):
					if _regex_match.get_string() == "(*ACCEPT)":  #accept is the only backtracking verb can be quantified
						continue  # prevent no more quantifier from being called, see below
				elif check_rule(Comment.rule):
					pass
				elif check_rule(Group.internal_setting):
					var regex_match_string = _regex_match.get_string()
					analyze_internal_settings(regex_match_string)

				else:
					_open_parentheses.append(_pointer)
					_is_open_parentheses_condition.append(-1)
					var grouped = check_rules(Group.rule)
					if grouped:
						if grouped == Group.name:
							var group_name = _regex_match.get_string("name")
							if not Group.valid_name.search(group_name):
								_token_start -= group_name.length() + 2
								set_error()
						if grouped in [Group.condition, Group.condition_name]:
							_is_open_parentheses_condition[-1] = 1  # only one | is allowedin condition group
						if grouped in [Group.sub_routine, Group.sub_routine_name, Group.back_ref_name]:
							close_a_parentheses(false)
						if grouped in [Group.sub_routine, Group.condition]:
							_group_idx_refs[_pointer] = [_regex_match, _closed_parentheses + _open_parentheses.size(), false]
						elif grouped == Group.internal_setting:
							var regex_match_string = _regex_match.get_string("setting")
							analyze_internal_settings(regex_match_string)
							set_color(group_color)

				no_more_quantifier()

			elif c == ")":
				if not _open_parentheses:
					mark_current(error_color)
				else:
					# if is not negative, then it is a condition group, which does not count
					close_a_parentheses(_is_open_parentheses_condition[-1] < 0)
					mark_current(group_color)

		elif is_char_class_mode():
			if check_rule(CharClass.posix):
				continue

			elif (_pointer - 1 != _char_class_start) and c == "]":
				mark_current(char_class_color)
				_char_class_start = -1  # terminate char class mode

			elif c == "-":  # a potential range indicator
				var right = _text[_pointer + 1] if _pointer + 1 < _text_length else ""
				if right == "]":
					continue  # a hyphen at the end    -]
				elif _pointer == _char_class_start + 1:
					continue  # a hyphen at the start  [-
				elif not right:  # ahyphrn at the end
					continue
				#what's on the left?
				var left: String
				var left_start: int
				left_start = _pointer - 1  #just the single character adjacent
				left = _text[left_start]

				if _last_escaped_regex_match:
					var last_escaped_start = _pointer - _last_escaped_regex_match.get_end()
					if _text[last_escaped_start] == "\\":  #left is indeed an escaped character
						left = Escape.get_value(_last_escaped_regex_match.get_string())
						left_start = last_escaped_start
				if left_start <= _last_char_class_hyphen + 1:
					continue  # a char_class_hyphen before our left neighbor, meaning it is already a right part of a range

				#what's on the right
				var p = _pointer
				if right == "\\":  # should escape;
					_pointer += 1
					if escape() and _last_escaped_regex_match:  # do the escape; check the escape
						right = Escape.get_value(_last_escaped_regex_match.get_string())
					_pointer -= 1
				else:
					_token_start = p + 1
				# compare left and right char value
				# if the range is in order
				_result.get_or_add(p, {}).color = char_class_color if (left and right and left <= right) else error_color
				_last_char_class_hyphen = _pointer  #. indicating the end of last "range max"


func escape() -> bool:
	if is_char_class_mode() and _pointer + 1 < _text_length and _text[_pointer + 1] in "RXB":
		_pointer += 1
		set_error()  # RXB won't be escaped in char class
		return true
	elif check_rule(Escape.back_ref):
		_group_idx_refs[_pointer] = [_regex_match, _closed_parentheses + _open_parentheses.size(), false]
		var p := _pointer
		_pointer -= _regex_match.get_end() - 1
		if check_rule(Escape.ambiguous):  # a group back reference or a octal digit escape
			_group_idx_refs[p][-1] = true
		_pointer = p
		_token_start = p + 1
		return true
	var escaped := check_rules(Escape.rule)
	if not escaped:
		_pointer += 1
		set_error()  # doesn't match any escape rule
		no_more_quantifier()
	else:
		if escaped == Escape.anchor:
			if is_char_class_mode():
				_token_start -= _regex_match.get_end()
				set_color(error_color if _text[_pointer] != "b" else escape_color)
			else:
				no_more_quantifier()
		elif escaped == Escape.sub_routine:
			_group_idx_refs[_pointer] = [_regex_match, _closed_parentheses + _open_parentheses.size(), false]
		_last_escaped_regex_match = _regex_match
	return escaped != null


var _extended_mode: bool  # pcre2 extended mode
var _pointer: int = -1
var _token_start: int
var _text: String  # current line to be highlighted
var _text_length: int

var _last_escaped_regex_match: RegExMatch

var _regex_match: RegExMatch  # The last regex match we encountered

# char class stuffs
var _char_class_start: int


func is_char_class_mode():
	return _char_class_start != -1


var _last_char_class_hyphen: int

# group stuffs
# all open parentheses
var _open_parentheses: Array[int]
var _is_open_parentheses_condition: Array[int]
# counter of closed parentheses, also the numbers of valid group
var _closed_parentheses: int


# close a parentheses, if cnt set false, won't affect the _closed_parentheses
# useful when manually closing a token that is not a not a group
func close_a_parentheses(cnt := true):
	_closed_parentheses += 1 if cnt else 0
	_open_parentheses.pop_back()
	_is_open_parentheses_condition.pop_back()


# information about group index references, so that we can mark non-existent group error later
# e.g \1 \g+3 \g<1> ,all pointing to a group at give index
# {position: [RegexMatch, parentheses count, if ambiguous]}
# parentheses count : how many left parentheses (open & closed) are there before the ref, used for relative group reference
# if ambiguous: whether the backref can be also interpreted into a hexadecimal digit
var _group_idx_refs: Dictionary[int, Array]


# add a group index reference, by default, it won't be set ambiguous
func add_group_idx_ref() -> void:
	_group_idx_refs[_pointer] = [_regex_match, _closed_parentheses + _open_parentheses.size(), false]


var _result: Dictionary[int, Dictionary]  # the result that will be returned in _get_line_syntax_highlighting
#----------------


# set the _ext, also reset all private states property
func set_text(p_text: String):
	_extended_mode = false
	_pointer = 0
	_token_start = 0
	_text = p_text
	_text_length = p_text.length()
	_last_escaped_regex_match = null
	_regex_match = null
	_char_class_start = -1
	_last_char_class_hyphen = -1
	_open_parentheses.clear()
	_closed_parentheses = 0
	_group_idx_refs.clear()

	_result = {}


# read a character, and move the pointer toward
func _read() -> String:
	_pointer += 1
	return _text[_pointer] if _pointer < _text_length else ""


# check if the token staring exactly from our pointer matches the rule
# return true and automatically dye the token on success
# otherwise returns false
func check_rule(rule: TokenMatcher, color_override := Color()) -> bool:
	set_color(normal_color, 0)
	_regex_match = rule.regex.search(_text.substr(_pointer))
	if _regex_match:
		_pointer += _regex_match.get_end() - 1
		set_color(color_override if color_override else get(rule.color))
		return true
	return false


# check and dye a set of rule in order, returns the rule matched and stop checking the others if one is matched
func check_rules(rules: Array[TokenMatcher], color_override := Color()) -> TokenMatcher:
	for regex_rule in rules:
		if check_rule(regex_rule, color_override):
			return regex_rule
	return null


# check and dye tokens until a token not following the rule is encountered.
# return how many tokens are matched
func check_multiple_tokens(rule: TokenMatcher, color_override := Color()) -> int:
	var cnt = 0
	while check_rule(rule, color_override):
		cnt += 1
		_pointer += 1
		continue
	_pointer -= 1
	return cnt


# analyze an internal option setting and decide what flags to turn on or off
# the setting string may look like x, mx-J, ^
func analyze_internal_settings(setting: String):
	var unset := setting.find("-")  # internal setting after a - will be unset
	var extended := setting.rfind("x")  # find the last occurrence of x (extended)flag
	if _extended_mode:
		if unset != -1 and extended > unset:
			_extended_mode = false
		elif "^" in setting:  # alternatively, use (:^ can also unset settings
			_extended_mode = false
	elif not _extended_mode and (extended != -1 and (unset == -1 or extended < unset)):
		_extended_mode = true


# This function dye all chars between _token_start and _pointer(_pointer.e the current token)
# It also moves the _token_start right after _pointer, which means a offset with value 1
# You can change the offset if you'd like to.
func set_color(color: Color, offset := 1):
	_result.get_or_add(_token_start, {}).color = color
	_token_start = _pointer + offset


# a shorthand
func set_error(offset: int = 1):
	set_color(error_color, offset)


# mark the current char at the pointer
func mark_current(color: Color):
	set_color(normal_color, 0)
	set_color(color)


# immediately call this if you don't want any quantifiers following a token
# has no effect if char_class_mode is on
func no_more_quantifier():
	if is_char_class_mode():
		return
	_pointer += 1
	while check_rules(Quantifier.rule, error_color):
		_pointer += 1  # let's check whether there are duplicating quantifiers in the next char
		continue
	_pointer -= 1  # This char is not duplicating quantifier, we need to go back


class TokenMatcher:
	func _init(p_string: String, p_color: StringName) -> void:
		# ^ make sure the pattern is at the very start of a string (where the _pointer lies)
		regex = RegEx.create_from_string("^" + p_string)
		color = p_color

	var regex: RegEx
	var color: StringName


class Comment:
	static var rule := TokenMatcher.new(r"\(\?#.*?\)", &"comment_color")
	static var extended_rule := TokenMatcher.new(r"#.*\Z", &"comment_color")


# namespace
class Verb:
	static var start := TokenMatcher.new(
		r"\(\*(U(TF|CP)|NO(TEMPTY(_ATSTART)?|_(AUTO_POSSESS|START_OPT|DOTSTAR_ANCHOR|JIT))|CR(LF)?|LF|ANY(CRLF)?|NUL|LIMIT_((DEPTH|HEAP|MATCH)=\d+))\)", &"verb_color"
	)
	static var common := TokenMatcher.new(r"\(\*((ACCEPT|F(AIL)?|SKIP|THEN|COMMIT|PRUNE)(:.*?)?|(MARK)?:.*?)\)", &"verb_color")


# namespace
# though named group, It actually contains every pattern (excluding verbs) beginning with a "("
class Group:
	static var internal_setting = TokenMatcher.new(r"\(\?((?<unset>\^)?([imnsxrJU]|xx|a[DSWPT]?|)*(?('unset')|-?)([imnsxrJU]|xx|a[DSWPT]?|)*)\)", &"verb_color")
	static var valid_name = RegEx.create_from_string(r"^[_A-Za-z][_A-Za-z0-9]{0,127}\z")
	static var name = TokenMatcher.new(r"\(\?(?|P?\<(?<name>.*?)\>|\'(?<name>.*?)\')", &"group_color")  # matches a named group
	static var lookaround = TokenMatcher.new(r"\((\?\<?\*?[=!]|\*(:?(na)?[pn]l[ab]|(non_atomic_)?(posi|nega)tive_look(ahead|behind)\:))", &"group_color")
	static var atomic = TokenMatcher.new(r"\((?:(\?\>|\*atomic\:))", &"group_color")
	static var back_ref_name = TokenMatcher.new(r"\(\?P=([_a-zA-Z][_a-zA-Z0-9]*)\)", &"back_ref_color")
	static var sub_routine = TokenMatcher.new(r"\(\?(?<index>[+-]?\d+)\)", &"sub_routine_color")
	static var sub_routine_name = TokenMatcher.new(r"\(\?((\&|P\>)[_a-zA-Z][_a-zA-Z0-9]*|R)\)", &"sub_routine_color")
	static var scan_sub_str = TokenMatcher.new(
		r"\(\*sc(?:an_substring|s)\:\((?:([+-]?\d|[<'][_A-Za-z][_A-Za-z0-9]{0,127}['>]),)*([+-]?\d|\'[_A-Za-z][_A-Za-z0-9]{0,127}\')\)", &"group_color"
	)
	static var script_run = TokenMatcher.new(r"\(\*((:?atomic_)?script_run|a?sr)\:", &"group_color")
	static var condition = TokenMatcher.new(r"\(\?\((?<index>[R+-]?\d+)\)", "group_color")
	static var condition_name = TokenMatcher.new(
		r"\(\?\((:|R|DEFINE|VERSION>?=\d+\.\d+|assert|R&(?<name>[_a-zA-Z][_a-zA-Z0-9]*)|<(?<name>[_a-zA-Z][_a-zA-Z0-9]*)>|'(?<name>[_a-zA-Z][_a-zA-Z0-9]*)')\)", &"group_color"
	)
	static var normal = TokenMatcher.new(r"\((\?(?<setting>\^|([imnsxrJU]|xx|a[DSWPT]|)*-?([imnsxrJU]|xx|a[DSWPT]|)*)[:|])?", &"group_color")  # matches beginning group (capturing or not)
	# The rules appear first have the higher priority
	static var rule: Array[TokenMatcher] = [
		lookaround,
		name,
		atomic,
		back_ref_name,
		sub_routine,
		sub_routine_name,
		scan_sub_str,
		script_run,
		condition,
		condition_name,
		normal,
	]


# namespace
class CharClass:
	#POSIX notations for character classes
	static var posix = TokenMatcher.new(r"\[:\^?(?:alnum|alpha|ascii|blank|cntrl|digit|graph|lower|print|punct|space|upper|word|xdigit|<|>):\]", &"char_class_color")


# namespace
# though named group, It actually contains every pattern beginning with a "\"
class Escape:
	static var sequence := TokenMatcher.new(r"\\Q.*?(\\E|$)", &"escape_color")  # escape \Q \E sequence quote
	static var chars := TokenMatcher.new(r"\\([aefnrtE]|[[:^alnum:]])", &"escape_color")  # escape character
	static var control_chars := TokenMatcher.new(r"\\c[\x1e-\x7e]", &"escape_color")  # escape character [\x1e-\x7e] is all printing characters
	static var char_class := TokenMatcher.new(r"\\([CNXKR]|(?i)[dsvhw])", &"char_class_color")  # escape character
	static var anchor := TokenMatcher.new(r"\\[bBAzZG]", &"anchor_color")  # escape anchor
	# properties e.g \pL \P{Nd}
	static var property := TokenMatcher.new(
		(
			r"(?i)\\P([CLMNPSZ]|\{\s*(\^)?\s*(C\s*[cfnos]?|L\s*[c&lmotu]?"
			+ r"|M\s*[cem]?|N\s*[dlo]?|P\s*[cdefios]?|S\s*[ck%mo]?|Z\s*[lps]?|"
			+ r"X\s*(a\s*n|p\s*s|s\s*p|u\s*c|w\s*d))\s*\})"
		),
		&"char_class_color"
	)
	static var bidi_property := TokenMatcher.new(
		(
			r"(?i)\\P\{\s*\^?\s*b\s*(c|i\s*-?\s*d\s*i_?\s*c\s*l\s*a\s*s\s*s)\s*[:=]"
			+ r"\s*(a\s*[ln]|b\s*n?|c\s*s|e\s*[nst]|f\s*s\s*i|l(\s*r\s*[eio])?|n\s*s\s*m|o\s*n|p\s*d\s*[fi]|r\s*(l\s*[eio])?|s|w\s*s)\s*\}"
		),
		&"char_class_color"
	)
	static var hex := TokenMatcher.new(r"\\x(?:[[:xdigit:]]{1,2}|\{\s*[[:xdigit:]]{1,8}\s*\})", &"escape_color")
	static var oct := TokenMatcher.new(r"\\(?:0[0-7]{,2}|o\{[0-7]{1,8}\})", &"escape_color")

	static var sub_routine = TokenMatcher.new(r"\\g(:|<(?<index>[+-]?\d+)>|'(?<index>[+-]?\d+)')", &"sub_routine_color")
	static var sub_routine_name = TokenMatcher.new(r"\\g(<(?<name>[_a-zA-Z][_a-zA-Z0-9]*)>|'(?<name>[_a-zA-Z][_a-zA-Z0-9]*)')", &"sub_routine_color")
	static var back_ref = TokenMatcher.new(r"\\(:|g(:|\{\s*(?<index>[+-]?\d+)\s*\}|(?<index>[+-]?\d+))|(?<index>[1-9]\d*))", &"back_ref_color")
	static var back_ref_name = TokenMatcher.new(r"(?(DEFINE)(?<n>[_a-zA-Z][_a-zA-Z0-9]*))\\k<(?&n)>|\\[gk]\{(?&n)\}|\(\?P=(?&n)\)", &"back_ref_color")
	static var ambiguous := TokenMatcher.new(r"\\(?<index>[1-7][0-7]+)", &"back_ref_color")

	# The rules appear first have the higher priority
	static var rule: Array[TokenMatcher] = [
		sequence,
		chars,
		control_chars,
		char_class,
		anchor,
		property,
		bidi_property,
		sub_routine,
		sub_routine_name,
		back_ref_name,
		hex,
		oct,
	]

	# get the _result of an escape pattern in char class
	# \Qqw\E returns qw, \b returns the backspace key and \\ returns "\"
	static func get_value(string: String) -> String:
		match string[1]:
			"Q":
				return string.left(-2 if string.ends_with("\\E") else 0).right(-2)
			"c":
				var ascii := ord(string[2])
				return char(ascii - 64 if ascii >= 64 else ascii + 64)
			"b":
				return char(8)  # backspace in char class
			"x":
				if string[2] == "{":
					return str((string.substr(2).left(-1).right(-1)).hex_to_int())
				return char(string.substr(2).hex_to_int())
			"o" when string[2] == "{":
				return str((string.substr(2).left(-1).right(-1)).hex_to_int())
			"0":
				var a = 0
				for i in string.substr(2):
					a = a << 3  #a *= 8
					a += int(i)
				return char(a)

			var p when p in "pPBAzZGwWhHvVsSdDCNXKR":
				return ""
		return string[1]


class Quantifier:
	static var normal := TokenMatcher.new(r"[+*?][+?]?", &"quantifier_color")
	static var exact := TokenMatcher.new(r"\{\s*\d+\s*\}", &"quantifier_color")
	static var greater := TokenMatcher.new(r"\{\s*(?<l>\d+)\s*,\s*\}[+?]?", &"quantifier_color")
	static var less := TokenMatcher.new(r"\{\s*,\s*(?<r>\d+)\s*\}[+?]?", &"quantifier_color")
	static var min_max := TokenMatcher.new(r"\{\s*(?<l>\d+)\s*,\s*(?<r>\d+)\s*\}[+?]?", &"quantifier_color")
	static var rule: Array[TokenMatcher] = [normal, exact, greater, less, min_max]
