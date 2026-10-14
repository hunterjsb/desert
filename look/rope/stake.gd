extends RigidBody3D
## A stake in the sand: frozen in place until the sustained pull of its lines
## passes its holding strength, then it pulls out and goes where they drag it.

## Newtons of sustained pull it holds.
var holding := 2500.0
## The net pull of its lines this tick, and sustained, N.
var pull := Vector3.ZERO
var sustained := 0.0
var pulled := false
var ring: RopeEnd


## Called once a tick with the net pull of its lines; true when it gives way.
func feel(pull: Vector3, alpha: float) -> bool:
	self.pull = pull
	if pulled:
		return false
	sustained += (pull.length() - sustained) * alpha
	return sustained > holding


## Out of the sand and standing on it, so it doesn't start inside the ground.
func pull_out(ground: float) -> void:
	pulled = true
	sustained = 0.0
	global_position.y = ground + 0.42
	freeze = false
