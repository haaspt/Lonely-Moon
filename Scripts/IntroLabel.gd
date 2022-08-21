extends Panel

signal any_key_pressed


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		emit_signal("any_key_pressed")
