class_name Feral
extends Node
## The feral layer (docs/world-system.md): wild plants on the habitats history
## left. No plant spawns at random. Each grows from its habitat, a road, a
## water line, a site, a planting, so finding plants is finding history. A
## chunk's wild plants are made from the seed and the laid history alone,
## drawn instanced while the chunk is drawn, and stand where they grew. On
## ground you can stand on they're real crops: take on one and it gives as a
## crop does, at the wild share, with its cutting, tuber or spores, and they
## grow there on the farm's tick. Within feral_fold_m they fold before a storm
## as planted saltbush does. Only what you took or cut is remembered, while
## its chunk is loaded, as finds are.

## Where each crop grows wild, a row a habitat. "along" a path: of these
## kinds, or any but "except", used in this era, carrying this; a slot every
## "every" m along its line, "side" m off it on both sides or one a stretch;
## a stretch of "stretch" m lives by its region's "alive" share, and each slot
## in it by "keep". "at" a site of these kinds, "built" only where a kit stands
## it on the ground and it's partly exposed or more. A slot is a "clump" of
## plants within "spread" m, each standing "size" of its look. A crop the
## catalog doesn't know yet places nothing. A row's place in the table seeds
## its plants, so rows are appended, never inserted. Defaults.
const HABITATS := [
	# The Sisters' silver lines: both sides of a pilgrim road, close.
	{"crop": &"saltbush", "along": {"kinds": [&"pilgrim_road"], "era": Eras.SECOND, "carries": PathNetwork.ROAD},
		"every": 3.2, "side": Vector2(2.2, 3.2), "both": true, "stretch": 60.0, "keep": 0.92,
		"alive": {&"han": 0.5, &"mon": 0.85, &"rim": 0.95, &"far": 0.4}, "size": Vector2(0.95, 1.4)},
	# Every other road the second age walked: one side at a time, broken.
	{"crop": &"saltbush", "along": {"except": [&"pilgrim_road"], "era": Eras.SECOND, "carries": PathNetwork.ROAD},
		"every": 4.0, "side": Vector2(1.8, 3.4), "stretch": 90.0, "keep": 0.8,
		"alive": {&"han": 0.08, &"mon": 0.3, &"rim": 0.55, &"far": 0.05}, "size": Vector2(0.8, 1.25)},
	# The Dark Age's first plantings, on the First Kingdoms' water lines.
	{"crop": &"saltbush", "at": {"kinds": [&"saltbush_planting"]}, "clump": Vector2i(4, 9), "spread": 4.0,
		"size": Vector2(0.8, 1.4)},
	# Root-tuber gone bitter by the colonial aqueducts: patches near the line.
	{"crop": &"root_tuber", "along": {"era": Eras.COLONIAL, "carries": PathNetwork.WATER},
		"every": 160.0, "side": Vector2(8.0, 35.0), "stretch": 160.0, "keep": 1.0,
		"alive": {&"han": 0.3, &"mon": 0.6, &"rim": 0.7, &"far": 0.1}, "clump": Vector2i(3, 6), "spread": 3.0,
		"size": Vector2(1.5, 2.1)},
	# And by the pumps on them.
	{"crop": &"root_tuber", "at": {"kinds": [&"pump_station"]}, "clump": Vector2i(3, 7), "spread": 14.0,
		"size": Vector2(1.5, 2.1)},
	# Vat fungus in the colony's buried corridors and habs, once a kit stands
	# them and a storm opens them.
	{"crop": &"vat_fungus", "at": {"kinds": [&"hab_pod", &"pump_station", &"vent_station"], "built": true},
		"clump": Vector2i(3, 8), "spread": 5.0, "size": Vector2(1.4, 2.0)},
	# Not grown yet: each waits on its crop.
	{"crop": &"dewleaf", "at": {"kinds": [&"cistern"]}, "clump": Vector2i(2, 5), "spread": 14.0,
		"size": Vector2(1.0, 1.4)},
	{"crop": &"coalcane", "at": {"kinds": [&"cistern"]}, "clump": Vector2i(5, 12), "spread": 10.0,
		"size": Vector2(1.0, 1.6)},
	{"crop": &"sandroot", "at": {"kinds": [&"pipe_wall_hut", &"low_wall", &"generator_shrine"]},
		"clump": Vector2i(1, 1), "spread": 6.0, "size": Vector2(2.0, 3.0)},
	{"crop": &"glowcap", "at": {"kinds": [&"hab_pod", &"vent_station"], "built": true}, "clump": Vector2i(2, 5),
		"spread": 5.0, "size": Vector2(1.2, 1.6)},
	{"crop": &"office_fern", "at": {"kinds": [&"hab_pod"], "built": true}, "clump": Vector2i(1, 3), "spread": 4.0,
		"size": Vector2(1.0, 1.3)},
]
## How each crop stands wild: Feral's own "bush", or its crop's own look; and
## the box you aim at to take from it, m across and up, at full size.
const LOOKS := {
	&"coalcane": {"box": Vector3(0.5, 0.5, 1.2)},
	&"saltbush": {"bush": true, "box": Vector3(1.1, 1.1, 0.6)},
	&"root_tuber": {"box": Vector3(0.24, 0.24, 0.22)},
	&"vat_fungus": {"box": Vector3(0.16, 0.16, 0.12)},
}
const DEFAULT_BOX := Vector3(0.3, 0.3, 0.3)
## How big a young plant stands against a grown one.
const STAGE_SIZE := {Plant.SEEDLING: 0.3, Plant.YOUNG: 0.65}
## A wild plant's foot sits this far into the sand, m.
const SINK := 0.04
## Rays find wild plants on this layer, and nothing moving touches them.
const LAYER := 2
## What a plant taken or dug up leaves in memory.
const TAKEN := Vector2(-1.0, 0.0)
## A part's frame standing on the sand: its +Z up.
static var UPRIGHT := Basis.looking_at(Vector3.DOWN, Vector3.BACK)

var _world: World
var _tuning: Tuning
var _size: float
## Each drawn chunk's wild plants, by its coord.
var _patches := {}
## What was taken or cut in each loaded chunk: {plant id: Vector2(growth, fruit)}, or TAKEN.
var _memory := {}
## Chunks waiting to be laid out: [coord, what], what being &"draw" or &"stand".
var _work: Array[Array] = []
var _dirty: Array[Patch] = []
## Main-thread time laying out took, the most any frame has, ms.
var slowest_ms := 0.0


## One drawn chunk's wild plants: as planned, as drawn, and, where you can
## stand, as real crops.
class Patch:
	var coord: Vector2i
	var chunk: TerrainChunk
	var middle: Vector2
	## {id, crop, row, x, z, yaw, size, y}: y once it's been laid out.
	var plants: Array[Dictionary] = []
	var planned := false
	var looks: Array[MultiMeshInstance3D] = []
	var dirty := false
	## Each folding crop's leaves here, 0 open to 1 shut; NAN until first read.
	var folds := {}
	## Its plants as real crops, a few to a stand, whether all stand, and the
	## next to stand.
	var stands: Array[Stand] = []
	var stood := false
	var next := 0
	## Each standing plant's socket, by its place in plants.
	var held := {}
	## The sockets whose plants aren't ripe: all that grow.
	var growing: Array[Socket] = []


## A few of a grounded chunk's wild plants as one frozen body: a socket a
## plant, each holding its crop, which your hands take from as from a
## planter. Nothing moving touches it.
class Stand extends Device:
	var feral: Feral
	var patch: Patch

	func _ready() -> void:
		super()
		set_physics_process(false)

	func take(socket: Socket) -> Part:
		return feral._take(self, socket)


## Feral's own looks in B's paint, low, since a line is hundreds of them.
class Look extends Paint.Pieces:
	## A clump of leaves: a low ellipsoid.
	func clump(radius: float, at: Vector3, look: Paint.Coat, scale: Vector3, turn: Basis) -> void:
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = 6
		m.rings = 3
		_add(m.get_mesh_arrays(), Transform3D(turn * Basis.from_scale(scale), at), look, Vector3.ONE, 1.0)


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_size = _tuning.chunk_size
	if not _tuning.feral:
		return
	world.terrain.child_entered_tree.connect(_on_chunk)
	world.terrain.grounded.connect(_on_grounded)
	world.terrain.ungrounded.connect(_on_ungrounded)
	world.terrain.unloaded.connect(_on_unloaded)
	# Every look of the bush now, while the world loads, as the crops' are:
	# made the first time one's drawn, it would stall that frame.
	_make_looks()


func _ready() -> void:
	# After the terrain has attached this frame's ground.
	process_priority = 10


# --- Where they grow: pure in the seed and the laid history. ---

## A chunk's wild plants, from the history laid round it alone: {id, crop,
## row, x, z, yaw, size}, world metres.
static func plan(history: History, sites: Sites, coord: Vector2i, size: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rect := Rect2(Vector2(coord) * size, Vector2.ONE * size)
	var reach := _reach()
	var pieces := sites.paths_in(rect.grow(reach))
	var near := _sites_near(sites, rect.grow(reach))
	for r in HABITATS.size():
		var row: Dictionary = HABITATS[r]
		if not Catalog.PARTS.has(row.crop):
			continue
		if row.has("along"):
			for piece in pieces:
				if _runs_along(row.along, piece):
					_along(history, sites, piece, r, rect, out)
		else:
			for site in near:
				if _stands_at(row.at, site):
					_at(history.run_seed, site, r, rect, out)
	return out


## History's sites whose ground touches a rect. Not the grid's ruins: no
## habitat is one, and asking for them would survey dunes not yet built.
static func _sites_near(sites: Sites, rect: Rect2) -> Array[Site]:
	var found: Array[Site] = []
	for unit in sites.units():
		if unit.ground.intersects(rect, true):
			for site in unit.sites:
				if site.touches(rect):
					found.append(site)
	return found


## The farthest any habitat puts a plant from its line or site, m.
static func _reach() -> float:
	var most := 0.0
	for row: Dictionary in HABITATS:
		most = maxf(most, row.get("side", Vector2.ZERO).y + row.get("spread", 0.0))
	return most + 2.0


static func _runs_along(along: Dictionary, piece: Sites.Piece) -> bool:
	if along.has("kinds") and not piece.kind in along.kinds or piece.kind in along.get("except", []):
		return false
	return piece.eras & Eras.BITS[along.era] != 0 and piece.carries & along.carries != 0


static func _stands_at(at: Dictionary, site: Site) -> bool:
	if not site.kind in at.kinds:
		return false
	# Only on a kit's site, once storms have the sand partly off it (Exposure: 0 is buried).
	return not at.get("built", false) or not site.planned and (not site.has_method(&"state") or site.call(&"state") > 0)


## Slots along a path's line through the rect: each its own draw, by its
## running length along the path, so every chunk asking gets the same.
static func _along(history: History, sites: Sites, piece: Sites.Piece, r: int, rect: Rect2,
		out: Array[Dictionary], rng := _rng, fate_rng := _fate) -> void:
	var row: Dictionary = HABITATS[r]
	var path: PathNetwork.Path = history.network.paths[piece.path]
	var alive: float = row.alive.get(history.region_of(path.points[piece.first]), 0.0)
	if alive <= 0.0:
		return
	var every: float = row.every
	var side: Vector2 = row.side
	var both: bool = row.get("both", false)
	var near := rect.grow(side.y + row.get("spread", 0.0) + 1.0)
	# Each stretch's fate, once: whether it lives, and which side it's on.
	var fates := {}
	for k in piece.points.size() - 1:
		var a := piece.points[k]
		var b := piece.points[k + 1]
		var span := _clip(a, b, near)
		if span.x > span.y:
			continue
		var la := path.lengths[piece.first + k]
		var lb := path.lengths[piece.first + k + 1]
		var length := lb - la
		var run := (b - a) / length if length > 0.0 else Vector2.RIGHT
		var across := Vector2(-run.y, run.x)
		for n in range(floori((la + span.x * length) / every) - 1, ceili((la + span.y * length) / every) + 1):
			var slot := _seed(history.run_seed, path.id, r, n)
			rng.seed = slot
			var s := (n + 0.5 + rng.randf_range(-0.35, 0.35)) * every
			if s < la or s >= lb:
				continue
			var stretch := floori(s / row.stretch)
			if not fates.has(stretch):
				fate_rng.seed = _seed(history.run_seed, path.id, r + STRETCHES, stretch)
				fates[stretch] = Vector2(1.0 if fate_rng.randf() < alive else 0.0, 1.0 if fate_rng.randf() < 0.5 else -1.0)
			var fate: Vector2 = fates[stretch]
			if fate.x == 0.0 or rng.randf() >= row.keep:
				continue
			var on := a + run * (s - la)
			for j in (2 if both else 1):
				var off := across * (fate.y if j == 0 else -fate.y) * rng.randf_range(side.x, side.y) \
					+ run * rng.randf_range(-0.4, 0.4)
				_clump(r, on + off, slot * 32 + j * 16, rect, out, sites, rng)


## A site's own clump, within its spread of its middle.
static func _at(run_seed: int, site: Site, r: int, rect: Rect2, out: Array[Dictionary]) -> void:
	var slot := _seed(run_seed, site.id & 0x7fffffff, site.id >> 31, r + SITES)
	_rng.seed = slot
	_clump(r, Vector2(site.x, site.z), slot * 32, rect, out, null)


## A slot's plants round a place, drawn on from its stream; those standing
## in the rect are its. Every draw is made whatever's kept, so a slot is the
## same from any chunk.
static func _clump(r: int, at: Vector2, first_id: int, rect: Rect2, out: Array[Dictionary], clear_of: Sites,
		rng := _rng) -> void:
	var row: Dictionary = HABITATS[r]
	var clump: Vector2i = row.get("clump", Vector2i.ONE)
	var count := rng.randi_range(clump.x, clump.y)
	var spread: float = row.get("spread", 0.0) if count > 1 or row.has("at") else 0.0
	for c in count:
		var spot := at
		if spread > 0.0:
			spot += Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * spread
		var yaw := rng.randf() * TAU
		var size := rng.randf_range(row.size.x, row.size.y)
		# Nothing on the road grows in a ruin's walls.
		if not rect.has_point(spot) or clear_of != null and clear_of.covering(spot.x, spot.y) != null:
			continue
		out.append({"id": first_id + c, "crop": row.crop, "row": r, "x": spot.x, "z": spot.y, "yaw": yaw,
			"size": size})


## A line's plants this close or closer read as one line far off, m apart.
const LINE_EVERY := 5.0


## Whether a path carries a line of wild plants far off (Skyline): a habitat
## along it that grows a close line of a crop the catalog has.
static func lines_along(path: PathNetwork.Path) -> bool:
	var piece := Sites.Piece.new()
	piece.kind = path.kind
	piece.eras = path.eras
	piece.carries = path.carries
	for row: Dictionary in HABITATS:
		if row.has("along") and row.every <= LINE_EVERY and Catalog.PARTS.has(row.crop) and _runs_along(row.along, piece):
			return true
	return false


## A laid stretch of path's close lines of wild plants within a rect, for
## drawing them far off (Skyline): each as its chunk would place it, from
## the same draws, bar the clearing of a ruin's walls. Its own streams: a
## worker asks.
static func far_plants(history: History, piece: Sites.Piece, rect: Rect2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	var fate := RandomNumberGenerator.new()
	for r in HABITATS.size():
		var row: Dictionary = HABITATS[r]
		if row.has("along") and row.every <= LINE_EVERY and Catalog.PARTS.has(row.crop) and _runs_along(row.along, piece):
			_along(history, null, piece, r, rect, out, rng, fate)
	return out


## A grown wild bush's height and width at its look's own size, m.
const BUSH_TALL := 0.5
const BUSH_WIDE := 1.04


## Two streams the placing draws from, reseeded for each slot and stretch:
## a stretch's fate and a site's slot draw apart from a path's slots.
static var _rng := RandomNumberGenerator.new()
static var _fate := RandomNumberGenerator.new()
const STRETCHES := 1000
const SITES := 2000


static func _seed(run_seed: int, a: int, b: int, c: int) -> int:
	return hash(Vector4i(run_seed, a, b, c))


## The share of a segment a to b within a rect, as [from, to], from > to if none.
static func _clip(a: Vector2, b: Vector2, rect: Rect2) -> Vector2:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for axis in 2:
		var lo := rect.position[axis]
		var hi := rect.end[axis]
		if absf(d[axis]) < 1e-9:
			if a[axis] < lo or a[axis] > hi:
				return Vector2(1.0, 0.0)
			continue
		var u := (lo - a[axis]) / d[axis]
		var v := (hi - a[axis]) / d[axis]
		t0 = maxf(t0, minf(u, v))
		t1 = minf(t1, maxf(u, v))
	return Vector2(t0, t1)


# --- Laid out with the ground. ---

func _on_chunk(node: Node) -> void:
	var chunk := node as TerrainChunk
	if chunk == null:
		return
	var patch := Patch.new()
	patch.coord = chunk.coord
	patch.chunk = chunk
	patch.middle = (Vector2(chunk.coord) + Vector2.ONE * 0.5) * _size
	_patches[chunk.coord] = patch
	_work.append([chunk.coord, &"draw"])


## Its ground is the 1 m samples you stand on now: feet go on them.
func _on_grounded(chunk: TerrainChunk) -> void:
	var patch: Patch = _patches.get(chunk.coord)
	if patch != null:
		for each in patch.plants:
			each.erase("y")
		_redraw(patch)
	_work.append([chunk.coord, &"stand"])


func _on_ungrounded(chunk: TerrainChunk) -> void:
	var patch: Patch = _patches.get(chunk.coord)
	if patch != null:
		_unstand(patch)


## Gone with its chunk, which takes its looks along: so does what was taken from it.
func _on_unloaded(coord: Vector2i) -> void:
	var patch: Patch = _patches.get(coord)
	if patch != null:
		_unstand(patch)
		_dirty.erase(patch)
	_patches.erase(coord)
	_memory.erase(coord)


func _unstand(patch: Patch) -> void:
	for stand in patch.stands:
		stand.free()
	patch.stands.clear()
	patch.stood = false
	patch.next = 0
	patch.held.clear()
	patch.growing.clear()


func _process(_delta: float) -> void:
	if _world == null or not _tuning.feral:
		return
	var started := Time.get_ticks_usec()
	var deadline := started + int(_tuning.feral_budget_ms * 1000.0)
	while not _dirty.is_empty() and Time.get_ticks_usec() < deadline:
		_draw(_dirty.pop_back())
	while not _work.is_empty() and Time.get_ticks_usec() < deadline:
		var job: Array = _work[0]
		var patch: Patch = _patches.get(job[0])
		if patch == null or not is_instance_valid(patch.chunk):
			_work.pop_front()
			continue
		if not patch.planned:
			patch.plants = plan(_world.shape.history, _world.shape.sites, patch.coord, _size)
			patch.planned = true
			for each in patch.plants:
				if Catalog.PARTS[each.crop].crop.stages.has("folds"):
					patch.folds[each.crop] = NAN
			continue
		if job[1] == &"draw":
			_work.pop_front()
			_draw(patch)
		elif not patch.chunk.has_collision() or patch.stood or _stand_some(patch):
			_work.pop_front()
	slowest_ms = maxf(slowest_ms, (Time.get_ticks_usec() - started) / 1000.0)


## Nothing waiting to be laid out.
func is_idle() -> bool:
	return _work.is_empty() and _dirty.is_empty()


## A loaded chunk's wild plants, as planned; empty until it's been laid out.
func plants_in(coord: Vector2i) -> Array[Dictionary]:
	var patch: Patch = _patches.get(coord)
	var none: Array[Dictionary] = []
	return patch.plants if patch != null else none


## Every wild plant standing as a crop now, on ground you can stand on.
func standing() -> Array[Plant]:
	var all: Array[Plant] = []
	for patch: Patch in _patches.values():
		for socket: Socket in patch.held.values():
			if socket.part is Plant:
				all.append(socket.part)
	return all


## Where a standing wild plant's foot is, engine metres.
func foot_of(plant: Plant) -> Vector3:
	var socket := plant.socket
	var patch: Patch = (socket.get_parent() as Stand).patch
	var each: Dictionary = patch.plants[socket.get_meta(&"wild")]
	return patch.chunk.global_transform * Vector3(each.x - patch.coord.x * _size, each.y, each.z - patch.coord.y * _size)


func _redraw(patch: Patch) -> void:
	if not patch.dirty:
		patch.dirty = true
		_dirty.append(patch)


## How a planned plant stands now: [growth, fruit], or TAKEN.
func _state(patch: Patch, i: int) -> Vector2:
	if patch.held.has(i):
		var plant := (patch.held[i] as Socket).part as Plant
		return TAKEN if plant == null else Vector2(plant.growth, plant.fruit)
	return _memory.get(patch.coord, {}).get(patch.plants[i].id, Vector2(1.0, 0.0))


## Where a plant's foot goes: on the chunk's own samples, as its ground is drawn.
func _foot(patch: Patch, each: Dictionary) -> float:
	if not each.has("y"):
		var chunk := patch.chunk
		var step := chunk.step
		if step <= 0 or chunk.heights.is_empty():
			each.y = _world.shape.height_at(each.x, each.z) - SINK
			return each.y
		var w := chunk.side / step + 1
		var x: float = (each.x - chunk.coord.x * chunk.side) / step
		var z: float = (each.z - chunk.coord.y * chunk.side) / step
		var i := clampi(floori(x), 0, w - 2)
		var j := clampi(floori(z), 0, w - 2)
		var fx := x - i
		var fz := z - j
		var k := j * w + i
		var h := chunk.heights
		each.y = TerrainShape.across(fx, fz, h[k + 1], h[k + w], h[k] if fx + fz <= 1.0 else h[k + w + 1]) - SINK
	return each.y


## Draws a patch's plants, instanced a look at a time.
func _draw(patch: Patch) -> void:
	patch.dirty = false
	for view in patch.looks:
		view.free()
	patch.looks.clear()
	var groups := {}
	var origin := Vector2(patch.coord) * _size
	for i in patch.plants.size():
		var now := _state(patch, i)
		if now == TAKEN:
			continue
		var each: Dictionary = patch.plants[i]
		var crop: StringName = each.crop
		var data: Dictionary = Catalog.PARTS[crop].crop
		var ripe: bool = now.x >= 1.0 and (not data.stages.has("bursts") or now.y >= 1.0)
		var stage := Plant.RIPE if ripe else Plant.stage_of(now.x)
		var fold: float = patch.folds.get(crop, 0.0)
		fold = 0.0 if is_nan(fold) else roundi(fold * Plant.FOLD_STEPS) / float(Plant.FOLD_STEPS)
		var key := "%s/%s/%.2f" % [crop, stage, fold]
		if not groups.has(key):
			groups[key] = [look(crop, stage, fold), [], look(crop, stage, fold, true) if _bush(crop) else null]
		var turn := Basis(Vector3.UP, each.yaw) * (Basis.IDENTITY if _bush(crop) else UPRIGHT)
		var grown: float = each.size * Plant.fill_of(now.x)
		groups[key][1].append(Transform3D(turn * Basis.from_scale(Vector3.ONE * grown),
			Vector3(each.x - origin.x, _foot(patch, each), each.z - origin.y)))
	for key: String in groups:
		var group: Array = groups[key]
		var near := _view(patch, group[0], group[1])
		if group[2] != null:
			# Past this a chunk's bushes are its plain look, too far to tell apart.
			near.visibility_range_end = FAR_LOOK_M
			near.visibility_range_end_margin = FAR_LOOK_MARGIN
			var far := _view(patch, group[2], group[1])
			far.visibility_range_begin = FAR_LOOK_M
			far.visibility_range_begin_margin = FAR_LOOK_MARGIN


## One look's plants as an instanced view on the patch's chunk.
func _view(patch: Patch, mesh: Mesh, places: Array) -> MultiMeshInstance3D:
	var shown := MultiMesh.new()
	shown.transform_format = MultiMesh.TRANSFORM_3D
	shown.mesh = mesh
	shown.instance_count = places.size()
	for k in places.size():
		shown.set_instance_transform(k, places[k])
	var view := MultiMeshInstance3D.new()
	view.multimesh = shown
	view.set_instance_shader_parameter(&"age", Paint.age_of(&"", 1.0))
	patch.chunk.add_child(view)
	patch.looks.append(view)
	return view


## A chunk's bushes this far from you, m, give way to their plain look.
const FAR_LOOK_M := 80.0
const FAR_LOOK_MARGIN := 10.0


static func _bush(crop: StringName) -> bool:
	return LOOKS.get(crop, {}).get("bush", false)


static var _looks := {}


## A wild crop's look at a stage, its leaves folded this share shut.
static func look(crop: StringName, stage: StringName, fold: float, far := false) -> ArrayMesh:
	if not _bush(crop):
		return Dress.crop(crop, stage, fold)
	var key := "%s/%.2f/%s" % [Plant.MATURE if stage == Plant.RIPE else stage, fold, far]
	if not _looks.has(key):
		_looks[key] = _wild_bush(stage, fold, far)
	return _looks[key]


## Every stage of the bush at every step of its fold, once a run.
static func _make_looks() -> void:
	for stage: StringName in [Plant.SEEDLING, Plant.YOUNG, Plant.MATURE]:
		for step in Plant.FOLD_STEPS + 1:
			for far in [false, true]:
				look(&"saltbush", stage, step / float(Plant.FOLD_STEPS), far)


## Old wild saltbush: woody stems low under a mound of small silvered leaf,
## held level to the sun; folded, the leaves close up against the stems,
## showing their green undersides, and the mound goes narrow and dull.
## Upright, y up, about a metre across at full size. Its plain look, for
## far off, is the same mound in a few big clumps.
static func _wild_bush(stage: StringName, fold: float, far := false) -> ArrayMesh:
	var b := Look.new(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("wild saltbush")
	var full := stage == Plant.RIPE or stage == Plant.MATURE
	var young := stage == Plant.SEEDLING
	var count := (8 if young else (20 if not full else 40)) / (3 if far else 1)
	var wide := (0.14 if young else (0.32 if not full else 0.52)) * lerpf(1.0, 0.72, fold)
	var tall := (0.12 if young else (0.3 if not full else 0.46)) * lerpf(1.0, 1.08, fold)
	var leaf := (0.06 if young else (0.08 if not full else 0.1)) * (2.4 if far else 1.0)
	var stems := (3 if young else (5 if not full else 7)) / (3 if far else 1)
	var tones: Array[Paint.Coat] = []
	for k in LEAF.size():
		tones.append(Paint.coat(LEAF[k].lerp(LEAF_SHUT[k], fold), 0.0, lerpf(0.12, 0.02, fold), 0.62, 0.15))
	for i in stems:
		var a := TAU * i / stems + rng.randf_range(-0.3, 0.3)
		var top := Vector3(sin(a) * wide * 0.65, tall * rng.randf_range(0.55, 0.8), cos(a) * wide * 0.65)
		var y := top.normalized()
		var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
		b.drum(0.012 if young else 0.02, top.length(), top * 0.5, Dress.WOOD, Basis(x, y, x.cross(y)), 5)
	for i in count:
		var up := acos(1.0 - (i + 0.5) / count * 0.95)
		var a := i * 2.39996 + rng.randf_range(-0.3, 0.3)
		var shell := rng.randf_range(0.78, 1.05)
		var deep := shell * (0.8 if far else 1.0)
		var at := Vector3(sin(up) * sin(a) * wide * deep, 0.04 + cos(up) * tall * deep, sin(up) * cos(a) * wide * deep)
		# The sun-side shell silvers most; inside it's the leaf's own sage.
		var tone := tones[0] if shell > 0.95 and up < 1.1 else (tones[2] if i % 5 == 0 else tones[1])
		var open := Vector3(1.0, rng.randf_range(0.5, 0.75), rng.randf_range(0.75, 1.0))
		var shut := Vector3(0.55, 1.15, 0.5)
		b.clump(leaf * rng.randf_range(0.8, 1.3), at, tone, open.lerp(shut, fold),
			Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)))
	return b.commit()


## The bush's leaf, sun-side, its own and deep inside: open, and folded.
const LEAF: Array[Color] = [Color(0.8, 0.84, 0.82), Color(0.65, 0.71, 0.67), Color(0.46, 0.52, 0.47)]
const LEAF_SHUT: Array[Color] = [Color(0.56, 0.62, 0.52), Color(0.45, 0.53, 0.43), Color(0.35, 0.42, 0.34)]


## Stands a few more of a patch's plants; says when all of them stand.
func _stand_some(patch: Patch) -> bool:
	var stand := Stand.new()
	stand.feral = self
	stand.patch = patch
	stand.label = "wild plants"
	stand.freeze = true
	stand.collision_layer = 1 << (LAYER - 1)
	stand.collision_mask = 0
	var origin := Vector2(patch.coord) * _size
	var made := 0
	while patch.next < patch.plants.size() and made < STAND_STEP:
		var i := patch.next
		patch.next += 1
		var now := _state(patch, i)
		if now == TAKEN:
			continue
		made += 1
		var each: Dictionary = patch.plants[i]
		var socket := Socket.new()
		socket.kind = &"wild"
		socket.set_meta(&"wild", i)
		socket.transform = Transform3D(Basis(Vector3.UP, each.yaw) * UPRIGHT,
			Vector3(each.x - origin.x, _foot(patch, each), each.z - origin.y))
		stand.add_child(socket)
		# Only what you aim at: its look is the patch's.
		var spec: Dictionary = Catalog.PARTS[each.crop]
		var plant := Plant.new()
		plant.kind = spec.kind
		plant.mass = spec.mass
		plant.stats = spec.stats.duplicate()
		plant.set_meta(&"catalog", each.crop)
		plant.sow(each.crop)
		plant.wild = true
		plant.set_growth(now.x)
		plant.fruit = now.y
		plant.state = Plant.RIPE if plant.ripe() else Plant.GROWING
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.set_meta(&"socket", socket)
		stand.add_child(shape)
		socket.fitted.append(shape)
		socket.part = plant
		plant.socket = socket
		_fit_size(socket, each)
		patch.held[i] = socket
		if not plant.ripe():
			patch.growing.append(socket)
	if made > 0:
		patch.chunk.add_child(stand)
		patch.stands.append(stand)
		for crop: StringName in patch.folds:
			_fold_stand(patch, crop)
	else:
		stand.free()
	patch.stood = patch.next >= patch.plants.size()
	return patch.stood


## Plants a stand takes a step of the streaming budget.
const STAND_STEP := 6


## What you aim at grows with the plant, and you take from its top, so what
## comes away rises clear of it.
func _fit_size(socket: Socket, each: Dictionary) -> void:
	var plant := socket.part as Plant
	var box: Vector3 = LOOKS.get(plant.crop, {}).get("box", DEFAULT_BOX) * each.size * Plant.fill_of(plant.growth) \
		* STAGE_SIZE.get(plant.stage(), 1.0)
	(socket.fitted[0] as CollisionShape3D).shape.size = box
	socket.transform.origin = Vector3(socket.transform.origin.x, each.y + box.z, socket.transform.origin.z)
	socket.fitted[0].transform = socket.transform * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -box.z * 0.5))


## Take on a wild plant: ripe, its harvest at the wild share and its
## propagule, and it's picked, growing again where it stands if it regrows;
## not ripe, one grown from cuttings gives a cutting and is cut back to the
## ground, and anything else, or one cut to the ground, comes up whole. The
## first of it to your hands, the rest in with what you carry.
func _take(stand: Stand, socket: Socket) -> Part:
	var plant := socket.part as Plant
	var patch := stand.patch
	var i: int = socket.get_meta(&"wild")
	var out: Array[Part] = []
	var gone := false
	if plant.ripe():
		for gives: Array in plant.yields():
			out.append_array(Catalog.output(gives[0], gives[1]))
		out.append(_propagule(plant, 0.0))
		plant.pick()
		gone = not plant.data.stages.has("regrows")
	elif plant.data.propagule == &"cutting" and plant.growth >= Plant.SEEDLING_UNTIL:
		out.append(_propagule(plant, 0.0))
		plant.set_growth(0.0)
	else:
		out.append(_propagule(plant, plant.growth))
		gone = true
	plant.state = Plant.GROWING
	var memory: Dictionary = _memory.get(patch.coord, {})
	_memory[patch.coord] = memory
	memory[patch.plants[i].id] = TAKEN if gone else Vector2(plant.growth, plant.fruit)
	var pose := stand.global_transform * socket.transform
	var player := _world.player
	for k in range(1, out.size()):
		player.suit.carried.append(out[k])
		Planter.fall(_world, out[k], pose.origin, player)
	patch.growing.erase(socket)
	if gone:
		socket.fitted[0].free()
		socket.fitted.clear()
		socket.part = null
		plant.socket = null
		plant.free()
		# Nothing goes back where a wild plant was.
		socket.closed = true
		stand._recompute()
	else:
		_fit_size(socket, patch.plants[i])
		patch.growing.append(socket)
	_redraw(patch)
	var first := out[0]
	_world.content.add_child(first)
	first.global_transform = pose
	return first


func _propagule(plant: Plant, grown: float) -> Plant:
	var made := Catalog.part(plant.crop) as Plant
	made.wild = true
	made.set_growth(grown)
	return made


# --- Growing and folding, on the farm's tick. ---

## Leaves read the storm once a second of world time.
const FOLD_EVERY := 1.0


## One farm tick of `seconds` at world time t. Wild crops you can stand
## among grow by what they feel there. Once a second, folding crops within
## feral_fold_m read the storm field over their chunk now and their fold's
## lead ahead, as a planter's do, and close or open toward it.
func tick(seconds: float, t: float) -> void:
	if _world == null or not _tuning.feral:
		return
	if floori(t / FOLD_EVERY) != floori((t - seconds) / FOLD_EVERY):
		_fold(t)
	var weather := _world.weather
	for patch: Patch in _patches.values():
		if patch.growing.is_empty():
			continue
		var memory: Dictionary = _memory.get(patch.coord, {})
		for socket in patch.growing.duplicate():
			var plant := socket.part as Plant
			var each: Dictionary = patch.plants[socket.get_meta(&"wild")]
			var stage := plant.stage()
			var fill := Plant.fill_of(plant.growth)
			var at: Vector3 = (socket.get_parent() as Node3D).global_transform * socket.transform.origin
			plant.grow(seconds, Planter.felt_at(weather, at, t), INF)
			if memory.has(each.id):
				memory[each.id] = Vector2(plant.growth, plant.fruit)
			if plant.ripe():
				plant.state = Plant.RIPE
				patch.growing.erase(socket)
			if plant.ripe() or plant.stage() != stage or absf(Plant.fill_of(plant.growth) - fill) > 0.05:
				_fit_size(socket, each)
				_redraw(patch)


func _fold(t: float) -> void:
	var you := Vector2(_world.player_world_x(), _world.player_world_z())
	var reach := _tuning.feral_fold_m + _size * 0.71
	var field := _world.weather.field
	for patch: Patch in _patches.values():
		if patch.folds.is_empty() or patch.middle.distance_to(you) > reach:
			continue
		for crop: StringName in patch.folds:
			var lead: float = Catalog.PARTS[crop].crop.stages.folds * 60.0
			var stormy := field.raw_storm_at(patch.middle.x, patch.middle.y, t) > 0.0 \
				or field.raw_storm_at(patch.middle.x, patch.middle.y, t + lead) > 0.0
			var was: float = patch.folds[crop]
			var now := Plant.fold_toward(was, stormy, FOLD_EVERY, is_nan(was))
			if now == was:
				continue
			patch.folds[crop] = now
			if is_nan(was) or roundi(now * Plant.FOLD_STEPS) != roundi(was * Plant.FOLD_STEPS):
				_redraw(patch)
			_fold_stand(patch, crop)


func _fold_stand(patch: Patch, crop: StringName) -> void:
	var fold: float = patch.folds[crop]
	if is_nan(fold):
		return
	for socket: Socket in patch.held.values():
		var plant := socket.part as Plant
		if plant != null and plant.crop == crop:
			plant.fold = fold


# --- Saves: only what was taken or cut. ---

## What a save keeps of the wild plants: for each loaded chunk where any were
## taken or cut, [coord, [[id, growth, fruit]...]], growth -1 for one taken.
func memories() -> Array:
	var out := []
	for coord: Vector2i in _memory:
		var held: Dictionary = _memory[coord]
		if held.is_empty():
			continue
		var each := []
		for id: int in held:
			each.append([id, held[id].x, held[id].y])
		out.append([coord, each])
	return out


## A resumed run's wild plants as they were: the memories of chunks within
## view of `around`, and every loaded chunk laid out again by them.
func recall(memories: Array, around: Vector2i) -> void:
	_memory.clear()
	for each: Array in memories:
		var coord: Vector2i = each[0]
		if maxi(absi(coord.x - around.x), absi(coord.y - around.y)) > _tuning.view_radius:
			continue
		var held := {}
		for plant: Array in each[1]:
			held[plant[0]] = Vector2(plant[1], plant[2])
		_memory[coord] = held
	for patch: Patch in _patches.values():
		if patch.next > 0:
			_unstand(patch)
			_work.append([patch.coord, &"stand"])
		_redraw(patch)
