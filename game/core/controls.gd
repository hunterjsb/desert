extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so WASD sits in the same spot on any keyboard layout.

## What F1 lists, before whatever the scene adds.
const HELP := [
	["click", "look, or throw what you hold"], ["WASD", "move"], ["Shift", "sprint"],
	["E", "pick up, take out, put in"], ["F", "use what you look at or hold: drive a stake, waist a line"],
	["G", "drop; empty-handed, let go of your waist"], ["Esc", "free the mouse"],
	["F1", "these keys"], ["F2", "scenarios"], ["F3", "numbers"],
	["F4", "fly: Space up, Ctrl down"], ["F5", "speed up time"], ["F6", "low gravity"],
	["Space", "jump"], ["Ctrl", "crouch; at a run or downhill, slide"],
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
	"jump": KEY_SPACE,
	"crouch": KEY_CTRL,
	"dev_time_warp": KEY_F5,
	"dev_gravity": KEY_F6,
	"hands_grab": KEY_E,
	"hands_drop": KEY_G,
	"interact": KEY_F,
}

## Mouse buttons, the same way.
const BUTTONS := {
	"hands_throw": MOUSE_BUTTON_LEFT,
}


func _enter_tree() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)
	for action: String in BUTTONS:
		if InputMap.has_action(action):
			continue
		var click := InputEventMouseButton.new()
		click.button_index = BUTTONS[action]
		InputMap.add_action(action)
		InputMap.action_add_event(action, click)
