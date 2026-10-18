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
const ORDER: Array[StringName] = [COLONIAL, &"collapse", SKIMMER, FIRST, DARK, SECOND, &"feral", &"sand"]
## The eras that left structures.
const BUILT: Array[StringName] = [COLONIAL, SKIMMER, FIRST, SECOND]
## As bits, for what a path was used in.
const BITS := {COLONIAL: 1, SKIMMER: 2, FIRST: 4, DARK: 8, SECOND: 16}
const NAMES := {COLONIAL: "colonial", SKIMMER: "skimmer era", FIRST: "First Kingdoms", DARK: "Dark Age",
	SECOND: "second age"}

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
## Efficiency against repairability (part 5), as ranks, best first, and what
## mends each. The skimmer era is "the light cheap gear from before" (Hunter).
const MENDS := {COLONIAL: [1, "finite colonial parts"], FIRST: [2, "metal"], SKIMMER: [3, "light cheap gear"],
	SECOND: [4, "cord, ceramic and saltbush wood"]}


## A thing's lineage by the era of the site it was found in, the Dark Age's
## rule: [era, what was done] from its making on. Nothing after the colony
## was manufactured, so everything started colonial; the First Kingdoms kept
## and marked it; a second-age thing is a colonial or First Kingdoms one
## remade in the Dark Age.
static func lineage(era: StringName, rng: RandomNumberGenerator) -> Array:
	match era:
		FIRST:
			return [[COLONIAL, &"made"], [FIRST, &"marked"]]
		SECOND:
			var line := [[COLONIAL, &"made"]]
			if rng.randf() < 0.5:
				line.append([FIRST, &"marked"])
			line.append([DARK, &"remade"])
			if rng.randf() < 0.4:
				line.append([SECOND, &"blessed"])
			return line
	return [[era, &"made"]]


## How deep a site of the era lies, from its own draw.
static func depth(era: StringName, rng: RandomNumberGenerator) -> float:
	var span: Vector2 = BURIAL.get(era, Vector2.ZERO)
	return rng.randf_range(span.x, span.y)
