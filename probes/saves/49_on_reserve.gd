extends DeckProbe
## Profile & saves probe 49: On Reserve. A power box on a deck, a charged
## battery in its bay, and a shield running: while a feed makes more than
## the shield draws, nothing; with the feed off, the box's battery carries
## the camp: On Reserve.


## What makes power on the deck, as much as the probe says.
class Feed extends Device:
	var watts := 500.0

	func production_w(_t := NAN) -> float:
		return watts


func run() -> void:
	await load_lines()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var deck := piece(spot(0.0, 4.0))
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, 0.22), 0.0, Rig.make([&"power_box", [&"battery"]], 0.5))
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.28, -0.3), 0.0, shield)
	var feed := Feed.new()
	Stick.put(deck, deck, Chassis.TOP, Vector2(-0.3, -0.3), 0.0, feed)
	shield.switch(true)
	await simulate(2.0)
	check(shield.powered and not profile.did("on_reserve"), "made more than drawn: nothing")
	feed.watts = 0.0
	await simulate(2.0)
	check(shield.powered and profile.did("on_reserve"), "the box's battery carries the shield: On Reserve")
