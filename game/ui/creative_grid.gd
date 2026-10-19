class_name CreativeGrid
extends VBoxContainer
## The creative menu's grid: every part and device there is, by group, each
## a card with its picture and name, for building in a dev run. Picked, a
## fresh one comes to your hands, or with them full goes in your suit; one
## too big for the suit stands in front of you, and you have hold of it if
## your hands are free. A line under the grid says where the last one went.

## Each group's heading and what's in it, by the ids give knows them by,
## filling the left side and then the right.
const GROUPS := [
	["Chassis and frames", [&"chassis", &"frame", &"fabric", &"hover_tray", &"skates", &"board_plate"]],
	["Power", [&"battery", &"big_battery", &"solar_panel", &"light_panel", &"turbine", &"cable", &"strong_cable"]],
	["Devices", [&"shield", &"light_shield", &"condenser", &"console", &"screen", &"anemometer", &"barometer",
		&"hygrometer", &"particle_sensor", &"radar", &"radio", &"lamp", &"planter", &"harvester", &"bedroll",
		&"survival_kit"]],
	["Sail and rope", [&"mast", &"sail", &"keel", &"helm_seat", &"coil", &"hook", &"stake"]],
	["Tools", [&"cutter", &"sand_scoop", &"sealant", &"med_kit", &"compass", &"hull_plate"]],
	["Food and water", [&"canister", &"hose", &"ration", &"tubers", &"fungus_caps", &"saltbush_leaves", &"salt",
		&"root_tuber", &"vat_fungus", &"saltbush"]],
	["Boards by make", BoardMakes.ALL],
]
## Rope and wire come rolled up, as they're found: a coil, or a first end
## with the rest behind it.
const ROLLED := {&"coil": &"coil", &"cable": &"plug", &"strong_cable": &"strong_plug", &"hose": Hose.END}
## A card, its picture, cards a row, the room between cards, under a
## group's heading and between groups and sides, px.
const CARD := Vector2(132.0, 108.0)
const PICTURE := 60.0
const ACROSS := 6
const GAP := 6.0
const HEAD := 28.0
const GROUP_GAP := 14.0
const SIDE_GAP := 40.0
## A name longer than this many letters gives way to its short one.
const LONGEST := 16
## The room the menu round it takes on the screen, px: past that, it's drawn
## smaller to fit.
const ROOM := Vector2(120.0, 260.0)

var _world: World
## What holds its place in the menu, and the cards and headings drawn in it at
## their own size or smaller.
var _board: Control
var _drawn: Control
var _said: Label
var _cards := {}


## The grid in a menu, and Back under it.
static func fill(words: Words, world: World, back: Callable) -> CreativeGrid:
	var grid := CreativeGrid.new(world)
	words.add_body(grid)
	var word := words.add("Back", back)
	word.focus_neighbor_top = word.get_path_to(grid.first())
	return grid


## Every id on it, in order.
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for group: Array in GROUPS:
		out.append_array(group[1])
	return out


## A fresh one of a thing give knows: in your hands if they're free, else in
## your suit; too big for the suit, it stands in front of you, and you have
## hold of it if your hands are free. Where it went, in a few words.
static func give(world: World, id: StringName) -> String:
	var player := world.player
	var hands := player.hands
	var thing := _made(id)
	var free := hands.held == null and hands.grasp.body == null
	var device := thing as Device
	if free and (device == null or device.carryable):
		world.content.add_child(thing)
		thing.global_transform = player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5))
		Finds.unroll(world, thing)
		hands.hold(thing)
		return "in your hands"
	if player.suit.fits(thing):
		player.suit.carried.append(thing)
		player.suit.carry_devices()
		Sounds.play(player, Sounds.POUCH_IN)
		return "in your suit"
	var size: Vector3 = Catalog.DEVICES[id].size
	Scenarios.drop(world, thing, Transform3D(Basis(Vector3.UP, player.global_rotation.y),
		Vector3(0.0, size.y * 0.5, 0.0)), 0.0, 1.0 + size.z * 0.5)
	if free:
		hands.grasp.take(thing)
		return "held in front of you"
	return "in front of you"


## A thing's name on its card: its label, or its short name where that's too long.
static func name_of(id: StringName) -> String:
	var spec: Dictionary = Catalog.DEVICES.get(id, Catalog.PARTS.get(id, {}))
	var label: String = spec.get("label", Catalog.short_label(id))
	return label if label.length() <= LONGEST else Catalog.short_label(id)


static func _made(id: StringName) -> RigidBody3D:
	if ROLLED.has(id):
		var rolled := Catalog.part(ROLLED[id])
		rolled.set_meta(&"rolled", ROLLED[id])
		return rolled
	if id == &"stake":
		return Catalog.stake()
	return Catalog.device(id) if Catalog.DEVICES.has(id) else Catalog.part(id)


func _init(world: World) -> void:
	_world = world
	theme_type_variation = &"Column"
	_board = Control.new()
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board)
	_drawn = Control.new()
	_drawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_drawn)
	_lay_out()
	_said = Label.new()
	_said.theme_type_variation = &"MenuNote"
	_said.uppercase = true
	_said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_said)
	say("")


func _ready() -> void:
	var room := get_viewport_rect().size - ROOM
	var fits := minf(1.0, minf(room.x / _drawn.size.x, room.y / _drawn.size.y))
	_drawn.scale = Vector2(fits, fits) if fits > 0.0 else Vector2.ONE
	_board.custom_minimum_size = _drawn.size * _drawn.scale
	_focus_first.call_deferred()


## Opened, the first card's highlighted, unless it closed meanwhile.
func _focus_first() -> void:
	if is_inside_tree():
		first().grab_focus()


func first() -> Button:
	return _cards[GROUPS[0][1][0]]


## Says a line under the grid, such as where the last pick went; a space
## keeps its line with nothing to say.
func say(line: String) -> void:
	_said.text = line if line != "" else " "


## The groups down two sides, split where the sides come out nearest level.
func _lay_out() -> void:
	var tall: Array[float] = []
	for group: Array in GROUPS:
		tall.append(HEAD + ceili(group[1].size() / float(ACROSS)) * (CARD.y + GAP) - GAP)
	var split := 1
	var best := INF
	for k in range(1, GROUPS.size()):
		var sides := Vector2.ZERO
		for i in GROUPS.size():
			sides[0 if i < k else 1] += tall[i] + GROUP_GAP
		if maxf(sides.x, sides.y) < best:
			best = maxf(sides.x, sides.y)
			split = k
	var wide := ACROSS * (CARD.x + GAP) - GAP
	var at := Vector2.ZERO
	for i in GROUPS.size():
		if i == split:
			at = Vector2(wide + SIDE_GAP, 0.0)
		var head := Label.new()
		head.theme_type_variation = &"MenuNote"
		head.text = GROUPS[i][0]
		head.uppercase = true
		head.position = at
		_drawn.add_child(head)
		var items: Array = GROUPS[i][1]
		for k in items.size():
			var card := _card(items[k])
			card.position = at + Vector2(k % ACROSS * (CARD.x + GAP), HEAD + floorf(k / float(ACROSS)) * (CARD.y + GAP))
			_drawn.add_child(card)
			_cards[items[k]] = card
		at.y += tall[i] + GROUP_GAP
	_drawn.size = Vector2(2.0 * wide + SIDE_GAP, best - GROUP_GAP)


## A thing's card: its picture over its name, as the deeds' cards are drawn.
func _card(id: StringName) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"DeedCard"
	card.focus_mode = Control.FOCUS_ALL
	card.size = CARD
	card.set_meta(&"item", id)
	var column := VBoxContainer.new()
	column.theme_type_variation = &"Column"
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var look := TextureRect.new()
	look.texture = ItemIcons.of(Engine.get_main_loop(), ROLLED.get(id, id))
	look.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	look.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	look.custom_minimum_size = Vector2(PICTURE, PICTURE)
	look.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	look.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(look)
	var name := Label.new()
	name.theme_type_variation = &"DeedCardName"
	name.text = name_of(id)
	name.uppercase = true
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(name)
	card.mouse_entered.connect(card.grab_focus)
	card.focus_entered.connect(func() -> void: Sounds.play(get_tree().root, Sounds.MENU_MOVE, Sounds.UI))
	card.pressed.connect(_pick.bind(id))
	return card


func _pick(id: StringName) -> void:
	Sounds.play(get_tree().root, Sounds.MENU_CONFIRM, Sounds.UI)
	say("%s %s" % [name_of(id), give(_world, id)])
