class_name Ride
extends RefCounted
## You on the hoverboard. It pushes where your keys point and turns under you
## as fast as it can, its hover gripping sideways so a carve holds until it
## slides out into a skid; crouched into a hard turn it drifts instead, a
## slide that keeps its speed. Move back brakes, sprint kicks off the sand on
## your stamina, and standing up as the hover presses into a dip (crouching
## as it unloads over a crest) pumps speed into it, as on a skateboard in a
## bowl. Its tilt settles onto the sand and into a carve as a spring would,
## so it never twitches. Slopes pull it along as they pull a slide, drag
## holds it to its top speed, and the air's share of that drag is felt
## against the felt wind, so shelter applies to it. Its hover rides the
## ground's one function, never the sand's collision, so no seam between
## chunks can catch it: stiff toward the sand and soft off it, it skims a
## slope and floats off a crest. It hits things and ruins. Stepped at a fixed
## rate inside each tick, as a slide is, so the same keys trace the same path
## at 30, 60 or 120 ticks a second; only drawing smooths between ticks.

const STEP_HZ := 240.0
## It leans into a carve at most this far, radians: further, and its edge
## would have to ride higher than the hover holds it.
const BANK := PI / 6.0
## More than this over its ride height, m, it's in the air: no grip, no push.
const REACH := 1.5
## Touching its clearance faster than this, m/s, it bottoms out.
const BUMP := 0.5
## A kick's push lasts this long, s, and your foot reaches the sand only this
## near the board's ride height, m.
const KICK_SECONDS := 0.25
const KICK_REACH := 0.3
## Crouched with the board this far off your way, radians, you drift, until
## it comes back this near.
const DRIFT_FROM := deg_to_rad(20.0)
const DRIFT_TO := deg_to_rad(8.0)
## Where the sand under it and the sand round it meet, the ground it rides
## is eased over about this much height, m.
const EASE := 0.4
## Flying, its tilt follows the sand below at this share of the pull it has
## lying on it.
const AIR_LIE := 0.1
## A line at your waist pulling you this hard, m/s², and the board's push
## gives nothing: it tows nothing, and towed, your keys only carve.
const HELD_BACK := 0.6

var player: Player
var board: Hoverboard
## Its way over the ground, m/s along engine x and z, and where its nose points.
var velocity := Vector2.ZERO
var ahead := Vector2(0.0, -1.0)
## Its underside, engine metres up, and how fast that rises, m/s.
var y := 0.0
var vy := 0.0
## How far it is over its ride height, m: more off a crest or in a hop.
var gap := 0.0
## How far you went last tick: what drawing smooths between ticks.
var last_step := Vector3.ZERO
## How far it leans into a carve, radians, positive turning right; and how
## it lies along the sand under it, nose up and right side up.
var bank := 0.0
var pitch := 0.0
var roll := 0.0
## How hard its hover holds you beyond your weight, m/s², over the last tick:
## more pressed into a dip, less unloading over a crest.
var pressing := 0.0
## Whether it's drifting, and the kicks you've made.
var drifting := false
var kicks := 0
## Times it bottomed out on its clearance, and the hardest, m/s.
var bottomed := 0
var hardest := 0.0
## Ticks it moved you, and ticks it waited for ground not yet solid:
## streaming fell behind.
var ticks := 0
var waited := 0

var _tuning := Tuning.current()
var _thick: float = Catalog.DEVICES[&"board"].size.y
## It reads the sand at its ends, half its length from its middle, and as
## far across; its edges are half its width out.
var _half: float = Catalog.DEVICES[&"board"].size.z * 0.5
var _edge: float = Catalog.DEVICES[&"board"].size.x * 0.5
## The ground the hover rides last step, NAN before the first.
var _ground := NAN
## The sand under it, and round it, along the way it went.
var _under := PathMean.new()
var _around := PathMean.new()
## How far it has come, m.
var _came := 0.0
var _hopping := false
## How fast its pitch, roll and lean are changing, rad/s; and those three and
## its nose as the last tick left them, which drawing eases from.
var _tilting := Vector3.ZERO
var _tilt_was := Vector3.ZERO
var _ahead_was := Vector2(0.0, -1.0)
## Steps until you can kick again, and steps left of a kick's push.
var _kick_wait := 0
var _stroke := 0
## What the lines at your waist pulled you by this tick, m/s along engine x and z.
var _towed := Vector2.ZERO
## In a storm as the last tick ended, so riding into one is noticed.
var _stormy := false


func _init(by: Player, on: Hoverboard) -> void:
	player = by
	board = on
	velocity = by.own
	var facing := -by.global_basis.z
	ahead = Vector2(facing.x, facing.z).normalized()
	_ahead_was = ahead
	var at := Vector2(by.global_position.x, by.global_position.z)
	y = maxf(by.global_position.y - _thick, _floor(at))
	_stormy = by.world.weather.in_storm


## A line's pull on you this tick, as the change in your way it makes: your
## camp towing you, sand-kiting, or a line holding you back.
func tow(by: Vector3) -> void:
	_towed += Vector2(by.x, by.z)


## One tick: `dir` is where your keys steer, flat, forward and to the sides;
## `brake` how hard move back is held, 0 to 1; `hop` a jump pressed; `kick`
## sprint held; `crouch` crouch held.
func step(delta: float, dir: Vector2, hop: bool, brake := 0.0, kick := false, crouch := false) -> void:
	var world := player.world
	var t := _tuning
	var g := world.gravity
	ticks += 1
	var n := maxi(1, roundi(delta * STEP_HZ))
	var h := delta / n
	var from := player.global_position
	var at := Vector2(from.x, from.z)
	# Drag of speed² that just matches the push at top speed.
	var drag := t.board_push / (t.board_top_speed * t.board_top_speed)
	var low_to := 1.0 if crouch else 0.0
	var getting_low := exp(-h / Player.LOW_SECONDS)
	var pushed := 0.0
	var hit := 0.0
	pressing = 0.0
	_tilt_was = Vector3(pitch, roll, bank)
	_ahead_was = ahead
	# A hop springs off the hover while it still holds the sand, higher from a
	# crouch: get low into a crest and pop off its top.
	if hop and gap < t.board_hold_reach and not _hopping:
		vy += t.board_hop + t.board_pop * player.low
		_hopping = true
	# Towed, the line carries you along and the hover's grip carves against
	# it: the board can't push against the line or run past it, and left
	# alone it swings round to run where the line leads, as a towed ski does.
	velocity += _towed
	var pull := _towed / delta
	var free := clampf(1.0 - pull.length() / HELD_BACK, 0.0, 1.0)
	var lead := pull.normalized() if pull.length() > HELD_BACK else Vector2.ZERO
	_towed = Vector2.ZERO
	for i in n:
		var when := world.time + i * h * world.time_warp
		var middle := _height(at)
		var east := _height(at + Vector2(_half, 0.0))
		var west := _height(at - Vector2(_half, 0.0))
		var south := _height(at + Vector2(0.0, _half))
		var north := _height(at - Vector2(0.0, _half))
		var grade := Vector2(east - west, south - north) / (2.0 * _half)
		var across := grade.dot(Vector2(-ahead.y, ahead.x))
		var nose := _height(at + ahead * _half)
		var tail := _height(at - ahead * _half)
		# The hover feels the sand along its whole length, so the lattice's
		# facets never judder it. A dip's bottom is read as the sand round it,
		# so it's rounded, not slammed into; a crest as it is, so you float off.
		var speed := velocity.length()
		var along := velocity / speed if speed > 0.5 else ahead
		var look := maxf(_half, speed * t.board_look_seconds)
		var under := _under.step(_height(at + along * _half), _came, 2.0 * _half)
		var around := _around.step(_height(at + along * look), _came, 2.0 * look)
		# The higher of the two, eased where they meet, so the ground it rides
		# never turns a corner its spring would have to snap round: the same
		# where they agree, EASE / 2 under the higher where they're far apart.
		var ground := (under + around + sqrt((under - around) * (under - around) + EASE * EASE) - EASE) * 0.5
		var rise := 0.0 if is_nan(_ground) else (ground - _ground) / h
		_ground = ground

		gap = y - ground - t.board_ride_height
		# Its spring is stiff pressed down and soft lifting off, its force
		# the same either way at ride height, so nothing jolts as it crosses it.
		# Its pull back down only holds while the sand is near: past that it's
		# let you go, and you fly under gravity alone.
		var w := TAU * (t.board_hover_hertz if gap < 0.0 else t.board_settle_hertz)
		var lift := -w * w * gap - 2.0 * t.board_hover_damping * TAU * t.board_hover_hertz * (vy - rise)
		var contact := clampf(1.0 - gap / REACH, 0.0, 1.0)
		if _hopping and gap > 0.0:
			lift = -g * t.board_hop_fall
		else:
			lift = maxf(lift, -g - t.board_hold * clampf(1.0 - gap / t.board_hold_reach, 0.0, 1.0))
			_hopping = _hopping and (gap > 0.0 or vy > rise)
		# Coming down, it brakes your fall evenly enough to meet the sand at
		# its pace by ride height, once that takes about its cushion, and
		# harder if the sand rises to meet you: a landing from high up is a
		# firm press, never a slam.
		var closing := rise - vy
		if closing > 0.0 and gap > 0.0:
			var need := closing * closing / (2.0 * gap)
			var cushion := t.board_cushion
			lift = maxf(lift, minf(lerpf(-g, need, clampf(2.0 * need / cushion - 1.0, 0.0, 1.0)), 3.0 * cushion))
		vy += lift * h
		y += vy * h
		var lowest := _lowest(middle, nose, tail)
		if y < lowest:
			hit = maxf(hit, rise - vy)
			y = lowest
			vy = maxf(vy, rise)
		pressing += lift * contact / n

		# Your legs work against what the hover holds you with beyond your
		# weight: stand up as a dip presses it, or get low as a crest unloads
		# it, and that work goes into your way. Your weight's own share comes
		# back each time you crouch again, so only the pressing counts.
		var was_low := player.low
		player.low = low_to + (player.low - low_to) * getting_low
		var pumped := lift * (was_low - player.low) * t.board_pump_rise * contact

		# The slope pulls it down, as it pulls a slide.
		velocity -= grade * g / (1.0 + grade.length_squared()) * contact * h
		speed = velocity.length()
		var axis := ahead if velocity.dot(ahead) >= 0.0 else -ahead
		var slip := (velocity / speed).angle_to(axis) if speed > 0.05 else 0.0
		# Crouched into a hard turn, its grip lets go on purpose and it slides.
		if drifting:
			drifting = crouch and absf(slip) > DRIFT_TO and speed > 2.0
		else:
			drifting = crouch and contact > 0.5 and speed > t.board_drift_speed and absf(slip) > DRIFT_FROM \
				and dir != Vector2.ZERO
		var pushing := 0.0
		var stopping := brake
		if dir != Vector2.ZERO:
			if speed > 1.0 and dir.dot(velocity / speed) < -0.5:
				stopping = 1.0
			else:
				var swing := (t.board_drift_turn if drifting else t.board_turn_rate) * h
				ahead = ahead.rotated(clampf(ahead.angle_to(dir), -swing, swing))
				pushing = clampf(ahead.dot(dir), 0.0, 1.0) * contact * (1.0 - stopping) * free
				velocity += ahead * t.board_push * pushing * h
		elif lead != Vector2.ZERO:
			var swing := t.board_turn_rate * contact * h
			ahead = ahead.rotated(clampf(ahead.angle_to(lead), -swing, swing))
		if stopping > 0.0:
			velocity = velocity.move_toward(Vector2.ZERO, t.board_brake * stopping * contact * h)
		pushed += pushing / n
		# A kick off the sand, like a skateboard's: from rest it gets you
		# going, and up a slope it keeps you going; at top speed your foot
		# can't add anything.
		_kick_wait = maxi(0, _kick_wait - 1)
		if kick and _kick_wait == 0 and stopping == 0.0 and gap < KICK_REACH \
				and player.stamina >= t.board_kick_stamina:
			player.stamina -= t.board_kick_stamina
			_kick_wait = roundi(t.board_kick_every * STEP_HZ)
			_stroke = roundi(KICK_SECONDS * STEP_HZ)
			kicks += 1
		if _stroke > 0:
			_stroke -= 1
			var spare := clampf(1.0 - velocity.length() / t.board_top_speed, 0.0, 1.0) * free
			velocity += ahead * t.board_kick / KICK_SECONDS * spare * contact * h
		if not kick:
			player.stamina = minf(player.stamina + t.stamina_regen * h, t.stamina_max)
		# Its hover grips sideways, so your way follows the board round, as
		# far as its grip; past that it skids, and a skid bleeds speed. A
		# drift grips less and bleeds far less.
		speed = velocity.length()
		var turn := 0.0
		if speed > 0.05 and contact > 0.0:
			axis = ahead if velocity.dot(ahead) >= 0.0 else -ahead
			slip = (velocity / speed).angle_to(axis)
			var most := (t.board_drift_grip if drifting else t.board_grip) * contact * h / speed
			turn = clampf(slip, -most, most)
			velocity = velocity.rotated(turn)
			var bleed := t.board_drift_slide if drifting else t.board_drift_drag
			velocity *= maxf(0.0, 1.0 - bleed * absf(sin(slip - turn)) * contact * h)
		# The hover's drag is against the ground, so in the air only the air's
		# is left, and that's against the wind.
		var wind := world.weather.felt_wind(Vector3(at.x, y + 1.0, at.y), when)
		var air := velocity - Vector2(wind.x, wind.z)
		var catch := lerpf(1.0, t.crouch_catch, player.low)
		speed = velocity.length()
		velocity -= (drag * (1.0 - t.board_air_share) * contact * speed * velocity
			+ drag * t.board_air_share * catch * air.length() * air) * h
		if pushing == 0.0 and _stroke == 0:
			velocity = velocity.move_toward(Vector2.ZERO, t.board_coast * contact * h)
		if pumped != 0.0:
			speed = velocity.length()
			if speed > 0.05:
				velocity *= sqrt(maxf(0.0, speed * speed + 2.0 * pumped)) / speed
		# It lies along the sand and leans into the carve as its hover pulls
		# you round, each settling as a spring would: never a snap. Flying,
		# you turn it slowly to the sand below, so it lands along it.
		var lean := clampf(atan2(turn / h * velocity.length(), g), -BANK, BANK)
		var lie := maxf(contact, AIR_LIE)
		_settle(Vector3(lerpf(pitch, atan((nose - tail) / (2.0 * _half)), lie),
			lerpf(roll, atan(across), lie), lean), h)
		at += velocity * h
		_came += velocity.length() * h

	board.push = pushed
	board.meter(world.time, world.time + delta * world.time_warp, delta)
	if hit > BUMP:
		bottomed += 1
		hardest = maxf(hardest, hit)
		player.landed.emit(hit)
	_move(from, at - Vector2(from.x, from.z), delta)
	_deeds(world)


## The board's deeds as they happen: high over the sand under it, far in one
## ride, and into a storm by night or in an eclipse.
func _deeds(world: World) -> void:
	var stormy := world.weather.in_storm
	var into := stormy and not _stormy
	_stormy = stormy
	if not world.counts_deeds:
		return
	var t := _tuning
	if y - _height(Vector2(player.global_position.x, player.global_position.z)) >= t.deed_board_height_m:
		Deeds.done(world, &"board_height")
	if _came >= t.deed_board_km * 1000.0:
		Deeds.done(world, &"board_distance")
	var day := world.weather.day
	if into and (not day.is_day(world.time, world.moon.longitude) or day.sun_shown(world.time) < 1.0):
		Deeds.done(world, &"board_storm")


## Pitch, roll and lean one step on toward where they'd lie, critically
## damped: they start gently, follow, and never overshoot.
func _settle(toward: Vector3, h: float) -> void:
	var now := Vector3(pitch, roll, bank)
	var w := TAU * Vector3(_tuning.board_tilt_hertz, _tuning.board_tilt_hertz, _tuning.board_lean_hertz)
	_tilting += (w * w * (toward - now) - 2.0 * w * _tilting) * h
	now += _tilting * h
	pitch = now.x
	roll = now.y
	bank = clampf(now.z, -BANK, BANK)


## A tick it waited for ground not yet solid: nothing moved, nothing to draw.
func wait() -> void:
	waited += 1
	last_step = Vector3.ZERO
	_tilt_was = Vector3(pitch, roll, bank)
	_ahead_was = ahead


## Carries you there: exactly, over open sand, so the path is the same at any
## tick rate; stopped short by anything solid, as far as it let you go.
func _move(from: Vector3, moved: Vector2, delta: float) -> void:
	player.velocity = Vector3(moved.x, y + _thick - from.y, moved.y) / delta
	player.move_and_slide()
	var open := true
	for i in player.get_slide_collision_count():
		var hit := player.get_slide_collision(i)
		var holder := hit.get_collider_shape() as CollisionShape3D
		if holder != null and holder.shape is HeightMapShape3D:
			continue
		open = false
		var normal := hit.get_normal()
		var loose := hit.get_collider() as RigidBody3D
		if loose != null and not loose.freeze:
			player.shove(loose, hit.get_position(), -normal, moved / delta, delta)
		var across := Vector2(normal.x, normal.z)
		if across.length() > 0.1:
			across = across.normalized()
			velocity -= across * minf(0.0, velocity.dot(across))
	if open:
		player.global_position = Vector3(from.x + moved.x, y + _thick, from.z + moved.y)
	else:
		y = maxf(y, _floor(Vector2(player.global_position.x, player.global_position.z)))
		player.global_position.y = y + _thick
	player.velocity = Vector3(velocity.x, vy, velocity.y)
	last_step = player.global_position - from


## Where the board is under your feet, as the tick knows it or as drawn this
## frame, smoothed between the last tick and this one, its tilt and its turn
## too.
func board_pose(drawn: bool) -> Transform3D:
	var at := player.global_position + Vector3.DOWN * _thick * 0.5
	var nose := ahead
	var lie := Vector3(pitch, roll, bank)
	if drawn:
		var f := Engine.get_physics_interpolation_fraction()
		at -= last_step * (1.0 - f)
		nose = _ahead_was.slerp(ahead, f)
		lie = tilt(true)
	var turn := Basis(Vector3.UP, atan2(-nose.x, -nose.y)) * Basis(Vector3.RIGHT, lie.x) \
		* Basis(Vector3.BACK, lie.y - lie.z)
	return Transform3D(turn, at)


## Its pitch, roll and lean, radians, as the tick left them or as drawn this
## frame between the last tick and this one.
func tilt(drawn: bool) -> Vector3:
	var now := Vector3(pitch, roll, bank)
	return _tilt_was.lerp(now, Engine.get_physics_interpolation_fraction()) if drawn else now


## The lowest its underside may come at a place, engine metres.
func _floor(at: Vector2) -> float:
	return _lowest(_height(at), _height(at + ahead * _half), _height(at - ahead * _half))


## Lying along the sand from its nose to its tail, the board clears both ends
## as far as its middle; a dip under it brings its ends nearer, a crest its
## middle, and a lean into a carve its lower edge.
func _lowest(middle: float, nose: float, tail: float) -> float:
	return maxf(middle, (nose + tail) * 0.5) + _tuning.board_clearance + _edge * absf(sin(bank))


## The ground's one function under an engine place.
func _height(at: Vector2) -> float:
	var world := player.world
	return world.height_at(world.world_x(at.x), world.world_z(at.y))


## The mean of the sand along the way you went over the last `length` m, read
## each step at the stretch's leading end: so the sand from half of it behind
## you to half ahead. It's the sand between readings taken as a straight
## line and summed exactly, the cut end of the stretch too, so it changes
## smoothly however the lattice's facets pass under it.
class PathMean:
	## How far along the way each reading was taken, m, and the sand there.
	var _at: Array[float] = []
	var _sand: Array[float] = []
	## The sand summed over the readings kept, m².
	var _area := 0.0

	func step(sand: float, came: float, length: float) -> float:
		if _at.is_empty() or came > _at[-1] + 1e-4:
			if not _at.is_empty():
				_area += (_sand[-1] + sand) * 0.5 * (came - _at[-1])
			_at.append(came)
			_sand.append(sand)
		var start := came - length
		while _at.size() > 2 and _at[1] <= start:
			_area -= (_sand[0] + _sand[1]) * 0.5 * (_at[1] - _at[0])
			_at.pop_front()
			_sand.pop_front()
		var span := _at[-1] - _at[0]
		if span <= 1e-6:
			return _sand[-1]
		if _at[0] >= start:
			return _area / span
		# The first stretch is cut where the mean's begins.
		var cut := _sand[0] + (_sand[1] - _sand[0]) * (start - _at[0]) / (_at[1] - _at[0])
		return (_area - (_sand[0] + cut) * 0.5 * (start - _at[0])) / length
