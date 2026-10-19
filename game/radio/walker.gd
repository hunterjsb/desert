class_name Walker
extends Device
## The Walker itself: Tilg's survey walker, the colonial survey mind, on its
## fixed route round the Rim where its station is heard from (Gods.home),
## walking at its pace whoever watches. Six legs on a tripod gait, one of
## them snapped short and dragged. You can walk up to it, and plug a cable
## into its data port: a Console at the other end uploads what it has
## (Console.upload). Far off it's its stand-in by the Skyline's rules, a few
## boxes at its own size, veiled by any storm between; past the skyline's
## reach, nothing. It's no thing of yours: no save, power pool or wear has it.

## Its legs: right front to rear, then left; the left rear is the broken one.
## The tripods step half a stride apart.
const BROKEN := 5
const PHASES: Array[float] = [0.0, 0.5, 0.0, 0.5, 0.0, 0.5]
## A stride, m; the share of it a foot stands, and how high one swings, m.
const STRIDE := 1.3
const STANCE := 0.6
const LIFT := 0.3
## Its hips stand this high over the sand, its feet this far out from them, m.
const HIP_HIGH := 1.75
const REACH := 1.2
## It lists toward its broken leg, rad.
const LIST := 0.04
## Its heading is read this far along its route, s.
const AHEAD := 10.0
## Its stand-in is read for the storms between this often, s.
const VEIL_EVERY := 1.0

var port: Socket
var _hull: MeshInstance3D
var _legs: Array[Array] = []
var _far: MultiMeshInstance3D
var _veils: ImageTexture
var _veil_at := -INF
var _read_plug: Part
var _tuning: Tuning


func _init() -> void:
	label = "Walker"
	frame_mass = 900.0
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	_tuning = Tuning.current()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = WalkerLooks.HULL + Vector3(0.0, 0.0, 0.4)
	shape.shape = box
	shape.position = Vector3(0.0, 0.15, -0.2)
	add_child(shape)
	_hull = _view(WalkerLooks.hull())
	for i in WalkerLooks.hips().size():
		_legs.append([_view(WalkerLooks.upper()), _view(WalkerLooks.stump() if i == BROKEN else WalkerLooks.lower())])
	port = Socket.new()
	port.kind = &"port"
	port.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), WalkerLooks.PORT)
	add_child(port)
	var tell := MeshInstance3D.new()
	tell.mesh = Dress.tell(&"port")
	tell.set_instance_shader_parameter(&"lit", 1.0)
	port.add_child(tell)
	port.marker = tell
	_far = _stand_in()
	add_child(_far)


func _ready() -> void:
	super()
	add_to_group(&"walker")
	for view in painted():
		view.set_instance_shader_parameter(&"age", 0.62)
		view.set_instance_shader_parameter(&"lit", 1.0)


## Where a place on the sphere lies on the ground, world metres: as the sheet
## lays history, else as the radio reckons it from where you stand.
static func ground(of: World, q: Vector3) -> Vector2:
	var anchor := of.shape.sites.anchor()
	if anchor != null:
		return anchor.place(q)
	var moon := of.moon
	var facing := -moon.north().z
	var off := Sphere.flat_from(Sphere.point(moon.latitude, moon.longitude), q) * moon.radius
	return Vector2(of.player_world_x() + off.x * facing, of.player_world_z() - off.y * facing)


## The place on the sphere under a point of the ground, world metres: ground's inverse.
static func point(of: World, x: float, z: float) -> Vector3:
	var anchor := of.shape.sites.anchor()
	if anchor != null:
		return anchor.point_at(x, z)
	var moon := of.moon
	var facing := -moon.north().z
	var off := Vector2((x - of.player_world_x()) * facing, -(z - of.player_world_z()) * facing) / moon.radius
	return Sphere.from_flat(Sphere.point(moon.latitude, moon.longitude), off)


## What the hands look over: it, when it's near enough to work.
static func near(of: World) -> Array:
	return of.get_tree().get_nodes_in_group(&"walker") if of.is_inside_tree() else []


## A loose plug comes off it onto the sand, among your things.
func _holder() -> Node:
	return world.content


func painted() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = [_hull]
	for leg in _legs:
		out.append_array(leg)
	return out


## It does what it does: nothing a use changes.
func interact(_by: Player) -> bool:
	return false


func _physics_process(_delta: float) -> void:
	if world == null:
		return
	var t := world.time
	var gods := Radio.gods_of(world)
	var at := ground(world, gods.home(&"walker", t))
	var on := Vector3(world.engine_x(at.x), 0.0, world.engine_z(at.y))
	var eye := world.player.camera.global_position
	var far := Vector2(on.x - eye.x, on.z - eye.z).length()
	var shows := far <= _tuning.skyline_m
	if shows != visible:
		visible = shows
		collision_layer = 1 if shows else 0
	if not shows:
		return
	var next := ground(world, gods.home(&"walker", t + AHEAD))
	var way := (next - at).normalized() if next.distance_to(at) > 1e-3 else Vector2(0.0, -1.0)
	var yaw := Basis(Vector3.UP, atan2(-way.x, -way.y))
	var walked := t * _tuning.walker_speed
	var feet := _feet(on, yaw, walked)
	var sand := 0.0
	for i in feet.size():
		if i != BROKEN:
			sand += feet[i].y - _swing(i, walked)
	sand /= feet.size() - 1
	var front := _sand_at(on + yaw * Vector3(0.0, 0.0, -1.2))
	var back := _sand_at(on + yaw * Vector3(0.0, 0.0, 1.2))
	var pitch := atan2(front - back, 2.4)
	var bob := 0.04 * sin(TAU * 2.0 * (walked / STRIDE))
	var body := yaw * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, -LIST)
	global_transform = Transform3D(body, Vector3(on.x, sand + HIP_HIGH + bob, on.z))
	if far <= _tuning.skyline_handover_m.y + 20.0:
		_pose_legs(feet)
	if t >= _veil_at + VEIL_EVERY or t < _veil_at:
		_veil_at = t
		_read_veil(eye)
	_read_port()


## Where each foot is on the ground this tick, engine metres: on a stride
## planted while the body passes over it, swung forward over the rest; the
## broken leg's stump dragged behind its hip.
func _feet(on: Vector3, yaw: Basis, walked: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var hips := WalkerLooks.hips()
	var half := STANCE * STRIDE * 0.5
	for i in hips.size():
		var home := hips[i] + Vector3(signf(hips[i].x) * REACH, 0.0, 0.0)
		var ahead := -0.45
		if i != BROKEN:
			var u := walked / STRIDE + PHASES[i]
			var f := u - floorf(u)
			ahead = lerpf(half, -half, f / STANCE) if f < STANCE else lerpf(-half, half, (f - STANCE) / (1.0 - STANCE))
		var spot := on + yaw * Vector3(home.x, 0.0, home.z - ahead)
		out.append(Vector3(spot.x, _sand_at(spot) + _swing(i, walked), spot.z))
	return out


## How high a foot swings clear of the sand now, m.
func _swing(i: int, walked: float) -> float:
	if i == BROKEN:
		return 0.0
	var u := walked / STRIDE + PHASES[i]
	var f := u - floorf(u)
	return 0.0 if f < STANCE else LIFT * sin(PI * (f - STANCE) / (1.0 - STANCE))


## Each leg from its hip to its foot, its knee up and out.
func _pose_legs(feet: Array[Vector3]) -> void:
	var hips := WalkerLooks.hips()
	for i in hips.size():
		var hip := global_transform * hips[i]
		var out := global_basis.x * signf(hips[i].x)
		var a := WalkerLooks.UPPER
		var b := WalkerLooks.STUMP if i == BROKEN else WalkerLooks.LOWER
		var to := feet[i] - hip
		var d := clampf(to.length(), absf(a - b) + 0.05, a + b - 0.01)
		var dir := to.normalized()
		var bend := (Vector3.UP + out * 0.5) - dir * (Vector3.UP + out * 0.5).dot(dir)
		bend = bend.normalized() if bend.length() > 1e-4 else Vector3.UP
		var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
		var knee := hip + dir * a * cos_a + bend * a * sqrt(1.0 - cos_a * cos_a)
		_legs[i][0].global_transform = Transform3D(_along(knee - hip, out), hip)
		_legs[i][1].global_transform = Transform3D(_along(hip + dir * d - knee, out), knee)


## A basis whose +Y runs along `way`, its +X as near `side` as that allows.
static func _along(way: Vector3, side: Vector3) -> Basis:
	var y := way.normalized()
	var x := side - y * side.dot(y)
	x = x.normalized() if x.length() > 1e-4 else y.cross(Vector3.FORWARD).normalized()
	return Basis(x, y, x.cross(y))


## The sand's height at an engine place: the built ground where it's built,
## the far ring's past it.
func _sand_at(at: Vector3) -> float:
	var x := world.world_x(at.x)
	var z := world.world_z(at.z)
	if world.terrain.has_collision_at(x, z):
		return world.height_at(x, z)
	return FarRing.ground(world.shape, _tuning, x, z)


## How much of its stand-in shows past the storms between you and it.
func _read_veil(eye: Vector3) -> void:
	var from := Vector3(world.world_x(eye.x), eye.y, world.world_z(eye.z))
	var middle := global_position + Vector3(0.0, 0.5, 0.0)
	var to := Vector3(world.world_x(middle.x), middle.y, world.world_z(middle.z))
	var through := Plume.seen_through(world.weather.field, _tuning, from, to, world.time) * (1.0 - world.weather.seen_storm)
	var image := Image.create_from_data(1, 1, false, Image.FORMAT_RF, PackedFloat32Array([through]).to_byte_array())
	_veils.update(image)


## A plug just put in its port: the Console at the other end of its cable
## uploads what it holds.
func _read_port() -> void:
	var plug := port.part
	if plug == _read_plug:
		return
	_read_plug = plug
	if plug == null:
		return
	for node in world.content.get_children():
		var cable := node as Cable
		if cable == null or not cable.plugs.has(plug):
			continue
		var other := cable.plugs[1 - cable.plugs.find(plug)]
		if is_instance_valid(other) and other.socket != null and other.socket.get_parent() is Console:
			(other.socket.get_parent() as Console).upload()


func _view(look: ArrayMesh) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = look
	var handover := _tuning.skyline_handover_m
	view.visibility_range_end = handover.x
	view.visibility_range_end_margin = handover.y - handover.x
	view.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(view)
	return view


## Its stand-in, drawn as the skyline draws one, coming in across the hand-over.
func _stand_in() -> MultiMeshInstance3D:
	var boxes := WalkerLooks.far(HIP_HIGH)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = true
	many.use_custom_data = true
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	many.mesh = cube
	many.instance_count = boxes.size()
	for i in boxes.size():
		var each: Array = boxes[i]
		many.set_instance_transform(i, Transform3D(Basis.from_scale(each[0]), each[1]))
		many.set_instance_color(i, (each[2] as Color).srgb_to_linear())
		many.set_instance_custom_data(i, Color(1.0, each[3], each[4], 0.0))
	var look := ShaderMaterial.new()
	look.shader = Skyline.BOX_SHADER
	look.set_shader_parameter("thinnest_px", _tuning.skyline_thinnest_px)
	look.set_shader_parameter("handover", _tuning.skyline_handover_m)
	_veils = ImageTexture.create_from_image(Image.create_from_data(1, 1, false, Image.FORMAT_RF,
		PackedFloat32Array([1.0]).to_byte_array()))
	look.set_shader_parameter("veils", _veils)
	var view := MultiMeshInstance3D.new()
	view.multimesh = many
	view.material_override = look
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return view
