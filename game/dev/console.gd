class_name Console
extends Control
## Dev: a line to type commands into over the running game, with what they
## said above it. The UI root opens and closes it and keeps every key from
## the game while it's up; up and down step through what was typed before,
## and the focus-next key finishes a command's name, a scenario or an id.
## Each command is a thin call into the game's own code.

## Each command's arguments and what it does, in the order help lists them.
const COMMANDS := {
	"help": ["", "these commands"],
	"scenarios": ["", "the scenarios' keys"],
	"scenario": ["<key>", "start one; the run is a dev run from then on, never saved"],
	"fly": ["", "fly through the world, or walk again"],
	"warp": ["[n]", "the clock n times as fast; alone, the next of x1, x10, x60"],
	"gravity": ["[m/s²]", "gravity; alone, low gravity or back"],
	"time": ["<0-1>", "on to the next such moment of your local day: 0 is midnight, 0.5 noon"],
	"tu": ["[6|9|13]", "Tu's width across the sky under trial, degrees; alone, the next"],
	"give": ["<id> [n]", "a part in your hands or a device at your feet, by its catalog id"],
	"fresh": ["", "fed, watered and whole, on a fresh suit's kit"],
}
## Parts that only come on something else: a cable's plugs, a hose's ends, a line's ends.
const ON_SOMETHING := [&"plug", &"strong_plug", &"hose_end", &"rope_end"]
## Lines of output shown, commands remembered, and the most give makes at once.
const SHOWN := 10
const REMEMBERED := 50
const MOST := 20
## Its panel's width and how far down it hangs, px.
const WIDTH := 640.0
const TOP := 24.0

var ui: UIRoot
var _out: RichTextLabel
var _line: LineEdit
var _said := PackedStringArray()
var _typed := PackedStringArray()
## How far back up has gone through what was typed; 0 is a new line.
var _back := 0


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Every click lands here, so none reaches the world to throw or look.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ConsolePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -WIDTH * 0.5
	panel.offset_right = WIDTH * 0.5
	panel.offset_top = TOP
	panel.offset_bottom = TOP
	add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	_out = Controls.keys_label()
	_out.theme_type_variation = &"ConsoleOut"
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_out)
	_line = LineEdit.new()
	_line.theme_type_variation = &"ConsoleLine"
	_line.keep_editing_on_text_submit = true
	_line.context_menu_enabled = false
	_line.emoji_menu_enabled = false
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_line.set_focus_neighbor(side, ^".")
	_line.focus_next = ^"."
	_line.focus_previous = ^"."
	_line.text_submitted.connect(_submit)
	_line.gui_input.connect(_on_line_input)
	_line.focus_exited.connect(_keep_focus, CONNECT_DEFERRED)
	stack.add_child(_line)


func open() -> void:
	visible = true
	_write()
	_line.grab_focus()
	_line.edit()


func close() -> void:
	if not visible:
		return
	visible = false
	_line.unedit()
	_line.clear()
	_line.release_focus()
	_back = 0


## Runs one line as if typed and confirmed.
func run(line: String) -> void:
	var words := line.strip_edges().split(" ", false)
	if words.is_empty():
		return
	var name := words[0].to_lower()
	if not COMMANDS.has(name):
		_say("no command %s: help lists them" % _plain(name))
		return
	var world := ui.main.world() if ui != null and ui.main != null else null
	if world == null and name not in ["help", "scenarios"]:
		_say("only in a run")
		return
	call("_" + name, words.slice(1), world)


func _help(_args: PackedStringArray, _world: World) -> void:
	for name: String in COMMANDS:
		_say("%s  %s" % [_usage(name), COMMANDS[name][1]])


func _scenarios(_args: PackedStringArray, _world: World) -> void:
	_say(" ".join(_scenario_keys()))


func _scenario(args: PackedStringArray, _world: World) -> void:
	var scenario := Scenarios.by_key(args[0]) if args.size() == 1 else {}
	if scenario.is_empty():
		_say("%s, a key of: %s" % [_usage("scenario"), " ".join(_scenario_keys())])
		return
	ui.main.start_scenario(scenario)
	# Where it put you shows at once; its things follow.
	_say("%s: %s" % [Dev.read("world/scn"), scenario.label])


func _fly(_args: PackedStringArray, world: World) -> void:
	var player := world.player
	player.step_off()
	player.flying = not player.flying
	_say(Controls.bbcode("flying: {fly_up} up, {fly_down} down, {sprint} faster") if player.flying else "walking")


func _warp(args: PackedStringArray, world: World) -> void:
	if args.is_empty():
		var at := World.TIME_WARPS.find(world.time_warp)
		world.time_warp = World.TIME_WARPS[(at + 1) % World.TIME_WARPS.size()]
	elif args[0].is_valid_float() and args[0].to_float() >= 0.0:
		world.time_warp = args[0].to_float()
	else:
		_say(_usage("warp"))
		return
	_say(("time x%d" if world.time_warp == roundf(world.time_warp) else "time x%.2f") % world.time_warp)


func _gravity(args: PackedStringArray, world: World) -> void:
	if args.is_empty():
		world.set_gravity(World.LOW_GRAVITY if world.gravity == world.tuning.gravity else world.tuning.gravity)
	elif args[0].is_valid_float() and args[0].to_float() >= 0.0:
		world.set_gravity(args[0].to_float())
	else:
		_say(_usage("gravity"))
		return
	_say("gravity %.2f m/s², %.2f g" % [world.gravity, world.gravity / Player.ONE_G])


func _time(args: PackedStringArray, world: World) -> void:
	var of_day := args[0].to_float() if args.size() == 1 and args[0].is_valid_float() else -1.0
	if of_day < 0.0 or of_day > 1.0:
		_say(_usage("time"))
		return
	# On, never back: every tick's clock only runs forward.
	var day := world.weather.day
	var longitude := world.moon.longitude
	world.time += fposmod(of_day - day.time_of_day(world.time, longitude), 1.0) * world.tuning.day_minutes * 60.0
	world.weather.forecast_now()
	_say("day %d, %.3f of it" % [day.day(world.time, longitude), day.time_of_day(world.time, longitude)])


func _tu(args: PackedStringArray, world: World) -> void:
	var sizes := DayCycle.TU_SIZES
	var size := -1.0
	if args.is_empty():
		size = sizes[(sizes.find(world.tuning.tu_degrees) + 1) % sizes.size()]
	elif args.size() == 1 and args[0].is_valid_float() and sizes.has(args[0].to_float()):
		size = args[0].to_float()
	if size < 0.0:
		_say(_usage("tu"))
		return
	world.tuning.tu_degrees = size
	var day := world.weather.day
	_say("Tu %d° across: an orbit of %.1f of its radii, %d s of totality" % [roundi(size), day.tu_orbit(), roundi(day.totality())])


func _give(args: PackedStringArray, world: World) -> void:
	if args.is_empty() or not _give_ids().has(args[0]):
		_say("%s, an id of: %s" % [_usage("give"), " ".join(_give_ids())])
		return
	var id := StringName(args[0])
	var count := clampi(args[1].to_int(), 1, MOST) if args.size() > 1 else 1
	var player := world.player
	var ahead := 1.0
	for i in count:
		if Catalog.DEVICES.has(id):
			var depth: float = Catalog.DEVICES[id].size.z
			Scenarios.standing(world, id, [], [0.0, ahead + depth * 0.5])
			ahead += depth + 0.3
		elif id == &"stake":
			Scenarios.stakes_and_coils(world, [[0.0, ahead]], [])
			ahead += 0.2
		elif id == &"coil":
			Scenarios.stakes_and_coils(world, [], [[0.0, ahead]])
			ahead += 0.4
		elif id in [&"cable", &"strong_cable", &"hose"]:
			var at := player.global_position - player.global_basis.z * ahead
			at.y = world.height_under(at)
			if id == &"hose":
				Catalog.hose(world, at)
			else:
				Catalog.cable(world, at, id == &"strong_cable")
			ahead += 0.3
		elif player.hands.held == null:
			var part := Catalog.part(id)
			world.content.add_child(part)
			part.global_position = player.global_position + Vector3.UP
			player.hands.hold(part)
		else:
			var lying := Transform3D(Basis(Vector3.UP, player.global_rotation.y) * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO)
			Scenarios.drop(world, Catalog.part(id), lying, 0.0, ahead)
			ahead += 0.3
	_say("%d %s" % [count, id])


func _fresh(_args: PackedStringArray, world: World) -> void:
	world.player.vitals.fresh()
	_say("fed, watered and whole")


## What give can make: every part that comes by itself, every device, and
## the things built whole.
static func _give_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id: StringName in Catalog.PARTS:
		if not ON_SOMETHING.has(id):
			ids.append(id)
	for id: StringName in Catalog.DEVICES:
		ids.append(id)
	ids.append_array(["stake", "cable", "strong_cable", "hose"])
	return ids


static func _scenario_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for scenario in Scenarios.LIST:
		keys.append(scenario.key)
	return keys


static func _usage(name: String) -> String:
	return ("%s %s" % [name, COMMANDS[name][0]]).strip_edges()


## What's typed, as text and never as markup.
static func _plain(text: String) -> String:
	return text.replace("[", "[lb]")


func _submit(text: String) -> void:
	_line.clear()
	_back = 0
	text = text.strip_edges()
	if text == "":
		return
	if _typed.is_empty() or _typed[-1] != text:
		_typed.append(text)
		if _typed.size() > REMEMBERED:
			_typed.remove_at(0)
	_say("> " + _plain(text))
	run(text)


func _say(line: String) -> void:
	_said.append(line)
	if _said.size() > SHOWN:
		_said = _said.slice(_said.size() - SHOWN)
	_write()


## Written as it opens too, so a rebound key shows as it is now.
func _write() -> void:
	var head := "[color=#%s]%s[/color]" % [get_theme_color(&"dim", &"Palette").to_html(),
		Controls.bbcode("help lists the commands   {console} or {ui_cancel} closes")]
	_out.text = "\n".join(PackedStringArray([head]) + _said)


## The line keeps these keys from the menus' focus moving: up and down step
## through what was typed, and the focus-next key completes.
func _on_line_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_up", true):
		_recall(1)
	elif event.is_action_pressed(&"ui_down", true):
		_recall(-1)
	elif event.is_action_pressed(&"ui_focus_next", true):
		_complete()
	else:
		return
	_line.accept_event()


func _recall(by: int) -> void:
	_back = clampi(_back + by, 0, _typed.size())
	_line.text = "" if _back == 0 else _typed[_typed.size() - _back]
	_line.caret_column = _line.text.length()


## Finishes the word being typed: a command's name, then a scenario's key or
## a catalog id. Several fit: as far as they agree, and they're listed.
func _complete() -> void:
	var words := _line.text.split(" ")
	var choices := PackedStringArray(COMMANDS.keys())
	if words.size() == 2 and words[0] == "scenario":
		choices = _scenario_keys()
	elif words.size() == 2 and words[0] == "give":
		choices = _give_ids()
	elif words.size() != 1:
		return
	var fits := Array(choices).filter(func(c: String) -> bool: return c.begins_with(words[-1]))
	if fits.is_empty():
		return
	var common: String = fits[0]
	for each: String in fits:
		while not each.begins_with(common):
			common = common.left(-1)
	words[-1] = common + (" " if fits.size() == 1 and words.size() == 1 else "")
	_line.text = " ".join(words)
	_line.caret_column = _line.text.length()
	if fits.size() > 1:
		_say(" ".join(PackedStringArray(fits)))


## A click on nothing never leaves the open console without its line.
func _keep_focus() -> void:
	if visible and is_inside_tree():
		_line.grab_focus()
		_line.edit()
