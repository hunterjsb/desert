class_name CityLights
extends Node3D
## What you see of the living city: nothing by day, and at night, within its
## chatter's few km, its lights. Lamps along its decks and in its shields, the
## glow its decks throw up, and against it the silhouettes of its rafts of
## chassis, its turbines' masts and rotors, its people: never a face. A
## storm between hides it, and come within city_douse_m its lights go out:
## it isn't found by walking up to it. Seeing them is The Living City.

const SHADER := preload("res://game/radio/city_lights.gdshader")
## Its rafts spread this far either side of its line and along it, m.
const WIDE := 55.0
const LONG := 130.0
const DECKS := 18
const TIERS := 8
const TURBINES := 5
const SHIELDS := 3
const FIGURES := 26
const WARM := Color(1.0, 0.62, 0.28)
const SHIELD := Color(0.55, 0.75, 1.0)
const DECK_GLOW := Color(0.16, 0.08, 0.03)
const INK := Color(0.012, 0.011, 0.012)
## Its lamps fade in over this much of the edge of its range, m, and out
## over this much short of its dousing.
const FADE_IN := 500.0
const FADE_OUT := 100.0
## How often what's between you and it is read again, s; the deed looks
## this often too, at its middle and either end this high, where its upper
## decks' lamps hang, m, over the dunes at this many points.
const LOOK_EVERY := 0.5
const LAMPS_HIGH := 12.0
const SIGHT_STEPS := 24

## How much of it shows now, 0 to 1: night, range and dousing; and past the
## storms between.
var shown := 0.0
var veil := 1.0

var _world: World
var _tuning: Tuning
var _ink: MultiMeshInstance3D
var _lamps: MultiMeshInstance3D
var _look: ShaderMaterial
var _built_for: LivingCity
var _looked_at := -INF


func _ready() -> void:
	_world = World.of(self)
	_tuning = Tuning.current()
	_look = ShaderMaterial.new()
	_look.shader = SHADER
	_look.set_shader_parameter("haze", Vector3(_tuning.haze_begin, _tuning.haze_end, _tuning.haze_strength))
	visible = false


func _process(_delta: float) -> void:
	if _world == null or _world.shape == null:
		return
	var city := Radio.gods_of(_world).city
	if city != _built_for:
		_build(city)
	var t := _world.time
	var q := city.at(t)
	var at := Walker.ground(_world, q)
	var eye := _world.player.camera.global_position
	var middle := Vector3(_world.engine_x(at.x), 0.0, _world.engine_z(at.y))
	var far := Vector2(middle.x - eye.x, middle.z - eye.z).length()
	var moon := _world.moon
	var sun := _world.weather.day.sun_direction(t, moon.latitude, moon.longitude)
	var heard := _tuning.city_heard_m.y
	shown = smoothstep(0.02, -0.06, sun.y) * (1.0 - smoothstep(heard - FADE_IN, heard, far)) \
		* smoothstep(_tuning.city_douse_m, _tuning.city_douse_m + FADE_OUT, far)
	visible = shown > 0.0
	if not visible:
		return
	var leg := city.leg(t)
	var heading := Sphere.bearing(leg[0], leg[3])
	var ahead := Walker.ground(_world, Sphere.toward(q, heading, 100.0 / _world.shape.history.radius)) - at
	var yaw := atan2(-ahead.x, -ahead.y) if ahead.length() > 1e-3 else 0.0
	var sand := FarRing.ground(_world.shape, _tuning, at.x, at.y)
	global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(middle.x, sand, middle.z))
	if t >= _looked_at + LOOK_EVERY or t < _looked_at:
		_looked_at = t
		_look_over(eye)
	_look.set_shader_parameter("shown", shown)
	_look.set_shader_parameter("veil", veil)


## The storms between you and it, and whether you see its lights now:
## in view, over the dunes and past the storms.
func _look_over(eye: Vector3) -> void:
	var field := _world.weather.field
	var to := global_position + Vector3(0.0, LAMPS_HIGH, 0.0)
	var from := Vector3(_world.world_x(eye.x), eye.y, _world.world_z(eye.z))
	var far := Vector3(_world.world_x(to.x), to.y, _world.world_z(to.z))
	veil = Plume.seen_through(field, _tuning, from, far, _world.time) * (1.0 - _world.weather.seen_storm)
	if shown > 0.5 and veil > 0.5 and Deeds.waiting(_world, &"living_city"):
		for along: float in [0.0, -LONG, LONG]:
			if sees(_world, eye, to + global_basis.z * along):
				Deeds.done(_world, &"living_city")
				return


## Whether a place far off is in your view and over the dunes from your eye.
static func sees(world: World, eye: Vector3, to: Vector3) -> bool:
	var camera := world.player.camera
	if not camera.is_position_in_frustum(to):
		return false
	for i in range(1, SIGHT_STEPS):
		var at := eye.lerp(to, float(i) / SIGHT_STEPS)
		if world.shape.height_at(world.world_x(at.x), world.world_z(at.z)) > at.y:
			return false
	return true


## Its rafts, masts and people as silhouettes, its lamps and glows, laid out
## from the seed: the same city every time.
func _build(city: LivingCity) -> void:
	_built_for = city
	for child in get_children():
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([city.run_seed, "city look"])
	var ink: Array[Array] = []
	var lamps: Array[Array] = []
	var tops: Array[Array] = []
	for i in DECKS:
		var size := Vector3(rng.randf_range(14.0, 36.0), rng.randf_range(2.5, 7.0), rng.randf_range(14.0, 40.0))
		var at := Vector3(rng.randf_range(-WIDE, WIDE), 0.0, rng.randf_range(-LONG, LONG))
		ink.append([size, at + Vector3(0.0, size.y * 0.5, 0.0)])
		tops.append([at, size])
		lamps.append([at + Vector3(0.0, size.y + 4.0, 0.0), DECK_GLOW, maxf(size.x, size.z) * 1.4, 1.0])
		if i < TIERS:
			var upper := Vector3(size.x * rng.randf_range(0.4, 0.7), rng.randf_range(3.0, 7.0), size.z * rng.randf_range(0.4, 0.7))
			ink.append([upper, at + Vector3(0.0, size.y + upper.y * 0.5, 0.0)])
			tops.append([at + Vector3(0.0, size.y, 0.0), upper])
	for each: Array in tops:
		var at: Vector3 = each[0]
		var size: Vector3 = each[1]
		for k in rng.randi_range(3, 8):
			# Lamps hung along a deck's edge, and lit openings down its sides.
			var side := rng.randi() % 4
			var along := rng.randf_range(-0.5, 0.5)
			var edge := Vector3(along * size.x, 0.0, (0.5 if side == 0 else -0.5) * size.z) if side < 2 \
				else Vector3((0.5 if side == 2 else -0.5) * size.x, 0.0, along * size.z)
			var high := size.y + rng.randf_range(0.4, 2.0) if k % 3 != 2 else rng.randf_range(0.3, 0.8) * size.y
			lamps.append([at + edge * 1.01 + Vector3(0.0, high, 0.0), WARM * rng.randf_range(0.6, 1.0),
				rng.randf_range(0.6, 1.6), 0.0])
	for i in TURBINES:
		var on: Array = tops[rng.randi() % tops.size()]
		var foot: Vector3 = on[0] + Vector3(0.0, (on[1] as Vector3).y, 0.0)
		var tall := rng.randf_range(26.0, 40.0)
		ink.append([Vector3(0.8, tall, 0.8), foot + Vector3(0.0, tall * 0.5, 0.0)])
		var hub := foot + Vector3(0.0, tall, 0.0)
		var turn := rng.randf() * TAU
		for blade in 3:
			var spin := Basis(Vector3.RIGHT, turn + blade * TAU / 3.0)
			ink.append([Vector3(0.3, 11.0, 0.8), hub + spin * Vector3(0.0, 5.5, 0.0), spin])
		lamps.append([hub + Vector3(0.0, 0.8, 0.0), Color(1.0, 0.25, 0.15), 0.8, 0.0])
	for i in SHIELDS:
		var on: Array = tops[rng.randi() % tops.size()]
		var dome: Vector3 = on[0] + Vector3(rng.randf_range(-0.3, 0.3) * on[1].x, on[1].y + 1.0, 0.0)
		ink.append([Vector3(3.0, 2.0, 3.0), dome])
		lamps.append([dome + Vector3(0.0, 1.4, 0.0), SHIELD, 1.4, 0.0])
		lamps.append([dome + Vector3(0.0, 3.0, 0.0), SHIELD * 0.18, 30.0, 1.0])
	for i in FIGURES:
		var on: Array = tops[rng.randi() % tops.size()]
		var size: Vector3 = on[1]
		var spot := Vector3(rng.randf_range(-0.45, 0.45) * size.x, size.y + 0.9, (0.5 if rng.randf() < 0.5 else -0.5) * size.z * 0.95)
		ink.append([Vector3(0.5, 1.8, 0.4), on[0] + spot])
	_ink = _many(ink, _silhouette(), BoxMesh.new())
	var quad := QuadMesh.new()
	_lamps = _many(lamps, _look, quad, true)


static func _silhouette() -> StandardMaterial3D:
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = INK
	dark.disable_fog = true
	return dark


## One multimesh of boxes ([size, middle, turn]) or lamps ([at, colour, size, glow]).
func _many(rows: Array[Array], look: Material, mesh: PrimitiveMesh, lit := false) -> MultiMeshInstance3D:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = lit
	many.use_custom_data = lit
	many.mesh = mesh
	many.instance_count = rows.size()
	for i in rows.size():
		var row: Array = rows[i]
		if lit:
			many.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * row[2]), row[0]))
			many.set_instance_color(i, row[1])
			many.set_instance_custom_data(i, Color(row[3], 0.0, 0.0, 0.0))
		else:
			var turn: Basis = row[2] if row.size() > 2 else Basis.IDENTITY
			many.set_instance_transform(i, Transform3D(turn * Basis.from_scale(row[0]), row[1]))
	var view := MultiMeshInstance3D.new()
	view.multimesh = many
	view.material_override = look
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	return view
