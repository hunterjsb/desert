class_name Runs
extends Node
## One run at a time. When you die the run is over: the world goes, with
## everything you had in it, and a fresh one on a new seed takes its place,
## so nothing carries over. It sits beside the world, never in it. Every run
## starts with its kit (Kit, data): some in the suit's slots, the rest on the
## sand beside you.

signal started(world: World)

const WORLD := preload("res://game/world/world.tscn")
## The word that the last run is over shows this long, s.
const CAPTION_SECONDS := 4.0
## A run begins on a clear morning with the first storm due in three to eight
## minutes, facing where it will come from: time to set the kit up and batten
## down, not a storm on arrival.
const START := {"key": "start", "kind": "clear", "day": [0.25, 0.45], "due": [180.0, 480.0]}

## Runs since the game began, this one included.
var count := 1
var _caption: Label
var _shown := INF


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 102
	add_child(layer)
	_caption = Label.new()
	_caption.text = "You died. A new run."
	_caption.theme_type_variation = &"Caption"
	_caption.uppercase = true
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.modulate.a = 0.0
	layer.add_child(_caption)
	_watch()
	_equip(world())


func world() -> World:
	return get_node("../World")


func _watch() -> void:
	world().player.vitals.died.connect(_over, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _over() -> void:
	# Death ends the run, and its save with it.
	var saves := get_node_or_null(^"/root/Saves")
	if saves != null:
		saves.delete()
	var old := world()
	var parent := old.get_parent()
	var at := old.get_index()
	parent.remove_child(old)
	old.queue_free()
	var next: World = WORLD.instantiate()
	next.run_seed = randi_range(1, 0x7fffffff)
	next.name = "World"
	parent.add_child(next)
	parent.move_child(next, at)
	count += 1
	Dev.clear()
	Dev.put("world/run", "%d" % count)
	_shown = 0.0
	_watch()
	started.emit(next)
	_equip(next)


func _process(delta: float) -> void:
	_shown += delta
	_caption.modulate.a = clampf(CAPTION_SECONDS - _shown, 0.0, 1.0)


## Sets the kit down once the sand under it is solid: before, it would be
## frozen or forgotten.
func _equip(at: World) -> void:
	while is_instance_valid(at) and not at.is_queued_for_deletion() \
			and not at.terrain.is_settled_around(at.spawn.x, at.spawn.y):
		await get_tree().physics_frame
	# A resumed run has its own things already, and its own moment.
	if is_instance_valid(at) and not at.is_queued_for_deletion() and not at.has_meta(&"resumed"):
		_begin(at)
		# Kept on the world, so a dev scenario can clear it for its own.
		at.set_meta(&"kit", kit(at))


## Puts a new run at its starting moment, unless a dev scenario sets its own.
func _begin(at: World) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			return
	var place := Scenarios.find(at, START)
	if not place.is_empty():
		at.respawn(place.x, place.z, place.yaw, place.time)


## The kit's things beside where you begin, each at its place, put together
## as it says, every battery as full as it says, a floater floating, and its
## lines laid: all it made.
static func kit(world: World, from: Kit = Kit.standard()) -> Array[Node]:
	var made: Array[Node] = []
	var named := {}
	for id in from.beside:
		var where: Vector2 = from.beside[id]
		var lying := Transform3D(Basis(Vector3.UP, world.player.global_rotation.y) * Basis(Vector3.RIGHT, -PI / 2.0),
			_beside(world, where) + Vector3.UP * 0.02)
		if id == &"coil":
			var line := Line.make(world, from.rope_m)
			line.coil.global_transform = lying
			made.append_array([line, line.coil])
		elif id == &"stake":
			var stake := Catalog.stake()
			world.content.add_child(stake)
			var at := _beside(world, where)
			stake.drive(at, at.y)
			named[id] = stake
			made.append(stake)
		elif Catalog.PARTS.has(id):
			var part := Catalog.part(id)
			world.content.add_child(part)
			part.global_transform = lying
			made.append(part)
		else:
			var spec: Dictionary = from.assembled.get(id, {"frame": id, "sockets": {}})
			var device := Catalog.device(spec.frame)
			_set_down(world, device, where)
			made.append(device)
			var sockets := device.sockets()
			var filling: Dictionary = spec.sockets
			for k: int in filling:
				if Catalog.PARTS.has(filling[k]):
					_fit(world, device, Catalog.part(filling[k]), sockets[k], from.charge)
				else:
					var seated := Catalog.device(filling[k])
					device.mount(seated, sockets[k])
					made.append(seated)
			# A plain device comes with its batteries.
			if not from.assembled.has(id):
				for socket in sockets:
					if socket.kind == &"battery":
						_fit(world, device, Catalog.part(&"battery"), socket, from.charge)
			_set_down(world, device, where)
			named[id] = device
	for id in from.lines:
		var a: Device = named[id]
		var b: Device = named[from.lines[id]]
		# Laid the way the wind will pull it, its tie toward the other end.
		var tie := a.free_tie(b.global_position)
		var want := b.global_position - a.global_position
		a.global_basis = Basis(Vector3.UP, atan2(want.x, want.z) - atan2(tie.position.x, tie.position.z))
		tie = a.free_tie(b.global_position)
		var other := b.free_tie(tie.global_position)
		var span := (tie.global_transform * Line.END_AT).distance_to(other.global_transform * Line.END_AT)
		made.append(Line.between(world, tie, other, maxf(from.rope_m - span, 0.0)))
	return made


## A place on the sand right and ahead of where the run begins, facing as you do.
static func _beside(world: World, where: Vector2) -> Vector3:
	var start := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	var facing := Basis(Vector3.UP, world.player.global_rotation.y)
	var at: Vector3 = start + facing.x * where.x - facing.z * where.y
	at.y = world.height_under(at)
	return at


## Facing as you do: resting on the sand, or held at the tray's height if it floats.
static func _set_down(world: World, device: Device, where: Vector2) -> void:
	var at := _beside(world, where)
	if device.get_parent() == null:
		world.content.add_child(device)
	var up := world.tuning.hover_height if device.stats().can_float \
		else -Finds.bounds(device).position.y + 0.02
	device.global_transform = Transform3D(Basis(Vector3.UP, world.player.global_rotation.y), at + Vector3.UP * up)


static func _fit(world: World, device: Device, part: Part, socket: Socket, charge: float) -> void:
	var cell := part as Battery
	if cell != null:
		cell.charge_wh = cell.capacity() * charge
	world.content.add_child(part)
	device.fit(part, socket)
	if cell != null:
		cell.show_charge()
