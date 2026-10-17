class_name Tracks
extends Node
## The marks you leave on the sand, so your way back can be followed through a
## storm or the night: footprints, the board's wake, the groove of anything
## dragged and the imprint under anything resting. A layer the sand is drawn
## with, never its shape: height_at, collision and physics never see it.
##
## A window of ground round you, track_cells texels a side, wrapped round on
## itself so it scrolls without redrawing and holds still in world metres
## through origin shifts. Each texel holds the reading of the fill clock at
## which the wind will have filled its mark, so filling costs nothing per
## texel: the sand's shader takes the clock away. Marks press in on the CPU,
## which headless runs keep too, in tiles that exist only while they hold a
## mark; a window uploads only the tiles that change. Tracks beyond the window
## are forgotten, and none are saved.

## Texels a side of a tile: the window scrolls, clears and uploads by tiles.
const TILE := 64
## Tiles sent to the GPU per frame at most; a scroll clears a column of them.
const UPLOADS := 32
## A full mark's depth; marks are fractions of it, and fill at one a clock unit.
const FULL := 1.0
## Ticks between looks for tiles whose every mark has filled, which go.
const SWEEP_TICKS := 240
## Each foot lands this far either side of your middle, and its print runs
## this far heel to toe and across, m.
const FOOT_SPREAD := 0.1
const FOOT_LENGTH := 0.26
const FOOT_WIDTH := 0.1
## How deep a step presses, walking, running and crouched, and a landing.
const STEP_DEPTH := 1.0
const RUN_DEPTH := 1.0
const CROUCH_DEPTH := 0.75
const LANDING_DEPTH := 1.0
## A slide ploughs a groove this wide, m, this deep.
const SLIDE_WIDTH := 0.3
const SLIDE_DEPTH := 0.6
## The board's hover presses a faint groove this deep at its ride height,
## deeper pressed into a dip, none once it's this far over it, m.
const WAKE_DEPTH := 0.25
const WAKE_REACH := 1.0
## Something on the sand: a corner this near it touches, m. Resting, it sits
## in an imprint this deep; dragged, it ploughs one this deep.
const CONTACT := 0.05
const REST_DEPTH := 1.0
const DRAG_DEPTH := 0.75
## Loose bodies are looked at every this many ticks, and one at rest presses
## its imprint again this often, s, so the wind never fills it under it.
const BODY_TICKS := 4
const REST_REFRESH := 3.0
## Main-thread time the bodies may take per look, ms; the rest wait a look.
const BODY_BUDGET_MS := 0.25

## The fill clock: a full mark fills in one unit, sooner in a storm.
var clock := 1.0
## Whether the sand draws them: a look-test turns it off to measure their cost.
var drawn := true
## Main-thread time the last tick and frame took, and the most each has, ms.
var tick_ms := 0.0
var frame_ms := 0.0
var slowest_tick_ms := 0.0
var slowest_frame_ms := 0.0

var _world: World
var _tuning: Tuning
var _material: ShaderMaterial
var _cells: int
var _texel: float
var _tiles: int
## Per tile of the window (row-major, wrapped), while it holds a mark: an
## Image of the fill clock's readings at which its texels are filled, and the
## clock when it was last pressed.
var _held := {}
var _held_at := {}
## What a tile with no marks uploads.
var _blank_tile := PackedByteArray()
## The window's corner, as a world texel, on a whole tile.
var _corner := Vector2i.ZERO
var _placed := false
var _dirty := PackedByteArray()
var _dirty_list := PackedInt32Array()
var _last_time := 0.0
var _phase := 0.0
var _foot := 1.0
var _slid_from := Vector2.INF
var _wake_from := Vector2.INF
var _ticks := 0
## Per loose body: where it last pressed (world xz) and when (world time).
var _pressed := {}
var _rd: RenderingDevice
var _map := RID()
var _staging: Array[RID] = []
var _texture: Texture2DRD


func setup(world: World, material: Material) -> void:
	_world = world
	_tuning = world.tuning
	_cells = _tuning.track_cells
	_texel = _tuning.track_texel
	_tiles = _cells / TILE
	_blank_tile.resize(TILE * TILE * 4)
	_dirty.resize(_tiles * _tiles)
	_material = material as ShaderMaterial
	world.player.landed.connect(_on_landed)
	# After you move and the weather is read, before the origin shifts.
	process_physics_priority = 140
	# Headless has no GPU: marks are still kept, just never drawn.
	_rd = RenderingServer.get_rendering_device()
	if _rd != null and _material != null:
		RenderingServer.call_on_render_thread(_create_map)
		_material.set_shader_parameter("track_extent", _cells * _texel)
		_material.set_shader_parameter("track_texel", _texel)


func _exit_tree() -> void:
	if _texture != null:
		_texture.texture_rd_rid = RID()
	if _map.is_valid():
		var rd := _rd
		var gone: Array[RID] = _staging.duplicate()
		gone.append(_map)
		# Not bound to this node, which is gone by the time it runs on its own thread.
		RenderingServer.call_on_render_thread(func() -> void:
			for rid in gone:
				rd.free_rid(rid))
	_map = RID()
	_staging.clear()


## How deep the mark at a world place is, 0 to 1, filtered as the GPU does.
func depth_at(x: float, z: float) -> float:
	var fx := x / _texel - 0.5
	var fz := z / _texel - 0.5
	var i := floori(fx)
	var j := floori(fz)
	var u := fx - i
	var v := fz - j
	var top := lerpf(_read(i, j), _read(i + 1, j), u)
	var bottom := lerpf(_read(i, j + 1), _read(i + 1, j + 1), u)
	return clampf(lerpf(top, bottom, v) - clock, 0.0, FULL)


## Tiles holding a mark, of the window's track_cells² / TILE².
func held_tiles() -> int:
	return _held.size()


## The deepest mark within `reach` m of a world place.
func deepest_near(x: float, z: float, reach: float) -> float:
	var deepest := 0.0
	var r := ceili(reach / _texel)
	var i0 := floori(x / _texel)
	var j0 := floori(z / _texel)
	for j in range(j0 - r, j0 + r + 1):
		for i in range(i0 - r, i0 + r + 1):
			deepest = maxf(deepest, clampf(_read(i, j) - clock, 0.0, FULL))
	return deepest


## The wind fills every mark by this many seconds' worth of a storm this strong.
func fill(seconds: float, storm: float) -> void:
	var calm := 1.0 / (_tuning.track_calm_minutes * 60.0)
	var stormy := 1.0 / (_tuning.track_storm_minutes * 60.0)
	clock += seconds * lerpf(calm, stormy, clampf(storm, 0.0, 1.0))


## Presses a mark along a world segment, half_width m either side of it,
## `depth` of a full one, soft over a texel at its edge. A mark only ever
## deepens what's there.
func press(from: Vector2, to: Vector2, half_width: float, depth: float) -> void:
	var soft := _texel
	var reach := half_width + 2.0 * soft
	var i0 := floori((minf(from.x, to.x) - reach) / _texel)
	var i1 := floori((maxf(from.x, to.x) + reach) / _texel)
	var j0 := floori((minf(from.y, to.y) - reach) / _texel)
	var j1 := floori((maxf(from.y, to.y) + reach) / _texel)
	var along := to - from
	var length2 := maxf(along.length_squared(), 1e-9)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var at := Vector2((i + 0.5) * _texel, (j + 0.5) * _texel)
			var k := clampf((at - from).dot(along) / length2, 0.0, 1.0)
			var outside := at.distance_to(from + along * k) - half_width
			_deepen(i, j, depth * (1.0 - smoothstep(0.0, soft, outside)))


## Presses a box's footprint: centred at a world place, half sizes along a
## unit axis and across it.
func press_box(middle: Vector2, axis: Vector2, half_along: float, half_across: float, depth: float) -> void:
	var soft := _texel
	var reach := maxf(half_along, half_across) * 1.42 + 2.0 * soft
	var across := Vector2(-axis.y, axis.x)
	for j in range(floori((middle.y - reach) / _texel), floori((middle.y + reach) / _texel) + 1):
		for i in range(floori((middle.x - reach) / _texel), floori((middle.x + reach) / _texel) + 1):
			var at := Vector2((i + 0.5) * _texel, (j + 0.5) * _texel) - middle
			var outside := maxf(absf(at.dot(axis)) - half_along, absf(at.dot(across)) - half_across)
			_deepen(i, j, depth * (1.0 - smoothstep(0.0, soft, outside)))


func _physics_process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	var t := _world.time
	fill(maxf(0.0, t - _last_time), _world.weather.storm)
	_last_time = t
	_follow()
	_walk(delta)
	_wake()
	_ticks += 1
	if _ticks % BODY_TICKS == 0:
		_bodies()
	if _ticks % SWEEP_TICKS == 0:
		_sweep()
	tick_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_tick_ms = maxf(slowest_tick_ms, tick_ms)


func _process(_delta: float) -> void:
	var started := Time.get_ticks_usec()
	if _map.is_valid():
		if _texture == null:
			_texture = Texture2DRD.new()
			_texture.texture_rd_rid = _map
			_material.set_shader_parameter("track_map", _texture)
		_upload()
		var extent := _cells * _texel
		var origin := Vector2(_world.origin_chunk) * _tuning.chunk_size
		_material.set_shader_parameter("track_clock", clock)
		_material.set_shader_parameter("track_shift", Vector2(fposmod(origin.x, extent), fposmod(origin.y, extent)) / extent)
		var middle := (Vector2(_corner) + Vector2.ONE * _cells * 0.5) * _texel - origin
		# A texel short of the edge, where the window wraps onto its far side.
		_material.set_shader_parameter("track_window", Vector3(middle.x, middle.y,
			extent * 0.5 - _texel if drawn else -1.0))
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_frame_ms = maxf(slowest_frame_ms, frame_ms)
	Dev.put("tracks/ms", "%.2f tick %.2f frame" % [slowest_tick_ms, slowest_frame_ms])


## Keeps the window centred on you a tile at a time, clearing what it leaves
## behind; a jump further than it reaches (a respawn) clears it all.
func _follow() -> void:
	var here := Vector2i(floori(_world.player_world_x() / (_texel * TILE)),
		floori(_world.player_world_z() / (_texel * TILE)))
	var corner := (here - Vector2i.ONE * (_tiles / 2)) * TILE
	if _placed and corner == _corner:
		return
	var moved := (corner - _corner) / TILE
	if not _placed or absi(moved.x) >= _tiles or absi(moved.y) >= _tiles:
		_clear_all()
	else:
		var tiles := _corner / TILE
		for step in range(mini(0, moved.x), maxi(0, moved.x)):
			# Leaving east, the west columns go; leaving west, the east ones.
			_clear_column(posmod(tiles.x + step + (0 if moved.x > 0 else _tiles), _tiles))
		for step in range(mini(0, moved.y), maxi(0, moved.y)):
			_clear_row(posmod(tiles.y + step + (0 if moved.y > 0 else _tiles), _tiles))
	_corner = corner
	_placed = true


func _clear_all() -> void:
	_held.clear()
	_held_at.clear()
	_dirty.fill(0)
	_dirty_list.clear()
	_pressed.clear()
	if _map.is_valid():
		RenderingServer.call_on_render_thread(_clear_map)


func _clear_column(tx: int) -> void:
	for ty in _tiles:
		_drop(ty * _tiles + tx)


func _clear_row(ty: int) -> void:
	for tx in _tiles:
		_drop(ty * _tiles + tx)


func _drop(tile: int) -> void:
	if _held.erase(tile):
		_held_at.erase(tile)
		_mark(tile)


## Tiles whose last mark is a full fill old hold nothing any more.
func _sweep() -> void:
	for tile: int in _held_at.keys():
		if _held_at[tile] + FULL < clock:
			_drop(tile)


func _read(i: int, j: int) -> float:
	if i < _corner.x or j < _corner.y or i >= _corner.x + _cells or j >= _corner.y + _cells:
		return 0.0
	var px := posmod(i, _cells)
	var py := posmod(j, _cells)
	var image: Image = _held.get((py / TILE) * _tiles + px / TILE)
	return image.get_pixel(px % TILE, py % TILE).r if image != null else 0.0


func _deepen(i: int, j: int, depth: float) -> void:
	if i < _corner.x or j < _corner.y or i >= _corner.x + _cells or j >= _corner.y + _cells:
		return
	var px := posmod(i, _cells)
	var py := posmod(j, _cells)
	var tile := (py / TILE) * _tiles + px / TILE
	var image: Image = _held.get(tile)
	if image == null:
		image = Image.create_empty(TILE, TILE, false, Image.FORMAT_RF)
		_held[tile] = image
	# Even a mark's soft edge writes the clock as it stands, so the GPU's
	# filtering eases from it into the sand round it instead of a step.
	var filled := clock + depth
	if image.get_pixel(px % TILE, py % TILE).r < filled:
		image.set_pixel(px % TILE, py % TILE, Color(filled, 0.0, 0.0))
		_held_at[tile] = clock
		_mark(tile)


func _mark(tile: int) -> void:
	if _dirty[tile] == 0 and _map.is_valid():
		_dirty[tile] = 1
		_dirty_list.append(tile)


## Footprints on alternate feet, a stride apart as feel's steps are, and a
## slide's groove.
func _walk(delta: float) -> void:
	var player := _world.player
	if player.ride != null or player.flying or not _on_sand(player.global_position):
		_slid_from = Vector2.INF
		return
	var at := _world_xz(player.global_position)
	if player.mode == "slide":
		if _slid_from != Vector2.INF and _slid_from.distance_to(at) > _texel * 0.5:
			press(_slid_from, at, SLIDE_WIDTH * 0.5, SLIDE_DEPTH)
			_slid_from = at
		elif _slid_from == Vector2.INF:
			_slid_from = at
		return
	_slid_from = Vector2.INF
	var speed := player.own.length()
	if (player.mode != "walk" and player.mode != "sprint") or speed < 0.1:
		return
	var before := floori(_phase / PI)
	_phase += speed * delta / Feel.stride(speed) * PI
	if floori(_phase / PI) == before:
		return
	var depth := CROUCH_DEPTH if player.crouched else (RUN_DEPTH if player.mode == "sprint" else STEP_DEPTH)
	_foot = -_foot
	_print_foot(at, player.own / speed, _foot, depth)


func _print_foot(at: Vector2, heading: Vector2, side: float, depth: float) -> void:
	var foot := at + Vector2(-heading.y, heading.x) * FOOT_SPREAD * side
	var half := heading * (FOOT_LENGTH - FOOT_WIDTH) * 0.5
	press(foot - half, foot + half, FOOT_WIDTH * 0.5, depth)


func _on_landed(speed: float) -> void:
	var player := _world.player
	if player.ride != null or speed < Feel.SOFTEST or not _on_sand(player.global_position):
		return
	var heading := -Vector2(player.global_basis.z.x, player.global_basis.z.z).normalized()
	for side in [-1.0, 1.0]:
		_print_foot(_world_xz(player.global_position), heading, side, LANDING_DEPTH)


## The hover presses a faint groove under the board, deeper as it's pressed
## into a dip, and none once it's in the air.
func _wake() -> void:
	var ride := _world.player.ride
	if ride == null:
		_wake_from = Vector2.INF
		return
	var at := _world_xz(ride.board_pose(false).origin)
	var close := clampf(1.0 - ride.gap / WAKE_REACH, 0.0, 1.0)
	if close <= 0.0 or _wake_from == Vector2.INF:
		_wake_from = at
		return
	if _wake_from.distance_to(at) < _texel * 0.5:
		return
	var pressed := 1.0 + clampf(ride.pressing / _world.gravity, 0.0, 1.0) * 0.5
	var half := (Catalog.DEVICES[&"board"].size.x as float) * 0.5
	press(_wake_from, at, half, minf(WAKE_DEPTH * close * pressed, FULL))
	_wake_from = at


## Whatever loose lies on the sand sits in its own imprint, and anything
## dragged over it ploughs a groove the width of what touches.
func _bodies() -> void:
	var player := _world.player
	var t := _world.time
	var seen := {}
	var deadline := Time.get_ticks_usec() + int(BODY_BUDGET_MS * 1000.0)
	for child in _world.content.get_children():
		var body := child as RigidBody3D
		if body == null or body.freeze or (body == player.board and player.ride != null):
			continue
		var id := body.get_instance_id()
		seen[id] = true
		var at := _world_xz(body.global_position)
		var last: Array = _pressed.get(id, [])
		var moved := last.is_empty() or (last[0] as Vector2).distance_to(at) > _texel * 0.5
		if (not moved and t - (last[1] as float) < REST_REFRESH) or Time.get_ticks_usec() > deadline:
			continue
		if _press_body(body, REST_DEPTH if not moved or last.is_empty() else DRAG_DEPTH,
				Vector2.INF if last.is_empty() else last[0], at):
			_pressed[id] = [at, t]
		else:
			_pressed.erase(id)
	for id in _pressed.keys():
		if not seen.has(id):
			_pressed.erase(id)


## Presses each of a body's shapes that touches the sand, swept from where the
## body last pressed so a fast drag leaves no gaps. Says whether any touched.
func _press_body(body: RigidBody3D, depth: float, from: Vector2, to: Vector2) -> bool:
	var touched := false
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null or shape.disabled:
			continue
		if not shape.has_meta(&"sand_box"):
			shape.set_meta(&"sand_box", Catalog.bounds(shape.shape))
		var box: AABB = shape.get_meta(&"sand_box")
		var frame := body.global_transform * shape.transform
		var lowest := INF
		for i in 8:
			var corner := frame * box.get_endpoint(i)
			var under := _world_xz(corner)
			lowest = minf(lowest, corner.y - _world.height_at(under.x, under.y))
		if lowest > CONTACT:
			continue
		touched = true
		# Its footprint: the box seen from above, along its own flattened axes.
		var middle := _world_xz(frame * box.get_center())
		var x := Vector2(frame.basis.x.x, frame.basis.x.z)
		var z := Vector2(frame.basis.z.x, frame.basis.z.z)
		var half_x := box.size.x * 0.5 * x.length()
		var half_z := box.size.z * 0.5 * z.length()
		var axis := x.normalized() if x.length_squared() > 1e-6 else Vector2.RIGHT
		var steps := 1
		var back := Vector2.ZERO
		if from != Vector2.INF:
			back = from - to
			steps = clampi(ceili(back.length() / _texel), 1, 64)
		for s in steps:
			press_box(middle + back * (float(s) / steps), axis, half_x, half_z, depth)
	return touched


func _on_sand(engine_position: Vector3) -> bool:
	var under := _world_xz(engine_position)
	return engine_position.y - _world.height_at(under.x, under.y) < CONTACT * 2.0


func _world_xz(engine_position: Vector3) -> Vector2:
	return Vector2(_world.world_x(engine_position.x), _world.world_z(engine_position.z))


## Ships the touched tiles to the GPU's copy, a frame's worth at a time.
func _upload() -> void:
	var blocks: Array = []
	var taken := 0
	while taken < _dirty_list.size() and blocks.size() < UPLOADS:
		var tile := _dirty_list[taken]
		taken += 1
		_dirty[tile] = 0
		var image: Image = _held.get(tile)
		blocks.append([Vector2i((tile % _tiles) * TILE, (tile / _tiles) * TILE),
			image.get_data() if image != null else _blank_tile])
	if taken == 0:
		return
	_dirty_list = _dirty_list.slice(taken)
	RenderingServer.call_on_render_thread(_send.bind(blocks))


func _create_map() -> void:
	var format := RDTextureFormat.new()
	format.width = _cells
	format.height = _cells
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	_map = _rd.texture_create(format, RDTextureView.new())
	_rd.texture_clear(_map, Color(0.0, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	var tile := RDTextureFormat.new()
	tile.width = TILE
	tile.height = TILE
	tile.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	tile.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	for i in UPLOADS:
		_staging.append(_rd.texture_create(tile, RDTextureView.new()))


func _send(blocks: Array) -> void:
	for i in blocks.size():
		var at: Vector2i = blocks[i][0]
		_rd.texture_update(_staging[i], 0, blocks[i][1])
		_rd.texture_copy(_staging[i], _map, Vector3.ZERO, Vector3(at.x, at.y, 0.0), Vector3(TILE, TILE, 1.0), 0, 0, 0, 0)


func _clear_map() -> void:
	_rd.texture_clear(_map, Color(0.0, 0.0, 0.0, 0.0), 0, 1, 0, 1)

