class_name Ropes
extends Node3D
## Every rope in the camp, solved together once a physics tick before anything
## else moves: you, the wind and the physics engine all act after it. Ropes
## belong to the camp, not the land, so they live here, never in a chunk, and
## their strands move with every origin shift. Whatever is in your hands or
## at your waist is you, as far as a rope is concerned: its pull lands on you.

signal snapped(rope: Rope)

## Passes over every rope per tick, so lines sharing a load agree on it.
const ITERATIONS := 2
## Cap on how much a body is expected to change speed in a tick, m/s² and
## rad/s², so one hard landing can't mislead the rope about the next.
const MAX_EXPECTED := 80.0
const MAX_EXPECTED_SPIN := 80.0
## A creak eases between quiet and its strain over this long, s, and its last
## share of that fades to silence: a line flicking taut and slack as you walk
## a tow would click each time the sound was cut.
const CREAK_EASE := 0.4
const CREAK_FADE := 0.15
const NO_TURN := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)
## Where a bare line in your hand ties on, in your own frame (the look-test's);
## a line's own end in your hand ties on where your hand holds it.
const HAND_AT := Vector3(0.3, 1.1, -0.35)
const WAIST_AT := Vector3(0.0, 0.95, 0.0)
## A line's end in your hand can swing this share past its length.
const SWING_SLACK := 0.02

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

var _tuning: Tuning
var _bodies := {}
var _tick := 0
var _pulls := {}
var _drag := Vector3.ZERO
var _sags := {}
var _crack: AudioStreamWAV


func _ready() -> void:
	process_physics_priority = -10
	# After the hands have placed what they hold this frame.
	process_priority = 10


func setup(on: World) -> void:
	world = on
	_tuning = world.tuning
	var groan: AudioStreamOggVorbis = Sounds.CREAK
	groan.loop = true
	creak = groan
	world.origin_shifted.connect(_on_origin_shifted)
	hand = RopeEnd.make(world.player, HAND_AT, false)
	waist = RopeEnd.make(world.player, WAIST_AT, false)


## A line between two ends; NAN breaking is common rope's. A strand already
## drawn (half of a snapped line) can carry on as this one's.
func tie(a: RopeEnd, b: RopeEnd, length: float, breaking := NAN, strand: RopeStrand = null) -> Rope:
	var rope := Rope.new()
	rope.a = a
	rope.b = b
	# Never none at all: a line of no length has no catenary to hang.
	rope.length = maxf(length, 0.05)
	rope.full = rope.length
	rope.breaking = _tuning.rope_breaking if is_nan(breaking) else breaking
	rope.kg_per_m = _tuning.rope_kg_per_m
	rope.frequency = _tuning.rope_hertz
	rope.damping = _tuning.rope_damping
	rope.max_stretch = _tuning.rope_max_stretch
	if strand == null:
		strand = RopeStrand.new()
		add_child(strand)
		strand.hang(world, length, a, b)
	else:
		strand.a = a
		strand.b = b
	rope.strand = strand
	if not strands.has(strand):
		strands.append(strand)
	if creak != null:
		rope.creak = Sounds.world_voice(creak, 0.0, 5.0)
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


## A line gone altogether, rope and strand: rolled up into its coil.
func untie(rope: Rope) -> void:
	_drop(rope)
	# A strand left hanging may be gone with its ground already, and out of strands.
	if is_instance_valid(rope.strand):
		strands.erase(rope.strand)
		rope.strand.queue_free()


## A line breaks in two; whatever owns it makes lines of the halves unless
## `halves` is false.
func snap(rope: Rope, halves := true) -> void:
	var tail := rope.strand.cut(rope.strand.points.size() / 2)
	add_child(tail)
	strands.append(tail)
	if creak != null:
		_crack_at(tail.points[0])
	_drop(rope)
	snapped.emit(rope)
	if halves and rope.parted.is_valid():
		rope.parted.call(rope.strand, tail)


func lines_on(end: RopeEnd) -> Array[Rope]:
	return ropes.filter(func(rope: Rope) -> bool: return rope.a == end or rope.b == end)


## Whether a body is on you: in your hands or at your waist.
func on_you(body: Node) -> bool:
	var player := world.player
	return body == player or (body != null and (body == player.hands.held or player.waist.holds(body)))


## Whether a line ties to your waist with its other end off you: what slows you.
func at_waist(rope: Rope) -> bool:
	var a_waist := _waist_end(rope.a)
	var b_waist := _waist_end(rope.b)
	return (a_waist and not on_you(rope.b.holder)) or (b_waist and not on_you(rope.a.holder))


## Where a line's end in your hand can be, wanting to be at `want`: no further
## from the other end of each of its lines than the line reaches, or than
## your body is less an arm's length. Holding a loaded line your arm follows
## it, so turning round swings your view, never a yank down the line. A line
## still paying out reaches as far as its coil holds.
func reach(end: RopeEnd, want: Vector3) -> Vector3:
	var body := world.player.global_position + Vector3.UP * HAND_AT.y
	for rope in lines_on(end):
		var other := (rope.b if rope.a == end else rope.a).global_position
		var most := maxf((rope.full if rope.paying else rope.length) * (1.0 + SWING_SLACK),
			other.distance_to(body) - _tuning.hold_distance)
		var off := want - other
		if off.length() > most:
			want = other + off.normalized() * most
	return want


func _waist_end(end: RopeEnd) -> bool:
	return end == waist or world.player.waist.holds(end.holder)


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


## Every drawn frame, a line's ends are drawn where its rings are now: after
## the physics step has moved them, and where your hand has what you hold.
func _process(_delta: float) -> void:
	for rope in ropes:
		if is_instance_valid(rope.a) and is_instance_valid(rope.b):
			rope.strand.pin_ends(rope.a.global_position, rope.b.global_position)


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
		rope.prepare(h, world.gravity)
		if rope.torn():
			# Its ends jumped apart (a dev teleport): no rope stretches to twice
			# its length, so it parts rather than fling what's on it, with no
			# break anywhere to leave new ends at.
			snap(rope, false)
			continue
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
	if on_you(holder):
		holder = world.player
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
		body.inv_mass = Vector3(1.0, 0.0, 1.0) / _tuning.player_mass
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


## A pull on you from your hands, N·s: it drags you as a line's would.
func pull_player(impulse: Vector3) -> void:
	_drag += impulse / _tuning.player_mass


## Your share of the pull, plus the waist tie's price. The player applies it
## through its one hook, the rope_drag meta.
func _drag_player(h: float) -> void:
	var player := world.player
	var tied := ropes.any(at_waist)
	var own: Vector3 = player.velocity - player.get_meta(&"rope_drag", Vector3.ZERO)
	own.y = 0.0
	if tied:
		var wind := world.weather.felt_wind(player.global_position)
		_drag += wind * wind.length() * _tuning.waist_catch * h / _tuning.player_mass
	# Exact over the tick, so dragging plays out the same at any tick rate.
	var speed := _drag.length()
	if speed > 0.0:
		var floor_speed := _tuning.grip / _tuning.grip_per_speed
		var after := maxf(0.0, (speed + floor_speed) * exp(-_tuning.grip_per_speed * h) - floor_speed)
		_drag *= after / speed
	# Slower only while you walk, so the wind's own shove on you isn't eased.
	var walking := player.mode == "walk" or player.mode == "sprint"
	player.set_meta(&"rope_drag", _drag - own * _tuning.waist_slow if tied and walking else _drag)


## Sustained load breaks ropes and pulls stakes; a spike alone never does.
func _bear(h: float) -> void:
	var alpha := 1.0 - exp(-h / _tuning.rope_load_seconds)
	for rope: Rope in ropes.duplicate():
		rope.sustained += (rope.tension - rope.sustained) * alpha
		if rope.sustained > rope.breaking:
			snap(rope)
	for stake: Node3D in _pulls:
		if stake.feel(_pulls[stake], alpha):
			stake.pull_out(world.height_under(stake.global_position))


func _draw(h: float) -> void:
	_sags.clear()
	for rope in ropes:
		_sags[rope.strand] = rope.sag
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
		strand.step(h, world.weather.felt_wind(middle), _sags.get(strand, NAN))
	for rope in ropes:
		if rope.creak == null:
			continue
		var strain := smoothstep(0.08, 0.9, rope.share()) if rope.is_taut() else 0.0
		rope.creak_level = move_toward(rope.creak_level, strain, h / CREAK_EASE)
		# Paused, not stopped, once silent, so it never seeks the stream.
		rope.creak.stream_paused = rope.creak_level <= 0.0
		if rope.creak_level <= 0.0:
			continue
		rope.creak.global_position = rope.strand.points[rope.strand.points.size() / 2]
		var fade := minf(rope.creak_level / CREAK_FADE, 1.0)
		rope.creak.volume_db = lerpf(-30.0, -2.0, rope.creak_level) + linear_to_db(maxf(fade, 0.001))
		rope.creak.pitch_scale = lerpf(0.85, 1.25, rope.creak_level)
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
	# Startling, as a snap should be, but well short of the old clank.
	var crack := Sounds.world_voice(_crack, -10.0, 8.0)
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
