class_name Stoker
extends Node3D
## The furnace's state belongs to the run, not the streamed city. Fixtures
## hold real finite stock; claimed parts join the ordinary world and its saves.

var world: World
var site: HalloranSite
var _fixtures: Node3D
var _status: Label3D
var _door: StaticBody3D
var _light: OmniLight3D
var _fire: MeshInstance3D
var _sound: AudioStreamPlayer3D
var _stock: Array[Part] = []
var _cache: Array[Part] = []
var _poll := 0.0

func _ready() -> void:
	world = get_parent() as World
	add_to_group(&"stoker")
	world.origin_shifted.connect(_shifted)


## Fixtures live outside Content, so they must follow the floating origin in the same tick.
func _shifted(by: Vector2i) -> void:
	global_position -= Vector3(by.x, 0.0, by.y) * world.tuning.chunk_size


func _process(delta: float) -> void:
	advance(world)
	_poll -= delta
	if _poll <= 0.0:
		_poll = 0.5
		var found: HalloranSite
		for unit in world.shape.sites.units():
			for each in unit.sites:
				if each is HalloranSite and each.stands():
					found = each
		if found != site:
			_clear()
			site = found
		if site != null and _fixtures == null and site.ground >= 0:
			_build()
	if site == null or _fixtures == null:
		return
	var at := site.frame()
	at.origin.x = world.engine_x(at.origin.x)
	at.origin.z = world.engine_z(at.origin.z)
	global_transform = at
	var burning := active(world)
	_light.light_energy = (2.8 + 0.2 * sin(world.time * 3.0)) if burning else 0.1
	_fire.visible = burning
	if burning and not _sound.playing:
		_sound.play()
	elif not burning and _sound.playing:
		_sound.stop()
	var opened: bool = world.stoker_state.get("opened", false)
	_door.position.y = HalloranKit.CACHE.y + (3.8 if opened else 1.2)
	_status.text = "STOKER / BAY 02\n" + ("MAINTENANCE BURN\nPRESSURE STABLE" if burning else
		("BAY RELEASED\nQUOTA STILL OUTSTANDING" if opened else "FEED REQUIRED\nCOALCANE"))


static func active(of: World) -> bool:
	return of.stoker_state.get("until", -1.0) > of.time


static func advance(of: World) -> void:
	if of.stoker_state.get("fed", 0) > 0 and of.time >= of.stoker_state.get("until", INF):
		of.stoker_state["opened"] = true


## A fresh ray prevents interaction through a wall or from a stale aim point.
func interact(by: Player) -> bool:
	if _fixtures == null:
		return false
	var from := by.camera.global_position
	var ray := PhysicsRayQueryParameters3D.create(from, from - by.camera.global_basis.z * world.tuning.reach)
	ray.exclude = by.hands._exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or not hit.collider.has_meta(&"stoker_action"):
		return false
	var action: StringName = hit.collider.get_meta(&"stoker_action")
	return operate(by, action)


func operate(by: Player, action: StringName) -> bool:
	var hands := by.hands
	advance(world)
	if action == &"feed":
		if active(world):
			return hands.refuse("maintenance burn in progress")
		var fuel := hands.held
		if not is_instance_valid(fuel) or fuel.get_meta(&"catalog", &"") != &"coalcane_bundle":
			return hands.refuse("feed a preserved coalcane bundle")
		hands.stow()
		world.stoker_state["fed"] = world.stoker_state.get("fed", 0) + 1
		world.stoker_state["until"] = world.time + world.tuning.stoker_burn_s
		if is_instance_valid(fuel):
			fuel.queue_free()
		Deeds.done(world, &"first_fire")
		return true
	return false


## An old count represents the first slots taken; new claims may be in any order.
func claimed(bank: StringName) -> Array:
	var key := str(bank) + "_taken"
	if not world.stoker_state.has(key):
		world.stoker_state[key] = range(int(world.stoker_state.get(bank, 0)))
	return world.stoker_state[key]


## Called by the ordinary salvage pickup path, before the part enters the hand.
func claim(body: Node) -> void:
	if not body.has_meta(&"stoker_slot") or locked(body):
		return
	var slot: Array = body.get_meta(&"stoker_slot")
	var taken := claimed(slot[0])
	if not taken.has(slot[1]):
		taken.append(slot[1])
	world.stoker_state[slot[0]] = taken.size()
	body.remove_meta(&"stoker_slot")
	body.reparent(world.content)
	(body as RigidBody3D).freeze = false


## The same small-object aim assistance used by ordinary salvage includes these shelves.
func loose() -> Array[RigidBody3D]:
	var parts: Array[RigidBody3D] = []
	for part in _stock + _cache:
		if is_instance_valid(part) and part.has_meta(&"stoker_slot"):
			parts.append(part)
	return parts


func locked(body: Node) -> bool:
	return body != null and body.has_meta(&"stoker_slot") \
		and body.get_meta(&"stoker_slot")[0] == &"cache" and not world.stoker_state.get("opened", false)


## Fixture bodies belong to the previous snapshot, not the resumed stock state.
func recall() -> void:
	_clear()
	_poll = 0.0


func _place(bank: StringName, index: int, id: StringName, at: Vector3, turn := Basis.IDENTITY) -> void:
	if claimed(bank).has(index):
		return
	var part := Catalog.part(id)
	part.freeze = true
	part.set_meta(&"stoker_slot", [bank, index])
	_fixtures.add_child(part)
	var bounds := Transform3D(turn, Vector3.ZERO) * Finds.bounds(part)
	part.transform = Transform3D(turn, at - Vector3.UP * bounds.position.y)
	if bank == &"stock":
		_stock.append(part)
	else:
		_cache.append(part)


func _clear() -> void:
	_stock.clear()
	_cache.clear()
	if is_instance_valid(_fixtures):
		_fixtures.free()
	_fixtures = null


func _build() -> void:
	_fixtures = Node3D.new()
	add_child(_fixtures)
	var steel := Paint.coat(Paint.GUNMETAL, 0.6, 0.6)
	var rust := Paint.coat(Paint.RUST, 0.8, 0.4)
	var orange := Paint.coat(Paint.YELLOW, 0.6)
	var furnace := HalloranKit.FURNACE
	_furnace(furnace)
	# Approach from downhill (-X); the feed is on that face.
	_target(&"feed", furnace + Vector3(-2.65, 1.1, 0), Vector3(0.35, 1.6, 1.6), rust)
	_box(_fixtures, Vector3(0.08, 0.3, 1.7), furnace + Vector3(-2.85, 2, 0), orange)
	_box(_fixtures, Vector3(0.16, 1.1, 2.2), furnace + Vector3(-2.5, 3.0, 0), steel)
	_status = _label("", furnace + Vector3(-2.6, 3.0, 0), -PI / 2)
	_status.pixel_size = 0.0035
	_fire = _box(_fixtures, Vector3(0.08, 0.8, 1.1), furnace + Vector3(-2.86, 1.15, 0),
		Paint.coat(Color(1, 0.3, 0.03), 0, 0, 0.5, 0, 3.0))
	_light = OmniLight3D.new()
	_light.position = furnace + Vector3(-4, 2, 0)
	_light.light_color = Color(1, 0.36, 0.08)
	_light.omni_range = 16
	_fixtures.add_child(_light)
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = Sounds.RADIO_STOKER
	_sound.position = furnace
	_sound.max_distance = 65
	_sound.volume_db = -17
	_fixtures.add_child(_sound)
	var store := HalloranKit.STORE
	# Open shelves carry actual loose bundles, not an invisible dispenser target.
	_box(_fixtures, Vector3(3.4, 0.15, 1.7), store + Vector3(0, 1.0, 0), steel, true)
	for x in [-1.55, 1.55]:
		_box(_fixtures, Vector3(0.12, 1.8, 1.75), store + Vector3(x, 0.9, 0), rust, true)
	_box(_fixtures, Vector3(3.4, 0.4, 0.12), store + Vector3(0, 1.65, 0.85), steel, true)
	var stock_label := _label("PRESERVED COALCANE", store + Vector3(0, 1.65, -0.84), PI)
	stock_label.pixel_size = 0.003
	for k in world.tuning.stoker_stock:
		_place(&"stock", k, &"coalcane_bundle", store + Vector3(-1.0 + k * 0.65, 1.08, -0.35))
	var cache := HalloranKit.CACHE
	# The hatch encloses the stock on every side; its opening grants physical access.
	_box(_fixtures, Vector3(3.3, 0.25, 2.5), cache + Vector3(0, 0.1, 0), steel, true)
	_box(_fixtures, Vector3(3.3, 0.25, 2.5), cache + Vector3(0, 2.65, 0), steel, true)
	_box(_fixtures, Vector3(3.3, 2.5, 0.2), cache + Vector3(0, 1.4, 1.15), rust, true)
	for x in [-1.55, 1.55]:
		_box(_fixtures, Vector3(0.2, 2.5, 2.5), cache + Vector3(x, 1.4, 0), steel, true)
	_box(_fixtures, Vector3(3.0, 0.12, 2.2), cache + Vector3(0, 0.95, 0), steel, true)
	var cache_label := _label("SERVICE STOCK / BAY 02", cache + Vector3(0, 2.8, -1.3), PI)
	cache_label.pixel_size = 0.003
	_place(&"cache", 0, &"big_battery", cache + Vector3(-0.85, 1.015, -0.5))
	_place(&"cache", 1, &"solar_panel", cache + Vector3(0.15, 1.015, -0.5), Basis(Vector3.UP, PI))
	_place(&"cache", 2, &"sealant", cache + Vector3(1.0, 1.015, -0.5))
	for x in [-1.7, 1.7]:
		_box(_fixtures, Vector3(0.16, 5.4, 0.28), cache + Vector3(x, 2.7, -1.0), steel, true)
	_box(_fixtures, Vector3(3.7, 0.25, 0.4), cache + Vector3(0, 5.4, -1.0), rust, true)
	_door = StaticBody3D.new()
	_door.position = cache + Vector3(0, 1.2, -1.0)
	_fixtures.add_child(_door)
	_box(_door, Vector3(2.9, 2.65, 0.25), Vector3.ZERO, orange, true)
	for x in [-1.3, 1.3]:
		_box(_door, Vector3(0.1, 2.3, 0.1), Vector3(x, 0, -0.2), steel)
	_box(_door, Vector3(0.45, 0.12, 0.2), Vector3(0, 0, -0.25), steel)


func _target(action: StringName, at: Vector3, size: Vector3, coat: Paint.Coat) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.set_meta(&"stoker_action", action)
	_fixtures.add_child(body)
	_box(body, size, Vector3.ZERO, coat, true)


func _box(parent: Node3D, size: Vector3, at: Vector3, coat: Paint.Coat, solid := false) -> MeshInstance3D:
	var b := Paint.Pieces.new()
	b.box(size, Vector3.ZERO, coat, 0.04)
	var view := MeshInstance3D.new()
	view.mesh = b.commit()
	view.position = at
	parent.add_child(view)
	if solid:
		var solid_parent := parent as CollisionObject3D
		if solid_parent == null:
			solid_parent = StaticBody3D.new()
			parent.add_child(solid_parent)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.position = at
		solid_parent.add_child(shape)
	return view


func _label(words: String, at: Vector3, yaw: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font_size = 40
	label.pixel_size = 0.008
	label.position = at
	label.rotation.y = yaw
	label.modulate = Color(0.85, 0.7, 0.35)
	label.outline_size = 3
	_fixtures.add_child(label)
	return label


func _furnace(at: Vector3) -> void:
	var b := Paint.Pieces.new()
	var iron := Paint.coat(Paint.GUNMETAL, 0.8, 0.7, 0.65)
	var rust := Paint.coat(Paint.RUST, 0.9, 0.5, 0.75)
	var ceramic := Paint.coat(Paint.CERAMIC, 0.8, 0, 0.95)
	var brass := Paint.coat(Paint.BRASS, 0.7, 0.7)
	b.drum(2.4, 4.5, Vector3(0, 2.5, 0), iron, Basis.IDENTITY, 20)
	b.drum(2.7, 0.6, Vector3(0, 0.3, 0), ceramic, Basis.IDENTITY, 20)
	b.drum(2.6, 0.4, Vector3(0, 4.8, 0), rust, Basis.IDENTITY, 20)
	b.drum(1.1, 4.0, Vector3(0, 7, 0), iron, Basis.IDENTITY, 12)
	for y in [0.8, 2.1, 4.3, 6.0, 8.5]:
		var r := 2.48 if y < 5 else 1.2
		b.drum(r, 0.16, Vector3(0, y, 0), rust, Basis.IDENTITY, 20)
	for k in 16:
		var a := k * TAU / 16
		var v := Vector3(cos(a), 0, sin(a))
		for y in [0.8, 4.3]:
			b.box(Vector3(0.18, 0.25, 0.18), v * 2.52 + Vector3.UP * y, brass, 0.025)
	# Heat tiles, inspection gauge and a much later hand-made repair band.
	for z in [-1.0, 1.0]:
		b.box(Vector3(0.25, 2.5, 0.3), Vector3(-2.3, 1.6, z), ceramic, 0.04)
	b.drum(0.3, 0.15, Vector3(-2.45, 3.9, 0), brass, Basis(Vector3.FORWARD, PI / 2), 16)
	b.box(Vector3(0.1, 0.35, 0.04), Vector3(-2.55, 3.9, 0), iron, 0.01)
	for side in [-1.0, 1.0]:
		b.drum(0.32, 3.0, Vector3(1.7, 2.5, side * 2.6), rust, Basis.IDENTITY, 10)
		b.drum(0.46, 0.18, Vector3(1.7, 1.2, side * 2.6), brass, Basis.IDENTITY, 10)
	var view := MeshInstance3D.new()
	view.mesh = b.commit()
	view.position = at
	_fixtures.add_child(view)
	var body := StaticBody3D.new()
	body.position = at + Vector3(0, 2.5, 0)
	var collision := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 2.4
	cylinder.height = 5
	collision.shape = cylinder
	body.add_child(collision)
	_fixtures.add_child(body)
