# Surveyor opening

The Surveyor starts in orbit, loads and launches a pod built from real chassis panels,
falls to Zan seated in it and makes a first camp from whatever survives. This page owns
that opening. It answers to the [vision](../vision.md) and extends [Survival](survival.md).
Other origins, developer scenarios and saves from before the opening keep their own starts.

## Hunter's decisions

- "Subnautica style launch pod… take apart the launch pod to form your chassis… you have
  a surveyor's guide. And let's keep it really, really simple for now."
- "We do want some randomization. So some drop pod randomization, and that could be part
  of the unlock tree too… We gotta keep our deeds in mind."
- "It'd be cool if we could actually start in orbit and get ejected down."
- "A spaceship interior from where we can see Zan from above, a launch computer for
  choosing landing location, trajectory, and scouting with very limited info from orbit
  so you don't spawn somewhere desolate. And then the pod, which you enter, load with
  what gear you can, and shoot down to the surface. You can then use the scattered
  chassis and frame from the pod plus whatever survived the landing."
- "Keep your first person the whole time… go through the atmosphere, heat up, land
  explosively on the ground; your stuff is… scattered around you."
- "Use, like, a display, like the console has… [using it] just zooms you into the display
  so you can interact with it with your mouse, and you can drag the trajectory like
  you're being launched with a single pulse… I don't want any inputs where people are
  inputting degrees… show, like, the planet spinning on this computer… which you need to
  account for in your launch and launch timing… really intuitive."
  Also: "Textures a little more articulate and not sandy", and "I don't see Tu in the background."
- "I should be able to put the roof on the pod myself and launch, and the message should
  tell me what's actually wrong… when the player drops in they start stuck in the chassis frame."
- "More windows, allow the player to look around while falling, add intensity and turbulence."
- "Go ahead and release and we will patch as we test": the opening is the Surveyor default.

## As built

**Cabin.** A small walkable room hangs over the start in the same World, sheltered from
weather. Its window shows Zan and Tu through a separate orbital renderer. While you prepare,
the world clock stands still and only the departure clock runs, so cabin time costs no survival.

**Station.** Using the computer zooms the view onto its screen for the mouse. The globe spins
on the departure clock. You drag one pulse handle; the screen draws the predicted path and
landing, and one line says whether the approach is gentle or hard and what the coarse survey
sees nearby. "Set launch pulse" commits it. The carrier keeps station over the start with a
small bounded drift, so the landing moves with launch time. One forecast, made every
`arrival_forecast_s`, is what the screen shows, what readiness judges and what the pod flies.

**Pod.** The pod is real chassis panels with its roofs and hatch set aside. Water, food, the
shield and the camp cell start aboard and always survive. Everything else waits on the racks,
for you to load by hand. You can fit a roof or the hatch yourself, or leave it loose and the
launch closes it. A lamp by the bay shows amber while anything is in the way and teal when
ready. The look line names only the first thing in the way, in one plain line, such as a roof
on the wrong face, a store left out or a landing that drifted onto rough ground. "Ready"
always launches.

**Fall.** You stay seated in first person from launch to impact. The view is from the pod
interior, out through windows in the real tail, side and roof panels. Head look turns within
seated limits and never steers. Turbulence, entry heat and the air and hull sound all come
from the saved flight time. The view is drawn every frame, a fraction of a tick past that
time, so it stays smooth at any frame rate. The landing ground is not drawn until entry
begins, when it starts to warm up behind the glass.

**Impact and camp.** Each panel and store rolls its survival and wear on its own seeded
identity and the approach's odds, so what else you packed never changes its fate. The impact
bursts the front frame off with the tail you watched the fall through, so the seat always faces
open floor under open sky: crawling straight ahead takes you out, and standing is possible
once clear. Nothing the impact places may land in that way. Real bodies stay in the pod or
scatter beside it, and anything that can't be placed is dropped beside the pod. The landing
never holds the run. The burst frame and its panels are recoverable debris, and the shield
and cell stay mounted behind the seat. The pod is your first chassis rig. Deeds: Plot a
Course, Drop In, Making Landfall.

**Saves.** One saved opening state. A save made in the cabin, mid-fall or mid-impact resumes
where it was, without rerolling, duplicating or replaying the impact. A departure model this
build cannot fly is rebuilt. An unlanded opening saved by a development build before the cabin
existed starts again in the cabin.

## Costs

Measured headless on seed 1234 in the cabin with the pulse set. The forecast costs 1.06 ms
and runs every 0.25 s. A full readiness check costs 0.31 ms and runs with each forecast. The
station's cargo report costs 0.29 ms and refreshes only when the forecast changes. Each frame,
the station costs 0.08 ms, the look line 0.007 ms and the window's moon frame 0.02 ms per tick.
The survey's sightings, 7.7 ms, are made once and saved with the plan. The ship's three
shadowed lights and two orbital viewports were not measured headless.

## Checks

`probes/arrival` covers:

- seeded per-identity survival (47);
- a flyable departure for every start (48);
- "Ready" always launches (49);
- a saved fall resuming once (50);
- crawling straight out, on the real opening (40) and on every seed and approach (51);
- loaded-only cargo (20, 21);
- rope and nested cargo through impact (23, 24, 44);
- lost frames as debris (5);
- recovery by hand (6);
- manual roofs and a broken pod (26, 39);
- station pointer and cover (32, 35);
- the flight shell (36);
- turbulence (43);
- other starts and old saves (13);
- the cabin floor (15).

`probes/camp/11` follows the loaded pod into a marked Home through a distant storm and a disk
resume. The capture is `look/surveyor_opening`. Captures that frame a run's surface start instead
take it through `look/surface_start.gd`, the developer `spawn` scenario with the run's own kit.

## Open

Hunter's playtest of comprehension and motion comfort. Survival odds and the default load
are provisional balance in Tuning.
