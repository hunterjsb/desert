class_name CreativeGrid
extends VBoxContainer
## The creative menu's grid: every part and device there is, each a card with
## its picture and name, for building in a dev run. A search over it narrows
## the cards to those whose name has what's typed, and a row of the groups
## picks one to show, or all of them under their headings; what shows is a
## grid that scrolls by the wheel, its bar or the selection. Picked, a fresh
## one comes to your hands, or with them full goes in your suit; one too big
## for the suit stands in front of you, and you have hold of it if your hands
## are free. A line under the grid says where the last one went.

## Each group's heading and what's in it, by the ids give knows them by, in
## the order they show.
const GROUPS := [
	["Chassis and frames", [&"chassis", &"frame", &"fabric", &"hover_tray", &"skates", &"board_plate"]],
	["Power", [&"coalcane_bundle", &"battery", &"big_battery", &"power_box", &"power_cabinet", &"power_rack", &"power_shrine", &"solar_panel", &"light_panel", &"turbine", &"cable", &"strong_cable"]],
	["Devices", [&"shield", &"light_shield", &"personal_shield", &"condenser", &"console", &"nav_computer", &"screen",
		&"anemometer", &"barometer", &"hygrometer", &"particle_sensor", &"radar", &"ground_radar", &"radio", &"survey_receiver", &"lamp",
		&"planter", &"harvester", &"bedroll", &"survival_kit"]],
	["Sail and rope", [&"mast", &"sail", &"hand_winch", &"keel", &"helm_seat", &"crows_nest", &"streamer", &"sailing_notes", &"coil", &"hook", &"stake"]],
	["Tools", [&"surveyor_guide", &"cutter", &"sand_scoop", &"sieve", &"sealant", &"med_kit", &"compass", &"hull_plate", &"flare", &"cargo"]],
	["Food and water", [&"canister", &"hose", &"ration", &"tubers", &"fungus_caps", &"saltbush_leaves", &"salt",
		&"root_tuber", &"vat_fungus", &"saltbush"]],
	["Boards by make", BoardMakes.ALL],
]
## Rope and wire come rolled up, as they're found: a coil, or a first end
## with the rest behind it.
const ROLLED := {&"coil": &"coil", &"cable": &"plug", &"strong_cable": &"strong_plug", &"hose": Hose.END}
## A card, its picture, the room between cards, under a group's heading and
## between groups, px.
const CARD := Vector2(132.0, 108.0)
const PICTURE := 60.0
const GAP := 6.0
const HEAD := 28.0
const GROUP_GAP := 14.0
## A name longer than this many letters gives way to its short one.
const LONGEST := 16
## Cards a row at most, and the room the menu round it takes on the screen,
## px: as many rows show as fit, and the rest scrolls, this far a notch of the
## wheel, px.
const ACROSS := 10
const ROOM := Vector2(120.0, 340.0)
const WHEEL := 70.0
## The search's width, px.
const SEARCH := 360.0

var _world: World
var _search: LineEdit
## All, then each group, as picked from; the one picked.
var _groups: Array[Button] = []
var _picked := 0
## What shows of the page, and the page: the headings and cards laid out.
var _view: Control
var _page: Control
var _bar: PageBar
var _heads: Array[Label] = []
var _none: Label
var _said: Label
var _cards := {}
## The cards showing, in order, and how many to a row.
var _shown: Array[Button] = []
var _across := ACROSS
## The menu's Back, which the selection reaches below the last row.
var _back: Button
## A card highlighted by the pointer, which never scrolls under it.
var _pointed := false
## How far down its page it's scrolled, px.
var scroll := 0.0:
	set(to):
		scroll = clampf(to, 0.0, maxf(_page.size.y - _view.size.y, 0.0))
		_page.position.y = -scroll
		_bar.show_page(_page.size.y, _view.size.y, scroll)


## The grid in a menu, and Back under it.
static func fill(words: Words, world: World, back: Callable) -> CreativeGrid:
	var grid := CreativeGrid.new(world)
	words.add_body(grid)
	grid._back = words.add("Back", back)
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
	_search = LineEdit.new()
	_search.theme_type_variation = &"CreativeSearch"
	_search.placeholder_text = "FIND BY NAME"
	_search.custom_minimum_size.x = SEARCH
	_search.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_search.context_menu_enabled = false
	_search.emoji_menu_enabled = false
	_search.text_changed.connect(func(_text: String) -> void: _lay_out())
	_search.text_submitted.connect(func(_text: String) -> void: first().grab_focus())
	# Typing as soon as it's reached, by the selection or the pointer.
	_search.focus_entered.connect(_search.edit)
	_search.gui_input.connect(_on_search_input)
	add_child(_search)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	add_child(row)
	for i in GROUPS.size() + 1:
		var word := Button.new()
		word.theme_type_variation = &"CreativeGroup"
		word.text = ("All" if i == 0 else GROUPS[i - 1][0]).to_upper()
		word.toggle_mode = true
		word.button_pressed = i == 0
		word.focus_mode = Control.FOCUS_ALL
		# Reached by the selection it's picked at once; the pointer picks by pressing.
		word.focus_entered.connect(_pick.bind(i))
		word.pressed.connect(_pick.bind(i))
		row.add_child(word)
		_groups.append(word)
	_view = Control.new()
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_PASS
	_view.gui_input.connect(_on_view_input)
	_view.resized.connect(func() -> void: scroll = scroll)
	add_child(_view)
	_page = Control.new()
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_page)
	_bar = PageBar.new()
	_bar.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_bar.offset_left = -PageBar.ACROSS
	_bar.offset_right = 0.0
	_bar.moved.connect(func(at: float) -> void: scroll = at)
	_view.add_child(_bar)
	for group: Array in GROUPS:
		var head := Label.new()
		head.theme_type_variation = &"MenuNote"
		head.text = group[0]
		head.uppercase = true
		_page.add_child(head)
		_heads.append(head)
		for id: StringName in group[1]:
			_cards[id] = _card(id)
			_page.add_child(_cards[id])
	_none = Label.new()
	_none.theme_type_variation = &"MenuNote"
	_none.text = "Nothing by that name"
	_none.uppercase = true
	_page.add_child(_none)
	_said = Label.new()
	_said.theme_type_variation = &"MenuNote"
	_said.uppercase = true
	_said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_said)
	say("")


## As many to a row as the screen has room for, and as tall as all of them
## under their headings, or as the screen has room for.
func _ready() -> void:
	var room := get_viewport_rect().size - ROOM
	_across = clampi(floori((room.x + GAP) / (CARD.x + GAP)), 1, ACROSS)
	_lay_out()
	_view.custom_minimum_size = Vector2(_page.size.x + GAP + PageBar.ACROSS, minf(_page.size.y, maxf(room.y, CARD.y)))
	_focus_first.call_deferred()


## Opened, the first card's highlighted, unless it closed meanwhile.
func _focus_first() -> void:
	if is_inside_tree():
		first().grab_focus()


## The first card showing, or with none the search.
func first() -> Control:
	return _shown[0] if not _shown.is_empty() else _search


## The cards showing now, by what they give.
func shown() -> Array[StringName]:
	var out: Array[StringName] = []
	for card in _shown:
		out.append(card.get_meta(&"item"))
	return out


## Says a line under the grid, such as where the last pick went; a space
## keeps its line with nothing to say.
func say(line: String) -> void:
	_said.text = line if line != "" else " "


## Shows one group, by its place in the row: 0 is all of them.
func _pick(at: int) -> void:
	for i in _groups.size():
		_groups[i].set_pressed_no_signal(i == at)
	if at == _picked:
		return
	_picked = at
	Sounds.play(get_tree().root, Sounds.MENU_MOVE, Sounds.UI)
	_lay_out()


## Whether a thing's name, its label or its id has what's searched for.
static func matches(id: StringName, wanted: String) -> bool:
	if wanted == "":
		return true
	var spec: Dictionary = Catalog.DEVICES.get(id, Catalog.PARTS.get(id, {}))
	for name: String in [name_of(id), spec.get("label", ""), str(id).replace("_", " ")]:
		if name.to_lower().contains(wanted):
			return true
	return false


## The group picked, or every group under its heading, each card whose name
## has what's searched for, in rows from the top; scrolled back to the top.
func _lay_out() -> void:
	var wanted := _search.text.strip_edges().to_lower()
	_shown.clear()
	for each: Control in _page.get_children():
		each.visible = false
	var y := 0.0
	for g in GROUPS.size():
		if _picked != 0 and _picked != g + 1:
			continue
		var items: Array = GROUPS[g][1].filter(func(id: StringName) -> bool: return matches(id, wanted))
		if items.is_empty():
			continue
		if _picked == 0:
			_heads[g].position = Vector2(0.0, y)
			_heads[g].visible = true
			y += HEAD
		for k in items.size():
			var card: Button = _cards[items[k]]
			card.position = Vector2(k % _across * (CARD.x + GAP), y + floorf(k / float(_across)) * (CARD.y + GAP))
			card.visible = true
			_shown.append(card)
		y += ceili(items.size() / float(_across)) * (CARD.y + GAP) - GAP + GROUP_GAP
	_none.visible = _shown.is_empty()
	_page.size = Vector2(_across * (CARD.x + GAP) - GAP, maxf(y - GROUP_GAP, HEAD))
	scroll = 0.0
	_link()


## The selection's way round the cards showing: along a row and on to the
## next, up and down to the nearest in the row above or below, from the top
## row up to the group picked and on to the search, and from the last down to
## Back.
func _link() -> void:
	var group := _groups[_picked]
	var below: Control = _back if _back != null else group
	for i in _groups.size():
		var word := _groups[i]
		word.focus_neighbor_left = word.get_path_to(_groups[i - 1])
		word.focus_neighbor_right = word.get_path_to(_groups[(i + 1) % _groups.size()])
		word.focus_neighbor_top = word.get_path_to(_search)
		word.focus_neighbor_bottom = word.get_path_to(first() if not _shown.is_empty() else below)
	for i in _shown.size():
		var card := _shown[i]
		card.focus_neighbor_left = card.get_path_to(_shown[maxi(i - 1, 0)])
		card.focus_neighbor_right = card.get_path_to(_shown[mini(i + 1, _shown.size() - 1)])
		card.focus_neighbor_top = card.get_path_to(_nearest(card, -1.0, group))
		card.focus_neighbor_bottom = card.get_path_to(_nearest(card, 1.0, below))
	if _back != null:
		var last: Control = group
		for card in _shown:
			if is_equal_approx(card.position.y, _shown.back().position.y):
				last = card
				break
		_back.focus_neighbor_top = _back.get_path_to(last)


## The card in the nearest row above (-1) or below (1) a card, nearest it
## across; with no row there, `past`.
func _nearest(card: Button, way: float, past: Control) -> Control:
	var best: Control = past
	var row := INF
	var across := INF
	for other in _shown:
		var down := (other.position.y - card.position.y) * way
		if down <= 0.5:
			continue
		var off := absf(other.position.x - card.position.x)
		if down < row - 0.5 or absf(down - row) <= 0.5 and off < across:
			best = other
			row = down
			across = off
	return best


## Scrolled as little as keeps a card wholly in what shows, its heading too
## at its group's top.
func _show_card(card: Button) -> void:
	if card.position.y - HEAD < scroll:
		scroll = card.position.y - HEAD
	elif card.position.y + CARD.y > scroll + _view.size.y:
		scroll = card.position.y + CARD.y - _view.size.y


## The wheel scrolls what shows.
func _on_view_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		scroll += WHEEL * (-1.0 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0) * wheel.factor
		_view.accept_event()


## Down from the search goes to the groups, as it would from any word.
func _on_search_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down", true):
		_groups[_picked].grab_focus()
		_search.accept_event()


## A thing's card: its picture over its name, as the deeds' cards are drawn.
func _card(id: StringName) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"DeedCard"
	card.focus_mode = Control.FOCUS_ALL
	# The wheel over it reaches the grid.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
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
	var title := Label.new()
	title.theme_type_variation = &"DeedCardName"
	title.text = name_of(id)
	title.uppercase = true
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(title)
	card.mouse_entered.connect(func() -> void:
		_pointed = true
		card.grab_focus()
		_pointed = false)
	card.focus_entered.connect(func() -> void:
		Sounds.play(get_tree().root, Sounds.MENU_MOVE, Sounds.UI)
		if not _pointed:
			_show_card(card))
	card.pressed.connect(_take.bind(id))
	return card


func _take(id: StringName) -> void:
	Sounds.play(get_tree().root, Sounds.MENU_CONFIRM, Sounds.UI)
	say("%s %s" % [name_of(id), give(_world, id)])
