class_name CloseUp
extends Camera3D
## Fine-tuning brings the radio up close, and with dial_close_up on, any
## tuning does (it's off: gonkhub would rather the rest didn't zoom). Turn a radio's dial or its volume, or
## sweep it, and the view eases in to its face, near it and through a
## narrower lens, so its band, needle and knobs fill the view; it eases back
## out once you've stopped tuning a while, or look away. A camera of its own,
## so your aim stays your own eyes': look off the radio and it lets go.

## The close view meets the face no more than this far off square, rad, so
## the band reads; nearer your own line of sight than that, it keeps yours.
const SLANT := PI / 6.0
## Nor nearer the sand than this, m.
const CLEAR := 0.12

## The radio the view closes in on, or null, and how far in it is, 0 to 1.
var radio: Receiver
var close := 0.0

var _player: Player
var _tuning := Tuning.current()
var _since := INF
var _controls: RichTextLabel


func _ready() -> void:
	_player = get_parent() as Player
	top_level = true
	# After your hands draw what you hold, so a radio in them is framed where it's drawn.
	process_priority = 10
	_build_controls()


## The tuning actions just worked this radio, finely or not. Only the fine
## steps bring the view in (gonkhub, 2026-10-19: "Bring back the pov zoom when
## using fine-tune shift scrolling"), unless dial_close_up has every tuning
## action do it.
func tuned(by: Receiver, fine := false) -> void:
	if not fine and not _tuning.dial_close_up:
		return
	radio = by
	_since = 0.0


func _process(delta: float) -> void:
	var eye := _player.camera
	_since += delta
	if radio != null and not (is_instance_valid(radio) and radio.is_inside_tree()):
		radio = null
		close = 0.0
	var keep := radio != null and _since < _tuning.dial_close_hold and Controls.playing() \
		and _player.hands.dial() == radio
	close = move_toward(close, 1.0 if keep else 0.0, delta / maxf(_tuning.dial_close_seconds, 0.001))
	_controls.visible = close > 0.0 and Controls.playing()
	_controls.modulate.a = close
	if _controls.visible:
		_controls.text = controls_text()
	if close <= 0.0:
		radio = null
		if current:
			eye.make_current()
		return
	var k := smoothstep(0.0, 1.0, close)
	global_transform = _between(eye.global_transform, _framing(eye.global_position), k)
	fov = lerpf(eye.fov, _tuning.dial_close_fov, k)
	near = eye.near
	far = eye.far
	compositor = eye.compositor
	if not current:
		make_current()


## The close view: dial_close_m off the radio's face, square on to it or as
## near your own line of sight as SLANT allows, its up the set's own so the
## band reads level.
func _framing(from: Vector3) -> Transform3D:
	var face := radio.face()
	var out := face.basis.z.normalized()
	var toward := (from - face.origin).normalized()
	var off := out.angle_to(toward)
	var way := out if off < 1e-4 or off > PI - 0.01 else out.slerp(toward, minf(SLANT / off, 1.0))
	var at := face.origin + way * _tuning.dial_close_m
	at.y = maxf(at.y, _player.world.height_under(at) + CLEAR)
	return Transform3D(Basis.looking_at(face.origin - at, face.basis.y.normalized()), at)


## Partway from your eyes to the close view, swung round the set, never through it.
func _between(from: Transform3D, to: Transform3D, k: float) -> Transform3D:
	var middle := radio.face().origin
	var a := from.origin - middle
	var b := to.origin - middle
	var way := b.normalized() if a.angle_to(b) > PI - 0.01 else a.normalized().slerp(b.normalized(), k)
	return Transform3D(from.basis.orthonormalized().slerp(to.basis, k), middle + way * lerpf(a.length(), b.length(), k))


## The dial remains the focus; reminders live below it only while tuning.
func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = &"RadioTuningControls"
	layer.layer = 98
	add_child(layer)
	_controls = Controls.keys_label()
	_controls.theme_type_variation = &"KeysList"
	_controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_controls.offset_top = -44.0
	_controls.offset_bottom = -44.0
	_controls.visible = false
	layer.add_child(_controls)


func controls_text() -> String:
	var lines := ["{reel_in} / {pay_out}  tune",
		"{tune_fine_up} / {tune_fine_down}  fine tune",
		"{volume_up} / {volume_down}  volume"]
	if is_instance_valid(radio) and radio.has_dial_marks():
		lines.append("{mark_frequency}  mark / unmark    {interact}  next mark")
	return "[center]%s[/center]" % Controls.bbcode("\n".join(lines))
