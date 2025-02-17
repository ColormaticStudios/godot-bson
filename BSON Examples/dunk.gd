extends Control


# These are set in dunk.tscn in the root node properties.
@export var JSONEditor: CodeEdit
@export var OutputLabel: Label
@export var CopyPopup: PopupPanel


func _on_button_pressed() -> void:
	var n_json = JSON.parse_string(JSONEditor.text) # Could be Dictionary or null
	if !n_json: return # JSON parse failed
	
	var b_json := BSON.to_bson(n_json)
	var d_json := BSON.from_bson(b_json)
	
	OutputLabel.text = ("SERIALIZED BSON:\n"
		+ str(b_json)
		+ "\nDESERIALIZED JSON:\n"
		+ str(d_json))

func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(OutputLabel.text)
	CopyPopup.show()
	
	var timer := Timer.new()
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = 1.5
	add_child(timer)
	
	await timer.timeout
	timer.queue_free()
	CopyPopup.hide()
