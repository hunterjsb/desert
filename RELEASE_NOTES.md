## 0.2.1-alpha “Sailboat” — release candidate

This patch gathers the current sand and Nomad gear work with playtest fixes.
Cross-platform publication is pending verification of the combined candidate.

- More depth and shade in dune sand and nearby ripples.
- Sand trails gain shaped depressions and rims that flatten the surrounding ripples.
- Nomad wrecks and camps with recoverable sailing gear, a streamer and a crow's nest.
- The dev console can open over any menu; unlocking origins updates the open menu.
- A crow's nest can be placed on a standing mast from deck height.
- The Varran's sheet ring rests on the deck, and waist ropes follow the rider's displayed movement.
- Shorter weather announcements, spoken when storm news changes.

### 0.2.0-alpha

The second alpha of a cozy survival game on a dead desert moon. Your home is a bubble
shield you carry with you, on a rig you build and tie down against the wind. Everything
is still rough: grey boxes, placeholder sounds, numbers still moving. It's here to be
played and broken.

## New since 0.1

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

## What's in it

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
4. Press **F1** for the keys list. It shows every key as it's bound now. **F11**
   switches fullscreen.

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
