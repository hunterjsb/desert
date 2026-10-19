class_name Ride
extends RefCounted
## You on the hoverboard. It pushes where your keys point and turns under you
## as fast as it can, its hover gripping sideways so a carve holds until it
## breaks loose into a skid, a slide you hold by how you steer until it comes
## back near your way and bites; crouched into a hard turn it drifts instead,
## a slide that keeps its speed. Move back digs an edge into the sand, trading
## speed for grip: into a carve it bites, alone it swings the board across
## your way to a hockey stop, and too hard at speed it catches. Sprint kicks
## off the sand on your stamina, and standing up as the hover presses into a
## dip (crouching as it unloads over a crest) pumps speed into it, as on a
## skateboard in a bowl. Its tilt settles onto the sand and into a carve as a
## spring would, so it never twitches; flying, it pitches with its path and
## leans with its turn, and comes down matched to the sand it meets. A
## landing at speed or crossed slides out before it bites; too hard, it jars
## you, and harder throws you off, as a crash into something solid does.
## Slopes pull it along as they pull a slide, drag holds it to its top speed,
## and the air's share of that drag is felt against the felt wind, so shelter
## applies to it. Its hover rides the ground's one function, never the sand's
## collision, so no seam between chunks can catch it: stiff toward the sand
## and soft off it, it skims a slope and floats off a crest. It hits things
## and ruins. Its make (BoardMakes) sets its numbers. Stepped at a fixed rate
## inside each tick, as a slide is, so the same keys trace the same path at
## 30, 60 or 120 ticks a second; only drawing smooths between ticks.

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
## Standing, a carve whose board points this far off its way has broken
## loose, radians, and skids until it comes back this near; a landing's
## knocked-loose grip lets it go from the nearer.
const SKID_FROM := deg_to_rad(12.0)
const SKID_TO := deg_to_rad(5.0)
## Dug this deep, its edge holds the carve: it can't skid.
const SKID_DIG := 0.3
## Where the sand under it and the sand round it meet, the ground it rides
## is eased over about this much height, m.
const EASE := 0.4
## Flying, its tilt follows the sand below at this share of the pull it has
## lying on it.
const AIR_LIE := 0.1
## A line at your waist pulling you this hard, m/s², and the board's push
## gives nothing: it tows nothing, and towed, your keys only turn it.
const HELD_BACK := 0.6
## The edge goes in and comes out over about this long, s.
const DIG_SECONDS := 0.2
## Stopping, the board swings across your way this fast, rad/s, faster than
## its hover follows: from about this speed, m/s.
const STOP_TURN := 5.0
const STOP_FROM := 1.0
## Dug this deep at this speed, m/s, the edge has bitten: you feel it.
const BITE := 0.5
const BITE_SPEED := 5.0
## The low edge, dug, comes this near the sand, m, and never nearer.
const SKIM := 0.01
## It flies free from this far over its ride height, m, all of it this much
## further on; coming down, it turns to the sand it'll meet over its last
## MATCH_SECONDS of falling before the last MATCH_LAST.
const AIR_FROM := 0.25
const AIR_SPAN := 1.0
const MATCH_SECONDS := 0.6
const MATCH_LAST := 0.15
## Slower than this along its nose, m/s, its path pitches it less; its path
## never pitches it further than AIR_PITCH.
const AIR_SLOW := 6.0
const AIR_PITCH := deg_to_rad(35.0)
## Flying with nothing steering it, its nose comes round to its way this fast, rad/s.
const AIR_TRUE := 1.2
## Back within this of its ride height after flying free, m, its hover has
## the sand again: it has landed. Till then it grips nothing.
const LANDED := 0.4
## Landing fully sideways this fast or faster, m/s, it hits this much harder again.
const CROSSED := 1.0
const CROSS_FAST := 10.0
## A landing as hard as its jar knocks this share of the grip loose, and the
## grip comes back over about this long, s.
const LOOSE_GRIP := 0.8
const LOOSE_SECONDS := 0.6
## Held fast, or this heavy, kg, a thing is solid to crash into; lighter,
## you shove it.
const SOLID_KG := 12.0
## Rising off the sand faster than this, m/s, it pops off a lip.
const LIP := 1.5

var player: Player
var board: Hoverboard
## Its make's numbers (BoardMakes.of).
var make: Dictionary
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
## Whether it's drifting, whether it has broken loose into a skid, how much
## of its grip a landing has knocked loose, 0 to 1, and the kicks you've made.
var drifting := false
var skidding := false
var loose := 0.0
var kicks := 0
## How deep its edge is dug in, 0 to 1; the most this tick that dig times
## the way across the board came to, m/s; whether it threw you off, which
## ends the ride: how (&"edge" caught, a &"landing" or a &"crash"), at what
## speed, m/s, and out of what it struck, if it struck something.
var dig := 0.0
var edge := 0.0
var caught := false
var thrown := &""
var thrown_at := 0.0
var struck := Vector2.ZERO
## This tick, the hardest it met the sand after flying free, m/s, a crossed
## landing counted harder, and how fast it popped up off the sand, m/s.
var touched := 0.0
var popped := 0.0
## Times it bottomed out on its clearance, and the hardest, m/s; the hardest
## it has met the sand after flying, m/s.
var bottomed := 0
var hardest := 0.0
var landed_hardest := 0.0
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
## Whether the edge has bitten since it last came out.
var _bitten := false
## In a storm as the last tick ended, so riding into one is noticed.
var _stormy := false
## Flown free of the sand's hold since it last landed, and the fastest it
## came down at the sand meanwhile, m/s.
var _flying := false
var _falling := 0.0


func _init(by: Player, on: Hoverboard) -> void:
	player = by
	board = on
	make = BoardMakes.of(BoardMakes.make_of(on))
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
## `digging` how hard move back is held, 0 to 1; `hop` a jump pressed; `kick`
## sprint held; `crouch` crouch held.
func step(delta: float, dir: Vector2, hop: bool, digging := 0.0, kick := false, crouch := false) -> void:
	var world := player.world
	var t := _tuning
	var m := make
	var g := world.gravity
	ticks += 1
	var n := maxi(1, roundi(delta * STEP_HZ))
	var h := delta / n
	var from := player.global_position
	var at := Vector2(from.x, from.z)
	# Its make's numbers on the tuning's.
	var top: float = t.board_top_speed * m.top
	var push: float = t.board_push * m.push
	var grip: float = t.board_grip * m.grip
	var turn_rate: float = t.board_turn_rate * m.turn
	var ride_height: float = t.board_ride_height * m.height
	var hover_hz: float = t.board_hover_hertz * m.spring
	var settle_hz: float = t.board_settle_hertz * m.spring
	var sturdy: float = m.sturdy
	# Drag of speed² that just matches the push at top speed.
	var drag := push / (top * top)
	var low_to := 1.0 if crouch else 0.0
	var getting_low := exp(-h / Player.LOW_SECONDS)
	var digging_in := exp(-h / DIG_SECONDS)
	var biting := exp(-h / (LOOSE_SECONDS * m.bite))
	var pushed := 0.0
	var hit := 0.0
	pressing = 0.0
	edge = 0.0
	touched = 0.0
	popped = 0.0
	_tilt_was = Vector3(pitch, roll, bank)
	_ahead_was = ahead
	# A hop springs off the hover while it still holds the sand, higher from a
	# crouch: get low into a crest and pop off its top.
	if hop and gap < t.board_hold_reach and not _hopping:
		var up: float = (t.board_hop + t.board_pop * player.low) * m.hop
		vy += up
		popped = up
		_hopping = true
	# Towed, the line carries you along: the board can't push against the
	# line or run past it, and left alone it runs where the line leads.
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

		# Dug, the field rides lower, bringing its low edge down to the sand.
		gap = y - ground - ride_height + dig * t.board_dig_depth
		# How free of the sand it flies, 0 riding it to 1 well clear.
		var air := clampf((gap - AIR_FROM) / AIR_SPAN, 0.0, 1.0)
		# Its spring is stiff pressed down and soft lifting off, its force
		# the same either way at ride height, so nothing jolts as it crosses it.
		# Its pull back down only holds while the sand is near: past that it's
		# let you go, and you fly under gravity alone.
		var w := TAU * (hover_hz if gap < 0.0 else settle_hz)
		var lift := -w * w * gap - 2.0 * t.board_hover_damping * TAU * hover_hz * (vy - rise)
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
			var cushion: float = t.board_cushion * m.cushion
			lift = maxf(lift, minf(lerpf(-g, need, clampf(2.0 * need / cushion - 1.0, 0.0, 1.0)), 3.0 * cushion))
		vy += lift * h
		y += vy * h
		var lowest := _lowest(middle, nose, tail)
		if y < lowest:
			# The sand rose into it faster than its hover could lift it: head
			# on into a face, it throws you.
			var into := rise - vy
			hit = maxf(hit, into)
			if into > t.board_crash * sturdy and not caught:
				_throw(&"crash", into)
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
		# Off the sand's hold it flies free, and coming back down it lands:
		# how fast it met the sand, harder crossed. That knocks its grip
		# loose, so it slides out before it bites; too hard, it throws you.
		if gap > t.board_hold_reach:
			if not _flying:
				_flying = true
				_falling = 0.0
				skidding = false
				if not _hopping and vy - rise > LIP:
					popped = maxf(popped, vy - rise)
			_falling = maxf(_falling, closing)
		elif _flying and gap < LANDED:
			_flying = false
			var hard := _falling * (1.0 + CROSSED * absf(sin(slip)) * minf(speed / CROSS_FAST, 1.0))
			touched = maxf(touched, hard)
			landed_hardest = maxf(landed_hardest, hard)
			loose = maxf(loose, clampf(hard / (t.board_land_jar * sturdy), 0.0, 1.0))
			if hard > t.board_land_throw * sturdy and not caught:
				_throw(&"landing", hard)
		loose *= biting
		# Crouched into a hard turn, its grip lets go on purpose and it slides.
		if drifting:
			drifting = crouch and absf(slip) > DRIFT_TO and speed > 2.0
		else:
			drifting = crouch and contact > 0.5 and speed > t.board_drift_speed and absf(slip) > DRIFT_FROM \
				and dir != Vector2.ZERO
		var pushing := 0.0
		var yawed := 0.0
		# Move back alone stops you: the board swings across your way and its
		# edge digs in as it comes across, as in a hockey stop. Steering, it
		# digs into the carve. Steering back against your way only brakes, so
		# looking back at speed never throws you.
		var wants := digging
		var stopping := digging > 0.0 and dir == Vector2.ZERO
		var braking := dir != Vector2.ZERO and speed > 1.0 and dir.dot(velocity / speed) < -0.5
		if stopping:
			var off := 0.0
			if speed > 0.05:
				var way := velocity / speed
				var sense := 1.0 if way.dot(ahead) >= 0.0 else -1.0
				off = way.angle_to(ahead * sense)
				if speed > STOP_FROM:
					off = (1.0 if off >= 0.0 else -1.0) * minf(PI * 0.5, absf(off) + STOP_TURN * contact * h)
					ahead = way.rotated(off) * sense
			wants *= sin(off) * sin(off)
		elif braking:
			velocity = velocity.move_toward(Vector2.ZERO, t.board_brake * contact * h)
		elif dir != Vector2.ZERO:
			var swing := (t.board_drift_turn if drifting else turn_rate) * h
			yawed = clampf(ahead.angle_to(dir), -swing, swing)
			ahead = ahead.rotated(yawed)
			pushing = clampf(ahead.dot(dir), 0.0, 1.0) * contact * (1.0 - dig) * free
			velocity += ahead * push * pushing * h
		elif lead != Vector2.ZERO:
			# Nothing holding it sideways, it trails its own way, as a towed ski does.
			var trail := velocity / speed if speed > 0.5 else lead
			var swing := turn_rate * contact * h
			ahead = ahead.rotated(clampf(ahead.angle_to(trail), -swing, swing))
		elif air > 0.0 and speed > 2.0:
			# Flying with nothing steering it, it comes round to its way.
			var swing := AIR_TRUE * air * h
			yawed = clampf(ahead.angle_to(velocity / speed * signf(velocity.dot(ahead) + 1e-6)), -swing, swing)
			ahead = ahead.rotated(yawed)
		dig = wants + (dig - wants) * digging_in
		pushed += pushing / n
		# A kick off the sand, like a skateboard's: from rest it gets you
		# going, and up a slope it keeps you going; at top speed your foot
		# can't add anything.
		_kick_wait = maxi(0, _kick_wait - 1)
		if kick and _kick_wait == 0 and digging == 0.0 and not stopping and not braking and gap < KICK_REACH \
				and player.stamina >= t.board_kick_stamina:
			player.stamina -= t.board_kick_stamina
			_kick_wait = roundi(t.board_kick_every * STEP_HZ)
			_stroke = roundi(KICK_SECONDS * STEP_HZ)
			kicks += 1
		if _stroke > 0:
			_stroke -= 1
			var spare := clampf(1.0 - velocity.length() / top, 0.0, 1.0) * free
			velocity += ahead * t.board_kick / KICK_SECONDS * spare * contact * h
		if not kick:
			player.stamina = minf(player.stamina + t.stamina_regen * h, t.stamina_max)
		# Its hover grips sideways, so your way follows the board round, as
		# far as its grip; past that it breaks loose into a skid, which grips
		# less until the board comes back near your way, and a skid bleeds
		# speed. A drift grips less again and bleeds far less. A landing
		# knocks the grip loose a moment. A line's pull drags that grip out
		# from under it, and stopping you let it go, so only a dug edge holds
		# then.
		speed = velocity.length()
		var turn := 0.0
		var dug_pull := 0.0
		if speed > 0.05 and contact > 0.0 and not _flying:
			axis = ahead if velocity.dot(ahead) >= 0.0 else -ahead
			slip = (velocity / speed).angle_to(axis)
			var right := Vector2(-ahead.y, ahead.x)
			var load := dig * absf(velocity.dot(right)) * contact
			edge = maxf(edge, load)
			if load > t.board_dig_catch * sturdy and not caught:
				_throw(&"edge", speed)
			var can_skid := not drifting and not stopping and not braking and dig < SKID_DIG and free > 0.5
			if skidding:
				skidding = can_skid and speed > 2.0 and absf(slip) > SKID_TO
			else:
				skidding = can_skid and contact > 0.5 and speed > t.board_skid_speed \
					and absf(slip) > lerpf(SKID_FROM, SKID_TO, minf(loose * 2.0, 1.0))
			var keeps: float = t.board_drift_grip * m.drift_grip if drifting \
				else grip * (t.board_skid_grip * m.skid if skidding else 1.0)
			var hold := keeps * (1.0 - dig) * free * (1.0 - LOOSE_GRIP * loose)
			var most := (0.0 if stopping else hold) * contact * h / speed
			turn = clampf(slip, -most, most)
			velocity = velocity.rotated(turn)
			# The dug edge takes out your way across it: slicing along its
			# length it holds hard, dragged across it scrapes.
			var held := grip * dig * contact * lerpf(t.board_dig_grip, 1.0, absf(sin(slip))) * h
			var cut := clampf(velocity.dot(right), -held, held)
			velocity -= right * cut
			dug_pull = -cut / h
			var bleed: float = t.board_drift_slide * m.drift_slide if drifting \
				else (t.board_skid_drag * m.skid_drag if skidding else t.board_drift_drag)
			var still := velocity.angle_to(axis) if cut != 0.0 and velocity.length() > 0.05 else slip - turn
			velocity *= maxf(0.0, 1.0 - (bleed * absf(sin(still)) + t.board_dig_drag * dig) * contact * h)
		# The hover's drag is against the ground, so in the air only the air's
		# is left, and that's against the wind.
		var wind := world.weather.felt_wind(Vector3(at.x, y + 1.0, at.y), when)
		var air_way := velocity - Vector2(wind.x, wind.z)
		var catch := lerpf(1.0, t.crouch_catch, player.low)
		speed = velocity.length()
		velocity -= (drag * (1.0 - t.board_air_share) * contact * speed * velocity
			+ drag * t.board_air_share * catch * air_way.length() * air_way) * h
		if pushing == 0.0 and _stroke == 0:
			velocity = velocity.move_toward(Vector2.ZERO, t.board_coast * contact * h)
		if pumped != 0.0:
			speed = velocity.length()
			if speed > 0.05:
				velocity *= sqrt(maxf(0.0, speed * speed + 2.0 * pumped)) / speed
		# It lies along the sand and leans into the carve as its hover pulls
		# you round, each settling as a spring would: never a snap. Flying, it
		# pitches with its path and leans with its turn, and coming down it
		# turns to the sand it'll meet, so it lands along it.
		var lean := clampf(atan2(turn / h * velocity.length() + dug_pull, g), -BANK, BANK)
		var lie := maxf(contact, AIR_LIE)
		var toward := Vector3(lerpf(pitch, atan((nose - tail) / (2.0 * _half)), lie),
			lerpf(roll, atan(across), lie), lean)
		if air > 0.0:
			var ahead_way := velocity.dot(ahead)
			var path := clampf(atan2(vy * signf(ahead_way), absf(ahead_way)) * minf(absf(ahead_way) / AIR_SLOW, 1.0),
				-AIR_PITCH, AIR_PITCH)
			var flying := Vector3(path, 0.0, clampf(atan2(yawed / h * velocity.length(), g), -BANK, BANK))
			var aloft := air
			if closing > 0.1:
				var left := gap / closing
				aloft = minf(air, clampf((left - MATCH_LAST) / MATCH_SECONDS, 0.0, 1.0))
				if aloft < 1.0:
					var meet := at + velocity * minf(left, MATCH_SECONDS + MATCH_LAST)
					var side := Vector2(-ahead.y, ahead.x) * _half
					toward.x = atan((_height(meet + ahead * _half) - _height(meet - ahead * _half)) / (2.0 * _half))
					toward.y = atan((_height(meet + side) - _height(meet - side)) / (2.0 * _half))
			toward = toward.lerp(flying, aloft)
		_settle(toward, h, air)
		at += velocity * h
		_came += velocity.length() * h
		if caught:
			break

	if not _bitten and dig > BITE and velocity.length() > BITE_SPEED:
		_bitten = true
		player.edge_bit.emit(velocity.length())
	_bitten = _bitten and dig > BITE * 0.5
	board.push = pushed
	board.meter(world.time, world.time + delta * world.time_warp, delta)
	if hit > BUMP:
		bottomed += 1
		hardest = maxf(hardest, hit)
		player.landed.emit(hit)
	if popped > 0.0:
		player.took_off.emit(popped)
	if touched > 0.0:
		player.touched_down.emit(touched)
	_move(from, at - Vector2(from.x, from.z), delta)
	_deeds(world)


## How fast it slides across the sand, m/s: its way across the board while
## it skids, drifts, slides out of a landing or drags a dug edge, its hover
## on the sand; 0 gripping or flying. What gouges the sand (Tracks).
func slide_across() -> float:
	if gap > AIR_FROM or not (skidding or drifting or loose > 0.1 or dig > SKID_DIG):
		return 0.0
	return absf(velocity.dot(Vector2(-ahead.y, ahead.x)))


## It throws you off: how, and how hard, m/s.
func _throw(how: StringName, speed: float) -> void:
	caught = true
	thrown = how
	thrown_at = speed

## The board's deeds as they happen: high over the sand under it, far in one
## ride, and into a storm by night or in an eclipse.
func _deeds(world: World) -> void:
	var stormy := world.weather.in_storm
	var into := stormy and not _stormy
	_stormy = stormy
	if not world.counts_deeds:
		return
	Deeds.measure(world, &"board_height", y - _height(Vector2(player.global_position.x, player.global_position.z)))
	Deeds.measure(world, &"board_distance", _came)
	var day := world.weather.day
	if into and (not day.is_day(world.time, world.moon.longitude) or day.sun_shown(world.time) < 1.0):
		Deeds.done(world, &"board_storm")


## Pitch, roll and lean one step on toward where they'd lie, critically
## damped: they start gently, follow, and never overshoot. Flying `air` free,
## its pitch and roll ease more slowly, after its path.
func _settle(toward: Vector3, h: float, air := 0.0) -> void:
	var now := Vector3(pitch, roll, bank)
	var lying := lerpf(_tuning.board_tilt_hertz, _tuning.board_air_hertz, air)
	var w := TAU * Vector3(lying, lying, _tuning.board_lean_hertz)
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
## tick rate; stopped short by anything solid, as far as it let you go, and
## into it too fast, thrown off.
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
			# A wall takes all of your way into it, a slope its share.
			var into := -velocity.dot(across)
			if into > _tuning.board_crash * make.sturdy and not caught and _solid(hit.get_collider()):
				_throw(&"crash", into)
				struck = across.normalized()
			across = across.normalized()
			velocity -= across * minf(0.0, velocity.dot(across))
	if open:
		player.global_position = Vector3(from.x + moved.x, y + _thick, from.z + moved.y)
	else:
		y = maxf(y, _floor(Vector2(player.global_position.x, player.global_position.z)))
		player.global_position.y = y + _thick
	player.velocity = Vector3(velocity.x, vy, velocity.y)
	last_step = player.global_position - from


## Whether a thing you hit stops you: it's held fast or too heavy to shove.
func _solid(body: Object) -> bool:
	var loose := body as RigidBody3D
	return loose == null or loose.freeze or loose.mass >= SOLID_KG


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
## middle, and a lean into a carve its lower edge, which dug comes down to the
## sand and no further.
func _lowest(middle: float, nose: float, tail: float) -> float:
	return maxf(middle, (nose + tail) * 0.5) + lerpf(_tuning.board_clearance, SKIM, dig) + _edge * absf(sin(bank))


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
