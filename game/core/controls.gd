extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so movement sits in the same spot on any keyboard layout.

## What the keys list shows, before whatever the scene adds: each {action}
## is drawn as its key.
const HELP := [
	["{hands_throw}", "throw what you hold"],
	["{hands_rotate}", "held, the mouse turns what you hold or have hold of, not your view: right what's tipped over"],
	["{reel_in} {pay_out}", "a notch at a time, reel in or pay out the line in your hand or at your waist; holding anything else, bring it nearer or push it out"],
	["{move_forward} {move_left} {move_back} {move_right}", "move"], ["{sprint}", "sprint"],
	["{hands_grab}", "pick up, take out, put in, put down"], ["{interact}", "use what you look at or hold: switch a shield, tune a radio, drive a stake, waist a line, water a planter, set its replant share"],
	["{inventory}", "your slots and waist, by mouse: click a slot to take out, put in or swap"], ["{ui_cancel}", "back: close what's open, or the menu"],
	["{toggle_keys}", "these keys"], ["{quick_save}", "quick save"], ["{quick_load}", "quick load: back to your last save"],
	["{jump}", "jump"], ["{crouch}", "crouch; at a run or downhill, slide"],
	["{ride}", "get on or off a hoverboard; riding, the move keys push and carve where they point but {move_back} only brakes, {sprint} kicks off the sand, {jump} hops, {crouch} tucks, and crouched into a hard carve you drift"],
]
## The developer's keys, listed apart under their own heading.
const DEV_HELP := [["{console}", "the console: help lists its commands"], ["{toggle_dev_overlay}", "numbers"]]
## Keys on screen stand out in the theme's key colour.
static var KEY_COLOR: Color:
	get:
		return ThemeDB.get_project_theme().get_color(&"key", &"Palette")
const BUTTON_NAMES := {
	MOUSE_BUTTON_LEFT: "click", MOUSE_BUTTON_RIGHT: "right click", MOUSE_BUTTON_MIDDLE: "middle click",
	MOUSE_BUTTON_WHEEL_UP: "wheel up", MOUSE_BUTTON_WHEEL_DOWN: "wheel down",
}

const KEYS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"sprint": KEY_SHIFT,
	"toggle_keys": KEY_F1,
	"toggle_dev_overlay": KEY_F3,
	"quick_save": KEY_F5,
	"quick_load": KEY_F9,
	"console": KEY_QUOTELEFT,
	"fly_up": KEY_SPACE,
	"fly_down": KEY_C,
	"jump": KEY_SPACE,
	"crouch": KEY_C,
	"hands_grab": KEY_E,
	"interact": KEY_F,
	"inventory": KEY_TAB,
	"ride": KEY_R,
}

## Mouse buttons, the same way.
const BUTTONS := {
	"hands_throw": MOUSE_BUTTON_LEFT,
	"hands_rotate": MOUSE_BUTTON_RIGHT,
	"reel_in": MOUSE_BUTTON_WHEEL_UP,
	"pay_out": MOUSE_BUTTON_WHEEL_DOWN,
}

## A gamepad works the menus too; its D-pad already moves them.
const PADS := {
	"ui_accept": JOY_BUTTON_A,
	"ui_cancel": JOY_BUTTON_B,
}

static var _named := RegEx.create_from_string("\\{(\\w+)\\}")

## Whether the mouse is free to click, rather than captured to look. Kept
## here, since a headless run never captures it.
var mouse_free := true
## The menus' root while the game has one. Probes of a bare world have none.
var ui: UIRoot


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
	for action: String in PADS:
		var pad := InputEventJoypadButton.new()
		pad.button_index = PADS[action]
		InputMap.action_add_event(action, pad)


## Frees the mouse to click, or captures it to look.
func free_mouse(free: bool) -> void:
	mouse_free = free
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if free else Input.MOUSE_MODE_CAPTURED


## Whether what you hold down reaches the game. A menu up, or the screen
## fading, holds it back; the world runs on without you.
func playing() -> bool:
	return ui == null or not ui.holds_input()


## An action held down, as the game hears it.
func held(action: StringName) -> bool:
	return playing() and Input.is_action_pressed(action)


## The key or mouse button bound to an action now, as it's named on screen.
static func key_for(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.physical_keycode != KEY_NONE:
			# Named as the player's own layout labels it.
			return _key_name(key.physical_keycode if DisplayServer.get_name() == "headless"
				else DisplayServer.keyboard_get_label_from_physical(key.physical_keycode))
		if key != null:
			return _key_name(key.keycode)
		var button := event as InputEventMouseButton
		if button != null:
			return BUTTON_NAMES.get(button.button_index, "mouse %d" % button.button_index)
	return "unbound"


## A printable key by its own mark, so the console's key shows as ` and not QuoteLeft.
static func _key_name(code: Key) -> String:
	return char(code) if code > KEY_SPACE and code <= KEY_ASCIITILDE else OS.get_keycode_string(code)


## A key's name, coloured, as BBCode.
static func tint(key: String) -> String:
	return "[color=#%s]%s[/color]" % [KEY_COLOR.to_html(false), key]


## Every key as bound now, one per line, the developer's under their heading, as BBCode.
static func help() -> String:
	var lines := PackedStringArray()
	for pair: Array in HELP:
		lines.append("%s  %s" % [bbcode(pair[0]), bbcode(pair[1])])
	lines.append("DEV")
	for pair: Array in DEV_HELP:
		lines.append("%s  %s" % [bbcode(pair[0]), bbcode(pair[1])])
	return "\n".join(lines)


## Text with each {action} in it as that action's key, coloured, as BBCode.
static func bbcode(text: String) -> String:
	var out := ""
	var from := 0
	for found in _named.search_all(text):
		out += text.substr(from, found.get_start() - from) + tint(key_for(found.get_string(1)))
		from = found.get_end()
	return out + text.substr(from)


## Text for bbcode(), in the theme, sized to what it says, never in the mouse's way.
static func keys_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Draws text on a control, in its theme's text, with each {action} in it as
## that action's key, coloured.
static func draw_keys(on: Control, at: Vector2, text: String) -> void:
	var x := at.x
	var from := 0
	var color := on.get_theme_color(&"text", &"Palette")
	for found in _named.search_all(text):
		x += _draw_run(on, Vector2(x, at.y), text.substr(from, found.get_start() - from), color)
		x += _draw_run(on, Vector2(x, at.y), key_for(found.get_string(1)), KEY_COLOR)
		from = found.get_end()
	_draw_run(on, Vector2(x, at.y), text.substr(from), color)


static func _draw_run(on: Control, at: Vector2, run: String, color: Color) -> float:
	var font := on.get_theme_font(&"font", &"Label")
	var size := on.get_theme_font_size(&"font_size", &"Label")
	on.draw_string_outline(font, at, run, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		on.get_theme_constant(&"outline_size", &"Label"), on.get_theme_color(&"shadow", &"Palette"))
	on.draw_string(font, at, run, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	return font.get_string_size(run, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
