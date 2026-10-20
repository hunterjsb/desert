class_name Bedroll
extends Device
## A bedroll: laid on the sand, carried, or stuck on a deck. Use on it,
## laid, stuck or among what you carry, asks how long to sleep (Sleep); in
## your hands, use lays it out, whatever the camp is doing: only sleeping
## waits for a still camp. Laid, it unrolls flat away from its head over a
## moment; taken, it rolls back up where it lay before it's in your hands.
## Only its look unrolls: its body stays the roll, under the pillow at its head.

## Looking at nothing in reach flat enough to lie on, it's laid this far
## ahead of your feet, m; flat enough is a normal this near straight up.
const FEET := 0.8
const FLAT := 0.7
## It unrolls over this long, s, and rolls up over this; laid, it rolls
## itself up if it's tipped this far, rad, past any slope of sand.
const UNROLLS := 1.1
const ROLLS_UP := 0.6
const TIPS := 0.8

## Laid out flat, or rolled: a save keeps which, and it comes back that way,
## not unrolling again.
var laid := false:
	set(to):
		laid = to
		_open = 1.0 if to else 0.0
		_left = false
		_show()

## How far it's unrolled, 0 to 1, as it goes.
var _open := 0.0
## Rolling up where it lay after it was taken: its look stays there.
var _left := false
var _laid_at := Transform3D()
## The unrolled look, under a plain node so what your hands copy of what you
## hold is only the roll.
var _spread := Node3D.new()
var _spread_view := MeshInstance3D.new()


func _init() -> void:
	carryable = true
	_spread.visible = false
	_spread.add_child(_spread_view)
	add_child(_spread)


func interact(by: Player) -> bool:
	if wrecked():
		return false
	return world.sleep.offer(by)


## In your hands, use lays it out where you look, its head there and across
## you, so it unrolls away from you; or at your feet.
func use(by: Player, at: Vector3) -> bool:
	var hands := by.hands
	var facing := Basis(Vector3.UP, by.global_rotation.y)
	var spot := at
	if hands.meets(Tuning.current().reach) == INF or hands.look_normal.y < FLAT:
		spot = by.global_position - facing.z * FEET
		spot.y = world.height_under(spot)
	hands.drop()
	global_transform = Transform3D(facing * Basis(Vector3.UP, PI / 2.0), spot + Vector3.UP * rest_height())
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	laid = true
	_open = 0.0
	_laid_at = global_transform
	_show()
	Sounds.play_at(self, Sounds.SAND_PUT)
	Sounds.play_at(self, Sounds.BAG_OPEN)
	return true


## How far its look is unrolled, 0 to 1.
func opened() -> float:
	return _open


func painted() -> Array[MeshInstance3D]:
	var views := super()
	views.append(_spread_view)
	return views


func _process(delta: float) -> void:
	if laid:
		var taken := _taken()
		if taken or global_basis.y.dot(Vector3.UP) < cos(TIPS):
			_roll_up(taken)
		else:
			_laid_at = global_transform
	var to := 1.0 if laid else 0.0
	if _open != to:
		_open = move_toward(_open, to, delta / (UNROLLS if laid else ROLLS_UP))
		_show()


## In your hands, on you or stuck on a deck: not lying where it was laid.
func _taken() -> bool:
	return collision_layer == 0 or host() != null


## Rolls back up from as far as it's unrolled; taken, where it lay.
func _roll_up(taken: bool) -> void:
	var was := _open
	laid = false
	_open = was
	_left = taken
	if taken:
		_spread.top_level = true
		_spread.global_transform = _laid_at
	_show()
	Sounds.play_at(self, Sounds.BAG_CLOSE)


## The roll's own look rolled, else the spread's at how far it's gone, eased
## as a roll slows once it's given its push.
func _show() -> void:
	var spread := _open > 0.0
	if frame_view != null:
		frame_view.visible = not spread
	_spread.visible = spread
	if spread:
		_spread_view.mesh = Dress.bedroll(1.0 - (1.0 - _open) * (1.0 - _open))
	elif _left or _spread.top_level:
		_left = false
		_spread.top_level = false
		_spread.transform = Transform3D.IDENTITY
