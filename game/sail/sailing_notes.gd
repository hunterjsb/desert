class_name SailingNotes
extends Device
## A field booklet you can keep beside the rig and reopen between attempts.
## Reading uses the normal menus, so controls and back behave as elsewhere.

const PAGES := [
	["First run", "The practice rig is on skates. Its sheet is already at your waist; the charged board and these notes lie at your feet. The streamer on its mast shows the air it feels.\n\n"
		+ "Look at the mast and {interact} to raise its sail. Look at the board and {ride} to step on. Start across the wind, with the rig ahead, and let it gather speed. {move_left} / {move_right} steer; {move_back} digs the edge. Change one thing at a time: your course, then your sheet. Use the mast again to furl before leaving the rig unattended.\n\n"
		+ "These pages stay available: {interact} reads the booklet loose or in your hands. {ui_cancel} closes a page; close the chapter list to return to the run. The world keeps moving while you read, so read before setting sail."],
	["Read the wind", "The streamer points downwind, away from where the air comes from. On a moving rig it shows apparent wind: the weather's wind minus the rig's movement. As you accelerate, the wind you sail through changes; trim again rather than keeping one setting forever.\n\n"
		+ "Start with the wind coming from your side: a beam reach. Turning toward the wind is heading up; turning away is bearing away. Straight into the wind the sail cannot pull you forward. To make ground upwind, sail diagonally toward it, then cross to the other tack. A floating Varran rig needs more room off the wind than a yacht with a keel.\n\n"
		+ "Dead downwind is not always fastest. A reach gives the sail useful lift across the apparent wind; the rig's skates, a yacht's keel, or your board's dug edge keep that sideways force from simply blowing everything downwind."],
	["Trim the sheet", "The sheet limits how far the boom can swing out. {reel_in} shortens it; {pay_out} eases it. It does not rotate the sail directly: wind swings the boom until the sheet checks it. A tight sheet is not a throttle. Haul too far and the sail stalls; let it too far out and it luffs without useful drive.\n\n"
		+ "Look toward the sail while reeling so you select its sheet. Start eased on a reach, then haul a little as speed builds and apparent wind moves forward. Watch the cloth and streamer, feel the pull, and compare speed after each change. The best trim follows the air you feel now, not just your compass heading.\n\n"
		+ "Bear away before a hard turn if you have lost drive. Ease in stronger gusts to reduce load, or furl at the mast if the rig is tipping. Heavy gear high on the mast makes it easier to heel."],
	["Steer with the board", "Your move directions steer relative to where you look. {move_left} / {move_right} carve; {move_back} with a turn digs an edge and bites across the pull. Held alone, {move_back} swings the board into a braking stop. {crouch} into a hard carve drifts instead of holding a firm edge.\n\n"
		+ "The practice rig is steered by where you pull its sheet: ride to windward and it bears away; ride to leeward and it heads up. Keep the rig ahead and make small course corrections. Its runners resist sideways slip, but left alone it can round into the wind and stop.\n\n"
		+ "Slack lines leave the motor free: catch up to the rig or race ahead to swing it around. Your momentum and dug edge can steer and counterbalance it. Once you pull against a loaded line, the motor has only a small towing reserve: a tiny rig crawls, while a heavy one overloads the hover, presses the board toward the sand and makes it sputter. Ease off or let the sail take the load so it can recover. Pulling also uses extra battery power."],
	["Varran's bridle", "The Varran's floating rig has no skates or keel. Your dug board edge supplies the sideways grip; without it the rig and rider slide downwind. There are three waist lines: the sheet plus one from each bow hook. The nearer bow line loads while the far one hangs slack.\n\n"
		+ "Steer by the course you ride and trim while looking at the sail. Before changing tack, ease off the motor and brake some speed. Bear away, then look at the far bow corner and haul its line to bring that side across. Hold it short until the rig crosses; then pay it out gradually as you head up onto the new course. Reversing course at full throttle can stall the motor against the old tack. Turning the board alone does not reliably bring the floating rig across.\n\n"
		+ "Do not haul all three lines blindly. Look at the actual corner whose line you need. Start in a moderate breeze on a reach, leave room to turn, and practise one crossing before trying to climb upwind."],
	["Choose and untie lines", "With a rope end held, reeling works that line first. Otherwise it works the waist line whose far end lies closest to your aim. Look at the sail for its sheet or a bow hook for that bow line. The readout names the selected line and gives its length and tension. The current choice is slightly sticky, so turn your aim clearly to the other end before hauling.\n\n"
		+ "Reeling and untying choose the same line. Empty-handed, aim along the intended line and check its name in the readout. Aim clear of a device you could operate, then {interact} to untie that line into your hands; it takes a moment. {interact} with its end held ties it to your waist again. To free yourself, untie each end and put it down with {hands_grab} while aiming clear of the rig.\n\n"
		+ "Several lines can pull against each other through your body even when the net pull feels small. Heavy opposing loads hurt and shake you; a rope's breaking strength is not a safe load for a person. Ease the loaded line or furl before handling a rig in stronger wind."],
]


func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	return _read()


func use(_by: Player, _at: Vector3) -> bool:
	return _read()


func _read() -> bool:
	if Controls.ui == null:
		return false
	Controls.ui.open(chapters())
	return true


func chapters() -> Words:
	var menu := Words.new("Sailing field notes")
	for i in PAGES.size():
		menu.add(PAGES[i][0], func() -> void: Controls.ui.open(page(i)))
	menu.add("Close", Controls.ui.close_top)
	return menu


func page(at: int, paragraph := 0) -> Words:
	var parts: PackedStringArray = PAGES[at][1].split("\n\n", false)
	var menu := Words.new("%s · %d / %d" % [PAGES[at][0], paragraph + 1, parts.size()])
	var body := Controls.keys_label()
	body.theme_type_variation = &"KeysList"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = minf(820.0, get_viewport().get_visible_rect().size.x - 100.0)
	body.text = Controls.bbcode(parts[paragraph])
	menu.add_body(body)
	if paragraph + 1 < parts.size():
		menu.add("Next", _turn_page.bind(at, paragraph + 1))
	elif at + 1 < PAGES.size():
		menu.add("Next chapter", _turn_page.bind(at + 1, 0))
	if paragraph > 0:
		menu.add("Previous", _turn_page.bind(at, paragraph - 1))
	elif at > 0:
		var previous: PackedStringArray = PAGES[at - 1][1].split("\n\n", false)
		menu.add("Previous chapter", _turn_page.bind(at - 1, previous.size() - 1))
	menu.add("Chapters", Controls.ui.close_top)
	return menu


func _turn_page(at: int, paragraph: int) -> void:
	Controls.ui.close_top()
	Controls.ui.open(page(at, paragraph))
