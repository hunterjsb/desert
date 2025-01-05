extends CanvasLayer

signal game_unpaused

@onready var sensitivity_slider = $SensitivitySlider
var player_ref: Node = null

func _ready():
	# Dynamically locate the player node in the scene tree
	player_ref = $Player
	
	if player_ref and sensitivity_slider:
		sensitivity_slider.value = player_ref.mouse_sensitivity
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

func find_player() -> Node:
	# Search for the Player node in likely parent paths
	var paths = ["Skybox/Player", "main/Player"]
	for path in paths:
		var node = get_tree().root.get_node_or_null(path)
		if node:
			return node
	return null

func _on_sensitivity_changed(value):
	if player_ref:
		player_ref.mouse_sensitivity = value

func toggle_menu():
	if is_visible():
		hide()
		emit_signal("game_unpaused")
	else:
		show()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_menu_button_pressed():
	pass
	# toggle_menu()
