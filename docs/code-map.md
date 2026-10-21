# Code map

Start with `vision.md`, then the relevant system PRD in `prd/`. This map points to the code that
owns the behavior and the probes that exercise it. Paths below are relative to the repository.

| System | Entry points | Checks |
| --- | --- | --- |
| Boot and runs | `game/main.gd`, `game/run.tscn`, `game/world/world.tscn`; `game/survival/runs.gd` starts runs from `kit.gd` and the kit resources | `probes/foundation`, `probes/saves` |
| Tuning and controls | `game/core/tuning.gd`, `game/tuning.tres`; `game/core/controls.gd` owns bindings and action text | `probes/dev`, `probes/menus` |
| World coordinates | `game/world/world.gd`: `height_at`, `teleport`, `world_x`/`world_z`, `engine_x`/`engine_z`; the engine origin moves while world coordinates stay fixed | `probes/world` |
| Ground and streaming | `game/world/terrain_shape.gd` owns `height_at` and dunes; `terrain_residency.gd` shares ground/collision retention rules with world-body culling; `terrain.gd` schedules work; `chunk_build.gd` builds worker arrays; `terrain_chunk.gd` owns uploaded meshes and collision; `far_ring.gd` extends the horizon | `probes/world`, `look/stream`, `look/dunes` |
| Sand and tracks | `game/world/sand.gdshader`, `terrain_shape.gd: shade`, `game/world/tracks.gd`; captures and paired GPU timings in `look/sandlight` | `probes/world`, `probes/movement`, `look/sandlight` |
| History and sites | `game/history/history.gd`, `site_kinds.gd`, `eras.gd`; `game/world/sites.gd` lays and holds nearby sites | `probes/history`, `probes/kits` |
| Halloran and the Stoker | `game/story/halloran_kit.gd`, `halloran_site.gd` build Aitch, the Crossing and refinery ground; `stoker.gd` owns physical furnace interactions, with run state in World/Snapshot | `probes/history/7_halloran_on_the_moon.gd`, `probes/kits/10_halloran_ground.gd`, `probes/kits/11_halloran_first_fire.gd`, `probes/saves/39_stoker_stock.gd`, `look/halloran` |
| Ruin geometry and exposure | `game/salvage/kits/structure_kit.gd` defines pieces, rooms and sockets; `structure.gd` presses them into the ground and follows `exposure.gd`; era kit files define the actual structures | `probes/kits`, `probes/salvage` |
| Loot and wrecks | `game/salvage/site_loot.gd: draw/plan` chooses a site's finds; `finds.gd: make/pose/bounds` builds and places them; `salvage.gd` streams and claims them; `kits/wrecks.gd` defines wrecks; `StructureKit.fitted_box` adds matching oriented solid details | `probes/loot`, `probes/wrecks`, `probes/salvage` |
| Devices and decks | `game/devices/catalog.gd` creates devices and parts; `device.gd` owns sockets, mounts and pooled mass; `chassis.gd`, `stick.gd`, `rig.gd` assemble a camp | `probes/devices` |
| Hands, movement and board | `game/player/player.gd`, `hands.gd`, `ledge_vault.gd` (swept on-foot ledges), `feel.gd`, `tumble.gd`; `game/board/ride.gd` handles riding and caches reachable static support faces | `probes/movement`, `probes/devices` |
| Rope and towing | `game/rope/rope.gd` simulates a line; `ropes.gd` coordinates ropes in the world; sailing and board movement consume their loads | `probes/rope`, `probes/sail` |
| Sailing and mast mounts | `game/sail/mast.gd` owns sail force, sheet, boom, halyard and mast faces; `manual_winch.gd` winds a tied ordinary line; `helm.gd` seats and steers; `crows_nest.gd` seats a lookout; `game/devices/streamer.gd` reads felt wind; `game/sail/sailing_notes.gd` teaches sailing through physical notes | `probes/sail`, `probes/devices`, `look/nomad`, `look/varran` |
| Weather and vents | `game/weather/weather.gd`, `weather_field.gd`; `rumbles.gd` schedules vent sound and tremble; `game/player/feel.gd` applies felt motion | `probes/weather`, `look/rumble` |
| Radio and the Walker | `game/radio/radio.gd` owns tuning, marks, reception and its speaker; `radio_speech.gd` and `voice_words.gd` assemble bundled native speech; `survey_receiver.gd` owns directional ruin pickup; `transmissions.gd`, `gods.gd`, `walker.gd`, `city.gd`, `city_lights.gd`; `game/devices/chart.gd` reads bearings | `probes/radio`, `probes/devices/30_the_console_says_its_battery_is_low.gd`, `look/walker`, `look/dial` |
| Satellites and radio interference | `game/radio/constellation.gd` defines the roster, carriers and schedules; `satellite.gd` owns orbital motion; `sky_voices.gd`, `garble.gd` and `glitch.gd` own per-radio satellite playback and effects; `game/weather/sky_view.gd` and `sky.gdshader` draw the sky | `probes/radio/32_the_constellation.gd`, `probes/radio/34_always_two_overhead.gd`, `probes/radio/35_the_irregular_ones.gd`, `probes/radio/37_the_jammer_and_the_burn.gd`, `probes/radio/38_round_tu_and_skimming_low.gd`, `probes/radio/40_radios_do_not_change_each_others_sound.gd`, `look/satellites` |
| Surveyor flare and deliveries | `game/survival/flare.gd` owns lighting, burn time and the one-time call; `game/salvage/airdrop.gd` owns the cannon, trajectory, impact, empty cargo and release; `game/saves/snapshot.gd` restores active drops and flare state | `probes/salvage/9_the_surveyors_care_package.gd`, `probes/salvage/10_the_surveyor_forced_over.gd`, `probes/saves/37_a_flare_keeps_its_call.gd`, `probes/saves/38_a_delivery_survives_loading.gd`, `probes/saves/40_a_flare_records_its_delivery.gd`, `look/airdrop`, `look/flare` |
| Survival and carried gear | `game/survival/suit.gd`, `kit.gd`, `runs.gd`, `bedroll.gd`, `inventory_look.gd` | `probes/survival`, `probes/saves`, `look/bedroll` |
| Power, water and farming | `game/power/power.gd`, `power_box.gd`; `game/water/`; `game/farming/farm.gd`, `planter.gd`, `plant.gd`; `game/shield/` holds weather out | `probes/power`, `probes/farming`, `probes/shield` |
| Menus and pictures | `game/ui/ui_root.gd`, `creative_grid.gd: GROUPS`, `deeds_grid.gd`, `item_icons.gd`, `page_bar.gd`; `game/look/dress.gd` and themed look builders draw catalog gear | `probes/menus`, `probes/dev` |
| Saves and deeds | `game/saves/snapshot.gd` captures run state; `deeds.gd: TABLE` defines deeds; gameplay systems record the action when it happens | `probes/saves` |
| Desktop launcher | `launcher/main.py` installs published releases and launches local Git worktrees; `.github/workflows/launcher-release.yml` packages the launcher | Standalone app; see `docs/prd/launcher.md` |

Probe hosts and system helpers live in `probes/lib/`. Use the nearest existing helper and a
targeted probe for the failure being fixed. `scripts/probe.sh` imports assets before running;
`scripts/verify.sh` handles whole-suite CI and landing. `AGENTS.md` describes the shared worktree,
locking and capture rules.
