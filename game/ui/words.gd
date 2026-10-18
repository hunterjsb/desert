class_name Words
extends Control
## A menu as a few small words, low on the screen over the menu's desert and in
## the middle over a running game; or, for choosing a new run, bigger words
## down the left with a short line under each, the kit on show beside them.
## The highlighted word is bright and the rest dim, never boxed. Menu up and
## down move the highlight, confirm triggers it, and left and right change a
## setting's value, each with a very quiet click. The mouse can pick too.

## The highlight moved to the word at this place, or landed there on opening.
signal moved(at: int)

## The title's moon, across, and how far it stands off the name, as far as
## the name's letters stand apart, px.
const MOON := 32.0
const MOON_GAP := 22.0
## A word's line while another is highlighted, as a share of its brightness.
const UNLIT := 0.6

## Back never closes it: the main menu is the bottom of the stack.
var root := false
## The game's name over the words, on the main menu only.
var title: Label
## Over the menu's desert: the words a little bigger and roomier, low on the screen.
## Over a running game they stand in the middle.
var _main := false
## Down the left of the menu's desert, each word with its line under it.
var side := false

var _list: VBoxContainer
var _items: Array[Dictionary] = []
## The word last highlighted.
var _was := 0


## A question or a note above the words. Under them, a dark wash over the
## running game (Scrim), or only a shade low down over the menu's desert
## (Shade), or down its left side (ShadeSide).
func _init(note := "", under := &"Scrim") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Every click lands here, so none reaches the world to throw or look.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var wash := Panel.new()
	wash.theme_type_variation = under
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	if under == &"Shade":
		wash.anchor_top = 0.6
	elif under == &"ShadeSide":
		wash.anchor_right = 0.6
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	_main = under == &"Shade"
	side = under == &"ShadeSide"
	_list = VBoxContainer.new()
	_list.theme_type_variation = &"MenuListMain" if _main else &"MenuListSide" if side else &"MenuList"
	_list.anchor_left = 0.1 if side else 0.0
	_list.anchor_right = 0.5 if side else 1.0
	if _main:
		_list.anchor_top = 1.0
		_list.anchor_bottom = 1.0
		_list.offset_bottom = -64.0
		_list.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_list.alignment = BoxContainer.ALIGNMENT_END
	else:
		_list.anchor_top = 0.5
		_list.anchor_bottom = 0.5
		_list.grow_vertical = Control.GROW_DIRECTION_BOTH
		_list.alignment = BoxContainer.ALIGNMENT_CENTER
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list)
	if note != "":
		var line := Label.new()
		line.theme_type_variation = &"MenuNote"
		line.text = note
		line.uppercase = true
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(line)
		_list.add_child(Control.new())


## The game's name at the top of the screen in a light logo, a moon hung
## beside it as the prototype's had, under a high shade that keeps it
## readable over a bright sky: the main menu's.
func add_title(name: String) -> void:
	var shade := Panel.new()
	shade.theme_type_variation = &"ShadeHigh"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_bottom = 0.35
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	title = Label.new()
	title.theme_type_variation = &"MenuTitle"
	title.text = name
	title.uppercase = true
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 44.0
	var mark := Control.new()
	mark.anchor_top = 0.5
	mark.anchor_bottom = 0.5
	mark.offset_left = -MOON - MOON_GAP
	mark.offset_right = -MOON_GAP
	# Level with the capitals, which stand above the line's middle.
	mark.offset_top = -MOON * 0.5 - 2.0
	mark.offset_bottom = MOON * 0.5 - 2.0
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.draw.connect(_draw_moon.bind(mark))
	title.add_child(mark)
	add_child(title)


## A crescent lit over the dark of the rest, as the prototype's moon was.
static func _draw_moon(mark: Control) -> void:
	var middle := mark.size * 0.5
	var r := minf(mark.size.x, mark.size.y) * 0.5 - 1.0
	var lit := mark.get_theme_color(&"text", &"Palette")
	var dark := mark.get_theme_color(&"faint", &"Palette")
	var shadow := mark.get_theme_color(&"shadow", &"Palette")
	mark.draw_circle(middle + Vector2(0.0, 1.5), r + 1.0, Color(shadow, shadow.a * 0.5), true, -1.0, true)
	mark.draw_circle(middle, r, dark, true, -1.0, true)
	var disc := PackedVector2Array()
	var bite := PackedVector2Array()
	for i in 64:
		var way := Vector2.from_angle(TAU * i / 64.0)
		disc.append(middle + way * r)
		bite.append(middle + Vector2(r * 0.42, -r * 0.3) + way * r * 0.92)
	for crescent in Geometry2D.clip_polygons(disc, bite):
		mark.draw_colored_polygon(crescent, lit)
		mark.draw_polyline(crescent + PackedVector2Array([crescent[0]]), lit, 1.0, true)


## Something to read above the words, such as the controls list.
func add_body(body: Control) -> void:
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_list.add_child(body)
	_list.add_child(Control.new())


## A word: `text` is its words, or a Callable giving them as they stand now.
## Confirm runs `act`; left and right run `step` with -1 or 1, if it has one.
## Down the left, `line` is a few words under it, brighter while it's highlighted.
func add(text: Variant, act: Callable, step := Callable(), line := "") -> Button:
	var word := Button.new()
	word.theme_type_variation = &"MenuWordMain" if _main else &"MenuWordSide" if side else &"MenuWord"
	word.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if side else Control.SIZE_SHRINK_CENTER
	word.alignment = HORIZONTAL_ALIGNMENT_LEFT if side else HORIZONTAL_ALIGNMENT_CENTER
	word.focus_mode = Control.FOCUS_ALL
	var item := {"button": word, "text": text, "act": act, "step": step}
	_items.append(item)
	var under: Label = null
	if side:
		var pair := VBoxContainer.new()
		pair.theme_type_variation = &"Column"
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		under = Label.new()
		under.theme_type_variation = &"MenuLine"
		# A space keeps a word without a line as tall as one with.
		under.text = line if line != "" else " "
		under.uppercase = true
		under.modulate.a = UNLIT
		pair.add_child(word)
		pair.add_child(under)
		_list.add_child(pair)
	else:
		_list.add_child(word)
	if not act.is_valid():
		# Locked: shown, never highlighted.
		word.disabled = true
		word.focus_mode = Control.FOCUS_NONE
		_wrap()
		refresh()
		return word
	word.pressed.connect(func() -> void:
		_click(Sounds.MENU_CONFIRM)
		act.call()
		refresh())
	word.mouse_entered.connect(word.grab_focus)
	word.focus_entered.connect(func() -> void:
		# Opening or uncovering lands on the word it was on, silently.
		var at := _items.find(item)
		if at != _was:
			_click(Sounds.MENU_MOVE)
		_was = at
		if under != null:
			under.modulate.a = 1.0
		moved.emit(at))
	word.focus_exited.connect(func() -> void:
		if under != null:
			under.modulate.a = UNLIT)
	word.focus_exited.connect(_keep_focus, CONNECT_DEFERRED)
	word.gui_input.connect(func(event: InputEvent) -> void: _on_word_input(item, event))
	_wrap()
	refresh()
	return word


## The words as they stand now, settings with their values.
func refresh() -> void:
	for item in _items:
		var text: Variant = item.text
		var words: String = text.call() if text is Callable else text
		(item.button as Button).text = words.to_upper()


func words() -> PackedStringArray:
	var out := PackedStringArray()
	for item in _items:
		out.append((item.button as Button).text)
	return out


## Which word is highlighted, or -1.
func highlighted() -> int:
	for i in _items.size():
		if (_items[i].button as Button).has_focus():
			return i
	return -1


## The one last highlighted, or the first that can be.
func highlight() -> void:
	var open := _open()
	if open.is_empty():
		return
	var was: Button = _items[clampi(_was, 0, _items.size() - 1)].button
	(was if was in open else open[0]).grab_focus()


## Another menu opens over this one.
func cover() -> void:
	visible = false


func uncover() -> void:
	visible = true
	highlight()


## A click on nothing, or the window losing focus, never leaves the menu
## with no word highlighted.
func _keep_focus() -> void:
	if is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
		highlight()


## Up from the top word goes round to the bottom, and down from the bottom to
## the top, passing over a locked one.
func _wrap() -> void:
	var open := _open()
	for i in open.size():
		var word := open[i]
		word.focus_neighbor_top = word.get_path_to(open[i - 1])
		word.focus_neighbor_bottom = word.get_path_to(open[(i + 1) % open.size()])
		word.focus_neighbor_left = NodePath(".")
		word.focus_neighbor_right = NodePath(".")


## The words that can be highlighted, in order.
func _open() -> Array[Button]:
	var out: Array[Button] = []
	for item in _items:
		if item.act.is_valid():
			out.append(item.button)
	return out


func _on_word_input(item: Dictionary, event: InputEvent) -> void:
	var step: Callable = item.step
	if not step.is_valid():
		return
	for way in [[&"ui_left", -1], [&"ui_right", 1]]:
		if event.is_action_pressed(way[0], true):
			step.call(way[1])
			_click(Sounds.MENU_MOVE)
			refresh()
			accept_event()


## From the tree's root, so a click outlives the menu it closes.
func _click(stream: AudioStream) -> void:
	Sounds.play(get_tree().root, stream, Sounds.UI)
