extends Label
@export var regex_edit: CodeEdit
@export var text_edit: TextEdit
@onready var check_box: CheckBox = $"../../HBoxContainer/CheckBox"

var _regex:= RegEx.new()
func _ready() -> void:
	var test := RegEx.create_from_string(r"(?(DEFINE)(?<one>1))(?&one)")
	_update()

func _update():
	_regex.compile(regex_edit.text, false)
	if not _regex.is_valid():
		text = "NOT VALID"
		return
		
	text = ""
	var result := _regex.search_all(text_edit.text)
	for i in result:
		if not i.get_string():
			continue
		else:
			text += i.get_string()
			text += "\n" if check_box.button_pressed else ""
	text += "\b"
