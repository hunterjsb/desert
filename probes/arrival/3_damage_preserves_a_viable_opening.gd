extends Probe
## Losing every optional piece must retain usable survival, scouting and return gear.
func run() -> void:
	var opening := SurveyorManifest.resolve(1234, Sphere.point(0.2, -0.3),
		{"outer_survival": 0.0, "frame_survival": 0.0, "extra_survival": 0.0})
	var all: Array = opening.structure + opening.equipment
	var uids := {}
	var catalog := true
	for entry: Dictionary in all:
		catalog = catalog and (Catalog.DEVICES.has(entry.id) or Catalog.PARTS.has(entry.id) or entry.id == &"stake")
		uids[entry.uid] = entry
	check(all.all(func(entry: Dictionary) -> bool: return not Catalog.DEVICES.has(entry.id) or entry.state.has("durability")),
		"device damage uses the existing durability state")
	check(catalog and uids.size() == all.size(), "every physical record has a known catalog kind and unique identity")
	check(opening.structure.size() == 12 and opening.structure.filter(func(entry: Dictionary) -> bool: return entry.survives).size() == 2,
		"only the two core floors survive loss of all optional shell parts")
	var required := [&"floor_a", &"floor_b", &"water", &"food", &"guide", &"beacon", &"shield", &"camp_cell", &"panel", &"stake", &"rope", &"board", &"board_cell", &"hook"]
	check(required.all(func(uid: StringName) -> bool: return uids.has(uid) and uids[uid].survives),
		"survival, a usable board and camp return are not randomized away")
	var gear: Array = opening.equipment.filter(func(entry: Dictionary) -> bool: return entry.survives)
	check(gear.all(func(entry: Dictionary) -> bool:
		return entry.state.get("durability", 1.0) > 0.0 and entry.state.get("charge_fraction", 1.0) > 0.0 and entry.state.get("fill_fraction", 1.0) > 0.0),
		"essential devices, cells and supplies remain usable")
	var intact := SurveyorManifest.resolve(1234, opening.landing_point,
		{"outer_survival": 1.0, "frame_survival": 1.0, "extra_survival": 1.0})
	check((intact.structure + intact.equipment).all(func(entry: Dictionary) -> bool: return entry.survives),
		"the opposite recovery rule keeps every authored piece")
