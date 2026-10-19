class_name Faces
extends RefCounted
## Wind on a deck's whole faces: each wall, shelf, screen and fabric on its
## frames is a flat plate the air pushes square to itself, by its area and how
## squarely the air meets it (mostly drag, some side force when angled), at its
## own middle, so a wall broadside heels a deck where edge-on it lets the wind
## by. Sorted along the wind, a face with another just upwind across its
## footprint catches a share of what it would alone; a frame closed behind and
## round about, open into the wind, is a scoop that catches more. Its faces
## break the wind for what stands behind them as a small dune does (Weather),
## and fabric shows the load it bears. No cloth, no new bodies or joints: every
## push goes into the deck's one body.

## The wind's way in the deck's frame is worked in steps of 1/STEPS (about
## 3°): turning less, its shading and lee stand as they were. Turning
## faster, they're worked out again at most every RESHADE ticks.
const STEPS := 20.0
const RESHADE := 6
## A face this little further along the wind is beside another, not behind it, m.
const BEHIND := 0.05
## A face's lee fades out this share of its height past its edges.
const EDGE_FADE := 0.3
## Fabric is drawn taut by this much air square on, m/s.
const TAUT := 12.0
## Faces on a frame: each side's opposite, and the sides round about the line
## from one to the other (the top, the floor and the other two sides).
const OPPOSITE := {&"right": &"left", &"left": &"right", &"front": &"back", &"back": &"front"}
const ROUND := {&"right": [&"front", &"back", &"top"], &"left": [&"front", &"back", &"top"],
	&"front": [&"right", &"left", &"top"], &"back": [&"right", &"left", &"top"]}

## The deck they're on, as of its last tick, and its id: freed, its lee
## still stands for what reads it until the next.
var deck: Chassis
var deck_id := 0
## Each face, in the deck's frame: its middle, way out, half its width and
## height along it, m², and its cloth if it's fabric.
var _middle := PackedVector3Array()
var _out := PackedVector3Array()
var _half_a := PackedVector3Array()
var _half_b := PackedVector3Array()
var _area := PackedFloat32Array()
var _cloth: Array[MeshInstance3D] = []
## Its scoops: each frame's open side with its back closed, as the open
## side's way out, its back's index and the share of the sides round about
## that are closed, the floor among them.
var _scoops: Array = []
## What else on the deck the wind grabs, where it is in the deck's frame and
## its catch (Chassis.loose_items).
var _items_at := PackedVector3Array()
var _items_catch := PackedFloat32Array()
var _known := false
## What each catches of what it would alone at the wind's way now, its shade
## and its cup.
var _share := PackedFloat32Array()
var _key := Vector3i.MAX
var _shaded_tick := 0
## The wind's way across the deck's frame, and each face that casts a lee as
## the wind sees it, 9 a face: how far along it, across and up its middle is,
## half its width and height across it, how squarely it meets it, how far
## behind its lee is full and gone, and how far past its edges it fades.
var _way := Vector3.ZERO
var _across := Vector3.ZERO
var _up := Vector3.ZERO
var _lee := PackedFloat32Array()
## The middle of its lee in the deck's frame and how far from it it reaches,
## m; from the world into the deck's frame as of its last tick.
var _lee_middle := Vector3.ZERO
var _lee_reach := 0.0
var _to_deck := Transform3D.IDENTITY
var _lee_centre := Vector3.ZERO
## What its faces catch together along the wind's way now, as a loose
## body's catch counts it: what a line holding the deck bears and what the
## wind carries off while you sleep. And what the rest of the deck catches,
## less what their lee keeps from what stands behind them; NAN till worked out.
var catch_now := 0.0
var loose_now := NAN
## Each face's push last tick, N, in the world; what a tick costs, µs, on average.
var pushes := PackedVector3Array()
var cost_us := 0.0
var _looks := PackedVector2Array()


## Its faces changed: worked out again on the next tick.
func forget() -> void:
	_known = false
	_key = Vector3i.MAX
	catch_now = 0.0
	loose_now = NAN


## How many faces it has.
func count() -> int:
	return _middle.size()


## Whether a face is fabric showing its load, and what it shows: [load, air].
func look_of(i: int) -> Vector2:
	return _looks[i] if i < _looks.size() else Vector2.ZERO


## A tick of wind on its faces: each face's push at its middle as the air
## meets it there, into the deck's body, then the lee it casts as it stands.
## The felt wind at the deck, its own faces' lee aside, given. Whether it
## has a lee to cast.
func blow(on: Chassis, felt: Vector3) -> bool:
	deck = on
	deck_id = on.get_instance_id()
	if not _known:
		_gather()
	if _middle.is_empty():
		return false
	var started := Time.get_ticks_usec()
	var t := deck.global_transform
	var middle := t * deck.center_of_mass
	var moving := deck.linear_velocity
	var spin := deck.angular_velocity
	var basis := t.basis.orthonormalized()
	var past := basis.inverse() * (felt - moving)
	# In still air, or still in the air, the faces stand as they were shaded.
	if past.length() > 0.1:
		var way := past.normalized()
		var key := Vector3i((way * STEPS).round())
		if key != _key and (_key == Vector3i.MAX or Engine.get_physics_frames() - _shaded_tick >= RESHADE):
			_key = key
			_shade(way, deck.world.tuning)
	var catch := deck.world.tuning.wind_catch_per_m2
	var force := Vector3.ZERO
	var torque := Vector3.ZERO
	for i in _middle.size():
		var at := t * _middle[i]
		var arm := at - middle
		var air := felt - moving - spin.cross(arm)
		var normal := basis * _out[i]
		var push := normal * (catch * _area[i] * _share[i] * air.length() * air.dot(normal))
		pushes[i] = push
		force += push
		torque += arm.cross(push)
		if _cloth[i] != null:
			_show(i, push.dot(normal) / (catch * _area[i] * TAUT * TAUT), air.length())
	deck.apply_central_force(force)
	deck.apply_torque(torque)
	_to_deck = t.affine_inverse()
	_lee_centre = t * _lee_middle
	cost_us += (Time.get_ticks_usec() - started - cost_us) * 0.05
	return not _lee.is_empty()


## How much of a full lee its faces give a place in the world, 0 to 1: the
## best of them, by how far behind it is in their heights (fully to the lee's
## first, none past its second), how squarely they meet the wind and how far
## out past their edges it stands.
func lee_at(at: Vector3) -> float:
	if _lee.is_empty() or at.distance_squared_to(_lee_centre) > _lee_reach * _lee_reach:
		return 0.0
	return _lee_here(_to_deck * at)


## lee_at() a place in the deck's frame.
func _lee_here(p: Vector3) -> float:
	var along := p.dot(_way)
	var x := p.dot(_across)
	var y := p.dot(_up)
	var best := 0.0
	for k in range(0, _lee.size(), 9):
		var behind := along - _lee[k]
		if behind <= 0.0 or behind >= _lee[k + 7]:
			continue
		var edge := _lee[k + 8]
		var off_x := absf(x - _lee[k + 1]) - _lee[k + 3]
		var off_y := absf(y - _lee[k + 2]) - _lee[k + 4]
		if off_x >= edge or off_y >= edge:
			continue
		best = maxf(best, _lee[k + 5] * (1.0 - smoothstep(_lee[k + 6], _lee[k + 7], behind))
			* (1.0 - smoothstep(0.0, edge, off_x)) * (1.0 - smoothstep(0.0, edge, off_y)))
	return best


func _gather() -> void:
	_known = true
	var plates := deck.plates()
	var n := plates.size()
	_middle.resize(n)
	_out.resize(n)
	_half_a.resize(n)
	_half_b.resize(n)
	_area.resize(n)
	_share.resize(n)
	pushes.resize(n)
	_looks.resize(n)
	_cloth.clear()
	_scoops.clear()
	_lee.clear()
	var on_frame := {}
	for i in n:
		var plate: Array = plates[i]
		_middle[i] = plate[0]
		_out[i] = plate[1]
		_area[i] = plate[2]
		_half_a[i] = plate[4]
		_half_b[i] = plate[5]
		_share[i] = 1.0
		pushes[i] = Vector3.ZERO
		_looks[i] = Vector2.ZERO
		var face: Socket = plate[6]
		var cloth: MeshInstance3D = null
		for node in face.fitted:
			if node.has_meta(&"cloth"):
				cloth = node
		_cloth.append(cloth)
		on_frame[face] = i
	_items_at.clear()
	_items_catch.clear()
	for item: Array in deck.loose_items():
		_items_at.append(item[0])
		_items_catch.append(item[1])
	# A frame open on a side with its back closed is a scoop, judged by its
	# faces: what's filled and where its open side points.
	for socket in deck.stuck():
		var frame := socket.part as Frame
		if frame == null:
			continue
		var named := frame.faces()
		for open: StringName in OPPOSITE:
			var back: int = on_frame.get(named.get(OPPOSITE[open]), -1)
			if not named.has(open) or on_frame.has(named[open]) or back < 0:
				continue
			var walls := 1.0
			for side: StringName in ROUND[open]:
				walls += 1.0 if on_frame.has(named.get(side)) else 0.0
			_scoops.append([(named[open] as Socket).transform.basis.z.normalized(), back, walls / 4.0])


## Each face's share of what it would catch alone, the wind's way in the
## deck's frame given: shaded by any face just upwind across its footprint,
## and cupped by a scoop open into the wind. And the lee the faces still in
## the wind cast, and their catch along the way, for anything that asks it
## of the deck.
func _shade(way: Vector3, tuning: Tuning) -> void:
	_shaded_tick = Engine.get_physics_frames()
	var up := Vector3.UP - way * way.y
	if up.length() < 0.1:
		up = Vector3.BACK - way * way.z
	up = up.normalized()
	var across := up.cross(way)
	_way = way
	_across = across
	_up = up
	var n := _middle.size()
	# Each face as the wind sees it: how far along it, its box across it
	# (its middle and half its width and height), and how squarely it meets it.
	var along := PackedFloat32Array()
	var x := PackedFloat32Array()
	var y := PackedFloat32Array()
	var hx := PackedFloat32Array()
	var hy := PackedFloat32Array()
	var square := PackedFloat32Array()
	var order := []
	for i in n:
		var m := _middle[i]
		var a := _half_a[i]
		var b := _half_b[i]
		along.append(m.dot(way))
		x.append(m.dot(across))
		y.append(m.dot(up))
		hx.append(absf(a.dot(across)) + absf(b.dot(across)))
		hy.append(absf(a.dot(up)) + absf(b.dot(up)))
		square.append(absf(_out[i].dot(way)))
		order.append(Vector2(along[i], i))
	order.sort()
	# Sorted along the wind, each face's box across it: only one further
	# upwind can shade it.
	var heights: Vector2 = tuning.lee_heights
	var s_along := PackedFloat32Array()
	var s_x := PackedFloat32Array()
	var s_y := PackedFloat32Array()
	var s_tall := PackedFloat32Array()
	for k in n:
		var i := int(order[k].y)
		s_along.append(along[i])
		s_x.append_array([x[i] - hx[i], x[i] + hx[i]])
		s_y.append_array([y[i] - hy[i], y[i] + hy[i]])
		s_tall.append(maxf(2.0 * hy[i], 0.1))
	var covered := PackedFloat32Array()
	covered.resize(n)
	for jj in n:
		var j := int(order[jj].y)
		var most := 0.0
		var box := 4.0 * hx[j] * hy[j]
		if box > 1e-6:
			var at := s_along[jj]
			var left := s_x[jj * 2]
			var right := s_x[jj * 2 + 1]
			var low := s_y[jj * 2]
			var high := s_y[jj * 2 + 1]
			for i in jj:
				var behind := at - s_along[i]
				if behind < BEHIND:
					break
				var wide := minf(s_x[i * 2 + 1], right) - maxf(s_x[i * 2], left)
				if wide <= 0.0:
					continue
				var tall := minf(s_y[i * 2 + 1], high) - maxf(s_y[i * 2], low)
				if tall <= 0.0:
					continue
				most = maxf(most, wide * tall / box * (1.0 - smoothstep(heights.x * s_tall[i], heights.y * s_tall[i], behind)))
		covered[j] = most
		_share[j] = lerpf(1.0, tuning.face_shaded, most)
	# A scoop: open on one side with its back closed. Open into the wind, its
	# back catches more, the more of its sides round about are closed (the
	# floor always is); open away from it, the back shelters its inside.
	for scoop: Array in _scoops:
		var into := -(scoop[0] as Vector3).dot(way)
		if into > 0.0:
			_share[scoop[1]] *= 1.0 + (tuning.face_cup - 1.0) * into * scoop[2]
	# The lee, from the faces standing across the wind and still in it: one
	# behind another is in the lee of the one in front already.
	_lee.clear()
	var middle := Vector3.ZERO
	for i in n:
		middle += _middle[i] / n
	var reach := 0.0
	catch_now = 0.0
	for i in n:
		catch_now += tuning.wind_catch_per_m2 * _area[i] * _share[i] * square[i]
		if hx[i] < 0.05 or hy[i] < 0.05 or square[i] < 0.1 or covered[i] > 0.5:
			continue
		var tall := 2.0 * hy[i]
		_lee.append_array([along[i], x[i], y[i], hx[i], hy[i], square[i], heights.x * tall, heights.y * tall,
			EDGE_FADE * tall])
		reach = maxf(reach, _middle[i].distance_to(middle) + heights.y * tall + hx[i] + hy[i] + EDGE_FADE * tall)
	_lee_middle = middle
	_lee_reach = reach
	# What stands behind them feels the wind their lee lets through.
	loose_now = 0.0 if not _lee.is_empty() else deck.loose_catch()
	for k in (_items_at.size() if not _lee.is_empty() else 0):
		loose_now += _items_catch[k] * pow(1.0 - tuning.lee_wind * _lee_here(_items_at[k]), 2.0)
	deck.set_meta(&"wind_catch", loose_now + catch_now)


## Fabric shows the load it bears: taut and bellied as hard as the air
## presses across it, which way it presses, slack fluttering in the air past it.
func _show(i: int, load: float, air: float) -> void:
	var look := Vector2(clampf(load, -1.5, 1.5), air)
	if absf(look.x - _looks[i].x) < 0.002 and absf(look.y - _looks[i].y) < 0.05:
		return
	_looks[i] = look
	_cloth[i].set_instance_shader_parameter(&"load", look.x)
	_cloth[i].set_instance_shader_parameter(&"air", look.y)


## A fabric face's cloth: a grid the fabric shader moves, across the face
## inside its hem, standing out of it along +Z.
static func cloth(size: Vector3) -> MeshInstance3D:
	var grid := PlaneMesh.new()
	grid.orientation = PlaneMesh.FACE_Z
	grid.size = Vector2(size.x, size.y)
	grid.subdivide_width = 10
	grid.subdivide_depth = 10
	grid.material = _material()
	grid.custom_aabb = AABB(Vector3(-size.x * 0.5, -size.y * 0.5, -0.15), Vector3(size.x, size.y, 0.3))
	var view := MeshInstance3D.new()
	view.mesh = grid
	view.position = Vector3(0.0, 0.0, size.z * 0.5)
	view.set_meta(&"cloth", true)
	return view


static var _fabric: ShaderMaterial


static func _material() -> ShaderMaterial:
	if _fabric == null:
		_fabric = ShaderMaterial.new()
		_fabric.shader = preload("res://game/devices/fabric.gdshader")
	return _fabric
