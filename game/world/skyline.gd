class_name Skyline
extends Node3D
## What you see of history past the built ground, so a site is found by eye.
## Tall structures stand on the far ring as stand-ins, a few boxes of their
## shape in their paint's tone; bare metal, glass and glaze glints when the
## sun catches it, near and far; and the saltbush lines on the second age's
## roads run on across the dunes. Inside a storm, what it has just laid bare
## near you glints through the dust and clangs on the wind. All of it is what the sheet laid, or what
## it would lay from where you are, surveyed as it would be: a stand-in
## stands where its structure will, as high as the sand leaves it, so what's
## far off is what you find there. A worker makes it each time the sheet
## follows you; the main thread swaps it in, and hides a stand-in once its
## chunk draws the real thing.

## The eye over the sand, m, and what a pixel spans at the screen's middle,
## rad: 1080 rows under the camera's 75°.
const EYE := 1.65
const PIXEL := 0.00142
## A sighting the anchor moves less than this keeps its survey, m: the
## sheet's seams move what's far off a little as you walk.
const KEEP_M := 1.0
## Lines are draped on the far ground at this spacing, m.
const DRAPE_M := 8.0
## Main-thread time a frame may take looking over newly laid units, µs.
const UNITS_US := 250
## Floats an instance of a box and of a glint takes in its view's buffer.
const BOX_FLOATS := 20
const GLINT_FLOATS := 20
## What stands on loaded ground is drawn again at most this often as a storm
## moves it, and what a storm has just laid bare looked over this often, s.
const REDRAW_S := 0.2
## What a storm has just laid bare clangs on the wind: a chance each this
## many s of world time, by how far it's laid bare; heard after the sound's
## trip, at its level from this far, m.
const CLANG_S := 4.0
const CLANG_CHANCE := 0.35
const CLANG_UNIT := 20.0
const SOUND_SPEED := 343.0

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
var _line_view: RID
## The lines' mesh drawn now; each job's own is a worker's to fill.
var _line_mesh: RID
var _environment: Environment
var _box_look: ShaderMaterial
var _glint_look: ShaderMaterial
var _line_look: ShaderMaterial
var _box_room := 0
var _glint_room := 0
## Glints through a storm's dust, off what it has just laid bare near you:
## drawn from the chunk you're on.
var _dust_glints: RID
var _dust_view: RID
var _dust_look: ShaderMaterial
var _dust_room := 0
var _dust_center := Vector2i.ZERO
## Each site's last chance to clang, by its tick.
var _clanged := {}
## Whether what stands on loaded ground has moved since it was last drawn,
## and when anything was last drawn or looked over, usec.
var _moved := false
var _drawn_at := 0
var _dust_at := 0
## The meshes every stand-in box and glint is drawn from, kept: the views
## hold only their RIDs.
var _cube := BoxMesh.new()
var _quad := QuadMesh.new()
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
## in each state: its stand-in's boxes and glints. Where its chunk draws it,
## its own glints are read as it stands. Slices of the views' buffers, from the job's
## centre.
class Entry:
	var site: Structure
	## Its state as the job read it, on the worker: reading the weather that
	## far back costs too much for the main thread.
	var state: int
	var ground: float
	var boxes: Array[PackedFloat32Array] = []
	## A landmark's boxes over its own built ground, till the real thing takes over.
	var near_boxes: Array[PackedFloat32Array] = []
	var far_glints: Array[PackedFloat32Array] = []


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
	var lines: RID
	var lined := 0


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_sites = world.shape.sites
	_size = _tuning.chunk_size
	_environment = (world.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	# The pieces are loaded here, on the main thread, before a worker asks for one.
	StructureKit.kinds()
	var scenario := get_world_3d().scenario
	_box_look = ShaderMaterial.new()
	_box_look.shader = BOX_SHADER
	_box_look.set_shader_parameter("thinnest_px", _tuning.skyline_thinnest_px)
	_box_look.set_shader_parameter("landmark_px", _tuning.skyline_landmark_px)
	_boxes = RenderingServer.multimesh_create()
	_cube.size = Vector3.ONE
	RenderingServer.multimesh_set_mesh(_boxes, _cube.get_rid())
	_box_view = _instance(_boxes, _box_look, scenario)
	_glint_look = ShaderMaterial.new()
	_glint_look.shader = GLINT_SHADER
	_glint_look.set_shader_parameter("sparkle_px", _tuning.glint_px)
	_glint_look.set_shader_parameter("landmark_px", _tuning.skyline_landmark_px)
	_glint_look.set_shader_parameter("brightness", _tuning.glint_brightness)
	_glints = RenderingServer.multimesh_create()
	_quad.size = Vector2.ONE * 2.0
	RenderingServer.multimesh_set_mesh(_glints, _quad.get_rid())
	_glint_view = _instance(_glints, _glint_look, scenario)
	_dust_look = _glint_look.duplicate()
	_dust_look.set_shader_parameter("dust_reach", _tuning.storm_glint_m)
	_dust_look.set_shader_parameter("widen", deg_to_rad(_tuning.storm_glint_widen_degrees))
	_dust_glints = RenderingServer.multimesh_create()
	RenderingServer.multimesh_set_mesh(_dust_glints, _quad.get_rid())
	_dust_view = _instance(_dust_glints, _dust_look, scenario)
	_line_look = ShaderMaterial.new()
	_line_look.shader = BOX_SHADER
	_line_look.set_shader_parameter("thinnest_px", _tuning.skyline_thinnest_px)
	_line_look.set_shader_parameter("draped", true)
	# The leaf's shade side: a line far off reads by how it darkens the sand.
	_line_look.set_shader_parameter("leaf", Feral.LEAF[2].srgb_to_linear())
	_line_look.set_shader_parameter("line_px", _tuning.skyline_line_px)
	_line_view = RenderingServer.instance_create()
	RenderingServer.instance_set_scenario(_line_view, scenario)
	RenderingServer.instance_geometry_set_material_override(_line_view, _line_look.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(_line_view, RenderingServer.SHADOW_CASTING_SETTING_OFF)
	RenderingServer.instance_set_extra_visibility_margin(_line_view, 1.0e6)
	world.terrain.child_entered_tree.connect(func(_node: Node) -> void: _dirty = true)
	world.terrain.unloaded.connect(func(_coord: Vector2i) -> void: _dirty = true)


func _ready() -> void:
	# After the terrain has attached this frame's ground and the sheet has followed.
	process_priority = 20


func _exit_tree() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if _job != null and _job != _shown and _job.lines.is_valid():
		RenderingServer.free_rid(_job.lines)
	for rid in [_box_view, _glint_view, _line_view, _dust_view, _boxes, _glints, _dust_glints, _line_mesh]:
		if rid.is_valid():
			RenderingServer.free_rid(rid)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var started := Time.get_ticks_usec()
	var shown := _tuning.skyline and _world.terrain.is_far_shown()
	RenderingServer.instance_set_visible(_box_view, shown)
	RenderingServer.instance_set_visible(_glint_view, shown)
	RenderingServer.instance_set_visible(_line_view, shown)
	# Inside a storm, what it has just laid bare: the far ring's hidden then.
	var in_dust := _tuning.skyline and not _world.terrain.is_far_shown()
	RenderingServer.instance_set_visible(_dust_view, in_dust)
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
	# What the sand leaves of a far site changes as storms work on it: read
	# afresh on a worker each time the storm's work is read.
	var tick := floorf(_world.time / Exposure.SURGE_STEP_S)
	if tick != _tick:
		_tick = tick
		_follows = -1
	var now := Time.get_ticks_usec()
	if _shown != null and (_dirty or (_moved and now - _drawn_at >= REDRAW_S * 1e6)):
		_dirty = false
		_moved = false
		_drawn_at = now
		_draw()
	if in_dust and now - _dust_at >= REDRAW_S * 1e6:
		_dust_at = now
		_draw_dust()
	_shade()
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_ms = maxf(slowest_ms, frame_ms)
	Dev.put("terrain/sky", "%d %.2fms" % [_shown.entries.size() if _shown != null else 0, frame_ms])


## Nothing being made.
func is_idle() -> bool:
	return not _tuning.skyline or _sites.anchor() == null \
		or (_task == -1 and _follows == _sites.follows and not _dirty)


## The origin moved: what's drawn keeps its world place.
func reposition() -> void:
	if _shown != null:
		_place()
	_place_dust()


## What stands on loaded ground moved: drawn again soon.
func moved() -> void:
	_moved = true


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
## faces, the cosine of how wide it sweeps].
func glints_of(site: Structure) -> Array[Array]:
	var out: Array[Array] = []
	if _shown == null:
		return out
	var shift := Vector3(_shown.center.x * _size, 0.0, _shown.center.y * _size)
	for entry in _shown.entries:
		if entry.site != site:
			continue
		var rows := entry.far_glints[_state(entry)]
		if _world.terrain.is_loaded_at(site.x, site.z):
			rows = PackedFloat32Array()
			_own_glints(site, rows, _shown.center)
		_unpack(rows, shift, out)
	return out


## The glints through a storm's dust drawn now: each [world place, the way
## it faces, the cosine of how wide it sweeps].
func dust_glints() -> Array[Array]:
	var out: Array[Array] = []
	var rows := PackedFloat32Array()
	rows.resize(_dust_room * GLINT_FLOATS)
	if _dust_room > 0:
		rows = RenderingServer.multimesh_get_buffer(_dust_glints)
	rows.resize(RenderingServer.multimesh_get_visible_instances(_dust_glints) * GLINT_FLOATS)
	_unpack(rows, Vector3(_dust_center.x * _size, 0.0, _dust_center.y * _size), out)
	return out


static func _unpack(rows: PackedFloat32Array, shift: Vector3, out: Array[Array]) -> void:
	for k in range(0, rows.size(), GLINT_FLOATS):
		out.append([Vector3(rows[k + 3], rows[k + 7], rows[k + 11]) + shift, Vector3(rows[k + 16], rows[k + 17],
			rows[k + 18]), rows[k + 19]])


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
	# Made here: the main thread makes the RIDs, a worker fills them.
	job.lines = RenderingServer.mesh_create()
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
			job.entries.append(_entry(site, job.center))
	var arrays := _drape(history, pieces, job.center)
	if not arrays.is_empty():
		job.lined = (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		RenderingServer.mesh_add_surface_from_arrays(job.lines, RenderingServer.PRIMITIVE_TRIANGLES, arrays, [], {},
			RenderingServer.ARRAY_CUSTOM_RGBA_FLOAT << RenderingServer.ARRAY_FORMAT_CUSTOM0_SHIFT)
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


## How a structure is drawn in each state, from the job's centre.
func _entry(site: Structure, center: Vector2i) -> Entry:
	var entry := Entry.new()
	entry.site = site
	entry.state = site.state()
	entry.ground = FarRing.ground(_world.shape, _tuning, site.x, site.z)
	var shift := Vector3(center.x * _size, 0.0, center.y * _size)
	var landmark := site.piece.far_landmark
	for s in 3:
		var frame := site.frame_on(s, entry.ground).translated(-shift)
		var own := site.frame_on(s, site.pad()).translated(-shift)
		var tall := site.top_in(s)
		entry.boxes.append(_boxes_of(site, s, frame, entry.ground, tall if landmark else 0.0, shift))
		entry.near_boxes.append(_boxes_of(site, s, own, site.pad(), -tall, shift) if landmark else PackedFloat32Array())
		var far := PackedFloat32Array()
		for each in site.bare_glints_at(s):
			# On a landmark it rides with its stand-in as that's drawn larger.
			var spot := frame * (each[0] as Vector3)
			var foot := Vector3(site.x, entry.ground, site.z) - shift
			_put_glint(far, spot, (frame.basis * _facing(site, each)).normalized(), each[2], foot - spot,
				tall if landmark else 0.0)
		entry.far_glints.append(far)
	return entry


## No two sites' plates lie quite the same way: a glint's own turn, the same
## each time it shows.
static func _facing(site: Structure, glint: Array) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([site.loot, glint[3]])
	return (Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)) * Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
		* (glint[1] as Vector3)).normalized()


## A loaded structure's own glints where the sand leaves them bare as it
## stands now, from a chunk's corner; with `newly`, only those the storm
## working on it has just laid bare.
func _own_glints(site: Structure, into: PackedFloat32Array, center: Vector2i, newly := false) -> void:
	var level := site.level()
	var shift := Vector3(center.x * _size, 0.0, center.y * _size)
	var frame := site.frame_at(level).translated(-shift)
	var foot := Vector3(site.x, site.pad(), site.z) - shift
	var tall := -site.top_in(StructureKit.Piece.shown_state(level)) if site.piece.far_landmark else 0.0
	var before := {}
	if newly:
		for each in site.bare_glints_at(Exposure.level(site.depth, site.settled())):
			before[each[3]] = true
	for each in site.bare_glints_at(level):
		if before.has(each[3]):
			continue
		var spot := frame * (each[0] as Vector3)
		_put_glint(into, spot, (frame.basis * _facing(site, each)).normalized(), each[2], foot - spot, tall)


## A stand-in's boxes in a state on a frame, each with the way to its foot
## and, for a landmark, how tall it stands (negative over its own ground).
func _boxes_of(site: Structure, s: int, frame: Transform3D, ground: float, tall: float, shift: Vector3) -> PackedFloat32Array:
	var rows := PackedFloat32Array()
	var foot := Vector3(site.x, ground, site.z) - shift
	for each in site.far_look(s):
		var box := frame * (each[0] as Transform3D)
		var b := box.basis
		var tone := (each[1] as Color).srgb_to_linear()
		var to := foot - box.origin
		rows.append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, box.origin.x, b.x.y, b.y.y, b.z.y, box.origin.y,
			b.x.z, b.y.z, b.z.z, box.origin.z, tone.r, tone.g, tone.b, 1.0, to.x, to.y, to.z, tall]))
	return rows


## A glint: where it is, with the way to its foot and its landmark's height
## as the box's are, then the way it faces and how wide it sweeps.
static func _put_glint(into: PackedFloat32Array, at: Vector3, facing: Vector3, sweep: float, to: Vector3,
		tall: float) -> void:
	into.append_array(PackedFloat32Array([1.0, 0.0, 0.0, at.x, 0.0, 1.0, 0.0, at.y, 0.0, 0.0, 1.0, at.z,
		to.x, to.y, to.z, tall, facing.x, facing.y, facing.z, cos(sweep)]))


## The lines' arrays: each living stretch draped on the far ground as a low
## ridge, past the chunks loaded round the centre, where Feral's own stand.
func _drape(history: History, pieces: Array[Sites.Piece], center: Vector2i) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var spread := PackedFloat32Array()
	var indices := PackedInt32Array()
	var shape := _world.shape
	var origin := Vector2(center) * _size
	var inner := Rect2(origin - Vector2.ONE * _tuning.view_radius * _size, Vector2.ONE * (2 * _tuning.view_radius + 1) * _size)
	var reach := _tuning.skyline_m
	var here := origin + Vector2.ONE * _size * 0.5
	var seen := {}
	for piece in pieces:
		var key := Vector2i(piece.path, piece.first)
		if seen.has(key):
			continue
		seen[key] = true
		for line in Feral.far_lines(history, piece):
			var a: Vector2 = line[0]
			var b: Vector2 = line[1]
			var length := a.distance_to(b)
			var steps := maxi(1, ceili(length / DRAPE_M))
			var across := (b - a).orthogonal().normalized()
			var last := -1
			for k in steps + 1:
				var at := a.lerp(b, float(k) / steps)
				if inner.has_point(at) or at.distance_to(here) > reach:
					last = -1
					continue
				var y := FarRing.ground(shape, _tuning, at.x, at.y)
				var base := vertices.size()
				for side in [-1.0, 0.0, 1.0]:
					var lift: float = line[2] if side == 0.0 else -0.15
					vertices.append(Vector3(at.x - origin.x, y, at.y - origin.y))
					var out := Vector3(across.x * side * line[3] * 0.5, lift, across.y * side * line[3] * 0.5)
					spread.append_array(PackedFloat32Array([out.x, out.y, out.z, 0.0]))
					normals.append(Vector3(across.x * side, 1.0, across.y * side).normalized())
				if last >= 0:
					indices.append_array(PackedInt32Array([last, last + 1, base, base, last + 1, base + 1,
						last + 1, last + 2, base + 1, base + 1, last + 2, base + 2]))
				last = base
	if indices.is_empty():
		return []
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_CUSTOM0] = spread
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


# --- Drawn on the main thread. ---

func _swap(job: Job) -> void:
	_shown = job
	_place()
	RenderingServer.instance_set_base(_line_view, job.lines)
	if _line_mesh.is_valid():
		RenderingServer.free_rid(_line_mesh)
	_line_mesh = job.lines
	_dirty = true


## Every entry's look in its state now: a stand-in and its glints past the
## built ground, its own glints on it where its chunk draws it.
func _draw() -> void:
	var boxes := PackedFloat32Array()
	var glints := PackedFloat32Array()
	var terrain := _world.terrain
	for entry in _shown.entries:
		# Its ground, built since, gave way to a bigger one's.
		if entry.site.yields == 1:
			continue
		var s := _state(entry)
		if terrain.is_loaded_at(entry.site.x, entry.site.z):
			boxes.append_array(entry.near_boxes[s])
			_own_glints(entry.site, glints, _shown.center)
		else:
			boxes.append_array(entry.boxes[s])
			glints.append_array(entry.far_glints[s])
	_box_room = _fill(_boxes, boxes, _box_room, BOX_FLOATS, true)
	_glint_room = _fill(_glints, glints, _glint_room, GLINT_FLOATS, true)


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


## Inside a storm: what it has just laid bare near you glints through the
## dust, and now and then clangs on the wind. Asked of the index by area.
func _draw_dust() -> void:
	var x := _world.player_world_x()
	var z := _world.player_world_z()
	var center := _world.terrain.chunk_at(x, z)
	if center != _dust_center:
		_dust_center = center
		_place_dust()
	var rows := PackedFloat32Array()
	for each in _sites.newly_exposed(x, z, maxf(_tuning.storm_glint_m, _tuning.storm_clang_m)):
		var site: Structure = each[0]
		if site.piece.glints.is_empty():
			continue
		var by := site.distance_to(x, z)
		if by <= _tuning.storm_glint_m and _world.terrain.is_loaded_at(site.x, site.z):
			_own_glints(site, rows, center, true)
		if by <= _tuning.storm_clang_m:
			_clang(site, each[1], by)
	_dust_room = _fill(_dust_glints, rows, _dust_room, GLINT_FLOATS, true)


## A chance for what a storm has just laid bare to clang, once each CLANG_S;
## heard after the sound has come that far, duller the further.
func _clang(site: Structure, bared: float, by: float) -> void:
	var tick := floori(_world.time / CLANG_S)
	if _clanged.get(site, -1) == tick:
		return
	if _clanged.size() > 256:
		_clanged.clear()
	_clanged[site] = tick
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([site.loot, "clang", tick])
	if rng.randf() >= CLANG_CHANCE * clampf(bared, 0.0, 1.0):
		return
	var top := site.frame() * Vector3(0.0, site.top_in(StructureKit.Piece.shown_state(site.level())) * 0.5, 0.0)
	get_tree().create_timer(by / SOUND_SPEED).timeout.connect(_ring.bind(top))


func _ring(at: Vector3) -> void:
	var voice := Sounds.world_voice(Sounds.CLANG, 0.0, CLANG_UNIT)
	voice.attenuation_filter_cutoff_hz = 2500.0
	voice.attenuation_filter_db = -18.0
	voice.finished.connect(voice.queue_free)
	add_child(voice)
	voice.global_position = Vector3(_world.engine_x(at.x), at.y, _world.engine_z(at.z))
	voice.play()


func _place_dust() -> void:
	RenderingServer.instance_set_transform(_dust_view, Transform3D(Basis.IDENTITY,
		Vector3((_dust_center.x - _world.origin_chunk.x) * _size, 0.0, (_dust_center.y - _world.origin_chunk.y) * _size)))


func _place() -> void:
	var at := Vector3((_shown.center.x - _world.origin_chunk.x) * _size, 0.0,
		(_shown.center.y - _world.origin_chunk.y) * _size)
	RenderingServer.instance_set_transform(_line_view, Transform3D(Basis.IDENTITY, at))
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
	if weather.map != null:
		var uniforms := weather.map.uniforms(t)
		for key: String in uniforms:
			_glint_look.set_shader_parameter(key, uniforms[key])
	# In the dust the light comes from all round overhead, and less of it.
	_dust_look.set_shader_parameter("sun_dir", weather.light_dir)
	_dust_look.set_shader_parameter("glare", risen * _tuning.storm_glint_light)
	_dust_look.set_shader_parameter("dust_time", t)


static func _instance(multimesh: RID, look: Material, scenario: RID) -> RID:
	var view := RenderingServer.instance_create2(multimesh, scenario)
	RenderingServer.instance_geometry_set_material_override(view, look.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(view, RenderingServer.SHADOW_CASTING_SETTING_OFF)
	# Its instances stand kilometres apart; the view never culls them as one box.
	RenderingServer.instance_set_extra_visibility_margin(view, 1.0e6)
	return view

