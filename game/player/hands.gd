class_name Hands
extends Node3D
## Your hands, with room for one part. Look at a loose part and take it, or at
## a fitted one and it slides out the way it went in. Carry it in front of your
## eyes and aim at a free socket of its kind: aimed within reach of where it
## would sit, it leans in, a ghost shows the spot, and it snaps home with a
## clunk. Only a part held here ever snaps; nothing fits by being bumped.

signal fitted(part: Part, device: Device, socket: Socket)
signal taken(part: Part, device: Device, socket: Socket)

enum Phase { EMPTY, TAKING, ARRIVING, HELD }

## A part that's come free reaches your hand in this long, s.
const ARRIVE := 0.12
## Blocked on its way to your hand this long, it skips there instead, s.
const STUCK := 0.3
## Aiming from this far behind a socket's face still counts as its open side, m.
const OPEN_MARGIN := 0.05
## A tugged part this close in angle to its seat is home: about 10°.
const HOME_ANGLE := 0.17
## How fast the tug swings over when a nearer socket wins, 1/s.
const SWING := 16.0
## Shapes are shrunk this much a side when asking whether a part is inside
## something, so resting against it doesn't count, m.
const SKIN := 0.005
const GHOST := Color(0.75, 0.95, 1.0)
const CLUNKS: Array[AudioStream] = [preload("res://assets/audio/clunk_a.ogg"),
	preload("res://assets/audio/clunk_b.ogg")]
const CLANK_OUT: AudioStream = preload("res://assets/audio/clank_out.ogg")
const HUM: AudioStreamOggVorbis = preload("res://assets/audio/hum.ogg")
const CLUNK_DB := -3.0
const OUT_DB := -12.0
## The magnetic hum at a full tug; it fades with the tug.
const HUM_DB := 0.0

var held: Part
var phase := Phase.EMPTY
## What the look ray hits: a loose part, or a device and, when it's a fitted
## part, that part's socket; and where it hit.
var look_part: Part
var look_device: Device
var look_socket: Socket
var look_point := Vector3.ZERO
var look_normal := Vector3.UP
## Your line of sight, from your eyes to whatever it stops at, or as far as you reach.
var sight_from := Vector3.ZERO
var sight_to := Vector3.ZERO
## The free socket the held part leans toward, how far your aim is from where
## the part would sit there, m, and how hard it leans, 0 to 1.
var socket: Socket
var gap := INF
var pull := 0.0

var _player: Player
var _tuning := Tuning.current()
var _hooked := false
## The held part's shapes, shrunk copies of them, and their bounds and middle
## in the part's own frame.
var _shapes: Array[CollisionShape3D] = []
var _skins: Array[Shape3D] = []
var _bounds := AABB()
var _middle := Vector3.ZERO
var _layers := Vector2i.ZERO
var _freeze_mode := RigidBody3D.FREEZE_MODE_STATIC
## How the held part is turned relative to your heading.
var _carry := Basis.IDENTITY
## Where the tug leans the part, swung smoothly between sockets.
var _lean := Transform3D.IDENTITY
## Progress through sliding out or arriving, 0 to 1; where arriving began, and
## how long the way has been blocked.
var _t := 0.0
var _from := Transform3D.IDENTITY
var _stuck := 0.0
var _slide := 0.0
## The device a part is coming out of, held still meanwhile so it can't drop
## onto the part, and what it was doing before.
var _source: Device
var _source_socket: Socket
var _source_was := {}
## The socket a part just came out of: it won't tug again until you aim away.
var _rearm: Socket
var _aim := Vector3.ZERO
## Parts just let go, which can't push you until they're clear of you.
var _released: Array[Dictionary] = []
var _body_radius := 0.35
var _ghost: Node3D
var _ghost_look: StandardMaterial3D
var _readout: Label
var _sound: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _clunks := 0
var _cast := PhysicsShapeQueryParameters3D.new()
var _inside := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	_player = get_parent() as Player
	for child in _player.get_children():
		var body := child as CollisionShape3D
		if body != null and body.shape is CapsuleShape3D:
			_body_radius = (body.shape as CapsuleShape3D).radius
	_ghost = Node3D.new()
	_ghost.top_level = true
	_ghost.visible = false
	add_child(_ghost)
	_ghost_look = StandardMaterial3D.new()
	_ghost_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Seen through whatever is in the way, even the sand under a resting device.
	_ghost_look.no_depth_test = true
	_ghost_look.albedo_color = GHOST
	_sound = AudioStreamPlayer.new()
	_sound.max_polyphony = 2
	add_child(_sound)
	var hum: AudioStreamOggVorbis = HUM
	hum.loop = true
	_hum = AudioStreamPlayer.new()
	_hum.stream = hum
	add_child(_hum)
	_build_hud()


## E: take what you're looking at, or, holding a part, fit it now if a socket
## is in tug range. Says whether it did anything.
func grab() -> bool:
	if held != null:
		if phase == Phase.HELD and socket != null:
			_fit(socket)
			return true
		return false
	_look()
	if look_part != null:
		_pick_up(look_part)
		return true
	if look_socket != null and look_socket.part != null:
		_take_out(look_device, look_socket)
		return true
	return false


## G: let go, moving as you were.
func drop() -> void:
	_release(_player.velocity)


## Click: let go with a throw along your aim.
func throw() -> void:
	_release(_player.velocity - _player.camera.global_basis.z * _tuning.throw_speed)


## One line saying what something is and what it does.
static func describe(label: String, mass: float, stats: Dictionary) -> String:
	var bits := PackedStringArray([label, ("%d kg" % roundi(mass)) if is_equal_approx(mass, roundf(mass))
		else ("%.1f kg" % mass)])
	if stats.get("capacity_wh", 0.0) > 0.0:
		bits.append("%d Wh" % roundi(stats.capacity_wh))
	var hooks: int = stats.get("hooks", 0)
	if hooks > 0:
		bits.append("%d hook%s" % [hooks, "" if hooks == 1 else "s"])
	if stats.get("lift_kg", 0.0) > 0.0:
		bits.append("floats %d kg" % roundi(stats.lift_kg))
	if stats.get("hover_w", 0.0) > 0.0:
		bits.append("%d W" % roundi(stats.hover_w))
	if stats.get("solar_w", 0.0) > 0.0:
		bits.append("%d W solar" % roundi(stats.solar_w))
	if stats.get("light_w", 0.0) > 0.0:
		bits.append("%d W light" % roundi(stats.light_w))
	var plants: int = stats.get("plants", 0)
	if plants > 0:
		bits.append("%d plant%s" % [plants, "" if plants == 1 else "s"])
	return " · ".join(bits)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hands_grab"):
		if grab():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_drop") and held != null:
		drop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_throw") and held != null \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		throw()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	if not _hooked:
		world.origin_shifted.connect(_on_origin_shifted)
		_hooked = true
	if phase != Phase.EMPTY and not is_instance_valid(held):
		_forget()
	_look()
	match phase:
		Phase.TAKING:
			if not is_instance_valid(_source):
				_arrive_from(held.global_transform)
			else:
				_t = minf(_t + delta / _tuning.take_seconds, 1.0)
				held.global_transform = _sliding()
				if _t >= 1.0:
					_arrive_from(held.global_transform)
		Phase.ARRIVING:
			_arrive(delta)
		Phase.HELD:
			_tug(delta)
			held.global_transform = _pose()
			if socket != null and _home():
				_fit(socket)
	_unblock_released()
	_show(delta)


## Frame by frame too, so a held part never trails your view as you turn.
func _process(_delta: float) -> void:
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _pose()


func _look() -> void:
	look_part = null
	look_device = null
	look_socket = null
	var eye := _player.camera.global_transform
	sight_from = eye.origin
	sight_to = eye.origin - eye.basis.z * _tuning.reach
	var ray := PhysicsRayQueryParameters3D.create(sight_from, sight_to)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return
	sight_to = hit.position
	look_point = hit.position
	look_normal = hit.normal
	var body: Object = hit.collider
	if body is Part:
		look_part = body
	elif body is Device:
		look_device = body
		look_socket = look_device.socket_of(
			look_device.shape_owner_get_owner(look_device.shape_find_owner(hit.shape)) as Node)


func _pick_up(part: Part) -> void:
	_grip(part)
	_arrive_from(part.global_transform)


## The device holds still while the part slides straight out along its
## socket's +Z, then the part comes to your hand.
func _take_out(device: Device, from: Socket) -> void:
	_source = device
	_source_socket = from
	_source_was = {"freeze": device.freeze, "velocity": device.linear_velocity, "spin": device.angular_velocity}
	device.freeze = true
	var part := device.take(from)
	_grip(part)
	_slide = part.depth()
	_t = 0.0
	phase = Phase.TAKING
	_rearm = from
	_play(CLANK_OUT, OUT_DB)
	taken.emit(part, device, from)


func _grip(part: Part) -> void:
	held = part
	_layers = Vector2i(part.collision_layer, part.collision_mask)
	_freeze_mode = part.freeze_mode
	part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	part.freeze = true
	# Held, it touches nothing: it can't shove a device, a part or you.
	part.collision_layer = 0
	part.collision_mask = 0
	_unblock(part)
	_shapes.clear()
	_skins.clear()
	var first := true
	for child in part.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		_shapes.append(shape)
		_skins.append(_skin(shape.shape))
		var box := shape.transform * shape.shape.get_debug_mesh().get_aabb()
		_bounds = box if first else _bounds.merge(box)
		first = false
	_middle = _bounds.get_center()
	_carry = _tidy(Basis(Vector3.UP, -_player.global_rotation.y) * part.global_basis.orthonormalized())
	pull = 0.0
	socket = null
	gap = INF
	_build_ghost(part)


func _arrive_from(pose: Transform3D) -> void:
	_from = pose
	_t = 0.0
	_stuck = 0.0
	phase = Phase.ARRIVING


## Eases to your hand, but never through anything: blocked, it waits, and
## blocked too long it skips to your hand, which is always clear.
func _arrive(delta: float) -> void:
	var next := minf(_t + delta / ARRIVE, 1.0)
	var pose := _blend(_from, _hand(), smoothstep(0.0, 1.0, next))
	if _clear(pose):
		_t = next
		_stuck = 0.0
		held.global_transform = pose
	else:
		_stuck += delta
		if _stuck > STUCK:
			_t = 1.0
			held.global_transform = _hand()
	if _t >= 1.0:
		phase = Phase.HELD
		_release_source()


func _tug(delta: float) -> void:
	_find_socket()
	var want := 0.0
	if socket != null:
		var seat := _settle_in(_seat(socket))
		want = smoothstep(_tuning.snap_reach, _tuning.snap_home, gap)
		_lean = seat if pull == 0.0 else _blend(_lean, seat, 1.0 - exp(-SWING * delta))
	pull = move_toward(pull, want, delta / _tuning.tug_seconds)


## The free socket of the held part's kind nearest your line of sight, among
## the devices in reach, reached from its open side: measured from where the
## part would sit there, so aiming at the spot or at the ghost is the same.
func _find_socket() -> void:
	if _rearm != null and (not is_instance_valid(_rearm) or _rearm.part != null
			or _sight_gap(_seat(_rearm)) > _tuning.snap_reach):
		_rearm = null
	var best: Socket = null
	var nearest := INF
	for child in _player.world.content.get_children():
		var device := child as Device
		if device == null or device.global_position.distance_to(sight_from) > _tuning.reach + 2.0:
			continue
		for each in device.sockets():
			if each.part != null or each.kind != held.kind or each == _rearm:
				continue
			var seat := _seat(each)
			var d := _sight_gap(seat)
			if d < nearest and _open(seat, device):
				nearest = d
				best = each
	gap = nearest
	socket = best if nearest < _tuning.snap_reach else null


## How near your line of sight passes to the part as it would sit in this
## seat, m; _aim is the point on it that passes nearest.
func _sight_gap(seat: Transform3D) -> float:
	var inverse := seat.affine_inverse()
	var a := inverse * sight_from
	var b := inverse * sight_to
	# The distance to a box along a line has one valley: close in on it.
	var lo := 0.0
	var hi := 1.0
	for i in 24:
		var one := lerpf(lo, hi, 1.0 / 3.0)
		var two := lerpf(lo, hi, 2.0 / 3.0)
		if _outside(a.lerp(b, one)) <= _outside(a.lerp(b, two)):
			hi = two
		else:
			lo = one
	var nearest := a.lerp(b, (lo + hi) * 0.5)
	_aim = seat * nearest
	return _outside(nearest)


## How far a point in a seat's frame is outside the part sitting there.
func _outside(local: Vector3) -> float:
	return local.distance_to(local.clamp(_bounds.position, _bounds.end))


func _open(seat: Transform3D, device: Device) -> bool:
	var out := seat.basis.z
	if (_aim - seat.origin).dot(out) >= -OPEN_MARGIN:
		return true
	# A seat facing down into the sand is only reached from beside: you slide
	# the part under, aiming at the device's side.
	var tip := seat * Vector3(0.0, 0.0, _bounds.end.z)
	return out.y < -0.7 and tip.y < _player.world.height_under(tip) and look_device == device \
		and absf(look_normal.dot(out)) < 0.5


## Parts are plain boxes, the same turned end over end about their middle, so
## the tug leans one toward whichever way of sitting in the seat is nearest
## how it's held, never flipping it over on the way; fit() then seats it
## exactly, and nothing you can see changes.
func _settle_in(seat: Transform3D) -> Transform3D:
	var held_turn := (Basis(Vector3.UP, _player.global_rotation.y) * _carry).get_rotation_quaternion()
	var best := seat
	var nearest := INF
	for flip: Basis in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI), Basis(Vector3.UP, PI), Basis(Vector3.BACK, PI)]:
		var basis := (seat.basis * flip).orthonormalized()
		var angle := held_turn.angle_to(basis.get_rotation_quaternion())
		if angle < nearest:
			nearest = angle
			best = Transform3D(basis, seat * _middle - basis * _middle)
	return best


func _home() -> bool:
	var seat := _settle_in(_seat(socket))
	var at := held.global_transform
	return (at * _middle).distance_to(seat * _middle) <= _tuning.snap_home \
		and at.basis.get_rotation_quaternion().angle_to(seat.basis.get_rotation_quaternion()) <= HOME_ANGLE


func _fit(into: Socket) -> void:
	var device := into.get_parent() as Device
	var part := held
	_let_go()
	device.fit(part, into)
	_play(CLUNKS[_clunks % CLUNKS.size()], CLUNK_DB)
	_clunks += 1
	fitted.emit(part, device, into)


func _release(velocity: Vector3) -> void:
	if held == null:
		return
	var part := held
	var middle := _middle
	var radius := _bounds.size.length() * 0.5
	_let_go()
	part.linear_velocity = velocity
	part.angular_velocity = Vector3.ZERO
	# It may start inside you: it can't push you until it's clear of you.
	part.add_collision_exception_with(_player)
	_released.append({"part": part, "middle": middle, "radius": radius})


func _let_go() -> void:
	var part := held
	_release_source()
	part.freeze = false
	part.freeze_mode = _freeze_mode
	part.collision_layer = _layers.x
	part.collision_mask = _layers.y
	_forget()


func _forget() -> void:
	_release_source()
	held = null
	phase = Phase.EMPTY
	socket = null
	pull = 0.0
	gap = INF
	_clear_ghost()


func _release_source() -> void:
	if is_instance_valid(_source):
		_source.freeze = _source_was.freeze
		if not _source.freeze:
			_source.linear_velocity = _source_was.velocity
			_source.angular_velocity = _source_was.spin
	_source = null
	_source_socket = null


func _unblock_released() -> void:
	for i in range(_released.size() - 1, -1, -1):
		var gone: Dictionary = _released[i]
		if not is_instance_valid(gone.part):
			_released.remove_at(i)
			continue
		var part: Part = gone.part
		var off: Vector3 = part.global_transform * gone.middle - _player.global_position
		if Vector2(off.x, off.z).length() > _body_radius + gone.radius or off.y < -gone.radius or off.y > 2.5:
			_unblock(part)


func _unblock(part: Part) -> void:
	for i in range(_released.size() - 1, -1, -1):
		if is_instance_valid(_released[i].part) and _released[i].part == part:
			_released.remove_at(i)
			part.remove_collision_exception_with(_player)


## Where the held part sits: in your hand, leaning toward a socket as hard as
## the tug pulls.
func _pose() -> Transform3D:
	var hand := _hand()
	return hand if pull <= 0.0 else _blend(hand, _lean, smoothstep(0.0, 1.0, pull))


## hold_distance in front of your eyes, turned with you, and stopped short of
## anything in the way, so it never ends up inside the sand or a device.
func _hand() -> Transform3D:
	var eye := _player.camera.global_transform
	var basis := Basis(Vector3.UP, _player.global_rotation.y) * _carry
	var ahead := -eye.basis.z.normalized() * _tuning.hold_distance
	var start := Transform3D(basis, eye.origin - basis * _middle)
	return start.translated(ahead * _sweep(start, ahead))


## How far along motion the held part can move from start before it touches
## something, 0 to 1. Starting inside something, it can't tell, so all the way.
func _sweep(start: Transform3D, motion: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	_cast.exclude = _exclusions()
	_cast.motion = motion
	var safe := 1.0
	for shape in _shapes:
		_cast.shape = shape.shape
		_cast.transform = start * shape.transform
		var fraction := space.cast_motion(_cast)
		if fraction[1] > 0.0:
			safe = minf(safe, fraction[0])
	return safe


func _clear(pose: Transform3D) -> bool:
	var space := get_world_3d().direct_space_state
	_inside.exclude = _exclusions()
	for i in _shapes.size():
		_inside.shape = _skins[i]
		_inside.transform = pose * _shapes[i].transform
		if not space.intersect_shape(_inside, 1).is_empty():
			return false
	return true


func _sliding() -> Transform3D:
	var out := 1.0 - (1.0 - _t) * (1.0 - _t)
	return _seat(_source_socket).translated_local(Vector3(0.0, 0.0, _slide * out))


## Where a part sits in a socket, in the world.
func _seat(into: Socket) -> Transform3D:
	return ((into.get_parent() as Node3D).global_transform * into.transform).orthonormalized()


## Between two poses of the held part, turning about its own middle.
func _blend(a: Transform3D, b: Transform3D, t: float) -> Transform3D:
	var basis := a.basis.orthonormalized().slerp(b.basis.orthonormalized(), t)
	var middle := (a * _middle).lerp(b * _middle, t)
	return Transform3D(basis, middle - basis * _middle)


func _exclusions() -> Array[RID]:
	var out: Array[RID] = [_player.get_rid()]
	if is_instance_valid(held):
		out.append(held.get_rid())
	return out


## Squared up to your heading, whatever way it lay.
static func _tidy(turn: Basis) -> Basis:
	var x := _axis(turn.x)
	var y := _axis(turn.y - x * turn.y.dot(x))
	return Basis(x, y, x.cross(y))


static func _axis(v: Vector3) -> Vector3:
	var a := v.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3(signf(v.x), 0.0, 0.0)
	if a.y >= a.z:
		return Vector3(0.0, signf(v.y), 0.0)
	return Vector3(0.0, 0.0, signf(v.z))


static func _skin(shape: Shape3D) -> Shape3D:
	var box := shape as BoxShape3D
	if box == null:
		return shape
	var thinner := BoxShape3D.new()
	thinner.size = (box.size - Vector3.ONE * SKIN * 2.0).max(Vector3.ONE * SKIN)
	return thinner


func _on_origin_shifted(by: Vector2i) -> void:
	var offset := Vector3(by.x, 0.0, by.y) * _tuning.chunk_size
	_from.origin -= offset
	_lean.origin -= offset


func _build_ghost(part: Part) -> void:
	_clear_ghost()
	for child in part.get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = mesh.mesh
		copy.transform = mesh.transform
		copy.material_override = _ghost_look
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.add_child(copy)


func _clear_ghost() -> void:
	for child in _ghost.get_children():
		child.free()
	_ghost.visible = false


func _play(stream: AudioStream, db: float) -> void:
	_sound.stream = stream
	_sound.volume_db = db
	_sound.play()


## A dot where you aim and, under it, one short line about what it's on.
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 99
	add_child(hud)
	var dot := Control.new()
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func() -> void:
		dot.draw_circle(Vector2.ZERO, 2.5, Color(0.0, 0.0, 0.0, 0.7))
		dot.draw_circle(Vector2.ZERO, 1.5, Color.WHITE))
	hud.add_child(dot)
	_readout = Label.new()
	_readout.add_theme_font_size_override("font_size", 12)
	_readout.add_theme_color_override("font_outline_color", Color.BLACK)
	_readout.add_theme_constant_override("outline_size", 4)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.set_anchors_preset(Control.PRESET_CENTER)
	_readout.offset_left = -400.0
	_readout.offset_right = 400.0
	_readout.offset_top = 10.0
	_readout.offset_bottom = 28.0
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.modulate.a = 0.0
	hud.add_child(_readout)


func _show(delta: float) -> void:
	var line := ""
	if look_part != null:
		line = describe(look_part.label, look_part.mass, look_part.stats)
	elif look_socket != null and look_socket.part != null:
		line = describe(look_socket.part.label, look_socket.part.mass, look_socket.part.stats)
	elif look_device != null:
		var stats := look_device.stats()
		line = describe(look_device.label, stats.mass, stats)
	if line != "" and line != _readout.text:
		_readout.text = line
	_readout.modulate.a = move_toward(_readout.modulate.a, 1.0 if line != "" else 0.0, delta * 8.0)

	_ghost.visible = socket != null
	if socket != null:
		_ghost.global_transform = _seat(socket)
		_ghost_look.albedo_color.a = 0.2 + 0.3 * pull
	if pull > 0.01:
		_hum.volume_db = HUM_DB + linear_to_db(pull)
		if not _hum.playing:
			_hum.play()
	elif _hum.playing:
		_hum.stop()

	Dev.put("hands/held", held.label if held != null else "-")
	Dev.put("hands/tug", "%.2f %.2fm" % [pull, gap] if socket != null else "-")
