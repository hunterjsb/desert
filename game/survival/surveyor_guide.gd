class_name SurveyorGuide
extends SailingNotes
## Company field instructions, carried safely with the starting supplies.

const GUIDE_PAGES := [
	["Your survey camp", "Your first survey: get a view from a nearby rise, identify a route or ruin, bring one useful find back and fit it to camp. Begin by checking the shield and keeping the mooring stake driven while you prepare. Your longer aim is power, water and food that sustain the camp as you travel. You choose the route.\nRead this guide from {inventory}: point at its picture and {interact}. It also opens with {interact} in your hands or lying nearby. The world keeps moving while you read."],
	["Know your gear", "Your chassis carries a light shield, solar panel, battery and hover trays. The shield starts off: look at it empty-handed and {interact}. Keep yourself and loose gear inside its bubble. Devices on the deck share its batteries; a detached board uses its own. Solar needs light, so save charge before a storm.\nThe board and compass hang on the upright. Look at the board and {ride} to scout. {inventory} shows carried supplies; your suit eats and drinks from them automatically. The bedroll can wait out safe, sheltered hours: {interact} lays it out, then use it again to choose sleep."],
	["Tow, then park", "Take the mooring stake with {hands_grab}. With it ready in hand, aim at an open, level horizon or into the sky and {interact} to tie it at your waist. Walk to tow the camp. The board is a scout, not a dependable heavy hauler.\nTo park, empty your hands and {interact} to return the sole waist stake to them; outside the carry view, aim clear of devices you could operate. Aim at nearby sand and {interact} to drive the stake. Dropping it with {hands_grab} leaves it loose. Anchor before a storm."],
	["Scout and return", "Take the compass before leaving camp. Its red needle points north, not toward home or Tu. Let it settle; storms and strange ground can pull it aside. A carried compass stays readable in {inventory}. Before departing, face back toward camp and remember that direction. Look back at recognizable skyline shapes as you go.\nMasts, towers, glints and lines of shrubs can lead you toward old routes and salvage. A glint depends on sunlight and viewing angle. Tracks fade. Keep your first trip short and camp in sight; look back at landmarks. Park and anchor before weather hides the route."],
	["Bring back an improvement", "Aim at a loose exposed find and {hands_grab} to take it. {inventory} lets you carry it home. Holding a compatible battery, panel or other part, aim at a free chassis face and {hands_grab} to mount it; the preview shows its place and warns of overlap. A mounted battery joins that deck's power pool. Buried or fastened salvage may need tools you have not found yet.\nWhen a storm approaches, return, drive the mooring stake and switch on the shield. Stay inside with the gear you need. Check charge before spending it on hover. Shelter and a still camp let you use the laid bedroll to sleep; a menu alone does not pause the storm."],
]


const HOW_TO := "surveyor_guide"
const HOW_TO_SAYS := "Your first survey: find a route or ruin from a nearby rise, bring back a useful find and fit it to camp.\n" \
	+ "Open {inventory}, point at the Surveyor's Guide and {interact} to read."

var _introduced := false


func _process(_delta: float) -> void:
	if not _introduced and world != null and Controls.ui != null and Controls.playing() \
			and world.player.suit.carried.has(self):
		_introduced = true
		Controls.ui.teach(HOW_TO, HOW_TO_SAYS)


func book_title() -> String:
	return "Surveyor's Guide"


func pages() -> Array:
	return GUIDE_PAGES
