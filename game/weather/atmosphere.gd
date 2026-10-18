class_name Atmosphere
extends Node3D
## The weather where you stand, made visible and audible: sand snaking along the
## ground as a front's outflow arrives, grit on every wind and filling a storm,
## parcels of dust tearing past inside one, the wind shoving the view, Sand
## Game's desert wind in the clear and its storm roar. It follows what you see,
## the dust at the camera, not the field at your feet. Inside a bubble the
## dust outside still blows past, carved away at the shell, and the sound is
## muffled.

const STREAK := preload("res://game/weather/streak.gdshader")
const PUFF := preload("res://game/weather/puff.gdshader")
## Muffled: what of the sound gets through a shell, its loudness and its top.
const MUFFLED_GAIN := 0.3
const MUFFLED_HZ := 600.0
const OPEN_HZ := 20000.0
## The eclipse's hush: the wind's sound dips by this share through totality,
## easing in and out over about this many seconds.
const HUSH := 0.45
const HUSH_SECONDS := 2.0

var _streamers: GPUParticles3D
var _grit: GPUParticles3D
var _puffs: GPUParticles3D
var _wind_sound: AudioStreamPlayer
var _roar: AudioStreamPlayer
var _buffet := FastNoiseLite.new()
var _buffet_time := 0.0
var _muffle: AudioEffectLowPassFilter
var _hush := 0.0


func _ready() -> void:
	_streamers = _particles(2500, 1.6, Vector3(40, 0.35, 40), 4.0, Vector2(0.6, 1.6),
		Vector2(0.02, 0.06), _streaks(0.12, 0.25))
	_grit = _particles(6000, 1.0, Vector3(22, 9, 22), 8.0, Vector2(0.5, 1.5),
		Vector2(0.05, 0.15), _streaks(0.06, 0.35))
	_puffs = _particles(400, 1.8, Vector3(26, 7, 26), 10.0, Vector2(2.5, 7.0),
		Vector2(0.03, 0.08), _puff_look())
	# Streaks stretch along their flight; puffs face the camera in the shader.
	(_streamers.process_material as ParticleProcessMaterial).particle_flag_align_y = true
	(_grit.process_material as ParticleProcessMaterial).particle_flag_align_y = true
	# The Weather bus's low-pass, from the bus layout.
	_muffle = AudioServer.get_bus_effect(AudioServer.get_bus_index(Sounds.WEATHER), 0) as AudioEffectLowPassFilter
	_wind_sound = _loop(Sounds.WIND)
	_roar = _loop(Sounds.STORM)


func _exit_tree() -> void:
	# Looping streams still playing at quit hold their resources past exit.
	_wind_sound.stop()
	_roar.stop()


## Called each tick. wind is the open air's at the player, slowed in a
## dune's lee but not by a bubble;
## sheltered is 1 when the camera is inside a bubble; seen is how far into the
## storm's dust the camera is (0 to 1), as if no bubble stood; near is how
## close the nearest face is (0 far, 1 here); light is what the dust grains
## catch; sigma the storm's extinction round the camera; running is false
## while the clock is stopped.
func show_weather(camera: Camera3D, ground: float, wind: Vector3, sheltered: float, seen: float,
		near: float, light: Vector3, sigma: float, running: bool, delta: float) -> void:
	var p := camera.global_position
	var blow := wind.length()
	var heading := wind / blow if blow > 0.01 else Vector3.FORWARD
	for system: GPUParticles3D in [_streamers, _grit, _puffs]:
		var motion := system.process_material as ParticleProcessMaterial
		motion.direction = heading
		motion.initial_velocity_min = blow * 0.8
		motion.initial_velocity_max = blow * 1.15
		system.speed_scale = 1.0 if running else 0.0
		var look := (system.draw_pass_1 as QuadMesh).material as ShaderMaterial
		look.set_shader_parameter("dust_light", light)
		look.set_shader_parameter("camera_sigma", sigma)
		if system != _puffs:
			# About a twelfth of a second of motion blur.
			look.set_shader_parameter("streak_length", clampf(blow * 0.06, 0.4, 1.8))
	# Emitters sit upwind by half a lifetime of travel, so you stand mid-stream.
	_streamers.global_position = Vector3(p.x, ground + 0.35, p.z) - heading * blow * _streamers.lifetime * 0.5
	_grit.global_position = p - heading * blow * _grit.lifetime * 0.5
	_puffs.global_position = p - heading * blow * _puffs.lifetime * 0.5
	_ratio(_streamers, smoothstep(0.1, 0.5, near) * (1.0 - 0.6 * seen))
	# Grit rides every strong wind a little, thickens as a face nears, fills a storm.
	_ratio(_grit, maxf(maxf(seen, 0.1 * smoothstep(0.55, 0.95, near)), clampf((blow - 6.0) / 60.0, 0.0, 0.1)))
	_ratio(_puffs, seen)
	# The roar grows as a face nears and fills everything once inside. A
	# shell takes its edge off at once: inside is a place.
	var through := lerpf(1.0, MUFFLED_GAIN, sheltered)
	_muffle.cutoff_hz = OPEN_HZ * pow(MUFFLED_HZ / OPEN_HZ, sheltered)
	_wind_sound.volume_db = linear_to_db(clampf(blow / 25.0, 0.0, 1.0) * (1.0 - seen) * 0.7 * through
		* (1.0 - HUSH * _hush) + 0.0001)
	_roar.volume_db = linear_to_db(maxf(seen, 0.5 * smoothstep(0.3, 1.0, near)) * through + 0.0001)
	_wind_sound.stream_paused = not running
	_roar.stream_paused = not running
	# The wind shoves the view: a small roll that grows with it, and none in
	# a bubble's still air. Nothing else sets the camera's roll, so this
	# can't fight the mouse.
	_buffet_time += delta if running else 0.0
	camera.rotation.z = deg_to_rad(0.5) * smoothstep(7.0, 22.0, blow) * (1.0 - sheltered) \
		* _buffet.get_noise_1d(_buffet_time * 90.0)


## Each tick, before show_weather: the eclipse ring's light on the grains,
## thrown forward about its bearing (none outside an eclipse), and how far the
## sun is behind Tu, 0 to 1, which hushes the wind.
func show_eclipse(toward: Vector3, glow: Vector3, hidden: float, delta: float) -> void:
	for system: GPUParticles3D in [_streamers, _grit, _puffs]:
		var look := (system.draw_pass_1 as QuadMesh).material as ShaderMaterial
		look.set_shader_parameter("ring_dir", toward)
		look.set_shader_parameter("ring_glow", glow)
	_hush = lerpf(_hush, hidden, 1.0 - exp(-delta / HUSH_SECONDS))


## How far the sound is muffled now: 0 open, 1 inside a bubble.
func muffled() -> float:
	return log(_muffle.cutoff_hz / OPEN_HZ) / log(MUFFLED_HZ / OPEN_HZ)


## Every drawn frame: the shelters' spheres, which no grain enters.
func carve(holes: PackedVector4Array) -> void:
	var padded := Shelter.padded(holes)
	for system: GPUParticles3D in [_streamers, _grit, _puffs]:
		var look := (system.draw_pass_1 as QuadMesh).material as ShaderMaterial
		look.set_shader_parameter("shelters", padded)
		look.set_shader_parameter("shelter_count", holes.size())


func _ratio(system: GPUParticles3D, ratio: float) -> void:
	if absf(system.amount_ratio - ratio) > 0.01 or (ratio == 0.0) != (system.amount_ratio == 0.0):
		system.amount_ratio = ratio


func _particles(count: int, life: float, spread: Vector3, cone: float, scale: Vector2,
		swirl: Vector2, look: ShaderMaterial) -> GPUParticles3D:
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = spread
	motion.spread = cone
	motion.gravity = Vector3.ZERO
	motion.scale_min = scale.x
	motion.scale_max = scale.y
	motion.turbulence_enabled = true
	motion.turbulence_noise_strength = 1.0
	motion.turbulence_noise_scale = 6.0
	motion.turbulence_influence_min = swirl.x
	motion.turbulence_influence_max = swirl.y
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = look
	var system := GPUParticles3D.new()
	system.amount = count
	system.lifetime = life
	system.preprocess = life
	system.local_coords = false
	system.process_material = motion
	system.draw_pass_1 = quad
	system.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	system.visibility_aabb = AABB(Vector3(-70, -25, -70), Vector3(140, 50, 140))
	system.amount_ratio = 0.0
	add_child(system)
	return system


func _streaks(width: float, opacity: float) -> ShaderMaterial:
	var look := ShaderMaterial.new()
	look.shader = STREAK
	look.set_shader_parameter("streak_width", width)
	look.set_shader_parameter("opacity", opacity)
	return look


func _puff_look() -> ShaderMaterial:
	var look := ShaderMaterial.new()
	look.shader = PUFF
	look.set_shader_parameter("opacity", 0.28)
	return look


func _loop(sound: AudioStreamOggVorbis) -> AudioStreamPlayer:
	sound.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.bus = Sounds.WEATHER
	player.volume_db = -80.0
	player.autoplay = true
	add_child(player)
	return player
