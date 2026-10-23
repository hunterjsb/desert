## 0.3.1-alpha “Leeward Sanddune” — development, unreleased

- Compare your heading and sail trim with an ideal on the Console Map's Nav layer.
  A sheet tied to a hand winch can be trimmed by the powered Console; a supported,
  occupied helm can steer toward the chosen course or Home through its existing
  controls. Manual input takes priority; the aid adds no sailing force.

- Make sailing and towing respond at the real rope and hull centres. The sail follows
  its physical halyard, the board motor stays consistent across power ticks, and the
  old magic sail toggle is gone.

- Add main-thread CPU budgets for 108-frame sailing, capsized and remote Home
  camps. Batch tipped-contact ground reads while preserving contact order and
  live impulse response. Admit the measured heavy Home camp with a 272-item cap,
  guarded by the existing one-millisecond upkeep budget.

- Keep distant Home support current as the world shifts: rebuild it only when
  needed, build nearby collision first, and keep collision under a camp that
  outruns its ground. Home's state stays with its beacon.

- Make the survey receiver appearance replaceable independently of gameplay,
  retaining its current procedural model, wear, controls and saved identity.

- Fit either original roof panel to either pod roof bay and launch with it in
  place. Loose roofs close into the remaining free roof faces. Invalid placements
  identify their actual host/face and explain the intended destination.
- Keep the real crawl route through the opened hatch clear after impact.
  Obstructing cargo breaks loose as its original recoverable assembly, preserving
  fitted batteries and both rope ends instead of trapping the player.
- Keep the Surveyor opening on one forecast and flight path, explain launch blockers
  together, and make a ready cabin launch reliably. See Tu from orbit, keep the pod
  clear in space, then see the scatter on landing with room to lie down.
- Add real glazed side and roof panels, free mouse look while falling, stronger
  phase-driven flight sound and bounded turbulence. Looking does not steer the pod.

- Inspect a live Cargo view on the physical launch computer before departure. It
  reports which original items are aboard, held or misplaced without moving them.
- Fix saving recovered camps after removing custom mounts from joined chassis.
- Avoid a redundant zero-motion projection in large craft contact work; a
  controlled 108-piece camp measured about 3.4% lower settled CPU time.

- Add the passive crystal set, new field-radio looks, coloured band windows and
  powered receiver modules. Reorganize AM/FM/shortwave broadcasts around their
  updated carriers, including wreck distress and the tower weather/schedule. Hear
  the Walker on FM, and bring the relay's music back.
- Align the printed AM/FM/shortwave dial marks with actual tuning and needle travel.
- Fly a radio antenna aerial from its reel and route its lead through a stake
  for grounding. Static charge, wear and damaged leads affect reception. The
  traction kite remains a separate Spaceport feature.
- Rename the delivery craft to the deliveryship and raise its pass; keep the
  former drone/surveyor developer commands and scenarios as aliases.
- Migrate old survey-receiver frequencies while preserving their detuning,
  charge and switch state. Reset queued speech on actual station changes and
  require power for the counter and logger modules.
- Keep the aerial aligned through world recentering and disconnect a ruptured
  strong lead from reception and grounding. Remove the clipped footstep sample.
- Call a deliveryship care package with a signal flare and recover its contents
  after it lands clear of your camp.
- Fold the Console's Survey and Chart pages into one Map with weather, survey and
  navigation filters.
- Grow coalcane from cuttings and burn the harvest for camp power through the night
  and storms; earn Night Harvest for powering the camp.
- Storms leave visible wear on struck parts, and worn parts produce less. Repairs
  are not available yet.
- Add Quiver for riding every board make, On Reserve for powering camp from a
  battery, and Nomad after earning a deed in each of Wind, Weather, Ruins, Signals
  and Far.
- Carry small things low and close, out of your face, with the gloves gripping
  them; push one out ahead or bring it back in as before. A radio comes up to
  read while you tune it.
- Import a source checkout before the launcher starts it, so Godot refreshes its
  script cache; published game builds launch directly.

Existing run/profile formats remain supported. The escape-route repair applies
when impact materializes; already recovered camps are not rearranged on load.
The AM dial and station allocation change; full-radio frequency marks retain
their recorded frequencies. Natural-radio listening and the Whistler deed are
retired, with existing profile completion data retained. Published 0.3.0 remains
unchanged. This patch is not yet published.

## 0.3.0-alpha “Sanddune”

A physical Surveyor departure, a camp you can find again, and more grounded
movement, ropes and radio. Published for ongoing playtesting; fixes will follow
as Sanddune patches.

- Walk the Surveyor carrier, load actual equipment into a reusable chassis pod,
  and launch from its seat. Required stores and structural blockers are explained
  at the computer and before boarding.
- Read the always-on physical launch screen, smoothly focus it, and drag one
  departure pulse over a rotating globe. The forecast, cabin window and flight
  share the same saved clock and path; there are no numeric angle controls.
- Stay in first person through ejection, descent, atmospheric heating and impact.
  Loaded gear remains visible; recover surviving equipment nearby and dismantle
  the pod's ordinary panels into your first camp.
- Give the cabin sheltered industrial materials, a marked pod bay and a closer
  planetary horizon. The pod has a real recoverable glazed viewing panel.
- Share lore-scale curvature between distant ground, sky, storms and the delivery
  drone. Compressed travel distance and the 20-minute day remain unchanged.
- Improve chassis-height boarding vaults and body poses, keep the torso out of the
  ridden-board view, and wrap the visible tether around the suit's waist.
- Publish a GitHub Pages performance observatory with probe retries, build costs,
  artifact sizes and headless streaming, rope and memory measurements.
- Speed up probe iteration with accelerated ruin traversal, native scheduling for
  expensive terrain checks, and fresh CI duration history. Package desktop builds
  faster with light ZIP compression.
- Begin new Surveyor runs in orbit, descend in a recoverable chassis pod and
  collect seeded surviving physical equipment. Other origins, developer scenarios
  and legacy saves retain their existing starts. During a fully eclipsed landing,
  the recovery notice points out the suit headlamp using its current binding.
- Mark one chassis as Home with a physical beacon. Its claimed camp retains bounded
  terrain, collision and history while you scout; ordinary power and weather keep running.
- Open Home from the carry view for distance, bearing and live or last-known reception.
  The Surveyor opening supplies a beacon; surface salvage can supply one too.
  Returning from a scouting trip records Home Again.
- Save and resume distant camps without discarding their excavation or exceeding
  the support budget. Overstretched camps keep their objects and report unsupported ground.
- See the Surveyor suit in first person: boots, posed legs and arms, with a full
  external model and shadow. Held-item hand reach remains preliminary.
- Sit on supported ground or lie down and crawl with physical low clearance.
  Getting up checks headroom; wind, ropes, slopes and moving decks still move you.
- Offer the existing safe sleep choices while lying still with empty hands.
  Posture survives saves, and the first ground rest earns A Moment's Rest.

- Continue holding Use to untie successive waist lines into a knot in hand, then
  anchor, retrieve or drop it normally. Select each original member in the carry
  view; lengths and routes survive saves. Securing multiple lines earns Make Fast.
- Continuously unwind and gather the rope coil while preserving its gauge and
  held-end attachment.
- Resolve capsized mast contacts against the mass response of the hull and hinged
  boom, preserve support while applying friction, and support capsized decks on
  their actual frame edges. Keep the existing upright runner clearance.
- Read current controls directly from the system menu or Options in a bounded,
  scrollable page. Remove the separate keys overlay and its persistent footer.
- See Frontier Ag's crop survey as a full model 6 km up: faceted nacelles, solar
  arrays and its care-package cannon, lit by the sun and the sand below and
  hazed by the air between. Its care packages fall for 30 s from the new height.
- The crop survey now passes over Port Morgan every lap, its route swinging round
  the moon. Port Morgan Control Tower reads its schedule on FM every 5 minutes:
  speed, altitude and when it's next over the port. Hearing it earns Flight Plan.
- Fit FM and shortwave converters to the radio and switch bands. FM brings Port
  Morgan's station by line of sight and the relay's music; shortwave carries the
  satellites and Tu's roar, clearer on an antenna reel's strung wire.
- Find a station's direction by the ferrite rod's null, and hear natural radio's
  sferics and whistlers at the bottom of the AM dial on a long wire.
- Fewer satellites, each on its own orbit: about two cross the sky at once.
  New deeds: Line of Sight, Storm on Tu, Long Wire, Null and Whistler.

### Compatibility

- Existing 0.2.4 run saves and profiles remain supported; no reset is required.
  Older Surveyor runs retain their existing start. Start a new Surveyor run to
  experience the carrier and pod opening.
- Preparation, seated, in-flight and recovered pod saves preserve the selected
  course and original equipment. Loading does not reroll the start or grant a
  second kit. Unsupported old save formats are still refused without overwriting.

### Current limits and verification

- Sailing balance, launch-screen comprehension, camera comfort and long-run camp
  performance remain active playtest work. This release does not close those gates.
- Kites, deeper suit/wrist instruments and broader origin variants remain for
  Spaceport. The carrier uses a bounded powered survey loiter and a one-pulse
  gameplay trajectory; it is not a full orbital flight simulator.
- Scenario runs do not save. Use Normal runs to test persistence.
- The shipped runtime passed all 21 Linux, native Windows/macOS and exported-build
  checks. Connected input/save checks and actual Forward+ and Compatibility
  captures were reviewed. The release pipeline repeats full checks on the tag
  and smoke-tests all three packaged builds before publishing.

## 0.2.4-alpha “Creaky Sailboat”

A manual sail hoist, physical salvage rewards and clearer radio handling.
Includes the sailing, traversal and exploration baseline described below.

- Raise and lower sails with a fitted hand winch and a real halyard over the masthead.
  Starter and found rigs supply the hardware; fully hauled sails retain wind-deed progress.
- Remove fitted sails and board rope ends, and recover loose ropes without losing anchors.
  Previously owned and older loose coils open into usable rope when picked up.
  Remaining coils follow the active paying end and use layered rope windings.
  The authored yacht uses visible ballast, four hover trays and two centreline keels.
- Show tuning controls in the radio close view and give stations distinct machine voices.
  New reports discard interference fragments left over from the previous playback.
- Pick up Halloran coalcane normally and unlock a physical service cache after the burn.
  Homes, refinery fittings and the connected pipeline gain modeled detail.
- Add a short illustrated hoisting page to the sailing notes.
- Reach Starcom's relay mountain and the far-side observatory volcano: hazy distant
  silhouettes become real slopes, colonial galleries and salvage when approached.
  The existing volcanic plume rises from the mountain's flank.
- Storm-stripped ruins refill more slowly in calmer air, leaving a short window to
  investigate after the dust clears. Strong storms can still bury them again.

## 0.2.3-alpha “Sailboat”

*Tagged, never published; 0.2.4-alpha shipped it (as with 0.2.2-alpha).*

Physical sailing controls, clearer radio reception, and a first encounter at Halloran.

The 0.2.2 and 0.2.3 tags remained unpublished candidates. The first failed its
verification gate; the second was withheld after a repeat-report interference bug
was reproduced. Version 0.2.4 includes their scope and fixes that bug.

- Select waist lines by hovering and clicking in the carry view. A single line reels
  without selection; release all uses timed progress and preserves momentum.
- Sailing booms turn on physical hinges, constrained by real sheets and routed lines.
  Fit hooks to clear surfaces, route ropes through them, and yank a worked line for
  a quick tug. Four short illustrated pages replace the long sailing tutorial.
- Skates, hover parts and keels can share decks where they physically fit. Vault onto
  reachable ledges and moving decks with a climb scaled to the ledge height; exposed
  wreck roofs provide solid walking and hoverboard surfaces.
- Fix distant stake placement, depleted-deck hover shutdown, freed rope selections,
  and frame-rate-dependent ridden-board battery use.
- Radios gain station marks, independent sound effects and steadier carried audio.
  Scheduled songs keep playing through mixer/world-clock drift instead of restarting under load.
  Bundled weather, god and beacon speech works without an external voice service.
- Thirteen satellites broadcast overhead. Signal the delivery drone with a flare to call
  a cargo drop; active deliveries and used flares survive saving and loading.
- Explore Halloran's lower homes and Crossing, feed the Stoker's maintenance furnace,
  and claim a finite service cache after the burn. Fuel, burn progress and rewards persist.
- Add a directional survey receiver, a physical Surveyor's Guide, a playable
  Archaeologist kit and a personal shield for the Salvager start.

### Limits recorded for 0.2.3 (historical)

- Drone cargo containers are empty; supply contents are not implemented yet.
- The Halloran maintenance burn is a bounded encounter, not a portable generator,
  sustainable fuel loop or completed ending.
- Kites, camp beacons and keeping distant camps loaded remain planned work.
- Scenario runs do not save. Use a Normal run to test persistence.

## 0.2.1-alpha “Sailboat”

Richer sand and trails, recoverable Nomad sailing gear, and fixes from sailing playtests.

- More depth and shade in dune sand and nearby ripples.
- Sand trails gain shaped depressions and rims that flatten the surrounding ripples.
- Nomad wrecks and camps with recoverable sailing gear, a streamer and a crow's nest.
- The dev console can open over any menu; unlocking origins updates the open menu.
- A crow's nest can be placed on a standing mast from deck height.
- The Varran's sheet ring rests on the deck, and waist ropes follow the rider's displayed movement.
- Waist lines show the selected line's name, length and tension; reeling and untying work that same line.
- The board can catch up on slack lines and carry momentum around a sailing rig. Motor assistance is limited under load; heavy towing grounds it and makes it sputter until you ease off.
- A physical sailing field guide in the sail scenario explains wind, trim, steering and the Varran bridle.
- Shorter weather announcements, spoken when storm news changes.

## 0.2.0-alpha

The second alpha of a cozy survival game on a dead desert moon. Your home is a bubble
shield you carry with you, on a rig you build and tie down against the wind. Everything
is still rough: grey boxes, placeholder sounds, numbers still moving. It's here to be
played and broken.

### New since 0.1

- **The chassis is the one structure.** Crates and slots are gone:
  - Anything sticks on a chassis's faces, and frames take walls and shelves.
  - Hover trays lift toward the sand they face.
  - Everything on a deck shares one power pool.
  - Walls and fabric catch the wind and shelter what's behind them.
- **Power boxes** come in four makes, from a colonial cabinet to a temple shrine. Each bay has
  a light strip, and a Console ranks and switches devices as far as the box allows.
- **Sailing for real:**
  - The sheet is a line you haul in and ease out, and the cloth shows its trim.
  - With a helm and a keel, a camp sails as a land yacht.
- **The hoverboard** skids on hard carves, lands hard, crashes, and comes in four makes.
- **Deeds:** 40 of them in eleven trees, earned in play with a bell and a badge. Four starts
  open by deeds.
- **Two new starts:**
  - **The Varran settler** flies a kite rig with his board as its keel.
  - **The Archaeologist** digs ruins out of the dunes.
- **Dune archaeology:**
  - Storms strip windward faces and bury the lee.
  - Big dunes hide ruins that a big storm bares.
  - A Console's ground radar maps what's buried, and a scoop and a sieve dig it out.
- **Wrecks** to cut open seam by seam, with live hazards to make safe first.
- **The anomaly:** a rare storm the forecast can't see, and the tells that give it away.
- **Vents and plumes:** sand columns that tower over the storm walls from far off, and booms
  that arrive after you see the burst.
- **Sightlines:** ruins on the horizon, true to size, catching the light.
- **Sleep** in a bedroll to skip a night or a storm, and **auto-walk** for the long haul.
- **The radio:**
  - Its storm reports come in a recorded voice.
  - Seven gods broadcast on its dial.
- **Sand that reads as sand:**
  - lopsided ripples;
  - grain at your feet;
  - grainflows down slip faces.
- **A creative menu** in the dev console, to build anything in a test run.

### What's in it

- **The moon:** endless dunes that the wind reshapes. A day and night with the gas giant
  Tu overhead and its eclipses, and storms you can see coming as a wall on the horizon.
- **The camp:**
  - a bubble shield that keeps the storm out;
  - chassis pieces you join into a deck, with hover trays, frames and walls;
  - whatever you find stuck on it: devices, batteries, hooks, lamps, a sail.
- **Power:** solar panels, a wind turbine, batteries, power boxes and cables, on a budget
  that has to last through night and storm.
- **Rope:** stakes, lines and reels to moor what floats and tow your camp behind you.
- **Survival:** water, food and a suit with five slots, and a condenser that wrings water
  out of the air.
- **Salvage:** finds half-buried in the dunes, ruins to walk into, and wrecks to cut open,
  all uncovered and buried again as the weather moves the sand.
- **Farming:** planters that grow root-tubers in the clear and vat fungus in the storm's
  dark, wild saltbush, and a harvester that feeds you.
- **Gear:** hoverboards, a radio, a Console for your instruments and maps, and a compass that
  Tu's field and the ground pull off north.
- **Five origins:**
  - the Surveyor tows a camp;
  - the Salvager rides light;
  - the Homesteader stays put;
  - the Varran sails;
  - the Archaeologist digs.

  All but the Surveyor open by deeds. Each runs in Normal, which saves as you go, or
  Ironman, where death ends the run.
- **The dev console and its scenarios** are left in, for jumping straight to a storm, a
  wreck or a vent. A scenario's run, or any run a dev command has touched, counts no deeds.

## How to start

1. Unzip the download for your computer and open the folder.
2. Start the game:
   - **Windows:** `Desert.exe`.
   - **macOS:** `Desert.app`.
   - **Linux:** `Desert.x86_64`. If it won't start, make it executable first:
     `chmod +x Desert.x86_64`.
3. Choose **New game**, pick who you come as, then **Normal**.
4. Open **Controls** from the pause menu or Options for the current bindings.

You'll need a graphics card with Vulkan (Windows and Linux) or a Mac on macOS 13 or
later (Apple silicon) or 11 or later (Intel).

## Known issues

- **The builds aren't signed,** so your computer will warn you the first time:
  - **Windows** SmartScreen says "Windows protected your PC". Click **More info**, then
    **Run anyway**.
  - **macOS** says the app can't be opened because Apple can't check it for malicious
    software. Control-click `Desert.app`, choose **Open**, then **Open** again. On
    macOS 15 or later, try to open it once, then go to **System Settings → Privacy &
    Security** and click **Open Anyway**. Or, in Terminal, from the folder it's in:
    `xattr -dr com.apple.quarantine Desert.app`.
- **Saves from 0.1 don't load,** since the camp is built differently now. Your settings
  carry over.
- **Saves may not carry over between later builds either.** A build that can't read a save
  says so on the main menu and leaves it alone; it never loads half a run.
- **It's an alpha.** Expect rough edges, odd physics in a hard storm, and balance that
  will change. Your save, your profile and the game's logs are in:
  - Windows: `%APPDATA%\Godot\app_userdata\Desert`
  - macOS: `~/Library/Application Support/Godot/app_userdata/Desert`
  - Linux: `~/.local/share/godot/app_userdata/Desert`

  The version is in the main menu's corner. Please name it when you report a bug.
