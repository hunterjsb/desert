extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so WASD sits in the same spot on any keyboard layout.

## What F1 lists, before whatever the scene adds.
const HELP := [
	["click", "look"], ["WASD", "move"], ["Shift", "sprint"], ["Esc", "free the mouse"],
	["F1", "these keys"], ["F2", "scenarios"], ["F3", "numbers"],
	["F4", "fly: Space up, Ctrl down"], ["F5", "speed up time"], ["F6", "low gravity"],
]

const KEYS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"toggle_keys": KEY_F1,
	"dev_scenarios": KEY_F2,
	"toggle_dev_overlay": KEY_F3,
	"dev_fly": KEY_F4,
	"fly_up": KEY_SPACE,
	"fly_down": KEY_CTRL,
	"dev_time_warp": KEY_F5,
	"dev_gravity": KEY_F6,
}


func _enter_tree() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)
