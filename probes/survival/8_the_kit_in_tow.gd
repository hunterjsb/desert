extends LineProbe
## Survival probe 8: the kit in tow. In a crosswind you take up the stake the
## kit's crate is moored to, tie it at your waist and walk off: the crate
## follows on its line, floating all the way, and its shield's bubble, on
## and seated on it, comes with it.

const AWAY := 40.0
const CROSSWIND := 8.0


func run() -> void:
	await load_lines()
	blow(Vector2(CROSSWIND, 0.0), 0.2)
	var kit := Runs.kit(world)
	var crate: Device = kit.filter(func(n: Node) -> bool: return n is Device and (n as Device).stats().lift_kg > 0.0)[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var stake: Stake = kit.filter(func(n: Node) -> bool: return n is Stake)[0]
	var line: Line = kit.filter(func(n: Node) -> bool: return n is Line)[0]
	await simulate(2.0)
	check(shield.interact(world.player), "use switches the crate's shield on")
	var heading := flat(stake.global_position - crate.global_position).normalized()
	var head := stake.global_position + Vector3.UP * 0.3
	look(head - heading * 1.0 + Vector3.UP * 1.2, head)
	await simulate(0.05)
	var taken := hands.grab()
	await simulate(0.5)
	check(taken and hands.held == stake and world.player.waist.take_from_hands(),
		"you take up its stake and tie it at your waist")
	var bubble_was := shield.shelter.global_position
	var seen := {"low": INF, "far": 0.0, "dark": 0}
	await walk_to(world.player.global_position + heading * AWAY, func() -> void:
		seen.low = minf(seen.low, clearance(crate))
		seen.far = maxf(seen.far, flat(crate.global_position - world.player.global_position).length())
		seen.dark += int(not shield.running()))
	await simulate(3.0)
	var reach := line.full * (1.0 + world.tuning.rope_max_stretch) + 1.5
	var carried := flat(shield.shelter.global_position - bubble_was).length()
	print("towed %.0f m: the crate %.2f m over the sand at lowest, at most %.1f m behind you; its bubble came %.1f m"
		% [AWAY, seen.low, seen.far, carried])
	check(seen.low > 0.8 and crate.stats().hovering, "the crate floats all the way")
	check(seen.far <= reach and world.player.waist.holds(stake), "it follows on its line (%.1f m of %.1f)" % [seen.far, reach])
	check(seen.dark == 0 and carried > AWAY - 8.0 and shield.host() == crate,
		"its shield's bubble comes with it, up all the way")
