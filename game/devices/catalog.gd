class_name Catalog
extends RefCounted
## Every device frame and part the skeleton knows, built in code as boxes
## with their few sockets in defined spots, and drawn in B's paint (Dress).
## The only slots left are plugs and water taps, and what's a thing's own (a
## planter's beds, a Console's ports, a mast's sail, a carried thing's
## battery); everything else sticks on a chassis's sticky faces (Stick).
## Salvage finds them, and the creative menu hands any of them over.

## Socket kinds, with the colour of the tell that marks a free one.
const KINDS := {
	&"battery": Color(0.95, 0.75, 0.2),
	&"ring": Color(0.85, 0.85, 0.85),
	&"bottom": Color(0.3, 0.7, 0.95),
	&"plant_pot": Color(0.55, 0.85, 0.3),
	&"plant_standard": Color(0.35, 0.65, 0.2),
	&"plant_deep": Color(0.25, 0.45, 0.15),
	&"port": Color(1.0, 0.5, 0.1),
	&"tie": Color(0.42, 0.31, 0.2),
	&"water": Color(0.3, 0.6, 1.0),
	&"mod": Color(0.75, 0.35, 0.7),
	&"food": Color(0.8, 0.7, 0.35),
	&"face": Color(0.55, 0.45, 0.95),
	&"sail": Color(0.92, 0.86, 0.7),
	&"computer_mod": Color(0.25, 0.9, 0.9),
	&"computer_top": Color(0.65, 1.0, 0.95),
	&"screen": Color(0.9, 0.95, 0.95),
	&"radio_mod": Color(0.95, 0.4, 0.55),
}

## Parts: the socket kind they fit, weight, size (z is how far they stand out
## from their socket, or from the face they're stuck on), colour and what they
## give a device. A "tie" is the ring a part adds while it's fitted, where a
## line's end snaps on. A part sticks on a chassis unless its kind is one
## SLOT_ONLY names.
const PARTS := {
	&"coalcane_bundle": {"kind": &"fuel", "label": "Preserved coalcane", "mass": 3.0, "size": Vector3(0.4, 0.3, 0.65),
		"color": Color(0.25, 0.17, 0.08), "stats": {}},
	&"battery": {"kind": &"battery", "label": "Battery", "mass": 4.0, "size": Vector3(0.22, 0.14, 0.12),
		"color": Color(0.2, 0.2, 0.22), "stats": {"capacity_wh": 100.0}},
	&"big_battery": {"kind": &"battery", "label": "Big battery", "mass": 9.0, "size": Vector3(0.26, 0.18, 0.18),
		"color": Color(0.15, 0.15, 0.3), "stats": {"capacity_wh": 300.0}},
	&"hook": {"kind": &"ring", "label": "Rope hook", "mass": 0.5, "size": Vector3(0.08, 0.08, 0.1),
		"color": Color(0.6, 0.6, 0.65), "stats": {"hooks": 1}, "tie": Vector3(0.0, 0.0, 0.16)},
	&"hover_tray": {"kind": &"bottom", "label": "Hover tray", "mass": 6.0, "size": Vector3(0.7, 0.7, 0.08),
		"color": Color(0.25, 0.45, 0.6), "stats": {"lift_kg": 80.0}},
	# Runners fit a bottom mount in place of a tray and ride the sand, along
	# their device's length: hold is the share of the load they hold at rest,
	# glide the share they drag sliding and plough how much more for each m/s,
	# grip the most of the load they hold across, and keel how far the blades
	# reach below the frame they hang from, so only they meet the sand. Skates are two long blades that bite hard; a
	# board plate drags a little more and lets go across sooner, so a camp on
	# it skids where one on skates would trip.
	&"skates": {"kind": &"bottom", "label": "Skates", "mass": 4.0, "size": Vector3(0.66, 0.9, 0.03),
		"color": Color(0.5, 0.52, 0.55), "stats": {"glide": 0.035, "plough": 0.03, "grip": 0.9, "hold": 0.1, "keel": 0.05}},
	&"board_plate": {"kind": &"bottom", "label": "Board plate", "mass": 6.0, "size": Vector3(0.72, 0.9, 0.02),
		"color": Color(0.35, 0.37, 0.4), "stats": {"glide": 0.05, "plough": 0.04, "grip": 0.45, "hold": 0.12, "keel": 0.03}},
	# A skimmer's ventral strake: a hover tray drawn out into a fin, lifting
	# less, whose field bites the sand across its length as a runner ploughs,
	# holding the camp it floats by `keel` of its weight, so a floating camp
	# sails across the wind and tacks. Along its length it drags `keel_drag`
	# of that. Lengthwise along its deck, as runners turn.
	&"keel": {"kind": &"bottom", "label": "Keel", "mass": 7.0, "size": Vector3(0.24, 0.9, 0.08),
		"color": Color(0.33, 0.35, 0.24), "stats": {"lift_kg": 60.0, "keel": 0.6, "keel_drag": 0.02}},
	# A sail furled on its boom: it fits a mast, and its sheet ties on at the
	# boom's end.
	&"sail": {"kind": &"sail", "label": "Sail", "mass": 5.0, "size": Vector3(0.18, 0.18, 2.2),
		"color": Color(0.85, 0.8, 0.68), "stats": {"sail_m2": 5.5}, "tie": Vector3(0.0, 0.0, 2.26)},
	# Half a piece across, so two lie side by side.
	&"solar_panel": {"kind": &"panel", "label": "Solar panel", "mass": 5.0, "size": Vector3(0.8, 0.4, 0.04),
		"color": Color(0.1, 0.15, 0.35), "stats": {"solar_w": 60.0}},
	&"lamp": {"kind": &"panel", "label": "Lamp", "mass": 1.0, "size": Vector3(0.12, 0.12, 0.25),
		"color": Color(0.95, 0.9, 0.6), "stats": {"light_w": 5.0}},
	# An open cube of rails that sticks square on a piece's top and takes a
	# piece, a screen or fabric on each other face (Frame). Its size is its
	# bounds: it's built of rails.
	&"frame": {"kind": &"frame", "label": "Frame", "mass": 4.0, "size": Vector3(Frame.WIDE, Frame.WIDE, Frame.TALL),
		"color": Color(0.3, 0.32, 0.33), "stats": {}},
	# A crude sail on a frame's face: stiff, it can't belly or be trimmed.
	&"fabric": {"kind": &"face", "label": "Fabric", "mass": 1.5, "size": Vector3(0.94, 0.94, 0.012),
		"color": Color(0.78, 0.7, 0.55), "stats": {}},
	# Crops, sown in a planter's slots. Each is all data, read by one growth
	# path (Plant): its kind is the planter it fits (a pot, a standard planter
	# or a deep bed), and its "crop" says how it grows:
	#   family: day, storm or special; light: what it grows by, the sun, the
	#   dark or a lamp; lit: the felt light it starts to grow at and grows full
	#   at (a dark crop's runs down); minutes of full growth from sown to
	#   mature; litres it drinks on the way; yields, a harvest as [part, units],
	#   the first what comes to your hands.
	#   Its tolerances, each the most it grows in and the most it holds through
	#   before it wilts back, so they say how much shelter it needs: wind, m/s;
	#   particles, the felt storm; heat and cold, °C. Radiation is the same,
	#   but nothing in the weather gives a dose yet.
	#   propagule: what it's sown again from; whether it's clean stock or wild
	#   is each plant's own (Plant).
	#   stages, its twists on the shared seedling, growing, mature, to seed:
	#   regrows, the share it keeps when picked, so it grows again in its
	#   slot; bursts, minutes it takes to fruit once mature, only in a storm;
	#   folds, minutes ahead of a storm its leaves close; never_dies, past its
	#   limits it holds instead of wilting. eats_scraps, keeps_growing, cycles,
	#   stump and awaits_rain are said of a crop but do nothing yet.
	&"root_tuber": {"kind": &"plant_standard", "label": "Root-tuber", "mass": 0.5, "size": Vector3(0.16, 0.16, 0.22),
		"color": Color(0.3, 0.55, 0.22), "stats": {"plants": 1},
		"crop": {"family": &"day", "light": &"sun", "lit": Vector2(0.25, 0.6), "minutes": 3.0, "litres": 0.25,
			"yields": [[&"tubers", 4]], "wind": Vector2(25.0, 45.0), "particles": Vector2(0.9, 1.0),
			"heat": Vector2(60.0, 70.0), "cold": Vector2(-10.0, -30.0), "radiation": Vector2(1.0, 1.0),
			"propagule": &"tuber", "stages": {}}},
	&"vat_fungus": {"kind": &"plant_pot", "label": "Vat fungus", "mass": 0.4, "size": Vector3(0.14, 0.14, 0.14),
		"color": Color(0.82, 0.78, 0.68), "stats": {"plants": 1},
		"crop": {"family": &"storm", "light": &"dark", "lit": Vector2(0.5, 0.25), "minutes": 5.0, "litres": 0.3,
			"yields": [[&"fungus_caps", 4]], "wind": Vector2(12.0, 35.0), "particles": Vector2(1.0, 1.0),
			"heat": Vector2(45.0, 55.0), "cold": Vector2(-5.0, -15.0), "radiation": Vector2(0.3, 0.6),
			"propagule": &"spores", "stages": {"regrows": 0.0, "bursts": 1.0, "eats_scraps": true}}},
	&"saltbush": {"kind": &"plant_standard", "label": "Saltbush", "mass": 0.6, "size": Vector3(0.2, 0.2, 0.26),
		"color": Color(0.66, 0.7, 0.64), "stats": {"plants": 1},
		"crop": {"family": &"day", "light": &"sun", "lit": Vector2(0.2, 0.55), "minutes": 12.0, "litres": 0.15,
			"yields": [[&"salt", 4], [&"saltbush_leaves", 1]], "wind": Vector2(40.0, 40.0), "particles": Vector2(1.0, 1.0),
			"heat": Vector2(65.0, 65.0), "cold": Vector2(-20.0, -20.0), "radiation": Vector2(1.0, 1.0),
			"propagule": &"cutting", "stages": {"regrows": 0.5, "folds": 2.0, "never_dies": true}}},
	# Fits a planter's mod mount: ripe crops go into the planter's own storage.
	&"harvester": {"kind": &"mod", "label": "Harvester", "mass": 1.5, "size": Vector3(0.22, 0.14, 0.1),
		"color": Color(0.5, 0.3, 0.45), "stats": {"harvester": 1}},
	&"plug": {"kind": &"port", "label": "Cable plug", "mass": 0.2, "size": Vector3(0.06, 0.06, 0.09),
		"color": Color(1.0, 0.5, 0.1), "stats": {}},
	&"strong_plug": {"kind": &"port", "label": "Strong cable plug", "mass": 0.3, "size": Vector3(0.07, 0.07, 0.1),
		"color": Color(0.7, 0.15, 0.1), "stats": {}},
	# A hose's end fits a water socket as a canister does, and fitted it "adds"
	# one of its own on top, [kind, position, outward], so a canister or
	# another hose goes on there too.
	&"hose_end": {"kind": &"water", "label": "Hose end", "mass": 0.3, "size": Vector3(0.08, 0.08, 0.12),
		"color": Paint.HOSE, "stats": {}, "adds": [&"water", Vector3(0.0, 0.055, 0.075), Vector3.UP]},
	&"rope_end": {"kind": &"tie", "label": "Rope end", "mass": 0.3, "size": Vector3(0.05, 0.05, 0.08),
		"color": Color(0.3, 0.22, 0.14), "stats": {}},
	# Nothing takes a coil: picked up, it gives you its first end.
	&"coil": {"kind": &"coil", "label": "Rope coil", "mass": 1.5, "size": Vector3(0.34, 0.34, 0.07),
		"color": Color(0.42, 0.31, 0.2), "stats": {}},
	# Sealed water, and sealed food, which only a survival kit's slot takes:
	# they live in what you carry.
	&"canister": {"kind": &"water", "label": "Water canister", "mass": 2.4, "size": Vector3(0.12, 0.12, 0.26),
		"color": Color(0.55, 0.62, 0.68), "stats": {}},
	&"ration": {"kind": &"food", "label": "Ration", "mass": 0.5, "size": Vector3(0.16, 0.1, 0.06),
		"color": Color(0.45, 0.42, 0.25), "stats": {}},
	# What a harvest gives, "each" unit of it: food like a ration, holding its
	# kcal, and salt, which does nothing yet but stack with what you carry.
	# Food in "pieces" shows what's left by how many are left, not a light.
	&"tubers": {"kind": &"food", "label": "Tubers", "mass": 0.6, "size": Vector3(0.16, 0.1, 0.08),
		"color": Color(0.72, 0.58, 0.36), "stats": {}, "each": 150.0, "pieces": 5},
	&"fungus_caps": {"kind": &"food", "label": "Fungus caps", "mass": 0.4, "size": Vector3(0.14, 0.1, 0.08),
		"color": Color(0.85, 0.8, 0.65), "stats": {}, "each": 150.0, "pieces": 3},
	&"saltbush_leaves": {"kind": &"food", "label": "Saltbush leaves", "mass": 0.2, "size": Vector3(0.12, 0.08, 0.06),
		"color": Color(0.62, 0.68, 0.6), "stats": {}, "each": 120.0, "pieces": 5},
	&"salt": {"kind": &"salt", "label": "Salt", "mass": 0.1, "size": Vector3(0.07, 0.07, 0.05),
		"color": Color(0.9, 0.9, 0.86), "stats": {}},
	# Nothing takes a compass: it's read, in your hand or in the inventory.
	&"compass": {"kind": &"compass", "label": "Compass", "mass": 0.2, "size": Vector3(0.12, 0.12, 0.03),
		"color": Color(0.26, 0.28, 0.29), "stats": {}},
	# A signal flare: lit, it calls the Surveyor's cannon down on itself as it passes (Flare).
	&"flare": {"kind": &"flare", "label": "Signal flare", "mass": 0.3, "size": Vector3(0.05, 0.05, 0.3),
		"color": Color(0.75, 0.12, 0.08), "stats": {}},
	# What the Surveyor's cannon fires down (Airdrop): a container, its contents to come.
	&"cargo": {"kind": &"cargo", "label": "Cargo container", "mass": 80.0, "size": Vector3(0.8, 0.8, 1.3),
		"color": Color(0.85, 0.45, 0.12), "stats": {}},
	# A Console's screen and its computer mods: each instrument adds its own
	# readings to the screen (Console), and draws a little while it runs. The
	# radar sweeps the field this far out, m.
	&"screen": {"kind": &"screen", "label": "Screen", "mass": 3.0, "size": Vector3(0.62, 1.12, 0.03),
		"color": Color(0.04, 0.05, 0.05), "stats": {"screen": 1, "draw_w": 3.0}},
	&"anemometer": {"kind": &"computer_mod", "label": "Anemometer", "mass": 0.7, "size": Vector3(0.16, 0.14, 0.16),
		"color": Color(0.26, 0.28, 0.29), "stats": {"anemometer": 1, "draw_w": 0.5}},
	&"barometer": {"kind": &"computer_mod", "label": "Barometer", "mass": 0.6, "size": Vector3(0.16, 0.16, 0.06),
		"color": Color(0.8, 0.76, 0.66), "stats": {"barometer": 1, "draw_w": 0.2}},
	&"hygrometer": {"kind": &"computer_mod", "label": "Hygrometer", "mass": 0.5, "size": Vector3(0.14, 0.16, 0.08),
		"color": Color(0.18, 0.4, 0.43), "stats": {"hygrometer": 1, "draw_w": 0.3}},
	&"particle_sensor": {"kind": &"computer_mod", "label": "Particle sensor", "mass": 0.7, "size": Vector3(0.16, 0.12, 0.14),
		"color": Color(0.86, 0.62, 0.12), "stats": {"particle_sensor": 1, "draw_w": 1.5}},
	# Reads what lies under the sand this far round its Console, m, and gives
	# it a page of its own.
	&"ground_radar": {"kind": &"computer_mod", "label": "Ground radar", "mass": 1.4, "size": Vector3(0.18, 0.16, 0.16),
		"color": Color(0.8, 0.76, 0.66), "stats": {"ground_radar": 1, "ground_radar_m": 300.0, "draw_w": 4.0}},
	# Scrapping: a scoop to clear the sand storms packed into a wreck, a
	# canister of sealant for a breached store, what a cut plate drops as, and
	# a med kit for what a breached store leaves you with. "tool" is the work
	# one does on a wreck in your hands (Wreck).
	&"sand_scoop": {"kind": &"tool", "label": "Sand scoop", "mass": 1.5, "size": Vector3(0.3, 0.08, 0.6),
		"color": Color(0.6, 0.58, 0.5), "stats": {}, "tool": &"clear"},
	&"sealant": {"kind": &"tool", "label": "Sealant canister", "mass": 0.8, "size": Vector3(0.1, 0.1, 0.22),
		"color": Color(0.86, 0.62, 0.12), "stats": {}, "tool": &"seal"},
	# Sifts what a scoop digs off a ruin, carried or set down near the dig
	# (Hands): nothing takes it, and it sticks on a deck.
	&"sieve": {"kind": &"sieve", "label": "Sieve", "mass": 1.2, "size": Vector3(0.5, 0.5, 0.09),
		"color": Color(0.45, 0.39, 0.3), "stats": {}},
	&"hull_plate": {"kind": &"scrap", "label": "Hull plate", "mass": 6.0, "size": Vector3(0.6, 0.6, 0.04),
		"color": Color(0.4, 0.36, 0.3), "stats": {}},
	&"med_kit": {"kind": &"medicine", "label": "Med kit", "mass": 0.5, "size": Vector3(0.18, 0.12, 0.07),
		"color": Color(0.8, 0.76, 0.66), "stats": {}},
	# A colonial FM converter, as AM car radios once took: it hears the FM band
	# on its own whip and hands it to the set as a carrier the set already
	# tunes, so the radio reaches FM, still as narrow as AM sounds.
	&"fm_converter": {"kind": &"radio_mod", "label": "FM converter", "mass": 0.6, "size": Vector3(0.12, 0.095, 0.06),
		"color": Color(0.22, 0.23, 0.22), "stats": {"fm": 1, "draw_w": 0.5}},
	# Its shortwave sibling, as car radios once took too: the band from 2 to 30
	# MHz handed to the set the same way, wire terminals on its top for a long
	# antenna in place of a whip.
	&"sw_converter": {"kind": &"radio_mod", "label": "Shortwave converter", "mass": 0.6,
		"size": Vector3(0.12, 0.095, 0.06), "color": Color(0.24, 0.22, 0.2), "stats": {"sw": 1, "draw_w": 0.5}},
	&"radar": {"kind": &"computer_top", "label": "Weather radar", "mass": 2.5, "size": Vector3(0.32, 0.32, 0.26),
		"color": Color(0.8, 0.76, 0.66), "stats": {"radar": 1, "radar_m": 6000.0, "draw_w": 6.0}},
}

## Parts by the names older saves knew them by.
const RENAMED := {&"carrot": &"root_tuber", &"fungus": &"vat_fungus", &"carrots": &"tubers"}
## Part kinds that go only in a slot of their own, never stuck loose on a
## chassis: hooks on rings, plugs in ports, a line's end, a hose's end, crops
## in beds, mods in their mounts, a sail on its mast.
const SLOT_ONLY: Array[StringName] = [&"ring", &"port", &"tie", &"plant_pot", &"plant_standard", &"plant_deep",
	&"mod", &"computer_mod", &"computer_top", &"screen", &"sail", &"face", &"radio_mod"]

## The colonial entity mark on each thing (art direction): TILG is the
## consignor; RMC is a legacy contractor placeholder, not mapped one-to-one
## to Moonco or its specialists; only shield and wind marks stand for OEMs.
## Commodity parts carry none.
const COLONIAL_MARKS := {&"chassis": &"tilg", &"frame": &"tilg", &"board": &"tilg", &"condenser": &"rmc", &"console": &"rmc",
	&"shield": &"rmc", &"light_shield": &"shield_maker", &"turbine": &"wind_maker", &"power_cabinet": &"rmc"}
## Where a lineage's marks sit on what isn't a box: round about its top's
## axis, as [its radius over its half width, and the shares of its height its
## round body spans].
const ROUND := {&"shield": [0.88, 0.22, 0.8], &"light_shield": [0.88, 0.22, 0.8], &"canister": [0.92, 0.0, 0.82],
	&"lamp": [0.92, 0.68, 0.96], &"barometer": [0.95, 0.0, 0.66]}
## Made things too small or too busy to carry a lineage's marks, though they
## keep its numbers: the ends of lines, a coil, the dish, the screen's glass,
## a compass's card.
const BARE: Array[StringName] = [&"hook", &"plug", &"strong_plug", &"hose_end", &"rope_end", &"coil", &"radar",
	&"screen", &"compass", &"frame", &"fabric", &"flare"]
## The stake's frame, which has no entry of its own.
const STAKE := {"mass": 2.0, "stats": {"toughness": INF}}
## What things with no entry of their own are called.
const NAMES := {&"stake": "Stake", &"line": "Line", &"cable": "Cable", &"strong_cable": "Strong cable",
	&"hose": "Hose"}

## Every board's: its battery at its nose, its port at its tail.
const BOARD_SOCKETS := [
	[&"battery", Vector3(0.0, 0.04, -0.5), Vector3.UP],
	[&"port", Vector3(0.0, 0.0, 0.65), Vector3.BACK],
]
## A power box's bays, by make: [kind, position, outward, what it is]: a bay
## found holds the cells it was built for, a dead one nothing, and a bay may
## sit turned about its way out, degrees, and its strip elsewhere than its
## make's (PowerBox).
const _BAY := {"fills": &"bay"}
const _CABINET_BAYS := [
	[&"battery", Vector3(0.21, 0.3275, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(-0.15, 0.3275, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(0.21, 0.0875, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(-0.15, 0.0875, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(0.21, -0.1525, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(-0.15, -0.1525, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(0.21, -0.3925, -0.165), Vector3.FORWARD, _BAY],
	[&"battery", Vector3(-0.15, -0.3925, -0.165), Vector3.FORWARD, _BAY],
]
const _DOCK_BAYS := [
	[&"battery", Vector3(0.155, 0.01, -0.11), Vector3.UP, _BAY],
	[&"battery", Vector3(-0.155, 0.01, -0.11), Vector3.UP, _BAY],
	[&"battery", Vector3(0.155, 0.01, 0.13), Vector3.UP, _BAY],
	[&"battery", Vector3(-0.155, 0.01, 0.13), Vector3.UP, _BAY],
]
## Bolted in where they'd go, none quite square; three burnt out.
const _RACK_BAYS := [
	[&"battery", Vector3(0.305, 0.392, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": 2.0}],
	[&"battery", Vector3(-0.006, 0.384, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": -1.5}],
	[&"battery", Vector3(-0.298, 0.396, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": 3.0}],
	[&"dead_bay", Vector3(0.296, 0.136, -0.13), Vector3.FORWARD, {"turn": -3.5}],
	[&"battery", Vector3(0.008, 0.142, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": 1.0}],
	[&"battery", Vector3(-0.31, 0.131, -0.13), Vector3.FORWARD, {"fills": &"bay"}],
	[&"battery", Vector3(0.302, -0.112, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": -2.0}],
	[&"dead_bay", Vector3(-0.004, -0.104, -0.13), Vector3.FORWARD, {"turn": 4.0}],
	[&"battery", Vector3(-0.296, -0.116, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": -1.0}],
	[&"battery", Vector3(0.31, -0.362, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": 1.5}],
	[&"dead_bay", Vector3(0.002, -0.37, -0.13), Vector3.FORWARD, {"turn": -2.5}],
	[&"battery", Vector3(-0.302, -0.357, -0.13), Vector3.FORWARD, {"fills": &"bay", "turn": 2.5}],
]
## Two niches low and one high, off true, each with its tube beside it.
const _SHRINE_BAYS := [
	[&"battery", Vector3(0.18, -0.24, -0.14), Vector3.FORWARD, {"fills": &"bay", "strip": Vector2(-0.172, 0.0)}],
	[&"battery", Vector3(-0.18, -0.24, -0.14), Vector3.FORWARD, {"fills": &"bay", "strip": Vector2(0.172, 0.0)}],
	[&"battery", Vector3(0.04, 0.07, -0.14), Vector3.FORWARD, _BAY],
]
## Frames: their box, weight, wind catch and sockets as [kind, position,
## outward], a bay with what it is too.
## "sticks" goes on a chassis's sticky face; "stands" only upright on one
## facing up; "tall" too tall to stand under a frame. A "short" name is what
## a Console's screen calls it, where its label is too long. A chassis's
## "spots" are where a find of one has things stuck: [face, place on it,
## turn in degrees, the fills it draws from].
const DEVICES := {
	# Its own water tank, fed from its water socket, and a mod mount on its
	# back for a harvester; it floats on its own tray and stands as it always
	# has, beside a camp rather than on one.
	&"planter": {"label": "Planter", "size": Vector3(1.0, 0.35, 0.6), "mass": 10.0, "planter": true,
		"sockets": [
			[&"plant_standard", Vector3(-0.3, 0.175, -0.12), Vector3.UP],
			[&"plant_standard", Vector3(-0.3, 0.175, 0.12), Vector3.UP],
			[&"plant_standard", Vector3(0.0, 0.175, 0.0), Vector3.UP],
			[&"plant_pot", Vector3(0.3, 0.175, 0.0), Vector3.UP],
			[&"battery", Vector3(-0.5, 0.0, 0.0), Vector3.LEFT],
			[&"ring", Vector3(0.0, 0.0, 0.3), Vector3.BACK],
			[&"ring", Vector3(0.0, 0.0, -0.3), Vector3.FORWARD],
			[&"bottom", Vector3(0.0, -0.175, 0.0), Vector3.DOWN],
			[&"port", Vector3(0.5, 0.0, 0.0), Vector3.RIGHT],
			[&"mod", Vector3(0.3, 0.0, 0.3), Vector3.BACK],
			[&"water", Vector3(-0.3, 0.0, 0.3), Vector3.BACK],
		]},
	# Strongest in a storm, and only while planted on the sand; built to stand
	# out in one, so the weather wears it four times slower.
	&"turbine": {"label": "Wind turbine", "size": Vector3(0.5, 0.3, 0.5), "mass": 18.0,
		"stats": {"turbine_w": 200.0, "toughness": 4.0}, "mast": 1.6,
		"sockets": [
			[&"battery", Vector3(0.0, 0.0, 0.25), Vector3.BACK],
			[&"port", Vector3(0.25, 0.0, 0.0), Vector3.RIGHT],
		]},
	# Pulls water out of the air into the canister in its tap, best in the
	# cold of the night, on its deck's power.
	&"condenser": {"label": "Condenser", "size": Vector3(0.6, 0.7, 0.6), "mass": 14.0, "condenser": true,
		"sticks": true, "stands": true, "tall": true,
		"sockets": [
			[&"water", Vector3(0.0, -0.1, 0.3), Vector3.BACK],
			[&"port", Vector3(-0.3, 0.1, 0.0), Vector3.LEFT],
		]},
	# The base shield: small and light, use switches it, and its bubble keeps
	# out wind and storm wherever it goes, on its deck's power.
	&"shield": {"label": "Shield generator", "short": "Shield",
		"size": Vector3(0.4, 0.42, 0.4), "mass": 6.0, "shield": true, "sticks": true, "stands": true,
		"sockets": [
			[&"port", Vector3(0.2, -0.05, 0.0), Vector3.RIGHT],
		]},
	# The light shield you start with: a smaller bubble that lets a little of
	# the wind through, built light enough that the light panel keeps it going.
	&"light_shield": {"label": "Light shield generator", "short": "Light shield",
		"size": Vector3(0.3, 0.32, 0.3), "mass": 4.0, "shield": true, "sticks": true, "stands": true,
		"stats": {"radius_m": 4.0, "clear_w": 2.0, "storm_w": 20.0, "wind_block": 0.85},
		"sockets": [
			[&"port", Vector3(0.15, -0.04, 0.0), Vector3.RIGHT],
		]},
	# The Varran settler's: a small bubble round one person, cheap and
	# hungry, on a battery of its own so it runs carried, in your hands or
	# your suit. Stuck on a deck, it joins the pool too.
	&"personal_shield": {"label": "Personal shield generator", "short": "Personal shield",
		"size": Vector3(0.3, 0.18, 0.3), "mass": 3.0, "shield": true, "carryable": true, "sticks": true, "stands": true,
		"stats": {"radius_m": 2.5, "clear_w": 3.0, "storm_w": 50.0, "wind_block": 0.85},
		"sockets": [
			[&"battery", Vector3(0.0, -0.03, 0.15), Vector3.BACK],
			[&"port", Vector3(0.15, -0.04, 0.0), Vector3.RIGHT],
		]},
	# The light solar panel you start with, half a found panel's watts on half
	# a piece, so it lies beside a shield: stick it, set it down, cable it in,
	# pick it up again. Lying flat, the wind meets its edge.
	&"light_panel": {"label": "Light solar panel", "short": "Light panel",
		"size": Vector3(0.8, 0.05, 0.4), "mass": 5.0, "carryable": true, "sticks": true,
		"stats": {"solar_w": 30.0, "face_m2": 0.04},
		"sockets": [
			[&"port", Vector3(0.4, 0.0, 0.0), Vector3.RIGHT],
		]},
	# A heat cutter: held, it cuts a wreck's plates away while use is held
	# down, on its own battery (Cutter).
	&"cutter": {"label": "Heat cutter", "size": Vector3(0.12, 0.16, 0.55), "mass": 3.0, "cutter": true,
		"carryable": true, "sticks": true,
		"sockets": [
			[&"battery", Vector3(0.0, 0.08, -0.1), Vector3.UP],
		]},
	# Music, the weather station and beacons, a channel a use. Carried, set
	# down or stuck on a deck, it runs on its battery or its deck's power.
	&"survey_receiver": {"label": "Survey receiver", "size": Vector3(0.36, 0.50, 0.26), "mass": 1.4,
		"radio": true, "receiver": true, "carryable": true, "sticks": true,
		"sockets": [[&"battery", Vector3(0.0, -0.12, -0.10), Vector3.FORWARD]]},
	&"radio": {"label": "Radio", "size": Vector3(0.32, 0.22, 0.16), "mass": 2.5, "radio": true,
		"carryable": true, "sticks": true,
		"sockets": [
			[&"battery", Vector3(0.0, -0.02, -0.08), Vector3.FORWARD],
			[&"port", Vector3(0.16, -0.035, -0.01), Vector3.RIGHT],
			# Its left side takes two bands' front ends, one over the other: the
			# FM converter and the shortwave converter.
			[&"radio_mod", Vector3(-0.16, 0.052, -0.01), Vector3.LEFT],
			[&"radio_mod", Vector3(-0.16, -0.052, -0.01), Vector3.LEFT],
		]},
	# A reel of aerial wire, clipped to a radio and walked out (AntennaReel).
	&"antenna_reel": {"label": "Antenna reel", "size": Vector3(0.14, 0.12, 0.08), "mass": 0.8, "antenna_reel": true,
		"carryable": true, "sticks": true, "sockets": []},
	# A sealed case of what keeps you going: a canister, a ration and seeds.
	&"survival_kit": {"label": "Survival kit", "size": Vector3(0.5, 0.25, 0.35), "mass": 3.0, "carryable": true,
		"sticks": true,
		"sockets": [
			[&"water", Vector3(-0.13, 0.0, 0.175), Vector3.BACK],
			[&"food", Vector3(0.13, 0.0, 0.175), Vector3.BACK],
			[&"plant_standard", Vector3(-0.15, 0.125, 0.0), Vector3.UP],
			[&"plant_standard", Vector3(0.0, 0.125, 0.0), Vector3.UP],
			[&"plant_pot", Vector3(0.15, 0.125, 0.0), Vector3.UP],
		]},
	# Just for you: it runs on its own battery, at its nose, and nothing ties
	# to it, so it tows nothing. Its port charges it from a cable, and a deck
	# it's stuck on charges it from its pool. Found buried on end, nose down.
	# Lying flat, the wind meets its edge.
	&"board": {"label": "Hoverboard", "size": Vector3(0.36, 0.08, 1.3), "mass": 7.0, "board": true, "on_end": true,
		"carryable": true, "sticks": true, "stats": {"face_m2": 0.1}, "sockets": BOARD_SOCKETS},
	# Boards by make (BoardMakes): one box, so any make sticks on a deck as the
	# issue does, hung on an upright; each its own weight, look and ride.
	&"racer_board": {"label": "Skimmer racer", "size": Vector3(0.36, 0.08, 1.3), "mass": 5.5, "board": true,
		"on_end": true, "carryable": true, "sticks": true, "stats": {"face_m2": 0.09}, "sockets": BOARD_SOCKETS},
	&"patrol_board": {"label": "Patrol board", "size": Vector3(0.36, 0.08, 1.3), "mass": 11.0, "board": true,
		"on_end": true, "carryable": true, "sticks": true, "stats": {"face_m2": 0.11}, "sockets": BOARD_SOCKETS},
	&"temple_board": {"label": "Temple board", "size": Vector3(0.36, 0.08, 1.3), "mass": 9.0, "board": true,
		"on_end": true, "carryable": true, "sticks": true, "stats": {"face_m2": 0.12}, "sockets": BOARD_SOCKETS},
	# Something to sleep on (Sleep): laid on the sand, carried, or stuck on a
	# deck. Round and low, it lets most of a breeze over it: a storm slides
	# it, a breeze doesn't.
	&"bedroll": {"label": "Bedroll", "size": Vector3(0.24, 0.24, 0.9), "mass": 3.0, "bedroll": true,
		"carryable": true, "sticks": true, "stats": {"face_m2": 0.13}, "sockets": []},
	# A sail's mount: a pole that stands on a deck, stowed short to carry and
	# standing its full height once stuck, its sail fitting low on it at the
	# boom's root. Found buried on end.
	&"mast": {"label": "Mast", "size": Vector3(0.14, 1.3, 0.14), "mass": 8.0, "rig": true,
		"carryable": true, "on_end": true, "sticks": true, "stands": true, "stats": {"face_m2": 0.18},
		"sockets": [
			[&"sail", Mast.BOOM_AT + Vector3(0.0, 0.0, -0.07), Vector3.FORWARD],
		]},
	# A skimmer pilot's seat, stuck on a deck: use on it sits you at the helm (Helm).
	&"helm_seat": {"label": "Helm seat", "short": "Helm", "size": Vector3(0.5, 0.5, 0.55), "mass": 7.0, "helm": true,
		"carryable": true, "sticks": true, "stands": true, "sockets": []},
	# The nomads': a wind streamer, a strip of cloth on a wand that streams
	# downwind of the air it feels (Streamer). Read in your hand or your suit,
	# or stuck anywhere on a rig, a mast too, as a telltale.
	&"streamer": {"label": "Wind streamer", "short": "Streamer", "size": Vector3(0.04, 0.36, 0.04), "mass": 0.2,
		"streamer": true, "carryable": true, "sticks": true, "stats": {"face_m2": 0.01}, "sockets": []},
	&"sailing_notes": {"label": "Sailing field notes", "short": "Sailing notes", "size": Vector3(0.28, 0.05, 0.36),
		"mass": 0.3, "notes": true, "carryable": true, "sticks": true, "sockets": []},
	&"surveyor_guide": {"label": "Surveyor's Guide", "short": "Survey guide", "size": Vector3(0.28, 0.05, 0.36),
		"mass": 0.3, "notes": true, "surveyor_guide": true, "carryable": true, "sticks": true, "sockets": []},
	# A lookout's basket for a mast's head, its rope ladder hung down the mast:
	# use on it climbs you in, a seat as the helm is (CrowsNest).
	&"crows_nest": {"label": "Crow's nest", "short": "Nest", "size": Vector3(0.9, 1.0, 0.9), "mass": 12.0, "nest": true,
		"helm": true, "carryable": true, "sticks": true, "stands": true, "stats": {"face_m2": 0.5}, "sockets": []},
	# The one structure: a flat square a little wider than a crate was, its
	# whole top and bottom sticky, a ring on each edge where the next piece
	# joins or a hook goes. No battery, no port: the power comes from what's
	# stuck on it. Lying flat, the wind meets its edge. Found buried on edge,
	# as the dunes would leave a sheet that wide.
	&"chassis": {"label": "Chassis piece", "short": "Deck",
		"size": Vector3(Chassis.WIDTH, Chassis.THICK, Chassis.WIDTH), "mass": 9.0, "chassis": true,
		"carryable": true, "on_end": true, "stats": {"face_m2": 0.12},
		"sockets": [
			[&"ring", Vector3(0.5, 0.0, 0.0), Vector3.RIGHT],
			[&"ring", Vector3(-0.5, 0.0, 0.0), Vector3.LEFT],
			[&"ring", Vector3(0.0, 0.0, 0.5), Vector3.BACK],
			[&"ring", Vector3(0.0, 0.0, -0.5), Vector3.FORWARD],
		],
		"spots": [[&"bottom", Vector2.ZERO, 0.0, &"bottom"], [&"top", Vector2(-0.22, -0.24), 0.0, &"battery"],
			[&"top", Vector2(0.16, 0.22), 0.0, &"top"]]},
	# The camp's computer, a rack standing tall and narrow so its whole front
	# is a big screen, as tall as the radar page wants and its middle at your
	# eyes on a floating deck. Its frame is heaviest at its foot, so it stands
	# steady. Its ports are its own: the screen the whole front, each side
	# three computer-mod ports down it, a computer-mod top for a radar, and a
	# power port at its back. It runs on its deck's power.
	&"console": {"label": "Console", "size": Vector3(0.7, 1.3, 0.6), "mass": 10.0, "middle": Vector3(0.0, -0.45, 0.0),
		"console": true, "sticks": true, "stands": true, "tall": true, "stats": {"draw_w": 4.0},
		"sockets": [
			[&"computer_top", Vector3(0.0, 0.65, -0.14), Vector3.UP],
			[&"screen", Vector3(0.0, 0.01, -0.3), Vector3.FORWARD],
			[&"port", Vector3(0.0, -0.24, 0.3), Vector3.BACK],
			[&"computer_mod", Vector3(0.35, 0.36, 0.0), Vector3.RIGHT],
			[&"computer_mod", Vector3(0.35, 0.12, 0.0), Vector3.RIGHT],
			[&"computer_mod", Vector3(0.35, -0.12, 0.0), Vector3.RIGHT],
			[&"computer_mod", Vector3(-0.35, 0.36, 0.0), Vector3.LEFT],
			[&"computer_mod", Vector3(-0.35, 0.12, 0.0), Vector3.LEFT],
			[&"computer_mod", Vector3(-0.35, -0.12, 0.0), Vector3.LEFT],
		]},
	# The Varran settler's navigation computer: a Console of the empire's make,
	# a rack the Console's size in an armoured case, three times its weight,
	# its weather instruments built in and its radar reaching half again as
	# far. Its screen port and its power port are the Console's; two
	# computer-mod ports take more.
	&"nav_computer": {"label": "Navigation computer", "short": "Nav computer", "size": Vector3(0.7, 1.3, 0.6),
		"mass": 30.0, "middle": Vector3(0.0, -0.45, 0.0), "console": true, "sticks": true, "stands": true, "tall": true,
		"stats": {"draw_w": 14.0, "anemometer": 1, "barometer": 1, "hygrometer": 1, "particle_sensor": 1, "radar": 1,
			"radar_m": 9000.0},
		"sockets": [
			[&"screen", Vector3(0.0, 0.01, -0.3), Vector3.FORWARD],
			[&"port", Vector3(0.0, -0.24, 0.3), Vector3.BACK],
			[&"computer_mod", Vector3(0.35, 0.36, 0.0), Vector3.RIGHT],
			[&"computer_mod", Vector3(-0.35, 0.36, 0.0), Vector3.LEFT],
		]},
	# Power boxes: battery bays sticking on a deck, joining its pool, each make
	# on its own terms (PowerBox). The colony's cabinet, rare and heavy: eight
	# precise bays in two columns, its bank read out across its head.
	&"power_cabinet": {"label": "Power cabinet", "short": "Cabinet", "size": Vector3(0.8, 1.2, 0.45), "mass": 30.0,
		"middle": Vector3(0.0, -0.2, 0.0), "power_box": true, "sticks": true, "stands": true, "tall": true,
		"sockets": _CABINET_BAYS + [[&"port", Vector3(0.0, -0.42, 0.225), Vector3.BACK]]},
	# The company's issue: a light dock of four bays on its face, sticking
	# anywhere, a wall too, built to a budget.
	&"power_box": {"label": "Power box", "short": "Power box", "size": Vector3(0.62, 0.12, 0.5), "mass": 6.0,
		"power_box": true, "carryable": true, "sticks": true,
		"sockets": _DOCK_BAYS + [[&"port", Vector3(0.31, -0.01, 0.0), Vector3.RIGHT]]},
	# A skimmer crew's bodged rack: a dozen mismatched bays, three dead,
	# shared pool only.
	&"power_rack": {"label": "Battery rack", "short": "Rack", "size": Vector3(0.96, 1.06, 0.36), "mass": 16.0,
		"power_box": true, "sticks": true, "stands": true, "tall": true,
		"sockets": _RACK_BAYS + [[&"port", Vector3(0.3, -0.35, 0.18), Vector3.BACK]]},
	# Temple-made round an old bus: three niches in an ornate casing.
	&"power_shrine": {"label": "Power shrine", "short": "Shrine", "size": Vector3(0.8, 0.9, 0.38), "mass": 16.0,
		"power_box": true, "sticks": true, "stands": true,
		"sockets": _SHRINE_BAYS + [[&"port", Vector3(-0.2, -0.36, 0.19), Vector3.BACK]]},
}


## What a thing is called where there's little room, by its id: a device's
## short name, else its label.
static func short_label(id: StringName) -> String:
	if DEVICES.has(id):
		return DEVICES[id].get("short", DEVICES[id].label)
	if PARTS.has(id):
		return PARTS[id].label
	return NAMES.get(id, str(id))


static func part(id: StringName) -> Part:
	var spec: Dictionary = PARTS[id]
	# A hose's end fits where water goes but holds none itself.
	var made: Part = Battery.new() if spec.kind == &"battery" \
		else (Supply.new() if Supply.HOLDS.has(spec.kind) and id != Hose.END \
		else (Plant.new() if spec.has("crop") \
		else (Compass.new() if spec.kind == &"compass" \
		else (Frame.new() if spec.kind == &"frame" \
		else (Remedy.new() if spec.kind == &"medicine" else (RopeHook.new() if id == &"hook" \
		else (RopeTip.new() if id == &"rope_end" else (Flare.new() if spec.kind == &"flare" else Part.new()))))))))
	made.kind = spec.kind
	made.label = spec.label
	made.mass = spec.mass
	# What a save knows it by.
	made.set_meta(&"catalog", id)
	made.stats = spec.stats.duplicate()
	var size: Vector3 = spec.size
	var look: MeshInstance3D = null
	if made is Frame:
		Frame.build(made, Dress.part(id, size))
	else:
		# Standing out from its socket along +Z.
		look = _add_box(made, size, Vector3(0.0, 0.0, size.z * 0.5), spec.color, Dress.part(id, size))
	if spec.kind == &"face":
		made.add_child(Faces.cloth(size))
	Paint.show_age(made, Paint.age_of(&"", 1.0))
	if made is Battery:
		# Found full, for now; salvage will find them at any charge.
		made.charge_wh = made.capacity()
		made.light = ChargeLight.make(Vector3(size.x * 0.7, 0.02, 0.01))
		made.light.position = Vector3(0.0, size.y * 0.3, size.z + 0.005)
		made.add_child(made.light)
		made.show_charge()
	if made is Supply:
		if spec.has("pieces"):
			made.pieces = spec.pieces
			made.look = look
		else:
			made.light = ChargeLight.make(Vector3(size.x * 0.7, 0.02, 0.01))
			made.light.position = Vector3(0.0, size.y * 0.5 + 0.005, size.z * 0.6)
			made.add_child(made.light)
		# A harvest's output holds one unit of it, alone.
		made.seal(spec.get("each", NAN))
	if made is Plant:
		(made as Plant).sow(id)
	if made is Compass:
		var needle := MeshInstance3D.new()
		needle.mesh = Dress.needle()
		needle.transform = Compass.pose(0.0)
		# Luminous, so it reads in the dark.
		needle.set_instance_shader_parameter(&"lit", 1.0)
		made.add_child(needle)
		made.needle = needle
	if spec.kind == &"tie":
		# A line's end is small and gets dragged over the dunes at the wind's
		# speed: swept, so it can't step through the sand in a tick.
		made.continuous_cd = true
	if spec.has("tie"):
		_add_tie(made, spec.tie, Vector3.BACK)
		if made is RopeHook:
			made.guide = RopeEnd.make(made, spec.tie, false)
	if spec.has("adds"):
		var adds := Socket.new()
		adds.kind = spec.adds[0]
		adds.transform = Transform3D(_facing(spec.adds[2]), spec.adds[1])
		made.add_child(adds)
	if spec.kind == &"coil":
		# It lies flat, so the wind meets its edge, not its face.
		made.set_meta(&"wind_catch", Tuning.current().wind_catch_per_m2 * size.x * size.z)
	if made.stats.get("light_w", 0.0) > 0.0:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.85, 0.6)
		lamp.omni_range = 7.0
		lamp.position = Vector3(0.0, 0.0, size.z + 0.1)
		# Dark until a powered device runs it.
		lamp.visible = false
		made.add_child(lamp)
	return made


## Food holding this many kcal: a harvest, picked or dropped onto you.
static func food(id: StringName, kcal: float) -> Supply:
	var made := part(id) as Supply
	made.seal(kcal)
	return made


## Units of a harvest's output: food as one, holding them all, and anything
## else one a unit.
static func output(id: StringName, units: int) -> Array[Part]:
	var spec: Dictionary = PARTS[id]
	if Supply.HOLDS.has(spec.kind):
		return [food(id, units * spec.each)]
	var made: Array[Part] = []
	for i in units:
		made.append(part(id))
	return made


## What a save made before a part was renamed calls it by now.
static func current(id: StringName) -> StringName:
	return RENAMED.get(id, id)


## A cable and its two plugs, dropped together at a place; both plugs go loose
## in the world as parts and the cable draws the wire between them. A strong
## cable is also a rope, holding what it's plugged into. Given its first plug,
## a found one, it makes only the second, beside it.
static func cable(world: World, at: Vector3, strong := false, first: Part = null) -> Cable:
	var made: Cable = StrongCable.new() if strong else Cable.new()
	_lay(world, made, at, &"strong_plug" if strong else &"plug", first)
	if strong:
		(made as StrongCable).bind(world)
	return made


## A hose and its two ends, dropped together as a cable is, a rope like a
## strong cable.
static func hose(world: World, at: Vector3, first: Part = null) -> Hose:
	var made := Hose.new()
	_lay(world, made, at, Hose.END, first)
	made.bind(world)
	return made


static func _lay(world: World, made: Cable, at: Vector3, end: StringName, first: Part) -> void:
	world.content.add_child(made)
	for side in [-0.2, 0.2]:
		var plug := first if first != null and made.plugs.is_empty() else part(end)
		if plug.get_parent() == null:
			world.content.add_child(plug)
			plug.global_position = at + Vector3(side, 0.05, 0.0)
			if first != null:
				plug.global_position.y = world.height_under(plug.global_position) + 0.05
		made.plugs.append(plug)


## A stake, loose: a spike with an eye on top whose tie socket faces up, so a
## line's end snaps on from wherever you stand.
static func stake() -> Stake:
	var made := Stake.new()
	made.set_meta(&"catalog", &"stake")
	made.label = NAMES[&"stake"]
	made.frame_mass = STAKE.mass
	made.carryable = true
	# A spike of iron: nothing in it the weather wears out.
	made.frame_stats = STAKE.stats.duplicate()
	made.holding = Tuning.current().stake_holding
	var spike := Vector3(0.06, Stake.LENGTH, 0.06)
	made.frame_view = _add_box(made, spike, Vector3.ZERO, Color(0.3, 0.27, 0.24), Dress.frame(&"stake", spike))
	_add_tie(made, Stake.RING, Vector3.UP)
	made.ring = RopeEnd.make(made, Stake.RING, false)
	made.show_wear()
	return made


## A tie socket facing `outward`, with the ring you see there.
static func _add_tie(body: Node3D, at: Vector3, outward: Vector3) -> void:
	var tie := Socket.new()
	tie.kind = &"tie"
	tie.transform = Transform3D(_facing(outward), at)
	body.add_child(tie)
	var ring := RopeEnd.ring_mesh()
	# Stood across its socket, so a line's end reads as clipped through it.
	ring.transform = Transform3D(_facing(outward) * Basis(Vector3.UP, PI / 2.0), at)
	body.add_child(ring)


static func device(id: StringName) -> Device:
	var spec: Dictionary = DEVICES[id]
	var made: Device = ShieldGenerator.new() if spec.get("shield", false) \
		else (Condenser.new() if spec.get("condenser", false) \
		else (Planter.new() if spec.get("planter", false) \
		else (Hoverboard.new() if spec.get("board", false) \
		else ((SurveyReceiver.new() if spec.get("receiver", false) else Radio.new()) if spec.get("radio", false) \
		else (Mast.new() if spec.get("rig", false) \
		else (Streamer.new() if spec.get("streamer", false) \
		else (CrowsNest.new() if spec.get("nest", false) \
		else (Helm.new() if spec.get("helm", false) \
		else (Chassis.new() if spec.get("chassis", false) \
		else (Bedroll.new() if spec.get("bedroll", false) \
		else (Console.new() if spec.get("console", false) \
		else (PowerBox.new() if spec.get("power_box", false) \
		else (Cutter.new() if spec.get("cutter", false) \
		else (AntennaReel.new() if spec.get("antenna_reel", false) \
		else ((SurveyorGuide.new() if spec.get("surveyor_guide", false) else SailingNotes.new()) if spec.get("notes", false) else Device.new())))))))))))))))
	made.set_meta(&"catalog", id)
	made.label = spec.label
	made.frame_mass = spec.mass
	made.frame_middle = spec.get("middle", Vector3.ZERO)
	made.frame_stats = spec.get("stats", {}).duplicate()
	made.sticks = spec.get("sticks", false)
	made.stands = spec.get("stands", false)
	made.tall = spec.get("tall", false)
	if spec.get("carryable", false):
		made.carryable = true
	var size: Vector3 = spec.size
	made.frame_view = _add_box(made, size, Vector3.ZERO, Color(0.55, 0.55, 0.55), Dress.frame(id, size, spec.get("mast", 0.0)))
	if spec.has("mast"):
		made.rotor = Rotor.new()
		made.rotor.mesh = Dress.rotor(id)
		made.rotor.position = Vector3(0.0, size.y * 0.5 + spec.mast, 0.0)
		made.add_child(made.rotor)
	# A power box shows its charge bay by bay, on its strips.
	if spec.sockets.any(func(e: Array) -> bool: return e[0] == &"battery") and not spec.get("power_box", false):
		made.charge_light = ChargeLight.make(Vector3(0.05, 0.05, 0.05))
		# High on its right side, where nothing on its top mounts covers it.
		made.charge_light.position = Vector3(size.x * 0.5 + 0.025, size.y * 0.5 - 0.05, size.z * 0.5 - 0.05)
		made.add_child(made.charge_light)
	for entry: Array in spec.sockets:
		var socket := Socket.new()
		socket.kind = entry[0]
		socket.transform = PowerBox.bay_frame(entry)
		if entry.size() > 3:
			socket.set_meta(&"bay", entry[3])
		made.add_child(socket)
		if socket.kind == PowerBox.DEAD:
			continue
		var tell := MeshInstance3D.new()
		tell.mesh = Dress.tell(socket.kind)
		# Its tab glows a little, so a free socket reads at dusk.
		tell.set_instance_shader_parameter(&"lit", 1.0)
		socket.add_child(tell)
		socket.marker = tell
	made.show_wear()
	return made


## Whether a thing has a lineage: anything made, not grown or eaten.
static func lineal(id: StringName) -> bool:
	if DEVICES.has(id) or id == &"stake":
		return true
	var spec: Dictionary = PARTS.get(id, {})
	return not spec.is_empty() and not spec.has("crop") and not spec.kind in [&"food", &"salt"]


## The loot's one call (docs/world-system.md, "What lineage does now"): a
## find's lineage from the site it lay in, drawn from the loot draw's seed
## (Eras.lineage) and given it, with its colonial entity mark by catalog id.
## What it was given.
static func found_in(body: Node, era: StringName, kind: StringName, seed_value: int) -> Array:
	var line := Eras.lineage(era, kind, seed_value)
	var id: StringName = body.get_meta(&"catalog", &"")
	if not line.is_empty() and line[0][0] == Eras.COLONIAL and COLONIAL_MARKS.has(id):
		line[0][2] = [COLONIAL_MARKS[id]]
	inherit(body, line)
	return body.get_meta(&"lineage", [])


## Gives a thing its lineage, made fresh and before it's in the world: its
## numbers by its era's make (Eras.GEAR), its look by every hand it passed
## through. A thing without one is what it always was: the company's issue,
## or its layer's look for a find from before lineage.
static func inherit(body: Node, line: Array) -> void:
	var id: StringName = body.get_meta(&"catalog", &"")
	if line.is_empty() or not lineal(id):
		return
	body.set_meta(&"lineage", line)
	var gear: Dictionary = Eras.GEAR.get(Eras.era_of(line), Eras.GEAR[Eras.COLONIAL])
	var part := body as Part
	if part != null:
		var spec: Dictionary = PARTS[id]
		var cell := part as Battery
		var held := cell.charge_wh / cell.capacity() if cell != null and cell.capacity() > 0.0 else 0.0
		part.stats = _made_by(spec.stats, gear, false)
		part.mass = spec.mass * gear.mass
		if cell != null:
			cell.charge_wh = cell.capacity() * held
			cell.show_charge()
	var device := body as Device
	if device != null:
		var spec: Dictionary = DEVICES.get(id, STAKE)
		var own: Dictionary = spec.get("stats", {}).duplicate()
		# The base shield's draw is the tuning's: its make scales it as its own.
		if spec.get("shield", false):
			var tuning := Tuning.current()
			own["clear_w"] = own.get("clear_w", tuning.shield_clear_w)
			own["storm_w"] = own.get("storm_w", tuning.shield_storm_w)
		device.frame_stats = _made_by(own, gear, true)
		device.frame_mass = spec.mass * gear.mass
	var view := _look_of(body)
	var look := Dress.lineage(id, line)
	if view != null and look != null:
		view.mesh = look
	if device != null:
		device.show_wear()
		# Its frame's weight changed, which its middle is worked out from.
		device.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		device._recompute()
	elif part != null:
		var age := Paint.age_for(part, Paint.PART_SOUND)
		Paint.show_age(part, age)
		if view != null:
			view.set_instance_shader_parameter(&"age", age)
			view.set_instance_shader_parameter(&"era", Paint.row_for(part))
		if part.socket != null:
			(part.socket.get_parent() as Device)._recompute()


## A thing's numbers as its era made it: what it gives by what it keeps, what
## it draws by how much more, a frame's toughness, and a tray's draw a kilogram.
static func _made_by(stats: Dictionary, gear: Dictionary, frame: bool) -> Dictionary:
	var out := stats.duplicate()
	for key in Eras.KEEPS:
		if out.has(key):
			out[key] *= gear.keeps
	for key in Eras.DRAWS:
		if out.has(key):
			out[key] *= gear.draws
	if frame:
		out["toughness"] = out.get("toughness", 1.0) * gear.tough
	if out.has("lift_kg") and gear.draws != 1.0:
		out["hover_draw"] = gear.draws
	return out


## Its painted look: a frame's, or the first worn mesh of a part's, fitted or not.
static func _look_of(body: Node) -> MeshInstance3D:
	var device := body as Device
	if device != null:
		return device.frame_view
	var part := body as Part
	for node in (part.socket.fitted if part.socket != null else part.get_children()):
		if node is MeshInstance3D and Paint.is_worn(node):
			return node
	return null


## A basis whose +Z points along outward.
static func _facing(outward: Vector3) -> Basis:
	var up := Vector3.UP if absf(outward.dot(Vector3.UP)) < 0.9 else Vector3.BACK
	return Basis.looking_at(-outward, up)


## A shape's bounds in its own frame. Everything here is built of boxes,
## whose bounds are their size; anything else asks its debug mesh, which
## stalls the main thread on the render thread the first time, a whole frame.
static func bounds(shape: Shape3D) -> AABB:
	var box := shape as BoxShape3D
	if box != null:
		return AABB(-box.size * 0.5, box.size)
	return shape.get_debug_mesh().get_aabb()


## Its box, and what you see of it: its painted look, in the body's own
## frame, or a grey box where it has none yet.
static func _add_box(body: CollisionObject3D, size: Vector3, at: Vector3, color: Color, look: Mesh = null) -> MeshInstance3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	if look != null:
		mesh.mesh = look
	else:
		var cube := BoxMesh.new()
		cube.size = size
		var flat := StandardMaterial3D.new()
		flat.albedo_color = color
		cube.material = flat
		mesh.mesh = cube
		mesh.position = at
	body.add_child(mesh)
	return mesh
