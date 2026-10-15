extends Node3D
## The look-test's shield: a grey-box generator on the sand with Sand Game's
## bloom and sounds, holding the Shelter whose radius is the bubble as it
## stands. Stage 6 makes it a device with a battery; this only answers how the
## bubble looks and sounds.

const BOOT := preload("res://assets/audio/shield_boot.ogg")
const HUM := preload("res://assets/audio/shield_hum.ogg")
const DOWN := preload("res://assets/audio/shield_down.ogg")
## Sand Game's shield blue.
const BLUE := Color(0.25, 0.67, 0.87)
## The bubble's centre, above the sand under the generator.
const CORE := 0.25
## A fresh bloom flares the shell, settling over this long, s.
const FLARE := 1.2

var on := false
var shelter := Shelter.new()

var _tuning := Tuning.current()
## Seconds since the last switch.
var _since := INF
var _boot: AudioStreamPlayer3D
var _hum: AudioStreamPlayer3D
var _down: AudioStreamPlayer3D
var _light: OmniLight3D
var _band: StandardMaterial3D


func _ready() -> void:
	shelter.position = Vector3.UP * CORE
	add_child(shelter)
	var body := MeshInstance3D.new()
	var drum := CylinderMesh.new()
	drum.top_radius = 0.2
	drum.bottom_radius = 0.24
	drum.height = 0.42
	drum.material = _matte(Color(0.22, 0.23, 0.25))
	body.mesh = drum
	body.position.y = 0.21
	add_child(body)
	var band := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.215
	ring.bottom_radius = 0.225
	ring.height = 0.05
	_band = _matte(Color(0.1, 0.12, 0.14))
	_band.emission_enabled = true
	_band.emission = BLUE
	ring.material = _band
	band.mesh = ring
	band.position.y = 0.3
	add_child(band)
	_light = OmniLight3D.new()
	_light.light_color = BLUE
	_light.omni_range = 4.0
	_light.position.y = 0.6
	_light.shadow_enabled = false
	add_child(_light)
	_boot = _sound(BOOT, 0.0)
	var hum: AudioStreamOggVorbis = HUM
	hum.loop = true
	_hum = _sound(hum, -12.0)
	_down = _sound(DOWN, 0.0)
	_show(1.0)


func _exit_tree() -> void:
	# A looping stream still playing at quit holds its resources past exit.
	_hum.stop()


## Switches the shield, blooming open or collapsing over the tuned time.
func switch(to_on: bool) -> void:
	if to_on == on:
		return
	on = to_on
	_since = 0.0
	if on:
		_boot.play()
		_hum.pitch_scale = 0.9
		_hum.play()
	else:
		_down.play()


## Straight to standing open or down, with no bloom and no sound.
func set_now(to_on: bool) -> void:
	on = to_on
	_since = INF
	if on and not _hum.playing:
		_hum.play()
	elif not on:
		_hum.stop()
	_show(1.0)


func _physics_process(delta: float) -> void:
	_since += delta
	var x := clampf(_since / _tuning.shield_bloom_seconds, 0.0, 1.0)
	_show(x)
	if not on and x >= 1.0 and _hum.playing:
		_hum.stop()


## x runs 0 to 1 through a bloom or a collapse.
func _show(x: float) -> void:
	# Sand Game's tween: out fast and settle on the way up, gather then go on
	# the way down.
	var open := 1.0 - (1.0 - x) * (1.0 - x) if on else 1.0 - x * x
	shelter.radius = _tuning.shield_radius * open
	shelter.glow = 1.0 + 2.5 * (1.0 - smoothstep(0.0, FLARE, _since)) if on else 1.0 + 1.5 * x * (1.0 - x)
	_light.light_energy = 0.35 * open * shelter.glow
	_band.emission_energy_multiplier = 0.3 + 2.0 * open * shelter.glow
	if not on and _hum.playing:
		# The hum sags as the bubble goes.
		_hum.pitch_scale = lerpf(0.9, 0.55, x)


func _sound(stream: AudioStream, db: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = db
	player.unit_size = 4.0
	player.position.y = 0.3
	add_child(player)
	return player


static func _matte(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
