class_name ShieldGenerator
extends Device
## The bubble shield: a small generator you carry, set down or seat on a top
## mount, and switch with use. Running, it holds a Shelter centred on itself, so
## the bubble goes wherever it does, carried or not, and keeps out what the
## shelter blocks. Seated on a crate, it runs on the crate's power too. It
## draws by what it's doing: a sip in the clear, the most while it holds back
## a storm. Low on power its hum sags and its shell flickers; flat, the bubble
## collapses for everything at once, and blooms again once there's power.

## Sand Game's shield blue.
const BLUE := Color(0.25, 0.67, 0.87)
## A fresh bloom flares the shell, settling over this long, s.
const FLARE := 1.2
## The hum's pitch running steady, where it sags to as the power runs out,
## and where it ends as the bubble goes.
const HUM_PITCH := 0.9
const SAG_PITCH := 0.65
const GONE_PITCH := 0.5
## The hum sits far under everything else, there if you listen for it
## (Hunter, 2026-10-17: "way, way softer"), dB.
const HUM_DB := -15.0
## How dim the shell drops in a flicker.
const FLICKER := 0.25

## The switch, which use flips. The bubble stands while it's on and has power.
var on := false
## Smart, a Console in its system switches it on as the radar sees a front
## near: set on the Console's power page.
var smart := true
## Metres to the shell, fully open: its kind's, unless widened.
var size := Tuning.current().shield_radius
var shelter := Shelter.new()
var hum: AudioStreamPlayer3D

var _tuning := Tuning.current()
var _radius := _tuning.shield_radius
var _clear_w := _tuning.shield_clear_w
var _storm_w := _tuning.shield_storm_w
## Whether the bubble is opening or open, rather than going or gone, and the
## seconds since that last changed.
var _up := false
var _since := INF
var _pitch := HUM_PITCH
var _boot: AudioStreamPlayer3D
var _down: AudioStreamPlayer3D
var _light: OmniLight3D
var _band: StandardMaterial3D


func _init() -> void:
	# Small and light: it goes in your hands, and its bubble with it.
	carryable = true
	# Its bubble is what keeps you alive: the last thing on a pool to go dark.
	rank = 1


func _ready() -> void:
	super()
	# A lighter kind says its own bubble, draw and hold; the base shield's are tuning.
	_radius = frame_stats.get("radius_m", _tuning.shield_radius)
	size = _radius
	_clear_w = frame_stats.get("clear_w", _tuning.shield_clear_w)
	_storm_w = frame_stats.get("storm_w", _tuning.shield_storm_w)
	shelter.blocks[&"wind"] = frame_stats.get("wind_block", 1.0)
	add_child(shelter)
	var housing := Vector3.ONE * 0.4
	for child in get_children():
		if child is CollisionShape3D:
			housing = Catalog.bounds((child as CollisionShape3D).shape).size
			break
	var band := MeshInstance3D.new()
	# A collar round its round body.
	var ring := CylinderMesh.new()
	ring.top_radius = housing.x * 0.44 + 0.006
	ring.bottom_radius = ring.top_radius
	ring.height = 0.05
	ring.radial_segments = 24
	ring.rings = 1
	_band = StandardMaterial3D.new()
	_band.albedo_color = Color(0.1, 0.12, 0.14)
	_band.emission_enabled = true
	_band.emission = BLUE
	ring.material = _band
	band.mesh = ring
	band.position.y = housing.y * 0.2
	add_child(band)
	_light = OmniLight3D.new()
	_light.light_color = BLUE
	_light.omni_range = 4.0
	_light.position.y = housing.y * 0.5 + 0.2
	_light.shadow_enabled = false
	add_child(_light)
	_boot = _sound(Sounds.SHIELD_BOOT)
	var looping := Sounds.SHIELD_HUM.duplicate() as AudioStreamOggVorbis
	looping.loop = true
	hum = _sound(looping)
	hum.volume_db = HUM_DB
	_down = _sound(Sounds.SHIELD_DOWN)
	_show()


func _exit_tree() -> void:
	# A looping stream still playing at quit holds its resources past exit.
	hum.stop()


## Seated on a device or taken off one, it leaves the tree and comes back
## running as it was.
func _enter_tree() -> void:
	if hum != null and _up:
		# Its sounds come into the tree after it does.
		_resume.call_deferred()


func _resume() -> void:
	if is_inside_tree() and _up and not hum.playing:
		hum.play()


## Use in your hands switches it just the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## Use: switches it. With nothing to run on it won't start, only fizzle, and the
## switch stays off. Wrecked, it does nothing.
func interact(_by: Player) -> bool:
	if wrecked():
		return false
	# Found in the sand, it's yours as you use it, so this use can start it.
	world.salvage.claim(self)
	if on:
		on = false
	elif powered and (world.power.pool_wh(self) > 0.0 or production_w() > 0.0):
		on = true
	else:
		_down.play()
		return true
	_follow()
	return true


## Switched from elsewhere, a Console's screen, as use at it would: on only
## with something to run on. Says whether it changed as asked.
func switch(up: bool) -> bool:
	if up == on or wrecked():
		return false
	interact(null)
	return on == up


## Whether its bubble stands: switched on, powered and whole.
func running() -> bool:
	return on and powered and not wrecked()


## Straight to standing open, or down, with no bloom and no sound: for
## scenarios and look-tests that start mid-storm.
func stand(up: bool) -> void:
	on = up
	_up = running()
	_since = INF
	if _up and not hum.playing:
		hum.pitch_scale = HUM_PITCH
		hum.play()
	elif not _up:
		hum.stop()
	_show()


## A sip in the clear, the most holding back a full storm, by the storm where
## it stands; a wider bubble costs more by its shell's area. Off, only what
## its parts draw.
func demand_w(t := NAN) -> float:
	var parts_w := super(t)
	if not on or wrecked() or world == null:
		return parts_w
	var storm := world.weather.field_storm(global_position, t)
	return parts_w + lerpf(_clear_w, _storm_w, storm) * pow(size / _radius, 2.0)


## Seconds of world time its pool's batteries last at what it draws now, less
## what it makes; INF while it isn't running down.
func seconds_left() -> float:
	var net := demand_w() - production_w()
	if net <= 0.0:
		return INF
	return world.power.pool_wh(self) / net * 3600.0


func _physics_process(delta: float) -> void:
	super(delta)
	_follow()
	_since += delta
	_show()


## Blooms the bubble open, or collapses it, as soon as whether it should
## stand changes: switched, or its power come or gone.
func _follow() -> void:
	var up := running()
	if up == _up:
		return
	_up = up
	_since = 0.0
	if up:
		_boot.play()
		hum.pitch_scale = HUM_PITCH
		hum.play()
	else:
		_pitch = hum.pitch_scale
		_down.play()


func _show() -> void:
	var x := clampf(_since / _tuning.shield_bloom_seconds, 0.0, 1.0)
	# Sand Game's tween: out fast and settle on the way up, gather then go on
	# the way down.
	var open := 1.0 - (1.0 - x) * (1.0 - x) if _up else 1.0 - x * x
	shelter.radius = size * open
	var glow := 1.0 + 2.5 * (1.0 - smoothstep(0.0, FLARE, _since)) if _up else 1.0 + 1.5 * x * (1.0 - x)
	if _up:
		# Over the last of its power the hum sags, and the shell flickers more
		# and more often.
		var low := clampf(1.0 - seconds_left() / _tuning.shield_warning_seconds, 0.0, 1.0)
		hum.pitch_scale = lerpf(HUM_PITCH, SAG_PITCH, low)
		if low > 0.0 and randf() < 0.1 + 0.4 * low:
			glow *= FLICKER
	elif hum.playing:
		hum.pitch_scale = lerpf(_pitch, GONE_PITCH, x)
		if x >= 1.0:
			hum.stop()
	shelter.glow = glow
	_light.light_energy = 0.35 * open * glow
	_band.emission_energy_multiplier = 0.3 + 2.0 * open * glow


## Heard at its level anywhere inside the bubble.
func _sound(stream: AudioStream) -> AudioStreamPlayer3D:
	var player := Sounds.world_voice(stream, 0.0, 4.0)
	add_child(player)
	return player
