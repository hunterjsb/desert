extends Node

# Global debug manager singleton
# Handles F3 debug toggles and dev mode state

signal debug_display_toggled(enabled: bool)
signal dev_mode_changed(enabled: bool)

var debug_displays_enabled: bool = false
var dev_mode_enabled: bool = false

func _ready() -> void:
	# Set process mode to always so it works even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("DebugManager: Ready - F3 to toggle dev mode")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3:
			toggle_dev_mode()

func toggle_dev_mode() -> void:
	dev_mode_enabled = not dev_mode_enabled
	dev_mode_changed.emit(dev_mode_enabled)
	
	# Dev mode automatically controls debug displays
	debug_displays_enabled = dev_mode_enabled
	debug_display_toggled.emit(debug_displays_enabled)
	
	print("DebugManager: Dev mode ", "enabled" if dev_mode_enabled else "disabled")

func is_debug_enabled() -> bool:
	return debug_displays_enabled

func set_dev_mode(enabled: bool) -> void:
	dev_mode_enabled = enabled
	dev_mode_changed.emit(enabled)
	
	# Auto-enable debug displays when dev mode is on
	if enabled and not debug_displays_enabled:
		debug_displays_enabled = true
		debug_display_toggled.emit(true)

func is_dev_mode() -> bool:
	return dev_mode_enabled