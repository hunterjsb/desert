class_name Hoverboard
extends Device
## The hoverboard: a find, fast, floaty and fun to carve, for scouting and for
## running when the shield dies. It runs on its own battery and nothing ties
## to it, so it tows nothing. Lying on the sand it's a device like any other:
## take it, carry it, swap its battery, cable it to charge. Stuck on a deck,
## hung on an upright as often as not, it travels with the camp and charges
## from it. Ridden, it leaves the
## physics world for the place under your feet, where the ride moves you
## both. What it draws is metered tick by tick in world time, so its charge
## comes out the same at any frame rate. Its make (BoardMakes) is its catalog
## id: how it rides, looks and sounds.

## Ridden, its battery says once it's low, WARNING s from flat out of charge
## flat out, and once more at CRITICAL s; charged past REARM times that, it
## will again. Its hum's sag is the tell between.
const WARNING := 60.0
const CRITICAL := 15.0
const REARM := 1.5

## Whoever rides it, or null.
var rider: Player
## The share of a full push this tick, 0 to 1.
var push := 0.0

var _tuning := Tuning.current()
## Energy drawn riding, as [from, to, Wh] in world time for each tick the
## power tick hasn't yet read.
var _drawn: Array[Array] = []
var _layers := Vector2i.ONE
## Its voice while ridden.
var _voice: RideSound
## The battery's cues said since it was last charged: none, low, critical.
var _warned := 0


func _init() -> void:
	# Thin and quick: stepped off at speed, it mustn't skip through the sand.
	continuous_cd = true


func _ready() -> void:
	super()
	get_tree().physics_frame.connect(_back_to_tick)


func _exit_tree() -> void:
	if _voice != null:
		_voice.stop()


## Whether it would carry you now: whole, with charge to run on, its own
## while it's on a deck.
func can_run() -> bool:
	if wrecked() or world == null:
		return false
	var charged := charge_share() > 0.0 if on_deck() else world.power.pool_wh(self) > 0.0
	return charged or production_w() > 0.0


## On a deck, its battery stays its own: it charges from the deck's pool as a
## draw ranked below the shield, so it never takes the shield's last quarter.
func pooled() -> Array[Battery]:
	var none: Array[Battery] = []
	return none if on_deck() else batteries()


## On a deck, what it draws to charge, W: its charge rate, or what fills it.
func charge_w() -> float:
	var cell := battery()
	if not on_deck() or cell == null or wrecked():
		return 0.0
	return minf(_tuning.board_charge_w, (cell.capacity() - cell.charge_wh) * 3600.0 / _tuning.power_tick)


## What it drew to charge goes into its battery: stored, not used.
func work(seconds: float, _t: float) -> float:
	var cell := battery()
	if cell == null:
		return 0.0
	var wh := charge_w() * seconds / 3600.0
	return wh - cell.fill(wh)


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
	if _voice == null:
		_voice = RideSound.new()
		add_child(_voice)
	_voice.start(by)
	Sounds.play(self, Sounds.BOARD_ON)


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
	_voice.stop()
	Sounds.play(self, Sounds.BOARD_OFF)


## What it draws riding now, W, as its make draws.
func draw_w() -> float:
	if rider == null or wrecked():
		return 0.0
	return (_tuning.board_hover_w + _tuning.board_push_w * push) * BoardMakes.of(BoardMakes.make_of(self)).draw


## One tick ridden: what it drew over its own `seconds`, spread over the world
## time they took, from..to.
func meter(from: float, to: float, seconds: float) -> void:
	var wh := draw_w() * seconds / 3600.0
	if wh > 0.0:
		_drawn.append([from, to, wh])


## Now, what it draws; read by a power tick ending at world time t, the mean
## over that tick of what the ticks ridden in it drew. Racked, its charging.
func demand_w(t := NAN) -> float:
	var parts_w := super(t) + charge_w()
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


## Seconds of riding its battery has left flat out, which only charging raises.
func seconds_flat_out() -> float:
	var cell := battery()
	var most: float = (_tuning.board_hover_w + _tuning.board_push_w) * BoardMakes.of(BoardMakes.make_of(self)).draw
	return INF if cell == null else cell.charge_wh / most * 3600.0


## Seconds of riding its battery has left at what it draws now.
func seconds_left() -> float:
	var draw := draw_w()
	var cell := battery()
	return INF if draw <= 0.0 or cell == null else cell.charge_wh / draw * 3600.0


## Drawn each frame where the ride draws it, between ticks.
func _process(_delta: float) -> void:
	if rider == null or rider.ride == null:
		return
	global_transform = rider.ride.board_pose(true)
	var left := seconds_flat_out()
	if left > WARNING * REARM:
		_warned = 0
	elif _warned < 1 and left <= WARNING:
		_warned = 1
		Sounds.battery_low(self)
	if _warned < 2 and left <= CRITICAL:
		_warned = 2
		Sounds.battery_critical(self)


## Before anything reads it this tick, back where the tick put it.
func _back_to_tick() -> void:
	if rider != null and rider.ride != null:
		global_transform = rider.ride.board_pose(false)
