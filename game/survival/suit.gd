class_name Suit
extends Node
## The suit: the one gift this world gives you. Its air and its shielding from
## the sun's radiation are built in and free, with no power and no bar. It
## carries a few slots, all you carry besides your hands and your waist, and
## feeds you from the water and food in them. The inventory action opens a
## small view of the slots and your waist; while it's open, looking picks a
## slot instead of turning you, and take puts what you hold into it or takes
## what's in it into your hands. It hears take before your hands do, being
## after them under you.

## Built in and free, so nothing ever drains them.
const BUILT_IN := "air, radiation"
## What a new suit carries: a run starts on sealed water and a ration.
const KIT: Array[StringName] = [&"canister", &"ration"]
## Looking this far across, px, picks the next slot.
const PICK_PX := 80.0
const SLOT := Vector2(100.0, 40.0)
const GAP := 6.0

## What each slot holds, or null. Stowed things wait off the tree, as fitted
## parts do.
var slots: Array[Part] = []
var open := false
var picked := 0

var _player: Player
var _drift := 0.0
var _layer: CanvasLayer
var _view: Control


func _ready() -> void:
	_player = get_parent() as Player
	slots.resize(Tuning.current().suit_slots)
	_layer = CanvasLayer.new()
	_layer.layer = 98
	_layer.visible = false
	add_child(_layer)
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	_layer.add_child(_view)
	restock()


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


## Take, while the view is open: what you hold goes into the picked slot, or
## the first free one; empty-handed, what's in the picked slot comes to your
## hands. Says whether it did anything.
func take_or_put() -> bool:
	var hands := _player.hands
	if hands.held != null:
		if hands.phase != Hands.Phase.HELD or not fits(hands.held):
			return false
		var at := picked if slots[picked] == null else slots.find(null)
		if at == -1:
			return false
		var part := hands.stow() as Part
		part.get_parent().remove_child(part)
		slots[at] = part
		hands.clunk()
		return true
	var part := slots[picked]
	if part == null:
		return false
	slots[picked] = null
	_player.world.content.add_child(part)
	part.global_transform = _player.camera.global_transform.translated_local(Vector3(0.0, -0.2, -0.5))
	hands.hold(part)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		open = not open
		_layer.visible = open
		get_viewport().set_input_as_handled()
	elif not open:
		return
	elif event is InputEventMouseMotion:
		_drift += event.relative.x
		while absf(_drift) >= PICK_PX:
			picked = posmod(picked + (1 if _drift > 0.0 else -1), slots.size())
			_drift -= signf(_drift) * PICK_PX
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_grab") and _player.hands.grasp.body == null and take_or_put():
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if open:
		_view.queue_redraw()


## A row of slots low in the middle of the view, the picked one lit, and
## what's at your waist under it.
func _draw_view() -> void:
	var font := ThemeDB.fallback_font
	var size := _view.get_rect().size
	var row := slots.size() * SLOT.x + (slots.size() - 1) * GAP
	var corner := Vector2((size.x - row) * 0.5, size.y * 0.68)
	for i in slots.size():
		var box := Rect2(corner + Vector2(i * (SLOT.x + GAP), 0.0), SLOT)
		_view.draw_rect(box, Color(0.0, 0.0, 0.0, 0.6 if i == picked else 0.4))
		_view.draw_rect(box, Color(1.0, 1.0, 1.0, 1.0 if i == picked else 0.25), false, 2.0 if i == picked else 1.0)
		var part := slots[i]
		if part != null:
			_text(font, box.position + Vector2(5.0, 15.0), part.label, SLOT.x - 10.0)
			_text(font, box.position + Vector2(5.0, 31.0), _brief(part), SLOT.x - 10.0)
	var tied := PackedStringArray()
	for body in _player.waist.tied:
		if is_instance_valid(body):
			tied.append(str(body.get(&"label")))
	_text(font, corner + Vector2(0.0, SLOT.y + 16.0), "waist: " + (", ".join(tied) if not tied.is_empty() else "-"), row)
	_text(font, corner + Vector2(0.0, SLOT.y + 30.0), "take puts in or takes out · look across to pick", row)


func _text(font: Font, at: Vector2, line: String, width: float) -> void:
	_view.draw_string_outline(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, 11, 4, Color.BLACK)
	_view.draw_string(font, at, line, HORIZONTAL_ALIGNMENT_LEFT, width, 11, Color.WHITE)


## What's in a part that you'd want to know at a glance.
static func _brief(part: Part) -> String:
	if part is Supply:
		return ("%.2f L" if part.kind == &"water" else "%d kcal") % part.amount
	if part is Battery:
		return "%d Wh" % floori(part.charge_wh)
	return ""
