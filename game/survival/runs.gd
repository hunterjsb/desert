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
## What's beside you lies in a row this far ahead, this far apart, m.
const KIT_AHEAD := 2.0
const KIT_APART := 1.2

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


## The kit's things on the sand beside where you begin, every battery in them
## as full as the kit says, cabled together if it says so: all it made.
static func kit(world: World, from: Kit = Kit.standard()) -> Array[Node]:
	var made: Array[Node] = []
	var ids: Array[StringName] = []
	for id in from.beside:
		for i in from.beside[id]:
			ids.append(id)
	var powered: Array[Device] = []
	for k in ids.size():
		var where := [(k - (ids.size() - 1) * 0.5) * KIT_APART, KIT_AHEAD]
		var id := ids[k]
		var lying := Transform3D(Basis(Vector3.UP, world.player.global_rotation.y) * Basis(Vector3.RIGHT, -PI / 2.0),
			_beside(world, where) + Vector3.UP * 0.02)
		if id == &"coil":
			var line := Line.make(world, from.rope_m)
			line.coil.global_transform = lying
			made.append_array([line, line.coil])
			continue
		if Catalog.PARTS.has(id):
			var part := Catalog.part(id)
			world.content.add_child(part)
			part.global_transform = lying
			made.append(part)
			continue
		var device := Catalog.device(id)
		_set_down(world, device, where)
		for socket in device.sockets():
			if socket.kind == &"battery":
				var cell := Catalog.part(&"battery") as Battery
				cell.charge_wh = cell.capacity() * from.charge
				world.content.add_child(cell)
				device.fit(cell, socket)
				cell.show_charge()
		if _socket(device, &"port") != null:
			powered.append(device)
		made.append(device)
	for k in range(1, powered.size() if from.wired else 0):
		var cable := Catalog.cable(world, _beside(world, [0.0, KIT_AHEAD * 0.7]))
		powered[0].fit(cable.plugs[0], _socket(powered[0], &"port"))
		powered[k].fit(cable.plugs[1], _socket(powered[k], &"port"))
		made.append(cable)
	return made


## A place on the sand right and ahead of where the run begins, facing as you do.
static func _beside(world: World, where: Array) -> Vector3:
	var start := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	var facing := Basis(Vector3.UP, world.player.global_rotation.y)
	var at: Vector3 = start + facing.x * where[0] - facing.z * where[1]
	at.y = world.height_under(at)
	return at


static func _set_down(world: World, device: Device, where: Array) -> void:
	var at := _beside(world, where)
	world.content.add_child(device)
	device.global_transform = Transform3D(Basis(Vector3.UP, world.player.global_rotation.y),
		at + Vector3.UP * (Finds.bounds(device).size.y * 0.5 + 0.02))


static func _socket(device: Device, kind: StringName) -> Socket:
	for socket in device.sockets():
		if socket.kind == kind and socket.is_open():
			return socket
	return null
