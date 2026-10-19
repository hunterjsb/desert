class_name Tumble
extends RefCounted
## Thrown off the board, you tumble on over the sand with the way you had.
## You go over onto it, and each time you come down hard you hit it: the sand
## takes a share of your way, and what's left throws you up into the next
## roll, rolling over as a body does and never faster. Too slow to bounce,
## you plough to a stop and roll onto your side; you lie a moment, then get
## up. Something solid stops you as it would on foot. Your view, the sand
## and the thuds are Feel's; this only moves you. Stepped at a fixed rate
## inside each tick, as the ride is, so it goes the same way at any tick rate.

const STEP_HZ := 240.0
## Thrown, you leave the board this fast upward, m/s; off a landing you're
## slammed down this fast instead.
const POP := 0.5
const SLAM := -2.0
## You go over onto the sand over about this long, s.
const OVER_SECONDS := 0.3
## Coming down this fast or faster, m/s, you hit: the sand takes this share
## of your way, and throws you up into the next roll at this much for each
## m/s left, at most HOP_MOST, m/s.
const HIT_FROM := 1.0
const HIT_TAKES := 0.4
const HOP := 0.25
const HOP_MOST := 2.4
## Down on the sand, ploughing it takes this many g of your way.
const PLOUGH := 1.0
## You roll over this many radians a second for each m/s of your way, never
## faster than SPIN_MOST: a body rolls about once a second at most.
const SPIN := 0.5
const SPIN_MOST := 4.7
## Down, you roll onto your side at about this rate, Hz; slower than STILL,
## m/s, you've come to rest. You lie LIE s, then get up over GET_UP s; still
## going after LONGEST s, you stop anyway.
const SETTLE_HZ := 1.5
const STILL := 0.2
const LIE := 0.5
const GET_UP := 0.6
const LONGEST := 8.0
## Thrown off something solid, you come back off it at this share of the way
## you hit it with.
const REBOUND := 0.3

var player: Player
## How you came off (Ride.thrown).
var how: StringName
## Your way over the ground, m/s along engine x and z; how high you are off
## the sand, m, and how fast you rise, m/s.
var velocity := Vector2.ZERO
var lift := 0.0
var vy := 0.0
## How far you've rolled over, radians, positive toward your right, and how
## fast; how far you've gone over onto the sand from standing, 0 to 1; how
## long you've lain at rest, s, and how far you've got up, 0 to 1.
var rolled := 0.0
var spin := 0.0
var over := 0.0
var lain := 0.0
var rising := 0.0
## The way you were thrown with, m/s, the times you hit the sand and the
## hardest, m/s, how far you've tumbled, m, and for how long, s.
var thrown_with := 0.0
var hits := 0
var hardest := 0.0
var came := 0.0
var age := 0.0
## How far you went last tick: what drawing smooths between ticks.
var last_step := Vector3.ZERO

var _side := 1.0
var _touching := false
## Rolled, over and rising as the last tick left them, which drawing eases from.
var _was := Vector3.ZERO


## Thrown with `way`, m/s over the ground, toward `side` (1 your right), and
## `back` off what you struck.
func _init(by: Player, way: Vector2, thrown: StringName, side: float, back := Vector2.ZERO) -> void:
	player = by
	how = thrown
	_side = side
	velocity = way + back
	thrown_with = way.length()
	var at := Vector2(by.global_position.x, by.global_position.z)
	lift = maxf(0.0, by.global_position.y - _height(at))
	vy = SLAM if thrown == &"landing" else POP
	# Into a wall, you go over as hard as you hit it.
	spin = side * minf(SPIN * maxf(thrown_with, back.length() / REBOUND), SPIN_MOST)


## One tick of the tumble.
func step(delta: float) -> void:
	var world := player.world
	var g := world.gravity
	var n := maxi(1, roundi(delta * STEP_HZ))
	var h := delta / n
	var from := player.global_position
	var at := Vector2(from.x, from.z)
	var hit := 0.0
	_was = Vector3(rolled, over, rising)
	for i in n:
		var grade := Vector2(_height(at + Vector2(0.5, 0.0)) - _height(at - Vector2(0.5, 0.0)),
			_height(at + Vector2(0.0, 0.5)) - _height(at - Vector2(0.0, 0.5)))
		var rise := grade.dot(velocity)
		over = minf(1.0, over + h / OVER_SECONDS)
		vy -= g * h
		lift += (vy - rise) * h
		_touching = lift <= 0.0
		if _touching:
			var into := rise - vy
			lift = 0.0
			vy = rise
			if into > HIT_FROM:
				var lost := velocity * HIT_TAKES
				velocity -= lost
				hit = maxf(hit, Vector2(into, lost.length()).length())
				hits += 1
				vy += minf(HOP * velocity.length(), HOP_MOST)
				spin = _side * minf(SPIN * velocity.length(), SPIN_MOST)
			else:
				# Down, the slope pulls you as it pulls a slide, you plough to a
				# stop, and you roll onto whichever side you're nearer, never a
				# snap.
				velocity -= grade * g / (1.0 + grade.length_squared()) * h
				velocity = velocity.move_toward(Vector2.ZERO, PLOUGH * g * h)
				var side := roundf((rolled - PI * 0.5) / PI) * PI + PI * 0.5
				var w := TAU * SETTLE_HZ
				spin += (w * w * (side - rolled) - 2.0 * w * spin) * h
		rolled += spin * h
		age += h
		if _touching and (velocity.length() < STILL or age > LONGEST):
			velocity = Vector2.ZERO
			lain += h
			if lain >= LIE:
				rising = minf(1.0, rising + h / GET_UP)
		at += velocity * h
		came += velocity.length() * h
	_move(from, at - Vector2(from.x, from.z), delta)
	if hit > 0.0:
		hardest = maxf(hardest, hit)
		player.tumbled.emit(hit)
	Deeds.measure(world, &"yard_sale", came)


## A tick it waited for ground not yet solid: nothing moved, nothing to draw.
func wait() -> void:
	last_step = Vector3.ZERO
	_was = Vector3(rolled, over, rising)


## Whether you've got up: the tumble is over.
func up() -> bool:
	return rising >= 1.0


## Whether you're down on the sand and still going, ploughing it.
func ploughing() -> bool:
	return _touching and velocity.length() >= STILL


## How far you've rolled, gone over and got up, as the tick left them or as
## drawn this frame between the last tick and this one.
func view(drawn: bool) -> Vector3:
	var now := Vector3(rolled, over, rising)
	return _was.lerp(now, Engine.get_physics_interpolation_fraction()) if drawn else now


## Carries you there: exactly, over open sand, so the path is the same at any
## tick rate; stopped short by anything solid, as far as it let you go.
func _move(from: Vector3, moved: Vector2, delta: float) -> void:
	var to := Vector2(from.x + moved.x, from.z + moved.y)
	var y := _height(to) + lift
	player.velocity = Vector3(moved.x, y - from.y, moved.y) / delta
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
		player.global_position = Vector3(to.x, y, to.y)
	else:
		var under := _height(Vector2(player.global_position.x, player.global_position.z))
		player.global_position.y = maxf(player.global_position.y, under)
		lift = player.global_position.y - under
	player.velocity = Vector3(velocity.x, vy, velocity.y)
	last_step = player.global_position - from


## The ground's one function under an engine place.
func _height(at: Vector2) -> float:
	var world := player.world
	return world.height_at(world.world_x(at.x), world.world_z(at.y))
