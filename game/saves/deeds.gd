class_name Deeds
extends RefCounted
## What you've done across every run (Profile & saves, deeds): one table,
## and one hook every system records a deed through the moment it's done,
## never a check that goes looking for them. Only a player's own run counts
## (World.counts_deeds): a dev scenario's never does, nor one while the dev
## console's god holds you. A deed done is kept in
## the profile with its run, and a start that names it as its unlock opens.
## Deeds wait on others (`after`), so they open a branch at a time; one done
## early is kept all the same, and shows once its branch opens.

const ALL := &"*"
## What all deck_home asks to be stuck on one deck, by catalog id.
const HOME := [&"console", &"condenser", &"battery"]
## Each deed in the order the grid lays them out, a family a column or two:
##   name; asks, what it asks, its goal in place of %s; family; after, the
##   deeds it waits on; icon, its card's thing (ItemIcons), or a mark drawn
##   (DeedsGrid): a sail, or a landmark's for none;
##   goal, a number to reach (measure) or of different things to count
##   (`parts`): a tuning field, or every landmark, every age that built, or
##   the home's three; unit, what its progress counts; step, how much better
##   a best must be before the profile keeps it;
##   landmark, where it's reached, or every landmark for ALL; hidden, ????
##   until done (none is).
const TABLE := {
	&"board_distance": {"name": "Frequent Flyer", "asks": "Ride a board %s m without stepping off", "family": &"board",
		"icon": &"board", "goal": "deed_board_m", "unit": "m", "step": 250.0},
	&"board_height": {"name": "Big Air", "asks": "Fly %s m over the sand on a board", "family": &"board",
		"after": [&"board_distance"], "icon": &"board", "goal": "deed_board_height_m", "unit": "m", "step": 0.5},
	&"board_storm": {"name": "Flying Bling", "asks": "Ride into a storm by night or in an eclipse", "family": &"board",
		"after": [&"board_height"], "icon": &"board"},
	&"shield_day": {"name": "Hermit", "asks": "Spend a whole day under a shield, never stepping out",
		"family": &"shield", "icon": &"shield", "goal": "day_minutes", "unit": "min", "step": 1.0},
	&"shield_storm": {"name": "Sandblasted", "asks": "Hold off %s minutes of storm with one shield", "family": &"shield",
		"after": [&"shield_day"], "icon": &"shield", "goal": "deed_storm_minutes", "unit": "min", "step": 1.0},
	&"crop": {"name": "Green Thumb", "asks": "Grow a crop", "family": &"farm", "icon": &"crop"},
	&"crops": {"name": "Crop Rotation", "asks": "Grow %s kinds of crop", "family": &"farm", "after": [&"crop"],
		"icon": &"planter", "goal": "deed_crop_kinds", "parts": true, "unit": "kinds"},
	&"planters_towed": {"name": "Meals on Wheels", "asks": "Have %s planters in tow at once", "family": &"farm",
		"after": [&"crop"], "icon": &"planter", "goal": "deed_planters_towed", "unit": "planters", "step": 1.0},
	&"deck_home": {"name": "All Mod Cons", "asks": "A Console, a condenser and a battery on one deck", "family": &"camp",
		"icon": &"console", "goal": "home", "unit": "on one deck", "step": 1.0},
	&"sail_waist": {"name": "Set Sail", "asks": "Tie a sail's sheet at your waist", "family": &"camp", "icon": &"sail"},
	&"deck_pieces": {"name": "Six Pack", "asks": "Join %s chassis pieces into one deck", "family": &"camp",
		"after": [&"deck_home"], "icon": &"chassis", "goal": "deed_deck_pieces", "unit": "pieces", "step": 1.0},
	&"power": {"name": "Power Trip", "asks": "Make %s W in one system", "family": &"camp", "after": [&"sail_waist"],
		"icon": &"turbine", "goal": "deed_power_w", "unit": "W", "step": 10.0},
	&"port_morgan": {"name": "The Old City", "asks": "Reach Port Morgan", "family": &"story", "landmark": &"port_morgan"},
	&"ages": {"name": "Carbon Dated", "asks": "Stand in a structure of each of the four ages", "family": &"story",
		"goal": "ages", "parts": true, "unit": "ages"},
	&"landmarks": {"name": "Hot Tourist Destinations", "asks": "Reach every named landmark", "family": &"story",
		"after": [&"port_morgan"], "landmark": ALL, "goal": "landmarks", "parts": true, "unit": "landmarks"},
}
## The hook: a deed done in this world's run, now. With a `part`, that thing
## counts toward it, and it's done once enough different ones have. Says
## whether it was done just now; a deed already done, or a world whose deeds
## don't count, does nothing.
static func done(world: World, id: StringName, part: StringName = &"") -> bool:
	var profile := _counting(world, id)
	if profile == null:
		return false
	if part != &"" and profile.toward(id, part) < goal(id, world.tuning):
		return false
	var runs := world.get_node_or_null(^"../Runs")
	if not profile.deed(id, {"seed": world.run_seed, "origin": str(Kit.of(world).id),
			"ironman": runs != null and runs.ironman}):
		return false
	# Said once it shows: done in its branch, with any done early that it opens.
	var said := PackedStringArray()
	if is_open(profile, id):
		said.append(TABLE[id].name)
		for each: StringName in TABLE:
			if TABLE[each].get("after", []).has(id) and profile.did(each) and is_open(profile, each):
				said.append(TABLE[each].name)
	if Controls.ui != null and not said.is_empty():
		Controls.ui.note("Deed: " + ", ".join(said))
	return true


## How far toward a deed that's a number to reach, as it stands now: the
## best kept a step at a time, and the deed done once it's reached.
static func measure(world: World, id: StringName, value: float) -> void:
	var profile := _counting(world, id)
	if profile == null:
		return
	if value >= profile.best(id) + TABLE[id].get("step", 1.0):
		profile.improve(id, floorf(value / TABLE[id].step) * TABLE[id].step)
	if value >= goal(id, world.tuning):
		done(world, id)


## A landmark reached: the deed that asks for it, and one more toward every one.
static func reached(world: World, landmark: StringName) -> void:
	for id: StringName in TABLE:
		var at: StringName = TABLE[id].get("landmark", &"")
		if at == landmark:
			done(world, id)
		elif at == ALL:
			done(world, id, landmark)


## The profile a deed would be kept in now, or null: none, a world whose
## deeds don't count or whose player the dev console's god holds, or the
## deed done already.
static func _counting(world: World, id: StringName) -> Node:
	if world == null or not world.counts_deeds or world.player.vitals.god or not TABLE.has(id):
		return null
	var profile := world.get_node_or_null(^"/root/Profile")
	return null if profile == null or profile.did(id) else profile


## What a deed asks you to reach, or how many different things.
static func goal(id: StringName, tuning: Tuning) -> float:
	var named: String = TABLE[id].get("goal", "")
	match named:
		"":
			return 1.0
		"landmarks":
			return History.LANDMARKS.size()
		"ages":
			return Eras.BUILT.size()
		"home":
			return HOME.size()
	return float(tuning.get(named))


## Its branch is open: everything it waits on done, and open in turn.
static func is_open(profile: Node, id: StringName) -> bool:
	for before: StringName in TABLE[id].get("after", []):
		if profile == null or not profile.did(before) or not is_open(profile, before):
			return false
	return true


## Done and showing so.
static func lit(profile: Node, id: StringName) -> bool:
	return profile != null and profile.did(id) and is_open(profile, id)


## How many show done.
static func count(profile: Node) -> int:
	return TABLE.keys().filter(func(id: StringName) -> bool: return lit(profile, id)).size()


## What it asks, its goal in place.
static func line(id: StringName, tuning: Tuning) -> String:
	var asks: String = TABLE[id].asks
	return asks % number(goal(id, tuning)) if "%s" in asks else asks


## How far along you are, as "3,250 / 5,000 m", or "" for a deed that's
## done at once.
static func progress(profile: Node, id: StringName, tuning: Tuning) -> String:
	var spec: Dictionary = TABLE[id]
	if not spec.has("unit") or profile == null:
		return ""
	var target := goal(id, tuning)
	var got: float = profile.toward_count(id) if spec.get("parts", false) else profile.best(id)
	if profile.did(id):
		got = maxf(got, target)
	return ("%s / %s %s" % [number(got, target < 10.0), number(target), spec.unit]).strip_edges()


## What a deed opens: the starts whose unlock names it.
static func opens(id: StringName) -> Array[Kit]:
	var out: Array[Kit] = []
	for kit in Kit.origins():
		if kit.unlock == id:
			out.append(kit)
	return out


## A number as the grid says it: whole numbers in thousands, a tenth if it's small.
static func number(value: float, tenths := false) -> String:
	if tenths and not is_equal_approx(value, roundf(value)):
		return "%.1f" % value
	var digits := str(roundi(value))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(-3)
	return digits + out
