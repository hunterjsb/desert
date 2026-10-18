extends Probe
## Lineage probe 2: the Dark Age's rule. Every second-age find, at every
## second-age kind of site over five hundred seeds, is a colonial or First
## Kingdoms thing remade in the Dark Age: made first by an older hand, the
## remake after it, every hand in history's order. A Dark Age cache's thing is
## remade and never yet blessed; a First Kingdoms find is colonial, marked by
## a house; a colonial or skimmer-era one is only made.


func run() -> void:
	var count := 0
	var kept := 0
	var marked := 0
	var blessed := 0
	for kind: StringName in SiteKinds.KINDS:
		var era := SiteKinds.era(kind)
		if era != Eras.SECOND and era != Eras.DARK:
			continue
		for k in 500:
			var line := Eras.lineage(era, kind, k)
			count += 1
			var made: Array = line[0] if not line.is_empty() else []
			var remade := line.filter(func(e: Array) -> bool: return e[0] == Eras.DARK and e[1] == &"remade")
			var ordered := true
			for i in range(1, line.size()):
				ordered = ordered and Eras.ORDER.find(line[i][0]) > Eras.ORDER.find(line[i - 1][0])
			var older: bool = not made.is_empty() and made[1] == &"made" and made[0] in [Eras.COLONIAL, Eras.FIRST]
			var never_blessed := era != Eras.DARK or not line.any(func(e: Array) -> bool: return e[1] == &"blessed")
			if older and remade.size() == 1 and ordered and never_blessed and Eras.era_of(line) == Eras.SECOND:
				kept += 1
			if line.any(func(e: Array) -> bool: return e[0] == Eras.FIRST):
				marked += 1
			if line.any(func(e: Array) -> bool: return e[1] == &"blessed"):
				blessed += 1
	print("%d second-age finds: %d kept a house's marks, %d blessed" % [count, marked, blessed])
	check(count > 0 and kept == count, "every one an older thing remade in the Dark Age (%d of %d)" % [kept, count])
	check(marked > count / 5 and marked < count * 4 / 5, "some kept a house's marks under the repair, not all")

	var first := Eras.lineage(Eras.FIRST, &"cistern", 3)
	check(first.size() == 2 and first[0][0] == Eras.COLONIAL and first[1][0] == Eras.FIRST and first[1][1] == &"marked"
		and Eras.HOUSES.has(first[1][2][0]), "a First Kingdoms find is colonial, marked by a house")
	for era: StringName in [Eras.COLONIAL, Eras.SKIMMER]:
		var line := Eras.lineage(era, &"", 3)
		check(line.size() == 1 and line[0][0] == era and line[0][1] == &"made", "a %s find is only made" % Eras.NAMES[era])
