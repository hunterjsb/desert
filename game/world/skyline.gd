class_name Skyline
extends Node3D
## What you see of history past the built ground, so a site is found by eye.
## Tall structures stand on the far ring as stand-ins, a few boxes of their
## shape at their own size in the coats their real look shows; bare metal,
## glass and glaze glints when the sun catches it, near and far; and the
## saltbush on the second age's roads stands on past it, bush by bush. All of
## it is what the sheet laid, or what it would lay from where you are,
## surveyed as it would be: a stand-in stands where its structure will, as
## high as the sand leaves it, so what's far off is what you find there. A
## worker makes it each time the sheet follows you; the main thread swaps it
## in. Over the built ground a stand-in comes in across the hand-over as the
## real thing dithers away. A storm between you and any of it hides it, as it
## hides the ground behind and the plume (Plume.seen_through).

## The eye over the sand, m, and what a pixel spans at the screen's middle,
## rad: 1080 rows under the camera's 75°.
const EYE := 1.65
const PIXEL := 0.00142
## A sighting the anchor moves less than this keeps its survey, m: the
## sheet's seams move what's far off a little as you walk.
const KEEP_M := 1.0
## Main-thread time a frame may take looking over newly laid units, and
## reading the storms between you and what's drawn, µs.
const UNITS_US := 250
const VEIL_US := 100
## What's drawn is read for storms afresh once the clock has run this long,
## s, or you've gone this far, m, since the last reading began: a storm
## moves metres in that time.
const VEIL_EVERY := Vector2(1.0, 25.0)
## Floats an instance of a box or a far bush, and of a glint, takes in its
## view's buffer.
const BOX_FLOATS := 20
const GLINT_FLOATS := 20
## A far bush's metalness and roughness: the real leaf's.
const BUSH_FINISH := Vector2(0.12, 0.62)

const BOX_SHADER := preload("res://game/world/skyline.gdshader")
const GLINT_SHADER := preload("res://game/world/glint.gdshader")

## Main-thread time it took in a frame, the most any has, and how long its
## last worker job took, ms.
var frame_ms := 0.0
var slowest_ms := 0.0
var job_ms := 0.0

var _world: World
var _tuning: Tuning
var _sites: Sites
var _size: float
var _boxes: RID
var _box_view: RID
var _glints: RID
var _glint_view: RID
var _bushes: RID
var _bush_view: RID
var _environment: Environment
var _box_look: ShaderMaterial
var _glint_look: ShaderMaterial
var _box_room := 0
var _glint_room := 0
var _bush_room := 0
## The meshes every stand-in box, glint and far bush is drawn from, kept:
## the views hold only their RIDs.
var _cube := BoxMesh.new()
var _quad := QuadMesh.new()
var _mound := _mound_mesh()
## How much of each thing drawn shows past the storms between you and it, by
## the index its instances carry, a few read afresh each frame in turn; and
## where each is looked at, world metres.
var _veils := PackedFloat32Array()
var _aims := PackedVector3Array()
var _veil_next := 0
## When and where the last reading began; NAN once one is due.
var _veil_t := NAN
var _veil_eye := Vector3.ZERO
var _veil_texture := ImageTexture.new()
## What's drawn now: the job it came from, and each thing's entry.
var _shown: Job
var _task := -1
var _job: Job
var _follows := -1
var _dirty := false
var _tick := NAN
## Each laid unit's things seen from afar, by unit.
var _of_unit := {}
## Moon cells' sites of the kinds seen from afar, made once: the worker's alone.
var _cells := {}


## One thing seen from afar: a structure, laid or sighted, and how it's drawn
## in each state: its stand-in's boxes and glints, and its own glints for
## when its chunk draws it. Slices of the views' buffers, from the job's
## centre.
class Entry:
	var site: Structure
	## Its veil's index.
	var index: int
	## Its state as the job read it, on the worker: reading the weather that
	## far back costs too much for the main thread.
	var state: int
	var ground: float
	var boxes: Array[PackedFloat32Array] = []
	## Its boxes over its own built ground, coming in as the real thing goes.
	var near_boxes: Array[PackedFloat32Array] = []
	var far_glints: Array[PackedFloat32Array] = []
	var near_glints: Array[PackedFloat32Array] = []


## A sighting past the sheet: history's site as the sheet would lay it from
## the anchor, and where that anchor put it before its survey.
class Sighting:
	var site: Site
	var placed: Vector2


## One worker's making: what it's given, then what it made.
class Job:
	var anchor: Sites.Anchor
	var center: Vector2i
	var laid_cells := {}
	var laid: Array[Structure] = []
	var laid_pieces: Array[Sites.Piece] = []
	var before := {}
	var sightings := {}
	var entries: Array[Entry] = []
	## The far bushes by the chunk they stand on, each chunk's a slice of the
	## view's buffer from the job's centre, and how many in all.
	var bushes := {}
	var bushed := 0
	## What each veil's index is of, a site's id or a chunk's coord, and where
	## it's looked at: a structure's middle, a chunk's bushes' ground.
	var keys := []
	var aims := PackedVector3Array()


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_sites = world.shape.sites
	_size = _tuning.chunk_size
	_environment = (world.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	# The pieces are loaded here, on the main thread, before a worker asks for one.
	StructureKit.kinds()
	var scenario := get_world_3d().scenario
	_upload_veils()
	_box_look = ShaderMaterial.new()
	_box_look.shader = BOX_SHADER
	_box_look.set_shader_parameter("thinnest_px", _tuning.skyline_thinnest_px)
	_box_look.set_shader_parameter("handover", _tuning.skyline_handover_m)
	_box_look.set_shader_parameter("veils", _veil_texture)
	_boxes = RenderingServer.multimesh_create()
	_cube.size = Vector3.ONE
	RenderingServer.multimesh_set_mesh(_boxes, _cube.get_rid())
	_box_view = _instance(_boxes, _box_look, scenario)
	# A far bush is drawn as a stand-in box is, on a mound from its foot.
	_bushes = RenderingServer.multimesh_create()
	RenderingServer.multimesh_set_mesh(_bushes, _mound.get_rid())
	_bush_view = _instance(_bushes, _box_look, scenario)
	_glint_look = ShaderMaterial.new()
	_glint_look.shader = GLINT_SHADER
	_glint_look.set_shader_parameter("sparkle_px", _tuning.glint_px)
	_glint_look.set_shader_parameter("brightness", _tuning.glint_brightness)
	_glint_look.set_shader_parameter("veils", _veil_texture)
	_glints = RenderingServer.multimesh_create()
	_quad.size = Vector2.ONE * 2.0
	RenderingServer.multimesh_set_mesh(_glints, _quad.get_rid())
	_glint_view = _instance(_glints, _glint_look, scenario)
	world.terrain.child_entered_tree.connect(func(_node: Node) -> void: _dirty = true)
	world.terrain.unloaded.connect(func(_coord: Vector2i) -> void: _dirty = true)


func _ready() -> void:
	# After the terrain has attached this frame's ground and the sheet has followed.
	process_priority = 20


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	for rid in [_box_view, _glint_view, _bush_view, _boxes, _glints, _bushes]:
		if rid.is_valid():
			RenderingServer.free_rid(rid)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var started := Time.get_ticks_usec()
	var shown := _tuning.skyline and _world.terrain.is_far_shown()
	RenderingServer.instance_set_visible(_box_view, shown)
	RenderingServer.instance_set_visible(_glint_view, shown)
	RenderingServer.instance_set_visible(_bush_view, shown)
	if not _tuning.skyline:
		return
	var swapped := false
	if _task != -1 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_swap(_job)
		swapped = true
	# The next job begins a frame after a swap: that frame is busy enough.
	if _task == -1 and not swapped and _sites.follows != _follows and _sites.anchor() != null:
		_launch()
	# What the sand leaves of a far site can change at an exposure tick: read
	# afresh on a worker.
	var tick := floorf(_world.time / (_tuning.site_exposure_step_minutes * 60.0))
	if tick != _tick:
		_tick = tick
		_follows = -1
	if _dirty and _shown != null:
		_dirty = false
		_draw()
	_shade()
	_read_storms()
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_ms = maxf(slowest_ms, frame_ms)
	Dev.put("terrain/sky", "%d %d %.2fms" % [_shown.entries.size() if _shown != null else 0,
		_shown.bushed if _shown != null else 0, frame_ms])


## Nothing being made.
func is_idle() -> bool:
	return not _tuning.skyline or _sites.anchor() == null \
		or (_task == -1 and _follows == _sites.follows and not _dirty)


## The origin moved: what's drawn keeps its world place.
func reposition() -> void:
	if _shown != null:
		_place()


## A structure's stand-in as drawn now, for probes: its frame's origin in
## world metres and its top's height, or {} if none is drawn.
func stand_in(site: Structure) -> Dictionary:
	if _shown == null:
		return {}
	for entry in _shown.entries:
		if entry.site == site and not _world.terrain.is_loaded_at(site.x, site.z):
			var s := _state(entry)
			if entry.boxes[s].is_empty():
				return {}
			var top := -INF
			var rows := entry.boxes[s]
			for k in range(0, rows.size(), BOX_FLOATS):
				var box := Transform3D(Basis(Vector3(rows[k], rows[k + 4], rows[k + 8]), Vector3(rows[k + 1], rows[k + 5],
					rows[k + 9]), Vector3(rows[k + 2], rows[k + 6], rows[k + 10])), Vector3(rows[k + 3], rows[k + 7], rows[k + 11]))
				for i in 8:
					top = maxf(top, (box * (Vector3(i & 1, (i >> 1) & 1, (i >> 2) & 1) - Vector3.ONE * 0.5)).y)
			var at := site.frame_on(s, entry.ground).origin
			return {"x": at.x, "z": at.z, "ground": entry.ground, "top": top}
	return {}


## A structure's glints as drawn now: on its stand-in past the built
## ground, on it where its chunk draws it; each [world place, the way it
## faces, how wide it sweeps, rad].
func glints_of(site: Structure) -> Array[Array]:
	var out: Array[Array] = []
	if _shown == null:
		return out
	var shift := Vector3(_shown.center.x * _size, 0.0, _shown.center.y * _size)
	for entry in _shown.entries:
		if entry.site != site:
			continue
		var s := _state(entry)
		var rows := entry.near_glints[s] if _world.terrain.is_loaded_at(site.x, site.z) else entry.far_glints[s]
		for k in range(0, rows.size(), GLINT_FLOATS):
			out.append([Vector3(rows[k + 3], rows[k + 7], rows[k + 11]) + shift, Vector3(rows[k + 16], rows[k + 17],
				rows[k + 18]), acos(rows[k + 19])])
	return out


## How much of a structure seen from afar shows past the storms between you
## and it as drawn now, 0 to 1: its stand-in, its boxes over its own ground
## and its glints alike. 1 for what isn't drawn.
func veil_of(site: Structure) -> float:
	if _shown != null:
		for entry in _shown.entries:
			if entry.site == site:
				return _veils[entry.index]
	return 1.0


## The far bushes drawn now, by the chunk they stand on: [how many, how much
## of them shows past the storms between you and them, their middle in world
## metres].
func far_bushes() -> Dictionary:
	var out := {}
	if _shown != null:
		var shift := Vector2(_shown.center) * _size
		for i in range(_shown.entries.size(), _shown.keys.size()):
			var coord: Vector2i = _shown.keys[i]
			if _loaded(coord):
				continue
			var rows: PackedFloat32Array = _shown.bushes[coord]
			var middle := Vector2.ZERO
			for k in range(0, rows.size(), BOX_FLOATS):
				middle += Vector2(rows[k + 3], rows[k + 11])
			out[coord] = [rows.size() / BOX_FLOATS, _veils[i], shift + middle / (rows.size() / BOX_FLOATS)]
	return out


## How brightly a glint, [where, the way it faces, how wide it sweeps],
## shines toward an eye with the sun that way, 0 to 1, before the air and
## the sky take their share (glint.gdshader).
static func shine(glint: Array, eye: Vector3, sun: Vector3) -> float:
	var n: Vector3 = glint[1]
	var v := (eye - (glint[0] as Vector3)).normalized()
	if n.dot(v) <= 0.0 or n.dot(sun) <= 0.0:
		return 0.0
	var edge := cos(glint[2] as float)
	return smoothstep(edge, lerpf(edge, 1.0, 0.75), n.dot((v + sun).normalized()))


## Every structure seen from afar now, laid or sighted.
func seen() -> Array[Structure]:
	var all: Array[Structure] = []
	if _shown != null:
		for entry in _shown.entries:
			all.append(entry.site)
	return all


# --- Where it's seen from. ---

## How far the top of something, `to` in world metres, stands clear over the
## ground as drawn from an eye at `eye`, m at its own distance; negative
## where dunes hide it. The ground is the dunes within the chunks loaded round
## `center`, the far ring's past them, and is looked over until `short` m
## before it: its own ground's. `exact` looks a metre at a time on the
## loaded ground and at every edge of the far ring's triangles, between
## which the slope to it can't peak; else more coarsely, further out.
static func clearance(shape: TerrainShape, tuning: Tuning, eye: Vector3, to: Vector3, center: Vector2i,
		short := 0.0, exact := false) -> float:
	var flat := Vector2(to.x - eye.x, to.z - eye.z)
	var dist := flat.length()
	if dist < 1.0:
		return to.y - eye.y
	var from := Vector2(eye.x, eye.z)
	var way := flat / dist
	var worst := -INF
	var d := 1.0
	var upto := dist - short
	while d < upto:
		var at := from + way * d
		if exact and not on_loaded(tuning, center, at):
			break
		worst = maxf(worst, (drawn(shape, tuning, center, at.x, at.y) - eye.y) / d)
		d = d + 1.0 if exact else next_look(d)
	if exact and d < upto:
		# Where the line crosses the far ring's lattice and its diagonals.
		var step := float(tuning.far_step)
		var end := from + way * upto
		for axis in 3:
			var a := from.x if axis == 0 else (from.y if axis == 1 else from.x + from.y)
			var b := end.x if axis == 0 else (end.y if axis == 1 else end.x + end.y)
			if absf(b - a) < 1.0e-6:
				continue
			for k in range(ceili(minf(a, b) / step), floori(maxf(a, b) / step) + 1):
				var at := from.lerp(end, (k * step - a) / (b - a))
				var by := from.distance_to(at)
				if by >= d and by > 0.0:
					worst = maxf(worst, (drawn(shape, tuning, center, at.x, at.y) - eye.y) / by)
	return to.y - eye.y - (worst * dist if worst > -INF else -INF)


## Whether a world place is on the chunks loaded round `center`.
static func on_loaded(tuning: Tuning, center: Vector2i, at: Vector2) -> bool:
	var off := Vector2i(floori(at.x / tuning.chunk_size), floori(at.y / tuning.chunk_size)) - center
	return maxi(absi(off.x), absi(off.y)) <= tuning.view_radius


## The ground as it's drawn at a world place with the chunks loaded round
## `center`: the dunes on them, the far ring's past them.
static func drawn(shape: TerrainShape, tuning: Tuning, center: Vector2i, x: float, z: float) -> float:
	return shape.dunes(x, z) if on_loaded(tuning, center, Vector2(x, z)) else FarRing.ground(shape, tuning, x, z)


## The next place along a sightline it's looked at, m: closer together near
## the eye.
static func next_look(d: float) -> float:
	return d + clampf(d * 0.02, 2.0, 16.0)


## The kinds seen from afar: those with a far look or a glint.
static func seen_kind(kind: StringName) -> bool:
	var piece := StructureKit.piece(kind)
	return piece != null and piece.seen()


## The kinds drawn past the built ground: those with a far look.
static func stands_far(kind: StringName) -> bool:
	var piece := StructureKit.piece(kind)
	return piece != null and not piece.far.is_empty()


# --- Made on a worker. ---

func _launch() -> void:
	var units := _sites.units()
	# Each unit newly laid is looked over once, a few a frame: after a jump
	# they're all new.
	var until := Time.get_ticks_usec() + UNITS_US
	for unit in units:
		if not _of_unit.has(unit):
			_of_unit[unit] = [_seen_of(unit), unit.pieces.filter(_lined)]
			if Time.get_ticks_usec() > until:
				return
	var job := Job.new()
	job.anchor = _sites.anchor()
	job.center = Vector2i(floori(job.anchor.x / _size), floori(job.anchor.z / _size))
	if _shown != null:
		job.before = _shown.sightings
	var kept := {}
	for unit in units:
		if unit.key >= 0 and _sites.has_unit(unit.key):
			job.laid_cells[unit.key] = true
		var own: Array = _of_unit[unit]
		kept[unit] = own
		job.laid.append_array(own[0])
		job.laid_pieces.append_array(own[1])
	_of_unit = kept
	_follows = _sites.follows
	_job = job
	_task = WorkerThreadPool.add_task(_make.bind(job))


## A laid unit's structures seen from afar that stand, bar those whose
## ground, once built, gave way to a bigger one's. Whether one gives way is
## only kept once its ground is built: asked sooner, it's asked afresh of
## everything round it, too dear for every structure in sight.
func _seen_of(unit: Sites.Unit) -> Array[Structure]:
	var found: Array[Structure] = []
	for site in unit.sites:
		var each := site as Structure
		if each != null and each.piece.seen() and each.stands() and each.yields != 1:
			found.append(each)
	return found


func _lined(piece: Sites.Piece) -> bool:
	return _tuning.feral and Feral.lines_along(_world.shape.history.network.paths[piece.path])


func _make(job: Job) -> void:
	var started := Time.get_ticks_usec()
	var history := _sites.history
	var reach := _tuning.skyline_m
	var anchor := job.anchor
	var here := Vector2(anchor.x, anchor.z)
	var pieces: Array[Sites.Piece] = job.laid_pieces.duplicate()
	for cell in history.cells.within(anchor.p, reach):
		if job.laid_cells.has(cell):
			continue
		for each: Dictionary in _records(history, cell):
			var placed := anchor.place(each.p)
			if placed.distance_to(here) > reach + 50.0:
				continue
			var had: Sighting = job.before.get(each.id)
			if had == null or had.placed.distance_to(placed) > KEEP_M:
				had = Sighting.new()
				had.site = _sites.sighted(each, anchor)
				had.placed = placed
			job.sightings[each.id] = had
		if _tuning.feral:
			pieces.append_array(_sites.pieces_of(cell, anchor, Feral.lines_along))
	var shown := job.laid.duplicate()
	for each: Sighting in job.sightings.values():
		var site := each.site as Structure
		if site != null and site.stands():
			shown.append(site)
	for site: Structure in shown:
		if site.distance_to(here.x, here.y) <= reach:
			var entry := _entry(site, job.center, job.keys.size())
			job.entries.append(entry)
			job.keys.append(site.id)
			job.aims.append(Vector3(site.x, entry.ground + site.top_in(entry.state) * 0.5, site.z))
	_bushes_of(history, pieces, job)
	job_ms = (Time.get_ticks_usec() - started) / 1000.0


## A cell's sites of the kinds seen from afar, made once.
func _records(history: History, cell: int) -> Array:
	var had: Variant = _cells.get(cell)
	if had == null:
		had = history.sites_in_cell(cell).filter(func(each: Dictionary) -> bool: return seen_kind(each.kind))
		if _cells.size() > 4000:
			_cells.clear()
		_cells[cell] = had
	return had


## How a structure is drawn in each state, from the job's centre, its
## instances carrying their veil's index.
func _entry(site: Structure, center: Vector2i, index: int) -> Entry:
	var entry := Entry.new()
	entry.site = site
	entry.index = index
	entry.state = site.state()
	entry.ground = FarRing.ground(_world.shape, _tuning, site.x, site.z)
	var shift := Vector3(center.x * _size, 0.0, center.y * _size)
	for s in 3:
		var frame := site.frame_on(s, entry.ground).translated(-shift)
		var own := site.frame_on(s, site.pad()).translated(-shift)
		entry.boxes.append(_boxes_of(site, s, frame, false, index))
		entry.near_boxes.append(_boxes_of(site, s, own, true, index))
		for into: Array in [[entry.far_glints, frame], [entry.near_glints, own]]:
			var rows := PackedFloat32Array()
			for each in glints_on(site, s, into[1]):
				_put_glint(rows, each[0], each[1], each[2], index)
			into[0].append(rows)
	return entry


## A structure's glints in a state on a frame, as [where, the way it faces,
## how wide it sweeps]: what's bare of sand, no two sites' plates lying quite
## the same way.
static func glints_on(site: Structure, s: int, frame: Transform3D) -> Array[Array]:
	var out: Array[Array] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = site.loot
	for each in site.bare_glints(s):
		var facing := (Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)) * Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
			* (each[1] as Vector3)).normalized()
		out.append([frame * (each[0] as Vector3), (frame.basis * facing).normalized(), each[2]])
	return out


## A stand-in's boxes in a state on a frame, each in its coat's colour as
## the worn look takes it, how solid it is, whether it's drawn over its own
## built ground, its coat's metalness and roughness, and its veil's index.
static func _boxes_of(site: Structure, s: int, frame: Transform3D, over_own: bool, index: int) -> PackedFloat32Array:
	var rows := PackedFloat32Array()
	for each in site.far_look(s):
		var box := frame * (each[0] as Transform3D)
		var b := box.basis
		var tone: Color = each[1]
		var finish: Vector2 = each[2]
		rows.append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, box.origin.x, b.x.y, b.y.y, b.z.y, box.origin.y,
			b.x.z, b.y.z, b.z.z, box.origin.z, tone.r, tone.g, tone.b, tone.a, 1.0 if over_own else 0.0,
			finish.x, finish.y, index]))
	return rows


## A glint: where it is, its veil's index, the way it faces and how wide it
## sweeps.
static func _put_glint(into: PackedFloat32Array, at: Vector3, facing: Vector3, sweep: float, index: int) -> void:
	into.append_array(PackedFloat32Array([1.0, 0.0, 0.0, at.x, 0.0, 1.0, 0.0, at.y, 0.0, 0.0, 1.0, at.z,
		index, 0.0, 0.0, 0.0, facing.x, facing.y, facing.z, cos(sweep)]))


## The close lines' wild plants in reach, each a bush on the far ground where
## its chunk would stand it, at its own size, in the leaf's own sage, grouped
## by that chunk: a group gives way to the real bushes while its chunk is
## drawn, and is veiled as one.
func _bushes_of(history: History, pieces: Array[Sites.Piece], job: Job) -> void:
	var shape := _world.shape
	var origin := Vector2(job.center) * _size
	var here := origin + Vector2.ONE * _size * 0.5
	var reach := _tuning.skyline_m
	var near := Rect2(here - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
	var by_chunk := {}
	var seen := {}
	for piece in pieces:
		var key := Vector2i(piece.path, piece.first)
		if seen.has(key):
			continue
		seen[key] = true
		for each in Feral.far_plants(history, piece, near):
			if Vector2(each.x, each.z).distance_to(here) <= reach:
				var coord := Vector2i(floori(each.x / _size), floori(each.z / _size))
				if not by_chunk.has(coord):
					by_chunk[coord] = []
				by_chunk[coord].append(each)
	var tone := Feral.LEAF[1].srgb_to_linear()
	var grown := Vector3(Feral.BUSH_WIDE, Feral.BUSH_TALL, Feral.BUSH_WIDE)
	for coord: Vector2i in by_chunk:
		var index := job.keys.size()
		var middle := (Vector2(coord) + Vector2.ONE * 0.5) * _size
		job.keys.append(coord)
		job.aims.append(Vector3(middle.x, FarRing.ground(shape, _tuning, middle.x, middle.y), middle.y))
		var rows := PackedFloat32Array()
		for each: Dictionary in by_chunk[coord]:
			var b := Basis(Vector3.UP, each.yaw) * Basis.from_scale(grown * each.size)
			var foot := Vector3(each.x - origin.x, FarRing.ground(shape, _tuning, each.x, each.z) - Feral.SINK,
				each.z - origin.y)
			rows.append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, foot.x, b.x.y, b.y.y, b.z.y, foot.y,
				b.x.z, b.y.z, b.z.z, foot.z, tone.r, tone.g, tone.b, 1.0, 0.0, BUSH_FINISH.x, BUSH_FINISH.y, index]))
		job.bushes[coord] = rows
		job.bushed += rows.size() / BOX_FLOATS


## A bush far off: a low mound a metre across, rising a metre from its foot
## before it's sized.
static func _mound_mesh() -> ArrayMesh:
	var dome := SphereMesh.new()
	dome.radius = 0.5
	dome.height = 1.0
	dome.radial_segments = 8
	dome.rings = 3
	dome.is_hemisphere = true
	var arrays := dome.get_mesh_arrays()
	var box := dome.get_aabb()
	var at: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in at.size():
		at[i] = Vector3(at[i].x, (at[i].y - box.position.y) / box.size.y, at[i].z)
	arrays[Mesh.ARRAY_VERTEX] = at
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# --- Drawn on the main thread. ---

func _swap(job: Job) -> void:
	# What was drawn keeps its veil; what's new is hidden until it's read.
	var had := {}
	if _shown != null:
		for i in _shown.keys.size():
			had[_shown.keys[i]] = _veils[i]
	var veils := PackedFloat32Array()
	for key: Variant in job.keys:
		veils.append(had.get(key, 0.0))
	_veils = veils
	_aims = job.aims
	_veil_next = 0
	_veil_t = NAN
	_upload_veils()
	_shown = job
	_place()
	_dirty = true


## Every entry's look in its state now: a stand-in and its glints past the
## built ground, its own glints on it where its chunk draws it; and the far
## bushes on every chunk not drawn.
func _draw() -> void:
	var boxes := PackedFloat32Array()
	var glints := PackedFloat32Array()
	var bushes := PackedFloat32Array()
	var terrain := _world.terrain
	for entry in _shown.entries:
		# Its ground, built since, gave way to a bigger one's.
		if entry.site.yields == 1:
			continue
		var s := _state(entry)
		if terrain.is_loaded_at(entry.site.x, entry.site.z):
			boxes.append_array(entry.near_boxes[s])
			glints.append_array(entry.near_glints[s])
		else:
			boxes.append_array(entry.boxes[s])
			glints.append_array(entry.far_glints[s])
	for coord: Vector2i in _shown.bushes:
		if not _loaded(coord):
			bushes.append_array(_shown.bushes[coord])
	_box_room = _fill(_boxes, boxes, _box_room, BOX_FLOATS, true)
	_glint_room = _fill(_glints, glints, _glint_room, GLINT_FLOATS, true)
	_bush_room = _fill(_bushes, bushes, _bush_room, BOX_FLOATS, true)


func _loaded(coord: Vector2i) -> bool:
	return _world.terrain.is_loaded_at((coord.x + 0.5) * _size, (coord.y + 0.5) * _size)


## An entry's state now: as its chunk's build read it where that's drawn,
## else as the job read it.
func _state(entry: Entry) -> int:
	return entry.site.state() if _world.terrain.is_loaded_at(entry.site.x, entry.site.z) else entry.state


## Puts a buffer of instances in a multimesh, a transform, a colour if
## `colours`, and custom data each, growing its room as needed.
static func _fill(multimesh: RID, buffer: PackedFloat32Array, room: int, stride: int, colours: bool) -> int:
	var count := buffer.size() / stride
	if count > room:
		room = maxi(count, room * 2)
		RenderingServer.multimesh_allocate_data(multimesh, room, RenderingServer.MULTIMESH_TRANSFORM_3D, colours, true)
	if count > 0:
		var full := buffer.duplicate()
		full.resize(room * stride)
		RenderingServer.multimesh_set_buffer(multimesh, full)
	RenderingServer.multimesh_set_visible_instances(multimesh, count)
	return room


func _place() -> void:
	var at := Vector3((_shown.center.x - _world.origin_chunk.x) * _size, 0.0,
		(_shown.center.y - _world.origin_chunk.y) * _size)
	RenderingServer.instance_set_transform(_bush_view, Transform3D(Basis.IDENTITY, at))
	RenderingServer.instance_set_transform(_box_view, Transform3D(Basis.IDENTITY, at))
	RenderingServer.instance_set_transform(_glint_view, Transform3D(Basis.IDENTITY, at))


## The sun and the air on the glints, each frame.
func _shade() -> void:
	var weather := _world.weather
	var t := _world.time
	var moon := _world.moon
	var sun := weather.day.sun_direction(t, moon.latitude, moon.longitude)
	var risen := smoothstep(-0.02, 0.1, sun.y) * weather.day.sun_shown(t)
	var glare := risen * weather.seen_sun * (1.0 - weather.seen_shade) * (0.0 if weather.in_storm else 1.0)
	_glint_look.set_shader_parameter("sun_dir", sun)
	_glint_look.set_shader_parameter("glare", glare)
	_glint_look.set_shader_parameter("haze", Vector3(_environment.fog_depth_begin, _environment.fog_depth_end,
		_tuning.haze_strength))


## What's drawn read for the storms between you and it, a few each frame in
## turn within VEIL_US, a reading at a time (VEIL_EVERY).
func _read_storms() -> void:
	var count := _veils.size()
	if count == 0:
		return
	var camera := _world.player.camera.global_position
	var eye := Vector3(_world.world_x(camera.x), camera.y, _world.world_z(camera.z))
	if _veil_next == 0:
		if not is_nan(_veil_t) and absf(_world.time - _veil_t) < VEIL_EVERY.x \
				and eye.distance_to(_veil_eye) < VEIL_EVERY.y:
			return
		_veil_t = _world.time
		_veil_eye = eye
	var weather := _world.weather
	var round_you := 1.0 - weather.seen_storm
	var until := Time.get_ticks_usec() + VEIL_US
	var changed := false
	while Time.get_ticks_usec() < until:
		var through := Plume.seen_through(weather.field, _tuning, eye, _aims[_veil_next], _world.time) * round_you
		if absf(through - _veils[_veil_next]) > 0.005:
			_veils[_veil_next] = through
			changed = true
		_veil_next = (_veil_next + 1) % count
		if _veil_next == 0:
			break
	if changed:
		_upload_veils()


## The veils as the shaders read them, a texel each.
func _upload_veils() -> void:
	var wide := maxi(64, nearest_po2(_veils.size()))
	var texels := _veils.duplicate()
	texels.resize(wide)
	var image := Image.create_from_data(wide, 1, false, Image.FORMAT_RF, texels.to_byte_array())
	if _veil_texture.get_width() == wide:
		_veil_texture.update(image)
	else:
		_veil_texture.set_image(image)


static func _instance(multimesh: RID, look: Material, scenario: RID) -> RID:
	var view := RenderingServer.instance_create2(multimesh, scenario)
	RenderingServer.instance_geometry_set_material_override(view, look.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(view, RenderingServer.SHADOW_CASTING_SETTING_OFF)
	# Its instances stand kilometres apart; the view never culls them as one box.
	RenderingServer.instance_set_extra_visibility_margin(view, 1.0e6)
	return view
