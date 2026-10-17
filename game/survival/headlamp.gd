class_name Headlamp
extends SpotLight3D
## The suit's headlamp, built in and free like its air: no power and no bar.
## Its own action switches it, for now (Hunter, 2026-10-17: "have b toggle
## the headlamp"), so your tracks can be followed when nothing else lights the
## sand. Warm and modest, so a camp's lamps and a bubble's glow still feel like
## home. It lights only the screen: nothing in the world reads it.

## Whether it's on: off as a run begins, switched by the headlamp action.
var on := false
## How lit it is, 0 to 1, fading as it comes on and goes off.
var level := 0.0

var _tuning := Tuning.current()


func _ready() -> void:
	light_color = Color(1.0, 0.88, 0.7)
	spot_range = _tuning.headlamp_range
	spot_attenuation = _tuning.headlamp_falloff
	spot_angle = _tuning.headlamp_angle
	spot_angle_attenuation = _tuning.headlamp_edge
	rotation_degrees.x = -_tuning.headlamp_tilt
	# The thing in your hands would throw its shadow down the beam.
	shadow_enabled = false
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("headlamp") and Controls.playing():
		on = not on
		get_viewport().set_input_as_handled()


## By the tick, fading on and off.
func _physics_process(delta: float) -> void:
	level = move_toward(level, 1.0 if on else 0.0, delta / _tuning.headlamp_fade_seconds)
	light_energy = _tuning.headlamp_energy * level
	visible = level > 0.0
	Dev.put("survival/lamp", "%d%%" % roundi(level * 100.0))
