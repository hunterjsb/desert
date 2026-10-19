class_name Wreckage
extends Node3D
## A wreck's scrapping on the ground, built from its kit piece's plan
## (WreckPlan) beside the wreck its chunk draws: the plates welded over its
## openings, the sand storms packed into its holds, and the hazards riding on
## some of its modules. Its state (each seam's cells cut, each hold's slices
## cleared, each hazard made safe or spent, where each cut plate came to
## rest) is a dictionary the site's memory keeps (Salvage), so it comes back
## as it was while the site is laid, and is forgotten with it.
##
## It stands in the wreck's frame turned but not leaning, at its floor in the
## state its chunk holds it in: what leans with the wreck (its plates, its
## hazards, the holds cleared in from an end) is under its lean, and a hold
## cleared down from the top lies in level layers, as sand settles.

const CUT := &"cut"
const CLEAR := &"clear"
const GROUND := &"ground"
const SEAL := &"seal"
const ELECTRICAL := &"electrical"
const BIO := &"bio"
## A hazard's state.
const LIVE := 0
const SAFE := 1
const SPENT := 2
## The cutter's hot spot finds the seam this near it, m, and cuts what of it
## lies this far either side.
const SNAP := 0.18
const KERF := 0.11
## A cell just cut glows, cooling by this much a second.
const COOL := 0.4
## A seam's cell no higher than this over the sand is under it, m; a plate's
## cells are each asked only once its foot comes this near the sand.
const UNDER_SAND := 0.03
const NEAR_SAND := 0.4
## A hazard's box, m.
const HAZARD_BOX := Vector3(0.5, 0.6, 0.4)
## A plate cut free falls, and once it's been still this long, s (or after
## this long at most), it lies where it fell.
const SETTLE := 0.5
const SETTLE_MOST := 6.0
## Rust-brown, apart from any hull's paint, so a plate reads as the thing to
## cut; its welds a dull bead round its edge.
const PLATE := Color(0.5, 0.3, 0.19)
const BEAD := Color(0.42, 0.39, 0.34)
const SAND := Color(0.72, 0.57, 0.39)
## A light alloy's density, kg/m³, for a fallen plate's mass; a plate falls
## this much smaller than the opening it was welded over, so it comes free.
const ALLOY := 2800.0
const FALLING := 0.94
## Why something won't come or go, said as it's tried.
const BEHIND := "behind the %s · cut it away"
const PACKED := "packed in sand · clear the %s"
const FIRST := "clear the sand in front of it first"
const FIRST_TOP := "clear the sand on top of it first"

static var _bead_mesh: BoxMesh
## Each plate's look, standing and fallen, made once.
static var _plate_meshes := {}
static var _bead_look: ShaderMaterial

var site: Structure
var plan: WreckPlan
## {"cut": [PackedFloat32Array per plate], "cleared": PackedFloat32Array per
## hold, "hazards": {socket: SAFE or SPENT}, "fallen": {plate: Transform3D}}.
var state: Dictionary

## The world's one ground function, world metres.
var _height: Callable
var _lean: Node3D
var _plates := {}
var _beads := {}
var _buried := {}
var _heat := {}
var _slices := {}
var _hazards := {}
var _falling: Array[Array] = []
## What's left to build, a piece at a time.
var _steps: Array = []
var _blink := 0.0
var _cooling := false


func _init(at: Structure, kept: Dictionary, height: Callable) -> void:
	site = at
	plan = at.piece.wreck
	state = kept
	_height = height
	if state.is_empty():
		state.merge(fresh(plan))
	name = "Wreckage"


## Makes every wreck's plates' looks, its hazards' and its materials while
## the world loads, so no wreck pays for them inside the streaming budget.
static func prepare() -> void:
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		if piece.wreck == null:
			continue
		for p in piece.wreck.plates:
			_plate_mesh(p)
			_plate_mesh(p, true)
	_bank_mesh()
	_store_mesh()
	_bead()
	_bead_material()
	_unit_box()
	_sand_material()
	ScrapFx.prepare()


## A wreck as found: nothing cut or cleared, every hazard live.
static func fresh(of: WreckPlan) -> Dictionary:
	var cut := []
	for p in of.plates:
		var cells := PackedFloat32Array()
		cells.resize(p.cells.size())
		cut.append(cells)
	var cleared := PackedFloat32Array()
	cleared.resize(of.holds.size())
	return {"cut": cut, "cleared": cleared, "hazards": {}, "fallen": {}}


## Builds what's left of it all at once: the plates still on and those cut
## away lying where they fell, the sand still packed in its holds, its hazards.
func build() -> void:
	while not build_step():
		pass


## Builds the next piece of it, a plate, a hold or a hazard, so the streaming
## budget can spread it over frames; true once it's all built.
func build_step() -> bool:
	if _lean == null:
		_lean = Node3D.new()
		_lean.name = "Lean"
		_lean.transform = site.lean_frame()
		add_child(_lean)
		_steps = []
		for i in plan.plates.size():
			_steps.append([&"plate", i])
		for h in plan.holds.size():
			_steps.append([&"hold", h])
		for socket: int in plan.modules:
			if (plan.modules[socket] as WreckPlan.Module).hazard != &"":
				_steps.append([&"hazard", socket])
	if _steps.is_empty():
		return true
	var step: Array = _steps.pop_front()
	match step[0]:
		&"plate":
			if state.fallen.has(step[1]):
				_lying(step[1])
			elif not done(step[1]):
				_standing(step[1])
		&"hold":
			_pack(step[1])
		&"hazard":
			_hazard(step[1])
	return _steps.is_empty()


## Whether all of it is built.
func built() -> bool:
	return _lean != null and _steps.is_empty()


# --- What it asks. ---

## Whether a plate is cut away.
func done(i: int) -> bool:
	return state.fallen.has(i) or not _plates.has(i) and _cut_through(i)


## How far a plate's seams are cut, 0 to 1.
func progress(i: int) -> float:
	var cells: PackedFloat32Array = state.cut[i]
	if cells.is_empty():
		return 1.0
	var sum := 0.0
	for c in cells:
		sum += c
	return sum / cells.size()


## How many of a hold's slices are cleared, from its open end.
func cleared(h: int) -> int:
	return floori(state.cleared[h] + 1e-6)


## Why a module won't come, or "" once what was in its way is gone.
func held_fast(socket: int) -> String:
	var m: WreckPlan.Module = plan.modules.get(socket)
	if m == null:
		return ""
	for need: Array in m.needs:
		if need[0] == &"plate" and not done(need[1]):
			return BEHIND % plan.plates[need[1]].label
		if need[0] == &"hold" and cleared(need[1]) < mini(need[2], plan.holds[need[1]].slices):
			return PACKED % plan.holds[need[1]].label
	return ""


## The hazard still live on a module, or &"".
func hazard(socket: int) -> StringName:
	var m: WreckPlan.Module = plan.modules.get(socket)
	if m == null or m.hazard == &"" or state.hazards.get(socket, LIVE) != LIVE:
		return &""
	return m.hazard


## The work a piece of it takes: [op, index...], or [] for none of its.
static func work_of(body: Object) -> Array:
	return body.get_meta(&"work") if body != null and body.has_meta(&"work") else []


## The work a tool in your hands does on a wreck, or &"".
static func tool_op(body: Object) -> StringName:
	if body is Cutter:
		return CUT
	if body is Stake:
		return GROUND
	if body is Part and body.has_meta(&"catalog"):
		return Catalog.PARTS.get(body.get_meta(&"catalog"), {}).get("tool", &"")
	return &""


## Seconds a slice of a hold takes a scoop to clear.
func slice_seconds(h: int, k: int) -> float:
	var box := _slice_box(h, k)
	return maxf(box.size.x * box.size.y * box.size.z, 0.05) * Tuning.current().clear_seconds_per_m3


## Seconds a cell of seam takes the cutter.
func cell_seconds() -> float:
	return Tuning.current().cut_seconds_per_m * WreckPlan.CELL * plan.armour


# --- The work. ---

## The cutter's hot spot on a plate at `point` (the engine's frame) for
## `seconds`: it finds the nearest seam and cuts what of it lies under the
## kerf. Returns {seam: whether one was in reach, at: where the hot spot sits
## on it, buried: if the sand holds that bit, through: if it came away}.
func cut(body: Object, point: Vector3, seconds: float) -> Dictionary:
	var what := work_of(body)
	if what.is_empty() or what[0] != CUT or not _plates.has(what[1]):
		return {"seam": false}
	var i: int = what[1]
	var p: WreckPlan.Plate = plan.plates[i]
	var local := _lean.global_transform.affine_inverse() * point
	var best := -1
	var near := INF
	for c in p.cells.size():
		var d := (p.cells[c] - local).length()
		if d < near:
			near = d
			best = c
	if best < 0 or near > SNAP:
		return {"seam": false}
	var at := _lean.global_transform * (p.cells[best] + p.normal() * 0.02)
	var buried: PackedByteArray = _buried[i]
	if buried[best] != 0:
		return {"seam": true, "at": at, "buried": true}
	var cells: PackedFloat32Array = state.cut[i]
	var heat: PackedFloat32Array = _heat[i]
	var per := cell_seconds()
	var bead: MultiMesh = _beads[i]
	for c in p.cells.size():
		if buried[c] != 0 or (p.cells[c] - p.cells[best]).length() > KERF:
			continue
		var was := cells[c]
		cells[c] = minf(cells[c] + seconds / per * (1.0 if c == best else 0.55), 1.0)
		heat[c] = 1.0
		if was < 1.0 and cells[c] >= 1.0:
			bead.set_instance_transform(c, _bead_at(p, c, true))
		bead.set_instance_custom_data(c, Color(heat[c], cells[c], 0.0, 0.0))
	state.cut[i] = cells
	state.touched = true
	_cooling = true
	if _cut_through(i):
		_fall(i)
		return {"seam": true, "at": at, "through": true}
	return {"seam": true, "at": at}


## A scoop at a hold's open slice for `seconds`. Says whether it cleared any.
func clear(body: Object, seconds: float) -> bool:
	var what := work_of(body)
	if what.is_empty() or what[0] != CLEAR:
		return false
	var h: int = what[1]
	var k: int = what[2]
	var hold: WreckPlan.Hold = plan.holds[h]
	if k != cleared(h) or k >= hold.slices:
		return false
	state.cleared[h] = minf(state.cleared[h] + seconds / slice_seconds(h, k), float(hold.slices))
	state.touched = true
	var now := cleared(h)
	var standing: Array = _slices[h]
	for gone in range(k, mini(now, hold.slices)):
		if standing[gone] != null:
			_gone(standing[gone])
			standing[gone] = null
	_shape_slice(h)
	return true


## Why a scoop on a slice behind the open one does nothing, or "".
func not_yet(body: Object) -> String:
	var what := work_of(body)
	if what.is_empty() or what[0] != CLEAR or what[2] == cleared(what[1]):
		return ""
	return FIRST_TOP if (plan.holds[what[1]] as WreckPlan.Hold).from == WreckPlan.TOP else FIRST


## Makes a hazard safe with what does it: a stake grounding a capacitor bank,
## sealant on a breached store. Says whether it did.
func make_safe(body: Object, op: StringName) -> bool:
	var what := work_of(body)
	if what.is_empty() or what[0] != op or not op in [GROUND, SEAL]:
		return false
	var socket: int = what[1]
	if hazard(socket) == &"":
		return false
	state.hazards[socket] = SAFE
	state.touched = true
	_quiet(socket)
	return true


## A live hazard has gone off on someone: it can't again.
func spend(socket: int) -> void:
	if hazard(socket) != &"":
		state.hazards[socket] = SPENT
		state.touched = true
		_quiet(socket)


## The hazard's body on a module, or null.
func hazard_body(socket: int) -> StaticBody3D:
	return _hazards.get(socket, [null])[0]


func plate_body(i: int) -> StaticBody3D:
	return _plates.get(i)


## A hold's slice still standing, or null.
func slice_body(h: int, k: int) -> StaticBody3D:
	var standing: Array = _slices.get(h, [])
	return standing[k] if k < standing.size() else null


## The middle of a plate's seam cell, the engine's frame, and the way out of
## its face: for probes and the look-test, which trace them.
func cell_point(i: int, c: int) -> Vector3:
	var p: WreckPlan.Plate = plan.plates[i]
	return _lean.global_transform * (p.cells[c] + p.normal() * 0.02)


func plate_normal(i: int) -> Vector3:
	return (_lean.global_basis * plan.plates[i].normal()).normalized()


## Whether a plate's seam cell is under the sand.
func cell_buried(i: int, c: int) -> bool:
	return (_buried[i] as PackedByteArray)[c] != 0


## What the readout says of a piece of it you look at.
func describe(body: Object) -> String:
	var key := Controls.key_for(&"interact")
	if body != null and body.has_meta(&"fallen_plate"):
		return "%s · cut away" % plan.plates[body.get_meta(&"fallen_plate")].label
	if body != null and body.has_meta(&"hazard_done"):
		var done: Array = body.get_meta(&"hazard_done")
		var electrical: bool = plan.modules[done[0]].hazard == ELECTRICAL
		if done[1] == SAFE:
			return "capacitor bank · grounded, dead" if electrical else "breached store · sealed"
		return "capacitor bank · discharged" if electrical else "breached store · spent"
	var what := work_of(body)
	if what.is_empty():
		return ""
	match what[0]:
		CUT:
			var i: int = what[1]
			var p: WreckPlan.Plate = plan.plates[i]
			var under := (_buried[i] as PackedByteArray).has(1)
			var cut := progress(i)
			var how := "welded on" if cut <= 0.0 else "seams %d%% cut" % floori(cut * 100.0)
			if under:
				return "%s · %s · a seam's under the sand: a storm may strip it" % [p.label, how]
			return "%s · %s · hold %s with a heat cutter along its seams" % [p.label, how, key]
		CLEAR:
			var hold: WreckPlan.Hold = plan.holds[what[1]]
			var done := cleared(what[1])
			var left := floori((state.cleared[what[1]] - done) * 100.0)
			return "packed sand · %s, %s · slice %d of %d%s · hold %s with a sand scoop" % [hold.label, hold.how,
				done + 1, hold.slices, " · %d%% cleared" % left if left > 0 else "", key]
		GROUND:
			return "live capacitor bank · crackling · %s with a stake to ground it" % key
		SEAL:
			return "breached store · leaking · %s with sealant to seal it" % key
	return ""


## Where a plate is, as a cutter or scoop on the hull itself would hear it.
func nearest_work(op: StringName, from: Vector3) -> String:
	var best := ""
	var near := INF
	if op == CUT:
		for i: int in _plates:
			var d := from.distance_to(_lean.global_transform * plan.plates[i].face())
			if d < near:
				near = d
				best = "not the hull: trace the seams of the rust-brown %s" % plan.plates[i].label
	elif op == CLEAR:
		for h: int in _slices:
			if slice_body(h, cleared(h)) != null:
				var d := from.distance_to(slice_body(h, cleared(h)).global_position)
				if d < near:
					near = d
					best = "not the hull: scoop the sand packed in the %s" % plan.holds[h].label
	return best


# --- Building it. ---

func _standing(i: int) -> void:
	var p: WreckPlan.Plate = plan.plates[i]
	var body := StaticBody3D.new()
	body.name = "Plate%d" % i
	_shape(body, p.box.get_center(), p.box.size)
	var look := MeshInstance3D.new()
	look.mesh = _plate_mesh(p)
	body.add_child(look)
	Paint.show_age(body, 0.85)
	body.set_meta(&"work", [CUT, i])
	body.set_meta(&"wreckage", self)
	_lean.add_child(body)
	_plates[i] = body
	# Its welds, each cell a bead, cut cells a dark kerf.
	var beads := MultiMesh.new()
	beads.transform_format = MultiMesh.TRANSFORM_3D
	beads.use_custom_data = true
	beads.mesh = _bead()
	beads.instance_count = p.cells.size()
	var cells: PackedFloat32Array = state.cut[i]
	var heat := PackedFloat32Array()
	heat.resize(p.cells.size())
	var buried := PackedByteArray()
	buried.resize(p.cells.size())
	# Each cell's sand is asked only of a plate whose foot comes near the
	# sand round it: most stand well clear.
	var frame := site.frame()
	var near := _near_sand(p, frame)
	for c in p.cells.size():
		beads.set_instance_transform(c, _bead_at(p, c, cells[c] >= 1.0))
		beads.set_instance_custom_data(c, Color(0.0, cells[c], 0.0, 0.0))
		if near:
			var w := frame * p.cells[c]
			buried[c] = 1 if w.y < float(_height.call(w.x, w.z)) + UNDER_SAND else 0
	var view := MultiMeshInstance3D.new()
	view.multimesh = beads
	view.material_override = _bead_material()
	body.add_child(view)
	_beads[i] = beads
	_heat[i] = heat
	_buried[i] = buried


## Whether a plate's foot comes within reach of the sand round it: its outer
## face's lowest corner against the highest sand at its corners and middle.
func _near_sand(p: WreckPlan.Plate, frame: Transform3D) -> bool:
	var axes := [(p.thin + 1) % 3, (p.thin + 2) % 3]
	var low := INF
	var sand := -INF
	var spots: Array[Vector3] = [p.face()]
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			var at := p.face()
			at[axes[0]] += su * p.box.size[axes[0]] * 0.5
			at[axes[1]] += sv * p.box.size[axes[1]] * 0.5
			spots.append(at)
	for at in spots:
		var w := frame * at
		low = minf(low, w.y)
		sand = maxf(sand, float(_height.call(w.x, w.z)))
	return low < sand + NEAR_SAND


## A plate cut away, lying where it fell.
func _lying(i: int) -> void:
	var p: WreckPlan.Plate = plan.plates[i]
	var body := StaticBody3D.new()
	body.name = "Fallen%d" % i
	_shape(body, Vector3.ZERO, p.box.size)
	var look := MeshInstance3D.new()
	look.mesh = _plate_mesh(p, true)
	body.add_child(look)
	Paint.show_age(body, 0.85)
	body.set_meta(&"fallen_plate", i)
	body.set_meta(&"wreckage", self)
	body.transform = state.fallen[i]
	add_child(body)


## Cut through: it comes away and falls outward off the hull, its welds
## still glowing.
func _fall(i: int) -> void:
	var standing: StaticBody3D = _plates[i]
	_plates.erase(i)
	var p: WreckPlan.Plate = plan.plates[i]
	var body := RigidBody3D.new()
	body.name = "Falling%d" % i
	# A little smaller than its opening, so it comes out of it free.
	var size := p.box.size * FALLING
	size[p.thin] = p.box.size[p.thin]
	_shape(body, Vector3.ZERO, size)
	var look := MeshInstance3D.new()
	look.mesh = _plate_mesh(p, true)
	body.add_child(look)
	Paint.show_age(body, 0.85)
	look.set_instance_shader_parameter(&"lit", 0.6)
	var area := p.area()
	body.mass = clampf(area * p.box.size[p.thin] * ALLOY * 0.25, 8.0, 80.0)
	body.set_meta(&"fallen_plate", i)
	body.set_meta(&"wreckage", self)
	add_child(body)
	var out := plate_normal(i)
	body.global_transform = standing.global_transform.translated_local(p.box.get_center()).translated(
		out * (p.box.size[p.thin] + 0.04))
	body.linear_velocity = out * 1.4 + Vector3.UP * 0.4
	body.angular_velocity = out.cross(Vector3.UP).normalized() * -1.2 if absf(out.y) < 0.9 else Vector3.ZERO
	_gone(standing)
	_falling.append([i, body, 0.0, 0.0, 0.0])
	Sounds.play_at(body, Sounds.PLATE_FREE, -4.0, 3.0)


## A hold's slices still standing, the first worn down as far as it's cleared.
func _pack(h: int) -> void:
	var hold: WreckPlan.Hold = plan.holds[h]
	var standing: Array = []
	var first := cleared(h)
	for k in hold.slices:
		if k < first:
			standing.append(null)
			continue
		var box := _slice_box(h, k)
		if box.size.y <= 0.02:
			standing.append(null)
			continue
		var body := StaticBody3D.new()
		body.name = "Sand%d_%d" % [h, k]
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		body.add_child(shape)
		var look := MeshInstance3D.new()
		look.mesh = _unit_box()
		look.material_override = _sand_material()
		body.add_child(look)
		body.set_meta(&"work", [CLEAR, h, k])
		body.set_meta(&"wreckage", self)
		body.set_meta(&"box", box)
		(self if hold.from == WreckPlan.TOP else _lean).add_child(body)
		standing.append(body)
	_slices[h] = standing
	for k in hold.slices:
		if standing[k] != null:
			_fit(standing[k], standing[k].get_meta(&"box"))
	_shape_slice(h)


## The first slice standing, worn back from the open end as far as it's cleared.
func _shape_slice(h: int) -> void:
	var k := cleared(h)
	var body := slice_body(h, k)
	if body == null:
		return
	var hold: WreckPlan.Hold = plan.holds[h]
	var box: AABB = body.get_meta(&"box")
	var left := maxf(1.0 - (state.cleared[h] - k), 0.04)
	var axis := 1 if hold.from == WreckPlan.TOP else _axis(hold.from)
	var toward := 1.0 if hold.from == WreckPlan.TOP else hold.from[axis]
	var size := box.size
	size[axis] *= left
	var at := box.get_center()
	# The far side stays where it was; the open side comes back toward it.
	at[axis] -= toward * box.size[axis] * (1.0 - left) * 0.5
	_fit(body, AABB(at - size * 0.5, size))


## A slice's box: in from the open end, an even share of the hold along its
## axis; down from the top, a level layer of what of the hold lies over the
## sand, as wide as the hold is at its middle height.
func _slice_box(h: int, k: int) -> AABB:
	var hold: WreckPlan.Hold = plan.holds[h]
	if hold.from != WreckPlan.TOP:
		var axis := _axis(hold.from)
		var each := hold.box.size[axis] / hold.slices
		var lo := hold.box.position
		var size := hold.box.size
		size[axis] = each
		# Slice 0 at the open end.
		lo[axis] = hold.box.end[axis] - each * (k + 1) if hold.from[axis] > 0.0 else hold.box.position[axis] + each * k
		return AABB(lo, size)
	var lean := site.lean_frame()
	var corners: Array[Vector3] = []
	var top := -INF
	var bottom := INF
	for c in 8:
		var at := lean * hold.box.get_endpoint(c)
		corners.append(at)
		top = maxf(top, at.y)
		bottom = minf(bottom, at.y)
	# The sand under the hold's middle, in this frame: what's under it is the dunes'.
	var middle := site.frame() * hold.box.get_center()
	var sand := float(_height.call(middle.x, middle.z)) - site.origin().y
	bottom = maxf(bottom, sand)
	var each := (top - bottom) / hold.slices
	if each <= 0.0:
		return AABB(Vector3.ZERO, Vector3.ZERO)
	var y0 := top - each * (k + 1)
	var y1 := top - each * k
	var mid := (y0 + y1) * 0.5
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for a in 8:
		for b in range(a + 1, 8):
			# Only the box's edges: corners differing along one axis.
			if bitcount(a ^ b) != 1:
				continue
			var p: Vector3 = corners[a]
			var q: Vector3 = corners[b]
			if (p.y - mid) * (q.y - mid) > 0.0 or is_equal_approx(p.y, q.y):
				continue
			var at := p.lerp(q, (mid - p.y) / (q.y - p.y))
			lo = Vector2(minf(lo.x, at.x), minf(lo.y, at.z))
			hi = Vector2(maxf(hi.x, at.x), maxf(hi.y, at.z))
	if not lo.is_finite():
		return AABB(Vector3.ZERO, Vector3.ZERO)
	# Inset off the walls, as packed sand meets them.
	lo += Vector2.ONE * 0.03
	hi -= Vector2.ONE * 0.03
	return AABB(Vector3(lo.x, y0, lo.y), Vector3(maxf(hi.x - lo.x, 0.0), each, maxf(hi.y - lo.y, 0.0)))


static func bitcount(n: int) -> int:
	var count := 0
	while n != 0:
		count += n & 1
		n >>= 1
	return count


func _hazard(socket: int) -> void:
	var m: WreckPlan.Module = plan.modules[socket]
	var live: bool = state.hazards.get(socket, LIVE) == LIVE
	var electrical := m.hazard == ELECTRICAL
	var body := StaticBody3D.new()
	body.name = "Hazard%d" % socket
	_shape(body, Vector3.ZERO, HAZARD_BOX)
	var look := MeshInstance3D.new()
	look.mesh = _bank_mesh() if electrical else _store_mesh()
	body.add_child(look)
	Paint.show_age(body, 0.75)
	var lamp := MeshInstance3D.new()
	var lamp_pieces := Paint.Pieces.new()
	if electrical:
		lamp_pieces.box(Vector3(0.07, 0.07, 0.03), Vector3(0.15, 0.2, HAZARD_BOX.z * 0.5 + 0.01),
			Paint.coat(Color(0.9, 0.12, 0.06), 0.0, 0.0, 0.3, 0.0, 4.0), 0.005)
	else:
		# The seep: a stain down its front, and, sealed, a patch over the breach.
		lamp_pieces.box(Vector3(0.16, 0.3, 0.02), Vector3(-0.05, -0.05, HAZARD_BOX.z * 0.5 + 0.005),
			Paint.coat(Color(0.42, 0.45, 0.2), 0.0, 0.0, 0.2, 0.0, 0.6), 0.004)
	lamp.mesh = lamp_pieces.commit()
	body.add_child(lamp)
	body.position = m.at
	body.set_meta(&"wreckage", self)
	_lean.add_child(body)
	var voice: AudioStreamPlayer3D = null
	var mist: CPUParticles3D = null
	if live:
		body.set_meta(&"work", [GROUND if electrical else SEAL, socket])
		voice = Sounds.world_voice(Sounds.looping(Sounds.ARC_LOOP if electrical else Sounds.HISS_LOOP), -4.0, 1.2)
		voice.autoplay = true
		body.add_child(voice)
		if not electrical:
			mist = ScrapFx.mist()
			mist.position = Vector3(-0.05, 0.1, HAZARD_BOX.z * 0.5 + 0.05)
			body.add_child(mist)
	else:
		body.set_meta(&"hazard_done", [socket, state.hazards[socket]])
		if not electrical:
			_patch(body)
	_hazards[socket] = [body, lamp, voice, mist]


## A hazard dealt with, either way: it goes quiet and dark.
func _quiet(socket: int) -> void:
	var made: Array = _hazards.get(socket, [])
	if made.is_empty():
		return
	var body: StaticBody3D = made[0]
	body.remove_meta(&"work")
	body.set_meta(&"hazard_done", [socket, state.hazards[socket]])
	(made[1] as MeshInstance3D).set_instance_shader_parameter(&"lit", 0.0)
	if made[2] != null:
		(made[2] as Node).queue_free()
		made[2] = null
	if made[3] != null:
		(made[3] as CPUParticles3D).emitting = false
	if plan.modules[socket].hazard == BIO and state.hazards[socket] == SAFE:
		_patch(body)


## Sealant over a breached store's crack.
func _patch(body: StaticBody3D) -> void:
	var pieces := Paint.Pieces.new()
	pieces.ball(0.12, Vector3(-0.05, 0.08, HAZARD_BOX.z * 0.5 + 0.01), Paint.coat(Color(0.86, 0.8, 0.58), 0.0, 0.0, 0.5),
		Vector3(1.1, 0.8, 0.35))
	var look := MeshInstance3D.new()
	look.mesh = pieces.commit()
	body.add_child(look)


func _physics_process(delta: float) -> void:
	_settle(delta)
	_cool(delta)
	_blink = fposmod(_blink + delta, 1.2)
	for socket: int in _hazards:
		var made: Array = _hazards[socket]
		if made[2] != null and plan.modules[socket].hazard == ELECTRICAL:
			(made[1] as MeshInstance3D).set_instance_shader_parameter(&"lit", 1.0 if _blink < 0.25 else 0.08)


## A plate falling comes to rest, and then lies there for good.
func _settle(delta: float) -> void:
	for n in range(_falling.size() - 1, -1, -1):
		var each: Array = _falling[n]
		var body: RigidBody3D = each[1]
		if not is_instance_valid(body):
			_falling.remove_at(n)
			continue
		each[2] += delta
		var speed := body.linear_velocity.length()
		# It rings as it lands.
		if each[4] > 1.2 and speed < each[4] * 0.5:
			Sounds.play_at(body, Sounds.PLATE_LAND, -6.0, 3.0)
		each[4] = speed
		each[3] = each[3] + delta if speed < 0.08 and body.angular_velocity.length() < 0.3 else 0.0
		var look := body.get_child(1) as MeshInstance3D
		if look != null:
			look.set_instance_shader_parameter(&"lit", maxf(0.6 - each[2] * 0.15, 0.0))
		if each[3] >= SETTLE or each[2] >= SETTLE_MOST:
			body.freeze = true
			state.fallen[each[0]] = transform.affine_inverse() * (get_parent() as Node3D).global_transform.affine_inverse() \
				* body.global_transform if get_parent() is Node3D else body.transform
			_falling.remove_at(n)


## Fresh kerfs cool from white-hot to a dark slot.
func _cool(delta: float) -> void:
	if not _cooling:
		return
	_cooling = false
	for i: int in _heat:
		if not _plates.has(i):
			continue
		var heat: PackedFloat32Array = _heat[i]
		var cells: PackedFloat32Array = state.cut[i]
		var bead: MultiMesh = _beads[i]
		var warm := 0.0
		for c in heat.size():
			if heat[c] <= 0.0:
				continue
			heat[c] = maxf(heat[c] - COOL * delta, 0.0)
			bead.set_instance_custom_data(c, Color(heat[c], cells[c], 0.0, 0.0))
			warm = maxf(warm, heat[c])
			_cooling = true
		_heat[i] = heat
		# The plate itself warms round where it's cut.
		var view := (_plates[i] as StaticBody3D).get_child(1) as MeshInstance3D
		view.set_instance_shader_parameter(&"lit", warm * 0.35 + progress(i) * 0.25)


func _exit_tree() -> void:
	# A plate still falling as its ground goes lies where it got to.
	for each in _falling:
		var body: RigidBody3D = each[1]
		if is_instance_valid(body):
			state.fallen[each[0]] = body.transform
	_falling.clear()


func _cut_through(i: int) -> bool:
	var cells: PackedFloat32Array = state.cut[i]
	for c in cells:
		if c < 1.0:
			return false
	return true


static func _axis(way: Vector3) -> int:
	var a := way.abs()
	return 0 if a.x >= a.y and a.x >= a.z else (1 if a.y >= a.z else 2)


static func _gone(body: Node3D) -> void:
	if body is CollisionObject3D:
		(body as CollisionObject3D).collision_layer = 0
	body.visible = false
	body.queue_free()


## A slice's body fitted to a box in its frame.
static func _fit(body: StaticBody3D, box: AABB) -> void:
	var shape := body.get_child(0) as CollisionShape3D
	(shape.shape as BoxShape3D).size = box.size.max(Vector3.ONE * 0.01)
	shape.position = box.get_center()
	var look := body.get_child(1) as MeshInstance3D
	look.transform = Transform3D(Basis.from_scale(box.size.max(Vector3.ONE * 0.01)), box.get_center())


static func _shape(body: CollisionObject3D, middle: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = middle
	body.add_child(shape)


## A bead of weld on a cell, along its seam; cut, a thin dark kerf sunk in.
func _bead_at(p: WreckPlan.Plate, c: int, through: bool) -> Transform3D:
	var run := p.runs[c]
	var n := p.normal()
	var up := n.cross(run).normalized()
	var turn := Basis(run, up, n)
	if through:
		turn = turn * Basis.from_scale(Vector3(1.0, 0.55, 0.4))
	return Transform3D(turn, p.cells[c] + n * (0.0 if through else 0.012))


static var _box: BoxMesh
static var _sand: ShaderMaterial


static func _unit_box() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
	return _box


## Packed sand, its storms' layers in it.
static func _sand_material() -> ShaderMaterial:
	if _sand == null:
		_sand = ShaderMaterial.new()
		_sand.shader = preload("res://game/salvage/packed_sand.gdshader")
		_sand.set_shader_parameter(&"sand", SAND)
	return _sand


static func _bead() -> BoxMesh:
	if _bead_mesh == null:
		_bead_mesh = BoxMesh.new()
		_bead_mesh.size = Vector3(WreckPlan.CELL * 0.98, 0.05, 0.03)
	return _bead_mesh


static func _bead_material() -> ShaderMaterial:
	if _bead_look == null:
		_bead_look = ShaderMaterial.new()
		_bead_look.shader = preload("res://game/salvage/weld.gdshader")
	return _bead_look


## A plate: one sheet of rust-brown alloy, a stencilled band to cut along
## inside its welds, and its rivets; fallen, centred on itself.
static func _plate_mesh(p: WreckPlan.Plate, centred := false) -> ArrayMesh:
	var key := [p, centred]
	if not _plate_meshes.has(key):
		_plate_meshes[key] = _made_plate(p, centred)
	return _plate_meshes[key]


static func _made_plate(p: WreckPlan.Plate, centred: bool) -> ArrayMesh:
	var pieces := Paint.Pieces.new()
	var middle := Vector3.ZERO if centred else p.box.get_center()
	var coat := Paint.coat(PLATE, 1.0, 0.55, 0.62, 1.0, 1.4)
	pieces.box(p.box.size, middle, coat, 0.01)
	var n := p.normal()
	var axes := [(p.thin + 1) % 3, (p.thin + 2) % 3]
	var face := middle + n * (p.box.size[p.thin] * 0.5 + 0.004)
	var rivet := Paint.coat(Paint.STEEL, 0.6, 0.8, 0.4)
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			var at := face
			at[axes[0]] += su * (p.box.size[axes[0]] * 0.5 - 0.16)
			at[axes[1]] += sv * (p.box.size[axes[1]] * 0.5 - 0.16)
			var rivet_size := Vector3.ONE * 0.05
			rivet_size[p.thin] = 0.02
			pieces.box(rivet_size, at, rivet, 0.005)
	# Hazard tape across its middle, level: what's behind was sealed on purpose.
	var across: int = axes[0] if axes[0] != 1 else axes[1]
	var tape := Vector3.ONE * 0.1
	tape[p.thin] = 0.006
	tape[across] = p.box.size[across] * 0.7
	pieces.box(tape, face, Paint.coat(Paint.YELLOW, 1.0, 0.2, 0.6), 0.0)
	for k in 5:
		var stripe := Vector3.ONE * 0.06
		stripe[p.thin] = 0.008
		stripe[across] = 0.05
		var at := face
		at[across] += (k - 2) * p.box.size[across] * 0.13
		pieces.box(stripe, at, Paint.coat(Paint.BLACK, 1.0, 0.2, 0.6), 0.0)
	return pieces.commit()


static var _bank: ArrayMesh
static var _store: ArrayMesh


## A capacitor bank: a squat yellow box, black bands, two terminal posts.
static func _bank_mesh() -> ArrayMesh:
	if _bank == null:
		var b := Paint.Pieces.new()
		var half := HAZARD_BOX * 0.5
		b.box(HAZARD_BOX, Vector3.ZERO, Paint.coat(Paint.YELLOW, 1.0, 0.3, 0.55), 0.02)
		for k in 3:
			b.box(Vector3(HAZARD_BOX.x + 0.01, 0.05, HAZARD_BOX.z + 0.01), Vector3(0.0, -0.18 + k * 0.12, 0.0),
				Paint.coat(Paint.BLACK, 1.0, 0.3, 0.6), 0.0)
		for side in [-1.0, 1.0]:
			b.drum(0.035, 0.12, Vector3(side * 0.12, half.y + 0.06, 0.0), Paint.coat(Paint.STEEL, 0.6, 0.9, 0.3))
			b.drum(0.05, 0.03, Vector3(side * 0.12, half.y + 0.12, 0.0), Paint.coat(Color(0.7, 0.4, 0.2), 0.6, 0.9, 0.3))
		_bank = b.commit()
	return _bank


## A breached store: a sealed drum of clinic or ration stock, cracked.
static func _store_mesh() -> ArrayMesh:
	if _store == null:
		var b := Paint.Pieces.new()
		b.drum(HAZARD_BOX.x * 0.45, HAZARD_BOX.y, Vector3.ZERO, Paint.coat(Color(0.82, 0.8, 0.74), 1.0, 0.1, 0.5), Basis.IDENTITY, 14)
		for y in [-0.22, 0.22]:
			b.drum(HAZARD_BOX.x * 0.46, 0.04, Vector3(0.0, y, 0.0), Paint.coat(Color(0.55, 0.12, 0.08), 1.0, 0.2, 0.5),
				Basis.IDENTITY, 14)
		b.box(Vector3(0.03, 0.22, 0.02), Vector3(-0.05, 0.05, HAZARD_BOX.x * 0.45), Paint.coat(Paint.BLACK, 0.0, 0.0, 0.9), 0.0,
			Basis(Vector3.BACK, 0.3))
		_store = b.commit()
	return _store
