extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so WASD sits in the same spot on any keyboard layout.

const KEYS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"toggle_dev_overlay": KEY_F3,
	"dev_fly": KEY_F4,
}


func _enter_tree() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)
