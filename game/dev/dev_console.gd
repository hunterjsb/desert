class_name DevConsole
extends Control
## Dev: a line to type commands into over the running game, or over the main
## menu for what needs no world, with what they said above it. The UI root
## opens and closes it and keeps every key from the game while it's up; up
## and down step through what was typed before, and the focus-next key
## finishes a command's name, a scenario or an id. Each command is a thin
## call into the game's own code.

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
	"god": ["", "nothing harms you and you never hunger or thirst; again, mortal"],
	"goto": ["[landmark]", "stand by a landmark, one of its parts or a vent, on fresh ground; alone, how far each is"],
	"map": ["[metres]", "the history under the sand round you, this wide; alone, on or off"],
	"unlockall": ["", "every start open, deeds or not"],
	"deed": ["<id>", "a deed done, by its id"],
	"deeds": ["[clear]", "which deeds are done; clear forgets them all"],
	"reset": ["", "forget the profile: deeds, starts opened, finds, how-tos, as Options' reset"],
	"meltdown": ["", "the Stoker plays its furnace song on its frequency, once, from now"],
	"surveyor": ["[s]", "the Surveyor's low pass forced: it comes straight over you in s seconds, 20 alone"],
	"airdrop": ["[now]", "on to just before the Surveyor's next pass high over you, a flare in your hands; now, its cannon fires at you at once"],
}
## What works with no world, at the main menu too.
const WORLDLESS := ["help", "scenarios", "unlockall", "deed", "deeds", "reset"]
## surveyor brings the Surveyor over this soon, s, unless told.
const SURVEYOR_LEAD := 20.0
## airdrop sets the clock this long before the Surveyor's pass, s.
const AIRDROP_LEAD := 15.0
## How far from a landmark's middle goto stands you, facing it, m.
const STANDOFF := 60.0
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
	panel.theme_type_variation = &"DevConsolePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -WIDTH * 0.5
	panel.offset_right = WIDTH * 0.5
	panel.offset_top = TOP
	panel.offset_bottom = TOP
	add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	_out = Controls.keys_label()
	_out.theme_type_variation = &"DevConsoleOut"
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_out)
	_line = LineEdit.new()
	_line.theme_type_variation = &"DevConsoleLine"
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
	if world == null and name not in WORLDLESS:
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
	_say("day %d, %.3f of it" % [day.day(world.time, longitude, world.began), day.time_of_day(world.time, longitude)])


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


func _surveyor(args: PackedStringArray, world: World) -> void:
	var lead := float(args[0]) if args.size() > 0 and args[0].is_valid_float() else SURVEYOR_LEAD
	Scenarios.surveyor_over(world, lead)
	_say("surveyor: straight over you in %d s, %.1f km up; light a flare as it comes over" % [roundi(lead),
		Airdrop.surveyor(world, world.player.global_position, world.time + lead).metres / 1000.0])


func _airdrop(args: PackedStringArray, world: World) -> void:
	var player := world.player
	if args.size() > 0 and args[0] == "now":
		var drop := Airdrop.fire(world, player.global_position)
		_say("airdrop: fired from %.1f km, down in %d s, %d m off" % [drop._metres / 1000.0,
			roundi(drop.lands_at - world.time), roundi(Vector2(drop.global_position.x - player.global_position.x,
			drop.global_position.z - player.global_position.z).length())])
		return
	var high := deg_to_rad(world.tuning.airdrop_elevation_degrees)
	var t := world.time
	var until := t + 200.0 * world.tuning.day_minutes * 60.0
	while t < until and Airdrop.surveyor(world, player.global_position, t).up < high:
		t += 1.0
	if t >= until:
		_say("airdrop: the Surveyor doesn't pass high over here for a long while")
		return
	world.time = t - AIRDROP_LEAD
	if player.hands.held == null:
		var flare := Catalog.part(&"flare")
		world.content.add_child(flare)
		flare.global_position = player.global_position + Vector3.UP
		player.hands.hold(flare)
	_say("airdrop: the Surveyor passes high over you in %d s; light the flare (use)" % roundi(AIRDROP_LEAD))


func _meltdown(_args: PackedStringArray, world: World) -> void:
	var gods := Radio.gods_of(world)
	gods.meltdown(world.time)
	_say("meltdown: the Stoker's song on %d kHz for %d s" % [roundi(gods.carrier(&"stoker", world.time)),
		roundi(Sounds.RADIO_STOKER.get_length())])


func _fresh(_args: PackedStringArray, world: World) -> void:
	world.player.vitals.fresh()
	_say("fed, watered and whole")


func _god(_args: PackedStringArray, world: World) -> void:
	var vitals := world.player.vitals
	vitals.god = not vitals.god
	_say("god: nothing harms you" if vitals.god else "mortal")


func _goto(args: PackedStringArray, world: World) -> void:
	var history := world.shape.history
	if args.is_empty():
		var here := Sphere.point(world.moon.latitude, world.moon.longitude)
		for each in history.landmarks + history.geology.live():
			_say("%s  %s, %.1f km %s" % [each.id, each.name, Sphere.angle(here, each.p) * history.radius / 1000.0,
				Radio.compass(rad_to_deg(Sphere.bearing(here, each.p)))])
		return
	var target := _place_named(history, args[0])
	if target.is_empty():
		_say("%s, an id of: %s" % [_usage("goto"), " ".join(_goto_ids(history))])
		return
	# A little in front of it, facing it.
	var heading: float = target.get("bearing", 0.0)
	var stand := Sphere.toward(target.p, heading + PI, STANDOFF / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(stand)), rad_to_deg(Sphere.longitude(stand)),
		-Sphere.bearing(stand, target.p))
	var p: Vector3 = target.p
	_say("%s: %s, %s" % [target.name, history.region_of(p), history.tu_words(p)])


func _map(args: PackedStringArray, _world: World) -> void:
	var map := HistoryMap.of(ui)
	if args.size() == 1 and args[0].is_valid_float() and args[0].to_float() > 0.0:
		map.width_m = clampf(args[0].to_float(), 100.0, 200000.0)
		map.visible = true
	elif args.is_empty():
		map.visible = not map.visible
	else:
		_say(_usage("map"))
		return
	_say("history map %d m across" % roundi(map.width_m) if map.visible else "history map off")


## Opens every start whatever deeds are done, so a start can be tried after
## the deeds are forgotten; they stay open until the profile is reset.
func _unlockall(_args: PackedStringArray, _world: World) -> void:
	var profile := _profile()
	if profile == null:
		_say("no profile")
		return
	var names := PackedStringArray()
	for kit in Kit.origins():
		if not kit.is_open_to(profile):
			profile.unlock(kit.unlock)
		names.append(kit.label)
	_say("open: " + ", ".join(names))


func _deed(args: PackedStringArray, _world: World) -> void:
	var profile := _profile()
	if args.size() != 1 or not Deeds.TABLE.has(StringName(args[0])) or profile == null:
		_say("%s, an id of: %s" % [_usage("deed"), " ".join(_deed_ids())])
		return
	var id := StringName(args[0])
	var name: String = Deeds.TABLE[id].name
	_say(("%s done" if profile.deed(id, {"dev": true}) else "%s was done already") % name)


func _reset(_args: PackedStringArray, _world: World) -> void:
	if ui == null or ui.main == null or ui.main.profile() == null:
		_say("no profile")
		return
	ui.main.reset_profile()
	_say("profile forgotten: only the Surveyor open, no deeds")


func _deeds(args: PackedStringArray, _world: World) -> void:
	var profile := _profile()
	if profile == null or args.size() > 1 or args.size() == 1 and args[0] != "clear":
		_say(_usage("deeds") if profile != null else "no profile")
		return
	if args.size() == 1:
		profile.forget_deeds()
		_say("every deed forgotten")
		return
	var done := PackedStringArray()
	var left := PackedStringArray()
	for id: StringName in Deeds.TABLE:
		if profile.did(id):
			done.append(id)
		else:
			left.append(id)
	_say("done %d of %d: %s" % [done.size(), Deeds.TABLE.size(), " ".join(done) if not done.is_empty() else "none"])
	if not left.is_empty():
		_say("not yet: " + " ".join(left))


func _profile() -> Node:
	return get_node_or_null(^"/root/Profile")


static func _deed_ids() -> PackedStringArray:
	return PackedStringArray(Deeds.TABLE.keys())


## A landmark, a landmark's part or a vent, by id.
static func _place_named(history: History, id: String) -> Dictionary:
	var found := history.landmark(StringName(id))
	if not found.is_empty():
		return found
	for each in history.landmarks:
		for part: Dictionary in each.parts:
			if part.id == StringName(id):
				return part
	for each in history.geology.vents:
		if each.id == StringName(id):
			return each
	return {}


static func _goto_ids(history: History) -> PackedStringArray:
	var ids := PackedStringArray()
	for each in history.landmarks:
		ids.append(each.id)
		for part: Dictionary in each.parts:
			ids.append(part.id)
	for each in history.geology.vents:
		if not ids.has(each.id):
			ids.append(each.id)
	return ids


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
	elif words.size() == 2 and words[0] == "deed":
		choices = _deed_ids()
	elif words.size() == 2 and words[0] == "deeds":
		choices = PackedStringArray(["clear"])
	elif words.size() == 2 and words[0] == "goto" and ui != null and ui.main != null and ui.main.world() != null:
		choices = _goto_ids(ui.main.world().shape.history)
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
