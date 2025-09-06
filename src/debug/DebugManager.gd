extends Node

# Global debug manager singleton
# Handles F3 debug toggles and provides debug state to other systems

signal debug_display_toggled(enabled: bool)

var debug_displays_enabled: bool = false

func _ready() -> void:
	# Set process mode to always so it works even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("DebugManager: Ready - F3 to toggle debug displays")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			toggle_debug_displays()

func toggle_debug_displays() -> void:
	debug_displays_enabled = not debug_displays_enabled
	debug_display_toggled.emit(debug_displays_enabled)
	print("DebugManager: Debug displays ", "enabled" if debug_displays_enabled else "disabled")

func is_debug_enabled() -> bool:
	return debug_displays_enabled