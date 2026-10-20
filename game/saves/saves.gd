extends Node
## The run save, at /root/Saves. One at a time, for the one run, and it keeps
## the run's mode: in Normal you save as you go and death offers it back; in
## Ironman, Save & quit only suspends the run and death deletes it. Resume
## puts it back on a world built on its seed and origin. It holds only what
## you changed (Snapshot). A save from another version is refused with a
## reason, never half-read; one from before modes has none, and is Normal's.

## Everything resumed and running again.
signal restored(world: World)

const KIND := "sandgame run"
## 2: what's on a deck is saved by the face it's stuck on and where, since
## the chassis became the one structure (2026-10-18).
const VERSION := 2
## Why an older version can't be resumed, said plainly.
const OLDER := {1: "it was saved before camps were rebuilt round the chassis, so nothing in it would sit where it was"}

## Where the save lives; probes point it somewhere of their own.
var dir := "user://"
## What a player's folder held when the game was called Sandgame.
const CARRIED := ["profile.save", "run.save", "settings.cfg"]
## Why the save on disk can't be resumed, or "".
var refused := ""
## A resume is waiting for the ground under the camp.
var restoring := false
## A save being written on a worker thread, or -1.
var _writing := -1


func path() -> String:
	return dir.path_join("run.save")


## A save that this build can resume.
func has_run() -> bool:
	return not _read().is_empty()


func run_seed() -> int:
	return _read().get("seed", 0)


## The saved run is Ironman's.
func ironman() -> bool:
	return _read().get("ironman", false)


## The saved run's origin, by id: none from before origins, which resumes
## with the start it had.
func kit() -> StringName:
	return _read().get("kit", &"")


## The saved run as its file holds it, {} with none (Snapshot reads it).
func held() -> Dictionary:
	return _read()


## When the run was saved, unix time; from before saves kept it, when the file was written.
func saved_at() -> int:
	return _read().get("saved", FileAccess.get_modified_time(path()))


## Saves the run, in its mode: safe at any moment, mid-storm included, and it
## changes nothing in the world. A dead run isn't saved, nor one half put back.
func save(world: World, ironman := false) -> bool:
	var bytes := _taken(world, ironman)
	return not bytes.is_empty() and SaveFile.write_bytes(path(), KIND, VERSION, bytes)


## The same without the frame waiting on the disk: the run is taken now,
## between ticks, and written on a worker thread.
func save_in_background(world: World, ironman := false) -> bool:
	var bytes := _taken(world, ironman)
	if bytes.is_empty():
		return false
	var to := path()
	_writing = WorkerThreadPool.add_task(func() -> void: SaveFile.write_bytes(to, KIND, VERSION, bytes))
	return true


## Puts the saved run back on a world built on run_seed() that has settled.
## You, the clock and the finds' memory are back at once; your things follow
## as soon as the ground under them is solid, with the clock held until then,
## and `restored` says when. False, with `refused` saying why, if it can't.
func restore(world: World) -> bool:
	var data := _read()
	if data.is_empty():
		return false
	if data.seed != world.run_seed:
		refused = "the save is for seed %d, the world is on %d" % [data.seed, world.run_seed]
	else:
		refused = Snapshot.problem(data)
	if refused != "":
		push_warning("refused: " + refused)
		return false
	var snapshot := Snapshot.new(world)
	var places := snapshot.begin(data)
	if _ready_at(world, places):
		snapshot.finish(data)
		restored.emit.call_deferred(world)
	else:
		_finish_later(world, snapshot, data, places)
	return true


func delete() -> void:
	_wait()
	SaveFile.remove(path())
	refused = ""


func _exit_tree() -> void:
	_wait()


func _taken(world: World, ironman: bool) -> PackedByteArray:
	_wait()
	if world == null or world.player.vitals.dead or restoring:
		return PackedByteArray()
	var data := Snapshot.take(world)
	data.ironman = ironman
	data.kit = world.kit.id if world.kit != null else &""
	data.saved = floori(Time.get_unix_time_from_system())
	return var_to_bytes(data)


## Until the save being written has landed.
func _wait() -> void:
	if _writing != -1:
		WorkerThreadPool.wait_for_task_completion(_writing)
		_writing = -1


func _read() -> Dictionary:
	_wait()
	var got := SaveFile.read(path(), KIND, VERSION)
	refused = OLDER.get(got.found, got.refused) if got.refused != "" else ""
	return got.data


## The ground is solid round you and loaded under everything of yours.
func _ready_at(world: World, places: Array[Vector2]) -> bool:
	if not world.terrain.is_settled_around(places[0].x, places[0].y):
		return false
	return places.all(func(p: Vector2) -> bool: return world.terrain.is_loaded_at(p.x, p.y))


## Holds the clock and you still until the ground is there, then puts
## everything back in the gap between two ticks.
func _finish_later(world: World, snapshot: Snapshot, data: Dictionary, places: Array[Vector2]) -> void:
	restoring = true
	var warp := world.time_warp
	var moving := world.player.is_physics_processing()
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	while is_instance_valid(world) and not _ready_at(world, places):
		await get_tree().physics_frame
	restoring = false
	if not is_instance_valid(world):
		return
	snapshot.finish(data)
	world.time_warp = warp
	world.player.set_physics_process(moving)
	restored.emit(world)


## The game was Sandgame until 0.1.0-alpha, and a player's folder is named for
## the game: their profile, save and settings come over once, the first time
## Desert starts with none of its own.
func _init() -> void:
	var here := OS.get_user_data_dir()
	if CARRIED.any(func(name: String) -> bool: return FileAccess.file_exists(here.path_join(name))):
		return
	var old := here.get_base_dir().path_join("Sandgame")
	for name: String in CARRIED:
		if FileAccess.file_exists(old.path_join(name)):
			DirAccess.make_dir_recursive_absolute(here)
			DirAccess.copy_absolute(old.path_join(name), here.path_join(name))
