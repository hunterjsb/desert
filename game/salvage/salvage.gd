class_name Salvage
extends Node
## Finds in the world. A chunk's finds are laid out when its ground becomes
## solid, inside the streaming budget, and go when it stops being solid: what
## the structures standing on it hold within reach (SiteLoot), and the few
## loose finds on its open sand on the way. They lie in the chunk as part of
## it, frozen where they were placed, buried or settled, until you take one,
## take from one, fit to one, use one or take hold of one: then it's yours,
## an ordinary thing in the world. A site remembers what was taken from it
## while it's laid, and the save keeps that; a chunk remembers its loose
## finds taken while it's loaded. And the drift a storm carries is caught on
## your lines (Drift). A wreck's scrapping (Wreckage) is built with its
## chunk's finds: its plates, the sand in its holds, its hazards, and its
## modules held fast until they're cleared; what was done to it is kept in
## its site's memory with what was taken.

## How long a loose find may take to settle before it's frozen anyway, s, and
## how still it must be to count as settled.
const SETTLE_SECONDS := 4.0
const STILL_SPEED := 0.05
const STILL_SECONDS := 0.3
## A clock that jumps (a resume, a scenario, sleep) draws this many ticks of drift at most.
const DRIFT_MOST := 540
## A loaded site a storm works on is read again each time this much more sand
## is off it or back on, or it has risen or sunk this far, m; what it holds
## eases to where it lies now over about this long, s, coming up out of the
## sand or sinking back into it.
const RE_READ_M := 0.02
const RE_READ_MOVE := 0.03
const EASE_S := 0.25

## Main-thread time laying out finds took, the most any frame has, ms.
var slowest_ms := 0.0
## Things your lines have caught this run.
var caught := 0

var _world: World
var _tuning: Tuning
var _lots := {}
var _queue: Array[Piece] = []
## Finds forgotten, freed one at a time inside the budget: a chunk's all at
## once would overrun the frame it leaves in.
var _forgotten: Array = []
## Loose finds settling: [body, seconds since placed, seconds still].
var _settling: Array[Array] = []
## What was taken from each site while it's laid, by its id: [the site, or
## null until a resumed run's is laid again, {socket: true}, what was done to
## it if it's a wreck (Wreckage.state)].
var _sites := {}
## Site finds easing to where they lie now: [body, its transform in its
## chunk's frame to come to, whether it's sinking out of reach].
var _easing: Array[Array] = []
## Each wreck's scrapping built now, by its site.
var _wreckage := {}
## Whether a chunk has gone since the sites' memory was last pruned.
var _prune := false
## The last tick of drift drawn.
var _drift_tick := 0


## One chunk's finds while it's loaded: how hard the weather had been when it
## first came near, what was taken, and what lies there now.
class Lot:
	var exposure := NAN
	var taken := {}
	var finds: Array[RigidBody3D] = []
	var chunk: TerrainChunk
	## Each structure's finds lying here, by socket; the sand off it and its
	## floor when it was last read; how many of its sockets wait to be read
	## again; and what each socket holds, drawn once, by [site, socket].
	var sites := {}
	var seen := {}
	var waiting := {}
	var drawn := {}
	var wrecks: Array[Wreckage] = []


## Work for the streaming budget: planning a chunk (no spec), or what one
## socket of its structures holds within reach (a site and socket), or one
## step of laying out a find: its body, each part it was found with, then
## into the world.
class Piece:
	var coord: Vector2i
	var spec: Dictionary
	var site: Structure
	var socket := -1
	var body: RigidBody3D
	var fitted := 0
	## Read again as a storm works on its site: what's newly within reach
	## comes up out of the sand.
	var again := false
	## A wreck's scrapping still being built, a piece a step.
	var wreck: Wreckage

	func _init(at: Vector2i, find := {}, of: Structure = null, i := -1, anew := false) -> void:
		coord = at
		spec = find
		site = of
		socket = i
		again = anew


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_drift_tick = floori(world.time / _tuning.drift_tick_s)
	world.terrain.grounded.connect(_on_grounded)
	world.terrain.ungrounded.connect(_on_ungrounded)
	world.terrain.unloaded.connect(_on_unloaded)
	if _tuning.salvage:
		_first_time()


## The first find laid out in a run pays for everything done the first time,
## a millisecond; a stand-in pays it now, while the world loads, as the
## sand's shader does. So do the first ruin, every socket's resting spots
## and the first of each painted look.
func _first_time() -> void:
	Ruin.prepare()
	SiteLoot.prepare()
	Dress.prepare()
	Wreckage.prepare()
	var spec := {"id": &"chassis", "device": true, "layer": Finds.DEEP, "x": 0.0, "z": 0.0, "yaw": 0.0,
		"lean": 0.0, "lean_by": 0.0, "bury": 0.3, "sound": 0.5, "charge": 0.5,
		"fill": [[0, &"hook", 0.0], [4, &"hover_tray", 0.0], [5, &"battery", 0.5], [6, &"solar_panel", 0.0]]}
	var stand_in := Finds.make(spec)
	stand_in.transform = Finds.pose(stand_in, spec, func(_x: float, _z: float) -> float: return -1000.0)
	stand_in.freeze = true
	_world.content.add_child(stand_in)
	Finds.age(stand_in, spec.sound)
	stand_in.free()


func _ready() -> void:
	# Settling finds are watched after the physics step they moved in.
	process_physics_priority = 120


## Finds half made wait off the tree, so nothing else would free them.
func _exit_tree() -> void:
	while not _queue.is_empty():
		_drop(0)
	for body: Variant in _forgotten:
		if is_instance_valid(body):
			body.free()
	_forgotten.clear()


## Called by the terrain each frame with its budget's deadline (usec).
func stream(deadline: int) -> void:
	var started := Time.get_ticks_usec()
	while not _forgotten.is_empty() and Time.get_ticks_usec() < deadline:
		# Its chunk may have gone first, and taken it along.
		var body: Variant = _forgotten.pop_back()
		if is_instance_valid(body):
			body.free()
	while not _queue.is_empty() and Time.get_ticks_usec() < deadline:
		var piece: Piece = _queue[0]
		var lot: Lot = _lots.get(piece.coord)
		if lot == null or not is_instance_valid(lot.chunk) or not lot.chunk.has_collision():
			_drop(0)
		elif piece.again:
			_queue.pop_front()
			_read_again(piece, lot)
		elif piece.wreck != null:
			if not is_instance_valid(piece.wreck) or piece.wreck.build_step():
				_queue.pop_front()
		elif piece.site != null and piece.spec.is_empty():
			_queue.pop_front()
			var spec := SiteLoot.within_reach(piece.site, piece.socket, _world.height_at, _taken_from(piece.site))
			if not spec.is_empty():
				_queue.push_front(Piece.new(piece.coord, spec, piece.site, piece.socket))
		elif piece.spec.is_empty():
			_queue.pop_front()
			_plan(piece.coord, lot)
		elif piece.body == null:
			piece.body = Finds.bare(piece.spec)
		elif piece.fitted < piece.spec.fill.size():
			Finds.fit(piece.body as Device, piece.spec, piece.fitted)
			piece.fitted += 1
		else:
			_queue.pop_front()
			Finds.dark(piece.body)
			_lay_out(piece.coord, lot, piece.spec, piece.body, piece.site)
	slowest_ms = maxf(slowest_ms, (Time.get_ticks_usec() - started) / 1000.0)


## A loaded site a storm is working on, read again when enough sand has
## come off it or gone back: called each time its chunk moves what stands on
## it. A wreck's scrapping moves with it every time.
func follow(chunk: TerrainChunk) -> void:
	var lot: Lot = _lots.get(chunk.coord)
	if lot == null or lot.chunk != chunk:
		return
	for wreck in lot.wrecks:
		if is_instance_valid(wreck):
			wreck.follow(chunk)
	for site in chunk.structures():
		var was: Variant = lot.seen.get(site)
		if was == null or lot.waiting.has(site):
			continue
		var now := Vector2(site.taken(), site.floor_y)
		if absf(now.x - (was as Vector2).x) < RE_READ_M and absf(now.y - (was as Vector2).y) < RE_READ_MOVE:
			continue
		lot.seen[site] = now
		lot.waiting[site] = site.piece.sockets.size()
		for i in site.piece.sockets.size():
			_queue.append(Piece.new(chunk.coord, {}, site, i, true))


## What a site's socket holds within reach now against what lies there: a
## find still within reach eases to where it lies now, one gone out of reach
## sinks into the sand, and one come within reach is laid, coming up out of
## it. What was taken stays taken.
func _read_again(piece: Piece, lot: Lot) -> void:
	var site := piece.site
	var i := piece.socket
	lot.waiting[site] = int(lot.waiting.get(site, 1)) - 1
	if lot.waiting[site] <= 0:
		lot.waiting.erase(site)
	var lying: Dictionary = lot.sites.get(site, {})
	var got: Variant = lying.get(i)
	var had: RigidBody3D = got if is_instance_valid(got) and got.has_meta(&"find") else null
	if had == null:
		lying.erase(i)
	if had == null and _laying(site, i):
		return
	var key := [site, i]
	if not lot.drawn.has(key):
		lot.drawn[key] = SiteLoot.draw(site, i)
	var spec := SiteLoot.lying(site, i, lot.drawn[key], _world.height_at, _taken_from(site))
	if spec.is_empty():
		if had != null:
			lying.erase(i)
			lot.finds.erase(had)
			_sink(had)
	elif had != null:
		_ease(had, _placed(lot, had, spec))
		if spec.bury > 0.0:
			had.set_meta(&"buried", true)
		elif had.has_meta(&"buried"):
			had.remove_meta(&"buried")
	else:
		spec.emerging = true
		_queue.append(Piece.new(piece.coord, spec, site, i))


## Whether a find for a site's socket waits to be laid.
func _laying(site: Structure, i: int) -> bool:
	for each in _queue:
		if each.site == site and each.socket == i and not each.spec.is_empty():
			return true
	return false


## Where a find lies for its spec, in its chunk's frame.
func _placed(lot: Lot, body: RigidBody3D, spec: Dictionary) -> Transform3D:
	var pose := _stowed(body, spec) if spec.has("base") else Finds.pose(body, spec, _world.height_at)
	var at := Vector3(_world.engine_x(pose.origin.x), pose.origin.y, _world.engine_z(pose.origin.z))
	return Transform3D(pose.basis, at - lot.chunk.position)


## A find eases to a transform in its chunk's frame.
func _ease(body: RigidBody3D, to: Transform3D, sinking := false) -> void:
	for each in _easing:
		if each[0] == body:
			each[1] = to
			each[2] = sinking
			return
	_easing.append([body, to, sinking])


## A find gone out of reach sinks into the sand and is gone: nothing takes it on the way.
func _sink(body: RigidBody3D) -> void:
	body.remove_meta(&"find")
	body.collision_layer = 0
	_ease(body, body.transform.translated(Vector3.DOWN * (Finds.bounds(body).size.length() + 0.05)), true)


func _process(delta: float) -> void:
	if _easing.is_empty():
		return
	var k := 1.0 - exp(-delta / EASE_S)
	for i in range(_easing.size() - 1, -1, -1):
		var each: Array = _easing[i]
		if not is_instance_valid(each[0]):
			_easing.remove_at(i)
			continue
		var body: RigidBody3D = each[0]
		var to: Transform3D = each[1]
		body.transform = body.transform.interpolate_with(to, k)
		if body.transform.origin.distance_to(to.origin) > 0.002 or not body.transform.basis.is_equal_approx(to.basis):
			continue
		body.transform = to
		_easing.remove_at(i)
		if each[2]:
			body.visible = false
			_forgotten.append(body)


## Nothing left to lay out or settle.
func is_idle() -> bool:
	return _queue.is_empty() and _settling.is_empty()


## The chunks it holds finds or memories for: never more than are loaded.
func lots() -> int:
	return _lots.size()


## How many finds lie in the world now, untaken.
func count() -> int:
	var total := 0
	for lot: Lot in _lots.values():
		total += lot.finds.size()
	return total


## Every find lying in a chunk of its own now, untaken.
func finds() -> Array[RigidBody3D]:
	var all: Array[RigidBody3D] = []
	for lot: Lot in _lots.values():
		all.append_array(lot.finds)
	return all


## The finds lying in the chunks round a place: what your hands look over.
func near(at: Vector3) -> Array[RigidBody3D]:
	var all: Array[RigidBody3D] = []
	var middle := _world.terrain.chunk_at(_world.world_x(at.x), _world.world_z(at.z))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var lot: Lot = _lots.get(middle + Vector2i(dx, dz))
			if lot != null:
				all.append_array(lot.finds)
	return all


## How hard the weather had been in a loaded chunk when it came near; NAN if
## it hasn't yet.
func exposure_in(coord: Vector2i) -> float:
	var lot: Lot = _lots.get(coord)
	return lot.exposure if lot != null else NAN


## Whether a find is yours now: of a loaded chunk's open sand by its coord
## and number (one of a chunk forgotten will lie there again), or of a laid
## site by its id and socket.
func taken(at: Variant, index: int) -> bool:
	if at is Vector2i:
		var lot: Lot = _lots.get(at)
		return lot != null and lot.taken.has(index)
	var memory: Array = _sites.get(at, [])
	return not memory.is_empty() and memory[1].has(index)


## Whether a body still lies as it was found, or is buried: taken hold of,
## it comes up out of the sand first.
func lying(body: Node) -> bool:
	return body != null and (body.has_meta(&"find") or body.has_meta(&"buried"))


## A find becomes yours: out of its chunk into the world, an ordinary thing
## from now on, loose unless the sand still holds it, running if its battery
## can, and its chunk won't lay it out again while it's loaded.
func claim(body: Node) -> void:
	if body == null or not body.has_meta(&"find"):
		return
	var from: Array = body.get_meta(&"find")
	body.remove_meta(&"find")
	var module: Array = body.get_meta(&"module", [])
	if body.has_meta(&"module"):
		body.remove_meta(&"module")
	var lot: Lot = _lots.get(from[0])
	for i in range(_easing.size() - 1, -1, -1):
		if _easing[i][0] == body:
			_easing.remove_at(i)
	if from.size() > 2:
		var memory: Array = _sites.get(from[2], [])
		if memory.is_empty():
			memory = [_laid_site(from[2]), {}, {}]
			_sites[from[2]] = memory
		memory[1][from[1]] = true
		_deeds(memory, module)
	elif lot != null:
		lot.taken[from[1]] = true
	if lot != null:
		lot.finds.erase(body)
	for i in range(_settling.size() - 1, -1, -1):
		if _settling[i][0] == body:
			_settling.remove_at(i)
	body.reparent(_world.content)
	# Only the sand holds a find still: left frozen, one you'd stripped or tied
	# a line to could never be taken hold of, pushed or towed.
	if not body.has_meta(&"buried"):
		body.freeze = false
	Finds.unroll(_world, body)
	if body is Device:
		_world.power.wake(body)
	_discovered(body)


## Site loot taken: from a site a storm working on it has bared; a wreck's
## module freed, its last, and its kind scrapped.
func _deeds(memory: Array, module: Array) -> void:
	var site: Structure = memory[0].get_ref() if memory[0] != null else null
	if site != null and Deeds.waiting(_world, &"bared") and site.bared() > 0.0:
		Deeds.done(_world, &"bared")
	if module.is_empty():
		return
	var wreck: Structure = module[0]
	Deeds.done(_world, &"bonepicker", wreck.kind)
	for i in wreck.piece.sockets.size():
		if wreck.piece.sockets[i].kind in SiteLoot.MODULES and not memory[1].has(i):
			return
	Deeds.done(_world, &"stripped")


## Every kind of thing a find held, reported to the profile: the first of
## each kind is a discovery.
func _discovered(body: Node) -> void:
	var profile := get_node_or_null(^"/root/Profile")
	if profile == null:
		return
	if body.has_meta(&"catalog"):
		profile.discover(str(body.get_meta(&"catalog")))
	for child in body.get_children():
		if child is Socket and child.part != null:
			_discovered(child.part)


## Takes something up out of the sand onto it, loose and yours: a buried
## device stands upright on the sand, a part rests on it.
func unbury(body: RigidBody3D) -> void:
	claim(body)
	if body.has_meta(&"drift"):
		body.remove_meta(&"drift")
		_discovered(body)
	if body.has_meta(&"buried"):
		body.remove_meta(&"buried")
		if body is Device:
			body.global_basis = Basis(Vector3.UP, body.global_rotation.y)
		var box := Finds.bounds(body)
		var rise := -INF
		for i in 8:
			var corner := body.global_transform * box.get_endpoint(i)
			rise = maxf(rise, _world.height_under(corner) - corner.y)
		body.global_position.y += rise + Finds.DROP
	body.freeze = false


func _on_grounded(chunk: TerrainChunk) -> void:
	if not _tuning.salvage:
		return
	var lot: Lot = _lots.get(chunk.coord)
	if lot == null:
		lot = Lot.new()
		_lots[chunk.coord] = lot
	lot.chunk = chunk
	_queue.append(Piece.new(chunk.coord))


## Its ground stops being solid: what lies there goes, to come back as it
## was if the ground does while the chunk is loaded.
func _on_ungrounded(chunk: TerrainChunk) -> void:
	var lot: Lot = _lots.get(chunk.coord)
	if lot == null:
		return
	_forget(chunk.coord, lot)


func _on_unloaded(coord: Vector2i) -> void:
	_prune = true
	var lot: Lot = _lots.get(coord)
	if lot != null:
		_forget(coord, lot)
		_lots.erase(coord)


func _forget(coord: Vector2i, lot: Lot) -> void:
	for body in lot.finds:
		if is_instance_valid(body):
			# Out of sight and touching nothing until it's freed.
			body.freeze = true
			body.visible = false
			body.collision_layer = 0
			_forgotten.append(body)
	lot.finds.clear()
	lot.sites.clear()
	lot.seen.clear()
	lot.waiting.clear()
	lot.drawn.clear()
	for wreck in lot.wrecks:
		if is_instance_valid(wreck):
			_wreckage.erase(wreck.site)
			wreck.queue_free()
	lot.wrecks.clear()
	for i in range(_queue.size() - 1, -1, -1):
		if _queue[i].coord == coord:
			_drop(i)
	for i in range(_settling.size() - 1, -1, -1):
		if not is_instance_valid(_settling[i][0]) or _settling[i][0].freeze:
			_settling.remove_at(i)


## The chunk's plan: what its structures hold within reach as they stand,
## less what was taken from them, a socket a piece of work; and its
## open sand's, from how hard the weather had been there when it first came
## near. Each find not taken becomes a piece of work of its own.
func _plan(coord: Vector2i, lot: Lot) -> void:
	var size := _tuning.chunk_size
	for site in lot.chunk.structures():
		lot.seen[site] = Vector2(site.taken(), site.floor_y)
		if site.piece.wreck != null:
			_build_wreck(lot, site)
		for i in site.piece.sockets.size():
			_queue.append(Piece.new(coord, {}, site, i))
	if is_nan(lot.exposure):
		lot.exposure = Finds.exposure(_world.weather.field, (coord.x + 0.5) * size, (coord.y + 0.5) * size,
			_world.time, _tuning)
	for spec in Finds.plan(_world.run_seed, coord, lot.exposure, _tuning, _world.height_at, on_way, on_site):
		if not lot.taken.has(spec.index):
			_queue.append(Piece.new(coord, spec))


## A wreck's scrapping, built as it was left, at its floor as its chunk draws it.
func _build_wreck(lot: Lot, site: Structure) -> void:
	var memory := _memory_of(site)
	var wreck := Wreckage.new(site, memory[2], _world.height_at)
	var chunk := lot.chunk
	wreck.transform = Transform3D(site.basis(), Vector3(site.x - chunk.coord.x * chunk.side, 0.0,
		site.z - chunk.coord.y * chunk.side))
	wreck.follow(chunk)
	chunk.add_child(wreck)
	lot.wrecks.append(wreck)
	_wreckage[site] = wreck
	# Built a piece at a time inside the streaming budget, ahead of what it holds.
	var step := Piece.new(chunk.coord)
	step.wreck = wreck
	_queue.push_front(step)


## The wrecks' scrapping built now, in every loaded chunk.
func wrecks() -> Array[Wreckage]:
	var all: Array[Wreckage] = []
	for wreck: Variant in _wreckage.values():
		if is_instance_valid(wreck):
			all.append(wreck)
	return all


## A wreck's scrapping built now, or null.
func wreckage_of(site: Structure) -> Wreckage:
	var wreck: Variant = _wreckage.get(site)
	return wreck if is_instance_valid(wreck) else null


## The wreck whose ground a point (the engine's frame) is on, or null.
func wreckage_near(at: Vector3) -> Wreckage:
	var x := _world.world_x(at.x)
	var z := _world.world_z(at.z)
	for wreck in wrecks():
		if wreck.site.reaches(x, z):
			return wreck
	return null


## Why something you'd take is held fast in its wreck, or "": a module, or
## anything in or on one.
func held_fast(body: Node) -> String:
	var module := _module_of(body)
	if module.is_empty():
		return ""
	var wreck := wreckage_of(module[0])
	return "" if wreck == null else wreck.held_fast(module[1])


## Taking hold of a module, or of something in it: a live hazard riding on
## it goes off on whoever does. Returns the hazard, or &"".
func touched(body: Node, by: Player) -> StringName:
	var module := _module_of(body)
	if module.is_empty():
		return &""
	var wreck := wreckage_of(module[0])
	if wreck == null:
		return &""
	var hazard := wreck.hazard(module[1])
	if hazard != &"":
		var at := wreck.hazard_body(module[1]).global_position
		wreck.spend(module[1])
		by.vitals.wounds.take(hazard, at)
	return hazard


## The wreck and module a body is or is in, while it still lies there:
## [site, socket], or [].
func _module_of(body: Node) -> Array:
	var device := body as Device
	if body is Part and (body as Part).socket != null:
		device = (body as Part).socket.get_parent() as Device
	while device != null and device.host() != null:
		device = device.host()
	if device == null or not device.has_meta(&"find") or not device.has_meta(&"module"):
		return []
	return device.get_meta(&"module")


## Whether a world place is a structure's ground, which loose finds keep clear of.
func on_site(x: float, z: float) -> bool:
	return _world.shape.sites.covering(x, z) != null


## Whether a world place is on the way, where loose finds still lie.
func on_way(x: float, z: float) -> bool:
	return Finds.on_way(_world.shape.sites, x, z, _tuning.finds_scatter_m)


## What was taken from a site, while it's the one laid now: a memory kept
## for a site since lifted is another's, and goes.
func _taken_from(site: Structure) -> Dictionary:
	var memory: Array = _sites.get(site.id, [])
	if memory.is_empty():
		return {}
	if memory[0] == null:
		memory[0] = weakref(site)
	elif memory[0].get_ref() != site:
		_sites.erase(site.id)
		return {}
	return memory[1]


## A site's memory, made if it has none yet: [the site, taken, done].
func _memory_of(site: Structure) -> Array:
	_taken_from(site)
	var memory: Array = _sites.get(site.id, [])
	if memory.is_empty():
		memory = [weakref(site), {}, {}]
		_sites[site.id] = memory
	while memory.size() < 3:
		memory.append({})
	return memory


## The site laid now with an id, as a weak reference, or null.
func _laid_site(id: int) -> WeakRef:
	for unit in _world.shape.sites.units():
		for site in unit.sites:
			if site.id == id:
				return weakref(site)
	return null


## A site's memory goes with it: kept only for the one laid now with its id.
func _prune_sites() -> void:
	_prune = false
	if _sites.is_empty():
		return
	var laid := {}
	for unit in _world.shape.sites.units():
		for site in unit.sites:
			laid[site.id] = site
	for id: int in _sites.keys():
		var memory: Array = _sites[id]
		if not laid.has(id) or (memory[0] != null and memory[0].get_ref() != laid[id]):
			_sites.erase(id)
		elif memory[0] == null:
			memory[0] = weakref(laid[id])


## A piece of work no longer wanted, and whatever it had begun to make.
func _drop(at: int) -> void:
	var piece := _queue[at]
	if piece.body != null:
		piece.body.free()
	_queue.remove_at(at)


## Lays out one find of a solid chunk's plan at once, as it lies there.
func lay(coord: Vector2i, spec: Dictionary) -> RigidBody3D:
	return _lay_out(coord, _lots[coord], spec, Finds.make(spec))


## A find laid where it lies, in its chunk; one a storm has just brought
## within reach comes up out of the sand.
func _lay_out(coord: Vector2i, lot: Lot, spec: Dictionary, body: RigidBody3D, site: Structure = null) -> RigidBody3D:
	var placed := _placed(lot, body, spec)
	body.transform = placed
	if spec.get("emerging", false):
		body.transform = placed.translated(Vector3.DOWN * (Finds.bounds(body).size.length() + 0.05))
		_ease(body, placed)
	if site != null:
		var lying: Dictionary = lot.sites.get(site, {})
		lot.sites[site] = lying
		lying[spec.index] = body
	body.set_meta(&"find", [coord, spec.index, spec.site] if spec.has("site") else [coord, spec.index])
	if spec.bury > 0.0:
		body.set_meta(&"buried", true)
	if spec.get("module", false) and site != null:
		body.set_meta(&"module", [site, spec.index])
	body.freeze = spec.bury > 0.0 or spec.get("frozen", false)
	lot.chunk.add_child(body)
	if body is Device:
		Finds.age(body, spec.sound)
	lot.finds.append(body)
	if not body.freeze:
		_settling.append([body, 0.0, 0.0])
	return body


## A wreck's module as it was stowed: its foot on its rack or floor, in the
## frame its spec says, world metres.
static func _stowed(body: RigidBody3D, spec: Dictionary) -> Transform3D:
	var box := Finds.bounds(body)
	var middle := box.get_center()
	return (spec.base as Transform3D) * Transform3D(Basis.IDENTITY,
		Vector3(-middle.x, -box.position.y + SiteLoot.DROP, -middle.z))


## A loose find settles from where it was set down, then holds there.
func _physics_process(delta: float) -> void:
	for i in range(_settling.size() - 1, -1, -1):
		var each: Array = _settling[i]
		if not is_instance_valid(each[0]):
			_settling.remove_at(i)
			continue
		var body: RigidBody3D = each[0]
		each[1] += delta
		var still := body.linear_velocity.length() < STILL_SPEED and body.angular_velocity.length() < STILL_SPEED * 4.0
		each[2] = each[2] + delta if still else 0.0
		if each[2] >= STILL_SECONDS or each[1] >= SETTLE_SECONDS:
			body.freeze = true
			_settling.remove_at(i)
	if _prune:
		_prune_sites()
	_drift()
	var here := _world.terrain.chunk_at(_world.player_world_x(), _world.player_world_z())
	var exposed := exposure_in(here)
	Dev.put("salvage/finds", "%d" % count())
	Dev.put("salvage/exp", "-" if is_nan(exposed) else "%d%% deep %d%%"
		% [roundi(exposed * 100.0), roundi(Finds.deep_share(exposed, _tuning) * 100.0)])
	Dev.put("salvage/drift", "%.1f/h a 10 m line, %d caught" % [10.0 * Drift.per_metre(_world, _world.player_world_x(),
		_world.player_world_z(), _world.time), caught])


## Each tick of drift since the last, what your lines catch, laid where it
## fell in their lee, up to what a line's pile holds.
func _drift() -> void:
	var tick := floori(_world.time / _tuning.drift_tick_s)
	if tick <= _drift_tick:
		_drift_tick = tick
		return
	var from := maxi(_drift_tick + 1, tick - DRIFT_MOST)
	_drift_tick = tick
	if not _tuning.salvage:
		return
	var lines := Drift.lines(_world)
	for each in lines:
		var piled := Drift.pile(_world, each[1], each[2])
		var near := Drift.near_line(_world, each[1], each[2])
		for k in range(from, tick + 1):
			if piled >= _tuning.drift_most:
				break
			var spec := Drift.caught(_world, each[1], each[2], k, near)
			if not spec.is_empty():
				Drift.lay(_world, spec)
				piled += 1
				caught += 1


## What a save keeps of the finds, for each chunk remembered: [coord, how
## hard the weather had been when it came near, the finds taken from it].
func memories() -> Array:
	var out := []
	for coord: Vector2i in _lots:
		var lot: Lot = _lots[coord]
		if not is_nan(lot.exposure):
			out.append([coord, lot.exposure, lot.taken.keys()])
	return out


## What a save keeps of the sites: for each laid one something was taken
## from or done to, [its id, the sockets taken, and a wreck's scrapping
## (Wreckage.state) once it's been worked].
func site_memories() -> Array:
	_prune_sites()
	var out := []
	for id: int in _sites:
		var memory: Array = _sites[id]
		var done: Dictionary = memory[2] if memory.size() > 2 else {}
		if done.get("touched", false):
			out.append([id, memory[1].keys(), done])
		elif not memory[1].is_empty():
			out.append([id, memory[1].keys()])
	return out


## A resumed run's sites as they were: each remembers what was taken from it
## once the sheet lays it again. A save from before has none.
func recall_sites(memories: Array) -> void:
	_sites.clear()
	for each: Array in memories:
		var taken := {}
		for socket: int in each[1]:
			taken[socket] = true
		_sites[each[0]] = [null, taken, (each[2] as Dictionary).duplicate(true) if each.size() > 2 else {}]


## A resumed run's finds as they were: a remembered chunk within view of
## `around` lays its finds out again by its own weather, less what was taken;
## any other loaded now comes near afresh, at this moment.
func recall(memories: Array, around: Vector2i) -> void:
	var reach := _tuning.view_radius
	var kept := {}
	for each: Array in memories:
		var coord: Vector2i = each[0]
		if maxi(absi(coord.x - around.x), absi(coord.y - around.y)) <= reach:
			kept[coord] = each
	for coord: Vector2i in _lots.keys() + kept.keys():
		var lot: Lot = _lots.get(coord)
		if lot == null:
			lot = Lot.new()
			_lots[coord] = lot
		_forget(coord, lot)
		lot.exposure = kept[coord][1] if kept.has(coord) else NAN
		lot.taken = {}
		var taken: Array = kept[coord][2] if kept.has(coord) else []
		for index: int in taken:
			lot.taken[index] = true
		if is_instance_valid(lot.chunk) and lot.chunk.has_collision():
			_queue.append(Piece.new(coord))
