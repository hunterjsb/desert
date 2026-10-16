extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so WASD sits in the same spot on any keyboard layout.

## What F1 lists, before whatever the scene adds.
const HELP := [
	["click", "look, or throw what you hold"], ["WASD", "move"], ["Shift", "sprint"],
	["E", "pick up, take out, put in, put down"], ["F", "use what you look at or hold: switch a shield, drive a stake, waist a line, water a planter, set its replant share"],
	["Tab", "your slots and waist: look across to pick one; take puts in or takes out"], ["Esc", "free the mouse"],
	["F1", "these keys"], ["F2", "scenarios"], ["F3", "numbers"],
	["F4", "fly: Space up, C down"], ["F5", "speed up time"], ["F6", "low gravity"],
	["Space", "jump"], ["C", "crouch; at a run or downhill, slide"],
	["R", "get on or off a hoverboard; riding, move keys push and carve where they point, S against your way brakes, Space hops, C tucks"],
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
	"fly_down": KEY_C,
	"jump": KEY_SPACE,
	"crouch": KEY_C,
	"dev_time_warp": KEY_F5,
	"dev_gravity": KEY_F6,
	"hands_grab": KEY_E,
	"interact": KEY_F,
	"inventory": KEY_TAB,
	"ride": KEY_R,
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
