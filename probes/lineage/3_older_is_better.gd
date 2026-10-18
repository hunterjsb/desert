extends Probe
## Lineage probe 3: era stats, efficiency against repairability, scale the
## numbers as Eras.GEAR says. A battery, a panel, a tray, a turbine, a light
## panel and both shields of each era keep and draw by their make's factors
## against the catalog's, a colonial battery holds more than any later one,
## and the weather takes a First Kingdoms frame slowest and a skimmer one
## fastest. A thing never found keeps the catalog's numbers.

const ERAS: Array[StringName] = [Eras.COLONIAL, Eras.FIRST, Eras.SKIMMER, Eras.SECOND]


func run() -> void:
	var held := {}
	var tuning := Tuning.current()
	for era in ERAS:
		var gear: Dictionary = Eras.GEAR[era]
		var line := _line(era)
		var cell := _part(&"battery", line)
		var big := _part(&"big_battery", line)
		var panel := _part(&"solar_panel", line)
		var tray := _part(&"hover_tray", line)
		held[era] = cell.capacity()
		check(is_equal_approx(cell.capacity(), 100.0 * gear.keeps) and is_equal_approx(big.capacity(), 300.0 * gear.keeps)
			and is_equal_approx(panel.stats.solar_w, 60.0 * gear.keeps) and is_equal_approx(tray.stats.lift_kg, 80.0 * gear.keeps),
			"%s: batteries hold %d and %d Wh, a panel makes %d W, a tray floats %d kg" % [era, cell.capacity(), big.capacity(),
			panel.stats.solar_w, tray.stats.lift_kg])
		var crate := Catalog.device(&"crate_frame")
		crate.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		crate.fit(tray, crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"bottom")[0])
		check(is_equal_approx(crate.stats().hover_draw, gear.draws), "%s: its tray draws %.2f a kilogram's watts" % [era,
			crate.stats().hover_draw])
		var turbine := _device(&"turbine", line)
		var light_panel := _device(&"light_panel", line)
		var shield := _device(&"shield", line)
		var light := _device(&"light_shield", line)
		check(is_equal_approx(turbine.frame_stats.turbine_w, 200.0 * gear.keeps)
			and is_equal_approx(light_panel.frame_stats.solar_w, 30.0 * gear.keeps)
			and is_equal_approx(shield.frame_stats.storm_w, tuning.shield_storm_w * gear.draws)
			and is_equal_approx(shield.frame_stats.clear_w, tuning.shield_clear_w * gear.draws)
			and is_equal_approx(light.frame_stats.storm_w, 20.0 * gear.draws), "%s: a turbine makes %d W, a shield draws %d W in a storm" % [
			era, turbine.frame_stats.turbine_w, shield.frame_stats.storm_w])
		turbine.wear(0.2)
		check(is_equal_approx(1.0 - turbine.durability, 0.2 / (4.0 * gear.tough)), "%s: the weather takes %.3f of a turbine's life" % [
			era, 1.0 - turbine.durability])
		for thing: Node in [cell, big, panel, crate, turbine, light_panel, shield, light]:
			thing.free()
	check(held[Eras.COLONIAL] > held[Eras.FIRST] and held[Eras.FIRST] > held[Eras.SKIMMER]
		and held[Eras.SKIMMER] > held[Eras.SECOND], "older is better: a colonial battery holds the most, a second-age one the least")
	var plain := Catalog.part(&"battery") as Battery
	check(plain.capacity() == 100.0 and not plain.has_meta(&"lineage"), "a battery never found holds the catalog's 100 Wh")
	plain.free()


## A lineage whose numbers are the era's.
func _line(era: StringName) -> Array:
	return {Eras.COLONIAL: [[Eras.COLONIAL, &"made", []]], Eras.SKIMMER: [[Eras.SKIMMER, &"made", []]],
		Eras.FIRST: Eras.lineage(Eras.FIRST, &"cistern", 1), Eras.SECOND: Eras.lineage(Eras.SECOND, &"house_ruin", 1)}[era]


func _part(id: StringName, line: Array) -> Part:
	var made := Catalog.part(id)
	Catalog.inherit(made, line)
	return made


func _device(id: StringName, line: Array) -> Device:
	var made := Catalog.device(id)
	Catalog.inherit(made, line)
	return made
