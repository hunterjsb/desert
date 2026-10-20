class_name BoardMakes
extends RefCounted
## Boards by make (docs/prd/movement.md): each make has its own provenance,
## and every one rides the one ride. A make is its catalog id, which saves
## already keep; its numbers are shares of the Hoverboard tuning, so tuning
## the ride tunes them all; its look is Dress's and its hum its own.

## Tilg & Standard's: the colony's yard and survey board, still issued.
const ISSUE := &"board"
## The skimmer era's own: light, cheap imports H-Town's crews raced.
const RACER := &"racer_board"
## The Knights Requisitioner's, ridden ahead of the crusade's water convoys.
const PATROL := &"patrol_board"
## Mother Cistern's temple's: an old hover core in a body of what grows.
const TEMPLE := &"temple_board"
const ALL: Array[StringName] = [ISSUE, RACER, PATROL, TEMPLE]

## What a make says, as shares of the tuning: flat out and the push, the
## hover's grip and how fast it turns, what a skid keeps of the grip and how
## hard it bleeds, a drift's grip and bleed, how high it rides, its spring,
## its cushion, its hop, how sturdy (what it takes before a landing jars or
## throws you, a knock throws you, or an edge catches), what it draws, and
## how long a landing's slide takes to bite again. Its hum is its own sound, at this
## pitch at rest and flat out.
const ISSUED := {"top": 1.0, "push": 1.0, "grip": 1.0, "turn": 1.0, "skid": 1.0, "skid_drag": 1.0,
	"drift_grip": 1.0, "drift_slide": 1.0, "height": 1.0, "spring": 1.0, "cushion": 1.0, "hop": 1.0,
	"sturdy": 1.0, "draw": 1.0, "bite": 1.0, "hum": [0.8, 1.4]}
const MAKES := {
	ISSUE: {},
	# Light and quick, flat out the fastest and highest off the sand; it
	# breaks loose soonest and holds the longest slide, and a hard landing
	# throws you sooner. Its era's gear wears out twice as fast.
	RACER: {"top": 1.15, "push": 1.12, "grip": 0.85, "turn": 1.15, "skid": 0.8, "skid_drag": 0.65,
		"drift_grip": 0.9, "drift_slide": 0.8, "height": 1.2, "spring": 1.1, "cushion": 0.9, "hop": 1.15,
		"sturdy": 0.85, "draw": 1.1, "bite": 1.2, "hum": [1.0, 1.75]},
	# Plated and heavy, low and planted: slower flat out, it grips hard and
	# skids short, and it takes a harder landing or knock before it throws you.
	PATROL: {"top": 0.9, "push": 0.92, "grip": 1.25, "turn": 0.9, "skid": 1.1, "skid_drag": 1.3,
		"drift_grip": 1.15, "drift_slide": 1.3, "height": 0.85, "spring": 0.95, "cushion": 1.15, "hop": 0.85,
		"sturdy": 1.3, "draw": 1.15, "bite": 0.75, "hum": [0.62, 1.0]},
	# Crude and lossy: the slowest and thirstiest, floating highest and
	# softest, it cushions a landing best and slides soft and slow to bite.
	TEMPLE: {"top": 0.85, "push": 0.85, "grip": 0.95, "turn": 0.95, "skid": 0.9, "skid_drag": 0.8,
		"drift_grip": 1.0, "drift_slide": 0.9, "height": 1.3, "spring": 0.75, "cushion": 1.35, "hop": 1.0,
		"sturdy": 1.1, "draw": 1.25, "bite": 1.4, "hum": [0.7, 1.2]},
}


## A make's numbers, the issue's where it says nothing: a catalog id that
## isn't a board's rides as the issue.
static func of(id: StringName) -> Dictionary:
	return ISSUED.merged(MAKES.get(id, {}), true)


## The make a board is: its catalog id.
static func make_of(board: Node) -> StringName:
	var id: StringName = board.get_meta(&"catalog", ISSUE)
	return id if MAKES.has(id) else ISSUE
