class_name Showpiece
extends Node3D
## The main menu's kit on show, put together as a new run's is: the kit of
## the origin you last came as, floating in the foreground and tilting toward
## the mouse, as the prototype's shield and radio did; dragged, it spins.
## While you choose who you come as it slides aside, right of the words, and
## shows the highlighted origin's kit. Only what you see of it is kept, never
## a body, so it can't fall, blow away or be saved, and it stands in the
## desert's own light and weather.

## Where it floats in the camera's view, m: between the title and the words.
const AT := Vector3(0.0, -0.06, -2.8)
## Aside, its middle stands this far across the screen from the left.
const ASIDE := 0.68
## How long it takes to slide aside or home, and to swap one kit for another, s.
const SLIDE_SECONDS := 0.6
const SWAP_SECONDS := 0.3
## Things shown side by side stand this far apart, m.
const GAP := 0.3
## A kit wider corner to corner than the crate, m, is shown smaller, to fit where the crate does.
const SPAN := 1.9
## Turned to show its front, the board racked beyond it, and tipped to show
## what rides on top, degrees.
const YAW := 205.0
const TIP := 24.0
## The most it tilts toward the mouse, degrees, and how quickly it gets there, /s.
const MAX_TILT := 25.0
const EASE := 5.0
## A drag spins it this far per pixel, degrees; let go, the spin dies away at this rate, /s.
const SPIN_PER_PX := 0.6
const SPIN_SETTLE := 2.5

var ui: UIRoot
var camera: Camera3D
## The kit it shows on the main menu.
var home: Kit
## The origin highlighted while you choose, whose kit it shows aside.
var picked: Kit
## The kit it shows now.
var kit: Kit
## Where the mouse is, -1 to 1 across the screen from its middle. Until it
## moves, and once it leaves the window, it rests facing you.
var aim := Vector2.ZERO
var _model: Node3D
## Its bounds about its middle, which it turns round.
var _box: AABB
## How much smaller it's shown than it is, to fit.
var _fit := 1.0
## Each kit's looks, its bounds and fit, built the first time it's shown.
var _built := {}
## 0 at home to 1 aside; and how far the kit shown has grown in, 0 to 1.
var _slide := 0.0
var _grown := 1.0
var _tilt := Vector2.ZERO
var _spin := 0.0
var _spinning := 0.0
var _dragging := false


func _ready() -> void:
	if home == null:
		home = Kit.standard()
	_show(home)
	get_window().mouse_exited.connect(func() -> void: aim = Vector2.ZERO)
	# In place at once, never a frame at the world's origin.
	_process(0.0)


func _show(next: Kit) -> void:
	if _model != null:
		_model.visible = false
	if not _built.has(next):
		_built[next] = _build(next)
	var built: Array = _built[next]
	_model = built[0]
	_box = built[1]
	_fit = built[2]
	_model.visible = true
	kit = next


## The kit's things built for real, side by side, the first on the left as
## you face them, their batteries' lights showing; then only their looks
## kept: the bodies go.
func _build(from: Kit) -> Array:
	var model := Node3D.new()
	add_child(model)
	var cursor := 0.0
	for id: StringName in from.shown:
		var device := _thing(from, id)
		for each: Device in [device] + device.mounted():
			if each.charge_light != null:
				ChargeLight.paint(each.charge_light, each.charge_share())
		var piece := Node3D.new()
		model.add_child(piece)
		var to_device := device.global_transform.affine_inverse()
		for look: GeometryInstance3D in device.find_children("*", "GeometryInstance3D", true, false):
			if look.is_visible_in_tree():
				var pose := to_device * look.global_transform
				look.get_parent().remove_child(look)
				piece.add_child(look)
				look.transform = pose
		device.free()
		piece.basis = Basis(Vector3.UP, deg_to_rad(from.shown[id]))
		# Turned half round on show, so the row runs the other way.
		var box := _bounds(piece, piece.transform)
		piece.position -= Vector3(box.end.x - cursor, box.position.y, box.get_center().z)
		cursor -= box.size.x + GAP
	var box := _bounds(model, Transform3D.IDENTITY)
	for piece: Node3D in model.get_children():
		piece.position -= box.get_center()
	box.position -= box.get_center()
	return [model, box, minf(1.0, SPAN / box.size.length())]


## One of the kit's things put together as it says, in the tree for a moment,
## as a run's kit is set down, so each device dresses itself as it would
## there. A plain one beside you comes with its batteries.
func _thing(from: Kit, id: StringName) -> Device:
	var spec: Dictionary = from.assembled.get(id, {"frame": id, "sockets": {}})
	var device := Catalog.device(spec.frame)
	add_child(device)
	var sockets := device.sockets()
	for k: int in spec.sockets:
		var fill: StringName = spec.sockets[k]
		if Catalog.PARTS.has(fill):
			_fit_part(device, Catalog.part(fill), sockets[k], from.charge)
		else:
			device.mount(_thing(from, fill), sockets[k])
	if not from.assembled.has(id) and from.beside.has(id):
		for socket in sockets:
			if socket.kind == &"battery":
				_fit_part(device, Catalog.part(&"battery"), socket, from.charge)
	return device


## The looks under a node, in the frame given for it.
static func _bounds(node: Node3D, frame: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	for look: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		var at := frame * (node.global_transform.affine_inverse() * look.global_transform) * look.get_aabb()
		box = at if first else box.merge(at)
		first = false
	return box


static func _fit_part(device: Device, part: Part, socket: Socket, charge: float) -> void:
	var cell := part as Battery
	if cell != null:
		cell.charge_wh = cell.capacity() * charge
	device.fit(part, socket)
	if cell != null:
		cell.show_charge()


func _process(delta: float) -> void:
	if camera == null:
		return
	var top := ui.top() if ui != null else null
	var aside := top != null and top.side
	_slide = move_toward(_slide, 1.0 if aside else 0.0, delta / SLIDE_SECONDS)
	# The old kit shrinks away and the new one grows in its place.
	var want := picked if aside and picked != null else home
	if want != kit:
		_grown = move_toward(_grown, 0.0, delta * 2.0 / SWAP_SECONDS)
		if _grown == 0.0:
			_show(want)
	else:
		_grown = move_toward(_grown, 1.0, delta * 2.0 / SWAP_SECONDS)
	_model.scale = Vector3.ONE * _fit * maxf(smoothstep(0.0, 1.0, _grown), 0.01)
	_tilt = _tilt.lerp(aim, 1.0 - exp(-EASE * delta))
	if not _dragging:
		_spin += _spinning * delta
		_spinning *= exp(-SPIN_SETTLE * delta)
	# Its face turns toward the mouse, in the camera's frame.
	var tilt := Basis(Vector3.UP, deg_to_rad(_tilt.x * MAX_TILT)) \
		* Basis(Vector3.RIGHT, deg_to_rad(_tilt.y * MAX_TILT))
	var rest := Basis(Vector3.RIGHT, deg_to_rad(TIP)) * Basis(Vector3.UP, deg_to_rad(YAW + _spin))
	global_transform = camera.global_transform \
		* Transform3D(tilt * rest, AT.lerp(_aside_at(), smoothstep(0.0, 1.0, _slide)))


## Aside: as far across the screen as ASIDE says, as high and as far off as at home.
func _aside_at() -> Vector3:
	var view := get_viewport().get_visible_rect().size
	var ray := camera.project_local_ray_normal(Vector2(view.x * ASIDE, view.y * 0.5))
	return Vector3(ray.x * AT.z / ray.z, AT.y, AT.z)


## A press on it while the main menu is up, and not on one of its words,
## spins it; nothing reaches the menu meanwhile.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var half := get_viewport().get_visible_rect().size * 0.5
		aim = ((motion.position - half) / half).clamp(-Vector2.ONE, Vector2.ONE)
		# A release the window never heard, as it lost focus, lets go too.
		_dragging = _dragging and motion.button_mask & MOUSE_BUTTON_MASK_LEFT != 0
		if _dragging:
			_spin += motion.relative.x * SPIN_PER_PX
			_spinning = motion.velocity.x * SPIN_PER_PX
			get_viewport().set_input_as_handled()
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not button.pressed and _dragging:
		_dragging = false
		get_viewport().set_input_as_handled()
	elif button.pressed and _grabbable(button.position):
		_dragging = true
		_spinning = 0.0
		get_viewport().set_input_as_handled()


func _grabbable(at: Vector2) -> bool:
	var menu := ui.top() if ui != null else null
	if menu == null or not menu.root or not menu.visible or ui.is_fading() \
			or get_viewport().gui_get_hovered_control() is BaseButton:
		return false
	var into := _model.global_transform.affine_inverse()
	return _box.intersects_ray(into * camera.project_ray_origin(at),
		into.basis * camera.project_ray_normal(at)) != null
