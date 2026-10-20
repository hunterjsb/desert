class_name RopeTip
extends Part
## A line end can pass through a fairlead before it is tied at its destination.


func use(by: Player, _at: Vector3) -> bool:
	return route_at(by)


func route_at(by: Player) -> bool:
	var hook := by.hands._look_hook()
	if hook == null or not has_meta(&"line"):
		return false
	var line: Line = get_meta(&"line")
	var why := line.route(hook.guide)
	if why != "":
		return by.hands.refuse(why)
	by.hands.say("line passes through hook" if line.rope.through != null else "line clear of hook")
	by.hands._seat_sound()
	return true
