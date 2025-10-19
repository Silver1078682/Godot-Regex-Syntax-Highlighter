extends MenuButton

@export var regex: TextEdit
func _ready() -> void:
	get_popup().clear()
	for i in list.size():
		get_popup().add_item((list[i]).capitalize(), i)
	get_popup().id_pressed.connect(_update)
	var f = FileAccess.open("res://known_issues.txt", FileAccess.READ)
	known_issues = f.get_as_text() if f else ""
	f.close()

func _update(p_id):
	regex.text = get(list[p_id])
	if p_id == 0:
		pass

var list: Array[String] = [
	"known_issues",
	"basic_feature",
	"an_example",
	"hello_regex",
	"nested_parentheses",
	"rainbow",
	"verb",
	"escape",
	"hex_oct",
	"sequence",
	"quantifier",
	"anchor",
	"char_class",
	"internal_setting",
	"comment",
	"group",
	"lookaround_atomic",
	"backreference",
	"search_substring_scripts_run",
	"sub_routines",
	"condition"
]

var known_issues: String
var basic_feature := \
r"""(*UTF)Basic Stuffs
(?#comments)
^anchors\bhighlighted$ [^\b$^]		(?# anchors)
(apple|banana|lemon)			 	(?# capture group)
(?=lookAhead) (?<!negativeLookBehind)
(.+)([A-Z]) \1\g{2} 				(?# back reference)
(?<groupName>) \k<groupName>		(?# group with name)
\s+?\S* \w{1, 2} cats? 				(?# quantifiers)
\x12 \x{0123} \0 \11 \o{12}			(?# hex and oct digit escape)
\Q(*^_ ^*)\E 						(?# quote a string)
[A-Z.\]-] 							(?# char class)
(?im)internal setting flag(?^x)		# optional settings

(?# email matcher by https://www.linkedin.com/in/peralta-steve-atileon/)
^((?!\.)[\w\-_.]*[^.])(@\w+)(\.\w+(\.\w+)?[^.\W])$
\x (??) [\B] .{2,1} )( \19			(?#errors, delete this line and you will get a valid expression)
"""


var an_example := \
r"""Oh h\i+?? x*+ |? a{1,2}b{2,1} ||(?:a|b)* (?<=(?<name>x))* (?>n)
((((?:((a))b.c)d|x(y){65536,}))))[^1-59-6\b-\cX.a-\w!---] \xFF \x \uFF\uFFFF\z\v\1\\\
(?#example from https://slevithan.github.io/regex-colorizer/demo/)
(?#the example above is for javascript regex, so it's likely that there exist slight differenece)
"""
var hello_regex := \
r"""(?xi) (a \s*)? regex(?(1)|es)? |(a \s*)? regular \s* expression(?(1)|s?)
(?x)  #(?x) starts the pcre extended mode, ignoring the whitespace in regular expression
(?x)  #(?i) makes matching case insensitive"""

var nested_parentheses := r"(?x)  \( ( [^()]++ | (?R) )* \) #matches things wrapped with (nested) parentheses like ((abc))"

var rainbow := r"\x\x\w\w^^^(||)\g<1>\1\1\\\\{1,2}(?)(?#)aaa"

var verb = \
r"""Verbs at begining
(*UTF)(*UCP)(*LIMIT_DEPTH=12)(*LIMIT_HEAP=12)(*LIMIT_MATCH=12)(*NOTEMPTY)(*NOTEMPTY_ATSTART)(*NO_AUTO_POSSESS)(*NO_DOTSTAR_ANCHOR)(*NO_JIT)(*NO_START_OPT)
(*LIMIT_DEPTH=12)
(*LIMIT_HEAP=)
(*LIMIT_MATCH=a)
(*)
Not at start (*LIMIT_DEPTH=12)
(*LIMIT_DEPTH=12)(Error)(*UTF)
Backtracking Control Verbs
(*ACCEPT)(*FAIL)(*MARK)(*COMMIT)(*PRUNE)(*SKIP)(*THEN)
(*ACCEPT:NAME)(*FAIL:NAME)(*MARK:NAME)(*COMMIT:NAME)(*PRUNE:NAME)(*SKIP:NAME)(*THEN:NAME)
(*:NAME)
"""

var escape = \
r"""Normal Escape
Char type escape: \w\W\s\S\N\d\D\C\X\R\K
Char escape: \a\e\f\n\r\t\^\$\.\?\*\(\)\[\]\{\}\\\+\-\|
Anchor escape: \b\B\A\Z\z\G
Reset \K
Property escape: \PC \P{C} \P{Cc} \P{Cf} \P{Co} \P{Cs}	\pC \p{C} \p{Cc} \p{Cf} \p{Co} \p{Cs} \p{^C} \p{Xan}
\p{ 	^	C} \p{X a	n	}
\p{bidiclass=al}
\p{BC=al}
\p{ Bidi_Class : AL }
\p{ Bi-di class = Al }
\P{ ^ Bi-di class = Al }
\p{bc = a n } \p{bc = b } \p{bc = b n } \p{bc = c s } \p{bc = e n }
\p{bc = e s } \p{bc = e t } \p{bc = f s i } \p{bc = l } \p{bc = l r e } \p{bc = l r i }
\p{bc = l r o } \p{bc = n s m }  \p{bc = o n} \p{bc = p d f } \p{bc = p d i}
\p{bc = r } \p{bc = r l  e } \p{bc = r l i}
\p{bc = r l  o}   \p{bc = s } \p{bc = w s }
Controls chars: \ca \cb \cc \cd \c@ \c؜ (<< special char inserted here)
\w\a\q\b 	\ww\aa\qq\bb		\w \a \q \b		\ww \aa \qq \bb
\
\\\
\\\\"""

var hex_oct = \
r"""Hex/Oct Escaping
Line Not Finished:
\x (?# This is not escaped to null in Godot[PCRE2])
\x{
\x{1
\x{12
HEX
\x0\x1\x2\x3\x4\x5\x6\x7\x8\x9\xa\xb\xc\xd\xe\xf\xg\xA\xB\xC\xD\xE\xF\xGs
\x \x1 \x12 \x{1} \x{12} \x1p \x12p \x{12} \x{12w} \x{1w} \x{w} \x{}
\x12 \x123  \x{1234567} \x{12345678} \x{123456789} \x{1234567890}
\x\w \x1\w \x12\w \x{1}\w \x{12}\w \x1p\w \x12p\w \x{12}\w \x{12w}\w \x{1w}\w \x{w}\w \x{}\w
\x\x \x1\x \x12\x \x{\x \x{1\x \x{12\x     \x\x{ \x1\x{ \x12\x{ \x{\x{ \x{1\x{ \x{12\x{
OCT
\o0\o1\o2\o3\o4\o5\o6\o7\o8\o9\oa\ob\oc\od\oe\of\og\oA\oB\oC\oD\oE\oF\oGs
\o \o1 \o12 \o{1} \o{12} \o1p \o12p \o{12} \o{12w} \o{1w} \o{w} \o{}
\o12 \o123  \o{1234567} \o{12345677} \o{12345678} \o{123456789} \o{1234567890}
\o\w \o1\w \o12\w \o{1}\w \o{12}\w \o1p\w \o12p\w \o{12}\w \o{12w}\w \o{1w}\w \o{w}\w \o{}\w
\o\o \o1\o \o12\o \o{\o \o{1\o \o{12\o     \o\o{ \o1\o{ \o12\o{ \o{\o{ \o{1\o{ \o{12\o{
\00\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e\0f\0g\0A\0B\0C\0D\0E\0F\0Gs
\0 \01 \012 \0{1} \0{12} \01p \012p \0{12} \0{12w} \0{1w} \0{w} \0{}
\1 \2 \3 \4 \5 \6 \7 \8 \9 \11 \22 \33 \44 \55 \66 \77 \88
\0\w \01\w \012\w \0{1}\w \0{12}\w \01p\w \012p\w \0{12}\w \0{12w}\w \0{1w}\w \0{w}\w \0{}\w
\0\0 \01\0 \012\0 \0{\0 \0{1\0 \0{12\0     \0\0{ \01\0{ \012\0{ \0{\0{ \0{1\0{ \0{12\0{
"""

var sequence = \
r"""Sequence Quote
\Q
\Q\E\Qa\E\Q\w\E\Q\c\E\Q\E
\Q\a\b\c\d\e
\Q\Q
\Q\\E (?# matches \ in PCRE2)
\E\E
\Q[ --- ]\E
\Q(?# comment)\E
\Q(?# \E comment)
prefix \Q \E suffix
"""

var quantifier = \
r"""Quantifiers
a+
a+ a+ a+
a+ a* a?
a+ a+* a+?   a* a** a*?   a? a?* a??
a+++ a++* a++? a+*+ a+** a+*? a+?+ a+?* a+?? a*++ a*+* a*+? a**+ a*** a**? a*?+ a*?* a*?? a?++ a?+* a?+? a?*+ a?** a?*? a??+ a??* a???
a++++ a+++++ a???? a????? a**** a***** a+*?+*?+*?
a+ \w+ \a+ \ca+ \b+ \x+ \x12+ \x123+ \x{123}+ \x{!}+ \Qq\E+ [123]+
a+\w+\a+\ca+\b+\x+\x12+\x123+\x{123}+\x{!}+\Qq\E+[123]+
a+++\w+++\a+++\ca+++\b+++\x+++\x12+++\x123+++\x{123}+++\x{!}+++\Qq\E+[123]+++
a{1} a{1,} a{,2} a{1,2} a{2,1} a{1,1}
"""

var anchor = \
r"""Anchors
^$\b\B\A\Z\z\G
^+ $+ \b+ \B+ \A+ \Z+ \z+ \G+
prefix ^ suffix
"""
var char_class = \
r"""Char class
[ ] [[ ] [ ]]
[] [[] []]
[\]]
[.?*{,}]
[\B\X\R]
[\b+^+]
[!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?qwertyuiopasdfghkl;'zxcvbnm,/]
[-][--][---][----]
[-----][------]
[\c-][\cA-][\c---][\c----][\c-----][\c+-\c-----]
[1-2]+ [1-] [-1] []
[2-1] [5-0] [\P{Xan}] 
[\x1-\x2\x{1}-\x{2}\00-\01\o{1}-\o{2}]
[\x2-\x1\x{2}-\x{1}\01-\00\o{2}-\o{1}]
[ \Q \E ] [ \Q ] \E
[[:alpha:]]  [\[:alpha:]]  [:alpha:]  [[:<:]]
[
prefix [ suffix
"""

var internal_setting = \
r"""Internal Setting
(?i) (?m) (?imnsxx) (?imnsxxx)
(?) (?^) (?-)
(?i) (?^i) (?-i) (?i) (?i^) (?i-) (?i) (?i^i) (?i-i) 
(?imnsxx) (?^imnsxx) (?-imnsxx) (?imnsxx) (?imnsxx^) (?imnsxx-) (?imnsxx) (?imnsxx^imnsxx) (?imnsxx-imnsxx) 
(?impossible) (?xxxxxxxxxx)
(?^-)(?-^)
(?aDaTUim)
prefix (?i) suffix
"""

var comment = \
r"""Comment
(?#) (?#
prefix (?#) suffix
(?x) # pcre extended mode set
(?-x) # pcre extended mode unset
(?x) [# set ](?-x) # unset
(?^) # unset
(?x) \Q# set \E  (?^) # unset
(?^) # unset
(?x) (?# set )  (?x-x) # unset
"""

var group = \
r"""Group
()
(a|b|c|)
|||
(()
((((((
))))))(()(
(\))
[(])
prefix ( suffix
prefix (internal) suffix
(?:) (?:uncapturing group)
prefix (?: suffix
prefix (?:internal) suffix
(?|branch)
(?i:)(?^:)(?im-x:)
prefix (?i:
(?x:#extended flag set true)
(?<named>group) (?P<another>group) (?'stll_another'group)\
(?<1> invalid name)(?P<''> invalid name2)(?'<>'invalid name3)(?P'' invalid name4)
(?<>(?i:i(?|\?\|nested(???(?<group>)?)*)++))
(?<A_Group_Name_That_Is_Longer_Than_128_Chars__Or_More_Accurately__128_Code_Units__is_NOT_Allowed_In_PCRE2_Standard___thus_an_error_is_raised>)
"""

var lookaround_atomic = \
r"""Lookaround & Atomic
(*negative_lookbehind:)(*nlb:)(?<!)
(*positive_lookbehind:)(*plb:)(?<=)
(*positive_lookahead:)(*pla:)(?=)
(*negative_lookahead:)(*nla:)(?!)
(*non_atomic_positive_lookahead:)(*napla:)(?*=)
(*non_atomic_positive_lookbehind:)(*naplb:)(?<*=)
(?>atomic) (*atomic:another way)
(?<=unclosed
"""


var backreference = \
r"""Back Reference
\1 \g{1} \g1
()\1 \g{1} \g1
\1 \g{1} \g1 ()
()\2 \g{2} \g2
(())\2 \g{2} \g2
(\2 \g{2} \g2)()
\1 \2
()\g{0} \g{1}
\g{+1} \g{-1}
()\g<0> \g<1>
\g<+0> \g<-1>
()\g{-1}\g{ +1 }()\g{ -1 }\g{+1}
(?<named>) \k{named} \g{named} \k<named> (?P=named) \1 \2 \g-1 \g-2
(\g-2 \g-1) (\g+1 \g+2)
(((((((((((((())))))))))))))\12 \15
"""

var search_substring_scripts_run = \
r"""Search Sub String & Scripts Run 
(*sr:\S+)
(*scan_substring:(1)...)
(*scs:(-2)...)
(*scs:('AB')...)
(*scs:(1,'AB',-2)...)
"""

var sub_routines = \
r"""SubRoutine
()(?2)
()(?-1)
(?+1)()
(?<n>) (?&n) (?P>n)
\g<-1>()\g<-1>\g<1>\g<+1>()\g<2>
((?R))(?<name>[A-Z][a-z]*)(?R&name)
"""
var condition = \
r"""condition
(?(invalid)|)
(?('qwq')1|2|3|4)
(?(<qwq>)|||)
(?(VERSION>=10.4)yes|no)
(?(1))()
(?(+2))(?(+3))
(())(?(-2))(?(-3))
"""
