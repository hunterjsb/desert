extends MenuProbe
## Dev probe 4: fresh starts you over and leaves what you carry. Hurt and
## fed, with a part of your own in your suit, fresh has you whole with no
## buffs, carrying the same things as before, that part among them.


func run() -> void:
	await open_main(false)
	await started()
	var vitals := world.player.vitals
	var suit := world.player.suit
	suit.carried.append(Catalog.part(&"battery"))
	var before := suit.carried.duplicate()
	vitals.health = 20.0
	vitals.buffs.fed = 100.0
	main.ui.dev_console.run("fresh")
	check(vitals.health == Vitals.FULL and not vitals.buffs.active(&"fed"), "whole, with no buffs")
	check(suit.carried == before, "carrying what you carried, your own part too (%d things, %d before)"
		% [suit.carried.size(), before.size()])
