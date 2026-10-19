extends LineProbe
## Rope & tethering probe 15: only into the sand. Standing, you take up the
## kit's stake, the deck's line on its ring. Used at a look at the sand a few
## steps off, out of reach, and then at the deck beside you, it stays in your
## hand each time, neither driven nor at your waist, and the readout says why.
## A look at the sand in reach drives it there at the ground's height, and
## looking out over the sand, use ties it at your waist to tow the deck.


func run() -> void:
	await load_lines()
	var kit := Runs.kit(world)
	await simulate(2.0)
	var stake: Stake = kit.filter(func(n: Node) -> bool: return n is Stake)[0]
	var deck: Device = kit.filter(func(n: Node) -> bool: return n is Chassis)[0]
	var toward := flat(deck.global_position - stake.global_position).normalized()
	_stand(stake.global_position + toward * 1.2, stake.global_position + Stake.RING * 0.5)
	await simulate(2.0 / 60.0)
	check(hands.grab() and hands.held == stake, "you take up the kit's stake")
	await simulate(0.5)

	var ahead := world.player.global_position - toward * 3.0
	_stand(world.player.global_position, Vector3(ahead.x, world.height_under(ahead), ahead.z))
	await simulate(2.0 / 60.0)
	check(_kept(), "used at sand out of reach, it stays in your hand and says why")
	await walk_to(deck.global_position - toward * 1.8)
	_stand(world.player.global_position, deck.global_position)
	await simulate(2.0 / 60.0)
	check(_kept(), "used at the deck, it stays in your hand and says why")

	var near := world.player.global_position - toward * 1.0
	_stand(world.player.global_position, Vector3(near.x, world.height_under(near), near.z))
	await simulate(2.0 / 60.0)
	check(hands.interact() and stake.driven and hands.held == null and absf(stake.global_position.y
		- world.height_under(stake.global_position) - Stake.DRIVEN_AT) < 0.001, "at sand in reach, it goes in there")
	_stand(world.player.global_position, stake.global_position + Stake.RING * 0.5)
	await simulate(2.0 / 60.0)
	hands.grab()
	await simulate(0.5)
	_stand(world.player.global_position, world.player.global_position - toward * 10.0 + Vector3.UP * 1.6)
	await simulate(2.0 / 60.0)
	check(hands.held == stake and hands.interact() and world.player.waist.holds(stake),
		"looking out over the sand, use ties it at your waist")


## Standing at a place, your eyes at their height, looking at a point.
func _stand(feet: Vector3, at: Vector3) -> void:
	look(Vector3(feet.x, world.height_under(feet) + world.player.camera.position.y, feet.z), at)


## Use, and the stake is still in your hand, not driven, not at your waist,
## with the readout saying why.
func _kept() -> bool:
	var stake := hands.held as Stake
	hands.notice = ""
	hands.interact()
	return stake != null and hands.held == stake and not stake.driven and not world.player.waist.holds(stake) \
		and hands.notice != ""
