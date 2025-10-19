@tool
extends Node
func _ready() -> void:
	_test()

#brute force test all possibilities of length-n string
func _test() -> void:
	var highlighter := RegexSyntaxHighlighter.new()
	for i in 128:
		for j in 128:
			for k in 128:
				var text = char(i) + char(j) + char(k)
				highlighter.set_text(text)
				var re := RegEx.create_from_string(text, false)
				var err_found := false
				highlighter.highlight()
				for a in highlighter._result:
					if highlighter._result[a]["color"] == Color.RED:
						err_found = true
				if re.is_valid() and err_found:
					printt(i, j, k, "False Error")
				if not re.is_valid() and not err_found:
					printt(i, j, k, "Fail To Catch")
		$ProgressBar.value += 100.0 / 128.0
		await get_tree().process_frame
	$ProgressBar.value = 100.0


r'''
91	94	93	Fail To Catch [^]
92	49	56	False Error \18 
92	49	57	False Error \19
92	50	56	False Error \28
92	50	57	False Error
92	51	56	False Error
92	51	57	False Error
92	52	56	False Error
92	52	57	False Error
92	53	56	False Error
92	53	57	False Error
92	54	56	False Error
92	54	57	False Error
92	55	56	False Error
92	55	57	False Error
92	69	42	Fail To Catch
92	69	43	Fail To Catch
92	69	63	Fail To Catch
92	75	42	Fail To Catch
92	75	43	Fail To Catch
92	75	63	Fail To Catch
92	78	123	Fail To Catch
92	99	30	Fail To Catch
92	99	31	Fail To Catch
92	103	48	Fail To Catch
92	103	58	Fail To Catch
'''
