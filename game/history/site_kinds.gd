class_name SiteKinds
extends RefCounted
## Every kind of site and sign, as data: the one registry history places by
## and the kits fill in. A site is a structure; a sign is a small marker that
## says something lies beneath (a cairn, a saltbush planting) with no ground
## of its own. `reach` is how far a kind's ground reaches from its middle, m;
## `lattice` kinds stand on the lattice and turn in quarter turns, as anything
## with walls must. Only the house ruin has a kit yet: `Ruin`.

const KINDS := {
	# Colonial: the skeleton's pieces, and the colonial settlements'.
	&"pylon_stub": {"era": Eras.COLONIAL, "reach": 3.0},
	&"pipeline_segment": {"era": Eras.COLONIAL, "reach": 6.0},
	&"hab_pod": {"era": Eras.COLONIAL, "reach": 10.0, "lattice": true},
	&"relay_mast": {"era": Eras.COLONIAL, "reach": 5.0},
	&"survey_beacon": {"era": Eras.COLONIAL, "reach": 2.0},
	&"pump_station": {"era": Eras.COLONIAL, "reach": 14.0, "lattice": true},
	&"farm_dome": {"era": Eras.COLONIAL, "reach": 18.0},
	&"vent_station": {"era": Eras.COLONIAL, "reach": 16.0, "lattice": true},
	# Skimmer era: scars on colonial structures, and wrecks anywhere.
	&"wreck_hull": {"era": Eras.SKIMMER, "reach": 14.0},
	&"fuel_bladder": {"era": Eras.SKIMMER, "reach": 4.0},
	&"dugout": {"era": Eras.SKIMMER, "reach": 6.0},
	&"checkpoint": {"era": Eras.SKIMMER, "reach": 8.0, "lattice": true},
	# First Kingdoms: low foundations along the dead lines and by water.
	&"pipe_wall_hut": {"era": Eras.FIRST, "reach": 6.0, "lattice": true},
	&"cistern": {"era": Eras.FIRST, "reach": 8.0},
	&"low_wall": {"era": Eras.FIRST, "reach": 8.0},
	&"generator_shrine": {"era": Eras.FIRST, "reach": 6.0, "lattice": true},
	# Second age: water, roads and the kingdoms dying of thirst.
	&"wayshrine": {"era": Eras.SECOND, "reach": 3.0},
	&"watchtower": {"era": Eras.SECOND, "reach": 5.0, "lattice": true},
	&"house_ruin": {"era": Eras.SECOND, "reach": Ruin.REACH, "lattice": true},
	&"caravanserai": {"era": Eras.SECOND, "reach": 20.0, "lattice": true},
	&"stepwell": {"era": Eras.SECOND, "reach": 8.0, "lattice": true},
	&"ration_gate": {"era": Eras.SECOND, "reach": 8.0, "lattice": true},
	&"granary": {"era": Eras.SECOND, "reach": 7.0, "lattice": true},
	&"earthwork": {"era": Eras.SECOND, "reach": 12.0},
	&"bunker": {"era": Eras.SECOND, "reach": 12.0, "lattice": true},
	# Signs: the Dark Age's markers on the migration routes.
	&"cairn": {"era": Eras.DARK, "reach": 1.0, "sign": true},
	&"cache": {"era": Eras.DARK, "reach": 1.0, "sign": true},
	&"saltbush_planting": {"era": Eras.DARK, "reach": 2.0, "sign": true},
}


static func era(kind: StringName) -> StringName:
	return KINDS[kind].era


static func reach(kind: StringName) -> float:
	return float(KINDS[kind].reach)


## The farthest any kind's ground reaches, m.
static func most_reach() -> float:
	var most := 0.0
	for kind: StringName in KINDS:
		most = maxf(most, reach(kind))
	return most


static func is_sign(kind: StringName) -> bool:
	return KINDS[kind].get("sign", false)
