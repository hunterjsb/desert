extends LineProbe
## Survival probe 10: stakes go in. A found stake, taken up, goes in with what
## you carry as it is, riding on you, and the view shows it as a stake. A
## driven stake, or one with a line on its eye, stays out. A loose stake goes
## in and comes out in your hands ready to drive: used over the sand it goes
## in, and holds a crate floating downwind on a line. The found one, saved
## carried and resumed into a fresh world, comes out and does the same.

## The breeze the crates float in, m/s, downwind along +x.
const BREEZE := 8.0

var suit: Suit


func run() -> void:
	await load_lines(1234, true)
	suit = world.player.suit
	var here := world.player.global_position
	var spec := {"index": 951, "id": &"stake", "device": true, "layer": Finds.SURFACE,
		"x": world.world_x(here.x) - 1.2, "z": world.world_z(here.z) + 0.6, "yaw": 0.3, "lean": 0.0,
		"lean_by": 0.0, "bury": 0.0, "loose": true, "sound": 1.0, "charge": 0.0, "fill": []}
	var found := world.salvage.lay(world.terrain.chunk_at(spec.x, spec.z), spec) as Stake
	await simulate(1.0)
	check(await _stows(found), "a found stake, taken up, goes in")
	var shown := Suit._name(suit.stacks()[stack_of(found)][0]) if stack_of(found) != -1 else "-"
	print("carried: %s" % shown)
	check(shown == "Stake", "the view shows it as a stake")

	var driven := driven_stake(here + Vector3(-1.0, 0.0, -2.0))
	check(not suit.fits(driven), "a driven stake stays out")
	var tied := _lying(here + Vector3(1.0, 0.0, -2.0))
	Line.between(world, driven.free_tie(tied.global_position), tied.free_tie(driven.global_position), 0.5)
	await simulate(0.5)
	hands.hold(tied)
	await simulate(0.5)
	check(not suit.put_in() and hands.held == tied, "a stake with a line on its eye stays out")
	hands.drop()
	await simulate(0.5)

	var loose := _lying(here + Vector3(0.0, 0.0, 1.2))
	await simulate(0.5)
	check(await _stows(loose), "a loose stake, taken up, goes in")
	check(await _drives(loose, here + Vector3(0.0, 0.0, 1.5)), "it comes out ready to drive, and drives")
	check(await _holds(loose), "driven, it holds a line")

	check(get_node(^"/root/Saves").save(world), "saved, carrying the found stake")
	check(await resume(), "resumed")
	suit = world.player.suit
	var back := suit.carried[-1] as Stake if not suit.carried.is_empty() else null
	check(back != null and back.has_meta(&"layer"), "the found stake is carried again")
	if back == null:
		return
	check(await _drives(back, here + Vector3(0.0, 0.0, -1.5)), "it comes out ready to drive, and drives")
	check(await _holds(back), "driven, it holds a line")


## A stake lying flat on the sand.
func _lying(at: Vector3) -> Stake:
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.global_transform = Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(at.x, world.height_under(at) + 0.04,
		at.z))
	return stake


## Taken up and put in: carried as it is, on you, out of sight.
func _stows(stake: Stake) -> bool:
	if not await take(stake):
		return false
	await simulate(0.5)
	return hands.held == stake and suit.put_in() and hands.held == null and suit.carried.has(stake) \
		and stake.get_parent() == world.player and not stake.visible


## Taken out into your hands, and used over the sand at a place.
func _drives(stake: Stake, at: Vector3) -> bool:
	if not suit.take_out(stack_of(stake)):
		return false
	await simulate(0.5)
	if hands.held != stake or stake.driven:
		return false
	at.y = world.height_under(at)
	look(eye(), at)
	await simulate(1.0 / 60.0)
	return hands.interact() and stake.driven and hands.held == null


## A crate floating on a line from a driven stake, in a breeze: the stake
## stays where it was driven, taking the pull.
func _holds(stake: Stake) -> bool:
	var crate := floating(&"crate_frame", stake.global_position + Vector3(1.5, 0.0, 0.0))
	var line := lay(crate, stake, 0.5)
	var at := stake.global_position
	blow(Vector2(BREEZE, 0.0))
	await simulate(5.0)
	blow(Vector2.ZERO)
	var off := flat(crate.global_position - at).length()
	print("in %.0f m/s: the stake takes %.1f N, the crate %.2f m off on %.2f m of line"
		% [BREEZE, stake.sustained, off, line.full])
	return ropes.ropes.has(line.rope) and stake.driven and stake.global_position == at and stake.sustained > 0.0
