extends MenuProbe
## Dev probe 4: fresh fills you up and leaves what you carry. Hurt, hungry and
## parched, with a part of your own in your suit, fresh has you whole, fed and
## watered, carrying the same things as before, that part among them.


func run() -> void:
	await open_main(false)
	await started()
	var vitals := world.player.vitals
	var suit := world.player.suit
	suit.carried.append(Catalog.part(&"battery"))
	var before := suit.carried.duplicate()
	vitals.health = 20.0
	vitals.hunger = 10.0
	vitals.thirst = 5.0
	main.ui.dev_console.run("fresh")
	check(vitals.health == Vitals.FULL and vitals.hunger == Vitals.FULL and vitals.thirst == Vitals.FULL,
		"whole, fed and watered")
	check(suit.carried == before, "carrying what you carried, your own part too (%d things, %d before)"
		% [suit.carried.size(), before.size()])
