class_name Headlamp
extends SpotLight3D
## The suit's headlamp, built in and free like its air: no power, no bar, no
## switch. It comes on by itself as the light round you fails, at dusk or deep
## in a storm, and goes off again by day, so your tracks can be followed when
## nothing else lights the sand. Warm and modest, so a camp's lamps and a
## bubble's glow still feel like home. It lights only the screen: nothing in
## the world reads it.

## Whether it's on, by the light round you past either threshold.
var on := false
## How lit it is, 0 to 1, fading as it comes on and goes off.
var level := 0.0

var _player: Player
var _tuning := Tuning.current()


func _ready() -> void:
	_player = owner as Player
	light_color = Color(1.0, 0.88, 0.7)
	spot_range = _tuning.headlamp_range
	spot_attenuation = _tuning.headlamp_falloff
	spot_angle = _tuning.headlamp_angle
	spot_angle_attenuation = _tuning.headlamp_edge
	rotation_degrees.x = -_tuning.headlamp_tilt
	# The thing in your hands would throw its shadow down the beam.
	shadow_enabled = false
	visible = false


## By the tick, as the light it reads is.
func _physics_process(delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	var light := world.weather.seen_light
	on = _tuning.headlamp and light < (_tuning.headlamp_off_above if on else _tuning.headlamp_on_below)
	level = move_toward(level, 1.0 if on else 0.0, delta / _tuning.headlamp_fade_seconds)
	light_energy = _tuning.headlamp_energy * level
	visible = level > 0.0
	Dev.put("survival/lamp", "%d%%" % roundi(level * 100.0))
