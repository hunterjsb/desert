The first alpha of a cozy survival game on a dead desert moon. Your home is a bubble
shield you carry with you, tied down with rope against the wind. Everything is rough:
grey boxes, placeholder sounds, numbers still moving. It's here to be played and
broken.

## What's in it

- **The moon:** endless dunes that the wind reshapes, a day and night with the gas
  giant Tu overhead and its eclipses, and storms you can see coming as a wall on the
  horizon.
- **The camp:** a bubble shield that keeps the storm out, devices you build up by
  fitting parts into their sockets (batteries, hooks, hover trays, lamps), crates that
  stand on a deck, and a sail to move a camp across the sand.
- **Power:** solar panels, a wind turbine, batteries and cables, on a budget that has
  to last through night and storm.
- **Rope:** stakes, lines and reels to moor what floats and tow your camp behind you.
- **Survival:** water, food and a suit with five slots; a condenser that wrings water
  out of the air.
- **Salvage:** finds half-buried in the dunes, uncovered as the weather strips the
  sand, and ruins to walk into.
- **Farming:** planters that grow root-tubers in the clear and vat fungus in the
  storm's dark, wild saltbush, and a harvester that feeds you.
- **A hoverboard,** a radio with music, a weather station and beacons, and a console
  for your instruments.
- **Three origins** to come as (the Surveyor tows a camp, the Salvager rides light, the
  Homesteader stays put), each run in Normal, which saves as you go, or Ironman, where
  death ends the run.
- **The dev console and its scenarios** are left in, for jumping straight to a storm,
  a farm or a ruin. A scenario's run is never saved.

## How to start

1. Unzip the download for your computer and open the folder.
2. Start the game:
   - **Windows:** `Sandgame.exe`.
   - **macOS:** `Sandgame.app`.
   - **Linux:** `Sandgame.x86_64`. If it won't start, make it executable first:
     `chmod +x Sandgame.x86_64`.
3. Choose **New game**, pick who you come as, then **Normal**.
4. Press **F1** for the keys list. It shows every key as it's bound now. **F11**
   switches fullscreen.

You'll need a graphics card with Vulkan (Windows and Linux) or a Mac on macOS 13 or
later (Apple silicon) or 11 or later (Intel). The window and the app are called
Sandgame, the game's working title.

## Known issues

- **The builds aren't signed,** so your computer will warn you the first time:
  - **Windows** SmartScreen says "Windows protected your PC". Click **More info**, then
    **Run anyway**.
  - **macOS** says the app can't be opened because Apple can't check it for malicious
    software. Control-click `Sandgame.app`, choose **Open**, then **Open** again. On
    macOS 15 or later, try to open it once, then go to **System Settings → Privacy &
    Security** and click **Open Anyway**. Or, in Terminal, from the folder it's in:
    `xattr -dr com.apple.quarantine Sandgame.app`.
- **Saves may not carry over.** A later build that can't read this one's save says so
  on the main menu and leaves it alone; it never loads half a run.
- **It's an alpha.** Expect rough edges, odd physics in a hard storm, and balance that
  will change. Your save, your profile and the game's logs are in:
  - Windows: `%APPDATA%\Godot\app_userdata\Sandgame`
  - macOS: `~/Library/Application Support/Godot/app_userdata/Sandgame`
  - Linux: `~/.local/share/godot/app_userdata/Sandgame`

  The version is in the main menu's corner. Please name it when you report a bug.
