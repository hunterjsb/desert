class_name Snapshot
extends RefCounted
## A run as its save holds it: only what's yours and what you changed. The
## ground, the weather and the finds come again from the seed, so the save
## keeps you, the clock, everything of yours in the world with its parts and
## state, every line between them, and of the finds near you only which were
## taken and how hard the weather had been there. Places are world metres;
## the engine origin is kept too, so a resumed run computes in the same
## floats as the one saved and plays on tick for tick.
##
## It reaches into the systems' own state (a strand's points, a solver's
## warm start) because that state is the run: anything left out shows up as
## a resumed run drifting from one never saved, which the round-trip probe
## measures.

## What each kind of thing keeps besides where it is, by property.
static var _kept := [
	[Stake, ["driven", "pulled", "sustained", "holding", "pull"]],
	[ShieldGenerator, ["on", "size", "_up", "_since"]],
	[Planter, ["tank_l", "split", "stored", "seeds", "ripened", "replanted", "banked", "dropped", "picked",
		"fed_kcal", "_gives", "_owed"]],
	[Condenser, ["made_l"]],
	[Battery, ["charge_wh"]],
	[Plant, ["growth", "state"]],
]
const PLAYER := ["stamina", "flying", "mode", "crouched", "own", "slope", "wind", "low", "sink", "_sliding",
	"_jumped", "_since_ground", "_touchdown", "_jump_buffer", "_jump_was", "_jump_queued", "_crouch_was",
	"_on_sand", "_left"]
const VITALS := ["health", "hunger", "thirst", "dead", "harms", "taken", "drunk", "eaten", "_next"]
const ROPE := ["length", "kg_per_m", "breaking", "frequency", "damping", "max_stretch", "tension", "sustained",
	"spring_impulse", "stop_impulse"]
const STRAND := ["length", "_rest", "_velocity", "_ground", "_slope", "_near", "_bulge", "_age", "_phase",
	"_hanging", "_bow"]

var _world: World
## Capture: the number each body is known by. Restore: the body each number made.
var _refs := {}
var _made := {}
## Restore: [body, record] for every body made, whose state goes on last.
var _states: Array[Array] = []


func _init(world: World) -> void:
	_world = world


## The run as it stands, changing nothing.
static func take(world: World) -> Dictionary:
	return Snapshot.new(world)._take()


## Why a save can't be resumed in this build ("" if it can): things the
## catalog no longer knows. Asked before anything of the world is touched.
static func problem(data: Dictionary) -> String:
	var unknown := PackedStringArray()
	var look := func(rec: Dictionary, again: Callable) -> void:
		if rec.has("id") and not (Catalog.PARTS.has(rec.id) or Catalog.DEVICES.has(rec.id) or rec.id == &"stake"):
			unknown.append(str(rec.id))
		for entry: Array in rec.get("sockets", []) + rec.get("added", []):
			again.call(entry[1], again)
		if rec.has("mounted"):
			again.call(rec.mounted, again)
	for rec: Dictionary in data.get("things", []) + data.get("slots", []).filter(func(r: Variant) -> bool: return r != null):
		look.call(rec, look)
	return "" if unknown.is_empty() else "it holds things this build doesn't know: " + ", ".join(unknown)


## First half of a resume, on a fresh world built on the save's seed: the
## world's own things go, and the clock, the origin, you and the finds'
## memory are put back. Returns where the rest will stand, world metres, so
## the caller can wait for the ground there.
func begin(data: Dictionary) -> Array[Vector2]:
	_clear()
	var world := _world
	# A resumed run has its own things: no new run's kit is set down in it.
	world.set_meta(&"resumed", true)
	world.time = data.time
	world.set_gravity(data.gravity)
	world.shift_origin(data.origin - world.origin_chunk)
	var moon: Dictionary = data.moon
	for key: String in moon:
		world.moon.set(key, moon[key])
	world._last_x = data.last[0]
	world._last_z = data.last[1]
	world.power._next = data.ticks.power
	world.wear._next = data.ticks.wear
	world.farm._next = data.ticks.farm
	world.power.generated_wh = data.ledger[0]
	world.power.used_wh = data.ledger[1]
	world.power.spilled_wh = data.ledger[2]
	var you: Dictionary = data.player
	var player := world.player
	player.global_transform = _transform_in(you.at)
	player.camera.rotation.x = you.pitch
	player.velocity = you.v
	for key: String in you.state:
		player.set(key, you.state[key])
	player.set_meta(&"rope_drag", you.drag)
	for key: String in you.vitals:
		player.vitals.set(key, _copy(you.vitals[key]))
	world.weather.forecast_now()
	world.salvage.recall(data.finds, world.terrain.chunk_at(world.player_world_x(), world.player_world_z()))
	var places: Array[Vector2] = [Vector2(world.player_world_x(), world.player_world_z())]
	for rec: Dictionary in data.things:
		places.append(Vector2(rec.at[1], rec.at[3]))
	return places


## Second half, once the ground under all of it is solid: everything of
## yours, its lines, your slots, hands and waist.
func finish(data: Dictionary) -> void:
	var world := _world
	var ropes := world.ropes
	var lines: Array[Line] = []
	for rec: Dictionary in data.lines:
		lines.append(_line(rec))
	var cables: Array[Cable] = []
	for rec: Dictionary in data.cables:
		var cable := Catalog.cable(world, Vector3.ZERO, rec.strong)
		cable.length = rec.length
		for i in 2:
			_made[rec.plugs[i]] = cable.plugs[i]
		cables.append(cable)
	for rec: Dictionary in data.things:
		var body := _make(rec)
		if body.get_parent() == null:
			world.content.add_child(body)
		body.global_transform = _transform_in(rec.at)
		body.linear_velocity = rec.v
		body.angular_velocity = rec.w
		body.freeze = rec.freeze
		body.sleeping = rec.sleeping
		if rec.world_froze:
			body.set_meta(&"frozen_by_world", true)
	var suit := world.player.suit
	for i in suit.slots.size():
		if suit.slots[i] != null:
			suit.slots[i].free()
		var rec: Variant = data.slots[i] if i < data.slots.size() else null
		suit.slots[i] = _make(rec) as Part if rec != null else null
	for pair in _states:
		_set_state(pair[0], pair[1])
	# The lines last: their ends are all where they belong now.
	var strands: Array[RopeStrand] = []
	for rec: Dictionary in data.strands:
		strands.append(null)
	for i in lines.size():
		var rec: Dictionary = data.lines[i]
		if rec.rope != null and lines[i].rope != null:
			strands[rec.rope.strand] = _rope_in(lines[i].rope, rec.rope)
	for i in cables.size():
		var rec: Dictionary = data.cables[i]
		var strong := cables[i] as StrongCable
		if strong == null:
			continue
		if rec.rope == null:
			ropes.untie(strong.rope)
			strong.rope = null
		else:
			strands[rec.rope.strand] = _rope_in(strong.rope, rec.rope)
	for i in strands.size():
		var strand := strands[i]
		if strand == null:
			# Left lying when a line let go: drawn only.
			strand = RopeStrand.new()
			ropes.add_child(strand)
			strand.world = world
			ropes.strands.append(strand)
		_strand_in(strand, data.strands[i])
	# Solved in the order they were: lines sharing a load settle it in turn.
	var was := []
	for rec: Dictionary in data.lines + data.cables:
		if rec.rope != null:
			was.append(rec.rope.index)
	if was.size() == ropes.ropes.size():
		var pairs := range(was.size())
		pairs.sort_custom(func(i: int, j: int) -> bool: return was[i] < was[j])
		var tied := ropes.ropes.duplicate()
		for k in pairs.size():
			ropes.ropes[k] = tied[pairs[k]]
	_solver_in(data.solver)
	_order(data.order, lines, cables)
	var hands := world.player.hands
	var waist := world.player.waist
	for ref: int in data.waist.tied:
		if _made.has(ref):
			waist.tie(_made[ref])
	waist.untying = data.waist.untying
	waist._to_hand = data.waist.to_hand
	var held: Variant = data.hands.get("held")
	if held != null and _made.has(held):
		var body: RigidBody3D = _made[held]
		hands._grip(body)
		hands._carry = data.hands.carry
		hands.phase = Hands.Phase.HELD
		hands._ticked = body.global_transform
	var grasped: Variant = data.grasp.get("body")
	if grasped != null and _made.has(grasped):
		var grasp := hands.grasp
		grasp.body = _made[grasped]
		grasp._beside = data.grasp.beside
		grasp._turned = data.grasp.turned
		grasp._heading = data.grasp.heading
		grasp._slipping = data.grasp.slipping


func _take() -> Dictionary:
	var world := _world
	var ropes := world.ropes
	var player := world.player
	var hands := player.hands
	var data := {"seed": world.run_seed, "time": world.time, "gravity": world.gravity, "origin": world.origin_chunk,
		"moon": {"latitude": world.moon.latitude, "longitude": world.moon.longitude,
			"_spawn_latitude": world.moon._spawn_latitude, "_spawn_longitude": world.moon._spawn_longitude,
			"_facing": world.moon._facing},
		"last": [world._last_x, world._last_z],
		"ticks": {"power": world.power._next, "wear": world.wear._next, "farm": world.farm._next},
		"ledger": [world.power.generated_wh, world.power.used_wh, world.power.spilled_wh]}
	var you := {"at": _transform_out(player.global_transform), "pitch": player.camera.rotation.x,
		"v": player.velocity, "drag": player.get_meta(&"rope_drag", Vector3.ZERO), "state": {}, "vitals": {}}
	for key in PLAYER:
		you.state[key] = player.get(key)
	for key in VITALS:
		you.vitals[key] = _copy(player.vitals.get(key))
	data.player = you
	var things := []
	var lines: Array[Line] = []
	var cables: Array[Cable] = []
	var order := []
	for child in world.content.get_children():
		if child is Line:
			order.append(["l", lines.size()])
			lines.append(child)
		elif child is Cable:
			order.append(["c", cables.size()])
			cables.append(child)
		elif child is RigidBody3D and child.has_meta(&"catalog"):
			order.append(["b", _ref(child)])
			things.append(_body(child, true))
	# A part sliding out of a device holds the device still a moment: it's
	# saved as it was, since a resumed part is simply in your hands.
	if is_instance_valid(hands._source) and _refs.has(hands._source):
		for rec: Dictionary in things:
			if rec.ref == _refs[hands._source]:
				rec.freeze = hands._source_was.freeze
				rec.v = hands._source_was.velocity
				rec.w = hands._source_was.spin
	data.things = things
	data.order = order
	data.slots = player.suit.slots.map(func(p: Part) -> Variant: return _body(p, false) if _known(p) else null)
	var strands := ropes.strands.filter(func(s: RopeStrand) -> bool: return is_instance_valid(s))
	data.lines = lines.map(func(line: Line) -> Dictionary: return {"state": line.state, "full": line.full,
		"first": line._first, "coil": _ref(line.coil) if is_instance_valid(line.coil) else null,
		"ends": line.ends.map(_ref),
		"rope": _rope_out(line.rope, strands) if line.rope != null and ropes.ropes.has(line.rope) else null})
	data.cables = cables.map(func(cable: Cable) -> Dictionary: return {"strong": cable is StrongCable,
		"length": cable.length, "plugs": cable.plugs.map(_ref),
		"rope": _rope_out(cable.rope, strands) if cable is StrongCable and cable.rope != null else null})
	data.strands = strands.map(_strand_out)
	data.solver = {"tick": ropes._tick, "drag": ropes._drag, "bodies": []}
	for body: RopeBody in ropes._bodies.values():
		if is_instance_valid(body.node) and (body.node == player or _refs.has(body.node)):
			data.solver.bodies.append(["player" if body.node == player else _refs[body.node], body.tick, body.left,
				body.left_spin])
	data.waist = {"tied": player.waist.tied.filter(_known).map(_ref), "untying": player.waist.untying,
		"to_hand": player.waist._to_hand}
	data.hands = {}
	if hands.held != null and _known(hands.held):
		data.hands = {"held": _ref(hands.held), "carry": hands._carry}
		for rec: Dictionary in things:
			if rec.ref == data.hands.held:
				# Where the tick has it, not where this frame drew it.
				rec.at = _transform_out(hands._ticked if hands.phase == Hands.Phase.HELD else hands.held.global_transform)
	var grasp := hands.grasp
	data.grasp = {}
	if is_instance_valid(grasp.body) and _known(grasp.body):
		data.grasp = {"body": _ref(grasp.body), "beside": grasp._beside, "turned": grasp._turned,
			"heading": grasp._heading, "slipping": grasp._slipping}
	data.finds = world.salvage.memories()
	return data


func _known(body: Variant) -> bool:
	return is_instance_valid(body) and body.has_meta(&"catalog")


func _ref(node: Object) -> int:
	if not _refs.has(node):
		_refs[node] = _refs.size()
	return _refs[node]


## A body as its catalog id and what's changed from a fresh one: loose, where
## it is and how it moves; a device, what's in each of its sockets.
func _body(body: RigidBody3D, loose: bool) -> Dictionary:
	var out := {"ref": _ref(body), "id": body.get_meta(&"catalog"), "state": _state(body)}
	if loose:
		out.at = _transform_out(body.global_transform)
		out.v = body.linear_velocity
		out.w = body.angular_velocity
		out.freeze = body.freeze
		out.sleeping = body.sleeping
		out.world_froze = body.get_meta(&"frozen_by_world", false)
	if body.has_meta(&"layer"):
		out.found = body.get_meta(&"layer")
	# Packed in a found case, it unrolls into a line or a cable once taken out.
	if body.has_meta(&"rolled"):
		out.rolled = body.get_meta(&"rolled")
	if body is Device:
		var filled := []
		var frame := (body as Device).sockets().filter(func(s: Socket) -> bool: return not s.has_meta(&"socket"))
		for i in frame.size():
			var inside := _socket_out(frame[i])
			if not inside.is_empty():
				filled.append([i, inside])
		out.sockets = filled
	return out


## What sits in a socket: a part, and whatever sits in the sockets it added
## (a line's end on a hook's ring); or a small device seated there.
func _socket_out(socket: Socket) -> Dictionary:
	if _known(socket.part):
		var out := _body(socket.part, false)
		var added := socket.fitted.filter(func(n: Node) -> bool: return n is Socket)
		var inner := []
		for k in added.size():
			var inside := _socket_out(added[k])
			if not inside.is_empty():
				inner.append([k, inside])
		if not inner.is_empty():
			out.added = inner
		return out
	if socket.mounted != null and _known(socket.mounted):
		var seated := socket.mounted
		# Where it rides on its host now, which needn't be just its seat.
		return {"mounted": _body(seated, false), "pose": socket.get_parent().global_transform.affine_inverse()
			* seated.global_transform}
	return {}


func _state(body: RigidBody3D) -> Dictionary:
	var out := {}
	for entry: Array in _kept:
		if is_instance_of(body, entry[0]):
			for key: String in entry[1]:
				out[key] = _copy(body.get(key))
	var device := body as Device
	if device != null:
		out.durability = device.durability
		out.powered = device.powered
	var part := body as Part
	if part != null:
		var stats: Dictionary = Catalog.PARTS.get(body.get_meta(&"catalog"), {}).get("stats", {})
		if part.stats != stats:
			out.stats = part.stats.duplicate(true)
		if part is Supply:
			out.amount = part.amount
	return out


func _set_state(body: RigidBody3D, rec: Dictionary) -> void:
	var state: Dictionary = rec.state
	var part := body as Part
	if part != null and state.has("stats"):
		part.stats = state.stats.duplicate(true)
	for key: String in state:
		if key in ["durability", "powered", "stats", "amount"]:
			continue
		body.set(key, _copy(state[key]))
	if body is Battery:
		body.show_charge()
	elif body is Supply:
		body._keep(state.amount)
	elif body is Plant:
		body.set_growth(state.growth)
		body.state = state.state
	var device := body as Device
	if device == null:
		return
	device.durability = state.durability
	device.set_powered(state.powered)
	var shield := device as ShieldGenerator
	if shield != null:
		var since: float = shield._since
		shield.stand(shield.on)
		shield._up = state._up
		shield._since = since
		if not shield._up:
			shield.hum.stop()
		shield._show()


## A body for a record: one its owner made already (a line's end, a cable's
## plug), or a fresh one from the catalog, with what's in its sockets fitted
## before it's in the world, so nothing fitting it lifts it off the sand.
func _make(rec: Dictionary) -> RigidBody3D:
	var body: RigidBody3D = _made.get(rec.ref)
	if body == null:
		var id: StringName = rec.id
		body = Catalog.stake() if id == &"stake" else (Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id))
		_made[rec.ref] = body
	_states.append([body, rec])
	if rec.has("found"):
		Finds.mark(body, rec.found)
	if rec.has("rolled"):
		body.set_meta(&"rolled", rec.rolled)
	var device := body as Device
	if device != null:
		device.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		var frame := device.sockets().filter(func(s: Socket) -> bool: return not s.has_meta(&"socket"))
		for entry: Array in rec.get("sockets", []):
			_socket_in(device, frame[entry[0]], entry[1])
	return body


func _socket_in(device: Device, socket: Socket, rec: Dictionary) -> void:
	if rec.has("mounted"):
		var seated := _make(rec.mounted) as Device
		device.mount(seated, socket)
		seated.transform = rec.pose
		return
	device.fit(_make(rec) as Part, socket)
	var added := socket.fitted.filter(func(n: Node) -> bool: return n is Socket)
	for entry: Array in rec.get("added", []):
		_socket_in(device, added[entry[0]], entry[1])


## A line as it was, its ends or coil made where they'll be put; its rope is
## tied now and given its state once everything is in place.
func _line(rec: Dictionary) -> Line:
	var line := Line.new()
	line._world = _world
	_world.content.add_child(line)
	line.state = rec.state
	line.full = rec.full
	line._first = rec.first
	if rec.coil != null:
		line._coil_up()
		_made[rec.coil] = line.coil
	for ref: int in rec.ends:
		var end := line._end(Transform3D.IDENTITY)
		line.ends.append(end)
		_made[ref] = end
	if rec.rope != null and line.ends.size() == 2:
		line._tie(rec.rope.length)
	return line


func _rope_out(rope: Rope, strands: Array) -> Dictionary:
	var out := {"strand": strands.find(rope.strand), "index": _world.ropes.ropes.find(rope)}
	for key in ROPE:
		out[key] = rope.get(key)
	return out


## Returns its strand, to be given its points next.
func _rope_in(rope: Rope, rec: Dictionary) -> RopeStrand:
	for key in ROPE:
		rope.set(key, rec[key])
	return rope.strand


func _strand_out(strand: RopeStrand) -> Dictionary:
	var out := {"points": _points_out(strand.points), "sampled": _flat_out(strand._sampled),
		"a": _end_out(strand.a), "b": _end_out(strand.b)}
	for key in STRAND:
		out[key] = _copy(strand.get(key))
	return out


func _strand_in(strand: RopeStrand, rec: Dictionary) -> void:
	strand.points = _points_in(rec.points)
	strand.length = rec.length
	# Sized for its points, then given their own motion and ground.
	strand._fit()
	for key in STRAND:
		strand.set(key, _copy(rec[key]))
	strand._sampled = _flat_in(rec.sampled)
	strand.a = _end_in(rec.a)
	strand.b = _end_in(rec.b)
	strand._look.set_shader_parameter("segment", strand._rest)
	strand._show()


## A rope's end as the body it's on and which of that body's ends it is;
## yours as "hand" or "waist".
func _end_out(end: Node3D) -> Variant:
	if end == null or not is_instance_valid(end):
		return null
	if end == _world.ropes.hand:
		return "hand"
	if end == _world.ropes.waist:
		return "waist"
	var item: Node = (end.get_meta(&"socket") as Socket).part if end.has_meta(&"socket") else end.get_parent()
	if not _known(item):
		return null
	return [_ref(item), _ends_of(item).find(end)]


func _end_in(rec: Variant) -> Node3D:
	if rec == null:
		return null
	if rec is String:
		return _world.ropes.hand if rec == "hand" else _world.ropes.waist
	var item: Node = _made.get(rec[0])
	if item == null:
		return null
	var ends := _ends_of(item)
	return ends[rec[1]] if rec[1] >= 0 and rec[1] < ends.size() else null


## A body's own rope ends in the order it was made with them: fitted, they
## live in the device with the rest of the part.
static func _ends_of(item: Node) -> Array:
	var part := item as Part
	if part != null and part.socket != null:
		return part.socket.fitted.filter(func(n: Node) -> bool: return n is RopeEnd)
	return item.get_children().filter(func(n: Node) -> bool: return n is RopeEnd and not n.has_meta(&"socket"))


func _solver_in(rec: Dictionary) -> void:
	var ropes := _world.ropes
	ropes._tick = rec.tick
	ropes._drag = rec.drag
	for entry: Array in rec.bodies:
		var node: Node3D = _world.player if entry[0] is String else _made.get(entry[0])
		if node == null:
			continue
		var body := RopeBody.new()
		body.node = node
		body.rigid = node as RigidBody3D
		body.player = node as Player
		body.stake = node is Stake
		body.tick = entry[1]
		body.left = entry[2]
		body.left_spin = entry[3]
		ropes._bodies[node.get_instance_id()] = body


## The world's things in the order they stood, which every system walks.
func _order(order: Array, lines: Array[Line], cables: Array[Cable]) -> void:
	var content := _world.content
	var at := _world.player.get_index() + 1
	for entry: Array in order:
		var node: Node = lines[entry[1]] if entry[0] == "l" else (cables[entry[1]] if entry[0] == "c" else _made.get(entry[1]))
		if node != null and node.get_parent() == content:
			content.move_child(node, at)
			at += 1


## The fresh world's own things go: a resumed run has only what was saved.
func _clear() -> void:
	var world := _world
	var player := world.player
	if player.hands.held != null:
		player.hands.stow()
	player.hands.grasp.let_go()
	for body in player.waist.tied.duplicate():
		player.waist.untie(body)
	world.ropes.clear()
	world.remove_meta(&"kit")
	for child in world.content.get_children():
		if child != player:
			world.content.remove_child(child)
			child.free()


func _transform_out(at: Transform3D) -> Array:
	return [at.basis, _world.world_x(at.origin.x), at.origin.y, _world.world_z(at.origin.z)]


func _transform_in(rec: Array) -> Transform3D:
	return Transform3D(rec[0], Vector3(_world.engine_x(rec[1]), rec[2], _world.engine_z(rec[3])))


## Points as world metres, in doubles: a float far from the origin would round.
func _points_out(points: PackedVector3Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for p in points:
		out.append_array([_world.world_x(p.x), p.y, _world.world_z(p.z)])
	return out


func _points_in(flat: PackedFloat64Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(0, flat.size(), 3):
		out.append(Vector3(_world.engine_x(flat[i]), flat[i + 1], _world.engine_z(flat[i + 2])))
	return out


func _flat_out(points: PackedVector2Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for p in points:
		out.append_array([_world.world_x(p.x), _world.world_z(p.y)])
	return out


func _flat_in(flat: PackedFloat64Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(_world.engine_x(flat[i]), _world.engine_z(flat[i + 1])))
	return out


## Its own copy: the snapshot never shares a container with the run.
static func _copy(value: Variant) -> Variant:
	var type := typeof(value)
	if type == TYPE_DICTIONARY or type == TYPE_ARRAY:
		return value.duplicate(true)
	if type >= TYPE_PACKED_BYTE_ARRAY and type <= TYPE_PACKED_VECTOR4_ARRAY:
		return value.duplicate()
	return value
