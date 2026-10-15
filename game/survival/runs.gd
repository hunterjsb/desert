class_name Runs
extends Node
## One run at a time. When you die the run is over: the world goes, with
## everything you had in it, and a fresh one on a new seed takes its place,
## so nothing carries over. It sits beside the world, never in it.

signal started(world: World)

const WORLD := preload("res://game/world/world.tscn")
## The word that the last run is over shows this long, s.
const CAPTION_SECONDS := 4.0

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


func _process(delta: float) -> void:
	_shown += delta
	_caption.modulate.a = clampf(CAPTION_SECONDS - _shown, 0.0, 1.0)
