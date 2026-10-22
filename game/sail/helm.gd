class_name Helm
extends Device
## A helm seat, a skimmer pilot's. Fitted to the camp the way anything is,
## use on it sits you at the helm: you ride the camp as what's seated on it
## does, your weight its, and the sideways moves turn it as a hovercraft's do,
## its hover field pushing it round toward a turn of your choosing. Ride, or
## use on it again, stands you up off its side. All of that is the seat's own,
## whatever holds it to the camp. A keel under the camp is what holds it
## across the wind; without one it only runs downwind.

## Where your feet go seated, in its own frame, so your eyes come where a
## sitter's would, and where your weight sits.
const FEET := Vector3(0.0, -0.35, 0.05)
const MIDDLE := Vector3(0.0, 0.1, 0.05)
## It turns toward the turn you want over about this long, s.
const TURN_SECONDS := 0.3
## Its deck leaning past this far, you're thrown off, rad.
const THROWN := deg_to_rad(40.0)
## Stood up, you step this far clear of the deck's edge, m.
const CLEAR := 0.45
## What the first sit at a helm teaches, once a profile: what the controls do.
const HOW_TO := "helm"
const HOW_TO_SAYS := "At the helm, {move_left} and {move_right} turn the camp; a keel under it holds it across the wind.\n" \
	+ "{reel_in} and {pay_out} work the sheet at your waist; {ride} stands you up."

## Who sits here, or null, and how hard they turn it: -1 left to 1 right.
var rider: Player
var turning := 0.0
## Whether it turns its camp, and whether you sit low in it; a lookout's
## seat does neither.
var steers := true
var sits := true
## The ground its camp has covered under sail, keeled, since you sat, m.
var sailed_m := 0.0
var _computer: Console
var _command_tick := -2
var _course := Vector2.ZERO


## The computer works this helm's turn input; it has no separate steering force.
func steer_by(computer: Console, heading: Vector2) -> void:
	if computer.running() and computer._root() == carrier() and steers and rider != null:
		_computer = computer
		_course = heading
		_command_tick = Engine.get_physics_frames()


## Use sits you here, or stands you up; empty-handed, and on a camp.
func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	if rider == by:
		by.stand_up()
		return true
	if carrier() == null:
		return by.hands.refuse("fit it to the camp")
	return by.sit(self)


## What it's fitted to, all the way down, or null.
func carrier() -> Device:
	var at: Device = host()
	while at != null and at.host() != null:
		at = at.host()
	return at


## Where a rider's feet are now.
func feet() -> Vector3:
	return global_transform * FEET


## What the first sit in it teaches, once a profile: [its key, its words].
func how_to() -> Array[String]:
	return [HOW_TO, HOW_TO_SAYS]


## Its deck's way at where you sit, m/s.
func carried_at(point: Vector3) -> Vector3:
	var on := carrier()
	if on == null:
		return Vector3.ZERO
	return on.linear_velocity + on.angular_velocity.cross(point - on.global_transform * on.center_of_mass)


## Whether its deck leans too far to sit on.
func tipped() -> bool:
	var on := carrier()
	return on == null or on.global_basis.y.normalized().dot(Vector3.UP) < cos(THROWN)


## The deck's hover field turns it toward the turn you want, as hard as the
## helm can push.
func _physics_process(delta: float) -> void:
	super(delta)
	var on := carrier()
	if rider == null:
		sailed_m = 0.0
	elif world.counts_deeds and steers:
		_sail_on(on, delta)
	var worked := turning
	if is_instance_valid(_computer) and _computer.running() and _computer._root() == on \
			and _computer.sailing.mode == SailingAid.Mode.STEER and Engine.get_physics_frames() - _command_tick <= 1:
		if turning != 0.0:
			_computer.sailing.mode = SailingAid.Mode.TRIM
		elif on != null:
			var error := SailingIdeal.heading_of(on).angle_to(_course)
			worked = clampf(error / (world.tuning.sailing_aid_helm_seconds * world.tuning.helm_turn), -1.0, 1.0)
	if not steers or rider == null or on == null or on.freeze or worked == 0.0 and absf(on.angular_velocity.y) < 1e-3:
		return
	var state := PhysicsServer3D.body_get_direct_state(on.get_rid())
	var up := on.global_basis.y.normalized()
	var spin := state.angular_velocity.dot(up)
	var inertia := 1.0 / maxf(up.dot(state.inverse_inertia_tensor * up), 1e-6)
	var want := -worked * world.tuning.helm_turn
	var most := world.tuning.helm_torque
	on.apply_torque(up * clampf(inertia * (want - spin) / TURN_SECONDS, -most, most))


## Its camp under a raised sail, floating on a keel: the ground it covers counts.
func _sail_on(on: Device, h: float) -> void:
	if on == null or not on.hovering() or not Deeds.waiting(world, &"land_yacht") or Runners.keels(on).is_empty():
		return
	for each in on.mounted():
		if each is Mast and (each as Mast).raise > 0.0:
			sailed_m += Vector2(on.linear_velocity.x, on.linear_velocity.z).length() * h
			Deeds.measure(world, &"land_yacht", sailed_m)
			return


## A rider's weight is the seat's, so the deck's hover holds you up and the
## sail heels you with it.
func _frame_masses() -> Array:
	var frames := super()
	if rider != null:
		frames.append([world.tuning.player_mass if world != null else 90.0, MIDDLE])
	return frames
