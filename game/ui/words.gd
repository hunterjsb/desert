class_name Words
extends Control
## A menu as a few small words low on the screen, over whatever is behind
## them. The highlighted word is bright and the rest dim, never boxed. Menu up
## and down move the highlight, confirm triggers it, and left and right change
## a setting's value. The mouse can pick too.

## Back never closes it: the main menu is the bottom of the stack.
var root := false

var _list: VBoxContainer
var _items: Array[Dictionary] = []
## The word last highlighted.
var _was := 0


## A question or a note above the words. Under them, a dark wash over the
## running game (Scrim), or only a shade low down, over the menu's desert (Shade).
func _init(note := "", under := &"Scrim") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Every click lands here, so none reaches the world to throw or look.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var wash := Panel.new()
	wash.theme_type_variation = under
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	if under == &"Shade":
		wash.anchor_top = 0.6
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	_list = VBoxContainer.new()
	_list.theme_type_variation = &"MenuList"
	_list.anchor_left = 0.0
	_list.anchor_right = 1.0
	_list.anchor_top = 1.0
	_list.anchor_bottom = 1.0
	_list.offset_bottom = -56.0
	_list.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_list.alignment = BoxContainer.ALIGNMENT_END
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


## Something to read above the words, such as the controls list.
func add_body(body: Control) -> void:
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_list.add_child(body)
	_list.add_child(Control.new())


## A word: `text` is its words, or a Callable giving them as they stand now.
## Confirm runs `act`; left and right run `step` with -1 or 1, if it has one.
func add(text: Variant, act: Callable, step := Callable()) -> Button:
	var word := Button.new()
	word.theme_type_variation = &"MenuWord"
	word.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	word.focus_mode = Control.FOCUS_ALL
	var item := {"button": word, "text": text, "act": act, "step": step}
	_items.append(item)
	word.pressed.connect(func() -> void:
		act.call()
		refresh())
	word.mouse_entered.connect(word.grab_focus)
	word.focus_entered.connect(func() -> void: _was = _items.find(item))
	word.focus_exited.connect(_keep_focus, CONNECT_DEFERRED)
	word.gui_input.connect(func(event: InputEvent) -> void: _on_word_input(item, event))
	_list.add_child(word)
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


## The first word, or the one last highlighted.
func highlight() -> void:
	if not _items.is_empty():
		(_items[clampi(_was, 0, _items.size() - 1)].button as Button).grab_focus()


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


## Up from the top word goes round to the bottom, and down from the bottom to the top.
func _wrap() -> void:
	for i in _items.size():
		var word: Button = _items[i].button
		word.focus_neighbor_top = word.get_path_to(_items[i - 1].button)
		word.focus_neighbor_bottom = word.get_path_to(_items[(i + 1) % _items.size()].button)
		word.focus_neighbor_left = NodePath(".")
		word.focus_neighbor_right = NodePath(".")


func _on_word_input(item: Dictionary, event: InputEvent) -> void:
	var step: Callable = item.step
	if not step.is_valid():
		return
	for way in [[&"ui_left", -1], [&"ui_right", 1]]:
		if event.is_action_pressed(way[0], true):
			step.call(way[1])
			refresh()
			accept_event()
