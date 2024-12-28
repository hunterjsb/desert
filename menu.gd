extends CanvasLayer

signal game_unpaused

@onready var sensitivity_slider = $SensitivitySlider
var player_ref: Node = null

func _ready():
	player_ref = get_tree().root.get_node("main/Player")
	
	if sensitivity_slider:
		sensitivity_slider.value = player_ref.mouse_sensitivity
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

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
	print("button pressed :)")
	# toggle_menu()
