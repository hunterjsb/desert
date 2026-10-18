class_name Eras
extends RefCounted
## The eras, in the order history runs them (part 5): colonial, collapse,
## skimmer era, First Kingdoms, Dark Age, second age, feral, then sand. Four
## leave sites. The collapses between them leave none, nor does the Dark Age:
## it is a rule on what later things are made of.

const COLONIAL := &"colonial"
const SKIMMER := &"skimmer"
const FIRST := &"first"
const DARK := &"dark"
const SECOND := &"second"
## The company's own issue now, what a run starts with: colonial make, new.
const NEW := &"new"
## The ground's own: older than every era, what geology leaves standing.
const GEOLOGY := &"geology"
const ORDER: Array[StringName] = [COLONIAL, &"collapse", SKIMMER, FIRST, DARK, SECOND, &"feral", &"sand"]
## The eras that left structures.
const BUILT: Array[StringName] = [COLONIAL, SKIMMER, FIRST, SECOND]
## As bits, for what a path was used in.
const BITS := {COLONIAL: 1, SKIMMER: 2, FIRST: 4, DARK: 8, SECOND: 16}
const NAMES := {COLONIAL: "colonial", SKIMMER: "skimmer era", FIRST: "First Kingdoms", DARK: "Dark Age",
	SECOND: "second age", NEW: "company issue", GEOLOGY: "the ground's own"}

## Sand over a site by its era, m, least and most (part 4's burial table):
## colonial deepest, the First Kingdoms' low foundations deep, skimmer wrecks
## shallow and tilted, the second age shallowest. Defaults.
const BURIAL := {COLONIAL: Vector2(2.0, 6.0), SKIMMER: Vector2(0.2, 1.0), FIRST: Vector2(0.8, 2.0),
	SECOND: Vector2(0.0, 0.6)}
## How far a buried site of the era leans, degrees.
const TILT := {SKIMMER: Vector2(10.0, 35.0)}

## What each era's sites are best for (part 4).
const LOOT := {COLONIAL: "infrastructure: power, crates, big systems",
	SKIMMER: "the best single-item gear, from deserters and the black site",
	FIRST: "intact working colonial tech used in new ways",
	DARK: "none of its own: the lineage of second-age gear",
	SECOND: "worn reused gear; water, seeds and salt"}

## Each era's make along part 5's one axis, efficiency against repairability,
## against colonial make: the share of its rated capacity, watts and lift it
## keeps, how much more it draws for the same work, how well it stands the
## weather, its weight, and what mends it. Nothing mends yet. The First
## Kingdoms kept colonial gear near its best and tougher; the skimmer era's is
## "the light cheap gear from before" (Hunter), light and fragile; the second
## age's is crude and lossy but mended from what grows. Defaults, but the order.
const GEAR := {
	COLONIAL: {"keeps": 1.0, "draws": 1.0, "tough": 1.0, "mass": 1.0, "mends": [&"colonial_parts"]},
	NEW: {"keeps": 1.0, "draws": 1.0, "tough": 1.0, "mass": 1.0, "mends": [&"colonial_parts"]},
	FIRST: {"keeps": 0.92, "draws": 1.05, "tough": 1.5, "mass": 1.0, "mends": [&"metal"]},
	SKIMMER: {"keeps": 0.85, "draws": 1.1, "tough": 0.5, "mass": 0.7, "mends": [&"scrap"]},
	SECOND: {"keeps": 0.75, "draws": 1.25, "tough": 0.9, "mass": 1.0, "mends": [&"cord", &"ceramic", &"saltbush_wood"]},
}
## The numbers each factor scales: what a thing gives, and what it draws.
const KEEPS: Array[String] = ["capacity_wh", "solar_w", "turbine_w", "lift_kg"]
const DRAWS: Array[String] = ["draw_w", "light_w", "clear_w", "storm_w"]

## Port Morgan's ruling families, whose heraldry First Kingdoms gear carries
## (part 5). Halloran's and the Rim's houses aren't named.
const HOUSES: Array[StringName] = [&"okafor", &"kessel", &"arkwright", &"vante"]
## How the Dark Age held a thing together, each a set of repair work: lashed
## with cord, a lost part rebuilt round in ceramic, a splint of saltbush wood,
## a plate off something else. Defaults.
const REMAKES := [[&"cord"], [&"cord", &"ceramic"], [&"plate", &"cord"], [&"wood", &"cord", &"ceramic"],
	[&"plate", &"ceramic"]]
## What the second age's devotion added: the sign of Tu, charms, tassels,
## water vials; the Cistern's blue glaze only where her water reached. Defaults.
const BLESSINGS := [[&"tu"], [&"tu", &"charm"], [&"vial", &"tassel"], [&"charm", &"tassel"]]
const CISTERN := [&"cistern", &"charm"]
## The shares of a lineage's draw by the kind of site it came from, over the
## default's: a remade thing kept a house's marks under its repair, was
## blessed, by the Cistern. Wayshrines bless, stepwells hold her water, and a
## Dark Age cache is from before devotion. Defaults.
const SHARES := {
	&"": {"marked": 0.5, "blessed": 0.4, "cistern": 0.05},
	&"wayshrine": {"blessed": 0.9},
	&"stepwell": {"blessed": 0.6, "cistern": 0.5},
}


## A thing's lineage, found at a site of this era and kind, from the loot
## draw's seed alone: [era, what was done, how] from its making on. Nothing
## after the colony was manufactured but the skimmer era's imports, so the
## rest started colonial: the First Kingdoms kept it and marked it with a
## house's heraldry; a second-age thing is a colonial or First Kingdoms one
## remade in the Dark Age, and maybe blessed after. A Dark Age cache holds
## the remade thing before any blessing. Who made it is the thing's own
## (Catalog.MAKERS), so a made entry's how is left empty here.
static func lineage(era: StringName, kind: StringName, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, &"lineage"])
	# Every draw in one order whatever the era, so each is the seed's alone.
	var keeps_house := rng.randf()
	var house: StringName = HOUSES[rng.randi() % HOUSES.size()]
	var remake: Array = REMAKES[rng.randi() % REMAKES.size()]
	var blessed := rng.randf()
	var cistern := rng.randf()
	var blessing: Array = BLESSINGS[rng.randi() % BLESSINGS.size()]
	var shares: Dictionary = SHARES[&""].merged(SHARES.get(kind, {}), true)
	match era:
		COLONIAL, SKIMMER:
			return [[era, &"made", []]]
		FIRST:
			return [[COLONIAL, &"made", []], [FIRST, &"marked", [house]]]
		SECOND, DARK:
			var line := [[COLONIAL, &"made", []]]
			if keeps_house < shares.marked:
				line.append([FIRST, &"marked", [house]])
			line.append([DARK, &"remade", remake.duplicate()])
			if era == SECOND and blessed < shares.blessed:
				line.append([SECOND, &"blessed", (CISTERN if cistern < shares.cistern else blessing).duplicate()])
			return line
	return []


## The era a thing's numbers are of: its last hands', the Dark Age's remake
## being second-age gear. None, a thing never found: the company's issue.
static func era_of(line: Array) -> StringName:
	if line.is_empty():
		return NEW
	var last: StringName = line[-1][0]
	return SECOND if last == DARK else last


## Who first made it: the era its maker's stamp is of.
static func origin(line: Array) -> StringName:
	return NEW if line.is_empty() else line[0][0]


## A lineage as one word, a look's name in its cache.
static func key(line: Array) -> String:
	var words := PackedStringArray()
	for entry: Array in line:
		words.append(entry_key(entry))
	return "|".join(words)


static func entry_key(entry: Array) -> String:
	return "%s:%s:%s" % [entry[0], entry[1], ",".join(PackedStringArray(entry[2]))]


## How deep a site of the era lies, from its own draw.
static func depth(era: StringName, rng: RandomNumberGenerator) -> float:
	var span: Vector2 = BURIAL.get(era, Vector2.ZERO)
	return rng.randf_range(span.x, span.y)
