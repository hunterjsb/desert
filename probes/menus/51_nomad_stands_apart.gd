extends MenuProbe
## Menus & UI probe 51: Nomad's card stands apart under every tree, a line
## from each of the five it waits on into its side, lit where a deed of that
## tree shows done: Set Sail's Wind, not Ruins with Bared done early and dark.


func run() -> void:
	await open_main()
	var profile := get_node(^"/root/Profile")
	profile.deed("sail_waist")
	profile.deed("bared")
	var menu := main.ui.deeds()
	main.ui.open(menu)
	var tree: DeedsGrid = menu.find_children("*", "DeedsGrid", true, false)[0]
	var card: Button = tree._cards[&"nomad"]
	check(tree._cards.values().all(func(other: Button) -> bool:
		return other == card or other.position.y + DeedsGrid.CARD.y < card.position.y), "Nomad stands under every tree")
	var trees: Array = Deeds.TABLE.nomad.after_any
	var lines := tree.tree_lines(&"nomad")
	var into := lines.all(func(line: Dictionary) -> bool:
		var end: Vector2 = line.line[-1]
		return absf(end.x - card.get_rect().end.x) < 0.5 and card.get_rect().has_point(end - Vector2(1.0, 0.0)))
	var from := range(trees.size()).all(func(i: int) -> bool:
		var top := INF
		for id: StringName in Deeds.TABLE:
			if Deeds.TABLE[id].family == trees[i] and id != &"nomad":
				top = minf(top, tree._cards[id].position.y)
		return absf(lines[i].line[0].y - top) < 0.5)
	check(lines.size() == 5 and into and from, "a line from the top of each of the five trees into its side")
	check(lines.map(func(line: Dictionary) -> bool: return line.lit) == [true, false, false, false, false],
		"lit only from Wind, where a deed shows done")
	main.ui.close_top()
