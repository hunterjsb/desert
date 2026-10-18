extends MenuProbe
## Menus & UI probe 11: deeds open in order. Flying Bling done first is kept
## but shows dark, uncounted, while the deeds it waits on aren't done; once
## Frequent Flyer and Big Air are, it shows done and counts. A card
## highlighted has its panel beside it.


func run() -> void:
	await open_main()
	var profile := get_node(^"/root/Profile")
	profile.deed("board_storm")
	var menu := main.ui.deeds()
	main.ui.open(menu)
	var tree: DeedsGrid = menu.find_children("*", "DeedsGrid", true, false)[0]
	check(profile.did("board_storm") and tree._cards[&"board_storm"].get_meta(&"state") == &"locked"
		and Deeds.count(profile) == 0, "done early, it's kept but dark and uncounted")
	tree._cards[&"board_distance"].grab_focus()
	check(tree._tip.visible, "the highlighted card has its panel")
	main.ui.close_top()
	for id in ["board_distance", "board_height"]:
		profile.deed(id)
	menu = main.ui.deeds()
	tree = menu.find_children("*", "DeedsGrid", true, false)[0]
	check(tree._cards[&"board_storm"].get_meta(&"state") == &"done" and Deeds.count(profile) == 3,
		"its branch open, it shows done and counts")
	menu.free()
