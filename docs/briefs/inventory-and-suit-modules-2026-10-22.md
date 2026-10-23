# Inventory and suit modules: answered concept

*Answered by Hunter, 2026-10-22. Direction selected; implementation and release timing
remain unassigned. Original code audit: master `de7bbe23`, pending rest-buffs `d7eda8f2`.
The historical options below are not separate competing choices anymore.*

## Hunter's answer and readings (2026-10-22)

Verbatim speech-to-text answer, relayed by SANDGAME:

> A, B and C was my actual vision. B is going to completely overhaul what inventory means. C. needs to feel really good and snappy and white is open you can see the objects physically. A. must be done at some pt. 2. start with headlamp. tarkove-style visual layour of your gear in tab. bring it on the pod. that way we can introdice that mecahnic on the ship. out suit is neotech. the only thing better than colonial. we have a nano-HeG3N and wont be a problem for years for 3. 4. yes some parts that make sense but not all the installations will have them

- **SANDGAME's reading, 1:** A, B and C together are the vision. The harness changes
  inventory fundamentally; the pack must feel snappy and show physical contents
  while open (“white” read as “while”); clearer carry presentation comes at some point.
  [Menus](../prd/menus-and-ui.md#combined-inventory-direction-and-first-module-selected-2026-10-22) owns this direction.
- **Reading, 2:** headlamp first; a Tarkov-style visual gear layout through the
  inventory action. Bring the module on the pod and introduce fitting aboard the
  ship ([opening](../prd/surveyor-opening.md#headlamp-fitting-on-the-ship-selected-2026-10-22)).
- **Reading, 3:** the suit is neotech, above colonial. SANDGAME reads “nano-HeG3N” as
  a nano helium-3 generator; the expansion is not a settled technical name. Power
  lasts years and is not a module constraint now. [Survival](../prd/survival.md#neotech-suit-and-modular-headlamp-selected-2026-10-22)
  supersedes the old free built-in headlamp; [lore](../world/lore-research.md#neotech-the-players-suit-hunter-2026-10-22) owns neotech.
- **Reading, 4:** recover portable parts from some suitable later-era installations,
  not all; their hosts remain fixed ([Devices](../prd/devices-and-mods.md#portable-parts-from-later-installations-selected-2026-10-22)).

Timing is undecided. Socket counts, pack mechanics and fitting constraints still
need design; no new milestone, build or launch blocker is authorized by this brief.

## The problem to test

[Suit](../../game/survival/suit.gd) carries real objects by weight, without a slot
count. Stacks retain individual objects; taking one needs empty hands, while using
food or a radio can happen inside the carry view. Carried devices work on their
own batteries out of sight. Small held things now sit low with a real grip
([Body](../../game/player/body.gd)); that improvement should survive any rework.

**Likely friction, not a playtest finding:** carrying, fitting and using look similar;
powered equipment can run invisibly. Modules risk making “in my bag” mean “installed
on me”. Test finding a charged tool, inspecting wear, drinking and identifying a
battery drain before adding management.

There are no five storage slots to preserve. Pending rest-buffs shows **health and
stamina plus Rested/Fed/Hydrated**: five ordinary status entries, with wounds added
when relevant. Its three timed buffs are not sockets; that branch is not yet master.

## Original shapes (now selected together)

| Option | Physical interaction | Tradeoff |
| --- | --- | --- |
| **A. Clarify the carry view** | Keep weight-limited stacks and real models. Separate carried objects from a small fitted-module view; identify the actual item, charge and wear before taking it. | Least disruption; faster selection, but most belongings remain hidden on the body. |
| **B. A visible harness** | Add a few visible attachment points for installed tools/modules; reach, unclip and hold the same object. Keep bulk supplies in the existing carry view. | Makes readiness and power legible; body occlusion, camera reach and accidental selection become substantial design work. |
| **C. A pack you set down** | A physical container unfolds for inspection and module swaps at shelter; keep a few supplies/tools reachable on the body. Everything remains a saved object with real mass. | Strong camp ritual and readable belongings; risks turning every item change into tedious unpacking and creates abandonment/recovery problems. |

All preserve holding, dropping and item identity. Limited **installed** capacity
is separate from carried weight, not a packing puzzle. The camp Console can explain
equipment/power but should not be required to access portable belongings.

## What a suit module would mean

**Proposed distinction:** a device mod changes its machine; a suit module fits the
wearer, providing optional thermal protection or sensing. A god module is a particular
mind with provenance, agency and obligations. Mountable gods are still a [proposed framework](../prd/devices-and-mods.md#god-modules-as-crate-modules-proposed-session-4-part-5-not-built);
keep their camp/Console relationship rather than silently making them wearable.

**Superseded options:** independent suit-module cells versus a limited suit bus were
not selected. Suit power should not be a constraint for years. The headlamp becomes
a fitted module; it no longer stays a free built-in in the selected design. Existing
carried-device batteries and camp power are not waived. Bag contents do not thereby
become fitted modules.

Portable colonial/skimmer salvage remains available; some later-era fixed sites may
also yield suitable portable parts. The host installation remains fixed, and not
every site has an extractable part. Neither raw-material crafting nor universal
core extraction follows.

Keep the recognizable ancestral body, fittings and marks across eras; show damage
through the shared wear treatment. **Era is history; wear is condition**, not four
upgrade colours. Rest buffs remain earned temporary stamina effects, not installed
modules, socket occupants or permanent substitutes for meals and shelter.

## Still open before a build

Timing and implementation order, physical fitted capacity, pack deployment and
swap constraints, and the particular extractable parts/sites. Start with the
headlamp and test find → inspect → fit → use → remove → save/restore. A suit battery
failure test is no longer the defining first loop; preserve actual camp/device
power behavior and the separately approved rest-buffs contract.
