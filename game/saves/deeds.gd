class_name Deeds
extends RefCounted
## What you've done across every run (Profile & saves, deeds): one table,
## and one hook every system records a deed through the moment it's done,
## never a check that goes looking for them. Only a player's own run counts
## (World.counts_deeds): a dev scenario's never does. A deed done is kept in
## the profile with its run, and a start that names it as its unlock opens.

## Each deed in the order the grid shows them: its name, the line saying
## what it asks (its X from the tuning field `x`, in place of %s), and
## optionally `hidden`, shown as ???? until done, and `need`, how many
## different things count toward it: every landmark, every age that left
## structures, or the number in a tuning field. A `landmark` deed is reached
## there, or at every landmark for ALL.
const TABLE := {
	&"board_height": {"name": "Big Air", "asks": "Fly %s m over the sand on a board", "x": "deed_board_height_m"},
	&"board_distance": {"name": "Frequent Flyer", "asks": "Ride a board %s km without stepping off",
		"x": "deed_board_km"},
	&"board_storm": {"name": "Flying Bling", "asks": "Ride into a storm by night or in an eclipse"},
	&"shield_storm": {"name": "Sandblasted", "asks": "Hold off %s minutes of storm with one shield",
		"x": "deed_storm_minutes"},
	&"shield_day": {"name": "Hermit", "asks": "Spend a whole day under a shield"},
	&"crops": {"name": "Crop Rotation", "asks": "Grow %s kinds of crop", "x": "deed_crop_kinds",
		"need": "deed_crop_kinds"},
	&"planters_towed": {"name": "Meals on Wheels", "asks": "Have %s planters in tow at once",
		"x": "deed_planters_towed"},
	&"sail_waist": {"name": "Set Sail", "asks": "Tie a sail's sheet at your waist"},
	&"deck_pieces": {"name": "Six Pack", "asks": "Join %s chassis pieces into one deck", "x": "deed_deck_pieces"},
	&"deck_home": {"name": "All Mod Cons", "asks": "A Console, a condenser and a crate on one deck"},
	&"power": {"name": "Power Trip", "asks": "Make over %s W in one system", "x": "deed_power_w"},
	&"port_morgan": {"name": "The Old City", "asks": "Reach Port Morgan", "landmark": &"port_morgan"},
	&"landmarks": {"name": "Hot Tourist Destinations", "asks": "Reach every named landmark", "landmark": &"*",
		"need": "landmarks"},
	&"ages": {"name": "Carbon Dated", "asks": "Stand in a structure of each of the four ages",
		"need": "ages"},
}
const ALL := &"*"
## What all deck_home asks to stand on one deck, by catalog id.
const HOME := [&"console", &"condenser", &"crate_frame"]


## The hook: a deed done in this world's run, now. With a `part`, that thing
## counts toward it, and it's done once enough different ones have. Says
## whether it was done just now; a deed already done, or a world whose deeds
## don't count, does nothing.
static func done(world: World, id: StringName, part: StringName = &"") -> bool:
	if world == null or not world.counts_deeds or not TABLE.has(id):
		return false
	var profile := world.get_node_or_null(^"/root/Profile")
	if profile == null or profile.did(id):
		return false
	if part != &"" and profile.toward(id, part) < need(id, world.tuning):
		return false
	var runs := world.get_node_or_null(^"../Runs")
	if not profile.deed(id, {"seed": world.run_seed, "origin": str(Kit.of(world).id),
			"ironman": runs != null and runs.ironman}):
		return false
	if Controls.ui != null:
		Controls.ui.note("Deed: " + str(TABLE[id].name))
	return true


## A landmark reached: the deed that asks for it, and one more toward every one.
static func reached(world: World, landmark: StringName) -> void:
	for id: StringName in TABLE:
		var at: StringName = TABLE[id].get("landmark", &"")
		if at == landmark:
			done(world, id)
		elif at == ALL:
			done(world, id, landmark)


## How many different things a deed made of several needs.
static func need(id: StringName, tuning: Tuning) -> int:
	var n: Variant = TABLE[id].get("need", "")
	match n:
		"":
			return 1
		"landmarks":
			return History.LANDMARKS.size()
		"ages":
			return Eras.BUILT.size()
	return int(tuning.get(n))


## Its X, as the tuning has it now.
static func x(id: StringName, tuning: Tuning) -> float:
	return float(tuning.get(TABLE[id].x)) if TABLE[id].has("x") else 0.0


## What it asks, its X in place.
static func line(id: StringName, tuning: Tuning) -> String:
	var asks: String = TABLE[id].asks
	return asks % _number(x(id, tuning)) if TABLE[id].has("x") else asks


## What a deed opens: the starts whose unlock names it.
static func opens(id: StringName) -> Array[Kit]:
	var out: Array[Kit] = []
	for kit in Kit.origins():
		if kit.unlock == id:
			out.append(kit)
	return out


## How many of the table this profile has done.
static func count(profile: Node) -> int:
	if profile == null:
		return 0
	return TABLE.keys().filter(func(id: StringName) -> bool: return profile.did(id)).size()


static func _number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
