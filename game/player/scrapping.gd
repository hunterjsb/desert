class_name Scrapping
extends RefCounted
## Your hands at a wreck or a ruin with what you hold. Use on a piece of a
## wreck does that piece's work, or says what it needs; held down, a heat
## cutter traces a plate's seams and a scoop clears a hold or digs a ruin out
## of the sand a stroke at a time, sifted by a sieve near.

## What a piece of a wreck needs before it gives, said when you try it without.
const WRECK_NEEDS := {&"cut": "needs a heat cutter: hold use along its seams",
	&"clear": "needs a sand scoop: hold use on it", &"ground": "live: ground it with a stake first",
	&"seal": "breached: seal it first"}
## The cutter's hot spot off a seam, on one the sand holds, and flat.
const NO_SEAM := "trace the seam: the weld round its edge"
const SEAM_BURIED := "that seam's under the sand"
const CUTTER_FLAT := "the cutter's battery is flat"
## A scoop stroke takes this long, s.
const STROKE := 0.45
## A scoop on sand with no ruin under it, or on one dug out; a sieve this
## near the dig sifts it, m.
const NO_RUIN := "no ruin under this sand"
const DUG_OUT := "dug out: what's left is the weather's"
const SIFT_REACH := 4.0

var _hands: Hands
var _player: Player
var _tuning := Tuning.current()
## Until a scoop's next stroke, s.
var _stroke := 0.0


func _init(hands: Hands, player: Player) -> void:
	_hands = hands
	_player = player


## Use on a piece of a wreck: what you hold does that piece's work. A hazard's
## is done at once: a stake laid across a capacitor bank's terminals shorts it
## to the hull, and falls where it was; sealant is used up over a breached
## store. A cutter or a scoop works while use is held down (scrap). Without
## the tool for it, it says what it needs.
func work_once() -> bool:
	var what := Wreckage.work_of(_hands.look_work)
	var wreck: Wreckage = _hands.look_work.get_meta(&"wreckage")
	var op := Wreckage.tool_op(_hands.held) if _hands.phase == Hands.Phase.HELD else &""
	if op != what[0]:
		return _hands.refuse(WRECK_NEEDS[what[0]])
	if op == Wreckage.CUT or op == Wreckage.CLEAR:
		if op == Wreckage.CUT and not (_hands.held as Cutter).cuts():
			return _hands.refuse(CUTTER_FLAT)
		return true
	var at := _hands.look_point + _hands.look_normal * 0.12
	if not wreck.make_safe(_hands.look_work, op):
		return false
	var used := _hands.stow()
	if used is Stake:
		used.global_position = at
		used.freeze = false
		ScrapFx.burst(_player.world.content, _hands.look_point, 50, 3.5)
		Sounds.play_at(used, Sounds.ZAP, -4.0, 3.0)
		_hands.say("grounded: the bank's dead")
	else:
		Sounds.play_at(_player, Sounds.SEAL, -4.0, 2.0)
		used.queue_free()
		_hands.say("sealed")
	return true


## Use held down with a heat cutter or a scoop, for `delta` s. The cutter
## fires where you aim, and on a plate's seam its hot spot cuts the weld away
## as you trace it; a scoop clears the open slice of a hold a stroke at a
## time. Says whether it did any work.
func scrap(delta: float) -> bool:
	if _hands.phase != Hands.Phase.HELD or not is_instance_valid(_hands.held):
		return false
	var look_point := _hands.look_point
	var op := Wreckage.tool_op(_hands.held)
	var what := Wreckage.work_of(_hands.look_work)
	if op == Wreckage.CUT:
		var cutter := _hands.held as Cutter
		if not cutter.cuts():
			_hands.say(CUTTER_FLAT)
			return false
		if what.is_empty() or what[0] != Wreckage.CUT:
			cutter.fire(look_point if look_point != Vector3.ZERO else _hands.sight_to, false)
			return false
		var wreck: Wreckage = _hands.look_work.get_meta(&"wreckage")
		var label: String = wreck.plan.plates[what[1]].label
		var result := wreck.cut(_hands.look_work, look_point, delta)
		if not result.seam:
			cutter.fire(look_point, false)
			_hands.say(NO_SEAM)
			return false
		cutter.fire(result.at, not result.get("buried", false))
		if result.get("buried", false):
			_hands.say(SEAM_BURIED)
			return false
		if result.get("through", false):
			ScrapFx.burst(_player.world.content, result.at, 60, 3.0)
			_hands.say("the %s comes away" % label)
		return true
	if op == Wreckage.CLEAR and what.is_empty() and _hands.look_sand:
		return _dig(delta)
	if op != Wreckage.CLEAR or what.is_empty() or what[0] != Wreckage.CLEAR:
		return false
	var wreck: Wreckage = _hands.look_work.get_meta(&"wreckage")
	_stroke_on(delta)
	if not wreck.clear(_hands.look_work, delta):
		_hands.say(wreck.not_yet(_hands.look_work))
		return false
	return true


## Use let go: a scoop's next stroke is heard at once.
func stop() -> void:
	_stroke = 0.0


## A scoop at work is heard and sprays sand once a stroke.
func _stroke_on(delta: float) -> void:
	_stroke -= delta
	if _stroke <= 0.0:
		_stroke = STROKE
		var at := _hands.look_point
		Sounds.play_at(_player, Sounds.SCOOP, -4.0, 2.0)
		ScrapFx.spray(_player.world.content, at, _hands.sight_from - at, Wreckage.SAND)


## A scoop held on the sand over a ruin digs it out, a stroke and a spray at
## a time, as a storm would lay it bare (Sites.dig_at); a sieve in your suit
## or set down near sifts what it digs for the small things in it. A dune's
## ruin dug out with half its sand or more off by your hand is yours, not a
## storm's. Says whether it dug.
func _dig(delta: float) -> bool:
	var world := _player.world
	var at := _hands.look_point
	var got := world.shape.sites.dig_at(world.world_x(at.x), world.world_z(at.z), delta, world.time)
	var site: Structure = got[0]
	if site == null:
		_hands.say(NO_RUIN)
		return false
	if got[1] <= 0.0:
		_hands.say(DUG_OUT)
		return false
	_stroke_on(delta)
	if _sieved():
		_sift(site, got[2])
	if site.source == &"dune" and site.dug_m >= site.depth * _tuning.dig_own_share \
			and site.with_dug(site.pure_taken(world.time)) >= site.depth:
		Deeds.done(world, &"dune_dig")
	return true


## Whether a sieve sifts what you dig: carried, or lying or stuck on a deck near.
func _sieved() -> bool:
	for each in _player.suit.carried:
		if is_instance_valid(each) and each.get_meta(&"catalog", &"") == &"sieve":
			return true
	var world := _player.world
	for node in world.content.get_children():
		var near := node is Node3D and (node as Node3D).global_position.distance_to(_player.global_position) <= SIFT_REACH + 3.0
		if not near:
			continue
		var things: Array = (node as Chassis).camp() if node is Chassis else [node]
		for each: Node in things:
			if each is Node3D and each.get_meta(&"catalog", &"") == &"sieve" \
					and (each as Node3D).global_position.distance_to(_player.global_position) <= SIFT_REACH:
				return true
	return false


## What a sieve finds in `m3` more of a site's sand: one of the light things of
## its lesser rows (Drift.carried_from) each time sift_per_m3 more is
## through, from its own stream of the site's id and how many have come, laid
## on the sand at your feet.
func _sift(site: Structure, m3: float) -> void:
	var world := _player.world
	var before := floori(site.sifted_m3 * _tuning.sift_per_m3)
	site.sifted_m3 += m3
	for k in range(before, floori(site.sifted_m3 * _tuning.sift_per_m3)):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([site.id, "sift", k])
		var at := Vector2(world.player_world_x(), world.player_world_z()) + Vector2.from_angle(rng.randf() * TAU) * 0.8
		Drift.lay(world, {"id": Finds._pick(rng, Drift.carried_from(site)), "x": at.x, "z": at.y,
			"yaw": rng.randf() * TAU, "charge": rng.randf() * Drift.CHARGE,
			"layer": SiteLoot.ERAS[site.era].layer if SiteLoot.ERAS.has(site.era) else Finds.SURFACE})
		_hands.say("the sieve turns something up")
