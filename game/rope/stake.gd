class_name Stake
extends Device
## A stake: a spike with a ring, its own item. Driven into the sand it's frozen
## there until the sustained pull of its lines passes its holding strength,
## then it pulls out and goes where they drag it. Its ring is a tie socket like
## any hook's, so staking and tying are separate acts.

## The spike's length, and how far its middle sits above the sand driven in:
## a little under it, so most of it is buried, m.
const LENGTH := 0.8
const DRIVEN_AT := -0.05
## Its eye, on top, in its own frame: 0.4 m above the sand driven in.
const RING := Vector3(0.0, 0.45, 0.0)

## Newtons of sustained pull it holds.
var holding := 2500.0
## The net pull of its lines this tick, and sustained, N.
var pull := Vector3.ZERO
var sustained := 0.0
## In the sand, holding; pulled out by its lines.
var driven := false
var pulled := false
## Where a bare line ties on (the look-test's); a line's end snaps into the socket.
var ring: RopeEnd


## Called once a tick with the net pull of its lines; true when it gives way.
func feel(pull: Vector3, alpha: float) -> bool:
	self.pull = pull
	if not driven:
		return false
	sustained += (pull.length() - sustained) * alpha
	return sustained > holding


## Out of the sand and standing on it, so it doesn't start inside the ground.
func pull_out(ground: float) -> void:
	pulled = true
	driven = false
	sustained = 0.0
	global_position.y = ground + LENGTH * 0.5 + 0.02
	freeze = false


## Into the sand at a point on it, upright, keeping its heading.
func drive(at: Vector3, ground: float) -> void:
	var heading := Basis(Vector3.UP, global_rotation.y)
	global_transform = Transform3D(heading, Vector3(at.x, ground + DRIVEN_AT, at.z))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	driven = true
	pulled = false
	sustained = 0.0


## F held over the sand: it goes in where you look.
func use(by: Player, at: Vector3) -> bool:
	if not by.hands.look_sand:
		return false
	by.hands.stow()
	drive(at, by.world.height_under(at))
	by.hands.clunk()
	return true


func stats() -> Dictionary:
	var now := super()
	if driven:
		now["holding"] = holding
		now["load"] = sustained / holding
	return now


func _physics_process(delta: float) -> void:
	super(delta)
	# Let go in the open, it's lying loose.
	if driven and not freeze:
		driven = false


## Light and often dragged: it never sleeps through a pull.
func _recompute() -> void:
	super()
	can_sleep = false
