class_name CrowsNest
extends Helm
## A crow's nest: a lookout's basket on a mast's head, its rope ladder hung
## down the mast. Use on it climbs you in, a seat as the helm is: you ride
## the camp up there, your weight its, high up, so it heels and tips the
## camp as anything that heavy that high does. Standing in it your eyes are
## the mast's height over the deck, over the crests round you, so what
## they hid shows: a glint, a plume, a front. It steers nothing.

## Where your feet go in it, and where your weight sits, in its own frame.
const NEST_FEET := Vector3(0.0, -0.45, 0.0)
const NEST_MIDDLE := Vector3(0.0, 0.45, 0.0)
## Its ladder hangs this far below its floor, m, short of the deck.
const LADDER := 3.4
const NEST_HOW_TO := "crows_nest"
const NEST_HOW_TO_SAYS := "Up in the crow's nest you ride the camp and see over the dunes round it.\n" \
	+ "Its weight and yours are high up the mast: a hard gust heels it further. {ride} climbs you down."

var _ladder: MeshInstance3D
var _rungs: CollisionShape3D


func _ready() -> void:
	super()
	_ladder = MeshInstance3D.new()
	_ladder.mesh = NomadLooks.ladder()
	_ladder.visible = false
	add_child(_ladder)


func _physics_process(delta: float) -> void:
	super(delta)
	var mast := host() as Mast
	var down := mast != null and mast.standing()
	_ladder.visible = down
	if down == (_rungs != null):
		return
	if down:
		_rungs = CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.3, LADDER, 0.05)
		_rungs.shape = shape
		_rungs.position = Vector3(0.0, NEST_FEET.y - 0.05 - LADDER * 0.5, -0.15)
		add_child(_rungs)
	else:
		remove_child(_rungs)
		if is_instance_valid(_rungs):
			_rungs.queue_free()
		_rungs = null


func _init() -> void:
	steers = false
	sits = false


## Up the ladder and into the basket, empty-handed, once it's on a mast.
func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	if rider == by:
		by.stand_up()
		return true
	if not host() is Mast or carrier() == null:
		return by.hands.refuse("put it on a mast's head")
	return by.sit(self)


func feet() -> Vector3:
	return global_transform * NEST_FEET


## It sits on its basket's floor: the ladder hangs below the face it's on.
func seat() -> Transform3D:
	var size: Vector3 = Catalog.DEVICES[&"crows_nest"].size
	return Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, 0.0, size.y * 0.5))


func how_to() -> Array[String]:
	return [NEST_HOW_TO, NEST_HOW_TO_SAYS]


func _frame_masses() -> Array:
	var frames: Array = [[frame_mass, frame_middle]]
	if rider != null:
		frames.append([world.tuning.player_mass if world != null else 90.0, NEST_MIDDLE])
	return frames
