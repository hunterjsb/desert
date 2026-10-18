class_name Bedroll
extends Device
## A bedroll: laid on the sand, carried, or rolled on a crate's rack in the
## board's place. Use on it, wherever it is, in your hands or among what you
## carry, asks how long to sleep (Sleep).

## Racked, it stands this far proud of the rack, m, along the crate's side.
const GAP := 0.01


func _init() -> void:
	carryable = true


func interact(by: Player) -> bool:
	if wrecked():
		return false
	return world.sleep.offer(by, self)


## Use in your hands asks the same.
func use(by: Player, _at: Vector3) -> bool:
	return interact(by)


## Racked, it lies along the rack as the board does, its length fore and aft.
func seat() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, Vector3.BACK, Vector3.RIGHT), Vector3(0.0, 0.0, super().origin.z + GAP))
