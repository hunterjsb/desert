class_name ScrapFx
extends RefCounted
## What scrapping a wreck throws off, to see: the cutter's sparks where its
## hot spot bites a seam, a scoop's spray of packed sand, a breached store's
## mist, and the shower of sparks a capacitor bank lets go. Particles in the
## world's frame, cheap, and gone when they're done.

static var _dot: GradientTexture2D
static var _looks := {}


## Its materials, made while the world loads.
static func prepare() -> void:
	_look(true)
	_look(false)


## The cutter's sparks: a spray off a seam, falling and fading from white
## to red. Set `emitting` while it cuts; it follows where it's put.
static func sparks() -> CPUParticles3D:
	var made := _particles(24, 0.5, false, Color(1.0, 0.85, 0.5), Color(1.0, 0.3, 0.05, 0.0), true, 0.03)
	made.direction = Vector3.BACK
	made.spread = 55.0
	made.initial_velocity_min = 1.5
	made.initial_velocity_max = 3.5
	made.gravity = Vector3.DOWN * 6.0
	made.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	made.emission_sphere_radius = 0.01
	return made


## A burst of sparks at a point: a bank shorting out, a plate cut through.
static func burst(parent: Node, at: Vector3, count := 40, speed := 3.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var made := sparks()
	made.amount = count
	made.one_shot = true
	made.explosiveness = 0.95
	made.direction = Vector3.UP
	made.spread = 180.0
	made.initial_velocity_min = speed * 0.4
	made.initial_velocity_max = speed
	parent.add_child(made)
	made.global_position = at
	made.emitting = true
	made.finished.connect(made.queue_free)


## A scoop's throw of packed sand off a slice, out toward you.
static func spray(parent: Node, at: Vector3, toward: Vector3, sand: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var made := _particles(14, 0.7, true, Color(sand, 0.8), Color(sand, 0.0), false, 0.1)
	made.direction = toward.normalized() + Vector3.UP * 0.6
	made.spread = 35.0
	made.initial_velocity_min = 0.8
	made.initial_velocity_max = 1.8
	made.gravity = Vector3.DOWN * 9.0
	made.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	made.emission_sphere_radius = 0.08
	parent.add_child(made)
	made.global_position = at
	made.emitting = true
	made.finished.connect(made.queue_free)


## A breached store's seep: a thin sickly mist rising off it and hanging.
static func mist() -> CPUParticles3D:
	var made := _particles(10, 3.0, false, Color(0.62, 0.68, 0.4, 0.35), Color(0.55, 0.6, 0.35, 0.0), false, 0.35)
	made.local_coords = true
	made.direction = Vector3.UP
	made.spread = 25.0
	made.initial_velocity_min = 0.04
	made.initial_velocity_max = 0.12
	made.gravity = Vector3.ZERO
	made.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	made.emission_sphere_radius = 0.06
	made.emitting = true
	return made


## Particles of quads `size` m across, varied down to half that.
static func _particles(amount: int, lifetime: float, burst: bool, from: Color, to: Color, glowing: bool,
		size := 0.05) -> CPUParticles3D:
	var made := CPUParticles3D.new()
	made.amount = amount
	made.lifetime = lifetime
	made.one_shot = burst
	made.explosiveness = 1.0 if burst else 0.0
	made.emitting = false
	made.local_coords = false
	var fade := Gradient.new()
	fade.set_color(0, from)
	fade.set_color(1, to)
	made.color_ramp = fade
	var grain := QuadMesh.new()
	grain.size = Vector2.ONE * size
	grain.material = _look(glowing)
	made.mesh = grain
	made.scale_amount_min = 0.5
	made.scale_amount_max = 1.0
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


static func _look(glowing: bool) -> StandardMaterial3D:
	if not _looks.has(glowing):
		if _dot == null:
			var round := Gradient.new()
			round.set_color(0, Color.WHITE)
			round.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
			_dot = GradientTexture2D.new()
			_dot.gradient = round
			_dot.fill = GradientTexture2D.FILL_RADIAL
			_dot.fill_from = Vector2(0.5, 0.5)
			_dot.fill_to = Vector2(0.5, 0.0)
			_dot.width = 32
			_dot.height = 32
		var look := StandardMaterial3D.new()
		look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.vertex_color_use_as_albedo = true
		look.albedo_texture = _dot
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glowing else BaseMaterial3D.SHADING_MODE_PER_PIXEL
		# Sparks are lit by themselves, never brighter than white: stacked at
		# a hot spot, anything brighter blooms into a glare that hides the seam.
		_looks[glowing] = look
	return _looks[glowing]
