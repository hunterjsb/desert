extends Control

signal game_unpaused

@export var player: Node3D

@onready var sensitivity_slider = $SensitivitySlider

func _ready():
	# Dynamically locate the player node in the scene tree
	if player and sensitivity_slider:
		sensitivity_slider.value = player.mouse_sensitivity
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)


func _input(event):
	if event.is_action_pressed("esc"):
		toggle_menu()
		player.can_move = not player.can_move
		Input.mouse_mode = (
			Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
			else Input.MOUSE_MODE_VISIBLE
		)

func _on_sensitivity_changed(value):
	if player:
		player.mouse_sensitivity = value

func toggle_menu():
	if is_visible():
		hide()
		game_unpaused.emit()
	else:
		show()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_menu_button_pressed():
	pass
	# toggle_menu()
