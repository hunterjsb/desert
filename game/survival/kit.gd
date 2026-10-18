class_name Kit
extends Resource
## What a run starts with, as data: catalog ids and how many of each. What's
## carried goes into what the suit carries; what's beside you is set down on
## the sand where the run begins, some of it put together. Each origin is one
## (the vision's player origins): who you came as, what you brought and where
## on the moon you begin.

const STANDARD := "res://game/survival/standard_kit.tres"
## The origins New game offers, the default first.
const ORIGINS: Array[String] = [STANDARD, "res://game/survival/salvager_kit.tres",
	"res://game/survival/homesteader_kit.tres"]

## Who you came as, by id and by name, and the few words New game says
## under the name.
@export var id: StringName = &""
@export var label := ""
@export var about := ""
## What the main menu shows of it: things beside you, by name, side by side
## in this order, each turned this far about the up axis, degrees.
@export var shown: Dictionary[StringName, float] = {}
## Where on the moon it begins (Starts): "artery", "wreck_field" or
## "wayshrine"; none, where the tuning says.
@export var start: StringName = &""
## One of the three the game is balanced round. Only those have Ironman.
@export var balanced := false
## What unlocks it on the profile (Profile.unlock). None, it's open from the
## first run: the Salvager's and the Homesteader's playstyle unlocks wait on
## counting a playstyle, so they're open for now.
@export var unlock := ""
## Carried by the suit, in order.
@export var carried: Dictionary[StringName, int] = {}
## Set down beside you: a catalog id, or the name of something assembled, each
## at its place, m to your right and ahead of where you start.
@export var beside: Dictionary[StringName, Vector2] = {}
## Devices that come put together, by name: "frame", a catalog device, and
## "sockets", what fills them by their place in its list, a part fitted or a
## device seated; a thing beside you named there comes seated in it instead,
## as the board racked on the crate. A plain device beside you comes with its
## batteries.
@export var assembled: Dictionary[StringName, Dictionary] = {}
## Lines laid between two things beside you, by name, each a coil's length:
## a floater moored to its stake, the stake to be taken up to tow it.
@export var lines: Dictionary[StringName, StringName] = {}
## How full the batteries in what's beside you start, 0 to 1.
@export var charge := 1.0
## How long a coil or a line beside you lays, m.
@export var rope_m := 12.0


## The kit every run starts with when it has no origin of its own: the Surveyor's.
static func standard() -> Kit:
	return load(STANDARD)


## The kit a world's run starts with: its origin's, or the standard one.
static func of(world: World) -> Kit:
	return world.kit if world != null and world.kit != null else standard()


static func origins() -> Array[Kit]:
	var out: Array[Kit] = []
	for path in ORIGINS:
		out.append(load(path))
	return out


## The origin by its id, or null.
static func named(origin: StringName) -> Kit:
	for each in origins():
		if each.id == origin:
			return each
	return null


## The origins this profile may choose from, the default first.
static func open_to(profile: Node) -> Array[Kit]:
	var out: Array[Kit] = []
	for each in origins():
		if each.is_open_to(profile):
			out.append(each)
	return out


func is_open_to(profile: Node) -> bool:
	return unlock == "" or (profile != null and profile.has(unlock))


## What's carried, one id a thing.
func carried_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for thing in carried:
		for i in carried[thing]:
			out.append(thing)
	return out
