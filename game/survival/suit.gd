class_name Suit
extends Node
## The suit: the one gift this world gives you. Its air and its shielding from
## the sun's radiation are built in and free, with no power and no bar. It
## carries a few slots, all you carry besides your hands and your waist, and
## feeds you from the water and food in them. The inventory action opens a
## small view of the slots and your waist and frees the mouse to click them:
## a slot with something in it gives it to your empty hands, an empty one
## takes what you hold, and a full one swaps with it. Closing it captures the
## mouse again, to look.

## Built in and free, so nothing ever drains them.
const BUILT_IN := "air, radiation"
## What a new suit carries: a run starts on sealed water and a ration.
const KIT: Array[StringName] = [&"canister", &"ration"]
const HINT := "click a slot to take out, put in or swap · {inventory} closes"
const SLOT := Vector2(100.0, 40.0)
const GAP := 6.0

## What each slot holds, or null. Stowed things wait off the tree, as fitted
## parts do.
var slots: Array[Part] = []
var open := false
## The slot under the mouse, or -1.
var hover := -1

var _player: Player
var _layer: CanvasLayer
var _view: Control


func _ready() -> void:
	_player = get_parent() as Player
	add_to_group(UIRoot.PANELS)
	slots.resize(Tuning.current().suit_slots)
	_layer = CanvasLayer.new()
	_layer.layer = 98
	_layer.visible = false
	add_child(_layer)
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Open, it takes every click, so none reaches the world to throw or look.
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_draw_view)
	_view.gui_input.connect(_on_view_input)
	_view.mouse_exited.connect(func() -> void: hover = -1)
	_layer.add_child(_view)
	restock()


func _exit_tree() -> void:
	# A run ending with the view open leaves the next one looking.
	if open:
		show_view(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for part in slots:
			if part != null:
				part.free()


## A fresh suit's slots: the kit, and nothing else.
func restock() -> void:
	for i in slots.size():
		if slots[i] != null:
			slots[i].free()
		slots[i] = Catalog.part(KIT[i]) if i < KIT.size() else null


## Whether a slot can take it: a part with nothing fastened to it, since a
## line or a wire would lose its end.
func fits(body: Object) -> bool:
	var part := body as Part
	return part != null and not part.has_meta(&"line") and part.kind != &"port"


## Of the water or the food in your slots, the least full that isn't empty,
## so one runs out and frees its canister before the next is opened.
func supply(kind: StringName) -> Supply:
	var best: Supply = null
	for part in slots:
		var it := part as Supply
		if it != null and it.kind == kind and it.amount > 0.0 and (best == null or it.amount < best.amount):
			best = it
	return best


## All the water, L, or food, kcal, in your slots.
func stock(kind: StringName) -> float:
	var total := 0.0
	for part in slots:
		if part is Supply and part.kind == kind:
			total += part.amount
	return total


## A ration eaten to the end is gone, from a slot or your hands.
func discard(part: Part) -> void:
	var at := slots.find(part)
	if at == -1:
		part.queue_free()
		return
	slots[at] = null
	part.free()


## The view open, the mouse free to click its slots; or closed, and the
## mouse captured to look.
func show_view(to: bool) -> void:
	open = to
	hover = -1
	_layer.visible = to
	Controls.free_mouse(to)


## Back closes the view first, before any menu. Says whether it was open.
func close() -> bool:
	if not open:
		return false
	show_view(false)
	return true


## A slot clicked: empty-handed, what's in it comes to your hands; holding
## something that fits, it goes in, swapping with what's there. Says whether
## it did anything.
func click(at: int) -> bool:
	var hands := _player.hands
	if at < 0 or at >= slots.size() or hands.grasp.body != null:
		return false
	var out := slots[at]
	if hands.held != null:
		if hands.phase != Hands.Phase.HELD or not fits(hands.held):
			return false
		var part := hands.stow() as Part
		part.get_parent().remove_child(part)
		slots[at] = part
		hands.clunk()
	elif out != null:
		slots[at] = null
	else:
		return false
	if out != null:
		_player.world.content.add_child(out)
		out.global_transform = _player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5))
		hands.hold(out)
	return true


## Where a slot is drawn, and clicked, in the view.
func slot_rect(at: int) -> Rect2:
	var size := _view.get_rect().size
	var row := slots.size() * SLOT.x + (slots.size() - 1) * GAP
	return Rect2(Vector2((size.x - row) * 0.5 + at * (SLOT.x + GAP), size.y * 0.68), SLOT)


func _slot_at(point: Vector2) -> int:
	for i in slots.size():
		if slot_rect(i).has_point(point):
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		show_view(not open)
		get_viewport().set_input_as_handled()


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover = _slot_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hover = _slot_at(event.position)
		click(hover)
	_view.accept_event()


func _process(_delta: float) -> void:
	if open:
		_view.queue_redraw()


## A row of slots low in the middle of the view, the one under the mouse
## lit, and what's at your waist under it.
func _draw_view() -> void:
	var corner := slot_rect(0).position
	var row := slot_rect(slots.size() - 1).end.x - corner.x
	var panel := _view.get_theme_color(&"panel", &"Palette")
	for i in slots.size():
		var box := slot_rect(i)
		_view.draw_rect(box, panel)
		_view.draw_rect(box, _view.get_theme_color(&"text" if i == hover else &"faint", &"Palette"), false,
			2.0 if i == hover else 1.0)
		var part := slots[i]
		if part != null:
			_text(&"Label", box.position + Vector2(5.0, 15.0), part.label, SLOT.x - 10.0)
			_text(&"Readout", box.position + Vector2(5.0, 31.0), _brief(part), SLOT.x - 10.0)
	var tied := PackedStringArray()
	for body in _player.waist.tied:
		if is_instance_valid(body):
			tied.append(str(body.get(&"label")))
	_text(&"Label", corner + Vector2(0.0, SLOT.y + 16.0), "waist: " + (", ".join(tied) if not tied.is_empty() else "-"), row)
	Controls.draw_keys(_view, corner + Vector2(0.0, SLOT.y + 30.0), HINT)


## In the theme: names as text, amounts as a readout.
func _text(type: StringName, at: Vector2, line: String, width: float) -> void:
	var font := _view.get_theme_font(&"font", type)
	var size := _view.get_theme_font_size(&"font_size", type)
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, size,
		_view.get_theme_constant(&"outline_size", &"Label"), _view.get_theme_color(&"shadow", &"Palette"))
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, size, _view.get_theme_color(&"text", &"Palette"))


## What's in a part that you'd want to know at a glance.
static func _brief(part: Part) -> String:
	if part is Supply:
		return ("%.2f L" if part.kind == &"water" else "%d kcal") % part.amount
	if part is Battery:
		return "%d Wh" % floori(part.charge_wh)
	if part is Plant:
		return "%d%% grown" % floori(part.growth * 100.0)
	return ""
