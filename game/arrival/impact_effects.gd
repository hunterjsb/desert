class_name ArrivalImpactEffects
extends Control
## Saved phase time drives glass effects and one bounded recoil, never a new impact event.

var camera_offset := Vector3.ZERO
var camera_rotation := Vector3.ZERO
var _rules: Dictionary
var _look := ShaderMaterial.new()

func setup(tuning: Tuning) -> void:
	_rules = tuning.surveyor_arrival
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
func present(state: Dictionary, aperture: Rect2) -> void:
	var phase: StringName = state.get("phase", &"recovery")
	var elapsed := maxf(float(state.get("elapsed", 0.0)), 0.0)
	var progress := clampf(float(state.get("progress", 0.0)), 0.0, 1.0)
	var landing := phase == &"landing"
	visible = phase == &"entry" or landing
	var recoil := _pulse(elapsed, float(_rules.get("impact_jolt_s", 0.0))) if landing else 0.0
	camera_offset = Vector3(0.0, -0.35, 1.0).normalized() * recoil * float(_rules.get("impact_offset_m", 0.0))
	camera_rotation = Vector3(-deg_to_rad(float(_rules.get("impact_tilt_deg", 0.0))) * recoil, 0.0, 0.0)
	var dust_seconds := float(_rules.get("impact_dust_s", 0.0))
	var dust := 1.0 - smoothstep(0.0, dust_seconds, elapsed) if landing and dust_seconds > 0.0 else 0.0
	var heat := smoothstep(0.0, 1.0, progress) if phase == &"entry" else dust
	_look.set_shader_parameter(&"aperture", Vector4(aperture.position.x, aperture.position.y, aperture.size.x, aperture.size.y))
	_look.set_shader_parameter(&"heat", heat * float(_rules.get("entry_heat", 0.0)))
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
