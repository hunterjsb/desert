extends SailProbe
## Profile & saves probe 41: a rigged camp resumes. A deck on skates with its
## mast, the sail raised and its sheet made fast, sails across a steady wind.
## Saved and resumed into a fresh world on the same seed, the same camp is
## where it was: on runners under every piece, the mast standing on its
## piece, the sail raised, swung and trimmed as it was, the sheet on the
## boom's end. And it sails on where the one never saved went.

## As close as the round trip holds a sailing camp, m.
const METRES := 0.05

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_sailing()
	rig(open, heading())
	blow(downwind * 10.0)
	hoist(60.0)
	course = heading()
	await sail_for(8.0)
	var before := _reading()
	print("saved: ", before)
	check(before.runners == 4 and before.raised and before.sheeted and before.speed > 2.0, "the camp sails, its sheet made fast")
	check(saves.save(world), "saved")
	await sail_for(4.0)
	var never := _at(deck)

	check(await resume(), "resumed")
	var decks := world.content.get_children().filter(func(n: Node) -> bool: return n is Chassis)
	check(decks.size() == 1, "one deck came back")
	if decks.is_empty():
		return
	deck = decks[0]
	var masts := deck.mounted().filter(func(d: Device) -> bool: return d is Mast)
	check(masts.size() == 1, "its mast stands on it")
	if masts.is_empty():
		return
	mast = masts[0]
	var after := _reading()
	print("resumed: ", after)
	var moved: float = before.at.distance_to(after.at)
	after.at = before.at
	check(moved < 1e-3 and str(after) == str(before), "the same camp, where it was, rigged as it was (%.5f m off)" % moved)
	await sail_for(4.0)
	var apart := _at(deck).distance_to(never)
	print("resumed: %.4f m from the one never saved" % apart)
	check(apart < METRES, "and it sails on where it would have, within %.2f m" % METRES)


## What a save must keep of a rigged camp.
func _reading() -> Dictionary:
	var on: Chassis = deck._piece_of(mast) if deck._piece_of(mast) != null else deck
	return {"at": _at(deck), "runners": deck.glider.runners.size() if deck.glider != null else 0, "mast_on": on.cell,
		"raised": mast.raised, "raise": snappedf(mast.raise, 1e-4), "sheet": snappedf(mast.sheet().length, 1e-4) if mast.sheet() != null else 0.0,
		"boom": snappedf(mast.boom, 1e-4), "sail_m2": snappedf(mast.sail_m2(), 1e-3), "sheeted": mast.sheeted(),
		"speed": snappedf(way().length(), 1e-3)}


func _at(body: Node3D) -> Vector3:
	return Vector3(world.world_x(body.global_position.x), body.global_position.y, world.world_z(body.global_position.z))
