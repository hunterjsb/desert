class_name DeedsGrid
extends Control
## Every deed as a card in a tree (Deeds): a branch or two for each family,
## its name down the left, each deed right of the ones it waits on, a line
## from each to what it opens, narrow enough to stand left of the prop
## aside. Taller than the screen has room for, it shows a part of its page at
## a time, scrolled by the wheel, its bar beside it or the selection, and
## keeps the card highlighted in view.
## A card shows its name and its thing: lit once done, dimmer while open but
## not done, and a dark silhouette while what it waits on isn't done. A
## hidden deed is ???? with no picture until it shows done, though its place
## and the line to it show. The card highlighted, by the mouse or the menu's
## selection, has a small panel beside it saying what it asks, how far along
## you are, and what it opens. The selection starts on the deed done last,
## or with none done the first still to do. Opened, it's looked at: what was
## new in it isn't any more.

## A card, the picture on it, and the room round them: between a family's
## branches, between families, and between one deed and the next, where
## the lines run, px.
const CARD := Vector2(190.0, 58.0)
const ICON := 42.0
const GAP := 8.0
const FAMILY_GAP := 16.0
const STEP := 28.0
## The families in the order they stand, and their names down the left
## beside their branches, in a column this wide, px.
const FAMILIES := {&"board": "Board", &"wind": "Wind", &"weather": "Weather", &"camp": "Camp", &"farm": "Farming",
	&"ruins": "Ruins", &"scrap": "Scrap", &"signals": "Signals", &"far": "Far", &"story": "Story",
	&"nomad": "Nomad"}
const HEAD := 96.0
## The panel's width, how far it stands off its card, and how near the
## screen's edge it may come, px.
const TIP := 300.0
const TIP_OFF := 12.0
const TIP_EDGE := 16.0
## Of the screen's height, the most the tree shows at once; the rest scrolls,
## this far a notch of the wheel, px, keeping a highlighted card this far
## inside what shows.
const SHOWN := 0.66
const WHEEL := 70.0
const MARGIN := 12.0
## A deed open but not done, at this share of a done one's brightness; one
## still locked, only its thing's outline, faint.
const UNLIT := 0.55
const SILHOUETTE := "shader_type canvas_item;\nuniform vec4 ink : source_color;\n" \
	+ "void fragment() { COLOR = vec4(ink.rgb, texture(TEXTURE, UV).a * ink.a); }"

static var _shadow: ShaderMaterial

## How far down its page it's scrolled, px.
var scroll := 0.0:
	set(to):
		scroll = clampf(to, 0.0, maxf(_page.size.y - size.y, 0.0))
		_page.position.y = -scroll
		_bar.show_page(_page.size.y, size.y, scroll)

var _profile: Node
var _tuning: Tuning
## Everything it shows, as tall as all of it: the families, the cards and the
## lines between them.
var _page := Control.new()
var _bar := PageBar.new()
## Each deed's card, and where its middle stands, px.
var _cards := {}
var _at := {}
var _tip: PanelContainer
var _said: Array[Label] = []
## The card the panel stands beside.
var _told: Button


## The tree in a menu laid out for where it opens, and Back under it.
static func fill(words: Words, profile: Node, back: Callable) -> void:
	var tree := DeedsGrid.new(profile, Tuning.current())
	words.add_body(tree)
	var word := words.add("Back", back)
	word.focus_neighbor_top = word.get_path_to(tree.first())
	for id in Deeds.unseen(profile):
		profile.seen(id)


func _init(profile: Node, tuning: Tuning) -> void:
	_profile = profile
	_tuning = tuning
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_page.mouse_filter = Control.MOUSE_FILTER_PASS
	_page.draw.connect(_draw_lines)
	add_child(_page)
	_bar.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_bar.offset_left = -PageBar.ACROSS
	_bar.offset_right = 0.0
	_bar.moved.connect(func(at: float) -> void: scroll = at)
	add_child(_bar)
	_lay_out()
	# Over everything round it, so a scroll never cuts it off.
	_tip = PanelContainer.new()
	_tip.theme_type_variation = &"DeedTip"
	_tip.custom_minimum_size.x = TIP
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.top_level = true
	_tip.visible = false
	var column := VBoxContainer.new()
	column.theme_type_variation = &"Column"
	_tip.add_child(column)
	for kind: StringName in [&"DeedName", &"DeedLine", &"DeedOpens", &"DeedOpens"]:
		var label := Label.new()
		label.theme_type_variation = kind
		label.uppercase = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
		_said.append(label)
	add_child(_tip)


func _ready() -> void:
	custom_minimum_size = Vector2(_page.size.x + PageBar.ACROSS,
		minf(_page.size.y, get_viewport_rect().size.y * SHOWN))
	size = custom_minimum_size
	scroll = scroll
	# Over Back, which the menu highlights as it opens.
	_open.call_deferred()


## The wheel scrolls it.
func _gui_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		scroll += WHEEL * (-1.0 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0) * wheel.factor
		accept_event()


## The panel follows its card as the tree scrolls under it.
func _process(_delta: float) -> void:
	if _tip.visible and is_instance_valid(_told):
		_place_tip(_told)


## The first card, top left.
func first() -> Button:
	return _cards[Deeds.TABLE.keys()[0]]


## Where the selection starts: the deed done last, or with none done the
## first open and still to do.
func opening() -> Button:
	var last := &""
	var when := -INF
	var done: Dictionary = _profile.deeds() if _profile != null else {}
	for id: StringName in Deeds.TABLE:
		if Deeds.lit(_profile, id) and done[str(id)].get("at", 0.0) > when:
			last = id
			when = done[str(id)].get("at", 0.0)
	if last != &"":
		return _cards[last]
	for id: StringName in Deeds.TABLE:
		if Deeds.is_open(_profile, id):
			return _cards[id]
	return first()


## Opens on its card, scrolled to stand it in the middle of what shows.
func _open() -> void:
	if not is_inside_tree():
		return
	var card := opening()
	scroll = card.position.y + CARD.y * 0.5 - size.y * 0.5
	card.grab_focus()


## Each family a branch per deed at its widest step, each deed one step
## right of the furthest it waits on, under the others at its step.
func _lay_out() -> void:
	var depth := {}
	for id: StringName in Deeds.TABLE:
		var d := 0
		for before: StringName in Deeds.TABLE[id].get("after", []):
			d = maxi(d, depth[before] + 1)
		depth[id] = d
	var y := 0.0
	var deepest := 0
	for family: StringName in FAMILIES:
		var steps := {}
		for id: StringName in Deeds.TABLE:
			if Deeds.TABLE[id].family == family:
				steps[depth[id]] = steps.get(depth[id], []) + [id]
		var wide := 1
		for d: int in steps:
			wide = maxi(wide, steps[d].size())
			deepest = maxi(deepest, d)
			for k in steps[d].size():
				_at[steps[d][k]] = Vector2(HEAD + d * (CARD.x + STEP) + CARD.x * 0.5,
					y + k * (CARD.y + GAP) + CARD.y * 0.5)
		var tall := wide * (CARD.y + GAP) - GAP
		var head := Label.new()
		head.theme_type_variation = &"MenuNote"
		head.text = FAMILIES[family]
		head.uppercase = true
		head.size = Vector2(HEAD, tall)
		head.position = Vector2(0.0, y)
		head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_page.add_child(head)
		y += tall + FAMILY_GAP
	_page.size = Vector2(HEAD + (deepest + 1) * (CARD.x + STEP) - STEP, y - FAMILY_GAP)
	custom_minimum_size = _page.size
	for id: StringName in Deeds.TABLE:
		_cards[id] = _card(id)
		_page.add_child(_cards[id])


func _card(id: StringName) -> Button:
	var open := Deeds.is_open(_profile, id)
	var done := Deeds.lit(_profile, id)
	var shown := Deeds.revealed(_profile, id)
	var card := Button.new()
	card.theme_type_variation = &"DeedCard"
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size = CARD
	card.position = _at[id] - CARD * 0.5
	card.set_meta(&"deed", id)
	card.set_meta(&"state", &"done" if done else (&"open" if open else &"locked"))
	var row := HBoxContainer.new()
	row.theme_type_variation = &"DeedCardRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.modulate = Color.WHITE if done or not open else Color(UNLIT, UNLIT, UNLIT)
	card.add_child(row)
	var picture := picture(id, open, ICON) if shown else Control.new()
	picture.custom_minimum_size = Vector2(ICON, ICON)
	row.add_child(picture)
	var title := Label.new()
	title.theme_type_variation = &"DeedCardName"
	title.text = Deeds.TABLE[id].name if open and shown else "????"
	title.uppercase = true
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_FILL
	row.add_child(title)
	card.mouse_entered.connect(card.grab_focus)
	card.focus_entered.connect(_tell.bind(id))
	card.focus_exited.connect(func() -> void: _tip.visible = false)
	return card


## The panel beside a card: what it asks, how far along you are, and what it
## opens; locked, only what it waits on; hidden and not done, nothing it
## would give away.
func _tell(id: StringName) -> void:
	Sounds.play(get_tree().root, Sounds.MENU_MOVE, Sounds.UI)
	var spec: Dictionary = Deeds.TABLE[id]
	var lines := PackedStringArray(["????", "", "", ""])
	if not Deeds.revealed(_profile, id):
		pass
	elif Deeds.is_open(_profile, id):
		var record: Dictionary = _profile.deeds().get(str(id), {}) if _profile != null else {}
		var opens := PackedStringArray(Deeds.opens(id).map(func(k: Kit) -> String: return "opens the " + k.label))
		lines = PackedStringArray([spec.name, Deeds.line(id, _tuning),
			("done" + (" in Ironman" if record.get("ironman", false) else "")) if Deeds.lit(_profile, id)
				else Deeds.progress(_profile, id, _tuning), ", ".join(opens)])
	if not Deeds.is_open(_profile, id):
		var waits := PackedStringArray()
		for before: StringName in spec.get("after", []):
			if not Deeds.lit(_profile, before):
				waits.append(Deeds.TABLE[before].name if Deeds.is_open(_profile, before)
					and Deeds.revealed(_profile, before) else "????")
		lines[2] = "after " + " and ".join(waits)
	for i in _said.size():
		_said[i].text = lines[i]
		_said[i].visible = lines[i] != ""
	_told = _cards[id]
	_show_card(_told)
	_place_tip(_told)
	_tip.visible = true


## Scrolled as little as keeps a card wholly in what shows.
func _show_card(card: Button) -> void:
	if card.position.y - MARGIN < scroll:
		scroll = card.position.y - MARGIN
	elif card.position.y + CARD.y + MARGIN > scroll + size.y:
		scroll = card.position.y + CARD.y + MARGIN - size.y


## Beside the card, on whichever side has room on the screen, kept on it:
## as tall as its words wrap to now they've a width to wrap in.
func _place_tip(card: Button) -> void:
	_tip.reset_size()
	var at := card.get_global_rect()
	var room := get_viewport_rect().size
	var right := at.end.x + TIP_OFF + TIP < room.x
	_tip.position = Vector2(at.end.x + TIP_OFF if right else at.position.x - TIP_OFF - TIP,
		clampf(at.position.y, TIP_EDGE, maxf(room.y - _tip.size.y - TIP_EDGE, TIP_EDGE)))


## From each deed across to each it opens: brighter once it's open.
func _draw_lines() -> void:
	var lit := get_theme_color(&"dim", &"Palette")
	var faint := get_theme_color(&"faint", &"Palette")
	for id: StringName in Deeds.TABLE:
		for before: StringName in Deeds.TABLE[id].get("after", []):
			var from: Vector2 = _at[before] + Vector2(CARD.x * 0.5, 0.0)
			var to: Vector2 = _at[id] - Vector2(CARD.x * 0.5, 0.0)
			var bend := (from.x + to.x) * 0.5
			_page.draw_polyline(PackedVector2Array([from, Vector2(bend, from.y), Vector2(bend, to.y), to]),
				lit if Deeds.is_open(_profile, id) else faint, 2.0, true)


## A deed's card's picture, `across` px: its thing's look, or a mark drawn;
## only an outline while it's locked.
static func picture(id: StringName, open: bool, across: float) -> Control:
	var shown: Control
	var icon: StringName = Deeds.TABLE[id].get("icon", &"landmark")
	if ItemIcons.LOOKS.has(icon):
		var look := TextureRect.new()
		look.texture = ItemIcons.of(Engine.get_main_loop(), icon)
		look.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		look.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not open:
			look.material = _silhouette()
		shown = look
	else:
		shown = Control.new()
		shown.draw.connect(_draw_mark.bind(shown, icon, not open))
	shown.custom_minimum_size = Vector2(across, across)
	shown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shown


## Its thing's shape alone, in the theme's faint ink.
static func _silhouette() -> ShaderMaterial:
	if _shadow == null:
		var shader := Shader.new()
		shader.code = SILHOUETTE
		_shadow = ShaderMaterial.new()
		_shadow.shader = shader
		_shadow.set_shader_parameter(&"ink", ThemeDB.get_project_theme().get_color(&"faint", &"Palette"))
	return _shadow


## A mark drawn in the theme's ink, faint while locked, where no thing fits:
## a landmark's mast with its pennant, a sail, a storm's wall, an anomaly's
## eye, a ruin bared, a wreck, a mast's signal, the eclipse, a glint, a vent
## and its boom, Tu overhead, the dark side's stars, the sun's days, bearings
## crossing, the living city's decks and the Walker.
static func _draw_mark(on: Control, mark: StringName, locked: bool) -> void:
	var ink := on.get_theme_color(&"faint" if locked else &"text", &"Palette")
	var s := on.size
	var c := s * 0.5
	var u := s.x
	var foot := Vector2(c.x, s.y * 0.88)
	var top := Vector2(c.x, s.y * 0.12)
	var ground := func() -> void: on.draw_line(Vector2(u * 0.12, foot.y), Vector2(u * 0.88, foot.y), ink, 2.0, true)
	match mark:
		&"sail":
			ground.call()
			var boom := Vector2(c.x, s.y * 0.74)
			on.draw_line(boom + Vector2(0.0, s.y * 0.14), top, ink, 3.0, true)
			on.draw_colored_polygon(PackedVector2Array([top + Vector2(4.0, 4.0), boom + Vector2(4.0, -2.0),
				boom + Vector2(u * 0.34, -2.0)]), ink)
			on.draw_line(boom, boom + Vector2(u * 0.36, 0.0), ink, 2.0, true)
		&"storm":
			# A wall of dust rolling in over the sand.
			ground.call()
			var wall := PackedVector2Array([Vector2(u * 0.12, foot.y)])
			for k in 7:
				var a := PI * k / 6.0
				wall.append(Vector2(u * (0.2 + 0.06 * k), s.y * (0.3 + 0.12 * sin(a * 3.0) * (1.0 - k / 7.0))))
			wall.append(Vector2(u * 0.6, foot.y))
			on.draw_colored_polygon(wall, ink)
			for k in 3:
				var y := s.y * (0.45 + 0.13 * k)
				on.draw_line(Vector2(u * 0.66, y), Vector2(u * 0.88, y), ink, 2.0, true)
		&"eye":
			# An anomaly's heart: rings closing on a dark eye.
			for k in 3:
				on.draw_arc(c, u * (0.38 - 0.11 * k), 0.0, TAU, 32, ink, 2.0, true)
			on.draw_circle(c, u * 0.07, ink)
		&"dune":
			# A dune's slip face, and a ruin's roof in its lee.
			ground.call()
			on.draw_colored_polygon(PackedVector2Array([Vector2(u * 0.08, foot.y), Vector2(u * 0.5, s.y * 0.22),
				Vector2(u * 0.66, s.y * 0.26), Vector2(u * 0.8, foot.y)]), ink)
			on.draw_rect(Rect2(u * 0.74, s.y * 0.7, u * 0.18, foot.y - s.y * 0.7), ink)
		&"ruin":
			# Broken walls standing out of a dune.
			for x: Array in [[0.24, 0.42], [0.42, 0.22], [0.66, 0.34]]:
				on.draw_rect(Rect2(u * x[0] - u * 0.06, s.y * x[1], u * 0.12, foot.y - s.y * x[1]), ink)
			on.draw_colored_polygon(PackedVector2Array([Vector2(u * 0.08, foot.y), Vector2(u * 0.3, s.y * 0.7),
				Vector2(u * 0.55, s.y * 0.78), Vector2(u * 0.92, foot.y)]), ink)
		&"wreck":
			# A hull nosed into the sand.
			ground.call()
			var hull := Transform2D(-0.35, Vector2(c.x, s.y * 0.62))
			on.draw_set_transform_matrix(hull)
			on.draw_colored_polygon(PackedVector2Array([Vector2(-u * 0.36, -s.y * 0.1), Vector2(u * 0.22, -s.y * 0.12),
				Vector2(u * 0.38, 0.0), Vector2(u * 0.22, s.y * 0.1), Vector2(-u * 0.36, s.y * 0.08)]), ink)
			on.draw_line(Vector2(-u * 0.1, -s.y * 0.12), Vector2(-u * 0.2, -s.y * 0.26), ink, 2.0, true)
			on.draw_set_transform_matrix(Transform2D.IDENTITY)
		&"signal":
			# A mast sending: arcs either side of its head.
			ground.call()
			var head := Vector2(c.x, s.y * 0.36)
			on.draw_line(foot, head, ink, 3.0, true)
			for k in 3:
				var r := u * (0.12 + 0.1 * k)
				on.draw_arc(head, r, -PI * 0.25, PI * 0.25, 12, ink, 2.0, true)
				on.draw_arc(head, r, PI * 0.75, PI * 1.25, 12, ink, 2.0, true)
		&"eclipse":
			# Tu dark before the sun, its ring of fire round its limb.
			on.draw_arc(c, u * 0.34, 0.0, TAU, 40, ink, 3.0, true)
			on.draw_circle(c, u * 0.27, ink * Color(1.0, 1.0, 1.0, 0.35))
			for k in 8:
				var a := TAU * k / 8.0
				on.draw_line(c + Vector2.from_angle(a) * u * 0.4, c + Vector2.from_angle(a) * u * 0.46, ink, 2.0, true)
		&"glint":
			# A sparkle far off on the skyline.
			ground.call()
			var at := Vector2(c.x, s.y * 0.45)
			on.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -u * 0.32), at + Vector2(u * 0.06, -u * 0.06),
				at + Vector2(u * 0.32, 0.0), at + Vector2(u * 0.06, u * 0.06), at + Vector2(0.0, u * 0.32),
				at + Vector2(-u * 0.06, u * 0.06), at + Vector2(-u * 0.32, 0.0), at + Vector2(-u * 0.06, -u * 0.06)]), ink)
		&"vent", &"boom":
			# A vent's rampart and the plume it breathes; booming, the sound's arcs.
			on.draw_colored_polygon(PackedVector2Array([Vector2(u * 0.1, foot.y), Vector2(u * 0.36, s.y * 0.62),
				Vector2(u * 0.44, s.y * 0.66), Vector2(u * 0.56, s.y * 0.66), Vector2(u * 0.64, s.y * 0.62),
				Vector2(u * 0.9, foot.y)]), ink)
			for k in 3:
				on.draw_circle(Vector2(c.x + u * (0.04 * k - 0.02), s.y * (0.5 - 0.15 * k)), u * (0.07 + 0.03 * k), ink)
			if mark == &"boom":
				for k in 2:
					var r := u * (0.3 + 0.12 * k)
					on.draw_arc(Vector2(c.x, s.y * 0.35), r, -PI * 0.2, PI * 0.2, 10, ink, 2.0, true)
					on.draw_arc(Vector2(c.x, s.y * 0.35), r, PI * 0.8, PI * 1.2, 10, ink, 2.0, true)
		&"tu":
			# Tu straight overhead, its bands across it.
			on.draw_circle(c, u * 0.34, ink * Color(1.0, 1.0, 1.0, 0.5))
			on.draw_arc(c, u * 0.34, 0.0, TAU, 40, ink, 2.0, true)
			for k in 3:
				var y := (k - 1) * u * 0.12
				var half := sqrt(maxf(pow(u * 0.34, 2.0) - y * y, 0.0))
				on.draw_line(c + Vector2(-half, y), c + Vector2(half, y), ink, 2.0, true)
		&"dark":
			# Stars over a horizon Tu never clears.
			ground.call()
			on.draw_arc(Vector2(c.x, foot.y), u * 0.26, PI, TAU, 24, ink * Color(1.0, 1.0, 1.0, 0.4), 2.0, true)
			for at: Vector2 in [Vector2(0.2, 0.2), Vector2(0.5, 0.14), Vector2(0.78, 0.26), Vector2(0.34, 0.42),
					Vector2(0.66, 0.5)]:
				on.draw_circle(Vector2(u * at.x, s.y * at.y), u * 0.03, ink)
		&"bearings":
			# Three lines from three places crossing at one.
			var at := Vector2(c.x + u * 0.08, s.y * 0.3)
			for from: Vector2 in [Vector2(0.12, 0.86), Vector2(0.5, 0.9), Vector2(0.9, 0.78)]:
				var stood := Vector2(u * from.x, s.y * from.y)
				on.draw_line(stood, stood + (at - stood) * 1.25, ink, 2.0, true)
				on.draw_circle(stood, u * 0.035, ink)
			on.draw_arc(at, u * 0.09, 0.0, TAU, 16, ink, 2.0, true)
		&"city":
			# A raft's decks dark against their glow, lamps along them, a turbine.
			on.draw_circle(Vector2(c.x, s.y * 0.66), u * 0.3, ink * Color(1.0, 1.0, 1.0, 0.3))
			for deck: Array in [[0.12, 0.62, 0.3, 0.26], [0.36, 0.52, 0.3, 0.36], [0.62, 0.6, 0.28, 0.28]]:
				on.draw_rect(Rect2(u * deck[0], s.y * deck[1], u * deck[2], s.y * deck[3]), ink)
			on.draw_line(Vector2(u * 0.48, s.y * 0.52), Vector2(u * 0.48, s.y * 0.14), ink, 2.0, true)
			for k in 3:
				on.draw_line(Vector2(u * 0.48, s.y * 0.14), Vector2(u * 0.48, s.y * 0.14) + Vector2.from_angle(TAU * k / 3.0 - 0.3) * u * 0.14, ink, 2.0, true)
			for k in 7:
				on.draw_circle(Vector2(u * (0.16 + 0.11 * k), s.y * (0.5 + 0.06 * (k % 2))), u * 0.022, ink)
		&"walker":
			# A legged walker on its route, its mast up.
			ground.call()
			on.draw_rect(Rect2(u * 0.28, s.y * 0.38, u * 0.44, s.y * 0.16), ink)
			on.draw_line(Vector2(u * 0.6, s.y * 0.38), Vector2(u * 0.64, s.y * 0.14), ink, 2.0, true)
			for k in 3:
				var hip := Vector2(u * (0.32 + 0.18 * k), s.y * 0.5)
				var knee := hip + Vector2(u * (0.06 * (k - 1)), -s.y * 0.1)
				on.draw_line(hip, knee + Vector2(0.0, 0.0), ink, 2.0, true)
				on.draw_line(knee, Vector2(knee.x + u * 0.04 * (k - 1), foot.y if k != 0 else foot.y - s.y * 0.1), ink, 2.0, true)
		&"sun":
			# The sun up over the horizon, its rays: the days.
			ground.call()
			var sun := Vector2(c.x, foot.y)
			on.draw_arc(sun, u * 0.2, PI, TAU, 20, ink, 3.0, true)
			for k in 5:
				var a := PI + PI * (k + 1) / 6.0
				on.draw_line(sun + Vector2.from_angle(a) * u * 0.28, sun + Vector2.from_angle(a) * u * 0.4, ink, 2.0, true)
		_:
			ground.call()
			on.draw_line(foot, top, ink, 3.0, true)
			for k in 3:
				var y := lerpf(foot.y, top.y, 0.25 + k * 0.2)
				var half := u * (0.16 - k * 0.04)
				on.draw_line(Vector2(foot.x - half, y), Vector2(foot.x + half, y), ink, 2.0, true)
			on.draw_colored_polygon(PackedVector2Array([top, top + Vector2(u * 0.26, s.y * 0.07),
				top + Vector2(0.0, s.y * 0.14)]), ink)
