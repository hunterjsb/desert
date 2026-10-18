class_name Showpiece
extends Node3D
## The main menu's prop: the piece of the origin you last came as, put
## together as a new run's is, floating in the foreground and tilting toward
## the mouse, as the prototype's shield and radio did; dragged, it spins.
## Under every menu over the main menu it slides aside, right of the words,
## and shows what that menu says: an origin's piece, or your last camp as the
## save holds it. Only what you see of it is kept, never a body, so it can't
## fall, blow away or be saved. It stands in the desert's own light and
## weather, and once that light is low a soft light of its own keeps its
## shape and colours, the night left dark round it.

## Where it floats in the camera's view, m: between the title and the words.
const AT := Vector3(0.0, -0.06, -2.8)
## Aside, its middle stands this far across the screen from the left, and
## this far up from home, m, clear of the list under it.
const ASIDE := 0.68
const ASIDE_RISE := 0.12
## How long it takes to slide aside or home, and to swap one piece for another, s.
const SLIDE_SECONDS := 0.6
const SWAP_SECONDS := 0.3
## A piece wider corner to corner than this, m, is shown smaller, to fit where the crate does.
const SPAN := 2.4
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
## What a menu shows aside for your last camp.
const CAMP := &"camp"
## The camp: the thing of yours nearest where you stood and what stood within
## this of it, m, this many at most.
const CAMP_REACH := 12.0
const CAMP_MOST := 8
## Its own light is on a render layer only it stands on, so none reaches the
## desert. Seen as bright as this, it comes up as the desert's light falls
## below DUSK (Weather.seen_light).
const LAYER := 1 << 19
const GLOW := 0.5
const DUSK := 0.2

var ui: UIRoot
var camera: Camera3D
## The kit it shows on the main menu.
var home: Kit
## What it shows now: an origin's piece by its id, or CAMP.
var shown := &""
## Where the mouse is, -1 to 1 across the screen from its middle. Until it
## moves, and once it leaves the window, it rests facing you.
var aim := Vector2.ZERO
var _model: Node3D
## Its bounds about its middle, which it turns round.
var _box: AABB
## How much smaller it's shown than it is, to fit.
var _fit := 1.0
## Each piece's looks, its bounds and fit, built the first time it's shown.
var _built := {}
## 0 at home to 1 aside; and how far the piece shown has grown in, 0 to 1.
var _slide := 0.0
var _grown := 1.0
var _tilt := Vector2.ZERO
var _spin := 0.0
var _spinning := 0.0
var _dragging := false
var _light: DirectionalLight3D
var _world: World


func _ready() -> void:
	_world = World.of(self)
	if home == null:
		home = Kit.standard()
	_light = DirectionalLight3D.new()
	_light.light_cull_mask = LAYER
	_light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_light.shadow_enabled = false
	_light.top_level = true
	add_child(_light)
	_show(home.id)
	get_window().mouse_exited.connect(func() -> void: aim = Vector2.ZERO)
	# In place at once, never a frame at the world's origin.
	_process(0.0)


## Builds your last camp from a save's data, to show aside for CAMP.
func show_camp(data: Dictionary) -> void:
	if _built.has(CAMP):
		var old: Node3D = _built[CAMP][0]
		if old == _model:
			_model = null
		old.free()
	_built[CAMP] = _camp(data)
	if shown == CAMP:
		shown = &""


## Under the menu on top, if it's one over the main menu: the one state
## every such menu shares.
func aside() -> bool:
	var top := ui.top() if ui != null else null
	return top != null and top.side


func _show(next: StringName) -> void:
	if _model != null:
		_model.visible = false
	if not _built.has(next):
		_built[next] = _build(Kit.named(next))
	var built: Array = _built[next]
	_model = built[0]
	_box = built[1]
	_fit = built[2]
	_model.visible = true
	shown = next


## The kit's piece built for real, its batteries' lights showing; then only
## its looks kept: the bodies go.
func _build(from: Kit) -> Array:
	var device := _thing(from, from.shown)
	_light_up(device)
	var piece := _looks(device)
	piece.basis = Basis(Vector3.UP, deg_to_rad(from.shown_turn))
	return _framed([piece])


## The camp as the save holds it, each thing with its state and what's
## seated in it, as they stood round you, seen from where you stood.
func _camp(data: Dictionary) -> Array:
	var snapshot := Snapshot.new(null)
	var made := snapshot.camp(data, CAMP_REACH, CAMP_MOST)
	for each: Array in made:
		add_child(each[0])
	snapshot.dress()
	var pieces: Array[Node3D] = []
	var middle := Vector3.ZERO
	for each: Array in made:
		_light_up(each[0])
		var piece := _looks(each[0])
		piece.transform = each[1]
		pieces.append(piece)
		middle += piece.position / made.size()
	# Toward the camp's middle from where you stood; standing in it, as you faced.
	var toward := Vector2(middle.x, middle.z)
	var facing := atan2(-toward.x, -toward.y) if toward.length() > 1.0 else 0.0
	for piece in pieces:
		piece.transform = Transform3D(Basis(Vector3.UP, -deg_to_rad(YAW) - facing), Vector3.ZERO) * piece.transform
	return _framed(pieces)


## Pieces as one model about its middle, and how much smaller it's shown to fit.
func _framed(pieces: Array[Node3D]) -> Array:
	var model := Node3D.new()
	add_child(model)
	for piece in pieces:
		piece.reparent(model, false)
	var box := _bounds(model, Transform3D.IDENTITY)
	for piece in pieces:
		piece.position -= box.get_center()
	box.position -= box.get_center()
	return [model, box, minf(1.0, SPAN / maxf(box.size.length(), 0.01))]


## A device and what's seated on it, their batteries' lights as they hold.
static func _light_up(device: Device) -> void:
	for each: Device in [device] + device.mounted():
		if each.charge_light != null:
			ChargeLight.paint(each.charge_light, each.charge_share())


## A device's looks, in its own frame, under a node of their own, on the
## prop's render layer; the device is freed. What drives a look, such as a
## rotor's spin, and a picture drawn live, a Console's screen, go with it.
func _looks(device: Device) -> Node3D:
	var piece := Node3D.new()
	add_child(piece)
	var to_device := device.global_transform.affine_inverse()
	for look: GeometryInstance3D in device.find_children("*", "GeometryInstance3D", true, false):
		var drawn := look.material_override as BaseMaterial3D
		if look.is_visible_in_tree() and not (drawn != null and drawn.albedo_texture is ViewportTexture):
			var pose := to_device * look.global_transform
			look.set_script(null)
			look.get_parent().remove_child(look)
			piece.add_child(look)
			look.transform = pose
			look.layers |= LAYER
	device.free()
	return piece


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
	var away := aside()
	_slide = move_toward(_slide, 1.0 if away else 0.0, delta / SLIDE_SECONDS)
	# The old piece shrinks away and the new one grows in its place.
	var want: StringName = top.shows if away and top.shows != &"" else home.id
	if want == CAMP and not _built.has(CAMP):
		want = home.id
	if want != shown or _model == null:
		_grown = move_toward(_grown, 0.0, delta * 2.0 / SWAP_SECONDS)
		if _grown == 0.0 or _model == null:
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
	_glow()


## A soft key light from over your left shoulder, as bright to the eye
## whatever it's opened to, coming up as the desert's light goes.
func _glow() -> void:
	_light.global_basis = camera.global_basis * Basis.looking_at(Vector3(0.45, -0.5, -1.0))
	if _world == null:
		return
	var weather := _world.weather
	var dark := 1.0 - smoothstep(0.0, DUSK, weather.seen_light)
	_light.light_energy = GLOW * dark / weather.eye.exposure()
	_light.visible = dark > 0.0


## Aside: as far across the screen as ASIDE says, a little higher, as far off as at home.
func _aside_at() -> Vector3:
	var view := get_viewport().get_visible_rect().size
	var ray := camera.project_local_ray_normal(Vector2(view.x * ASIDE, view.y * 0.5))
	return Vector3(ray.x * AT.z / ray.z, AT.y + ASIDE_RISE, AT.z)


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
