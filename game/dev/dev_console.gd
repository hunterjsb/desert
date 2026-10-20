class_name DevConsole
extends Control
## Dev: a line to type commands into over the run or any menu,
## with what they said above it. Worldless commands work outside a run. The UI root
## opens and closes it and keeps every key from the game while it's up; up
## and down step through what was typed before, the focus-next key finishes
## a command's name, a scenario or an id, and the wheel, the page actions and
## its bar scroll back through what was said. Its sides and foot pull it
## bigger or smaller, and the settings keep its size. Each command is a thin
## call into the game's own code. One that changes the run makes it a dev run, whose deeds
## never count (World.counts_deeds); one that only lists, or works on the
## profile, leaves it as it was.

## Each command's arguments and what it does, in the order help lists them.
const COMMANDS := {
	"help": ["", "these commands"],
	"scenarios": ["", "each scenario, and what it stages"],
	"scenario": ["<key>", "start one; the run is a dev run from then on, never saved"],
	"creative": ["", "every part and device, to take straight into your hands"],
	"fly": ["", "fly through the world, or walk again"],
	"warp": ["[n]", "the clock n times as fast; alone, the next of x1, x10, x60"],
	"gravity": ["[m/s²]", "gravity; alone, low gravity or back"],
	"time": ["<0-1>", "on to the next such moment of your local day: 0 is midnight, 0.5 noon"],
	"tu": ["[6|9|13]", "Tu's width across the sky under trial, degrees; alone, the next"],
	"give": ["<id> [n]", "a part in your hands or a device at your feet, by its catalog id"],
	"fresh": ["", "fed, watered and whole; what you carry stays"],
	"god": ["", "nothing harms you, you never hunger or thirst, and nothing is too heavy; again, mortal"],
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
## Lines of output kept to scroll back through, and moved a wheel's notch;
## commands remembered, and the most give makes at once.
const KEPT := 200
const NOTCH := 2
const REMEMBERED := 50
const MOST := 20
## Said the first time the run turns a dev run.
const DEV_RUN := "a dev run from now: no deed counts in it"
## Its panel's first width, wide enough for a scenario's line, and how far
## down it hangs, px; at first it's as tall as scenario's whole list needs.
const WIDTH := 800.0
const TOP := 24.0
## The smallest it pulls to, how near the screen's edges it may come, and how
## far either side of a side or its foot it's taken hold of, px.
const SMALLEST := Vector2(360.0, 160.0)
const EDGE := 8.0
const GRIP := 8.0

var ui: UIRoot
var _panel: PanelContainer
var _head: RichTextLabel
var _out: RichTextLabel
var _bar: PageBar
var _line: LineEdit
var _said := PackedStringArray()
var _typed := PackedStringArray()
## How far back up has gone through what was typed; 0 is a new line.
var _back := 0
## How many lines back the output is scrolled; 0 shows the latest.
var _up := 0
## The sides being pulled, -1 or 1 across and 1 down, from where and at what size.
var _pulling := Vector2.ZERO
var _from := Vector2.ZERO
var _was := Vector2.ZERO


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Every click lands here, so none reaches the world to throw or look.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"DevConsolePanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_top = TOP
	# Its edge inside passes a press on, to be taken hold of.
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.draw.connect(_draw_grip)
	add_child(_panel)
	var stack := VBoxContainer.new()
	_panel.add_child(stack)
	_head = Controls.keys_label()
	_head.theme_type_variation = &"DevConsoleOut"
	stack.add_child(_head)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(row)
	# Scrolled a whole line at a time, by its own bar.
	_out = Controls.keys_label()
	_out.theme_type_variation = &"DevConsoleOut"
	_out.fit_content = false
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_out)
	_bar = PageBar.new()
	_bar.moved.connect(func(at: float) -> void:
		_up = _out.get_line_count() - _rows() - roundi(at)
		_place())
	row.add_child(_bar)
	_out.resized.connect(_place)
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
	get_viewport().size_changed.connect(_fit)


func open() -> void:
	visible = true
	_place()
	_fit()
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
	_up = 0
	_pulling = Vector2.ZERO


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
	var counted := world != null and world.counts_deeds
	call("_" + name, words.slice(1), world)
	if counted and not world.counts_deeds:
		_say(DEV_RUN)


## The run changed by the console: a dev run from now, saved as one.
static func _changed(world: World) -> void:
	world.counts_deeds = false


func _help(_args: PackedStringArray, _world: World) -> void:
	var wide := 0
	for name: String in COMMANDS:
		wide = maxi(wide, _usage(name).length())
	for name: String in COMMANDS:
		_say("%s  %s" % [_usage(name).rpad(wide), COMMANDS[name][1]])


## Each in a line of its own, their keys in a column.
func _scenarios(_args: PackedStringArray, _world: World) -> void:
	var wide := 0
	for scenario in Scenarios.LIST:
		wide = maxi(wide, scenario.key.length())
	for scenario in Scenarios.LIST:
		_say("%s  %s" % [scenario.key.rpad(wide), scenario.label])


## Alone, or with a key it doesn't know, it lists them.
func _scenario(args: PackedStringArray, _world: World) -> void:
	var scenario := Scenarios.by_key(args[0]) if args.size() == 1 else {}
	if scenario.is_empty():
		_say("%s, one of:" % _usage("scenario"))
		_scenarios(args, _world)
		return
	ui.main.start_scenario(scenario)
	# Where it put you shows at once; its things follow.
	_say("%s: %s" % [Dev.read("world/scn"), scenario.label])


func _creative(_args: PackedStringArray, _world: World) -> void:
	ui.open_creative()


func _fly(_args: PackedStringArray, world: World) -> void:
	var player := world.player
	player.step_off()
	player.flying = not player.flying
	_changed(world)
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
	_changed(world)
	_say(("time x%d" if world.time_warp == roundf(world.time_warp) else "time x%.2f") % world.time_warp)


func _gravity(args: PackedStringArray, world: World) -> void:
	if args.is_empty():
		world.set_gravity(World.LOW_GRAVITY if world.gravity == world.tuning.gravity else world.tuning.gravity)
	elif args[0].is_valid_float() and args[0].to_float() >= 0.0:
		world.set_gravity(args[0].to_float())
	else:
		_say(_usage("gravity"))
		return
	_changed(world)
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
	_changed(world)
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
	_changed(world)
	var day := world.weather.day
	_say("Tu %d° across: an orbit of %.1f of its radii, %d s of totality" % [roundi(size), day.tu_orbit(), roundi(day.totality())])


func _give(args: PackedStringArray, world: World) -> void:
	if args.is_empty() or not _give_ids().has(args[0]):
		_say("%s, an id of: %s" % [_usage("give"), " ".join(_give_ids())])
		return
	var id := StringName(args[0])
	var count := clampi(args[1].to_int(), 1, MOST) if args.size() > 1 else 1
	var player := world.player
	_changed(world)
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
	_changed(world)
	_say("meltdown: the Stoker's song on %d kHz for %d s" % [roundi(gods.carrier(&"stoker", world.time)),
		roundi(Sounds.RADIO_STOKER.get_length())])


func _fresh(_args: PackedStringArray, world: World) -> void:
	world.player.vitals.fresh()
	_changed(world)
	_say("fed, watered and whole")


func _god(_args: PackedStringArray, world: World) -> void:
	var vitals := world.player.vitals
	vitals.god = not vitals.god
	_changed(world)
	_say("god: nothing harms you, nothing is too heavy" if vitals.god else "mortal")


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
	_changed(world)
	go_to(world, target)
	var p: Vector3 = target.p
	_say("%s: %s, %s" % [target.name, history.region_of(p), history.tu_words(p)])


## Stands you a little in front of a landmark, a part of one or a vent, facing it.
static func go_to(world: World, target: Dictionary) -> void:
	var history := world.shape.history
	var heading: float = target.get("bearing", 0.0)
	var stand := Sphere.toward(target.p, heading + PI, STANDOFF / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(stand)), rad_to_deg(Sphere.longitude(stand)),
		-Sphere.bearing(stand, target.p))


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
			for each in kit.unlocks():
				profile.unlock(each)
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
	if _said.size() > KEPT:
		_said = _said.slice(_said.size() - KEPT)
	_up = 0
	_out.text = "\n".join(_said)
	_place()


## Back through what was said by `by` lines, or down again for a negative `by`.
func scroll(by: int) -> void:
	_up += by
	_place()


## How many lines of what was said show at its size now.
func _rows() -> int:
	return maxi(floori((_out.size.y + 0.5) / _tall()), 1)


## A line of what was said, px.
func _tall() -> float:
	var font := _out.get_theme_font(&"normal_font")
	return font.get_height(_out.get_theme_font_size(&"normal_font_size")) + _out.get_theme_constant(&"line_separation")


## The latest lines, or as far back as it's scrolled, its bar to match, and
## the head line saying which. Placed as it opens too, so a rebound key shows
## as it is now.
func _place() -> void:
	var lines := _out.get_line_count()
	var shown := _rows()
	_up = clampi(_up, 0, maxi(lines - shown, 0))
	var top := maxi(lines - shown - _up, 0)
	_out.scroll_to_line(top)
	_bar.show_page(lines, shown, top)
	var dim := get_theme_color(&"dim", &"Palette").to_html()
	_head.text = "[color=#%s]%s[/color]" % [dim, Controls.bbcode("help lists the commands   {console} or {ui_cancel} closes")
		if _up == 0 else Controls.bbcode("%d lines back   {ui_page_down} or the wheel comes down" % _up)]


## What shows of what was said, as plain text.
func shown() -> String:
	var lines := _out.get_line_count()
	var top := maxi(lines - _rows() - _up, 0)
	var last := mini(top + _rows(), lines) - 1
	if last < top:
		return ""
	var from := _out.get_line_range(top).x
	return _out.get_parsed_text().substr(from, _out.get_line_range(last).y - from).strip_edges(false, true)


## Its size as kept, or at first, within the screen: wide enough for a
## scenario's line and as tall as scenario's whole list, the line it was
## typed on and its usage need. Always whole lines tall, so none shows cut.
func _fit(want := Settings.console_size) -> void:
	# What's round the lines said: its edge, the head line and the typing line.
	var around := _panel.get_combined_minimum_size().y - _out.get_combined_minimum_size().y
	if want == Vector2.ZERO:
		want = Vector2(WIDTH, around + (Scenarios.LIST.size() + 2) * _tall())
	var room := get_viewport_rect().size - Vector2(EDGE * 2.0, TOP + EDGE)
	var fits := want.clamp(SMALLEST.min(room), room)
	fits.y = around + maxf(floorf((fits.y - around) / _tall()), 1.0) * _tall()
	_panel.offset_left = -roundf(fits.x * 0.5)
	_panel.offset_right = roundf(fits.x * 0.5)
	_panel.offset_bottom = TOP + roundf(fits.y)


## Its sides, its foot and the corners between are taken hold of to pull it
## bigger or smaller, about its middle; the pointer shows which way, and let
## go its size is kept.
func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if press != null and press.button_index == MOUSE_BUTTON_LEFT:
		if not press.pressed and _pulling != Vector2.ZERO:
			Settings.console_size = _panel.size
			Settings.save()
		_pulling = _sides(press.position) if press.pressed else Vector2.ZERO
		_from = press.position
		_was = _panel.size
		accept_event()
	elif motion != null and _pulling != Vector2.ZERO:
		_fit(_was + (motion.position - _from) * _pulling * Vector2(2.0, 1.0))
		accept_event()
	elif motion != null:
		var at := _sides(motion.position)
		var shape := CURSOR_ARROW
		if at.x != 0.0 and at.y != 0.0:
			shape = CURSOR_FDIAGSIZE if at.x > 0.0 else CURSOR_BDIAGSIZE
		elif at != Vector2.ZERO:
			shape = CURSOR_HSIZE if at.x != 0.0 else CURSOR_VSIZE
		mouse_default_cursor_shape = shape
		_panel.mouse_default_cursor_shape = shape


## Which of its sides and foot a point is near enough to take hold of.
func _sides(at: Vector2) -> Vector2:
	var edge := _panel.get_rect()
	var out := Vector2.ZERO
	if at.y >= edge.position.y and at.y <= edge.end.y + GRIP:
		if absf(at.x - edge.position.x) <= GRIP:
			out.x = -1.0
		elif absf(at.x - edge.end.x) <= GRIP:
			out.x = 1.0
	if absf(at.y - edge.end.y) <= GRIP and at.x >= edge.position.x - GRIP and at.x <= edge.end.x + GRIP:
		out.y = 1.0
	return out


## Two short strokes in its foot's corner: it can be pulled.
func _draw_grip() -> void:
	var ink := get_theme_color(&"faint", &"Palette")
	var corner := _panel.size - Vector2(3.0, 3.0)
	for reach: float in [6.0, 10.0]:
		_panel.draw_line(corner - Vector2(reach, 0.0), corner - Vector2(0.0, reach), ink, 1.0, true)


## The wheel scrolls what was said wherever the mouse is, and nothing of the
## game's on the wheel hears it meanwhile.
func _input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if not visible or wheel == null or wheel.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	if wheel.pressed:
		scroll(NOTCH * (1 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else -1))
	get_viewport().set_input_as_handled()


## The line keeps these keys from the menus' focus moving: up and down step
## through what was typed, the focus-next key completes, and the page actions
## scroll what was said a page at a time.
func _on_line_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_up", true):
		_recall(1)
	elif event.is_action_pressed(&"ui_down", true):
		_recall(-1)
	elif event.is_action_pressed(&"ui_focus_next", true):
		_complete()
	elif event.is_action_pressed(&"ui_page_up", true):
		scroll(_rows() - 1)
	elif event.is_action_pressed(&"ui_page_down", true):
		scroll(1 - _rows())
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
