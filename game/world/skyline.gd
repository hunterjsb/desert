class_name Skyline
extends Node3D
## What you see of history past the built ground, so a site is found by eye.
## Tall structures stand on the far ring as stand-ins, a few boxes of their
## shape in their paint's tone; bare metal, glass and glaze glints when the
## sun catches it, near and far; and the saltbush lines on the second age's
## roads run on across the dunes. All of it is what the sheet laid, or what
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
## The lines' mesh drawn now, and the next, a worker's to fill.
var _line_mesh: RID
var _environment: Environment
var _box_look: ShaderMaterial
var _glint_look: ShaderMaterial
var _line_look: ShaderMaterial
var _box_room := 0
var _glint_room := 0
## The meshes every stand-in box and glint is drawn from: kept, as views hold only their RIDs.
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
## in each state: its stand-in's boxes and glints, and its own glints for
## when its chunk draws it. Slices of the views' buffers, from the job's
## centre.
class Entry:
	var site: Structure
	## Its state as the job read it, on the worker: reading the weather that
	## far back costs too much for the main thread.
	var state: int
	var chunk: Vector2i
	var ground: float
	var boxes: Array[PackedFloat32Array] = []
	var far_glints: Array[PackedFloat32Array] = []
	var near_glints: Array[PackedFloat32Array] = []


## A sighting past the sheet: history's site as the sheet would lay it from
## the anchor, and where that anchor put it before its survey.
class Sighting:
	var site: Site
	var placed: Vector2
	var cell: int


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
	_boxes = RenderingServer.multimesh_create()
	_cube.size = Vector3.ONE
	RenderingServer.multimesh_set_mesh(_boxes, _cube.get_rid())
	_box_view = _instance(_boxes, _box_look, scenario)
	_glint_look = ShaderMaterial.new()
	_glint_look.shader = GLINT_SHADER
	_glint_look.set_shader_parameter("peak_px", _tuning.glint_px)
	_glint_look.set_shader_parameter("brightness", _tuning.glint_brightness)
	_glints = RenderingServer.multimesh_create()
	_quad.size = Vector2.ONE * 2.0
	RenderingServer.multimesh_set_mesh(_glints, _quad.get_rid())
	_glint_view = _instance(_glints, _glint_look, scenario)
	_line_look = ShaderMaterial.new()
	_line_look.shader = BOX_SHADER
	_line_look.set_shader_parameter("thinnest_px", _tuning.skyline_thinnest_px)
	_line_look.set_shader_parameter("draped", true)
	_line_look.set_shader_parameter("leaf", Feral.LEAF[1].srgb_to_linear())
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
	for rid in [_box_view, _glint_view, _line_view, _boxes, _glints, _line_mesh]:
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
		_follows = _sites.follows
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
			for k in range(0, rows.size(), 16):
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
		var s := _state(entry)
		var rows := entry.near_glints[s] if _world.terrain.is_loaded_at(site.x, site.z) else entry.far_glints[s]
		for k in range(0, rows.size(), 16):
			out.append([Vector3(rows[k + 3], rows[k + 7], rows[k + 11]) + shift, Vector3(rows[k + 12], rows[k + 13],
				rows[k + 14]), rows[k + 15]])
	return out


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
## before it: its own ground's.
static func clearance(shape: TerrainShape, tuning: Tuning, eye: Vector3, to: Vector3, center: Vector2i,
		short := 0.0) -> float:
	var flat := Vector2(to.x - eye.x, to.z - eye.z)
	var dist := flat.length()
	if dist < 1.0:
		return to.y - eye.y
	var way := flat / dist
	var worst := -INF
	var d := 2.0
	while d < dist - short:
		var at := Vector2(eye.x, eye.z) + way * d
		worst = maxf(worst, (drawn(shape, tuning, center, at.x, at.y) - eye.y) / d)
		d = next_look(d)
	return to.y - eye.y - (worst * dist if worst > -INF else -INF)


## The ground as it's drawn at a world place with the chunks loaded round
## `center`: the dunes on them, the far ring's past them.
static func drawn(shape: TerrainShape, tuning: Tuning, center: Vector2i, x: float, z: float) -> float:
	var off := Vector2i(floori(x / tuning.chunk_size), floori(z / tuning.chunk_size)) - center
	return shape.dunes(x, z) if maxi(absi(off.x), absi(off.y)) <= tuning.view_radius \
		else FarRing.ground(shape, tuning, x, z)


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
	var job := Job.new()
	job.anchor = _sites.anchor()
	job.center = Vector2i(floori(job.anchor.x / _size), floori(job.anchor.z / _size))
	if _shown != null:
		job.before = _shown.sightings
	var kept := {}
	for unit in _sites.units():
		if unit.key >= 0 and _sites.has_unit(unit.key):
			job.laid_cells[unit.key] = true
		var own: Array = _of_unit.get(unit, [])
		if own.is_empty():
			own = [_seen_of(unit), unit.pieces.filter(_lined)]
		kept[unit] = own
		job.laid.append_array(own[0])
		job.laid_pieces.append_array(own[1])
	_of_unit = kept
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
				had.cell = cell
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
	entry.chunk = Vector2i(floori(site.x / _size), floori(site.z / _size))
	entry.ground = FarRing.ground(_world.shape, _tuning, site.x, site.z)
	var shift := Vector3(center.x * _size, 0.0, center.y * _size)
	var rng := RandomNumberGenerator.new()
	for s in 3:
		var boxes := PackedFloat32Array()
		var frame := site.frame_on(s, entry.ground).translated(-shift)
		for each in site.far_look(s):
			_put_box(boxes, frame * (each[0] as Transform3D), (each[1] as Color).srgb_to_linear())
		entry.boxes.append(boxes)
		var far := PackedFloat32Array()
		var near := PackedFloat32Array()
		var own := site.frame_on(s, site.pad()).translated(-shift)
		rng.seed = site.loot
		for each in site.bare_glints(s):
			# No two sites' plates lie quite the same way.
			var facing := (Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)) * Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
				* (each[1] as Vector3)).normalized()
			for into: Array in [[far, frame], [near, own]]:
				var at: Transform3D = into[1]
				_put_glint(into[0], at * (each[0] as Vector3), (at.basis * facing).normalized(), each[2])
		entry.far_glints.append(far)
		entry.near_glints.append(near)
	return entry


static func _put_box(into: PackedFloat32Array, box: Transform3D, tone: Color) -> void:
	var b := box.basis
	into.append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, box.origin.x, b.x.y, b.y.y, b.z.y, box.origin.y,
		b.x.z, b.y.z, b.z.z, box.origin.z, tone.r, tone.g, tone.b, 1.0]))


static func _put_glint(into: PackedFloat32Array, at: Vector3, facing: Vector3, sweep: float) -> void:
	into.append_array(PackedFloat32Array([1.0, 0.0, 0.0, at.x, 0.0, 1.0, 0.0, at.y, 0.0, 0.0, 1.0, at.z,
		facing.x, facing.y, facing.z, cos(sweep)]))


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
			glints.append_array(entry.near_glints[s])
		else:
			boxes.append_array(entry.boxes[s])
			glints.append_array(entry.far_glints[s])
	_box_room = _fill(_boxes, boxes, _box_room, true)
	_glint_room = _fill(_glints, glints, _glint_room, false)


## An entry's state now: as its chunk's build read it where that's drawn,
## else as the job read it.
func _state(entry: Entry) -> int:
	return entry.site.state() if _world.terrain.is_loaded_at(entry.site.x, entry.site.z) else entry.state


## Puts a buffer of 16-float instances in a multimesh, a transform and a
## colour or custom data each, growing its room as needed.
static func _fill(multimesh: RID, buffer: PackedFloat32Array, room: int, colours: bool) -> int:
	var count := buffer.size() / 16
	if count > room:
		room = maxi(count, room * 2)
		RenderingServer.multimesh_allocate_data(multimesh, room, RenderingServer.MULTIMESH_TRANSFORM_3D, colours,
			not colours)
	if count > 0:
		var full := buffer.duplicate()
		full.resize(room * 16)
		RenderingServer.multimesh_set_buffer(multimesh, full)
	RenderingServer.multimesh_set_visible_instances(multimesh, count)
	return room


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


static func _instance(multimesh: RID, look: Material, scenario: RID) -> RID:
	var view := RenderingServer.instance_create2(multimesh, scenario)
	RenderingServer.instance_geometry_set_material_override(view, look.get_rid())
	RenderingServer.instance_geometry_set_cast_shadows_setting(view, RenderingServer.SHADOW_CASTING_SETTING_OFF)
	# Its instances stand kilometres apart; the view never culls them as one box.
	RenderingServer.instance_set_extra_visibility_margin(view, 1.0e6)
	return view

