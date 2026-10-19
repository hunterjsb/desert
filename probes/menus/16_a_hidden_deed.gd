extends MenuProbe
## Menus & UI probe 16: a hidden deed, in a tree that scrolls. With Hermit and
## Sandblasted done, Eye of the Anomaly is open but hidden: ???? with no
## picture, its panel giving nothing away, the line to it drawn; Tells after
## it waits on ????. Done, its card shows its name and picture. The tree is
## taller than it shows, and opens scrolled to the deed done last, Slept It
## Off, far down it, its panel beside it.


func run() -> void:
	get_window().size = Vector2i(1920, 1080)
	await open_main()
	var profile := get_node(^"/root/Profile")
	for id in ["shield_day", "shield_storm"]:
		profile.deed(id)
	var tree := await _opened()
	var eye: Button = tree._cards[&"anomaly_eye"]
	check(eye.get_meta(&"state") == &"open" and _name(eye) == "????" and not _pictured(eye),
		"open but hidden: ???? and no picture")
	eye.grab_focus()
	check(tree._said[0].text == "????" and not tree._said[1].visible, "its panel says nothing of it")
	tree._cards[&"tells"].grab_focus()
	check(tree._said[2].text == "after ????", "Tells waits on ???? (\"%s\")" % tree._said[2].text)
	main.ui.close_top()
	for id in ["anomaly_eye", "ten_days", "slept_it_off"]:
		profile.deed(id)
	profile._deeds["slept_it_off"].at += 1000.0
	tree = await _opened()
	eye = tree._cards[&"anomaly_eye"]
	check(_name(eye) == "Eye of the Anomaly" and _pictured(eye), "done, its name and picture")
	var scroll := tree.get_parent() as ScrollContainer
	var slept: Button = tree._cards[&"slept_it_off"]
	check(scroll.size.y < tree.size.y and scroll.scroll_vertical > 0, "taller than it shows, scrolled down")
	check(get_viewport().gui_get_focus_owner() == slept and scroll.get_global_rect().encloses(slept.get_global_rect()),
		"on the deed done last, in view")
	check(tree._tip.visible and absf(tree._tip.position.y - slept.get_global_rect().position.y) < 1.0,
		"its panel beside it")
	main.ui.close_top()


func _opened() -> DeedsGrid:
	var menu := main.ui.deeds()
	main.ui.open(menu)
	for i in 3:
		await get_tree().process_frame
	return menu.find_children("*", "DeedsGrid", true, false)[0]


func _name(card: Button) -> String:
	return (card.find_children("*", "Label", true, false)[0] as Label).text


func _pictured(card: Button) -> bool:
	var picture: Control = card.get_child(0).get_child(0)
	return picture is TextureRect or not picture.draw.get_connections().is_empty()
