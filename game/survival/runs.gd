class_name Runs
extends Node
## One run at a time. When you die the run is over: the world goes, with
## everything you had in it, and a fresh one on a new seed takes its place,
## so nothing carries over. It sits beside the world, never in it. Every run
## starts with the kit on the sand beside you, as well as the suit's.

signal started(world: World)
## The run's kit is down beside you.
signal equipped(world: World)

const WORLD := preload("res://game/world/world.tscn")
## The word that the last run is over shows this long, s.
const CAPTION_SECONDS := 4.0
## The kit, right and ahead of you, m: the base shield with a full battery,
## switched off, and the light solar panel cabled into it, so the sun keeps
## its battery up.
const KIT_SHIELD := [0.8, 2.0]
const KIT_PANEL := [-1.0, 2.2]

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
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 6)
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
	if is_instance_valid(at) and not at.is_queued_for_deletion():
		# Kept on the world, so a dev scenario can clear it for its own.
		at.set_meta(&"kit", kit(at))
		equipped.emit(at)


## The run's kit on the sand beside where you begin: [shield, panel, cable].
static func kit(world: World) -> Array[Node]:
	var shield := Catalog.device(&"shield")
	_set_down(world, shield, KIT_SHIELD)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	shield.fit(cell, _socket(shield, &"battery"))
	var panel := Catalog.device(&"light_panel")
	_set_down(world, panel, KIT_PANEL)
	var cable := Catalog.cable(world, _beside(world, [0.0, 1.4]))
	shield.fit(cable.plugs[0], _socket(shield, &"port"))
	panel.fit(cable.plugs[1], _socket(panel, &"port"))
	return [shield, panel, cable]


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
