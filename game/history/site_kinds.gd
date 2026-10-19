class_name SiteKinds
extends RefCounted
## Every kind of site and sign, as data: the one registry history places by.
## A kind with a kit piece (StructureKit, in its era's file) is built on the ground,
## and its reach, lattice, carve, boxes, sockets, look and states are the
## piece's. The rest are history's plan for now, for the map and the packages
## that will build them: `reach` is how far a kind's ground reaches from its
## middle, m, and `lattice` kinds will stand on the lattice and turn in
## quarter turns, as anything with walls must. A sign is a small marker that
## says something lies beneath (a cairn, a saltbush planting), with no ground
## of its own.

const KINDS := {
	# Colonial: the skeleton's pieces, and the colonial settlements'.
	&"pylon_stub": {"era": Eras.COLONIAL},
	&"pipeline_segment": {"era": Eras.COLONIAL},
	&"hab_pod": {"era": Eras.COLONIAL},
	&"relay_mast": {"era": Eras.COLONIAL},
	&"survey_beacon": {"era": Eras.COLONIAL, "reach": 2.0},
	&"pump_station": {"era": Eras.COLONIAL, "reach": 14.0, "lattice": true},
	&"farm_dome": {"era": Eras.COLONIAL, "reach": 18.0},
	&"vent_station": {"era": Eras.COLONIAL, "reach": 16.0, "lattice": true},
	# Wrecks from the colony's end: a contractor's freight pod and a
	# freighter's lifeboat, down after the rest was built, so shallower.
	&"freight_pod": {"era": Eras.COLONIAL, "burial": Vector2(1.0, 3.0)},
	&"lifeboat": {"era": Eras.COLONIAL, "burial": Vector2(0.8, 2.5)},
	# Skimmer era: scars on colonial structures, and wrecks anywhere.
	&"wreck_hull": {"era": Eras.SKIMMER},
	# A Provisional tithe hauler, down where the war's traffic ran.
	&"tithe_hauler": {"era": Eras.SKIMMER},
	&"fuel_bladder": {"era": Eras.SKIMMER},
	&"dugout": {"era": Eras.SKIMMER},
	&"checkpoint": {"era": Eras.SKIMMER, "reach": 8.0, "lattice": true},
	# First Kingdoms: low foundations along the dead lines and by water.
	&"pipe_wall_hut": {"era": Eras.FIRST},
	&"cistern": {"era": Eras.FIRST},
	&"low_wall": {"era": Eras.FIRST},
	&"generator_shrine": {"era": Eras.FIRST, "reach": 6.0, "lattice": true},
	# Second age: water, roads and the kingdoms dying of thirst.
	&"wayshrine": {"era": Eras.SECOND},
	&"watchtower": {"era": Eras.SECOND},
	&"house_ruin": {"era": Eras.SECOND},
	&"caravanserai": {"era": Eras.SECOND, "reach": 20.0, "lattice": true},
	&"stepwell": {"era": Eras.SECOND, "reach": 8.0, "lattice": true},
	&"ration_gate": {"era": Eras.SECOND, "reach": 8.0, "lattice": true},
	&"granary": {"era": Eras.SECOND, "reach": 7.0, "lattice": true},
	&"earthwork": {"era": Eras.SECOND, "reach": 12.0},
	&"bunker": {"era": Eras.SECOND, "reach": 12.0, "lattice": true},
	# A colonial hopper the Knights Requisitioner flew on the crusade.
	&"hopper": {"era": Eras.SECOND},
	# The ground's own: a live vent's mouth on the rift.
	&"vent_mouth": {"era": Eras.GEOLOGY},
	# Signs: the Dark Age's markers on the migration routes.
	&"cairn": {"era": Eras.DARK, "reach": 1.0, "sign": true},
	&"cache": {"era": Eras.DARK, "reach": 1.0, "sign": true},
	&"saltbush_planting": {"era": Eras.DARK, "reach": 2.0, "sign": true},
}


static func era(kind: StringName) -> StringName:
	return KINDS[kind].era


## Sand over a site of the kind, m, least and most: its own where it says,
## else its era's.
static func burial(kind: StringName) -> Vector2:
	return KINDS[kind].get("burial", Eras.BURIAL.get(era(kind), Vector2.ZERO))


static func reach(kind: StringName) -> float:
	var piece := StructureKit.piece(kind)
	return piece.reach if piece != null else float(KINDS[kind].reach)


## The kit piece a kind is built from on the ground, or null: only a plan.
static func kit(kind: StringName) -> StructureKit.Piece:
	return StructureKit.piece(kind)


## The farthest any kind's ground reaches, m.
static func most_reach() -> float:
	var most := 0.0
	for kind: StringName in KINDS:
		most = maxf(most, reach(kind))
	return most


static func is_sign(kind: StringName) -> bool:
	return KINDS[kind].get("sign", false)
