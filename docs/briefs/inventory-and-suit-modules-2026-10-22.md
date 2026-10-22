# Inventory and suit modules: three possible shapes

*Options for Hunter, 2026-10-22; no decisions or build approval, not 0.4 scope.
[Menus](../prd/menus-and-ui.md#inventory-and-suit-modules-open-design-2026-10-22)
owns the request. Master inspected: `de7bbe23`; pending `rest-buffs`: `d7eda8f2`.*

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

## Choose a shape

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

Power options: independent module cells, matching carried gadgets (simple, several
charges to manage), or one explicit suit battery bus (clear total budget, shared
failure). Either must meter real draw and visibly disable the powered function on
depletion. Built-in air/radiation protection and the headlamp stay free. Bag contents
must not gain suit-module effects merely by being carried; existing working radios
remain devices, not automatically installed modules.

Find portable colonial/skimmer equipment in appropriate salvage. Later-era fixed
installations remain destinations under the [era mobility rule](../prd/devices-and-mods.md#repairs-and-era-mobility-selected-2026-10-22).
Whether a detachable core can be recovered from one needs Hunter's explicit choice;
stowing must not bypass that rule. Neither new repair materials nor crafting follows.

Keep the recognizable ancestral body, fittings and marks across eras; show damage
through the shared wear treatment. **Era is history; wear is condition**, not four
upgrade colours. Rest buffs remain earned temporary stamina effects, not installed
modules, socket occupants or permanent substitutes for meals and shelter.

## Decisions before a build

Choose A, B or C; which physical inconvenience should it solve first? Which one suit
module demonstrates a useful new ability, where is it found, and can it be swapped
while moving? Choose independent cells or a suit bus, and whether fitted capacity
is limited. Set the boundary for extracting portable parts from later-era sites.
Playtest find → inspect → fit → use → power loss → remove → save/restore before
extending the system. Keep the pending rest-buffs contract intact.
