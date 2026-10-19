class_name Bedroll
extends Device
## A bedroll: laid on the sand, carried, or rolled on a crate's rack in the
## board's place. Use on it, laid, racked or among what you carry, asks how
## long to sleep (Sleep); in your hands, use lays it out, whatever the camp is
## doing: only sleeping waits for a still camp.

## Racked, it stands this far proud of the rack, m, along the crate's side.
const GAP := 0.01
## Looking at nothing in reach flat enough to lie on, it's laid this far
## ahead of your feet, m; flat enough is a normal this near straight up.
const FEET := 0.8
const FLAT := 0.7


func _init() -> void:
	carryable = true


func interact(by: Player) -> bool:
	if wrecked():
		return false
	return world.sleep.offer(by)


## In your hands, use lays it out where you look, fore and aft as you face,
## or at your feet.
func use(by: Player, at: Vector3) -> bool:
	var hands := by.hands
	var facing := Basis(Vector3.UP, by.global_rotation.y)
	var spot := at
	if hands.meets(Tuning.current().reach) == INF or hands.look_normal.y < FLAT:
		spot = by.global_position - facing.z * FEET
		spot.y = world.height_under(spot)
	hands.drop()
	global_transform = Transform3D(facing, spot + Vector3.UP * rest_height())
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	Sounds.play_at(self, Sounds.SAND_PUT)
	return true


## Racked, it lies along the rack as the board does, its length fore and aft.
func seat() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, Vector3.BACK, Vector3.RIGHT), Vector3(0.0, 0.0, super().origin.z + GAP))
