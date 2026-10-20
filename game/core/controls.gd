extends Node
## Every input binding, registered in code so they live in one readable place.
## Physical keys, so movement sits in the same spot on any keyboard layout.

## What the keys list shows, in groups, before whatever the scene adds: each
## {action} drawn as its key, and what it does in a word or two. The rest is
## learned where it's needed (UIRoot.teach) or by doing.
const HELP := [
	["MOVING", [["{move_forward}{move_left}{move_back}{move_right}", "move"], ["{sprint}", "sprint"],
		["{auto_walk}", "auto-walk"], ["{jump}", "jump"], ["{crouch}", "crouch, slide"],
		["{ride}", "board on or off, up from the helm"]]],
	["HANDS", [["{hands_grab}", "take, put down"], ["{interact}", "use"], ["{hands_throw}", "throw"],
		["{hands_rotate}", "turn what you hold"], ["{bring_near} / {push_out}", "nearer, further"],
		["{reel_in} / {pay_out}", "reel in, pay out; tune a radio"],
		["{tune_fine_up} / {tune_fine_down}", "fine tune"], ["{volume_up} / {volume_down}", "radio volume"],
		["{mark_frequency}", "mark or unmark a radio's frequency; then {interact} goes to the next"]]],
	["YOU", [["{inventory}", "what you carry"], ["{headlamp}", "headlamp"]]],
	["GAME", [["{ui_cancel}", "back, menu"], ["{quick_save}", "quick save"], ["{quick_load}", "quick load"],
		["{toggle_keys}", "these keys"], ["{fullscreen}", "fullscreen"]]],
]
## The developer's keys, listed apart under their own heading.
const DEV_HELP := [["{console}", "console"], ["{toggle_dev_overlay}", "numbers"]]
## Riding takes more than its key says, so it's taught the first time you ride.
const RIDE_HOW_TO := "ride"
const RIDE_HOW_TO_SAYS := "The move keys push and carve where they point; {move_back} digs an edge in, to bite into a carve" \
	+ " or, alone, to stop.\n" \
	+ "{sprint} kicks off the sand, {jump} hops, {crouch} tucks; crouched into a hard carve, you drift."
## A heading in the keys list sits back in the theme's dim text.
static var DIM: Color:
	get:
		return ThemeDB.get_project_theme().get_color(&"dim", &"Palette")
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
	# Beside forward: turned on or off without leaving the move keys.
	"auto_walk": KEY_Q,
	"sprint": KEY_SHIFT,
	"toggle_keys": KEY_F1,
	"fullscreen": KEY_F11,
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
	"headlamp": KEY_B,
	# A radio in your hands: mark where its dial stands.
	"mark_frequency": KEY_M,
}

## Mouse buttons, the same way.
const BUTTONS := {
	"hands_throw": MOUSE_BUTTON_LEFT,
	"hands_rotate": MOUSE_BUTTON_RIGHT,
	"reel_in": MOUSE_BUTTON_WHEEL_UP,
	"pay_out": MOUSE_BUTTON_WHEEL_DOWN,
}
## Mouse buttons with ctrl held: what you hold has the wheel apart from the
## lines, which have it bare since reeling matters more (sails, the waist).
## The bare wheel tunes a radio you look at; shift steps it finely, alt turns
## its volume.
const CTRL_BUTTONS := {
	"bring_near": MOUSE_BUTTON_WHEEL_UP,
	"push_out": MOUSE_BUTTON_WHEEL_DOWN,
}
const SHIFT_BUTTONS := {
	"tune_fine_up": MOUSE_BUTTON_WHEEL_UP,
	"tune_fine_down": MOUSE_BUTTON_WHEEL_DOWN,
}
const ALT_BUTTONS := {
	"volume_up": MOUSE_BUTTON_WHEEL_UP,
	"volume_down": MOUSE_BUTTON_WHEEL_DOWN,
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
	for action: String in BUTTONS.merged(CTRL_BUTTONS).merged(SHIFT_BUTTONS).merged(ALT_BUTTONS):
		if InputMap.has_action(action):
			continue
		var click := InputEventMouseButton.new()
		click.button_index = BUTTONS.get(action, CTRL_BUTTONS.get(action, SHIFT_BUTTONS.get(action,
			ALT_BUTTONS.get(action))))
		click.ctrl_pressed = CTRL_BUTTONS.has(action)
		click.shift_pressed = SHIFT_BUTTONS.has(action)
		click.alt_pressed = ALT_BUTTONS.has(action)
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
			return ("ctrl + " if button.ctrl_pressed else "") + ("shift + " if button.shift_pressed else "") \
				+ ("alt + " if button.alt_pressed else "") + BUTTON_NAMES.get(button.button_index, "mouse %d" % button.button_index)
	return "unbound"


## A printable key by its own mark, so the console's key shows as ` and not QuoteLeft.
static func _key_name(code: Key) -> String:
	return char(code) if code > KEY_SPACE and code <= KEY_ASCIITILDE else OS.get_keycode_string(code)


## A key's name, coloured, as BBCode.
static func tint(key: String) -> String:
	return "[color=#%s]%s[/color]" % [KEY_COLOR.to_html(false), key]


## Every key as bound now, a table of key and what it does under each
## group's heading, the developer's last, as BBCode.
static func help(extra: Array = []) -> String:
	var groups := HELP + [["DEV", DEV_HELP]]
	if not extra.is_empty():
		groups.append(["HERE", extra])
	var cells := PackedStringArray()
	for group: Array in groups:
		cells.append("[cell][color=#%s]%s[/color][/cell][cell][/cell]" % [DIM.to_html(), group[0]])
		for pair: Array in group[1]:
			cells.append("[cell][right]%s[/right][/cell][cell]%s[/cell]" % [bbcode(pair[0]), bbcode(pair[1])])
	return "[table=2]%s[/table]" % "".join(cells)



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
