class_name DeedBadge
extends PanelContainer
## A deed just done, shown a moment over the game: its card's picture and
## name under a quiet word, with a sound of its own. Several done at once
## wait their turn, so each is seen and heard alone.

## Coming up, held and going, then the pause before the next, s.
const IN_SECONDS := 0.35
const HOLD_SECONDS := 3.5
const OUT_SECONDS := 0.8
const BETWEEN_SECONDS := 0.4
## Its picture, across, px, and how far down the screen it stands: under the
## notes and how-tos at the top, which can come with it.
const PICTURE := 64.0
const TOP := 0.2
## It rises this far into place as it comes up, px.
const RISE := 10.0

## The deed showing, or none.
var showing := &""
var _waiting: Array[StringName] = []
var _row: HBoxContainer
var _name: Label


func _init() -> void:
	theme_type_variation = &"DeedBadge"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sized to what it holds, centred under TOP.
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = TOP
	anchor_bottom = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	modulate.a = 0.0
	visible = false
	_row = HBoxContainer.new()
	_row.theme_type_variation = &"DeedBadgeRow"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	var words := VBoxContainer.new()
	words.theme_type_variation = &"Column"
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(words)
	var word := Label.new()
	word.theme_type_variation = &"DeedBadgeWord"
	word.text = "Deed done"
	word.uppercase = true
	words.add_child(word)
	_name = Label.new()
	_name.theme_type_variation = &"DeedName"
	_name.uppercase = true
	words.add_child(_name)


## Shows it now, or after those before it.
func add(id: StringName) -> void:
	if id == showing or id in _waiting:
		return
	_waiting.append(id)
	if showing == &"":
		_next()


func _next() -> void:
	if _row.get_child_count() > 1:
		_row.get_child(0).free()
	if _waiting.is_empty():
		showing = &""
		visible = false
		return
	showing = _waiting.pop_front()
	var picture := DeedsGrid.picture(showing, true, PICTURE)
	_row.add_child(picture)
	_row.move_child(picture, 0)
	_name.text = Deeds.TABLE[showing].name
	visible = true
	Sounds.play(get_tree().root, Sounds.DEED, Sounds.UI)
	offset_top = RISE
	offset_bottom = RISE
	var shown := create_tween()
	shown.tween_property(self, "modulate:a", 1.0, IN_SECONDS)
	for side in ["offset_top", "offset_bottom"]:
		shown.parallel().tween_property(self, side, 0.0, IN_SECONDS).set_ease(Tween.EASE_OUT) \
			.set_trans(Tween.TRANS_CUBIC)
	shown.tween_interval(HOLD_SECONDS)
	shown.tween_property(self, "modulate:a", 0.0, OUT_SECONDS)
	shown.tween_interval(BETWEEN_SECONDS)
	shown.tween_callback(_next)
