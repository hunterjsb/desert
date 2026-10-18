extends Probe
## World system probe 5: today's ruin, the first kind through the index,
## stands exactly where it did before the world system: every one within 3 km
## of the origin on two seeds, against the list master placed (alongside this
## probe), by its middle, its turn and its floor; and the index answers for
## each as a house ruin of the second age, built and not planned.

const BEFORE := "res://probes/history/5_ruins_from_before.txt"
const RADIUS := 3000.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var before := PackedStringArray()
	for line in FileAccess.get_file_as_string(BEFORE).split("\n", false):
		before.append(line)
	var now := PackedStringArray()
	var answered := 0
	for run_seed: int in [1234, 7]:
		var shape := TerrainShape.new(run_seed, tuning)
		for ruin in shape.ruins.around(0.0, 0.0, RADIUS):
			now.append("%d %d %d %d %.6f" % [run_seed, ruin.center.x, ruin.center.y, ruin.turn, ruin.floor_y])
			var found := shape.sites.query(Rect2(ruin.x - 1.0, ruin.z - 1.0, 2.0, 2.0)).filter(func(s: Site) -> bool:
				return s == ruin and s.kind == &"house_ruin" and s.era == Eras.SECOND and not s.planned)
			if found.size() == 1:
				answered += 1
	check(now.size() == before.size(), "as many ruins as before (%d, %d before)" % [now.size(), before.size()])
	var moved := 0
	for i in mini(now.size(), before.size()):
		if now[i] != before[i]:
			moved += 1
			if moved <= 3:
				printerr("was %s, now %s" % [before[i], now[i]])
	check(moved == 0, "every ruin where it was, turned and floored as it was (%d not)" % moved)
	check(answered == now.size(), "the index answers for each as a built second-age house ruin (%d of %d)"
		% [answered, now.size()])
