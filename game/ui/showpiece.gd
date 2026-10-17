class_name Showpiece
extends Node3D
## The main menu's starting crate, put together as a new run's kit has it,
## floating in the foreground and tilting toward the mouse, as the
## prototype's shield and radio did; dragged, it spins. Only what you see of
## it is kept, never a body, so it can't fall, blow away or be saved, and it
## stands in the desert's own light and weather.

## The kit's assembly it shows.
const SHOWN := &"floating_crate"
## Where it floats in the camera's view, m: between the title and the words.
const AT := Vector3(0.0, -0.06, -2.8)
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
var _model := Node3D.new()
## Where the mouse is, -1 to 1 across the screen from its middle. Until it
## moves, and once it leaves the window, it rests facing you.
var aim := Vector2.ZERO
## Its bounds about its middle, which it turns round.
var _box: AABB
var _tilt := Vector2.ZERO
var _spin := 0.0
var _spinning := 0.0
var _dragging := false


func _ready() -> void:
	add_child(_model)
	_build(Kit.standard())
	get_window().mouse_exited.connect(func() -> void: aim = Vector2.ZERO)
	# In place at once, never a frame at the world's origin.
	_process(0.0)


## The kit's crate built for real, its batteries' lights showing, then only
## its looks kept: the bodies go.
func _build(kit: Kit) -> void:
	var spec: Dictionary = kit.assembled[SHOWN]
	var crate := Catalog.device(spec.frame)
	# In the tree for a moment, as a run's kit is set down, so each device
	# dresses itself as it would there.
	add_child(crate)
	var sockets := crate.sockets()
	for k: int in spec.sockets:
		var id: StringName = spec.sockets[k]
		if Catalog.PARTS.has(id):
			_fit(crate, Catalog.part(id), sockets[k], kit.charge)
		else:
			var seated := Catalog.device(id)
			add_child(seated)
			# Set down beside you, a device comes with its batteries.
			if kit.beside.has(id):
				for socket in seated.sockets():
					if socket.kind == &"battery":
						_fit(seated, Catalog.part(&"battery"), socket, kit.charge)
			crate.mount(seated, sockets[k])
	for device: Device in [crate] + crate.mounted():
		if device.charge_light != null:
			ChargeLight.paint(device.charge_light, device.charge_share())
	var to_crate := crate.global_transform.affine_inverse()
	for look: GeometryInstance3D in crate.find_children("*", "GeometryInstance3D", true, false):
		if look.is_visible_in_tree():
			var pose := to_crate * look.global_transform
			look.get_parent().remove_child(look)
			_model.add_child(look)
			look.transform = pose
	crate.free()
	var looks := _model.get_children()
	_box = looks[0].transform * looks[0].get_aabb()
	for look: GeometryInstance3D in looks:
		_box = _box.merge(look.transform * look.get_aabb())
	for look: Node3D in looks:
		look.position -= _box.get_center()
	_box.position -= _box.get_center()


static func _fit(device: Device, part: Part, socket: Socket, charge: float) -> void:
	var cell := part as Battery
	if cell != null:
		cell.charge_wh = cell.capacity() * charge
	device.fit(part, socket)
	if cell != null:
		cell.show_charge()


func _process(delta: float) -> void:
	if camera == null:
		return
	_tilt = _tilt.lerp(aim, 1.0 - exp(-EASE * delta))
	if not _dragging:
		_spin += _spinning * delta
		_spinning *= exp(-SPIN_SETTLE * delta)
	# Its face turns toward the mouse, in the camera's frame.
	var tilt := Basis(Vector3.UP, deg_to_rad(_tilt.x * MAX_TILT)) \
		* Basis(Vector3.RIGHT, deg_to_rad(_tilt.y * MAX_TILT))
	var rest := Basis(Vector3.RIGHT, deg_to_rad(TIP)) * Basis(Vector3.UP, deg_to_rad(YAW + _spin))
	global_transform = camera.global_transform * Transform3D(tilt * rest, AT)


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
