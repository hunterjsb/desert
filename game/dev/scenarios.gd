class_name Scenarios
extends RefCounted
## Dev starting conditions. Each one searches this run's own weather for a
## moment and a place that match, so a playtest starts where it needs to
## without faking anything, and lays what it stages in front of you in
## place of the run's kit. Dev probe 1 starts every one.

## Each scenario: its key, a line on what it stages, and how it's found.
## kind: "spawn", "clear", "front" (a storm `distance` m upwind, coming at
## you), "deep" (inside, far from any edge), "back" (inside, clear air
## `distance` m upwind), "sky" (clear, facing the light), or a search of its
## own: "ruin", "lee", "sail", "anomaly", "vent", "dig" and "walker". day is the window of
## local time of day to look in: 0 is midnight, 0.5 noon; calm and breeze
## bound the wind, m/s; due is when a storm comes, s, in place of ten clear
## minutes; moon is [latitude, degrees east of the point under Tu], so
## [30, 180] is the far side, 30° north. lays names what's laid.
const DELIVERYSHIP_LEAD := 60.0
const LIST: Array[Dictionary] = [
	{"key": "spawn", "label": "where and when the run began", "kind": "spawn"},
	{"key": "clear", "label": "clear skies, weather radio, a flare and the deliveryship passing overhead in a minute",
		"kind": "clear", "day": [0.35, 0.55], "due": [540.0, 840.0], "lays": &"clear"},
	{"key": "wall", "label": "a storm's wall on the horizon, 3 km off", "kind": "front", "distance": 3000.0,
		"day": [0.35, 0.5]},
	{"key": "storm_500", "label": "a storm 500 m off, coming at you", "kind": "front", "distance": 500.0,
		"day": [0.35, 0.55]},
	{"key": "storm_100", "label": "a storm 100 m off", "kind": "front", "distance": 100.0, "day": [0.35, 0.55]},
	{"key": "storm_20", "label": "a storm 20 m off", "kind": "front", "distance": 20.0, "day": [0.35, 0.55]},
	{"key": "deep", "label": "deep in a storm", "kind": "deep", "day": [0.35, 0.55]},
	{"key": "clearing", "label": "a storm about to clear, its back 100 m upwind", "kind": "back", "distance": 100.0,
		"day": [0.35, 0.55]},
	{"key": "dusk", "label": "dusk, the sun on the horizon", "kind": "sky", "day": [0.733, 0.745]},
	# With the relay satellite sunlit beside Tu, facing it.
	{"key": "night", "label": "night, facing the relay satellite hanging beside Tu", "kind": "sky", "day": [0.8, 0.97],
		"relay": true},
	{"key": "eclipse", "label": "clear, facing Tu, the sun half a minute from going behind it", "kind": "clear",
		"eclipse": 30.0},
	{"key": "far", "label": "the far side: a clear night with no Tu, facing the pole star", "kind": "sky",
		"day": [0.9, 0.97], "moon": [30.0, 180.0]},
	# To hear the music go as a storm comes over: at night, when the port's AM comes
	# round the moon to the far side, the radio on it.
	{"key": "far_storm", "label": "the far side at night: a radio on the Almanac's sky wave, a storm 1.2 km off",
		"kind": "front", "distance": 1200.0, "day": [0.8, 0.97], "moon": [30.0, 180.0], "lays": &"far_god"},
	{"key": "survive", "label": "sealed water at dawn, a deck with a crude condenser and a shield", "kind": "clear",
		"day": [0.25, 0.3], "lays": &"survive"},
	{"key": "ruin", "label": "a house ruin's door, finds round it, a bare piece of your own", "kind": "ruin",
		"day": [0.35, 0.5], "calm": 6.0, "lays": &"yours"},
	# A clear morning, with a storm due in time to pick the root-tubers first
	# and before the noon heat that wilts fungus, and far enough off that the
	# saltbush is open when you arrive and folds as you watch.
	{"key": "farm", "label": "two planters ripening, a harvester, a shield, a storm minutes off", "kind": "clear",
		"day": [0.33, 0.37], "due": [150.0, 200.0], "lays": &"farm"},
	{"key": "board", "label": "a board of every make at your feet by a deck of two, clear and calm", "kind": "clear",
		"day": [0.35, 0.5], "calm": 6.0, "lays": &"board"},
	# Beside a town where history left house ruins, so a beacon is in reach.
	{"key": "receiver", "label": "a survey receiver with a battery among old ruins", "kind": "clear",
		"day": [0.35, 0.5], "among": true, "lays": &"receiver"},
	{"key": "radio", "label": "a radio and a charged shield, a beacon in reach, a storm 300 m off", "kind": "front",
		"distance": 300.0, "day": [0.35, 0.55], "among": true, "lays": &"radio"},
	# A morning like a run's, the first storm minutes off, so it soon shows what the camp does in one.
	{"key": "afk", "label": "the reference camp running on a floating 2x2 deck, its farm on hoses", "kind": "clear",
		"day": [0.3, 0.4], "due": [180.0, 480.0], "lays": &"afk"},
	# A storm due soon, so the lee is felt in the clear and then as it comes over the crest.
	{"key": "lee", "label": "the foot of a tall slip face, a catch line across the wind, a storm minutes off",
		"kind": "lee", "day": [0.35, 0.55], "due": [120.0, 360.0], "lays": &"catch_line"},
	{"key": "chassis", "label": "pieces, trays, a frame, batteries, a shield and a condenser to build with",
		"kind": "clear", "day": [0.35, 0.5], "calm": 6.0, "lays": &"chassis"},
	# A steady breeze across open sand: the wind on your left, the camp
	# facing across it ahead of you, ready to raise its sail and go.
	{"key": "sail", "label": "a sailing rig on skates, sheet at your waist, board and field notes",
		"kind": "sail", "day": [0.35, 0.5], "breeze": [8.5, 11.5], "lays": &"sail"},
	{"key": "sail_tow", "label": "the sail rig towing a camp on a real towline, the board at your feet",
		"kind": "sail", "day": [0.35, 0.5], "breeze": [8.5, 11.5], "lays": &"sail_tow"},
	{"key": "yacht", "label": "a floating 3x2 deck with a keel, a mast and a helm seat, a breeze", "kind": "sail",
		"day": [0.35, 0.5], "breeze": [8.5, 11.5], "lays": &"yacht"},
	# A shortwave set, the antenna kite cabled to its top hook through a driven
	# stake: use the kite to fly it.
	{"key": "kite", "label": "a shortwave radio, a kite on its top hook's cable through a stake, a breeze",
		"kind": "sail", "day": [0.35, 0.5], "breeze": [8.5, 11.5], "lays": &"kite"},
	{"key": "wreck", "label": "every wreck in a fan ahead, dug out, and what strips them at your feet",
		"kind": "clear", "day": [0.36, 0.5], "calm": 6.0, "lays": &"wrecks"},
	# Far enough off that the radar sees the front coming before the smart
	# shield switches itself on.
	{"key": "console", "label": "a Console with every instrument on a deck, a storm due in minutes", "kind": "clear",
		"day": [0.35, 0.55], "due": [240.0, 360.0], "lays": &"console"},
	# Its heart comes over minutes after the wall, on a camp ready for an
	# ordinary storm: the one the Walker misjudged.
	{"key": "anomaly", "label": "a storm with an anomaly at its heart due, by a camp built for wind",
		"kind": "anomaly", "day": [0.3, 0.6], "due": [150.0, 300.0], "lays": &"anomaly_camp"},
	{"key": "sleep", "label": "dusk at a still camp: a bedroll, a running shield, a wall to windward",
		"kind": "clear", "day": [0.72, 0.745], "lays": &"sleep"},
	# Clear long enough for the burst to tower, and by daylight.
	{"key": "vent", "label": "across the rift from its live vent, a minute before it bursts", "kind": "vent",
		"day": [0.2, 0.62], "due": [180.0, INF], "lays": &"vent"},
	# Before the sand comes back over it: stand on it and it stays off.
	{"key": "dig", "label": "a big dune's ruin a storm has just laid bare, a scoop in hand and a sieve carried",
		"kind": "dig", "lays": &"dig"},
	# Where the run's start puts the Walker, ahead of it as it comes: plug in as it passes.
	{"key": "walker", "label": "beside the Walker as it comes, a Console holding all three tells, its cable in hand",
		"kind": "walker", "day": [0.35, 0.5], "lays": &"walker_camp"},
]

## A floater's stake is driven this far further upwind of it, m.
const TETHER_AHEAD := 3.0

## Survival's start, right and ahead: a deck of two resting on the sand with
## the condenser and its panel and battery, and the shield on its own
## battery; and spare rations.
const SURVIVE_DECK := [-0.5, 2.6]
const SURVIVE_RIG := [[&"piece", Vector2i(1, 0)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.2), 180.0, [&"condenser", [&"canister"]], &"condenser"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.3), 0.0, &"solar_panel"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(-0.2, 0.2), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.25, 0.25), 0.0, &"battery"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.25, -0.25), 0.0, &"battery"]]
const SURVIVE_RATIONS := [[0.35, 1.3], [0.6, 1.3]]

## The farm, right and ahead: a planter to pick by hand, one with a
## harvester, the shield between them on its plate so its bubble takes both
## and their stakes, and a canister to fit to a water socket. Its crops start
## part grown, so the root-tubers ripen within a minute in the clear and the
## vat fungus within a few once the storm's dark is on it and the bubble's
## still air round it. The one you pick by hand has a saltbush in place of a
## root-tuber, which folds two minutes before the storm and grows on slowly.
const FARM_BY_HAND := [-1.6, 2.8]
const FARM_HARVESTER := [1.6, 2.8]
const FARM_SHIELD := [0.0, 2.0]
const FARM_CANISTER := [-0.5, 1.3]
const FARM_CROPS := [&"root_tuber", &"root_tuber", &"root_tuber", &"vat_fungus"]
const FARM_BY_HAND_CROPS := [&"root_tuber", &"saltbush", &"root_tuber", &"vat_fungus"]
const FARM_GROWN := {&"root_tuber": 0.85, &"vat_fungus": 0.5, &"saltbush": 0.6}

## A board of each make at your feet, noses ahead, the issue nearest, and
## beside you a deck of two resting on the sand, the shield and its battery on
## its first piece and its second bare to rack a board on: right and ahead.
const BOARDS_AT := [[0.0, 1.3], [-0.6, 1.5], [0.6, 1.5], [-1.2, 1.7]]
const BOARD_DECK := [2.0, 3.2]
const BOARD_CAMP := [[&"piece", Vector2i(1, 0)],
	[&"stick", Vector2i.ZERO, &"top", Vector2(-0.22, 0.22), 0.0, &"shield"],
	[&"stick", Vector2i.ZERO, &"top", Vector2(0.25, -0.25), 0.0, &"battery"]]

## The radio, its face to you and far enough out to be in view as you
## arrive, and the shield on its plate to sit the storm out by it.
const RADIO_AT := [0.4, 2.4]
const RADIO_SHIELD := [-1.0, 3.2]

## A plate: one chassis on the sand with a few things stuck on its top, at
## these places on it in turn.
const PLATE_SPOTS := [Vector2(-0.22, 0.22), Vector2(0.25, -0.25), Vector2(0.25, 0.25), Vector2(-0.25, -0.25)]

## The reference camp on a deck two pieces by two, right and ahead, facing
## upwind: its first piece upwind on the left, the others to its right and
## back toward you. The planters float upwind of it, the stake that moors it
## between them and theirs upwind of them, and the turbine stands downwind of
## the bubble near the end of its cable, so the wind holds it out there.
const AFK_DECK := [-1.0, 2.5]
const AFK_STAKE := [-1.0, 3.9]
const AFK_PLANTERS := [[-2.2, 4.3], [1.2, 4.3]]
const AFK_PLANTER_STAKES := [[-2.2, 5.8], [1.2, 5.8]]
## The turbine stands this far straight back from the light panel's port, m,
## its strong cable all but taut.
const AFK_TURBINE_BACK := 5.85
## Upwind, the condenser, its tap toward the planters, a lamp and a panel;
## the shield across at the front, so the light panel's port downwind, toward
## the turbine, is as far from it as a deck this size allows; the bank of
## batteries and the other panels downwind, the weight behind the trays, which
## are set a little upwind under every piece against the mooring's pull, so it
## floats within a couple of degrees of level. A hook on every free ring.
const AFK_RIG := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2(0.0, -0.15), 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2(0.0, -0.15), 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2(0.0, -0.15), 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2(0.0, -0.15), 0.0, &"hover_tray"],
	[&"hook", Vector2i(0, 0), Vector2i(-1, 0)], [&"hook", Vector2i(0, 0), Vector2i(0, -1)],
	[&"hook", Vector2i(1, 0), Vector2i(1, 0)], [&"hook", Vector2i(1, 0), Vector2i(0, -1)],
	[&"hook", Vector2i(0, 1), Vector2i(-1, 0)], [&"hook", Vector2i(0, 1), Vector2i(0, 1)],
	[&"hook", Vector2i(1, 1), Vector2i(1, 0)], [&"hook", Vector2i(1, 1), Vector2i(0, 1)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(-0.2, -0.15), 180.0, &"condenser", &"condenser"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.35, -0.35), 0.0, &"lamp"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.28, 0.2), 90.0, &"solar_panel"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.28), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, -0.27), 0.0, &"solar_panel"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, -0.29), 0.0, &"light_panel", &"port"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.3, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.3, 0.0), 0.0, &"battery"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.0, 0.27), 0.0, &"solar_panel"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(-0.3, -0.27), 0.0, &"big_battery"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.0, -0.27), 0.0, &"big_battery"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.3, -0.27), 0.0, &"big_battery"]]
## What you carry, as you'd leave yourself: nothing brings you water yet, the
## condenser waters only the farm, so this many canisters, and no food: the
## farm drops it onto you. Spare stakes, a coil and a hose, to move the
## planters about and moor them again.
const AFK_CANISTERS := 3
const AFK_STAKES := 3

## The chassis pieces lying in a row ahead of you, a tray in front of each, a
## spare piece for a wall and a frame to raise it on, two batteries, the
## light shield and the condenser to stick on the deck: right and ahead.
const CHASSIS_PIECES := [[-1.8, 3.6], [-0.6, 3.6], [0.6, 3.6], [1.8, 3.6]]
const CHASSIS_TRAYS := [[-1.8, 2.2], [-0.6, 2.2], [0.6, 2.2], [1.8, 2.2]]
const CHASSIS_SPARE := [0.0, 5.2]
const CHASSIS_FRAME := [2.4, 5.4]
const CHASSIS_BATTERIES := [[3.0, 2.0], [3.2, 2.3]]
const CHASSIS_SHIELD := [3.4, 2.8]
const CHASSIS_CONDENSER := [-3.4, 2.4]
## The first piece's outer ring has a hook moored to a stake just short of
## where a piece joined there goes, so that join pops it; two hooks and a coil
## lie at your feet to moor more.
const CHASSIS_STAKE := [-2.8, 2.6]
const CHASSIS_HOOKS := [[-0.3, 1.4], [0.3, 1.4]]
const CHASSIS_COIL := [0.9, 1.4]

## The sailing camp on a deck two by two on skates, right and ahead, facing
## across the wind ahead of you: its first piece at the front on the windward
## side, the mast on it and behind it the ballast, three batteries in an open
## frame where the crate stood, catching the wind as it did, the shield (off)
## behind on the leeward side, and a bare tail piece behind the ballast for
## the sheet's ring, which sits under the boom's end hauled right in. The
## board lies at your feet, and the sheet's laid this much longer than the
## way from the boom's end to your waist, m.
const SAIL_DECK := [-0.5, 7.0]
const SAIL_TAIL := [&"piece", Vector2i(0, 2)]
const SKATES := [[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"]]
const SQUARE := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)]]
const SAIL_MAST := [&"stick", Vector2i(0, 0), &"top", Vector2(0.4, 0.0), 180.0, [&"mast", [&"sail"]], &"mast"]
const SAIL_WINCH := [&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.0), 0.0, &"hand_winch", &"hoist"]
const SAIL_BALLAST := [[&"frame", Vector2i(0, 1), 0],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.25, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.0), 0.0, &"battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.25, 0.0), 0.0, &"big_battery"]]
const SAIL_SHIELD := [&"stick", Vector2i(1, 1), &"top", Vector2(0.0, 0.1), 0.0, &"shield", &"shield"]
const SAIL_BOARD := [0.6, 1.0]
const SAIL_SHEET_SLACK := 1.5
## The sheet starts eased to let the boom swing this far out, degrees.
const SAIL_EASED := 75.0
## Sailing a larger camp: the camp a deck two by two behind you, right and
## ahead, its shield at its front, so its bubble takes you and not the sail;
## its line from the hook on its front left ring.
const TOW_CAMP := [-0.5, -5.0]
const TOW_STORES := [[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.1), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.2, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.2, 0.0), 0.0, &"big_battery"],
	[&"hook", Vector2i(0, 0), Vector2i(0, -1)]]
## The yacht: a centred mast and two centreline keels keep the wind and
## lateral resistance aligned. Four corner trays lift it, two batteries sit
## opposite each other aft, and the helm and sheet tail stay on its middle.
const YACHT_DECK := [-3.5, 2.5]
const YACHT_RIG := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)], [&"piece", Vector2i(0, 1)],
	[&"piece", Vector2i(1, 1)], [&"piece", Vector2i(2, 1)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"keel"],
	[&"stick", Vector2i(2, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"keel"],
	[&"stick", Vector2i(2, 1), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"top", Vector2.ZERO, 180.0, [&"mast", [&"sail"]], &"mast"],
	[&"stick", Vector2i(1, 1), &"top", Vector2.ZERO, 180.0, &"helm_seat", &"helm"],
	[&"stick", Vector2i(2, 0), &"top", Vector2.ZERO, 0.0, &"hand_winch", &"hoist"],
	[&"stick", Vector2i(0, 1), &"top", Vector2.ZERO, 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.0), 0.0, &"battery"],
	[&"stick", Vector2i(2, 1), &"top", Vector2.ZERO, 0.0, &"big_battery"]]
## Open sand to sail on: level within this much, m, for this far either way
## across the run's long-term wind, m, read every so far along it, m, and
## sought this far up and down the wind from where the run began, m, in
## steps this long, along lines this far apart across it, m.
const OPEN_RISE := 0.6
const OPEN_ACROSS := 120.0
const OPEN_EVERY := 15.0
const OPEN_SEARCH := 3000.0
const OPEN_STEP := 20.0
const OPEN_LINES := [0.0, 300.0, -300.0, 600.0, -600.0, 900.0, -900.0, 1200.0, -1200.0]
## The level runs this far up and down the wind of its line too, m: room to
## slip sideways and come back.
const OPEN_WIDE := [0.0, 40.0, -40.0]
## At most this share of a full lee there.
const OPEN_LEE := 0.05

## The Console's deck, two pieces floating on a tray each, right and ahead of
## you: the Console on the first, its screen to you, two big batteries and a
## radio behind it, and the base shield and its battery on the second; the
## stake that moors the deck, upwind beyond it.
const CONSOLE_DECK := [-0.5, 2.3]
const CONSOLE_PARTS := [&"screen", &"anemometer", &"barometer", &"hygrometer", &"particle_sensor", &"radar"]
const CONSOLE_RIG := [[&"piece", Vector2i(1, 0)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.18), 180.0, [&"console", CONSOLE_PARTS], &"console"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(-0.3, 0.32), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.32), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.32), 0.0, [&"radio", [&"battery", &"fm_converter", &"sw_converter"]], &"radio"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(-0.2, -0.1), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.27, 0.25), 0.0, &"battery"]]
const CONSOLE_STAKE := [-0.5, 4.6]

## The camp built for wind, on the reference camp's deck plan resting on the
## sand, moored upwind: a Console whose radar sees the storm coming, clean,
## reading the wind and the sand, a radio on the weather station behind it
## whose port holds the turbine out downwind beyond the bubble, the base
## shield on one battery across at the front.
const ANOMALY_CONSOLE := [&"screen", &"anemometer", &"barometer", &"particle_sensor", &"radar"]
const ANOMALY_RIG := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"hook", Vector2i(0, 0), Vector2i(-1, 0)], [&"hook", Vector2i(0, 0), Vector2i(0, -1)],
	[&"hook", Vector2i(1, 0), Vector2i(1, 0)], [&"hook", Vector2i(1, 0), Vector2i(0, -1)],
	[&"hook", Vector2i(0, 1), Vector2i(-1, 0)], [&"hook", Vector2i(0, 1), Vector2i(0, 1)],
	[&"hook", Vector2i(1, 1), Vector2i(1, 0)], [&"hook", Vector2i(1, 1), Vector2i(0, 1)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.0), 180.0, [&"console", ANOMALY_CONSOLE], &"console"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.28), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.25, -0.2), 0.0, &"battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, -0.3), 0.0, &"radio", &"radio"]]
## An anomaly's heart is looked for this far round where the run began, m,
## over at most this many days from the clock's start, coming over at most
## this long after its wall, s. Hearts are sparse: 30 km and 30 days found
## none on one seed in eight; this finds one within 23 days on every seed
## tried, in a few tens of milliseconds.
const ANOMALY_SEARCH := 60000.0
const ANOMALY_DAYS := 200.0
const ANOMALY_WALL := 300.0

## The still camp, a deck of two resting on the sand squared to you as you
## face upwind, right and ahead: the bedroll on its first piece by the base
## shield and its battery, a frame on the second with a wall on its upwind
## face, and in the frame a panel and a radio on the weather station.
const SLEEP_DECK := [-0.5, 2.4]
const SLEEP_RIG := [[&"piece", Vector2i(1, 0)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(-0.25, 0.0), 0.0, &"bedroll", &"bed"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.22, -0.25), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.25, 0.25), 0.0, &"battery"],
	[&"frame", Vector2i(1, 0), 0],
	[&"wall", Vector2i(1, 0), &"front"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.2), 0.0, &"solar_panel"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, -0.2), 0.0, [&"radio", [&"battery", &"fm_converter", &"sw_converter"]], &"radio"]]

## The live vent is looked at from this far across the rift, m, this long
## before a burst, s, over at most this many days from the clock's start:
## most days it bursts, at any hour, and over the rift it's often stormy.
const VENT_OFF := 1500.0
const VENT_LEAD := 60.0
const VENT_DAYS := 400.0

## Your own chassis, to stick what you find on: right and ahead.
const YOURS := [1.5, 2.5]
## A catch line's stakes, right and ahead: across the wind you face.
const CATCH_LINE := [[-3.0, 3.0], [3.0, 3.0]]
## How far round the moon from where the run began to look for a house ruin,
## m, and how many places on fresh ground to try standing it at.
const RUIN_SEARCH := 40000.0
const RUIN_STANDS := 6

## A tall slip face's foot: level sand at the bottom of a drop whose crest
## stands at least this far above it, m, and a lee there of at least this
## share of a full one. Looked for this far either way along the wind from
## where the run began, m, in steps this long, along lines this far either
## side, m.
const LEE_TALL := 15.0
const LEE_SHARE := 0.9
const LEE_SEARCH := 3000.0
const LEE_STEP := 4.0
const LEE_LINES := [0.0, 200.0, -200.0, 400.0, -400.0]

## How far upwind a search looks for edges, and its step.
const REACH := 6000.0
const STEP := 25.0
## Search the first three days, finely enough not to step over dusk.
const HORIZON := 3.0 * 24.0 * 3600.0
const TIME_STEP := 10.0
## "relay" looks for the relay this many degrees up, at least and at most.
const RELAY_SEEN := Vector2(10.0, 50.0)
## "deep" means full storm for at least this far either way along the wind.
const DEEP := 300.0


## Puts you into a scenario on this world, there and then, and lays what it
## stages. Where it put you, or that it found nowhere, shows on the overlay at
## once; its things follow once the sand under them is solid.
static func apply(world: World, scenario: Dictionary) -> void:
	if scenario.is_empty():
		push_warning("no such scenario")
		return
	var place := find(world, scenario)
	if place.is_empty():
		Dev.put("world/scn", "%s: none found" % scenario.key)
		return
	stand(world, scenario, place)
	Dev.put("world/scn", scenario.key)
	await lay(world, scenario, place)


## What a scenario stages, in front of you where it stood you, in place of
## the last scenario's things and the run's kit. What it laid.
static func lay(world: World, scenario: Dictionary, place: Dictionary) -> Array[Node3D]:
	_clear(world, &"scenario_kit", false)
	var lays: StringName = scenario.get("lays", &"")
	if lays == &"":
		return []
	# Bodies dropped before the sand under them has collision would be frozen or forgotten.
	while is_instance_valid(world) and not world.terrain.is_settled_around(place.x, place.z):
		await world.get_tree().physics_frame
	if not is_instance_valid(world):
		return []
	_clear(world, &"kit", true)
	var dropped: Array[Node3D] = []
	match lays:
		&"clear":
			dropped = weather_station(world)
			dropped.append_array(deliveryship_pass(world))
		&"yours": dropped = yours(world)
		&"survive": dropped = survive(world)
		&"farm": dropped = farm(world)
		&"board": dropped = board(world)
		&"receiver": dropped = [standing(world, &"survey_receiver", [&"battery"], RADIO_AT)]
		&"radio": dropped = radio(world)
		&"far_god": dropped = far_god(world)
		&"afk": dropped = afk(world)
		&"catch_line": dropped = catch_line(world)
		&"chassis": dropped = chassis(world)
		&"sail": dropped = sail(world)
		&"sail_tow": dropped = sail_tow(world)
		&"yacht": dropped = yacht(world)
		&"kite": dropped = kite(world)
		&"wrecks": dropped = await wrecks(world)
		&"console": dropped = console(world)
		&"anomaly_camp": dropped = anomaly_camp(world)
		&"sleep": dropped = sleep(world)
		&"vent": dropped = vent(world)
		&"dig": dropped = dig(world)
		&"walker_camp": dropped = walker_camp(world)
	world.set_meta(&"scenario_kit", dropped)
	return dropped


## Every wreck kind, dug out, in a fan this far ahead of you, m, this far
## apart round it, degrees; each tries further out where the dunes won't take
## it.
const WRECKS_AHEAD := 40.0
const WRECKS_APART := 32.0


## One of every wreck in a fan ahead of you, laid by hand as history would
## lay them, dug out, each turned so its way in faces you; the skimmer era's
## lean as a wreck of theirs would. At your feet what strips them: a heat
## cutter with a full battery, a sand scoop, two sealant canisters, two
## stakes and a med kit. Returns the tools once the wrecks are built.
static func wrecks(world: World) -> Array[Node3D]:
	var sites := world.shape.sites
	var me := Vector2(world.player_world_x(), world.player_world_z())
	var ahead := -world.player.global_basis.z
	var facing := atan2(ahead.x, -ahead.z)
	var kinds: Array[StringName] = []
	for kind: StringName in StructureKit.kinds():
		if StructureKit.piece(kind).wreck != null:
			kinds.append(kind)
	var placed: Array[Structure] = []
	for i in kinds.size():
		var piece := StructureKit.piece(kinds[i])
		var lean := deg_to_rad(Eras.TILT.get(piece.era, Vector2.ZERO).y * 0.6)
		var way := facing + deg_to_rad(WRECKS_APART * (i - (kinds.size() - 1) * 0.5))
		var fan := me + Vector2(sin(way), -cos(way)) * WRECKS_AHEAD
		# Out from its place in the fan on a spiral, nearest first, clear of
		# the others' ground.
		for j in 300:
			var at := fan + Vector2.from_angle(j * 2.39996) * 4.0 * sqrt(j)
			if placed.any(func(o: Structure) -> bool: return o.distance_to(at.x, at.y) < o.reach + piece.reach):
				continue
			# Turned so its approach is the side nearest you.
			var best: Structure = null
			var near := INF
			for k in 8:
				var tried := sites.by_hand(kinds[i], at.x, at.y, TAU * k / 8.0, 0.0, lean)
				var d := tried.to_world(piece.approach).distance_to(me)
				if d < near:
					near = d
					best = tried
			if best.stands():
				sites.add(best)
				placed.append(best)
				break
	# The ground they changed is built again, and what they hold laid out.
	for frame in 600:
		await world.get_tree().physics_frame
		if not is_instance_valid(world):
			return []
		if placed.all(func(s: Structure) -> bool: return world.salvage.wreckage_of(s) != null or not world.tuning.salvage) \
				and world.salvage.is_idle() and world.terrain.is_idle():
			break
	var tools: Array[Node3D] = [standing(world, &"cutter", [&"battery"], [0.7, 1.3])]
	for each: Array in [[&"sand_scoop", -0.7], [&"sealant", -0.3], [&"sealant", -0.15], [&"med_kit", 0.15]]:
		var made := Catalog.part(each[0])
		drop(world, made, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, 0.0)), each[1], 1.1)
		tools.append(made)
	for right: float in [1.2, 1.45]:
		var stake := Catalog.stake()
		drop(world, stake, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, 0.0)), right, 1.0)
		tools.append(stake)
	return tools


## Frees what a kit set down that's still lying about, and forgets the list:
## what you've put in your suit or hold is yours now, and stays.
static func _clear(world: World, key: StringName, now: bool) -> void:
	var player := world.player
	# Untyped, and checked at each: what the ground unloaded, or went with the
	# device it sat in, is freed already.
	for body in world.get_meta(key, []):
		if not is_instance_valid(body) or _yours(player, body):
			continue
		# A line of its own at your waist, a sheet or a tow, goes with it.
		if body is Line:
			for end in (body as Line).ends:
				if is_instance_valid(end) and player.waist.holds(end):
					player.waist.untie(end)
		if now:
			body.free()
		else:
			body.queue_free()
	world.remove_meta(key)


## Whether it's in your suit or hands, or seated in something that is.
static func _yours(player: Player, body: Node) -> bool:
	var at := body
	while at != null:
		if at == player.hands.held or at is RigidBody3D and at in player.suit.carried:
			return true
		at = at.get_parent()
	return false


## Puts you where find() found, there on the moon too.
static func stand(world: World, scenario: Dictionary, place: Dictionary) -> void:
	world.respawn(place.x, place.z, place.yaw, place.time)
	if place.has("moon"):
		world.moon.place(place.moon.x, place.moon.y)
	elif scenario.has("moon"):
		var at := moon_at(world, scenario)
		world.moon.place(rad_to_deg(at.x), rad_to_deg(at.y))


## Where on the moon a scenario stands you, radians: its "moon", or the run's start.
static func moon_at(world: World, scenario: Dictionary) -> Vector2:
	var tuning := world.tuning
	if not scenario.has("moon"):
		return Vector2(Sphere.latitude(world.start), Sphere.longitude(world.start))
	return Vector2(deg_to_rad(scenario.moon[0]), wrapf(deg_to_rad(tuning.tu_longitude_degrees + scenario.moon[1]), -PI, PI))


static func by_key(key: String) -> Dictionary:
	# Existing console histories and capture scripts still reach the one setup.
	if key in ["clear_skies", "deliveryship", "drone", "surveyor"]:
		key = "clear"
	for scenario in LIST:
		if scenario.key == key:
			return scenario
	return {}


## Where to put the player: {x, z, yaw, time}, or {} if this run's weather has
## no such moment in three days.
static func find(world: World, scenario: Dictionary) -> Dictionary:
	var spawn := world.spawn
	# A sky-only change must not put you back inside the landed pod.
	if scenario.kind == "sky" and scenario.get("lays", &"") == &"":
		spawn = Vector2(world.player_world_x(), world.player_world_z())
	if scenario.kind == "spawn":
		return {"x": spawn.x, "z": spawn.y, "yaw": 0.0, "time": 0.0}
	if scenario.kind == "ruin":
		return _at_ruin(world, scenario)
	if scenario.kind == "lee":
		return _in_lee(world, scenario)
	if scenario.kind == "sail":
		return _open_breeze(world, scenario)
	if scenario.kind == "anomaly":
		return _before_anomaly(world, scenario)
	if scenario.kind == "vent":
		return _before_burst(world, scenario)
	if scenario.kind == "walker":
		return _before_walker(world, scenario)
	if scenario.kind == "dig":
		var found := bared_dune_ruin(world, world.spawn, DUNE_SEARCH, 3.0, 0.25, true)
		if found.is_empty():
			return {}
		var site: Structure = found.site
		var at := Vector2(site.x, site.z) + world.shape.downwind() * (site.reach + DUNE_STAND)
		var facing := (Vector2(site.x, site.z) - at).normalized()
		return {"x": at.x, "z": at.y, "yaw": atan2(-facing.x, -facing.y), "time": found.time}
	# Without salvage there's no structure to stand among: where the run began.
	if scenario.get("among", false) and world.tuning.salvage:
		return _among(world, scenario)
	return _search(world, scenario, spawn, moon_at(world, scenario).y)


## The first moment and place in three days a scenario's weather and hour
## hold, from a world place, local time at a longitude, rad.
static func _search(world: World, scenario: Dictionary, spawn: Vector2, longitude: float) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var moon := Vector2(moon_at(world, scenario).x, longitude)
	var t := 0.0
	if scenario.has("eclipse"):
		t = day.next_eclipse(0.0) - day.totality() * 0.5 - scenario.eclipse
	while t < HORIZON:
		var hour := day.time_of_day(t, moon.y)
		if (scenario.has("eclipse") or (hour >= scenario.day[0] and hour <= scenario.day[1])) \
				and (not scenario.get("relay", false) or _relay_shows(world, moon, t)):
			var upwind := -field.prevailing_at(t).normalized()
			var place := _place(field, scenario, spawn, upwind, t)
			if not place.is_empty():
				place.time = t
				place.yaw = _facing(world, scenario, moon, upwind, t)
				return place
		t += world.tuning.day_minutes * 60.0 if scenario.has("eclipse") else TIME_STEP
	return {}


static func _place(field: WeatherField, scenario: Dictionary, from: Vector2, upwind: Vector2,
		t: float) -> Dictionary:
	match scenario.kind:
		"clear", "sky", "ruin", "lee", "sail", "vent":
			var breeze: Array = scenario.get("breeze", [0.0, INF])
			var blowing := field.wind_at(from.x, from.y, t).length()
			if field.raw_storm_at(from.x, from.y, t) <= 0.0 \
					and blowing < scenario.get("calm", INF) and _within(blowing, breeze) \
					and (scenario.kind == "sky" or _comes(field, scenario, from, t)):
				return {"x": from.x, "z": from.y}
		"front", "back":
			# March upwind for an edge with enough of the other side behind it.
			var into_storm: bool = scenario.kind == "front"
			var need: float = scenario.distance + 50.0
			var run := 0.0
			var d := 0.0
			var was := _stormy(field, from, upwind, 0.0, t)
			while d < REACH:
				d += STEP
				var now := _stormy(field, from, upwind, d, t)
				if now == was:
					run += STEP
					continue
				if now == into_storm and run >= need:
					var edge := _refine(field, from, upwind, d - STEP, d, t)
					var at: Vector2 = from + upwind * (edge - scenario.distance)
					return {"x": at.x, "z": at.y}
				was = now
				run = 0.0
		"deep":
			var run := 0.0
			var d := 0.0
			while d < REACH:
				var p := from + upwind * d
				run = run + STEP if field.storm_at(p.x, p.y, t) == 1.0 else 0.0
				if run >= DEEP * 2.0:
					var at := from + upwind * (d - DEEP)
					return {"x": at.x, "z": at.y}
				d += STEP
	return {}


## Where a scenario stands you among history's house ruins, a beacon in
## reach: on fresh ground, the moon's point beside the nearest town where one
## is heard from there, laid from where you'll stand; the weather searched
## there, the hour by the town's longitude.
static func _among(world: World, scenario: Dictionary) -> Dictionary:
	var tuning := world.tuning
	# Past where the history kept under the loaded ground could reach, however
	# far upwind the weather's search goes.
	var off := (tuning.history_lay_m + tuning.history_cell_m) * 2.0 + world.history_due() + REACH
	var fresh := Vector2(roundf(world.player_world_x() + off), roundf(world.player_world_z()))
	var spawn_moon := moon_at(world, scenario)
	var from := Sphere.point(spawn_moon.x, spawn_moon.y)
	var heard := func(laid: TerrainShape, ground: Vector2) -> bool:
		return not Finds.beacon(world.run_seed, laid.sites, ground.x, ground.y, tuning,
			func(_site: int, _socket: int) -> bool: return false).is_empty()
	var shape := TerrainShape.new(world.run_seed, tuning)
	for town in StructureKit.towns_near(shape.history, from, 12):
		var at := StructureKit.beside(shape.history, town, from, StructureKit.AMONG_ASIDE)
		var place := _search(world, scenario, fresh, Sphere.longitude(at))
		if not place.is_empty() and StructureKit.stands_among(shape, at, Vector2(place.x, place.z),
				StructureKit.AMONG_ASIDE + town.radius, StructureKit.AMONG_LEAST, heard):
			place.moon = Vector2(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)))
			return place
	return {}


## In front of the front door of history's house ruin nearest where the run
## began on the moon, facing it, at a moment in the day's window that's clear
## and calm there, stays clear ten minutes, and finds it dug out. You stand on
## fresh ground with the moon's point put where its door is, so the sheet lays
## it in front of you: {x, z, yaw, time, moon} with the moon's point in degrees.
static func _at_ruin(world: World, scenario: Dictionary) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var sites := world.shape.sites
	var radius := world.shape.history.radius
	var moon := moon_at(world, scenario)
	var from := Sphere.point(moon.x, moon.y)
	# Past where the history kept under the loaded ground could reach.
	var off := (world.tuning.history_lay_m + world.tuning.history_cell_m) * 2.0 + world.history_due()
	for each in StructureKit.nearest_on_moon(world.shape.history, from, &"house_ruin", RUIN_SEARCH):
		for k in RUIN_STANDS:
			var at := Vector2(roundf(world.player_world_x() + off + k * 250.0), roundf(world.player_world_z()))
			# Laid from its own point first, to learn which way its door faces.
			var guess := sites.would_lay(each, at.x, at.y, each.p) as Ruin
			var out := guess.to_world(Ruin.APPROACH) - Vector2(guess.x, guess.z)
			var point := Sphere.from_flat(each.p, Vector2(out.x, -out.y) / radius)
			var ruin := sites.would_lay(each, at.x, at.y, point) as Ruin
			if not ruin.stands():
				continue
			var door := ruin.to_world(Ruin.DOORS[0][0])
			var longitude := Sphere.longitude(point)
			var memo := Exposure.Memo.new()
			var t := 0.0
			while t < HORIZON:
				var hour := day.time_of_day(t, longitude)
				if hour >= scenario.day[0] and hour <= scenario.day[1] \
						and not _place(field, scenario, at, Vector2.ZERO, t).is_empty():
					var dug := Exposure.state(ruin.depth, Exposure.taken(field, ruin.x, ruin.z, t, world.tuning, memo)) \
						== Exposure.EXPOSED
					if dug:
						var facing := (door - at).normalized()
						return {"x": at.x, "z": at.y, "yaw": atan2(-facing.x, -facing.y), "time": t,
							"moon": Vector2(rad_to_deg(Sphere.latitude(point)), rad_to_deg(longitude))}
				t += TIME_STEP
	return {}


## At the foot of a tall slip face, facing up it, at a moment in the day's
## window that's clear with a storm due, the wind blowing over the crest.
static func _in_lee(world: World, scenario: Dictionary) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var mean := WeatherField.mean_heading(world.run_seed)
	var longitude := moon_at(world, scenario).y
	for foot in feet(world, mean):
		# Out of the long-term wind's lee, which the dunes face, is out of most winds'.
		if world.weather.lee.share(foot.x, foot.y, mean) < LEE_SHARE:
			continue
		var t := 0.0
		while t < HORIZON:
			var hour := day.time_of_day(t, longitude)
			if hour >= scenario.day[0] and hour <= scenario.day[1] \
					and not _place(field, scenario, foot, Vector2.ZERO, t).is_empty() \
					and world.weather.lee.share(foot.x, foot.y, field.prevailing_at(t).angle()) >= LEE_SHARE:
				var upwind := -field.prevailing_at(t).normalized()
				return {"x": foot.x, "z": foot.y, "yaw": atan2(-upwind.x, -upwind.y), "time": t}
			t += TIME_STEP
	return {}


## Where an anomaly's heart, at its full, comes over within ANOMALY_WALL s
## of its storm's wall, at a moment in the day's window that's clear there
## with that storm due in the window asked, facing upwind: it rides the
## air, so it's met wherever it passes, round where the run began. Asking
## for one, the dev run meets them whatever its days.
static func _before_anomaly(world: World, scenario: Dictionary) -> Dictionary:
	world.anomalies_any_time = true
	var field := world.weather.field
	var day := world.weather.day
	var longitude := moon_at(world, scenario).y
	var due: Array = scenario.due
	var t := 0.0
	var last := ANOMALY_DAYS * world.tuning.day_minutes * 60.0
	while t < last:
		for heart in field.anomalies_near(world.spawn.x, world.spawn.y, t, ANOMALY_SEARCH):
			var at := Vector2(heart.x, heart.z)
			if heart.strength < 1.0 or field.raw_storm_at(at.x, at.y, t) <= 0.0:
				continue
			var wall := t
			while wall > t - ANOMALY_WALL and field.raw_storm_at(at.x, at.y, wall - 5.0) > 0.0:
				wall -= 5.0
			var start: float = wall - (due[0] + due[1]) * 0.5
			var hour := day.time_of_day(start, longitude)
			if wall <= t - ANOMALY_WALL or hour < scenario.day[0] or hour > scenario.day[1] \
					or field.raw_storm_at(at.x, at.y, start) > 0.0 \
					or not _within(field.next_change(at.x, at.y, start, due[1] + 10.0, 5.0), due):
				continue
			var upwind := -field.prevailing_at(start).normalized()
			return {"x": at.x, "z": at.y, "yaw": atan2(-upwind.x, -upwind.y), "time": start}
		t += TIME_STEP * 6.0
	return {}


## Across the rift from its live vent, facing it, on fresh ground with the
## moon's point put there, VENT_LEAD s before a burst at a moment in the day's
## window that's clear, there and over the vent, until the next storm's due,
## and no eclipse while the burst towers: near the point under Tu, noon's
## goes dark.
static func _before_burst(world: World, scenario: Dictionary) -> Dictionary:
	var history := world.shape.history
	var geology := history.geology
	var vent: Dictionary = geology.live()[0]
	var stand := Sphere.toward(vent.p, vent.bearing + PI * 0.5, VENT_OFF / history.radius)
	var yaw := -Sphere.bearing(stand, vent.p)
	var longitude := Sphere.longitude(stand)
	# Past where the history kept under the loaded ground could reach.
	var off := (world.tuning.history_lay_m + world.tuning.history_cell_m) * 2.0 + world.history_due()
	var at := World.flat_near(world.shape, world.player_world_x() + off, world.player_world_z())
	var mouth := at + Vector2(-sin(yaw), -cos(yaw)) * VENT_OFF
	var field := world.weather.field
	var t := 0.0
	while t < VENT_DAYS * world.tuning.day_minutes * 60.0:
		var burst := geology.next_burst(vent, t)
		var start := burst - VENT_LEAD
		var hour := world.weather.day.time_of_day(start, longitude)
		var towers := VENT_LEAD + Geology.BURST_SHAPE.x + Geology.BURST_SHAPE.y
		var sunlit := range(0, int(towers) + 1, 10).all(func(s: int) -> bool:
			return world.weather.day.sun_shown(start + s) == 1.0)
		if start >= 0.0 and hour >= scenario.day[0] and hour <= scenario.day[1] and sunlit \
				and not _place(field, scenario, at, Vector2.ZERO, start).is_empty() \
				and not _place(field, scenario, mouth, Vector2.ZERO, start).is_empty():
			return {"x": at.x, "z": at.y, "yaw": yaw, "time": start,
				"moon": Vector2(rad_to_deg(Sphere.latitude(stand)), rad_to_deg(longitude))}
		t = burst
	return {}


## Level sand across the run's long-term wind, nearest where the run began
## down it, at a moment in the day's window that's clear for ten minutes with
## a breeze in the range asked, the breeze on your left and you facing across it.
static func _open_breeze(world: World, scenario: Dictionary) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var at := open_sand(world)
	if is_nan(at.x):
		return {}
	var longitude := moon_at(world, scenario).y
	var t := 0.0
	while t < HORIZON:
		var hour := day.time_of_day(t, longitude)
		var blowing := field.wind_at(at.x, at.y, t)
		# Out in the open wind, no dune's lee taking it.
		if hour >= scenario.day[0] and hour <= scenario.day[1] and not _place(field, scenario, at, Vector2.ZERO, t).is_empty() \
				and world.weather.lee.share(at.x, at.y, blowing.angle()) < OPEN_LEE:
			var upwind := -blowing.normalized()
			var ahead := Vector2(-upwind.y, upwind.x)
			return {"x": at.x, "z": at.y, "yaw": atan2(-ahead.x, -ahead.y), "time": t}
		t += TIME_STEP
	return {}


## The nearest place to where the run began whose sand runs level across
## the run's long-term wind both ways, so a camp sails across it on the flat:
## between the dunes, which lie across that wind. NAN if none.
static func open_sand(world: World) -> Vector2:
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var across := down.orthogonal()
	var found := Vector2(NAN, NAN)
	var nearest := INF
	for side: float in OPEN_LINES:
		var d := -OPEN_SEARCH
		while d < OPEN_SEARCH:
			var at := world.spawn + down * d + across * side
			if at.distance_to(world.spawn) < nearest and _level_across(world, at, across):
				nearest = at.distance_to(world.spawn)
				found = at
			d += OPEN_STEP
	return found


static func _level_across(world: World, at: Vector2, across: Vector2) -> bool:
	var h := world.shape.height_at(at.x, at.y)
	var down := -across.orthogonal()
	for wide: float in OPEN_WIDE:
		var off := -OPEN_ACROSS
		while off <= OPEN_ACROSS:
			var p := at + across * off + down * wide
			if absf(world.shape.height_at(p.x, p.y) - h) > OPEN_RISE:
				return false
			off += OPEN_EVERY
	return true


## Feet of tall slip faces round where the run began, facing a wind blowing
## toward heading: level sand just past a slip face's slope, from a crest
## LEE_TALL m or more above. Nearest first.
static func feet(world: World, heading: float) -> Array[Vector2]:
	var down := Vector2.from_angle(heading)
	var found: Array[Vector2] = []
	for across: float in LEE_LINES:
		var from := world.spawn + down.orthogonal() * across - down * LEE_SEARCH
		var behind := PackedFloat64Array()
		var d := 0.0
		while d < 2.0 * LEE_SEARCH:
			var at := from + down * d
			behind.append(world.shape.height_at(at.x, at.y))
			d += LEE_STEP
			var n := behind.size()
			if n < 16:
				continue
			var h := behind[n - 1]
			var crest := h
			for k in range(n - 16, n):
				crest = maxf(crest, behind[k])
			# Level for a step, after two at a slip face's slope.
			if absf(behind[n - 2] - h) < LEE_STEP * 0.1 and behind[n - 4] - behind[n - 2] > 2.0 * LEE_STEP * 0.45 \
					and crest - h >= LEE_TALL:
				found.append(at)
	found.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(world.spawn) < b.distance_squared_to(world.spawn))
	return found


## No storm for ten minutes, or one due within the window asked, s from t,
## and with "lasts", passing within that window of coming.
static func _comes(field: WeatherField, scenario: Dictionary, from: Vector2, t: float) -> bool:
	var due: Array = scenario.get("due", [INF, INF])
	var comes := field.next_change(from.x, from.y, t, minf(due[1], 600.0), 10.0)
	var lasts: Array = scenario.get("lasts", [])
	return _within(comes, due) and (lasts.is_empty()
		or _within(field.next_change(from.x, from.y, t + comes, lasts[1], 10.0), lasts))


static func _within(value: float, span: Array) -> bool:
	return value >= span[0] and value <= span[1]


static func _stormy(field: WeatherField, from: Vector2, along: Vector2, d: float, t: float) -> bool:
	var p := from + along * d
	return field.raw_storm_at(p.x, p.y, t) > 0.0


## The edge between lo and hi along the ray, to a centimetre.
static func _refine(field: WeatherField, from: Vector2, along: Vector2, lo: float, hi: float,
		t: float) -> float:
	var at_hi := _stormy(field, from, along, hi, t)
	while hi - lo > 0.01:
		var mid := (lo + hi) * 0.5
		if _stormy(field, from, along, mid, t) == at_hi:
			hi = mid
		else:
			lo = mid
	return hi


## Storms come from upwind, so you face it. Dusk faces the sunset in the west,
## night faces east toward the dawn, the far side north to the pole star, and
## an eclipse faces Tu.
static func _facing(world: World, scenario: Dictionary, moon: Vector2, upwind: Vector2, t: float) -> float:
	var day := world.weather.day
	if scenario.get("relay", false):
		var to := _relay_from(world, moon, t)
		return atan2(-to.x, -to.z)
	if scenario.has("eclipse"):
		var tu := day.tu_direction(t, moon.x, moon.y)
		return atan2(-tu.x, -tu.z)
	if scenario.kind != "sky":
		return atan2(-upwind.x, -upwind.y)
	if scenario.has("moon"):
		return 0.0
	return PI / 2.0 if scenario.key == "dusk" else -PI / 2.0


## The relay satellite from a place on the moon at world time t, engine axes:
## where to look for it.
static func _relay_from(world: World, moon: Vector2, t: float) -> Vector3:
	var relay := Radio.relay_of(world)
	var p := Sphere.point(moon.x, moon.y)
	return DayCycle.local((relay.at(t) - p).normalized(), moon.x, moon.y)


## Whether the relay shows in the night sky from a place at world time t: sunlit,
## and between RELAY_SEEN degrees up, so it's in view facing it.
static func _relay_shows(world: World, moon: Vector2, t: float) -> bool:
	var up := rad_to_deg(asin(clampf(_relay_from(world, moon, t).y, -1.0, 1.0)))
	return up >= RELAY_SEEN.x and up <= RELAY_SEEN.y \
		and Radio.relay_of(world).sunlit(t, world.weather.day.sun_toward(t))


## A planter floating in front of you on its own tray and battery, a hook on
## each ring, on one line from a hook to a stake driven upwind of it:
## [planter, stake].
static func _tethered(world: World, right: float, ahead: float) -> Array[Node3D]:
	var player := world.player
	var device := Catalog.device(&"planter")
	drop(world, device, Transform3D(Basis(Vector3.UP, player.global_rotation.y),
		Vector3(0.0, world.tuning.hover_height, 0.0)), right, ahead)
	fill(world, device, [&"battery", &"hover_tray", &"hook", &"hook"])
	_afloat(world, device)
	var stake := Catalog.stake()
	var at := device.global_position - player.global_basis.z * TETHER_AHEAD
	world.content.add_child(stake)
	stake.drive(at, world.height_under(at))
	Line.between(world, device.free_tie(stake.global_position), stake.free_tie(device.global_position), 0.5)
	return [device, stake]


## A run's sealed-water start: you fed, watered and whole, carrying a fresh
## suit's kit, and on the sand in front of you a deck of two with a crude
## condenser, its panel and an empty canister, and a charged shield on two
## batteries, all one pool; and spare rations. Returns what it dropped.
static func survive(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	world.player.suit.restock()
	var rig := rig_at(world, SURVIVE_RIG, SURVIVE_DECK, false)
	(rig.named.condenser as Condenser).canister().drain(INF)
	var dropped := _of(rig)
	var yaw := Basis(Vector3.UP, world.player.global_rotation.y)
	for entry: Array in SURVIVE_RATIONS:
		var ration := Catalog.part(&"ration")
		drop(world, ration, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), entry[0], entry[1])
		dropped.append(ration)
	return dropped


## Two hover planters floating in front of you, each on a line to a stake as
## in the camp, sown with root-tubers and a vat fungus part grown, one tank
## full and one half: one to pick by hand, a saltbush among its root-tubers,
## and one with a harvester that keeps its slots sown and drops food onto
## you. A charged shield on its plate, switched off, stands between them,
## with a full canister by your feet to fit to the half-full one's water
## socket, which keeps its tank full. You start fed, watered and whole, on a
## fresh suit's kit and a spare root-tuber to sow. Returns what it dropped.
static func farm(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	world.player.suit.restock()
	world.player.suit.carried.append(Catalog.part(&"root_tuber"))
	var dropped: Array[Node3D] = []
	for where: Array in [FARM_BY_HAND, FARM_HARVESTER]:
		var tied := _tethered(world, where[0], where[1])
		var planter := tied[0] as Planter
		for id: StringName in (FARM_CROPS + [&"harvester"] if where == FARM_HARVESTER else FARM_BY_HAND_CROPS):
			var part := Catalog.part(id)
			for socket in planter.sockets():
				if socket.kind == part.kind and socket.part == null:
					planter.fit(part, socket)
					break
		for plant in planter.plants():
			plant.set_growth(FARM_GROWN[plant.crop])
		planter.tank_l = world.tuning.planter_tank_litres * (1.0 if planter.harvests() else 0.5)
		dropped.append_array(tied)
	dropped.append_array(plate(world, [&"shield", &"battery"], FARM_SHIELD))
	var yaw := Basis(Vector3.UP, world.player.global_rotation.y)
	var canister := Catalog.part(&"canister")
	drop(world, canister, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), FARM_CANISTER[0], FARM_CANISTER[1])
	dropped.append(canister)
	return dropped


## A board of each make at your feet, charged, and the small camp beside you
## for the range warnings to watch. What it dropped, the issue first.
static func board(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = []
	for i in BoardMakes.ALL.size():
		dropped.append(standing(world, BoardMakes.ALL[i], [&"battery"], BOARDS_AT[i]))
	dropped.append_array(_of(rig_at(world, BOARD_CAMP, BOARD_DECK, false)))
	return dropped


## A radio with a full battery on the sand in front of you, switched off, and
## a charged shield on its plate beside it, switched off. Returns what it dropped.
static func radio(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = [standing(world, &"radio", [&"battery", &"fm_converter", &"sw_converter"], RADIO_AT)]
	dropped.append_array(plate(world, [&"shield", &"battery"], RADIO_SHIELD))
	return dropped


## A radio with a shortwave converter, switched on to shortwave; the antenna
## kite set down off it, and a cable from the radio's aerial clip to the kite
## reel's lead terminal through a stake driven between: use the kite to fly it.
static func kite(world: World) -> Array[Node3D]:
	var shortwave := standing(world, &"radio", [&"battery", &"sw_converter"], RADIO_AT) as Radio
	shortwave.on = true
	shortwave.switch_band()
	var flier := standing(world, &"antenna_kite", [], [RADIO_AT[0] + 4.0, RADIO_AT[1]]) as AntennaKite
	var stake := Catalog.stake()
	world.content.add_child(stake)
	var mid := shortwave.global_position.lerp(flier.global_position, 0.5) + Vector3(0.0, 0.0, 0.6)
	stake.drive(mid, world.height_under(mid))
	var cable := Catalog.cable(world, shortwave.global_position + Vector3.UP, false)
	shortwave.fit(cable.plugs[0], _free(shortwave, &"lead"))
	flier.fit(cable.plugs[1], _free(flier, &"lead"))
	cable.route(stake)
	return [shortwave, flier, stake]


## The radio of "radio" on the weather station, beside its charged shield,
## switched off, a valve preamp in its bay to lift the relay on shortwave.
static func weather_station(world: World) -> Array[Node3D]:
	var dropped := radio(world)
	var tuned := dropped[0] as Radio
	tuned.fit(Catalog.part(&"valve_preamp"), _free(tuned, &"radio_bay"))
	_on_station(world, tuned)
	return dropped


## A radio switched on and tuned to the weather: far from Port Morgan, the
## relay repeating its tower on shortwave.
static func _on_station(_world: World, tuned: Radio) -> void:
	tuned.channel = Radio.WEATHER


## Beside the Walker: a clear day where the run's start puts it as the run
## begins, the clock's moment then, this far ahead of it on its route and
## off its right, its port's side, facing it as it comes.
const WALKER_AHEAD := 60.0
const WALKER_ASIDE := 4.5


static func _before_walker(world: World, scenario: Dictionary) -> Dictionary:
	var gods := Radio.gods_of(world)
	var radius := world.shape.history.radius
	# Begun at any moment, the run puts it at the same place then.
	gods.place_walker(world.start, 0.0)
	var q := gods.home(&"walker", 0.0)
	var heading := Sphere.bearing(q, gods.home(&"walker", 10.0))
	var spot := Sphere.toward(Sphere.toward(q, heading, WALKER_AHEAD / radius), heading + PI * 0.5, WALKER_ASIDE / radius)
	var place := _search(world, {"kind": "clear", "day": scenario.day}, world.spawn, Sphere.longitude(spot))
	if place.is_empty():
		return {}
	place.moon = Vector2(rad_to_deg(Sphere.latitude(spot)), rad_to_deg(Sphere.longitude(spot)))
	place.yaw = -Sphere.bearing(spot, q)
	return place


## A Console on a deck of two resting on the sand at your side, its screen,
## anemometer and particle sensor fitted, a radio on the Walker's FM station, the
## base shield and a compass stuck on it; the Console holding evidence of all
## three tells, a cable in its port and the cable's other plug in your hands.
const WALKER_CONSOLE := [&"screen", &"anemometer", &"particle_sensor"]
const WALKER_DECK := [1.0, 1.2]
const WALKER_RIG := [[&"piece", Vector2i(-1, 0)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.18), 180.0, [&"console", WALKER_CONSOLE], &"console"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.32), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.32), 0.0, [&"radio", [&"battery", &"fm_converter"]], &"radio"],
	[&"stick", Vector2i(-1, 0), &"top", Vector2(-0.2, -0.1), 0.0, &"shield", &"shield"],
	[&"stick", Vector2i(-1, 0), &"top", Vector2(0.27, 0.25), 0.0, &"battery"],
	[&"stick", Vector2i(-1, 0), &"top", Vector2(0.25, -0.3), 0.0, &"compass"]]


static func walker_camp(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	world.player.suit.restock()
	var rig := rig_at(world, WALKER_RIG, WALKER_DECK, false)
	var console: Console = rig.named.console
	var tuned: Radio = rig.named.radio
	tuned.on = true
	tuned.switch_band()
	tuned.fm_mhz = tuned.fm_of(&"walker")
	for tell: StringName in Deeds.TELLS:
		console.evidence[tell] = {"t": world.time, "value": 1.0}
	var at := console.global_position
	at.y = world.height_under(at)
	var cable := Catalog.cable(world, at)
	console.fit(cable.plugs[0], _free(console, &"port"))
	# Whatever you held goes down at your feet: the plug's in your hands.
	if world.player.hands.held != null:
		world.player.hands.drop()
	world.player.hands.hold(cable.plugs[1])
	var dropped := _of(rig)
	dropped.append(cable)
	return dropped


## A flare in your hands, and the deliveryship forced over you in DELIVERYSHIP_LEAD
## s: light it as it comes over and its cannon fires. Returns the flare.
static func deliveryship_pass(world: World) -> Array[Node3D]:
	var flare := in_hands(world, &"flare")
	deliveryship_over(world, DELIVERYSHIP_LEAD)
	return [flare]


## The deliveryship's low pass forced: its orbit turned to bring it straight over
## you `lead` s from now (Satellite.pass_over).
static func deliveryship_over(world: World, lead: float) -> void:
	var moon := world.moon
	var orbit: Satellite = Radio.constellation_of(world).orbits[Airdrop.DELIVERYSHIP]
	orbit.pass_over(Sphere.point(moon.latitude, moon.longitude), world.time + lead)


## The radio of "radio" switched on and tuned to the Almanac, a far god whose
## AM comes round the moon past the skip at night.
static func far_god(world: World) -> Array[Node3D]:
	var dropped := radio(world)
	var tuned := dropped[0] as Radio
	tuned.on = true
	tuned.frequency = Radio.gods_of(world).carrier(&"almanac", world.time)
	return dropped


## The reference camp, parked round you and left running, on a deck two
## pieces by two floating on a tray under every piece, a hook on every free
## ring, everything on it one pool: upwind, the condenser and the bank's
## batteries and a lamp, and the base shield across from it; downwind, the
## panels, the light panel's port toward the turbine. The deck is moored to a
## stake upwind of it. Beyond the stake two planters with harvesters float on
## their own trays and batteries, sown and watered, near enough to drop food
## onto you, each on a hose from the condenser, the second on the first's
## end, so it waters both. Each is moored to a stake of its own upwind of it:
## a hose's weight draws a floating planter in toward the deck. The light
## panel holds a turbine out in the wind beyond the bubble on a strong cable:
## a turbine only works planted, and a loose one slides off in a storm. You
## start fed and watered, stocked up to leave it running, with spare stakes,
## a coil and a hose. Returns what it dropped, the deck before what's on it.
static func afk(world: World) -> Array[Node3D]:
	var player := world.player
	player.vitals.fresh()
	var carried := player.suit.carried
	for thing in carried:
		thing.free()
	carried.clear()
	for i in AFK_CANISTERS:
		carried.append(Catalog.part(&"canister"))
	for i in AFK_STAKES:
		carried.append(Catalog.stake())
	for id: StringName in [&"coil", Hose.END]:
		var rolled := Catalog.part(id)
		rolled.set_meta(&"rolled", id)
		carried.append(rolled)
	player.suit.carry_devices()
	var rig := rig_at(world, AFK_RIG, AFK_DECK)
	var deck := rig.deck
	var condenser: Condenser = rig.named.condenser
	var shield: ShieldGenerator = rig.named.shield
	var dropped := _of(rig)
	var stake := _driven(world, AFK_STAKE)
	dropped.append(stake)
	# Nearly taut, so the strong cable's weight doesn't draw the deck in toward the turbine.
	dropped.append(Line.between(world, _deck_tie(deck, Vector2i.ZERO, Vector2i(0, -1)),
		stake.free_tie(deck.global_position), 0.05))
	for i in AFK_PLANTERS.size():
		var planter := standing(world, &"planter", [&"battery", &"hover_tray", &"harvester", &"hook", &"hook"] + FARM_CROPS,
			AFK_PLANTERS[i]) as Planter
		planter.tank_l = world.tuning.planter_tank_litres
		_afloat(world, planter)
		var own := _driven(world, AFK_PLANTER_STAKES[i])
		dropped.append_array([planter, own])
		dropped.append(Line.between(world, planter.free_tie(own.global_position), own.free_tie(planter.global_position)))
		# Its plugs and ends go with the devices they're in.
		dropped.append(plumb(world, condenser, planter))
	var port: Device = rig.named.port
	var turbine := _behind(world, &"turbine", [&"battery"], port, deck, AFK_TURBINE_BACK)
	dropped.append(turbine)
	dropped.append(wire(world, port, turbine, true))
	shield.stand(true)
	return dropped


## A camp built for wind, as the forecast would have it: the reference
## camp's deck of four pieces resting on the sand with a hook on every ring,
## moored to a stake upwind; on it a Console with its screen, an anemometer
## and a particle sensor, a radio behind it on the weather station, the base
## shield on one battery, running, and the radio's strong cable holding a
## turbine out in the wind beyond the bubble: enough for any ordinary storm's
## 200 W. You start fed and watered, a compass in your suit. Returns what it
## dropped, the deck first.
static func anomaly_camp(world: World) -> Array[Node3D]:
	var player := world.player
	player.vitals.fresh()
	player.suit.restock()
	player.suit.carried.append(Catalog.part(&"compass"))
	var rig := rig_at(world, ANOMALY_RIG, AFK_DECK, false)
	var deck := rig.deck
	var radio: Radio = rig.named.radio
	_on_station(world, radio)
	var shield: ShieldGenerator = rig.named.shield
	var stake := _driven(world, AFK_STAKE)
	var line := Line.between(world, _deck_tie(deck, Vector2i.ZERO, Vector2i(0, -1)),
		stake.free_tie(deck.global_position), 0.05)
	var turbine := _behind(world, &"turbine", [], radio, deck, AFK_TURBINE_BACK)
	var cable := wire(world, radio, turbine, true)
	shield.stand(true)
	var dropped := _of(rig)
	dropped.append_array([stake, line, turbine, cable])
	return dropped


## A device on the sand this far straight back from another on a deck, the
## deck's own back, its port turned toward that one's.
static func _behind(world: World, id: StringName, parts: Array, from: Device, deck: Device, back: float) -> Device:
	var at := from.global_position + deck.global_basis.z.normalized() * back
	at.y = world.height_under(at)
	var device := Catalog.device(id)
	var size: Vector3 = Catalog.DEVICES[id].size
	world.content.add_child(device)
	var to := from.global_position - at
	# Its port on its right: turned so its right faces back toward `from`.
	device.global_transform = Transform3D(Basis(Vector3.UP, atan2(-to.z, to.x)), at + Vector3.UP * size.y * 0.5)
	fill(world, device, parts)
	return device


## A stake driven into the sand, right and ahead of you.
static func _driven(world: World, where: Array) -> Stake:
	var player := world.player
	var stake := Catalog.stake()
	world.content.add_child(stake)
	var at: Vector3 = player.global_position + player.global_basis.x * where[0] - player.global_basis.z * where[1]
	stake.drive(at, world.height_under(at))
	return stake


## Where a line ties to a deck: the hook on a piece's edge ring.
static func _deck_tie(deck: Chassis, cell: Vector2i, toward: Vector2i) -> Socket:
	for node in Rig.ring_of(deck, cell, toward).fitted:
		if node is Socket:
			return node
	return null


## A rig built from its steps, set down right and ahead of you squared to
## you: floating as high as its trays hold it, or its runners, over the sand
## under it, or resting on the sand.
static func rig_at(world: World, steps: Array, where: Array, floating := true) -> Rig:
	var rig := Rig.build(null, steps)
	rig.deck.resting = not floating
	rig.deck.lift_share = 1.0 if floating else 0.0
	drop(world, rig.deck, Transform3D(Basis(Vector3.UP, world.player.global_rotation.y), Vector3.ZERO), where[0], where[1])
	_afloat(world, rig.deck)
	return rig


## What a rig dropped, the deck first and the devices on it after.
static func _of(rig: Rig) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for each in rig.made:
		out.append(each as Node3D)
	return out


## A plate: one chassis resting on the sand right and ahead of you, these
## stuck on its top, each with its own slots filled. What it dropped.
static func plate(world: World, ids: Array, where: Array) -> Array[Node3D]:
	var steps := []
	for i in ids.size():
		steps.append([&"stick", Vector2i.ZERO, Chassis.TOP, PLATE_SPOTS[i], 0.0, ids[i]])
	return _of(rig_at(world, steps, where, false))


## Where it stands: floating as high as its trays hold it over the sand under
## it, on average, or resting on the highest of it.
static func _afloat(world: World, device: Device) -> void:
	var spots: Array = [Vector3.ZERO]
	if device is Chassis:
		spots = (device as Chassis).grid().map(func(p: Chassis) -> Vector3: return p.pose().origin)
	var sand := 0.0
	var top := -INF
	var middle := Vector3.ZERO
	for spot: Vector3 in spots:
		var under := world.height_under(device.global_transform * spot)
		sand += under / spots.size()
		top = maxf(top, under)
		middle += spot / spots.size()
	var up := device.rest_height() if not device.resting else -Finds.bounds(device).position.y + 0.02
	device.global_position.y += (top if device.resting else sand) + up - (device.global_transform * middle).y


## A cable laid between two devices, plugged into the port of each; a
## strong one holds them together too.
static func wire(world: World, a: Device, b: Device, strong := false) -> Cable:
	var at := (a.global_position + b.global_position) * 0.5
	at.y = world.height_under(at)
	var cable := Catalog.cable(world, at, strong)
	for i in 2:
		var device: Device = [a, b][i]
		device.fit(cable.plugs[i], _free(device, &"port"))
	return cable


## Four chassis pieces lying on the sand ahead of you, a hover tray on its
## back in front of each, a spare piece and a frame to raise it on as a wall,
## two charged batteries and the light shield to power a deck, and a
## condenser with an empty canister. The first piece's outer ring has a hook
## with a line to a stake, which a piece joined there pops; two more hooks
## and a coil lie at your feet. Returns what it dropped.
static func chassis(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = []
	for where: Array in CHASSIS_PIECES:
		dropped.append(standing(world, &"chassis", [], where))
	var first := dropped[0] as Chassis
	first.fit(Catalog.part(&"hook"), Rig.ring_of(first, Vector2i.ZERO, Vector2i(-1, 0)))
	var stake := _driven(world, CHASSIS_STAKE)
	Line.between(world, _deck_tie(first, Vector2i.ZERO, Vector2i(-1, 0)), stake.free_tie(first.global_position))
	dropped.append(stake)
	var yaw := Basis(Vector3.UP, world.player.global_rotation.y)
	for where: Array in CHASSIS_TRAYS:
		var tray := Catalog.part(&"hover_tray")
		drop(world, tray, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), where[0], where[1])
		dropped.append(tray)
	for where: Array in CHASSIS_HOOKS:
		var hook := Catalog.part(&"hook")
		drop(world, hook, Transform3D(yaw, Vector3(0.0, 0.04, 0.0)), where[0], where[1])
		dropped.append(hook)
	dropped.append_array(stakes_and_coils(world, [], [CHASSIS_COIL]))
	dropped.append(standing(world, &"chassis", [], CHASSIS_SPARE))
	var frame := Catalog.part(&"frame")
	drop(world, frame, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), CHASSIS_FRAME[0], CHASSIS_FRAME[1])
	dropped.append(frame)
	for where: Array in CHASSIS_BATTERIES:
		var cell := Catalog.part(&"battery")
		drop(world, cell, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), where[0], where[1])
		dropped.append(cell)
	dropped.append(standing(world, &"light_shield", [], CHASSIS_SHIELD))
	var condenser := standing(world, &"condenser", [&"canister"], CHASSIS_CONDENSER) as Condenser
	condenser.canister().drain(INF)
	dropped.append(condenser)
	return dropped


## A Console on a deck of two pieces floating on a tray each, its screen to
## you at your eyes, its screen and every instrument in its ports, two big
## batteries and a radio behind it; the base shield beside it on the other
## piece with a battery, switched off, smart from the Console; the deck
## moored by a hook on its far ring to a stake upwind. You start fed and
## watered. Returns what it dropped, the deck first.
static func console(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	world.player.suit.restock()
	var rig := rig_at(world, CONSOLE_RIG, CONSOLE_DECK)
	var deck := rig.deck
	var stake := _driven(world, CONSOLE_STAKE)
	var hook := Rig.ring_of(deck, Vector2i.ZERO, Vector2i(0, -1))
	deck.fit(Catalog.part(&"hook"), hook)
	var dropped := _of(rig)
	dropped.append(stake)
	dropped.append(Line.between(world, _deck_tie(deck, Vector2i.ZERO, Vector2i(0, -1)), stake.free_tie(deck.global_position), 0.3))
	return dropped


## A hose laid from one device to another, an end in the water socket of
## each: the first's own, or the free one on the end already there.
static func plumb(world: World, a: Device, b: Device) -> Hose:
	var at := (a.global_position + b.global_position) * 0.5
	at.y = world.height_under(at)
	var hose := Catalog.hose(world, at)
	for i in 2:
		var device: Device = [a, b][i]
		device.fit(hose.plugs[i], _free(device, &"water"))
	return hose


## A device's first free socket of a kind, or null.
static func _free(device: Device, kind: StringName) -> Socket:
	for socket in device.sockets():
		if socket.kind == kind and socket.is_open():
			return socket
	return null


## The sailing camp: a deck two pieces by two on skates under every piece,
## facing across the wind ahead of you, a mast with its sail furled on the
## front piece to windward, its ballast in a frame behind it and a charged
## shield, switched off, behind to leeward. The sheet runs from the boom's
## end to your waist, and a charged board lies at your feet. Work the hand winch to
## raise the sail, and ride.
static func sail(world: World) -> Array[Node3D]:
	var rig := rig_at(world, SQUARE + [SAIL_TAIL] + SKATES + [SAIL_MAST, SAIL_WINCH,
		[&"up", &"mast", &"front", Vector2(0.0, 0.5), 0.0, &"streamer"]] + SAIL_BALLAST + [SAIL_SHIELD], SAIL_DECK)
	var mast: Mast = rig.named.mast
	var hoist := mast.rig_hoist(rig.named.hoist)
	var board := standing(world, &"board", [&"battery"], SAIL_BOARD)
	var sheet := sheet_to_waist(world, mast)
	# Eased for a start across the wind: reel in as it picks up speed.

	var dropped := _of(rig)
	dropped.append_array([hoist, board, sheet, standing(world, &"sailing_notes", [], [-0.75, 0.8])])
	if Controls.ui != null:
		Controls.ui.teach("sailing_notes", "Sailing field notes lie beside the board. Look at them and {interact} to read, or take them with you.")
	return dropped


## Sailing a larger camp: the rig ahead as the sail scenario's deck, less its
## shield, and behind you the camp, a deck two by two on skates with the
## shield (off) at its front and two big batteries. An explicit towline joins
## the rig's stern hook to the camp's bow hook; only the sail's sheet goes to
## your waist, with the board at your feet. Raise the
## sail, ride, and carve to steer.
static func sail_tow(world: World) -> Array[Node3D]:
	var rig := rig_at(world, SQUARE + [SAIL_TAIL] + SKATES + [SAIL_MAST, SAIL_WINCH] + SAIL_BALLAST + [[&"hook", Vector2i(0, 2), Vector2i(0, 1)]], SAIL_DECK)
	var mast: Mast = rig.named.mast
	var hoist := mast.rig_hoist(rig.named.hoist)
	var camp := rig_at(world, SQUARE + SKATES + TOW_STORES, TOW_CAMP)
	var board := standing(world, &"board", [&"battery"], SAIL_BOARD)
	var sheet := sheet_to_waist(world, mast)
	var line := Line.between(world, _deck_tie(rig.deck, Vector2i(0, 2), Vector2i(0, 1)), _deck_tie(camp.deck, Vector2i.ZERO, Vector2i(0, -1)), 0.5)

	var dropped := _of(rig) + _of(camp)
	dropped.append_array([hoist, board, sheet, line])
	return dropped


## A land yacht from found parts: a deck three by two floating on hover
## trays and two centreline keels, the mast forward on that same line, and
## the helm aft between balanced batteries; the sheet at your waist. Hoist,
## sit at the helm, and reel in.
static func yacht(world: World) -> Array[Node3D]:
	var rig := rig_at(world, YACHT_RIG + [[&"piece", Vector2i(1, 2)]], YACHT_DECK)
	var mast: Mast = rig.named.mast
	var hoist := mast.rig_hoist(rig.named.hoist)
	var sheet := sheet_to_waist(world, mast)

	var dropped := _of(rig)
	dropped.append_array([hoist, sheet])
	return dropped


## A line from a mast's boom's end to your waist, a little slack.
static func sheet_to_waist(world: World, mast: Mast) -> Line:
	var line := to_waist(world, mast.boom_tie())
	mast.rig_sheet(line, SAIL_EASED)
	return line


## A line from a device's tie socket to your waist, a little slack.
static func to_waist(world: World, tie: Socket) -> Line:
	return Line.to_waist(world, tie, SAIL_SHEET_SLACK)


## Two stakes driven across the wind you face, a few steps ahead, a line
## strung between them for the drift to snag on. Returns what it dropped.
static func catch_line(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = []
	for where: Array in CATCH_LINE:
		dropped.append(_driven(world, where))
	var stakes := dropped.duplicate()
	dropped.append(Line.between(world, (stakes[0] as Stake).free_tie(stakes[1].global_position),
		(stakes[1] as Stake).free_tie(stakes[0].global_position), 0.3))
	return dropped


## The still camp to sleep at: you fed and watered by a deck of two resting
## on the sand, its bedroll and its shield running on its battery and panel,
## a wall to windward on a frame, and a radio on the weather station to wake
## you when it calls a storm. What it dropped, the deck first.
static func sleep(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	var rig := rig_at(world, SLEEP_RIG, SLEEP_DECK, false)
	_on_station(world, rig.named.radio)
	(rig.named.shield as ShieldGenerator).stand(true)
	return _of(rig)


## How far round the run's start a dune's ruin is looked for, m, and how far
## off its ground you stand downwind of it.
const DUNE_SEARCH := 2500.0
const DUNE_STAND := 6.0


## A big dune's ruin round a world place, nearest first, and the first minute
## in `days` a storm has it at least `least` out of the sand (Exposure.level),
## with `passed` once the storm has let go of it: {key, site, time}, or {}.
## Each found on a copy of its seed, so the world's own is looked at as play
## would look at it.
static func bared_dune_ruin(world: World, from: Vector2, radius: float, days := 2.0, least := 0.3,
		passed := false) -> Dictionary:
	var dunes := world.shape.sites.dunes
	var field := world.weather.field
	var seeds := dunes.cells_near(from, radius)
	seeds.sort_custom(func(a: DuneRuins.Seed, b: DuneRuins.Seed) -> bool:
		return dunes.middle(a).distance_to(from) < dunes.middle(b).distance_to(from))
	for each in seeds:
		var copy := DuneRuins.Seed.new()
		copy.key = each.key
		copy.id = each.id
		dunes.locate(copy)
		if copy.site == null:
			continue
		for m in range(30, roundi(days * 24.0 * 60.0)):
			var t := m * 60.0
			if Exposure.level(copy.site.depth, copy.site.pure_taken(t)) >= least \
					and (not passed or field.raw_storm_at(copy.site.x, copy.site.z, t) < 0.0):
				return {"key": copy.key, "site": copy.site, "time": t}
	return {}


## A scoop in your hands and a sieve in your suit, to dig the ruin out.
static func dig(world: World) -> Array[Node3D]:
	var player := world.player
	var sieve := Catalog.part(&"sieve")
	player.suit.carried.append(sieve)
	var scoop := Catalog.part(&"sand_scoop")
	drop(world, scoop, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, 0.0)), 0.0, 0.8)
	player.hands.hold(scoop)
	return [scoop]


## A charged board at your feet, to ride to the vent.
static func vent(world: World) -> Array[Node3D]:
	return [standing(world, &"board", [&"battery"], BOARDS_AT[0])]


## Your own bare chassis on the sand beside you, to stick what you find on.
static func yours(world: World) -> Array[Node3D]:
	return [standing(world, &"chassis", [], YOURS)]


## A part, by its catalog id, in your hands.
static func in_hands(world: World, id: StringName) -> Part:
	var part := Catalog.part(id)
	world.content.add_child(part)
	part.global_position = world.player.global_position + Vector3.UP
	world.player.hands.hold(part)
	return part


## A device standing on the sand, squared to you, with these parts fitted.
static func standing(world: World, id: StringName, parts: Array, where: Array) -> Device:
	var device := Catalog.device(id)
	var size: Vector3 = Catalog.DEVICES[id].size
	drop(world, device, Transform3D(Basis(Vector3.UP, world.player.global_rotation.y),
		Vector3(0.0, size.y * 0.5, 0.0)), where[0], where[1])
	fill(world, device, parts)
	return device


## These parts fitted into a device's first free sockets of their kinds.
static func fill(world: World, device: Device, parts: Array) -> void:
	for part_id: StringName in parts:
		var part := Catalog.part(part_id)
		world.content.add_child(part)
		var socket := _free(device, part.kind)
		if socket != null:
			device.fit(part, socket)


## Stakes lying flat across your way and coils lying on their backs.
static func stakes_and_coils(world: World, stakes: Array, coils: Array) -> Array[Node3D]:
	var player := world.player
	var yaw := Basis(Vector3.UP, player.global_rotation.y)
	var dropped: Array[Node3D] = []
	for entry: Array in stakes:
		var stake := Catalog.stake()
		drop(world, stake, Transform3D(yaw * Basis(Vector3.BACK, PI / 2.0), Vector3(0.0, 0.035, 0.0)),
			entry[0], entry[1])
		dropped.append(stake)
	for entry: Array in coils:
		var line := Line.make(world, world.tuning.rope_coil_length)
		var at: Vector3 = player.global_position + player.global_basis.x * entry[0] - player.global_basis.z * entry[1]
		at.y = world.height_under(at) + 0.02
		line.coil.global_transform = Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), at)
		dropped.append(line.coil)
	return dropped


## Sets a body on the sand, right and ahead of you, in the pose given.
static func drop(world: World, body: Node3D, pose: Transform3D, right: float, ahead: float) -> void:
	var player := world.player
	var at := player.global_position + player.global_basis.x * right - player.global_basis.z * ahead
	at.y = world.height_under(at) + 0.02
	world.content.add_child(body)
	body.global_transform = pose.translated(at)
