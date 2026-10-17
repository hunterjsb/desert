class_name Player
extends CharacterBody3D
## The scavenger on foot. Walks at about 5 km/h, sprints on stamina, pays for
## every climb, and gets shoved by wind too strong to stand against. Sand too
## steep to stand on slides you down it; crouch at a run or downhill and you
## slide on purpose, keeping what the slope gives. A small jump shows the
## moon's gravity, crouching makes you smaller to the wind, and hauling
## against a line you dig in. On a hoverboard the ride moves you instead.
## Never moves where the ground has no collision yet, and never ends up in
## the sand. How it feels is Feel's: the camera's.

## Touched down from the air at this speed, m/s.
signal landed(speed: float)
signal jumped

## Slides and the air step at this rate whatever the physics tick, and the
## rest is exact over a tick, so the same keys trace the same path at 30, 60
## or 120 ticks a second.
const STEP_HZ := 240.0
## What a jump's height is quoted at, m/s².
const ONE_G := 9.8
## Getting low or back up takes about this long, s.
const LOW_SECONDS := 0.12
## Slip faces let go of you at the slip angle and take you back this much
## shallower, degrees, so the edge of one doesn't flicker.
const SLIP_HOLD := 2.0
## A board this near your feet, m, is one you can step onto.
const BOARD_REACH := 1.5

var world: World
var stamina: float
## Dev only: the console's fly flies through the world, for checking the far view.
var flying := false
## How you're moving: stand, walk, sprint, slide, air, ride or fly. A
## crouched walk is still a walk; `crouched` says you're low.
var mode := "stand"
var crouched := false
## Your own way over the ground, m/s along engine x and z: what your legs, a
## slide or a leap carry, without the wind's shove or a line's drag.
var own := Vector2.ZERO
## The sand's rise per metre under you, along x and z.
var slope := Vector2.ZERO
## The wind on you this tick, as you feel it.
var wind := Vector3.ZERO
## How low you are, 0 standing to 1 crouched; your wind catch shrinks with it.
var low := 0.0
## How far your feet have dug in hauling against a line, 0 to 1.
var sink := 0.0
var feel: Feel
## The board you ride, or null, and the ride that moves you on it.
var board: Hoverboard
var ride: Ride

var _tuning := Tuning.current()
var _sliding := false
var _jumped := false
var _since_ground := 0.0
## How long before this tick began your feet really touched down, s, when the
## last one landed you: negative when the floor caught you a moment early.
var _touchdown := 0.0
var _jump_buffer := 0.0
var _jump_was := false
var _jump_queued := false
var _crouch_was := false
var _on_sand := true
## The velocity as this left it, so a change from outside (a respawn, a
## probe) is seen and taken as where you now are.
var _left := Vector3.ZERO
## The board you'll step onto once your waist is untied, and the one you
## just stepped off, which can't touch you until it's clear of you.
var _boarding: Hoverboard
var _stepped_off: Hoverboard

@onready var camera: Camera3D = $Camera3D
@onready var hands: Hands = $Hands
@onready var waist: Waist = $Waist
@onready var suit: Suit = $Suit
@onready var vitals: Vitals = $Vitals
@onready var camp_range: CampRange = $CampRange


func _ready() -> void:
	stamina = _tuning.stamina_max
	feel = Feel.new()
	add_child(feel)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Controls.free_mouse(false)
	elif event.is_action_pressed("ui_cancel"):
		Controls.free_mouse(true)
	elif event.is_action_pressed("ride"):
		if toggle_board():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		# A tap shorter than a tick still counts.
		_jump_queued = true
	elif event is InputEventMouseMotion and not Controls.mouse_free:
		if hands.turn(event.relative * _tuning.mouse_sensitivity):
			return
		rotate_y(-event.relative.x * _tuning.mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * _tuning.mouse_sensitivity,
			-1.5, 1.5)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") \
		if Controls.playing() else Vector2.ZERO
	if flying:
		mode = "fly"
		Dev.put("player/mode", mode)
		var boost := 5.0 if Controls.held("sprint") else 1.0
		var rise := Input.get_axis("fly_down", "fly_up") if Controls.playing() else 0.0
		global_position += (camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * rise) \
			* _tuning.dev_fly_speed * boost * delta
		_stop()
		return
	_clear_of_board()
	# A board freed under you (a scenario's, say) still leaves a ride to end.
	if ride != null:
		_ride(delta, input)
		return
	if _boarding != null:
		if not is_instance_valid(_boarding) or _boarding.global_position.distance_to(global_position) > BOARD_REACH * 2.0:
			_boarding = null
		elif waist.tied.is_empty():
			get_on(_boarding)
	if world == null or not world.has_ground_under(global_position):
		_stop()
		return
	if velocity != _left:
		own = Vector2(velocity.x, velocity.z)
		_sliding = false

	var wish := global_basis * Vector3(input.x, 0.0, input.y)
	var dir := Vector2(wish.x, wish.z).normalized()
	var on_floor := is_on_floor()
	_since_ground = 0.0 if on_floor else _since_ground + delta
	if on_floor:
		_jumped = false
	var crouch := Controls.held("crouch")
	var pressed := crouch and not _crouch_was
	_crouch_was = crouch
	var jump := Controls.held("jump")
	if _jump_queued or (jump and not _jump_was):
		_jump_buffer = _tuning.jump_buffer_seconds
	_jump_queued = false
	_jump_was = jump
	slope = _slope_here()
	var vy := velocity.y
	var sprinting := false
	var climb := 0.0

	if _jump_buffer > 0.0 and not _jumped and (on_floor or _since_ground <= _tuning.coyote_seconds):
		vy = _takeoff()
		on_floor = false
		_jumped = true
		_jump_buffer = 0.0
		_sliding = false
		jumped.emit()
	_jump_buffer = maxf(0.0, _jump_buffer - delta)

	var step: Vector2
	var lift := 0.0
	if on_floor:
		vy = 0.0
		_sliding = _keeps_sliding(dir, crouch, pressed)
		if _sliding:
			step = _slide(delta, dir, crouch)
			sink = _ease(sink, 0.0, _tuning.haul_seconds, delta)
		else:
			sprinting = dir != Vector2.ZERO and Controls.held("sprint") and stamina > 0.0 and not crouch
			var pace := _tuning.crouch_speed if crouch else (_tuning.sprint_speed if sprinting else _tuning.walk_speed)
			if dir != Vector2.ZERO:
				var ahead := Vector3(dir.x, 0.0, dir.y)
				climb = maxf(0.0, world.height_under(global_position + ahead) - world.height_under(global_position))
				pace *= maxf(0.4, 1.0 - climb * _tuning.uphill_slowdown)
			pace = _haul(dir, pace, delta)
			step = _walk(delta, dir * pace, _touchdown)
	else:
		_sliding = false
		sink = _ease(sink, 0.0, _tuning.haul_seconds, delta)
		step = _air(delta, dir)
		# Exact under steady gravity: the move takes the tick's mean rise.
		lift = vy - world.gravity * delta * 0.5
		vy -= world.gravity * delta
	crouched = crouch
	low = _ease(low, 1.0 if crouch else 0.0, LOW_SECONDS, delta)

	velocity.x = step.x
	velocity.z = step.y
	wind = world.weather.felt_wind(global_position)
	# Force goes with the area the wind catches, so a smaller catch feels a slower wind.
	var beyond := wind.length() * sqrt(lerpf(1.0, _tuning.crouch_catch, low)) - _tuning.wind_resist_speed
	if beyond > 0.0:
		var shove := wind.normalized() * beyond * _tuning.wind_push
		velocity.x += shove.x
		velocity.z += shove.z
	velocity += get_meta(&"rope_drag", Vector3.ZERO)
	velocity.y = lift
	var from := global_position
	var meant := Vector2(velocity.x, velocity.z) * delta
	move_and_slide()
	_after_move(from, meant, delta, on_floor, vy)
	_hold_above_sand()
	_left = velocity

	mode = "slide" if _sliding else ("air" if not is_on_floor() and (_jumped or _since_ground > _tuning.coyote_seconds)
		else ("sprint" if sprinting else ("walk" if dir != Vector2.ZERO else "stand")))
	if sprinting:
		stamina -= _tuning.stamina_sprint_drain * delta
	if climb > 0.0:
		stamina -= climb * _tuning.stamina_uphill_drain * delta
	stamina -= sink * _tuning.haul_stamina_drain * delta
	if not sprinting and climb == 0.0 and sink < 0.05:
		stamina += _tuning.stamina_regen * delta
	stamina = clampf(stamina, 0.0, _tuning.stamina_max)

	Dev.put("player/mode", ("crouch walk" if mode == "walk" else "crouch") if crouched and mode in ["stand", "walk"]
		else mode)
	Dev.put("player/stam", "%d/%d" % [stamina, _tuning.stamina_max])
	Dev.put("player/spd", "%.1fkm/h" % (Vector2(velocity.x, velocity.z).length() * 3.6))
	Dev.put("player/slope", "%d°" % roundi(rad_to_deg(atan(slope.length()))))
	Dev.put("player/sink", "%d%%" % roundi(sink * 100.0))


func _stop() -> void:
	velocity = Vector3.ZERO
	own = Vector2.ZERO
	_sliding = false
	_left = velocity


## Ride: riding, step off; otherwise step onto the board in your hands, the
## one you look at, or the nearest at your feet. Says whether it did anything.
func toggle_board() -> bool:
	if board != null:
		step_off()
		return true
	return get_on(_board_near())


## Onto a board, if it has the charge to carry you. It tows nothing, so you
## let go of what you hold on a line or drag; a line at your waist has to be
## untied first, and you step on once it is.
func get_on(on: Hoverboard) -> bool:
	_boarding = null
	if on == null or board != null or flying:
		return false
	if world.salvage.lying(on):
		world.salvage.unbury(on)
	if not on.can_run():
		return false
	if hands.held == on:
		hands.stow()
	hands.grasp.let_go()
	if hands.held != null and waist.carries_line(hands.held):
		hands.drop()
	if not waist.tied.is_empty():
		waist.let_go()
		_boarding = on
		return true
	board = on
	ride = Ride.new(self, on)
	on.carry(self)
	motion_mode = MOTION_MODE_FLOATING
	_sliding = false
	_jumped = false
	return true


## Off the board onto the sand, keeping your way: faster than you can run,
## you skid. The board goes on as it was going, a body again.
func step_off() -> void:
	if board == null:
		return
	var going := Vector3(ride.velocity.x, ride.vy, ride.velocity.y)
	if is_instance_valid(board):
		board.global_transform = ride.board_pose(false)
		board.set_down(going)
		board.add_collision_exception_with(self)
		_stepped_off = board
	board = null
	ride = null
	motion_mode = MOTION_MODE_GROUNDED
	velocity = Vector3(going.x, 0.0, going.z)
	own = Vector2(going.x, going.z)
	_left = velocity
	_since_ground = INF


## A tick on the board: your keys say where it pushes and carves, move back
## brakes, sprint kicks, a jump hops, a crouch tucks you small to the wind
## and drifts a hard turn. Out of charge, you step off.
func _ride(delta: float, input: Vector2) -> void:
	if not is_instance_valid(board):
		board = null
		ride = null
		motion_mode = MOTION_MODE_GROUNDED
		_stop()
		return
	# Never onto ground that isn't solid yet: the board waits for it.
	if not world.has_ground_under(global_position):
		ride.wait()
		return
	# Move back only brakes: it never steers you round into reverse.
	var wish := global_basis * Vector3(input.x, 0.0, minf(input.y, 0.0))
	var crouch := Controls.held("crouch")
	var jump := Controls.held("jump")
	var hop := _jump_queued or (jump and not _jump_was)
	_jump_queued = false
	_jump_was = jump
	_crouch_was = crouch
	crouched = crouch
	ride.step(delta, Vector2(wish.x, wish.z).normalized(), hop, maxf(input.y, 0.0), Controls.held("sprint"), crouch)
	own = ride.velocity
	wind = world.weather.felt_wind(global_position)
	sink = 0.0
	_hold_above_sand()
	_left = velocity
	mode = "ride"
	if not board.powered or board.wrecked():
		step_off()
	Dev.put("player/mode", "ride")
	Dev.put("player/spd", "%.1fkm/h" % (own.length() * 3.6))
	Dev.put("player/stam", "%d/%d" % [stamina, _tuning.stamina_max])
	if ride != null:
		Dev.put("player/board", "%.2fm up, %d%%" % [ride.gap + _tuning.board_ride_height,
			roundi(100.0 * board.charge_share())])


## The board in your hands, the one you look at, or the nearest lying at your feet.
func _board_near() -> Hoverboard:
	if hands.held is Hoverboard:
		return hands.held
	if hands.look_device is Hoverboard:
		return hands.look_device
	var best: Hoverboard = null
	var nearest := BOARD_REACH
	for node in world.content.get_children() + world.salvage.near(global_position):
		var each := node as Hoverboard
		if each == null or each == hands.held:
			continue
		var off := each.global_position - global_position
		var d := Vector2(off.x, off.z).length()
		if d < nearest and absf(off.y) < 1.0:
			nearest = d
			best = each
	return best


## The board you stepped off touches you again once it's clear of you.
func _clear_of_board() -> void:
	if _stepped_off == null:
		return
	if not is_instance_valid(_stepped_off):
		_stepped_off = null
	elif _stepped_off.global_position.distance_to(global_position + Vector3.UP * 0.9) > 1.6:
		_stepped_off.remove_collision_exception_with(self)
		_stepped_off = null


## Legs push off the same on any moon; a tired push is a hop.
func _takeoff() -> float:
	var push := sqrt(2.0 * ONE_G * _tuning.jump_height)
	if stamina < _tuning.jump_stamina:
		push *= sqrt(maxf(stamina / _tuning.jump_stamina, 0.25))
	stamina -= _tuning.jump_stamina
	return push


## Whether you slide this tick. A slip face takes you whatever you do; a
## crouch starts one at a run, or heading downhill steeper than a slide's
## friction. On a seat you slide on while there's speed or slope to carry
## you; on your feet until you can run out what's left.
func _keeps_sliding(dir: Vector2, crouch: bool, pressed: bool) -> bool:
	var grade := slope.length()
	var slip := tan(deg_to_rad(_tuning.slip_angle - (SLIP_HOLD if _sliding else 0.0)))
	if grade > slip:
		return true
	var speed := own.length()
	if not _sliding:
		if not pressed:
			return false
		var downhill := -slope.dot(dir) > _tuning.slide_friction
		if speed < _tuning.slide_start_speed and not downhill:
			return false
		var heading := own / speed if speed > 0.1 else dir
		own += heading * _tuning.slide_kick
		return true
	if crouch:
		return speed > _tuning.slide_stop_speed or grade > _tuning.slide_friction
	return speed > _tuning.sprint_speed


## The slope pulls you down it, the sand's friction and the drag of ploughing
## it slow you, and your input steers a little or digs your heels in.
## Returns the tick's mean velocity.
func _slide(delta: float, dir: Vector2, crouch: bool) -> Vector2:
	var n := maxi(1, roundi(delta * STEP_HZ))
	var h := delta / n
	var grip := _tuning.slide_friction if crouch else _tuning.slip_friction
	# No heel digs in enough to stand on a slip face.
	var most := tan(deg_to_rad(_tuning.slip_angle)) * 0.8
	var turn := _tuning.slide_turn * h
	var moved := Vector2.ZERO
	for i in n:
		var grade := _slope_at(global_position + Vector3(moved.x, 0.0, moved.y)) if _on_sand else slope
		# Gravity along the sand, and its friction, both as their pull across the ground.
		var g := world.gravity / (1.0 + grade.length_squared())
		own -= grade * g * h
		var speed := own.length()
		if speed > 0.0:
			var heading := own / speed
			var dig := grip
			if dir != Vector2.ZERO:
				if heading.dot(dir) > -0.5:
					own = own.rotated(clampf(heading.angle_to(dir), -turn, turn))
				dig = minf(dig + _tuning.slide_brake * maxf(0.0, -heading.dot(dir)), maxf(grip, most))
			var slower := (g * dig + _tuning.slide_drag * speed * speed) * h
			own *= maxf(0.0, speed - slower) / speed
		moved += own * h
	return moved / delta


## Your legs take up the pace they want over pace_seconds, exactly over the
## tick: a landing or a slide's end runs out the same way at any tick rate.
## Landed `early` s before the tick, you've walked since the touchdown, not
## since the tick that noticed it.
func _walk(delta: float, target: Vector2, early := 0.0) -> Vector2:
	var walked := delta + early
	var fade := exp(-walked / _tuning.pace_seconds)
	var moved := target * walked + (own - target) * _tuning.pace_seconds * (1.0 - fade) - own * early
	own = target + (own - target) * fade
	return moved / delta


## In the air you keep what you had and can steer toward walking pace, slowly.
func _air(delta: float, dir: Vector2) -> Vector2:
	var n := maxi(1, roundi(delta * STEP_HZ))
	var h := delta / n
	var moved := Vector2.ZERO
	for i in n:
		if dir != Vector2.ZERO:
			var short := _tuning.walk_speed - own.dot(dir)
			if short > 0.0:
				own += dir * minf(_tuning.air_control * h, short)
		moved += own * h
	return moved / delta


## Walking or sprinting against a line that takes much of your pace, you dig
## in: slower, lower, tiring faster. Returns the pace you can manage.
func _haul(dir: Vector2, pace: float, delta: float) -> float:
	var held := 0.0
	if dir != Vector2.ZERO:
		var drag: Vector3 = get_meta(&"rope_drag", Vector3.ZERO)
		var against := -Vector2(drag.x, drag.z).dot(dir)
		held = smoothstep(_tuning.haul_from, 1.0, against / maxf(pace * (1.0 - _tuning.haul_slow * sink), 0.1))
	sink = _ease(sink, held, _tuning.haul_seconds, delta)
	return pace * (1.0 - _tuning.haul_slow * sink)


## What stopped you stops your momentum, and a landing tells how hard it was.
## On open sand you go exactly where you meant to: Jolt nudges a body resting
## on a slope out along its normal every tick, which would add up to another
## path at another tick rate. Only something solid in the way changes course.
func _after_move(from: Vector3, meant: Vector2, delta: float, was_on_floor: bool, vy: float) -> void:
	_on_sand = true
	var open := true
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var normal := hit.get_normal()
		var sand := hit.get_collider() is StaticBody3D
		if normal.angle_to(up_direction) <= floor_max_angle:
			_on_sand = sand
			open = open and sand
			continue
		open = false
		var loose := hit.get_collider() as RigidBody3D
		if loose != null and not loose.freeze:
			shove(loose, hit.get_position(), -normal, meant / delta, delta)
		var across := Vector2(normal.x, normal.z)
		if across.length() > 0.1:
			across = across.normalized()
			own -= across * minf(0.0, own.dot(across))
	if open and was_on_floor and is_on_floor():
		var off := meant - Vector2(global_position.x - from.x, global_position.z - from.z)
		global_position += Vector3(off.x, _slope_at(global_position).dot(off), off.y)
		velocity.x = meant.x / delta
		velocity.z = meant.y / delta
	if is_on_ceiling():
		vy = minf(vy, 0.0)
	_touchdown = 0.0
	if is_on_floor():
		if not was_on_floor:
			# The fall's own time to the sand within the tick: a landing comes a
			# tick late at a slow rate, a snap a little early at a fast one.
			var start := vy + world.gravity * delta
			var drop := from.y - global_position.y
			var fall := (start + sqrt(maxf(start * start + 2.0 * world.gravity * drop, 0.0))) / world.gravity
			_touchdown = clampf(delta - fall, -delta, delta)
			landed.emit(maxf(0.0, -vy))
			# Land crouched at speed and the slide goes on; land faster than you
			# can run and you skid.
			_sliding = (crouched and own.length() >= _tuning.slide_start_speed) or own.length() > _tuning.sprint_speed
		vy = 0.0
	velocity.y = vy


## Walking into a loose thing pushes it on at the pace you meant, as hard as
## your strength allows, so a heavy one barely moves and a floating one goes.
func shove(body: RigidBody3D, at: Vector3, into: Vector3, meant: Vector2, delta: float) -> void:
	into.y = 0.0
	if into.length() < 0.1:
		return
	into = into.normalized()
	var short := Vector3(meant.x, 0.0, meant.y).dot(into) - body.linear_velocity.dot(into)
	if short > 0.0:
		body.apply_impulse(into * minf(body.mass * short, _tuning.hand_strength * delta), at - body.global_position)


## The sand is a hard floor: Jolt's heightmap is a skin, so anything that got
## through it is put back on top and counted, as World does for loose bodies.
func _hold_above_sand() -> void:
	var sand := world.height_under(global_position)
	if global_position.y < sand - World.BELOW_SAND:
		global_position.y = sand + 0.05
		velocity.y = 0.0
		world.rescued += 1
		push_warning("rescued the player from below the sand")


## The ground's one function's slope, or a device's top's from its normal.
func _slope_here() -> Vector2:
	if _on_sand or not is_on_floor():
		return _slope_at(global_position)
	var normal := get_floor_normal()
	return -Vector2(normal.x, normal.z) / maxf(normal.y, 0.1)


func _slope_at(at: Vector3) -> Vector2:
	var x := world.world_x(at.x)
	var z := world.world_z(at.z)
	return Vector2(world.height_at(x + 0.25, z) - world.height_at(x - 0.25, z),
		world.height_at(x, z + 0.25) - world.height_at(x, z - 0.25)) * 2.0


## Exactly over the tick, so easing comes out the same at any tick rate.
static func _ease(from: float, to: float, seconds: float, delta: float) -> float:
	return to + (from - to) * exp(-delta / seconds)
