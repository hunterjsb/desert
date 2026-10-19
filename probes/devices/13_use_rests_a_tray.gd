extends LineProbe
## Devices probe 13: use rests a deck's trays. The Surveyor's deck starts
## floating. Use at it sets it resting: it settles gently onto the sand and
## its trays draw nothing, while use at the shield stuck on it switches the
## shield and leaves the trays be. Use at it again and it floats. Saved
## resting, it resumes resting.

## A tray letting go would drop it at about 4 m/s; settled, it comes no faster
## than this, m/s.
const GENTLE := 1.5

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var kit := Runs.kit(world)
	var deck: Device = kit.filter(func(n: Node) -> bool: return n is Device and (n as Device).stats().lift_kg > 0.0)[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	await simulate(3.0)
	var draw := deck.demand_w()
	check(absf(clearance(deck) - deck.rest_height()) < 0.1 and draw > 0.0,
		"the Surveyor's deck starts floating, its trays drawing %.0f W" % draw)

	check(await _use_at(deck), "use at the deck does something")
	var seen := {"fastest": 0.0}
	await simulate(5.0, func() -> void: seen.fastest = maxf(seen.fastest, -deck.linear_velocity.y))
	print("resting, it settled %.2f m up, coming down at %.2f m/s at most, drawing %.0f W"
		% [clearance(deck), seen.fastest, deck.demand_w()])
	check(clearance(deck) < 0.5 and seen.fastest > 0.0 and seen.fastest < GENTLE,
		"set resting, it settles gently onto the sand")
	check(deck.demand_w() == 0.0, "resting, its trays draw nothing")

	check(await _use_at(shield) and shield.on and clearance(deck) < 0.5,
		"use at the shield stuck on it switches the shield, and the deck rests on")

	check(await _use_at(deck), "use at the deck again")
	await simulate(5.0)
	check(absf(clearance(deck) - deck.rest_height()) < 0.1 and absf(deck.demand_w() - draw) < draw * 1e-3,
		"and it floats again, drawing as before (%.3f, was %.3f W)" % [deck.demand_w(), draw])

	await _use_at(deck)
	await simulate(5.0)
	check(saves.save(world), "saved resting")
	check(await resume(), "resumed")
	var back: Array = world.devices().filter(func(d: Device) -> bool: return d.stats().lift_kg > 0.0)
	await simulate(3.0)
	check(back.size() == 1 and clearance(back[0]) < 0.5 and back[0].demand_w() == 0.0,
		"resumed, it's still resting on the sand, drawing nothing")


## Looks at a device from a metre and a half off its side, so the look ray
## meets it and nothing stuck on it, then uses it.
func _use_at(device: Device) -> bool:
	var middle := device.global_position
	look(middle + device.global_basis.x * 1.5 + Vector3.UP * 0.1, middle)
	await simulate(0.05)
	check(hands.look_device == device, "looking at the %s, the look ray meets it" % device.label)
	return hands.interact()
