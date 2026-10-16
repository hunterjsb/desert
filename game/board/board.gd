class_name Hoverboard
extends Device
## The hoverboard: a find, fast, floaty and fun to carve, for scouting and for
## running when the shield dies. It runs on its own battery and nothing ties
## to it, so it tows nothing. Lying on the sand it's a device like any other:
## take it, carry it, swap its battery, cable it to charge. Ridden, it leaves
## the physics world for the place under your feet, where the ride moves you
## both. What it draws is metered tick by tick in world time, so its charge
## comes out the same at any frame rate.

const HUM := preload("res://assets/audio/hum.ogg")
## The hum's pitch at rest and at top speed, and how far it sags as the
## battery runs out over its last WARNING seconds.
const HUM_REST := 0.7
const HUM_FAST := 1.3
const HUM_SAG := 0.7
const WARNING := 60.0

## Whoever rides it, or null.
var rider: Player
## The share of a full push this tick, 0 to 1.
var push := 0.0

var _tuning := Tuning.current()
## Energy drawn riding, as [from, to, Wh] in world time for each tick the
## power tick hasn't yet read.
var _drawn: Array[Array] = []
var _layers := Vector2i.ONE
var _hum: AudioStreamPlayer


func _init() -> void:
	carryable = true
	# Thin and quick: stepped off at speed, it mustn't skip through the sand.
	continuous_cd = true


func _ready() -> void:
	super()
	get_tree().physics_frame.connect(_back_to_tick)


func _exit_tree() -> void:
	if _hum != null:
		_hum.stop()


## Whether it would carry you now: whole, with charge to run on.
func can_run() -> bool:
	return not wrecked() and world != null \
		and (world.power.pool_wh(self) > 0.0 or production_w() > 0.0)


## Under your feet: out of the physics world, touching nothing. A cable in
## its port pops out, since it tows nothing.
func carry(by: Player) -> void:
	for socket in sockets():
		if socket.kind == &"port" and socket.part != null:
			var plug := take(socket)
			plug.global_position += global_basis * socket.transform.basis.z * plug.depth()
	rider = by
	push = 0.0
	_layers = Vector2i(collision_layer, collision_mask)
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0
	# Made the first time it's ridden: a find lying in the sand is laid out
	# inside the streaming budget.
	if _hum == null:
		var looping := HUM.duplicate() as AudioStreamOggVorbis
		looping.loop = true
		_hum = AudioStreamPlayer.new()
		_hum.stream = looping
		_hum.volume_db = -14.0
		add_child(_hum)
	_hum.play()


## Off your feet and a body again, moving as it was.
func set_down(velocity: Vector3) -> void:
	rider = null
	push = 0.0
	freeze = false
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	collision_layer = _layers.x
	collision_mask = _layers.y
	linear_velocity = velocity
	angular_velocity = Vector3.ZERO
	_hum.stop()


## What it draws riding now, W.
func draw_w() -> float:
	if rider == null or wrecked():
		return 0.0
	return _tuning.board_hover_w + _tuning.board_push_w * push


## One tick ridden: what it drew over its own `seconds`, spread over the world
## time they took, from..to.
func meter(from: float, to: float, seconds: float) -> void:
	var wh := draw_w() * seconds / 3600.0
	if wh > 0.0:
		_drawn.append([from, to, wh])


## Now, what it draws; read by a power tick ending at world time t, the mean
## over that tick of what the ticks ridden in it drew.
func demand_w(t := NAN) -> float:
	var parts_w := super(t)
	if is_nan(t):
		return parts_w + draw_w()
	var step := _tuning.power_tick
	var wh := 0.0
	var later: Array[Array] = []
	for each: Array in _drawn:
		var span: float = maxf(each[1] - each[0], 1e-9)
		wh += each[2] * clampf(minf(each[1], t) - maxf(each[0], t - step), 0.0, span) / span
		if each[1] > t:
			later.append(each)
	# A jump back in time (a scenario) leaves ticks no power tick will reach.
	_drawn = later if later.size() < 1000 else []
	return parts_w + wh * 3600.0 / step


## Seconds of riding its battery has left at what it draws now.
func seconds_left() -> float:
	var draw := draw_w()
	var cell := battery()
	return INF if draw <= 0.0 or cell == null else cell.charge_wh / draw * 3600.0


## Lying flat, the wind meets its edge, not its deck.
func stats() -> Dictionary:
	var now := super()
	if world != null:
		var size: Vector3 = Catalog.DEVICES[&"board"].size
		now["catch"] = world.tuning.wind_catch_per_m2 * size.y * size.z
	return now


## Drawn each frame where the ride draws it, between ticks.
func _process(_delta: float) -> void:
	if rider == null or rider.ride == null:
		return
	global_transform = rider.ride.board_pose(true)
	var speed := rider.ride.velocity.length() / _tuning.board_top_speed
	var low := clampf(1.0 - seconds_left() / WARNING, 0.0, 1.0)
	_hum.pitch_scale = lerpf(HUM_REST, HUM_FAST, clampf(speed, 0.0, 1.2)) * lerpf(1.0, HUM_SAG, low)


## Before anything reads it this tick, back where the tick put it.
func _back_to_tick() -> void:
	if rider != null and rider.ride != null:
		global_transform = rider.ride.board_pose(false)
