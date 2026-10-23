class_name ArrivalImpactEffects
extends Control
## Saved phase time drives glass effects and one bounded recoil, never a new impact event.

var camera_offset := Vector3.ZERO
var camera_rotation := Vector3.ZERO
var _rules: Tuning
var _look := ShaderMaterial.new()

func setup(tuning: Tuning) -> void:
	_rules = tuning
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_look.shader = preload("res://game/arrival/impact_effects.gdshader")
	_look.set_shader_parameter(&"sand", tuning.sand_color)
	var glass := ColorRect.new()
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.material = _look
	add_child(glass)
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()

## Aperture is a normalized screen rectangle; the cabin outside it stays readable.
func present(state: Dictionary, aperture: Rect2, windows: Array[Rect2] = [], corners := PackedVector2Array()) -> void:
	var phase: StringName = state.get("phase", &"recovery")
	var elapsed := maxf(float(state.get("elapsed", 0.0)), 0.0)
	var progress := clampf(float(state.get("progress", 0.0)), 0.0, 1.0)
	var landing := phase == &"landing"
	visible = phase == &"entry" or landing
	var recoil := _pulse(elapsed, _rules.arrival_impact_jolt_s) if landing else 0.0
	camera_offset = Vector3(0.0, -0.35, 1.0).normalized() * recoil * _rules.arrival_impact_offset_m
	camera_rotation = Vector3(-deg_to_rad(_rules.arrival_impact_tilt_deg) * recoil, 0.0, 0.0)
	var flying := [&"ejection", &"descent", &"entry"].find(phase)
	if flying >= 0:
		var share: float = _rules.arrival_sway_share[flying]
		var envelope := sin(PI * progress)
		if phase == &"entry":
			var fade := _rules.arrival_entry_fade
			envelope = smoothstep(0.0, fade.x, progress) * (1.0 - smoothstep(fade.y, 1.0, progress))
		var rates := _rules.arrival_sway_hz
		var sway := Vector3(sin(elapsed * TAU * rates.x), sin(elapsed * TAU * rates.y), sin(elapsed * TAU * rates.z)) / sqrt(3.0)
		camera_offset = sway * _rules.arrival_sway_m * share * envelope
		camera_rotation = Vector3(sway.y, sway.x, sway.z) * deg_to_rad(_rules.arrival_sway_deg) * share * envelope
	var dust_seconds := _rules.arrival_impact_dust_s
	var dust := 1.0 - smoothstep(0.0, dust_seconds, elapsed) if landing and dust_seconds > 0.0 else 0.0
	var heat := smoothstep(0.0, 1.0, progress) if phase == &"entry" else dust
	_look.set_shader_parameter(&"aperture", Vector4(aperture.position.x, aperture.position.y, aperture.size.x, aperture.size.y))
	var masks := PackedVector4Array()
	for window in windows:
		if window.has_area() and masks.size() < PodShell.VIEWPORTS.size():
			masks.append(Vector4(window.position.x, window.position.y, window.size.x, window.size.y))
	_look.set_shader_parameter(&"window_count", masks.size())
	while masks.size() < PodShell.VIEWPORTS.size():
		masks.append(Vector4.ZERO)
	_look.set_shader_parameter(&"windows", masks)
	var points := corners.duplicate()
	while points.size() < PodShell.VIEWPORTS.size() * 4:
		points.append(Vector2.ZERO)
	_look.set_shader_parameter(&"window_corners", points)
	_look.set_shader_parameter(&"heat", heat * _rules.arrival_entry_heat)
	_look.set_shader_parameter(&"dust", dust)
	_look.set_shader_parameter(&"passage", elapsed)

## One lobe peaks at a quarter of its duration and returns with zero end velocity.
static func _pulse(elapsed: float, duration: float) -> float:
	if duration <= 0.0 or elapsed >= duration:
		return 0.0
	var t := clampf(elapsed / duration, 0.0, 1.0)
	return (256.0 / 27.0) * t * pow(1.0 - t, 3.0)

func dispose() -> void:
	camera_offset = Vector3.ZERO
	camera_rotation = Vector3.ZERO
	hide()
	queue_free()
