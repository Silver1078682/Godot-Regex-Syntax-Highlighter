extends Label
@export var regex_edit: CodeEdit
@export var text_edit: TextEdit
@onready var check_box: CheckBox = $"../../HBoxContainer/CheckBox"

var _regex:= RegEx.new()
func _ready() -> void:
	_update()

func _update():
	_regex.compile(regex_edit.text, false)

	if not _regex.is_valid():
		modulate = Color.DIM_GRAY
		text = "NOT VALID"
		
	else:
		modulate = Color.WHITE
		text = ""
		var result := _regex.search_all(text_edit.text)
		for i in result:
			if not i.get_string():
				continue
			else:
				text += i.get_string()
				text += "\n" if check_box.button_pressed else ""
		text += "\b"
