extends SavesProbe
## Profile & saves probe 1: the round trip. A camp runs mid-storm: a shield
## up, a crate floating outside it on two lines to stakes, a planter growing
## inside, their batteries draining, a line from a stake to your waist and a
## battery in your hands. One run carries on a minute, never saved. Another,
## the same to the tick, is saved there; saving changes nothing in it, and
## resumed from the file into a fresh world on the same seed, the next
## minute matches the one never saved, within what physics repeats to. A
## save that drops one thing (how the floating crate was moving) doesn't.

## How close the resumed minute keeps to the one never saved: where things
## stand, m, and any number they carry. What physics repeats to: the same
## camp set up twice in fresh worlds lands a fraction of a millimetre apart.
const METRES := 0.02
const NUMBER := 0.01


func run() -> void:
	await load_camp()
	var start := reading()
	var never := await minute()
	check(never[-1].numbers["shield#0 Wh"] < start.numbers["shield#0 Wh"]
		and never[-1].numbers["crate_frame#2 Wh"] < start.numbers["crate_frame#2 Wh"], "their charges drain")
	check(never[-1].numbers["planter#1 growth 2"] > start.numbers["planter#1 growth 2"], "the planter's fungus grows")

	await fresh_world()
	await load_camp()
	var before := reading()
	var same := apart([start], [before])
	print("set up twice: %.5f m (%s), numbers %.5f" % [same.metres, same.where, same.number])
	check(same.missing == "" and same.metres <= METRES and same.number <= NUMBER, "the camp sets up the same")
	check(saves.save(world), "saved mid-storm")
	var after := apart([before], [reading()])
	check(after.metres == 0.0 and after.number == 0.0, "saving changes nothing")

	check(await resume(), "resumed")
	var drift := apart(never, await minute())
	print("resumed: %.5f m (%s), numbers %.5f (%s)" % [drift.metres, drift.where, drift.number, drift.which])
	check(drift.missing == "", "the resumed minute holds the same things (%s)" % drift.missing)
	check(drift.metres <= METRES, "everything stands where it would have, within %.2f m" % METRES)
	check(drift.number <= NUMBER, "every number matches, within %.2f" % NUMBER)

	# Broken on purpose: the save forgets how the floating crate was moving.
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	for rec: Dictionary in data.things:
		if rec.id == &"crate_frame":
			rec.v = Vector3.ZERO
			rec.w = Vector3.ZERO
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data)
	check(await resume(), "resumed the broken save")
	var broken := apart(never, await minute())
	print("broken: %.5f m (%s), numbers %.5f (%s)" % [broken.metres, broken.where, broken.number, broken.which])
	check(broken.metres > METRES, "a save that drops a field drifts past it")
