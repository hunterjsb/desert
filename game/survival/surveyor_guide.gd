class_name SurveyorGuide
extends SailingNotes
## Company field instructions recovered with the landing supplies.

## Four pictures, a line each: what to do, not how it all works.
const GUIDE_PAGES := [
	["Take what survived", "Look at loose gear and {hands_grab} to take it. {inventory} holds what you carry.", "res://assets/tutorial/surveyor/salvage.png"],
	["Raise a shield", "Fit a battery and a shield on a deck's top with {hands_grab}, then {interact} at the shield.", "res://assets/tutorial/surveyor/shelter.png"],
	["Mark Home", "Fit the Home beacon on your deck and {interact} at it. {inventory} shows the way back.", "res://assets/tutorial/surveyor/home.png"],
	["Follow a signal", "Turn your receiver toward a stronger needle: loot beacons only. {ride} your board to scout.", "res://assets/tutorial/surveyor/scout.png"],
]
const HOW_TO := "surveyor_guide"
const HOW_TO_SAYS := "Your Guide is in {inventory}: {interact} on it to read."

var _introduced := false


func _process(_delta: float) -> void:
	if not _introduced and world != null and Controls.ui != null and Controls.playing() \
			and world.player.suit.carried.has(self):
		_introduced = true
		set_process(false)
		Controls.ui.teach(HOW_TO, HOW_TO_SAYS)


func book_title() -> String:
	return "Surveyor's Guide"


func pages() -> Array:
	return GUIDE_PAGES
