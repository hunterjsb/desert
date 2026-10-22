class_name Snapshot
extends RefCounted
## A run as its save holds it: only what's yours and what you changed. The
## ground, the weather and the finds come again from the seed, so the save
## keeps you, the clock, everything of yours in the world with its parts and
## state, every line between them, of the finds near you only which were
## taken and how hard the weather had been there, what was taken from each
## site laid, and the sand held off any site over you or your camp. Places are world metres;
## the engine origin is kept too, so a resumed run computes in the same
## floats as the one saved and plays on tick for tick.
##
## It reaches into the systems' own state (a strand's points, a solver's
## warm start) because that state is the run: anything left out shows up as
## a resumed run drifting from one never saved, which the round-trip probe
## measures.

## What each kind of thing keeps besides where it is, by property.
static var _kept := [
	[Flare, ["lit", "called"]],
	[Stake, ["driven", "pulled", "sustained", "holding", "pull"]],
	[ShieldGenerator, ["on", "smart", "size", "_up", "_since", "held_minutes"]],
	# A save from before the dial kept "channel": setting it places the dial.
	[Radio, ["on", "frequency", "band", "fm_mhz", "am_khz", "sw_khz", "volume", "target"]],
	[SurveyReceiver, ["acquired_from", "scan_pending"]],
	[AntennaKite, ["flying", "line_out", "charge"]],
	[Planter, ["tank_l", "split", "stored", "seeds", "ripened", "replanted", "banked", "dropped", "picked",
		"fed_kcal", "_owed"]],
	[Condenser, ["made_l"]],
	[Console, ["page", "log_lines", "_alerts", "_front_near", "evidence", "bearings"]],
	[Battery, ["charge_wh"]],
	[Plant, ["growth", "fruit", "state", "wild"]],
	[Mast, ["raised", "raise", "head_speed", "boom", "boom_spin", "boom_pose", "boom_velocity", "boom_angular", "load_n", "bend_n", "extend", "upwind_m", "outflow_m"]],
	[Helm, ["sailed_m"]],
	[Chassis, ["_today", "_day_from"]],
	[PowerBox, ["held"]],
	[Bedroll, ["laid"]],
	[Device, ["resting", "lift_share", "lamps", "priority", "switched_off", "weathered"]],
]
const PLAYER := ["stamina", "flying", "mode", "crouched", "own", "slope", "wind", "low", "sink", "_sliding",
	"_jumped", "_since_ground", "_touchdown", "_jump_buffer", "_jump_was", "_jump_queued", "_crouch_was",
	"_on_sand", "_left"]
## A ride's own state, besides its running means of the sand.
const RIDE := ["velocity", "ahead", "y", "vy", "gap", "last_step", "bank", "pitch", "roll", "drifting", "kicks",
	"bottomed", "hardest", "ticks", "waited", "_ground", "_came", "_hopping", "_tilting", "_tilt_was", "_ahead_was",
	"_kick_wait", "_stroke", "dig", "_bitten", "overload", "motor_pulse", "_motor_load", "_line_load", "_motor_age"]
const VITALS := ["health", "hunger", "thirst", "dead", "harms", "taken", "drunk", "eaten", "_next", "in_heart"]
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
		var id: StringName = Catalog.current(rec.get("id", &""))
		if rec.has("id") and not (Catalog.PARTS.has(id) or Catalog.DEVICES.has(id) or id == &"stake"):
			unknown.append(str(rec.id))
		for entry: Array in rec.get("sockets", []) + rec.get("added", []):
			again.call(entry[1], again)
		for entry: Array in rec.get("stuck", []):
			again.call(entry[2], again)
		if rec.has("mounted"):
			again.call(rec.mounted, again)
		for entry: Array in rec.get("joined", []):
			again.call(entry[1], again)
	for rec: Dictionary in data.get("things", []) + _carried(data):
		look.call(rec, look)
	return "" if unknown.is_empty() else "it holds things this build doesn't know: " + ", ".join(unknown)


## What the main menu says of a save: seconds played (NAN if it never kept
## them), the run's day, and who you came as, by id (none from before origins).
static func summary(data: Dictionary) -> Dictionary:
	return {"played": data.get("played", NAN), "kit": data.get("kit", &""),
		"day": DayCycle.new(Tuning.current()).day(data.time, data.moon.longitude, data.get("began", 0.0))}


## What stood round you in a save, made from its own data with no world
## built: the device of yours nearest where you stood and those within
## `reach` of it, nearest it first and `most` at most, each with everything
## seated in it. Each as [body, its pose about you as you stood, facing -z].
## Out of the tree; dress() them once they're in it.
func camp(data: Dictionary, reach: float, most: int) -> Array[Array]:
	var you: Array = data.player.at
	var off := func(rec: Dictionary, from: Array) -> float:
		return Vector2(rec.at[1] - from[1], rec.at[3] - from[3]).length()
	var devices: Array = data.things.filter(func(rec: Dictionary) -> bool:
		return Catalog.DEVICES.has(Catalog.current(rec.id)))
	if devices.is_empty():
		return []
	devices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return off.call(a, you) < off.call(b, you))
	var nearest: Array = devices[0].at
	devices = devices.filter(func(rec: Dictionary) -> bool: return off.call(rec, nearest) <= reach)
	devices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return off.call(a, nearest) < off.call(b, nearest))
	var about := Transform3D(you[0], Vector3.ZERO).affine_inverse()
	var out: Array[Array] = []
	for rec: Dictionary in devices.slice(0, most):
		var at := Vector3(rec.at[1] - you[1], rec.at[2] - you[2], rec.at[3] - you[3])
		out.append([_make(rec), about * Transform3D(rec.at[0], at)])
	return out


## What camp() made has its state back, now it's in the tree.
func dress() -> void:
	for pair in _states:
		_set_state(pair[0], pair[1])
	_restore_pod_skins()


## First half of a resume, on a fresh world built on the save's seed: the
## world's own things go, and the clock, the origin, you and the finds'
## memory are put back. Returns where the rest will stand, world metres, so
## the caller can wait for the ground there.
func begin(data: Dictionary) -> Array[Vector2]:
	_world.set_meta(&"arrival_restoring", true)
	if is_instance_valid(_world.arrival):
		_world.arrival.prepare_restore()
		_world.arrival.restoring = true
	_world.arrival_state = (data.get("arrival", {}) as Dictionary).duplicate(true)
	_world.arrival_state.erase("node_refs")
	_world.arrival_enabled = not _world.arrival_state.is_empty()
	_world.arrival_nodes.clear()
	_clear()
	var world := _world
	# A resumed run has its own things: no new run's kit is set down in it.
	world.set_meta(&"resumed", true)
	world.time = data.time
	world.began = data.get("began", 0.0)
	world.taught = data.get("taught", false)
	world.stoker_state = data.get("stoker", {}).duplicate(true)
	world.stoker.recall()
	world.played = data.get("played", NAN)
	world.counts_deeds = world.counts_deeds and not data.get("dev_run", false)
	world.set_gravity(data.gravity)
	world.shift_origin(data.origin - world.origin_chunk)
	var moon: Dictionary = data.moon
	for key: String in moon:
		world.moon.set(key, moon[key])
	world._last_x = data.last[0]
	world._last_z = data.last[1]
	world.power._next = data.ticks.power
	world.wear._next = data.ticks.wear
	world.wear.sheltered = data.ticks.get("sheltered", 0.0)
	world.farm._next = data.ticks.farm
	world.power.generated_wh = data.ledger[0]
	world.power.used_wh = data.ledger[1]
	world.power.spilled_wh = data.ledger[2]
	var you: Dictionary = data.player
	var player := world.player
	world.teleport(player, _transform_in(you.at))
	player.camera.rotation.x = you.pitch
	player.velocity = you.v
	for key: String in you.state:
		player.set(key, you.state[key])
	player.restore_ground_pose(StringName(you.get("ground_pose", &"stand")))
	player.set_meta(&"rope_drag", you.drag)
	for key: String in you.vitals:
		player.vitals.set(key, _copy(you.vitals[key]))
	for key: String in you.get("wounds", {}):
		player.vitals.wounds.set(key, you.wounds[key])
	world.weather.forecast_now()
	world.salvage.recall(data.finds, world.terrain.chunk_at(world.player_world_x(), world.player_world_z()))
	# What was taken from each site; a save from before kept none.
	world.salvage.recall_sites(data.get("sites", []))
	# History laid where it was; a save from before has none, and lays afresh.
	world.shape.landforms.recall(data.get("landforms", []))
	world.shape._held.clear()
	world.shape.sites.recall(data.get("sheet", []))
	# Sand held off a site over you or your camp stays off it: a pit you
	# stood in comes back dug out.
	world.shape.sites.recall_held(data.get("held", []))
	# Sand dug off sites by hand stays off; a dune's ruin built comes back.
	world.shape.sites.recall_dug(data.get("dug", []), data.get("dunes", []))
	world.farm.feral.recall(data.get("feral", []), world.terrain.chunk_at(world.player_world_x(), world.player_world_z()))
	world.terrain.reset_home()
	var home: Dictionary = data.get("home", {})
	world.home.prepare_restore(home)
	if not home.is_empty():
		world.terrain.restore_home(home.get("support_cells", Rect2i()))
	var places: Array[Vector2] = [Vector2(world.player_world_x(), world.player_world_z())]
	for rec: Dictionary in data.things:
		if home.get("members", []).has(rec.ref) and not world.terrain.home_restores_at(rec.at[1], rec.at[3]):
			continue
		places.append(Vector2(rec.at[1], rec.at[3]))
	return places


## Second half, once the ground under all of it is solid: everything of
## yours, its lines, what you carry, your hands and waist.
func finish(data: Dictionary) -> void:
	var world := _world
	var ropes := world.ropes
	var lines: Array[Line] = []
	for rec: Dictionary in data.lines:
		lines.append(_line(rec))
	var cables: Array[Cable] = []
	for rec: Dictionary in data.cables:
		# An older save has no hoses.
		var cable := Catalog.hose(world, Vector3.ZERO) if rec.get("hose", false) \
			else Catalog.cable(world, Vector3.ZERO, rec.strong)
		cable.length = rec.length
		for i in 2:
			_made[rec.plugs[i]] = cable.plugs[i]
		cables.append(cable)
	for rec: Dictionary in data.things:
		var body := _make(rec)
		if body.get_parent() == null:
			world.content.add_child(body)
		body.global_transform = _transform_in(rec.at)
		PhysicsServer3D.body_set_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, body.global_transform)
		body.linear_velocity = rec.v
		body.angular_velocity = rec.w
		body.freeze = rec.freeze
		body.sleeping = rec.sleeping
		if rec.world_froze:
			body.set_meta(&"frozen_by_world", true)
		# Still held by the sand: only taking hold of it pulls it up.
		if rec.get("buried", false):
			body.set_meta(&"buried", true)
	var suit := world.player.suit
	for thing in suit.carried:
		thing.free()
	suit.carried.clear()
	for rec: Dictionary in _carried(data):
		suit.carried.append(_make(rec))
	for pair in _states:
		_set_state(pair[0], pair[1])
	# What a save from before needs brought up to date.
	for pair in _states:
		if pair[0].has_method(&"restored"):
			pair[0].restored()
	suit.carry_devices()
	# Back on the board you rode, going as you were.
	var rode: Dictionary = data.get("ride", {})
	if not rode.is_empty() and _made.has(rode.board) and world.player.get_on(_made[rode.board]):
		_ride_in(world.player.ride, rode)
	var seat: int = data.get("helm", -1)
	if _made.get(seat) is Helm:
		world.player.sit(_made[seat])
	for pair: Array in data.get("reels", []):
		var reel := _made.get(int(pair[0])) as AntennaReel
		var radio := _made.get(int(pair[1])) as Radio
		if reel != null and radio != null:
			reel.radio = radio
	DialMarks.restore(world, data.get("dial_marks", []))
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
		# Run through a stake: a kite's lead earthed on its way (AntennaKite).
		if rec.get("through") != null and _made.get(rec.through) is Stake:
			cables[i].through = _made[rec.through]
			cables[i]._rope_through()
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
	if data.waist.has("taking"):
		waist._taking = _made.get(data.waist.taking) if data.waist.taking != null else null
	elif waist._to_hand and not waist.tied.is_empty():
		waist._taking = waist.tied.back()
	var held: Variant = data.hands.get("held")
	if held != null and _made.has(held):
		var body: RigidBody3D = _made[held]
		hands._grip(body)
		hands._carry = data.hands.carry
		hands.phase = Hands.Phase.HELD
		hands._ticked = body.global_transform
	hands.reel.choose(_made.get(data.hands.get("chosen")))
	var grasped: Variant = data.grasp.get("body")
	if grasped != null and _made.has(grasped):
		hands.grasp.recall(_made[grasped], data.grasp)
	for drop: Dictionary in data.get("airdrops", []):
		var cargo := _made.get(drop.cargo) as Part
		if is_instance_valid(cargo):
			Airdrop.recall(world, cargo, _transform_in(drop.at), drop.state)
	world.home.finish_restore(data.get("home", {}), func(ref: int) -> Node: return _made.get(ref))
	for body in world.home.members:
		if not body.freeze and not world.terrain.has_collision_at(world.world_x(body.global_position.x), world.world_z(body.global_position.z)):
			body.freeze = true
			body.set_meta(&"frozen_by_world", true)
	_restore_pod_skins()
	var arrival: Dictionary = data.get("arrival", {})
	for uid: StringName in arrival.get("node_refs", {}):
		var body := _made.get(arrival.node_refs[uid]) as Node
		if is_instance_valid(body):
			world.arrival_nodes[uid] = body
	world.remove_meta(&"arrival_restoring")
	if not arrival.is_empty() and is_instance_valid(world.arrival):
		world.arrival.restore.call_deferred()
	world.shape.sites.resumed()


func _take() -> Dictionary:
	var world := _world
	var ropes := world.ropes
	var player := world.player
	var hands := player.hands
	var data := {"seed": world.run_seed, "time": world.time, "began": world.began, "taught": world.taught, "stoker": world.stoker_state.duplicate(true),
		"gravity": world.gravity,
		"origin": world.origin_chunk,
		"moon": {"latitude": world.moon.latitude, "longitude": world.moon.longitude,
			"_spawn_latitude": world.moon._spawn_latitude, "_spawn_longitude": world.moon._spawn_longitude,
			"_facing": world.moon._facing},
		"last": [world._last_x, world._last_z],
		"ticks": {"power": world.power._next, "wear": world.wear._next, "farm": world.farm._next,
			"sheltered": world.wear.sheltered},
		"ledger": [world.power.generated_wh, world.power.used_wh, world.power.spilled_wh]}
	if not is_nan(world.played):
		data.played = world.played
	# A run the dev console changed stays a dev run when it's resumed.
	if not world.counts_deeds:
		data.dev_run = true
	var you := {"at": _transform_out(player.global_transform), "pitch": player.camera.rotation.x,
		"v": player.velocity, "drag": player.get_meta(&"rope_drag", Vector3.ZERO), "state": {}, "vitals": {}}
	# A climb is an interrupted action, not a ballistic launch on resume.
	if player.vault.active:
		you.v = player.vault.release_velocity()
	for key in PLAYER:
		you.state[key] = player.get(key)
	for key in VITALS:
		you.vitals[key] = _copy(player.vitals.get(key))
	# A sickness from a wreck runs on through a save; a stun is over by then.
	you.wounds = {"sick": player.vitals.wounds.sick, "shocks": player.vitals.wounds.shocks,
		"sicknesses": player.vitals.wounds.sicknesses}
	you.ground_pose = player.ground_pose
	data.player = you
	var things := []
	var lines: Array[Line] = []
	var cables: Array[Cable] = []
	var order := []
	var drops := []
	for child in world.content.get_children():
		if child is Line:
			order.append(["l", lines.size()])
			lines.append(child)
		elif child is Cable:
			order.append(["c", cables.size()])
			cables.append(child)
		elif child is Airdrop and is_instance_valid(child.cargo) and child.cargo.get_parent() == child:
			order.append(["b", _ref(child.cargo)])
			things.append(_body(child.cargo, true))
			drops.append({"cargo": _ref(child.cargo), "at": _transform_out(child.global_transform), "state": child.memory()})
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
	# Ridden, the board is out of the physics world under your feet. It's kept
	# as stepping off would leave it, a body going your way, so one that can't
	# carry you on resume comes down on the sand.
	var ride := player.ride
	if ride != null and _refs.has(player.board):
		for rec: Dictionary in things:
			if rec.ref == _refs[player.board]:
				rec.at = _transform_out(ride.board_pose(false))
				rec.v = Vector3(ride.velocity.x, ride.vy, ride.velocity.y)
				rec.w = Vector3.ZERO
				rec.freeze = false
				rec.sleeping = false
		data.ride = _ride_out(ride)
	# At the helm, you sit there again on resume.
	if player.helm != null and _refs.has(player.helm):
		data.helm = _refs[player.helm]
	# A strung antenna reel stays clipped to its set: [reel, radio] by ref.
	var reels := []
	for reel: AntennaReel in world.get_tree().get_nodes_in_group(AntennaReel.GROUP):
		if is_instance_valid(reel.radio) and _refs.has(reel) and _refs.has(reel.radio):
			reels.append([_refs[reel], _refs[reel.radio]])
	if not reels.is_empty():
		data.reels = reels
	data.dial_marks = DialMarks.all(world)
	data.home = world.home.snapshot(_ref)
	if not data.home.is_empty():
		data.home.support_cells = world.terrain.home_support()
	data.things = things
	data.airdrops = drops
	data.order = order
	data.carried = player.suit.carried.filter(_known).map(func(p: RigidBody3D) -> Dictionary: return _body(p, false))
	var strands := ropes.strands.filter(func(s: RopeStrand) -> bool: return is_instance_valid(s) and not s.has_meta(&"unclaimed_rig"))
	data.lines = lines.map(func(line: Line) -> Dictionary: return {"state": line.state, "full": line.full,
		"routed_by_player": line.routed_by_player, "route_loaded_seconds": line.route_loaded_seconds,
		"first": line._first, "coil": _ref(line.coil) if is_instance_valid(line.coil) else null,
		"ends": line.ends.map(_ref),
		"rope": _rope_out(line.rope, strands) if line.rope != null and ropes.ropes.has(line.rope) else null})
	data.cables = cables.map(func(cable: Cable) -> Dictionary: return {"strong": cable is StrongCable,
		"hose": cable is Hose, "length": cable.length, "plugs": cable.plugs.map(_ref),
		"through": _ref(cable.through) if is_instance_valid(cable.through) else null,
		"rope": _rope_out(cable.rope, strands) if cable is StrongCable and cable.rope != null else null})
	data.strands = strands.map(_strand_out)
	data.solver = {"tick": ropes._tick, "drag": ropes._drag, "bodies": []}
	for body: RopeBody in ropes._bodies.values():
		if not is_instance_valid(body.node):
			continue
		var ref: Variant = null
		if body.node == player:
			ref = "player"
		elif _refs.has(body.node):
			ref = _refs[body.node]
		elif body.node.has_meta(&"boom_mast"):
			var mast: Mast = body.node.get_meta(&"boom_mast")
			if _refs.has(mast):
				ref = {"boom": _refs[mast]}
		if ref != null:
			data.solver.bodies.append([ref, body.tick, body.left, body.left_spin])
	var gathering := player.waist.gathering()
	data.waist = {"tied": player.waist.tied.filter(_known).map(_ref), "untying": -1.0 if gathering else player.waist.untying,
		"to_hand": player.waist._to_hand and not gathering,
		"taking": _ref(player.waist._taking) if not gathering and _known(player.waist._taking) else null}
	data.hands = {}
	if hands.held != null and _known(hands.held):
		data.hands = {"held": _ref(hands.held), "carry": hands._carry}
		for rec: Dictionary in things:
			if rec.ref == data.hands.held:
				# Where the tick has it, not where this frame drew it.
				rec.at = _transform_out(hands._ticked if hands.phase == Hands.Phase.HELD else hands.held.global_transform)
	var grasp := hands.grasp
	var chosen := hands.reel.chosen_body()
	if _known(chosen):
		data.hands.chosen = _ref(chosen)
	data.grasp = {}
	if is_instance_valid(grasp.body) and _known(grasp.body):
		data.grasp = grasp.memory()
		data.grasp.body = _ref(grasp.body)
	data.finds = world.salvage.memories()
	data.sites = world.salvage.site_memories()
	data.sheet = world.shape.sites.memories()
	data.landforms = world.shape.landforms.memories()
	data.held = world.shape.sites.held()
	data.dug = world.shape.sites.dug_memories()
	data.dunes = world.shape.sites.dunes.memories()
	data.feral = world.farm.feral.memories()
	if world.arrival_enabled and not world.arrival_state.is_empty():
		data.arrival = world.arrival_state.duplicate(true)
		var node_refs := {}
		for body: Node in _refs:
			if is_instance_valid(body) and body.has_meta(&"arrival_uid"):
				node_refs[body.get_meta(&"arrival_uid")] = _refs[body]
		data.arrival.node_refs = node_refs
	return data


## The ride as it stands, its running means too, so its hover goes on
## exactly as it would have.
func _ride_out(ride: Ride) -> Dictionary:
	var out := {"board": _refs[ride.board]}
	for key: String in RIDE:
		out[key] = ride.get(key)
	for key: String in ["_under", "_around"]:
		var mean: Ride.PathMean = ride.get(key)
		out[key] = [PackedFloat64Array(mean._at), PackedFloat64Array(mean._sand), mean._area]
	return out


func _ride_in(ride: Ride, rec: Dictionary) -> void:
	# An older save lacks the newer of these: they start as a new ride does.
	for key: String in RIDE:
		if rec.has(key):
			ride.set(key, rec[key])
	for key: String in ["_under", "_around"]:
		var mean: Ride.PathMean = ride.get(key)
		mean._at.assign(Array(rec[key][0]))
		mean._sand.assign(Array(rec[key][1]))
		mean._area = rec[key][2]


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
		out.buried = body.has_meta(&"buried")
	for key: StringName in [&"arrival_uid", &"pod_skin"]:
		if body.has_meta(key):
			out[key] = _copy(body.get_meta(key))
	if body.has_meta(&"layer"):
		out.found = body.get_meta(&"layer")
	if body.has_meta(&"lineage"):
		out.lineage = body.get_meta(&"lineage")
	# Found or stowed, it unrolls into a line or a cable once taken out, a
	# stowed line as long as it was.
	if body is RopeTip and not RopeBundle.slots(body).is_empty():
		out.bundle_slots = RopeBundle.slots(body).size()
	if body.has_meta(&"rolled"):
		out.rolled = body.get_meta(&"rolled")
	if body.has_meta(&"rolled_m"):
		out.rolled_m = body.get_meta(&"rolled_m")
	# What sits in the sockets a part added: a line's end on a hook, fitted
	# or loose.
	if body is Part:
		var added := _added(body as Part)
		var inner := []
		for k in added.size():
			var inside := _socket_out(added[k])
			if not inside.is_empty():
				inner.append([k, inside])
		if not inner.is_empty():
			out.added = inner
	if body is Device:
		var filled := []
		var frame := (body as Device).frame_sockets()
		for i in frame.size():
			var inside := _socket_out(frame[i])
			if not inside.is_empty():
				filled.append([i, inside])
		out.sockets = filled
	# What's stuck on a mast, by its pose on the mast and the face's way out,
	# as a piece's is.
	if body is Device and not body is Chassis and not (body as Device).stuck().is_empty():
		out.stuck = _stuck_out_of(body as Device)
	# A deck's pieces in the order they joined, each with what's stuck on it:
	# [how it joined, itself]. Across a ring: ["ring", the piece it joined,
	# that piece's ring, its quarter turns]; on a frame's face: ["face", the
	# piece the frame stands on, the frame among what's stuck there, the face].
	var deck := body as Chassis
	if deck != null:
		var on := deck if deck.deck == null else deck.deck
		out.stuck = _stuck_out(on, deck)
		if deck.deck == null and not deck.joined.is_empty():
			var pieces := deck.pieces()
			out.joined = []
			for piece in deck.joined:
				var how: Array
				if piece.on_frame():
					var host := deck.own_piece(piece.joined_at)
					var frame_in: Socket = piece.joined_at.get_meta(&"socket")
					how = ["face", pieces.find(host), _stuck_of(deck, host).find(frame_in),
						piece.joined_at.get_meta(&"face")]
				else:
					var ring_on := deck.own_piece(piece.joined_at)
					how = ["ring", pieces.find(ring_on), ring_on.frame_sockets().find(piece.joined_at), piece.turns]
				out.joined.append([how, _body(piece, false)])
	return out


## What's stuck on a deck's piece, in the order it went on.
static func _stuck_of(deck: Chassis, piece: Chassis) -> Array[Socket]:
	return deck.stuck().filter(func(s: Socket) -> bool: return deck.own_piece(s) == piece)


## What's stuck on a piece, each as [its pose on the piece, the face's way
## out, what it is]: a part, or a device with what's in its own sockets.
func _stuck_out(deck: Chassis, piece: Chassis) -> Array:
	var back := piece.pose().affine_inverse() if piece.deck != null else Transform3D.IDENTITY
	var out := []
	for socket in _stuck_of(deck, piece):
		var inside := _body(socket.part, false) if _known(socket.part) \
			else (_body(socket.mounted, false) if _known(socket.mounted) else {})
		if not inside.is_empty():
			out.append([back * socket.transform, back.basis * socket.out, inside])
	return out


## What's stuck on a device that isn't a deck, each as a piece's is.
func _stuck_out_of(device: Device) -> Array:
	var out := []
	for socket in device.stuck():
		var inside := _body(socket.part, false) if _known(socket.part) \
			else (_body(socket.mounted, false) if _known(socket.mounted) else {})
		if not inside.is_empty():
			out.append([socket.transform, socket.out, inside])
	return out


## What sits in a socket: a part, and whatever sits in the sockets it added
## (a line's end on a hook's ring); or a small device seated there.
func _socket_out(socket: Socket) -> Dictionary:
	if _known(socket.part):
		return _body(socket.part, false)
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
	if body is SurveyReceiver:
		out.beacon_khz = Dial.BEACON_KHZ
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
	if body is SurveyReceiver and not state.has("beacon_khz") and state.has("frequency"):
		# The old narrow-band receiver followed the beacon at 1930 kHz.
		if absf(state.frequency - 1930.0) <= _world.tuning.receiver_band_khz:
			state = state.duplicate()
			state.frequency += Dial.BEACON_KHZ - 1930.0
	var part := body as Part
	if part != null and state.has("stats"):
		part.stats = state.stats.duplicate(true)
	for key: String in state:
		if key in ["durability", "powered", "stats", "amount", "beacon_khz"]:
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


## Decorative shell skins follow their ordinary pieces after joins and mounting resolve.
func _restore_pod_skins() -> void:
	for pair in _states:
		var body := pair[0] as Chassis
		if is_instance_valid(body) and body.has_meta(&"pod_skin"):
			PodShell.restore_skin(body)


## A body for a record: one its owner made already (a line's end, a cable's
## plug), or a fresh one from the catalog, with what's in its sockets fitted
## before it's in the world, so nothing fitting it lifts it off the sand.
func _make(rec: Dictionary) -> RigidBody3D:
	var body: RigidBody3D = _made.get(rec.ref)
	if body == null:
		var id := Catalog.current(rec.id)
		body = Catalog.stake() if id == &"stake" else (Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id))
		_made[rec.ref] = body
	if body is RopeTip:
		RopeBundle.prepare(body, rec.get("bundle_slots", 0))
	_states.append([body, rec])
	for key: StringName in [&"arrival_uid", &"pod_skin"]:
		if rec.has(key):
			body.set_meta(key, _copy(rec[key]))
	if rec.has("found"):
		Finds.mark(body, rec.found)
	# Before its parts are fitted and it's in the world, as a find is given it.
	if rec.has("lineage"):
		Catalog.inherit(body, Eras.current(rec.lineage))
	if rec.has("rolled"):
		body.set_meta(&"rolled", rec.rolled)
	if rec.has("rolled_m"):
		body.set_meta(&"rolled_m", rec.rolled_m)
	var device := body as Device
	if device != null:
		device.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		var frame := device.frame_sockets()
		for entry: Array in rec.get("sockets", []):
			_socket_in(device, frame[entry[0]], entry[1])
		# A piece's own stuck things go on while it's still alone, in its own frame.
		for entry: Array in rec.get("stuck", []):
			device.stick(_make(entry[2]), entry[0], entry[1])
		var deck := device as Chassis
		for entry: Array in rec.get("joined", []):
			var how: Array = entry[0]
			var pieces := deck.pieces()
			var piece := _make(entry[1]) as Chassis
			if how[0] == "face":
				var frame_in := _stuck_of(deck, pieces[how[1]])[how[2]]
				deck.join(piece, (frame_in.part as Frame).faces()[how[3]])
			else:
				deck.join(piece, pieces[how[1]].frame_sockets()[how[2]], how[3])
	# Its line's end goes on a hook before the hook goes anywhere, and moves
	# with it into a device.
	var part := body as Part
	if part != null:
		var added := _added(part)
		for entry: Array in rec.get("added", []):
			Device.seat_part(_make(entry[1]) as Part, added[entry[0]])
		if part is RopeTip:
			RopeBundle.refresh_mass(part)
	return body


## The sockets a part added: its own while loose, in its device's body once fitted.
static func _added(part: Part) -> Array:
	var nodes: Array = part.socket.fitted if part.socket != null else part.get_children()
	return nodes.filter(func(n: Node) -> bool: return n is Socket and n.has_meta(&"socket") == (part.socket != null))


func _socket_in(device: Device, socket: Socket, rec: Dictionary) -> void:
	if rec.has("mounted"):
		var seated := _make(rec.mounted) as Device
		device.mount(seated, socket)
		seated.transform = rec.pose
		return
	device.fit(_make(rec) as Part, socket)


## A line as it was, its ends or coil made where they'll be put; its rope is
## tied now and given its state once everything is in place.
func _line(rec: Dictionary) -> Line:
	var line := Line.new()
	line._world = _world
	_world.content.add_child(line)
	line.state = rec.state
	line.full = rec.full
	line._first = rec.first
	line.routed_by_player = rec.get("routed_by_player", false)
	line.route_loaded_seconds = rec.get("route_loaded_seconds", 0.0)
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
	if is_instance_valid(rope.through):
		out.through = _end_out(rope.through)
	for key in ROPE:
		out[key] = rope.get(key)
	return out


## Returns its strand, to be given its points next.
func _rope_in(rope: Rope, rec: Dictionary) -> RopeStrand:
	for key in ROPE:
		rope.set(key, rec[key])
	rope.through = _end_in(rec.get("through"))
	rope.strand.through = rope.through
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
		var node: Node3D
		if entry[0] is Dictionary:
			var mast := _made.get(entry[0].get("boom")) as Mast
			node = mast.boom_body() if is_instance_valid(mast) else null
		else:
			node = _world.player if entry[0] is String else _made.get(entry[0])
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


## What you carry, as saved: a list, or from before there were none, five
## slots, their empty ones left out.
static func _carried(data: Dictionary) -> Array:
	if data.has("carried"):
		return data.carried
	return data.get("slots", []).filter(func(r: Variant) -> bool: return r != null)


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
	player.waist.cancel_gather()
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
