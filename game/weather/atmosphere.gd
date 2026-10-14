class_name Atmosphere
extends Node3D
## The weather where you stand, made visible and audible: grit and dust clouds
## streaming on the wind, Sand Game's desert wind in the clear and its storm
## roar inside one. Crude on purpose; the look-test and the sound pass make it good.

## Grit rides every wind a little and fills a storm; dust clouds come only with storms.
const GRIT := 6000
const CLOUDS := 300

var _grit: GPUParticles3D
var _clouds: GPUParticles3D
var _looks: Array[StandardMaterial3D] = []
var _wind_sound: AudioStreamPlayer
var _roar: AudioStreamPlayer


func _ready() -> void:
	# Grit draws as thin streaks along its own motion, so speed reads in a still frame.
	_grit = _dust(GRIT, 1.0, Vector3(14, 4, 14), Vector2(0.015, 0.5), 0.7, _soft_disc())
	_grit.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	_clouds = _dust(CLOUDS, 2.0, Vector3(30, 8, 30), Vector2(3.0, 8.0), 0.3, _soft_disc())
	_clouds.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD
	_wind_sound = _loop(preload("res://assets/audio/wind.ogg"))
	_roar = _loop(preload("res://assets/audio/storm.ogg"))


## Called each tick with the felt weather at the player.
func show_weather(at: Vector3, wind: Vector3, storm: float, color: Color) -> void:
	global_position = at
	var speed := wind.length()
	var along := wind / speed if speed > 0.01 else Vector3.FORWARD
	for dust: GPUParticles3D in [_grit, _clouds]:
		var motion: ParticleProcessMaterial = dust.process_material
		motion.direction = along
		motion.initial_velocity_min = speed * 0.8
		motion.initial_velocity_max = speed * 1.2
		# Emit upwind, so the dust streams through where you stand.
		motion.emission_shape_offset = -along * speed * dust.lifetime * 0.5
	# Grit catches the light and clouds shade it, so both stand out from the fog.
	_looks[0].albedo_color = Color(color.lightened(0.35), _looks[0].albedo_color.a)
	_looks[1].albedo_color = Color(color.darkened(0.25), _looks[1].albedo_color.a)
	_grit.amount_ratio = lerpf(0.4, 1.0, storm) if storm > 0.0 else clampf((speed - 6.0) / 60.0, 0.0, 0.15)
	_clouds.amount_ratio = storm
	_roar.volume_db = linear_to_db(storm)
	_wind_sound.volume_db = linear_to_db(clampf(speed / 25.0, 0.0, 1.0) * (1.0 - storm) * 0.7)


## size is the quad's width and height; clouds scale up to twice their size.
func _dust(count: int, life: float, spread: Vector3, size: Vector2, alpha: float,
		texture: Texture2D) -> GPUParticles3D:
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = spread
	motion.spread = 8.0
	motion.gravity = Vector3(0, -1.0, 0)
	motion.scale_min = 1.0
	motion.scale_max = 2.0
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.albedo_color = Color(1, 1, 1, alpha)
	look.albedo_texture = texture
	_looks.append(look)
	var quad := QuadMesh.new()
	quad.size = size
	quad.material = look
	var dust := GPUParticles3D.new()
	dust.amount = count
	dust.lifetime = life
	dust.local_coords = false
	dust.process_material = motion
	dust.draw_pass_1 = quad
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust.visibility_aabb = AABB(Vector3(-80, -20, -80), Vector3(160, 40, 160))
	dust.amount_ratio = 0.0
	add_child(dust)
	return dust


func _soft_disc() -> Texture2D:
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	var disc := GradientTexture2D.new()
	disc.gradient = fade
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(0.5, 0.0)
	return disc


func _loop(sound: AudioStreamOggVorbis) -> AudioStreamPlayer:
	sound.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = -80.0
	player.autoplay = true
	add_child(player)
	return player
