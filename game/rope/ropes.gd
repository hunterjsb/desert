class_name Ropes
extends Node3D
## Every rope in the camp, solved together once a physics tick before anything
## else moves: you, the wind and the physics engine all act after it. Ropes
## belong to the camp, not the land, so they live here, never in a chunk, and
## their strands move with every origin shift. The numbers live here until
## Stage 5 moves them into Tuning.

signal snapped(rope: Rope)

const Stake := preload("res://game/rope/stake.gd")

## Passes over every rope per tick, so lines sharing a load agree on it.
const ITERATIONS := 2
## Load is averaged over this long before it breaks anything, so a spike
## shorter than it can't.
const LOAD_SECONDS := 0.3
## Cap on how much a body is expected to change speed in a tick, m/s² and
## rad/s², so one hard landing can't mislead the rope about the next.
const MAX_EXPECTED := 80.0
const MAX_EXPECTED_SPIN := 80.0
const BREAKING := 1500.0
const NO_TURN := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)

## You on a line: your weight in the suit, and your feet's hold against a
## pull, which grows the faster you're dragged, as when you dig in and stumble.
const PLAYER_MASS := 90.0
const GRIP := 4.0
const GRIP_PER_SPEED := 2.0
## Tied round your waist: the share of your walking it costs, and the wind it
## adds to what pulls you.
const WAIST_SLOW := 0.3
## Where a line in your hand ties on, in your own frame, unless what you hold
## carries its own end (a strong cable's plug does).
const HAND_AT := Vector3(0.3, 1.1, -0.35)
const WAIST_CATCH := 0.12

var world: World
var ropes: Array[Rope] = []
## Every drawn strand, including loose ones a snap or a let-go leaves behind.
var strands: Array[RopeStrand] = []
## Where a line ties on you.
var hand: RopeEnd
var waist: RopeEnd
## Taut rope creaks with this; probes leave it empty.
var creak: AudioStream
## Time the ropes took this physics tick, and on average, ms.
var tick_ms := 0.0
var cost_ms := 0.0

var _bodies := {}
var _tick := 0
var _pulls := {}
var _drag := Vector3.ZERO
var _clock := 0.0
var _crack: AudioStreamWAV


func _ready() -> void:
	process_physics_priority = -10


func setup(on: World) -> void:
	world = on
	var groan: AudioStreamOggVorbis = preload("res://assets/audio/creak.ogg")
	groan.loop = true
	creak = groan
	world.origin_shifted.connect(_on_origin_shifted)
	hand = RopeEnd.make(world.player, HAND_AT, false)
	waist = RopeEnd.make(world.player, Vector3(0.0, 0.95, 0.0), false)


func tie(a: RopeEnd, b: RopeEnd, length: float, breaking := BREAKING) -> Rope:
	var rope := Rope.new()
	rope.a = a
	rope.b = b
	rope.length = length
	rope.breaking = breaking
	rope.strand = RopeStrand.new()
	add_child(rope.strand)
	rope.strand.hang(world, length, a, b)
	strands.append(rope.strand)
	if creak != null:
		rope.creak = AudioStreamPlayer3D.new()
		rope.creak.stream = creak
		rope.creak.unit_size = 5.0
		rope.creak.max_db = 4.0
		add_child(rope.creak)
	ropes.append(rope)
	return rope


## Moves one end to another point, keeping the length: unstaking, staking
## again, hand to waist.
func move_end(rope: Rope, from: RopeEnd, to: RopeEnd) -> void:
	if rope.a == from:
		rope.a = to
		rope.strand.a = to
	elif rope.b == from:
		rope.b = to
		rope.strand.b = to


## An end lets go: the rope stops holding and its strand hangs from the other.
func let_go(rope: Rope, end: RopeEnd) -> void:
	rope.strand.let_go(end)
	_drop(rope)


func snap(rope: Rope) -> void:
	var tail := rope.strand.cut(rope.strand.points.size() / 2)
	add_child(tail)
	strands.append(tail)
	if creak != null:
		_crack_at(tail.points[0])
	_drop(rope)
	snapped.emit(rope)


func lines_on(end: RopeEnd) -> Array[Rope]:
	return ropes.filter(func(rope: Rope) -> bool: return rope.a == end or rope.b == end)


func clear() -> void:
	for strand in strands:
		strand.queue_free()
	for rope in ropes:
		if rope.creak != null:
			rope.creak.queue_free()
	ropes.clear()
	strands.clear()
	_bodies.clear()
	_drag = Vector3.ZERO


func _physics_process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	_solve(delta)
	_bear(delta)
	_draw(delta)
	tick_ms = (Time.get_ticks_usec() - started) / 1000.0
	cost_ms += (tick_ms - cost_ms) * 0.05
	var worst := 0.0
	for rope in ropes:
		worst = maxf(worst, rope.share())
	Dev.put("rope/n", "%d" % ropes.size())
	Dev.put("rope/max", "%d%%" % roundi(worst * 100.0))
	Dev.put("rope/ms", "%.2f" % cost_ms)


func _solve(h: float) -> void:
	_tick += 1
	_pulls.clear()
	var live: Array[Rope] = []
	for rope: Rope in ropes.duplicate():
		if not is_instance_valid(rope.a) or not is_instance_valid(rope.b):
			# What it was tied to is gone altogether: so is the rope.
			_drop(rope)
			strands.erase(rope.strand)
			rope.strand.queue_free()
			continue
		var lost: RopeEnd = _lost_end(rope)
		if lost != null:
			let_go(rope, lost)
			continue
		rope.body_a = _body(rope.a.holder, h)
		rope.body_b = _body(rope.b.holder, h)
		rope.prepare(h)
		live.append(rope)
	for rope in live:
		rope.warm_start()
	for i in ITERATIONS:
		for rope in live:
			rope.solve()
	for rope in live:
		var push := rope.impulse()
		rope.tension = (rope.spring_impulse + rope.stop_impulse) / h
		_deliver(rope.body_a, push, rope.point_a, h)
		_deliver(rope.body_b, -push, rope.point_b, h)
	for id: int in _bodies.keys():
		var body: RopeBody = _bodies[id]
		if body.tick != _tick:
			_bodies.erase(id)
		else:
			body.left = body.velocity - body.expected
			body.left_spin = body.spin - body.expected_spin
	_drag_player(h)


## The solver's view of whatever an end is fixed to, kept from tick to tick.
## A moving body expects this tick's push from everything else to match
## last tick's: how far its velocity moved from where the ropes left it.
func _body(holder: Node3D, h: float) -> RopeBody:
	var id := holder.get_instance_id()
	var body: RopeBody = _bodies.get(id)
	if body != null and body.tick == _tick:
		return body
	var seen := body != null and body.tick == _tick - 1
	if body == null:
		body = RopeBody.new()
		body.node = holder
		body.rigid = holder as RigidBody3D
		body.player = holder as Player
		body.stake = holder is Stake
		_bodies[id] = body
	body.tick = _tick
	body.expected = Vector3.ZERO
	body.expected_spin = Vector3.ZERO
	var rigid := body.rigid
	if rigid != null and not rigid.freeze:
		body.center = holder.global_position
		body.inv_mass = Vector3.ONE / rigid.mass
		body.inv_inertia = _inverse_inertia(rigid)
		body.velocity = rigid.linear_velocity
		body.spin = rigid.angular_velocity
		if seen:
			body.expected = (body.velocity - body.left).limit_length(MAX_EXPECTED * h)
			body.expected_spin = (body.spin - body.left_spin).limit_length(MAX_EXPECTED_SPIN * h)
			body.velocity += body.expected
			body.spin += body.expected_spin
	elif body.player != null and not body.player.flying:
		# The ground holds you up, so a line can only pull you along it.
		body.center = holder.global_position
		body.inv_mass = Vector3(1.0, 0.0, 1.0) / PLAYER_MASS
		body.inv_inertia = NO_TURN
		body.velocity = body.player.velocity
		body.spin = Vector3.ZERO
	else:
		body.inv_mass = Vector3.ZERO
		body.inv_inertia = NO_TURN
		body.velocity = Vector3.ZERO
		body.spin = Vector3.ZERO
	return body


func _inverse_inertia(rigid: RigidBody3D) -> Basis:
	if rigid.inertia == Vector3.ZERO:
		return rigid.get_inverse_inertia_tensor()
	var turn := rigid.global_basis.orthonormalized()
	return turn * Basis.from_scale(Vector3.ONE / rigid.inertia) * turn.transposed()


## Hands an end its share: an impulse at the attachment point, a drag on you,
## or a pull a stake has to hold.
func _deliver(body: RopeBody, push: Vector3, at: Vector3, h: float) -> void:
	if body.inv_mass != Vector3.ZERO:
		if body.rigid != null:
			body.rigid.apply_impulse(push, at - body.center)
		else:
			_drag += body.inv_mass * push
	elif body.stake:
		_pulls[body.node] = _pulls.get(body.node, Vector3.ZERO) + push / h


## Your share of the pull, plus the waist tie's price. The player applies it
## through its one hook, the rope_drag meta.
func _drag_player(h: float) -> void:
	var player := world.player
	var tied := false
	for rope in ropes:
		if rope.a == waist or rope.b == waist:
			tied = true
			break
	var own: Vector3 = player.velocity - player.get_meta(&"rope_drag", Vector3.ZERO)
	own.y = 0.0
	if tied:
		var wind := world.weather.felt_wind(player.global_position)
		_drag += wind * wind.length() * WAIST_CATCH * h / PLAYER_MASS
	# Exact over the tick, so dragging plays out the same at any tick rate.
	var speed := _drag.length()
	if speed > 0.0:
		var floor_speed := GRIP / GRIP_PER_SPEED
		var after := maxf(0.0, (speed + floor_speed) * exp(-GRIP_PER_SPEED * h) - floor_speed)
		_drag *= after / speed
	# Slower only while you walk, so the wind's own shove on you isn't eased.
	var walking := player.mode == "walk" or player.mode == "sprint"
	player.set_meta(&"rope_drag", _drag - own * WAIST_SLOW if tied and walking else _drag)


## Sustained load breaks ropes and pulls stakes; a spike alone never does.
func _bear(h: float) -> void:
	var alpha := 1.0 - exp(-h / LOAD_SECONDS)
	for rope: Rope in ropes.duplicate():
		rope.sustained += (rope.tension - rope.sustained) * alpha
		if rope.sustained > rope.breaking:
			snap(rope)
	for stake: Node3D in _pulls:
		if stake.feel(_pulls[stake], alpha):
			stake.pull_out(world.height_under(stake.global_position))


func _draw(h: float) -> void:
	_clock += h
	for strand: RopeStrand in strands.duplicate():
		if strand.a != null and not _attached(strand.a):
			strand.a = null
		if strand.b != null and not _attached(strand.b):
			strand.b = null
		var middle := strand.points[strand.points.size() / 2]
		# A loose strand is gone with the ground it lay on. A held one goes
		# loose first, when the world forgets what it hangs from.
		if (strand.a == null or strand.b == null) \
				and not world.terrain.is_loaded_at(world.world_x(middle.x), world.world_z(middle.z)):
			strands.erase(strand)
			strand.queue_free()
			continue
		strand.step(h, world.weather.felt_wind(middle), _clock)
	for rope in ropes:
		if rope.creak == null:
			continue
		var strain := smoothstep(0.08, 0.9, rope.share()) if rope.is_taut() else 0.0
		# Paused, not stopped, so a line flicking taut and slack never seeks the stream.
		rope.creak.stream_paused = strain <= 0.0
		if strain <= 0.0:
			continue
		rope.creak.global_position = rope.strand.points[rope.strand.points.size() / 2]
		rope.creak.volume_db = lerpf(-26.0, 2.0, strain)
		rope.creak.pitch_scale = lerpf(0.85, 1.25, strain)
		if not rope.creak.playing:
			rope.creak.play(randf() * 20.0)


func _drop(rope: Rope) -> void:
	ropes.erase(rope)
	if rope.creak != null:
		rope.creak.queue_free()


func _lost_end(rope: Rope) -> RopeEnd:
	if not _attached(rope.a):
		return rope.a
	if not _attached(rope.b):
		return rope.b
	return null


func _attached(end: Object) -> bool:
	return is_instance_valid(end) and end.is_inside_tree() and is_instance_valid((end as RopeEnd).holder)


func _on_origin_shifted(by: Vector2i) -> void:
	var size := world.tuning.chunk_size
	var offset := Vector3(by.x * size, 0.0, by.y * size)
	for strand in strands:
		strand.shift(-offset)


func _crack_at(at: Vector3) -> void:
	if _crack == null:
		_crack = _crack_sound()
	var crack := AudioStreamPlayer3D.new()
	crack.stream = _crack
	crack.unit_size = 8.0
	crack.max_db = 6.0
	add_child(crack)
	crack.global_position = at
	crack.finished.connect(crack.queue_free)
	crack.play()


## A snap until there's a recording: a sharp burst of noise over a low thump.
static func _crack_sound() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.4)
	var data := PackedByteArray()
	data.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7
	for i in count:
		var t := float(i) / rate
		var sample := noise.randf_range(-1.0, 1.0) * exp(-t / 0.015) \
			+ sin(TAU * 70.0 * t) * exp(-t / 0.08) * 0.6
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 30000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = data
	return sound
