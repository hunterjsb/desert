class_name Deeds
extends RefCounted
## What you've done across every run (Profile & saves, deeds): one table,
## and one hook every system records a deed through the moment it's done,
## never a check that goes looking for them. Only a player's own run counts
## (World.counts_deeds): never a dev run, one a dev scenario or a dev command
## that changed it has made one. A deed done is kept in the profile with its
## run, a start that names it as its unlock opens, and its badge shows.
## Deeds wait on others (`after`), so they open a branch at a time; one done
## early is kept all the same, and shows once its branch opens.

const ALL := &"*"
## What all deck_home asks to be stuck on one deck, by catalog id.
const HOME := [&"console", &"condenser", &"battery"]
## An anomaly's tells, each noticed where it's shown to you.
const TELLS := [&"compass", &"crackle", &"load"]
## What the archaeology setup asks on one deck: a Console with a ground radar
## fitted, a scoop and a sieve.
const SETUP := [&"ground_radar", &"sand_scoop", &"sieve"]
## Each deed in the order the grid lays them out, a family a branch or two:
##   name; asks, what it asks, its goal in place of %s; family; after, the
##   deeds it waits on; icon, its card's thing (ItemIcons), or a mark drawn
##   (DeedsGrid), a landmark's for none;
##   goal, a number to reach (measure) or of different things to count
##   (`parts`): a tuning field, or every landmark, every age that built,
##   the home's three, the tells, every god or every wreck kind; unit, what
##   its progress counts; step, how much better a best must be before the
##   profile keeps it;
##   landmark, where it's reached, or every landmark for ALL; hidden, ????
##   and no picture until it's done, so the grid never says what it is.
const TABLE := {
	&"board_distance": {"name": "Frequent Flyer", "asks": "Ride a board %s m without stepping off", "family": &"board",
		"icon": &"board", "goal": "deed_board_m", "unit": "m", "step": 250.0},
	&"board_height": {"name": "Big Air", "asks": "Fly %s m over the sand on a board", "family": &"board",
		"after": [&"board_distance"], "icon": &"board", "goal": "deed_board_height_m", "unit": "m", "step": 0.5},
	&"board_storm": {"name": "Flying Bling", "asks": "Ride into a storm by night or in an eclipse", "family": &"board",
		"after": [&"board_height"], "icon": &"board"},
	&"yard_sale": {"name": "Yard Sale", "asks": "Tumble %s m in one wipeout", "family": &"board",
		"after": [&"board_height"], "icon": &"board", "goal": "deed_tumble_m", "unit": "m", "step": 1.0, "hidden": true},
	&"sail_waist": {"name": "Set Sail", "asks": "Tie a sail's sheet at your waist", "family": &"wind", "icon": &"sail"},
	&"cast_off": {"name": "Cast Off", "asks": "Release %s waist lines together", "family": &"wind",
		"after": [&"sail_waist"], "icon": &"sail", "goal": "deed_release_lines", "unit": "lines", "step": 1.0},
	&"hand_me_down": {"name": "Hand-Me-Down", "asks": "Take the sail off a wrecked nomad rig", "family": &"wind",
		"after": [&"sail_waist"], "icon": &"sail"},
	&"telltale": {"name": "Telltale", "asks": "Trim a sail with a streamer flying on its rig", "family": &"wind",
		"after": [&"hand_me_down"], "icon": &"streamer"},
	&"close_hauled": {"name": "Close-Hauled", "asks": "Make %s m upwind under sail", "family": &"wind",
		"after": [&"sail_waist"], "icon": &"sail", "goal": "deed_upwind_m", "unit": "m", "step": 50.0},
	&"land_yacht": {"name": "Land Yacht", "asks": "Sail a keeled camp %s m from its helm", "family": &"wind",
		"after": [&"close_hauled"], "icon": &"helm", "goal": "deed_yacht_m", "unit": "m", "step": 250.0},
	&"storm_runner": {"name": "Storm Runner", "asks": "Sail %s m on a storm's outflow, ahead of its wall",
		"family": &"wind", "after": [&"land_yacht"], "icon": &"storm", "goal": "deed_outflow_m", "unit": "m",
		"step": 100.0},
	&"shield_day": {"name": "Hermit", "asks": "Spend a whole day under a shield, never stepping out",
		"family": &"weather", "icon": &"shield", "goal": "day_minutes", "unit": "min", "step": 1.0},
	&"shield_storm": {"name": "Sandblasted", "asks": "Hold off %s minutes of storm with one shield", "family": &"weather",
		"after": [&"shield_day"], "icon": &"shield", "goal": "deed_storm_minutes", "unit": "min", "step": 1.0},
	&"anomaly_eye": {"name": "Eye of the Anomaly", "asks": "Live through an anomaly's heart", "family": &"weather",
		"after": [&"shield_storm"], "icon": &"eye", "hidden": true},
	&"tells": {"name": "Tells", "asks": "Notice each of an anomaly's three tells", "family": &"weather",
		"after": [&"anomaly_eye"], "icon": &"compass", "goal": "tells", "parts": true, "unit": "tells", "hidden": true},
	&"taught": {"name": "Taught", "asks": "Teach the Walker the anomaly", "family": &"weather", "after": [&"tells"],
		"icon": &"walker", "hidden": true},
	&"deck_home": {"name": "All Mod Cons", "asks": "A Console, a condenser and a battery on one deck", "family": &"camp",
		"icon": &"console", "goal": "home", "unit": "on one deck", "step": 1.0},
	&"deck_pieces": {"name": "Six Pack", "asks": "Join %s chassis pieces into one deck", "family": &"camp",
		"after": [&"deck_home"], "icon": &"chassis", "goal": "deed_deck_pieces", "unit": "pieces", "step": 1.0},
	&"power": {"name": "Power Trip", "asks": "Make %s W in one system", "family": &"camp", "after": [&"deck_home"],
		"icon": &"turbine", "goal": "deed_power_w", "unit": "W", "step": 10.0},
	&"crop": {"name": "Green Thumb", "asks": "Grow a crop", "family": &"farm", "icon": &"crop"},
	&"crops": {"name": "Crop Rotation", "asks": "Grow %s kinds of crop", "family": &"farm", "after": [&"crop"],
		"icon": &"planter", "goal": "deed_crop_kinds", "parts": true, "unit": "kinds"},
	&"planters_towed": {"name": "Meals on Wheels", "asks": "Have %s planters in tow at once", "family": &"farm",
		"after": [&"crop"], "icon": &"planter", "goal": "deed_planters_towed", "unit": "planters", "step": 1.0},
	&"ages": {"name": "Carbon Dated", "asks": "Stand in a structure of each of the four ages", "family": &"ruins",
		"goal": "ages", "parts": true, "unit": "ages"},
	&"bared": {"name": "Bared", "asks": "Take loot from a site a storm has stripped", "family": &"ruins",
		"after": [&"ages"], "icon": &"ruin"},
	&"storm_chaser": {"name": "Storm Chaser", "asks": "Reach %s freshly bared sites in one storm", "family": &"ruins",
		"after": [&"bared"], "icon": &"ruin", "goal": "deed_bared_sites", "unit": "sites", "step": 1.0},
	&"dune_reader": {"name": "Dune Reader", "asks": "Find a ruin buried in a dune's own lee", "family": &"ruins",
		"after": [&"storm_chaser"], "icon": &"dune"},
	&"dig_setup": {"name": "Field Kit", "asks": "A Console with a ground radar, a scoop and a sieve on one deck",
		"family": &"ruins", "after": [&"dune_reader"], "icon": &"sieve", "goal": "setup", "unit": "on one deck",
		"step": 1.0},
	&"dune_dig": {"name": "Spadework", "asks": "Dig a dune's ruin out yourself", "family": &"ruins",
		"after": [&"dune_reader"], "icon": &"sand_scoop"},
	&"first_cut": {"name": "First Cut", "asks": "Cut a wreck's seam through", "family": &"scrap", "icon": &"cutter"},
	&"stripped": {"name": "Stripped", "asks": "Free every module on one wreck", "family": &"scrap",
		"after": [&"first_cut"], "icon": &"survival_kit"},
	&"clean_hands": {"name": "Clean Hands", "asks": "Make a live wreck's hazards safe without a shock or a sickness",
		"family": &"scrap", "after": [&"stripped"], "icon": &"sealant"},
	&"bonepicker": {"name": "Bonepicker", "asks": "Scrap one of each kind of wreck", "family": &"scrap",
		"after": [&"clean_hands"], "icon": &"wreck", "goal": "wrecks", "parts": true, "unit": "kinds"},
	&"god_heard": {"name": "First Light", "asks": "Hear a god inside its window", "family": &"signals", "icon": &"radio"},
	&"fm_heard": {"name": "Line of Sight", "asks": "Hear an FM station come through quiet", "family": &"signals",
		"after": [&"god_heard"], "icon": &"radio"},
	&"whistler": {"name": "Whistler", "asks": "Hear a whistler on a long wire, away from your camp's hum",
		"family": &"signals", "after": [&"god_heard"], "icon": &"radio"},
	&"null": {"name": "Null", "asks": "Turn a radio until a god you hear falls silent", "family": &"signals",
		"after": [&"god_heard"], "icon": &"bearings"},
	&"long_wire": {"name": "Long Wire", "asks": "Hear a satellite clear on a long wire strung from the radio",
		"family": &"signals", "after": [&"god_heard"], "icon": &"radio"},
	&"tu_roar": {"name": "Storm on Tu", "asks": "Hear Tu roar on shortwave", "family": &"signals",
		"after": [&"god_heard"], "icon": &"radio"},
	&"gods": {"name": "Pantheon", "asks": "Hear all seven gods", "family": &"signals", "after": [&"god_heard"],
		"icon": &"signal", "goal": "gods", "parts": true, "unit": "gods"},
	&"triangulated": {"name": "Triangulated", "asks": "Fix the living city with three crossing bearings",
		"family": &"signals", "after": [&"gods"], "icon": &"bearings"},
	&"living_city": {"name": "The Living City", "asks": "See the living city's lights", "family": &"signals",
		"after": [&"triangulated"], "icon": &"city"},
	&"first_fire": {"name": "First Fire", "asks": "Feed the Stoker at Halloran", "family": &"far",
		"icon": &"coalcane_bundle", "hidden": true},
	&"totality": {"name": "Totality", "asks": "Watch a whole eclipse out in the open", "family": &"far",
		"icon": &"eclipse"},
	&"glint": {"name": "Glint", "asks": "Reach a site whose glint you saw from %s m off", "family": &"far",
		"after": [&"totality"], "icon": &"glint", "goal": "deed_glint_m"},
	&"live_vent": {"name": "Live Vent", "asks": "Stand at a live vent's mouth", "family": &"far", "after": [&"glint"],
		"icon": &"vent"},
	&"just_missed": {"name": "Just Missed Them", "asks": "Reach a nomads' camp", "family": &"far",
		"after": [&"glint"], "icon": &"streamer", "hidden": true},
	&"thunder": {"name": "Thunder", "asks": "Hear a burst's boom from %s m away", "family": &"far",
		"after": [&"live_vent"], "icon": &"boom", "goal": "deed_thunder_m"},
	&"under_tu": {"name": "Under Tu", "asks": "Stand with Tu overhead", "family": &"far", "after": [&"totality"],
		"icon": &"tu"},
	&"dark_side": {"name": "The Dark Side", "asks": "Stand where Tu never rises", "family": &"far",
		"after": [&"under_tu"], "icon": &"dark"},
	&"port_morgan": {"name": "The Old City", "asks": "Reach Port Morgan", "family": &"story", "landmark": &"port_morgan"},
	&"landmarks": {"name": "Hot Tourist Destinations", "asks": "Reach every named landmark", "family": &"story",
		"after": [&"port_morgan"], "landmark": ALL, "goal": "landmarks", "parts": true, "unit": "landmarks"},
	&"ten_days": {"name": "Ten Days", "asks": "Live %s days in one run", "family": &"nomad", "icon": &"sun",
		"goal": "deed_days", "unit": "days", "step": 1.0},
	&"moved_house": {"name": "Moved House", "asks": "Move your camp %s m in one day", "family": &"nomad",
		"after": [&"ten_days"], "icon": &"chassis", "goal": "deed_moved_m", "unit": "m", "step": 250.0},
	&"slept_it_off": {"name": "Slept It Off", "asks": "Sleep through a storm with nothing lost from your camp",
		"family": &"nomad", "after": [&"ten_days"], "icon": &"bedroll"},
	&"care_package": {"name": "Care Package", "asks": "Call the Surveyor with a signal flare",
		"family": &"signals", "icon": &"flare"},
	&"follow_signal": {"name": "Follow the Signal", "asks": "Find a ruin by following a survey receiver's signal",
		"family": &"signals", "icon": &"survey_receiver"},
	&"up_and_over": {"name": "Up and Over", "asks": "Vault onto a ledge",
		"family": &"nomad", "icon": &"chassis"},
	&"quick_haul": {"name": "Quick Haul", "asks": "Yank a loaded rope through your hands", "family": &"wind",
		"icon": &"coil"},
	&"fairlead": {"name": "Fairlead", "asks": "Redirect a loaded rope through a fitted hook", "family": &"wind",
		"icon": &"hook"},
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
	# Shown once it shows: done in its branch, with any done early that it opens.
	var said: Array[StringName] = []
	if is_open(profile, id):
		said.append(id)
		for each: StringName in TABLE:
			if TABLE[each].get("after", []).has(id) and profile.did(each) and is_open(profile, each):
				said.append(each)
	if Controls.ui != null:
		for each in said:
			Controls.ui.badge(each)
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


## Whether a deed would still be kept if done now: a world whose deeds count,
## and it not done yet. What's worth working out only for a deed asks this.
static func waiting(world: World, id: StringName) -> bool:
	return _counting(world, id) != null


## The profile a deed would be kept in now, or null: none, a world whose
## deeds don't count, or the deed done already.
static func _counting(world: World, id: StringName) -> Node:
	if world == null or not world.counts_deeds or not TABLE.has(id):
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
		"tells":
			return TELLS.size()
		"setup":
			return SETUP.size()
		"gods":
			return Gods.ROSTER.size()
		"wrecks":
			return Wreckage.kinds().size()
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


## Whether its name and picture show: a hidden deed's only once it shows done.
static func revealed(profile: Node, id: StringName) -> bool:
	return not TABLE[id].get("hidden", false) or lit(profile, id)


## Done and showing, and not looked at in the deeds menu yet: the main menu marks them.
static func unseen(profile: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in TABLE:
		if lit(profile, id) and profile.is_new(id):
			out.append(id)
	return out


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
		if kit.unlocks().has(String(id)):
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
