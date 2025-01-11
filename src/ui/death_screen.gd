extends Control

func _input(event):
	if event.is_action_pressed("esc"):
		queue_free()
