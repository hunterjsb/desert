class_name Cutter
extends Device
## A heat cutter: held in your hands with use held down on a wreck's plate,
## its lance throws a hot spot onto the plate where you aim, and traced along
## a seam it cuts the weld away (Wreckage.cut). It runs on its own battery,
## drawing cutter_w only while it fires, and with the battery flat it does
## nothing. Firing, its beam reaches from its nozzle to the hot spot, the
## spot throws sparks and lights what's round it, and it roars.

## It keeps drawing, and its beam keeps showing, this long after the last
## tick it fired, s: a tick's gap in holding use doesn't drop either.
const DRAW_FOR := 0.12
## Its nozzle, in its own frame.
const NOZZLE := Vector3(0.0, 0.01, -0.26)

var _firing := 0.0
var _beam: MeshInstance3D
var _glow: OmniLight3D
var _sparks: CPUParticles3D
var _roar: AudioStreamPlayer3D
var _at := Vector3.ZERO


func _init() -> void:
	carryable = true


## Whether it can fire: powered, whole, with charge in it. Asking draws its
## power for a moment, as firing does.
func cuts() -> bool:
	_firing = DRAW_FOR
	return powered and not wrecked() and charge_share() > 0.0


func cutting() -> bool:
	return _firing > 0.0


## Fires at a point (the engine's frame) this tick: its beam, its hot spot,
## its sparks; `biting` when the spot is on a seam, which is when the sparks
## fly. Call cuts() first.
func fire(at: Vector3, biting: bool) -> void:
	_firing = DRAW_FOR
	_at = at
	_effects()
	_beam.visible = true
	_glow.visible = true
	_sparks.emitting = biting
	if not _roar.playing:
		_roar.play()


func demand_w(t := NAN) -> float:
	return super(t) + (Tuning.current().cutter_w if cutting() and not wrecked() else 0.0)


func _physics_process(delta: float) -> void:
	super(delta)
	_firing = maxf(_firing - delta, 0.0)
	if _beam == null:
		return
	if _firing <= 0.0:
		_beam.visible = false
		_glow.visible = false
		_sparks.emitting = false
		if _roar.playing:
			_roar.stop()
		return
	# The beam from its nozzle to the hot spot, flickering.
	var from := global_transform * NOZZLE
	var along := _at - from
	var long := along.length()
	if long < 0.01:
		return
	var y := along / long
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var flicker := 0.85 + 0.3 * randf()
	_beam.global_transform = Transform3D(Basis(x * 0.008 * flicker, y * long, x.cross(y) * 0.008 * flicker), from + along * 0.5)
	_glow.global_position = _at - y * 0.5
	_glow.light_energy = 0.22 * flicker
	_sparks.global_position = _at
	_sparks.direction = (-y + Vector3.UP * 0.3).normalized()


func _effects() -> void:
	if _beam != null:
		return
	_beam = MeshInstance3D.new()
	var tube := CylinderMesh.new()
	tube.top_radius = 0.5
	tube.bottom_radius = 0.5
	tube.height = 1.0
	tube.radial_segments = 6
	tube.rings = 1
	_beam.mesh = tube
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hot.albedo_color = Color(1.0, 0.5, 0.2, 0.45)
	hot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam.material_override = hot
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.top_level = true
	add_child(_beam)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.62, 0.3)
	_glow.omni_range = 1.6
	_glow.shadow_enabled = false
	_glow.top_level = true
	add_child(_glow)
	_sparks = ScrapFx.sparks()
	_sparks.top_level = true
	add_child(_sparks)
	_roar = Sounds.world_voice(Sounds.looping(Sounds.CUTTER), -6.0, 2.0)
	add_child(_roar)
