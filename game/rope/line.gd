class_name Line
extends Node3D
## A rope you lay. Found as a coil, it gives you its first end when you pick it
## up, with the rest on your belt. Snap that end onto a ring, or tie it at your
## waist, and the coil comes to your hand, paying out as you walk off, up to its
## length; wherever its second end goes, the line's length is set there. Any
## loose end can be taken up again. Take up an end of a line lying loose at
## both ends and it rolls back up, ready to lay again; drop its first end
## before it's on anything and the coil goes down whole, or in with what you
## carry if that's where you put it. Snapped, it parts into two lines, each with a
## loose end where it broke.

enum State { COILED, FIRST, PAYING, LAID }

## A line ties on at its end's tip, in the end's own frame.
const END_AT := Vector3(0.0, 0.0, 0.08)
## Shortest a line lays, m.
const SHORTEST := 0.5

var state := State.COILED
## The coil while it's rolled up; its two ends once it's out.
var coil: Part
var ends: Array[Part] = []
var rope: Rope
## The longest it lays, m.
var full := 12.0
var routed_by_player := false
var route_loaded_seconds := 0.0
## Which end went first; the other is the coil's.
var _first := 0
var _world: World


## A coil of `length` metres, lying loose; place it with `coil`. Given a
## found coil, it's that one.
static func make(world: World, length: float, found: Part = null) -> Line:
	var line := Line.new()
	line._world = world
	line.full = length
	world.content.add_child(line)
	if found != null:
		line.coil = found
		found.set_meta(&"line", line)
	else:
		line._coil_up()
	return line


## A line already laid between two free tie sockets, `slack` metres longer
## than the way between them: a camp found staked out, or a probe's rig.
static func between(world: World, from: Socket, to: Socket, slack := 0.3) -> Line:
	var line := Line.new()
	line._world = world
	world.content.add_child(line)
	for socket in [from, to]:
		var end := line._end((socket.get_parent() as Node3D).global_transform * socket.transform)
		(socket.get_parent() as Device).fit(end, socket)
		line.ends.append(end)
	var span := _tip(line.ends[0]).global_position.distance_to(_tip(line.ends[1]).global_position)
	line.full = maxf(span + slack, SHORTEST)
	line._tie(line.full)
	line.state = State.LAID
	return line


## A line already laid from a device's free tie socket to your waist, `slack`
## metres longer than the way between them: a kit's sheet, a scenario's.
static func to_waist(world: World, tie: Socket, slack: float) -> Line:
	var line := Line.new()
	line._world = world
	world.content.add_child(line)
	var device := tie.get_parent() as Device
	var at := device.global_transform * tie.transform
	var ends: Array[Part] = [line._end(at), line._end(world.player.global_transform)]
	device.fit(ends[0], tie)
	world.player.waist.tie(ends[1])
	line.ends = ends
	var span := _tip(ends[0]).global_position.distance_to(_tip(ends[1]).global_position)
	line.full = maxf(span + slack, SHORTEST)
	line._tie(line.full)
	line.state = State.LAID
	return line


func _ready() -> void:
	# Before the ropes are solved, and before the hands move on this tick.
	process_physics_priority = -20


## What the look-at line says about it: rolled up, how long it is. Laid,
## nothing: its length shows, and its strain creaks.
func readout() -> Dictionary:
	if rope == null or not _world.ropes.ropes.has(rope):
		return {"rope_m": full}
	return {}


## Whether it rolls up to carry: held but not laid, its first end in your
## hand and the rest on your belt, with nothing letting go of it there.
func stowable() -> bool:
	var waist := _world.player.waist
	return state == State.FIRST and _world.player.hands.held == ends[_first] \
		and waist.holds(ends[1 - _first]) and waist.untying < 0.0


## Rolled back up to carry: the line goes, and a coil off the tree stands
## for it, as a found one does, keeping its length to lay again.
func roll() -> Part:
	_world.ropes.untie(rope)
	rope = null
	for end in ends:
		_world.player.waist.untie(end)
		_gone(end)
	ends.clear()
	state = State.COILED
	_gone(self)
	var rolled := Catalog.part(&"coil")
	rolled.set_meta(&"rolled", &"coil")
	rolled.set_meta(&"rolled_m", full)
	return rolled


## Out of the world at once, so nothing meets it before it's freed.
static func _gone(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.queue_free()


func _physics_process(delta: float) -> void:
	var hands := _world.player.hands
	if state == State.COILED:
		if not is_instance_valid(coil):
			queue_free()
		elif hands.held == coil:
			_uncoil()
		return
	if not ends.all(func(end: Variant) -> bool: return is_instance_valid(end)) or rope == null \
			or not _world.ropes.ropes.has(rope):
		_lost()
		return
	if routed_by_player and is_instance_valid(rope.through) and rope.sustained >= _world.tuning.deed_fairlead_n:
		route_loaded_seconds += delta * _world.time_warp
		if route_loaded_seconds >= _world.tuning.deed_fairlead_seconds:
			Deeds.done(_world, &"fairlead")
	else:
		route_loaded_seconds = 0.0
	var first := ends[_first]
	var other := ends[1 - _first]
	match state:
		State.FIRST:
			if hands.held == first:
				_pay()
			elif _placed(first):
				# The first end is on: the coil comes to your hand, paid out to
				# wherever that end went.
				_world.player.waist.untie(other)
				hands.hold(other)
				_pay()
				state = State.PAYING
			else:
				_roll_up(first)
		State.PAYING:
			if hands.held == other:
				_pay()
			else:
				# Laid, long enough at least to reach where its second end went.
				_pay(rope.length)
				rope.paying = false
				rope.kg_per_m = _world.tuning.rope_kg_per_m
				state = State.LAID
		State.LAID:
			var taken := ends.find(hands.held) if hands.held is Part else -1
			if taken != -1 and _loose(ends[1 - taken]):
				# Loose at both ends: it rolls up onto your belt, to lay again.
				_first = taken
				_world.player.waist.tie(ends[1 - taken])
				state = State.FIRST
				_pay()


## Picked up: its first end in your hand, the rest on your belt.
func _uncoil() -> void:
	var hands := _world.player.hands
	var at := coil.global_transform
	hands.stow()
	ends = [_end(at), _end(at.translated(Vector3.UP * 0.05))]
	_first = 0
	coil.queue_free()
	coil = null
	_world.player.waist.tie(ends[1])
	hands.hold(ends[0])
	_tie(full)
	state = State.FIRST
	_pay()
	# Draped afresh at its short length, with all the points it will pay out to.
	rope.strand.hang(_world, rope.length, rope.a, rope.b, RopeStrand.MAX_POINTS - 1)


## Its length follows the way between its ends while the coil pays out, never
## under `least`, and a coil feeding out pulls nothing until it's all out.
func _pay(least := SHORTEST) -> void:
	var span := rope.a.global_position.distance_to(rope.b.global_position)
	if is_instance_valid(rope.through):
		span = rope.a.global_position.distance_to(rope.through.global_position) \
			+ rope.through.global_position.distance_to(rope.b.global_position)
	var length := clampf(span + _world.tuning.rope_pay_slack, least, full)
	rope.paying = true
	rope.length = length
	rope.kg_per_m = 0.0 if length < full else _world.tuning.rope_kg_per_m
	rope.strand.set_length(length)


## Passing the held end through a ring changes the path, never the amount of rope.
func route(guide: RopeEnd) -> String:
	if rope == null or not state in [State.PAYING, State.LAID]:
		return "tie the first end before passing the line through a hook"
	if rope.through == guide:
		rope.through = null
	elif is_instance_valid(rope.through):
		return "remove this line's existing route first"
	else:
		var span := rope.a.global_position.distance_to(guide.global_position) \
			+ guide.global_position.distance_to(rope.b.global_position)
		if span > full:
			return "not enough rope to pass through that hook"
		if state == State.LAID and span > rope.length * (1.0 + rope.max_stretch):
			return "pay out more rope before passing through that hook"
		rope.through = guide
		if state == State.PAYING:
			_pay()
	# A changed path cannot reuse an impulse from the old direction.
	rope.spring_impulse = 0.0
	rope.stop_impulse = 0.0
	rope.strand.through = rope.through
	routed_by_player = rope.through != null
	route_loaded_seconds = 0.0
	return ""


## Dropped before its first end was on anything: the coil goes down whole,
## where that end went, moving as it was.
func _roll_up(went: Part) -> void:
	var at := went.global_transform
	var moving := went.linear_velocity
	_world.ropes.untie(rope)
	rope = null
	for end in ends:
		_world.player.waist.untie(end)
		end.queue_free()
	ends.clear()
	_coil_up()
	var ground := _world.height_under(at.origin)
	coil.global_transform = Transform3D(Basis(Vector3.UP, at.basis.get_euler().y) * Basis(Vector3.RIGHT, -PI / 2.0),
		Vector3(at.origin.x, maxf(at.origin.y, ground + 0.05), at.origin.z))
	coil.linear_velocity = moving
	state = State.COILED


func _coil_up() -> void:
	coil = Catalog.part(&"coil")
	coil.set_meta(&"line", self)
	_world.content.add_child(coil)


## On a ring, or tied at your waist: somewhere the coil can pay out from.
func _placed(end: Part) -> bool:
	return end.socket != null or _world.player.waist.holds(end)


## Lying free in the world: on nothing, not on you.
func _loose(end: Part) -> bool:
	return end.socket == null and end.is_inside_tree() and not _world.ropes.on_you(end)


func _end(at: Transform3D) -> Part:
	var end := Catalog.part(&"rope_end")
	end.set_meta(&"line", self)
	# Kept, since fitted it moves into the device with the end's other pieces.
	end.set_meta(&"tip", RopeEnd.make(end, END_AT, false))
	_world.content.add_child(end)
	end.global_transform = at
	return end


func _tie(length: float, strand: RopeStrand = null) -> void:
	rope = _world.ropes.tie(_tip(ends[0]), _tip(ends[1]), length, NAN, strand)
	rope.full = maxf(full, rope.length)
	rope.parted = _parted


static func _tip(end: Part) -> RopeEnd:
	return end.get_meta(&"tip")


## Snapped: this line keeps its first half, a new one takes the second, and
## each gets a loose end where it broke, or as near it as that half reaches.
func _parted(head: RopeStrand, tail: RopeStrand) -> void:
	var breaking := rope.breaking
	var cut := head.points[head.points.size() - 1]
	var at_a := _loose_end(_tip(ends[0]).global_position, cut, maxf(head.length, SHORTEST), head)
	var at_b := _loose_end(_tip(ends[1]).global_position, cut, maxf(tail.length, SHORTEST), tail)
	var second := Line.new()
	second._world = _world
	_world.content.add_child(second)
	second.ends = [at_b, ends[1]]
	ends[1].set_meta(&"line", second)
	at_b.set_meta(&"line", second)
	second.full = maxf(tail.length, SHORTEST)
	second.rope = _world.ropes.tie(_tip(at_b), _tip(ends[1]), second.full, breaking, tail)
	second.rope.parted = second._parted
	second.state = State.LAID
	ends = [ends[0], at_a]
	full = maxf(head.length, SHORTEST)
	rope = _world.ropes.tie(_tip(ends[0]), _tip(at_a), full, breaking, head)
	rope.parted = _parted
	state = State.LAID


## A half's new loose end: at the break if the half reaches it from the end
## it keeps, else as far toward it as it does, its strand hung afresh there.
func _loose_end(kept: Vector3, cut: Vector3, length: float, strand: RopeStrand) -> Part:
	var at := kept + (cut - kept).limit_length(length * 0.9)
	# On the sand, and still within reach once it's there.
	at.y = maxf(at.y, _world.height_under(at) + 0.04)
	at = kept + (at - kept).limit_length(length * 0.9)
	var out := (at - kept).normalized() if at.distance_to(kept) > 1e-3 else Vector3.FORWARD
	var end := _end(_facing(at, out))
	if at.distance_to(cut) > 0.01:
		strand.hang(_world, length, strand.a if strand.a != null else _tip(end),
			strand.b if strand.b != null else _tip(end), strand.points.size() - 1)
	return end


## An end lying along the line at a place, its tip toward `out`.
func _facing(at: Vector3, out: Vector3) -> Transform3D:
	var ground := _world.height_under(at) + 0.04
	at.y = maxf(at.y, ground)
	var up := Vector3.UP if absf(out.y) < 0.9 else Vector3.FORWARD
	return Transform3D(Basis.looking_at(-out, up), at)


## Its rope is gone without parting (torn by a teleport), or an end is gone
## with the land it lay on: so is the line. What's left is a bare end.
func _lost() -> void:
	if rope != null and _world.ropes.ropes.has(rope):
		_world.ropes.untie(rope)
	rope = null
	for end in ends:
		if is_instance_valid(end):
			# A bare end left after a lost line is no longer a waist tether.
			if _world.player.waist.holds(end):
				_world.player.waist.untie(end)
			end.remove_meta(&"line")
	queue_free()
