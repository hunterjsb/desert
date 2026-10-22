class_name SurveyorGuide
extends SailingNotes
## Company field instructions recovered with the landing supplies.

const GUIDE_PAGES := [
	["Recover your supplies", "Your pod is your first salvage. Look around it for surviving gear: condition and charge vary. Aim at a loose item and {hands_grab} to take it; {inventory} stores what you carry. Keep water and food with you: your suit uses carried supplies automatically.\nRecover shelter and power before setting out. You choose what your camp becomes."],
	["Build a shelter", "Keep the pod as a base, or salvage its panels to build your own chassis. Holding a battery or solar panel, aim at a free chassis face and {hands_grab} to mount it. The shield needs a free upward-facing chassis top. Check the placement preview. Mounted devices share that deck's batteries.\nEmpty your hands and {interact} at the shield to switch it on. Keep yourself and loose supplies inside. Solar needs light; save charge for storms."],
	["Make camp yours", "You do not need to dismantle the whole pod. Recover useful parts first; leave what you cannot move yet. A stake and rope can anchor a mobile camp against the wind. With a stake in hand, aim at nearby sand and {interact} to plant it.\nKeep the shield powered when weather threatens. A laid bedroll lets you sleep when camp is still and sheltered. Reading and other menus do not pause the weather."],
	["Mark Home", "Recover the Home beacon. Hold it, aim at a free upward-facing chassis top and {hands_grab} to mount it. Empty your hands and {interact} at the beacon to mark Home. Wait until support is ready before leaving.\nOpen Home in {inventory} for bearing and distance. Live reception follows camp; Last known fix is an older position after power or range is lost. The beacon offers no shelter."],
	["Your first survey", "Start small: reach a nearby rise, spot a route or ruin, and bring back one useful find to improve camp. Look at your recovered board and {ride} to scout; its fitted battery is separate from camp power.\nA compass points north, not home. Notice skyline shapes and check Home before going farther. Return before your shelter needs its charge. A self-sustaining camp is the longer survey; the route is yours."],
]


const HOW_TO := "surveyor_guide"
const HOW_TO_SAYS := "[font_size=20]" \
	+ "Open {inventory}, point at the Surveyor's Guide and {interact} to read.[/font_size]"

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
