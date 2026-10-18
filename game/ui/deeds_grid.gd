class_name DeedsGrid
extends Control
## Every deed as a card in a tree (Deeds): a column or two for each family,
## each deed below the ones it waits on, a line from each to what it opens.
## A card shows its name and its thing: lit once done, dimmer while open but
## not done, and a dark silhouette while what it waits on isn't done. The
## card highlighted, by the mouse or the menu's selection, has a small panel
## beside it saying what it asks, how far along you are, and what it opens.

## A card, the picture on it, and the room round them, px.
const CARD := Vector2(164.0, 176.0)
const ICON := 92.0
const GAP := 14.0
const FAMILY_GAP := 46.0
const ROW_GAP := 52.0
## The families' names over their columns, and how tall that row is, px.
const FAMILIES := {&"board": "Board", &"shield": "Shield", &"farm": "Farming", &"camp": "Camp", &"story": "Story"}
const HEAD := 30.0
## The panel's width, and how far it stands off its card, px.
const TIP := 300.0
const TIP_OFF := 12.0
## A deed open but not done, at this share of a done one's brightness; one
## still locked, only its thing's outline, faint.
const UNLIT := 0.55
const SILHOUETTE := "shader_type canvas_item;\nuniform vec4 ink : source_color;\n" \
	+ "void fragment() { COLOR = vec4(ink.rgb, texture(TEXTURE, UV).a * ink.a); }"

static var _shadow: ShaderMaterial

var _profile: Node
var _tuning: Tuning
## Each deed's card, and where its middle stands, px.
var _cards := {}
var _at := {}
var _tip: PanelContainer
var _said: Array[Label] = []


## The deeds' own menu: how many you've done over the tree, and Back.
static func menu(profile: Node, back: Callable) -> Words:
	var words := Words.new("%d of %d deeds" % [Deeds.count(profile), Deeds.TABLE.size()])
	var tree := DeedsGrid.new(profile, Tuning.current())
	words.add_body(tree)
	var word := words.add("Back", back)
	word.focus_neighbor_top = word.get_path_to(tree.first())
	return words


func _init(profile: Node, tuning: Tuning) -> void:
	_profile = profile
	_tuning = tuning
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lay_out()
	_tip = PanelContainer.new()
	_tip.theme_type_variation = &"DeedTip"
	_tip.custom_minimum_size.x = TIP
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# Over Back, which the menu highlights as it opens.
	first().grab_focus.call_deferred()


## The first card, where the selection starts.
func first() -> Button:
	return _cards[Deeds.TABLE.keys()[0]]


## Each family a column per deed at its widest depth, each deed one row
## below the deepest it waits on, beside the others at its depth.
func _lay_out() -> void:
	var depth := {}
	for id: StringName in Deeds.TABLE:
		var d := 0
		for before: StringName in Deeds.TABLE[id].get("after", []):
			d = maxi(d, depth[before] + 1)
		depth[id] = d
	var x := 0.0
	var deepest := 0
	for family: StringName in FAMILIES:
		var rows := {}
		for id: StringName in Deeds.TABLE:
			if Deeds.TABLE[id].family == family:
				rows[depth[id]] = rows.get(depth[id], []) + [id]
		var wide := 1
		for d: int in rows:
			wide = maxi(wide, rows[d].size())
			deepest = maxi(deepest, d)
			for k in rows[d].size():
				_at[rows[d][k]] = Vector2(x + k * (CARD.x + GAP) + CARD.x * 0.5,
					HEAD + d * (CARD.y + ROW_GAP) + CARD.y * 0.5)
		var head := Label.new()
		head.theme_type_variation = &"MenuNote"
		head.text = FAMILIES[family]
		head.uppercase = true
		head.position = Vector2(x, 0.0)
		add_child(head)
		x += wide * (CARD.x + GAP) - GAP + FAMILY_GAP
	custom_minimum_size = Vector2(x - FAMILY_GAP, HEAD + (deepest + 1) * (CARD.y + ROW_GAP) - ROW_GAP)
	for id: StringName in Deeds.TABLE:
		_cards[id] = _card(id)
		add_child(_cards[id])


func _card(id: StringName) -> Button:
	var open := Deeds.is_open(_profile, id)
	var done := Deeds.lit(_profile, id)
	var card := Button.new()
	card.theme_type_variation = &"DeedCard"
	card.focus_mode = Control.FOCUS_ALL
	card.size = CARD
	card.position = _at[id] - CARD * 0.5
	card.set_meta(&"deed", id)
	card.set_meta(&"state", &"done" if done else (&"open" if open else &"locked"))
	var column := VBoxContainer.new()
	column.theme_type_variation = &"DeedCardColumn"
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.modulate = Color.WHITE if done or not open else Color(UNLIT, UNLIT, UNLIT)
	card.add_child(column)
	var picture: Control
	var icon: StringName = Deeds.TABLE[id].get("icon", &"landmark")
	if ItemIcons.LOOKS.has(icon):
		var shown := TextureRect.new()
		shown.texture = ItemIcons.of(Engine.get_main_loop(), icon)
		shown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not open:
			shown.material = _silhouette()
		picture = shown
	else:
		picture = Control.new()
		picture.draw.connect(_draw_mark.bind(picture, icon, not open))
	picture.custom_minimum_size = Vector2(ICON, ICON)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	var title := Label.new()
	title.theme_type_variation = &"DeedCardName"
	title.text = Deeds.TABLE[id].name if open and not (Deeds.TABLE[id].get("hidden", false) and not done) else "????"
	title.uppercase = true
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	card.mouse_entered.connect(card.grab_focus)
	card.focus_entered.connect(_tell.bind(id))
	card.focus_exited.connect(func() -> void: _tip.visible = false)
	return card


## The panel beside a card: what it asks, how far along you are, and what it
## opens; locked, only what it waits on.
func _tell(id: StringName) -> void:
	Sounds.play(get_tree().root, Sounds.MENU_MOVE, Sounds.UI)
	var spec: Dictionary = Deeds.TABLE[id]
	var lines := PackedStringArray(["????", "", "", ""])
	if Deeds.is_open(_profile, id):
		var record: Dictionary = _profile.deeds().get(str(id), {}) if _profile != null else {}
		var opens := PackedStringArray(Deeds.opens(id).map(func(k: Kit) -> String: return "opens the " + k.label))
		lines = PackedStringArray([spec.name, Deeds.line(id, _tuning),
			("done" + (" in Ironman" if record.get("ironman", false) else "")) if Deeds.lit(_profile, id)
				else Deeds.progress(_profile, id, _tuning), ", ".join(opens)])
	else:
		var waits := PackedStringArray()
		for before: StringName in spec.get("after", []):
			if not Deeds.lit(_profile, before):
				waits.append(Deeds.TABLE[before].name if Deeds.is_open(_profile, before) else "????")
		lines[2] = "after " + " and ".join(waits)
	for i in _said.size():
		_said[i].text = lines[i]
		_said[i].visible = lines[i] != ""
	_tip.reset_size()
	# Beside the card, on whichever side has room on the screen.
	var card: Button = _cards[id]
	var room := get_viewport_rect().size.x
	var right := card.global_position.x + CARD.x + TIP_OFF + TIP < room
	_tip.position = Vector2(card.position.x + CARD.x + TIP_OFF if right else card.position.x - TIP_OFF - TIP,
		card.position.y)
	_tip.visible = true
	move_child(_tip, -1)


## From each deed down to each it opens: brighter once it's open.
func _draw() -> void:
	var lit := get_theme_color(&"dim", &"Palette")
	var faint := get_theme_color(&"faint", &"Palette")
	for id: StringName in Deeds.TABLE:
		for before: StringName in Deeds.TABLE[id].get("after", []):
			var from: Vector2 = _at[before] + Vector2(0.0, CARD.y * 0.5)
			var to: Vector2 = _at[id] - Vector2(0.0, CARD.y * 0.5)
			var bend := (from.y + to.y) * 0.5
			draw_polyline(PackedVector2Array([from, Vector2(from.x, bend), Vector2(to.x, bend), to]),
				lit if Deeds.is_open(_profile, id) else faint, 2.0, true)


## Its thing's shape alone, in the theme's faint ink.
static func _silhouette() -> ShaderMaterial:
	if _shadow == null:
		var shader := Shader.new()
		shader.code = SILHOUETTE
		_shadow = ShaderMaterial.new()
		_shadow.shader = shader
		_shadow.set_shader_parameter(&"ink", ThemeDB.get_project_theme().get_color(&"faint", &"Palette"))
	return _shadow


## A mark drawn in the theme's ink, faint while locked: a landmark's mast on
## the skyline with its pennant, or a sail on its mast.
static func _draw_mark(on: Control, mark: StringName, locked: bool) -> void:
	var ink := on.get_theme_color(&"faint" if locked else &"text", &"Palette")
	var s := on.size
	var foot := Vector2(s.x * 0.5, s.y * 0.88)
	var top := Vector2(s.x * 0.5, s.y * 0.12)
	on.draw_line(Vector2(s.x * 0.2, foot.y), Vector2(s.x * 0.8, foot.y), ink, 2.0, true)
	if mark == &"sail":
		var boom := Vector2(s.x * 0.5, s.y * 0.74)
		on.draw_line(boom + Vector2(0.0, s.y * 0.14), top, ink, 3.0, true)
		on.draw_colored_polygon(PackedVector2Array([top + Vector2(4.0, 4.0), boom + Vector2(4.0, -2.0),
			boom + Vector2(s.x * 0.34, -2.0)]), ink)
		on.draw_line(boom, boom + Vector2(s.x * 0.36, 0.0), ink, 2.0, true)
		return
	on.draw_line(foot, top, ink, 3.0, true)
	for k in 3:
		var y := lerpf(foot.y, top.y, 0.25 + k * 0.2)
		var half := s.x * (0.16 - k * 0.04)
		on.draw_line(Vector2(foot.x - half, y), Vector2(foot.x + half, y), ink, 2.0, true)
	on.draw_colored_polygon(PackedVector2Array([top, top + Vector2(s.x * 0.26, s.y * 0.07),
		top + Vector2(0.0, s.y * 0.14)]), ink)
