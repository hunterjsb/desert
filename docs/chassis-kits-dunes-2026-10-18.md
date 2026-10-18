<!-- Hunter's spec, 2026-10-18, as given; its open questions answered by the coordinator in the PRDs it folds into. -->

# Desert: Chassis, Kits & Dune Archaeology Spec

Oct 18, 2026 · @Hunter Boyd

## Overview

The crate and most slots go away: chassis become sticky surfaces you place anything on freely, frames add height, and a power box holds the batteries. Prompted by playtest feedback from Hunter's brother, who wanted a board he could just stick things to.

Goal: camps feel truly the player's own, with freeform layouts and stations (power, weather, workstation) instead of filled slots. This doc also collects the kits, sailing and nomad gear, and dune archaeology decided since the last spec.

Pillars still apply: physics-first, no NPCs or exposition, no one-off exceptions.

## Chassis, decks and frames

The chassis becomes the one structural piece: a sticky square you tile, tow by its edge rings and place things on freely.

| Term | What it is |
| --- | --- |
| Chassis | One 1 m square piece. Whole top (and bottom) is a sticky surface; edge rings join pieces and take ropes |
| Deck | Several chassis joined edge to edge into one rigid body (player-facing term; already in code) |
| Frame | An open cube that sits on a chassis and takes a chassis on any of its five remaining faces |
| Vertical | Internal term: a chassis standing upright on a frame's side (a wall to the player). Raised horizontal = shelf |

### Rules

- **No more slots.** Remove the crate entirely and the chassis's single deck mount. Top slots are gone everywhere.
- **Sticky surfaces.** Anything sticks anywhere it fits. Limits are space (no clipping) and the trays' lift; overloaded, it simply won't hover or drag.
- **The only remaining slots are plugs:** electrical plugs and water taps. Battery slots exist only on the power box.
- **Hooks:** removed from everything except planters and chassis edge rings.
- **Hover trays** stick onto chassis rather than living on every device. Open: whether a tray on a vertical lifts sideways or only works facing down.
- **Tall devices** (Console, condenser) don't fit in frames; they stick straight onto a chassis.
- **Standalone devices:** planter and turbine stay as they are.
- **Stacking:** an upper chassis can't rest on devices; it needs a frame under it. Weight is already self-limiting via trays.
- **Whole-face pieces** on a frame: a chassis, a screen/HUD, or fabric (a crude sail).
- **Saves:** need a total rework for freeform placement; format is the agent's call.

## Placement

Controls stay exactly as today; only the freedom is new.

- Hold an item and it snaps onto the chassis surface you're aiming at, horizontal or vertical. Press E or let go and it stays.
- Hold right click and pan the mouse to rotate, as now.
- **The preview is the real item**, not a ghost, as the game does today. Ghost preview only as a fallback if that causes issues.
- While held, the item is **non-solid**, so it never shoves things on a cluttered deck.
- **Tint it red** where it would clip, and optionally a small hint at the crosshair ("blocked", "too heavy"). The player should never wonder why it won't place.
- Gentle snapping to surface edges and neighbouring items so rows line up; rotation snapping is open.
- Taking a piece off a cluttered deck must select that item, not grab the whole deck (dragging a deck never takes it apart, as today).
- The goal is smooth, fun and tactile.

## Wind on faces

Every vertical and fabric face is a flat plate that catches wind, simulated as close to real life as possible, but cheaply: no cloth sim, no new bodies or joints.

- **Force:** per face, from its area and how squarely it faces the wind (mostly drag; some side lift when angled), applied at the face centre on the one rigid body it belongs to. Extends the existing per-device wind face area.
- **Verticals** catch wind and also shelter what's behind them, like a small dune: edge-on to travel, broadside as a windbreak when camped. Could feed the existing lee/shelter system.
- **Fabric faces** act as a crude sail: works on any side, but weakly, since it can't billow or be trimmed. A real sail stays the upgrade.
- **Occlusion:** sort a rig's faces along the wind; a face with another face directly upwind within its footprint catches only a fraction. No ray casts.
- **Scoops:** judge each frame by which faces are filled and where its open side points. Open side upwind with the back closed catches more (parachute effect); open side downwind shelters the inside.
- **Visuals:** fabric ripples realistically via a vertex shader: slack flutters, loaded goes taut and bellies out. Drive it from the same force the physics uses so the look always matches. The existing sail can share the shader.

## Power

Battery slots leave every device; batteries either stick loose on a chassis or live in a power box. Everything on one connected deck shares one pool automatically.

- **Shared pool:** anything on the same deck, loose batteries included, is on one pool. Cables (and hoses) are only for reaching other bodies, like a turbine staked on the sand. They still drag, but are much weaker than rope, so it's a risk.
- **Early game:** one chassis with a tray, a loose battery, a solar panel, the shield and the bedroll stuck on top. No power box needed.
- **Power box:** the upgrade. Many battery bays, each able to charge or supply, with a clear indicator of which. Must look good and read at a glance (e.g. a light strip per bay showing direction and fill).
- **Console:** its electronics screen mirrors the box with exact numbers. With a Console you can set priorities and switch devices off; subgrids maybe later.

### Era models

Power boxes come in sizes and era models. Nomads have none; they use whatever older chassis, frame or rack they scavenged.

| Era | Character |
| --- | --- |
| Colonial (Tilg/RMC) | Big clean industrial cabinet, many bays, precise readouts, full Console integration; rare and heavy |
| Skimmer | Bodged rack of mismatched bays, some dead; high capacity, shared pool only, no priority control |
| Second age | Temple-made, few bays, ornate casing; works, but crudely |
| Modern (company issue) | Small, light, about four bays, clean but built to a budget |

The era descriptions are a first riff and need Hunter's sign-off.

## Balance and flipping

Centre of mass is now a real, intended challenge: how many chassis need trays, where they go, the rig's shape, what's heavy, and what will flip it. Flipping should be brutal but fair.

- **No new balance UI.** The existing balance system (frame sagging and so on) already communicates it.
- **Righting a rig uses existing physics:** haul it over with a rope, or drag it (E) while left-clicking to punch it for small shoves.
- A big, badly built rig flipped in a storm may not be recoverable by hand. That's on the player; they can still strip it down and rebuild it upright.
- Things falling off in storms or crashes is deferred.

## Starts

Every start must be reworked around chassis, and two new kits are added: the archaeologist and the Varran settler. Balance targets the surveyor only; salvager and homesteader stay deed-locked.

### Surveyor (reworked)

Two base chassis joined as a deck, plus a frame with a vertical on its side, with gear stuck on so the player learns the whole system by sight: a battery, the shield, maybe a compass, and the hoverboard hanging on the vertical (if he keeps one).

### New kits

| Kit | Who | Starts with | Unlock |
| --- | --- | --- | --- |
| Archaeologist | A woman on a Daventry-funded university expedition, hunting evidence of war and destruction: proof of why humanity must be careful | The full archaeology setup: ground radar on a Console, a digging tool, sifting gear | Two deeds: assemble a full archaeology setup; dig a ruin out of a dune. Both should be fairly hard |
| Varran settler | Imperial settler who trusted tech over the land | Minimal fast sailing rig plus an out-of-place heavy navigation computer with rich wind and storm info; two batteries; small shield carried with its own battery, raised around himself in storms; rides a hoverboard as the keel | Build and use a dune sailboat |

**Archaeologist lore:** Zan only partly fits Daventry's story. The hive-mind war mattered, but abandonment, bureaucratic oversight and human factors really killed it.

**Varran notes:** the shield never goes on the sail, since a bubble there would block its own wind. He likes storms for the wind. A solar panel on top only if that's possible; otherwise there's no power gen and upgrading is the player's job. Open: whether the chassis and computer outside the bubble wear down in long storms.

## Sails and nomad gear

Nomad tech is a new, previously neglected gear tier, and it's how players get sails, which exist in game but can't be obtained anywhere yet.

### Nomad tier

- Common gear, found all over, even in open wilderness away from the main routes. Ruins give power and tech; the wilderness gives mobility.
- **Wrecked nomad rigs** are the common source. Nomads also leave gear inside other eras' wreckage, since they loot just like the player.
- **Active nomad camps** exist but are really rare (the moon is presumed empty). Nobody's ever home; they've always just left. A camp has a rig they actively maintain, with decent sailing gear and equipment from any era, chassis included, all lootable.
- Nomads have no power box; they use whatever older frames and racks they've scavenged.

### Sail sources (first pass)

- Take a sail off a broken nomad rig: a new wreck site that always carries one.
- Occasionally a sail lies in second-age ruins (low weight in the second-age loot table).

### Wind streamer

- A scarf or streamer that points downwind; how hard it flaps shows strength. Works in hand or inventory like the compass, and can be stuck onto a rig.
- Mounted, it's a telltale for trimming the sail. Part of the sailing setup. The anemometer stays the precise upgrade.

### Sail mounts and crow's nest

- Things should mount on the sail's mast, generically (with top slots gone, that's a sticky spot on the mast). Heavy things up high raise the centre of mass.
- **Crow's nest:** a mast mount you climb into. It counts as a seat and gives a long view for spotting glints, plumes and storm fronts.

## Dunes, ruins and storms

Marry the existing lee, drift and exposure systems so camping beside a big dune becomes an archaeology playstyle: let the ruins come to you. Most parts exist; they just don't talk to each other.

### What exists

- `weather/lee.gd`: shelter downwind of crests, strongest under the slip face.
- `salvage/drift.gd`: staked lines catch wind-borne loot, lee-boosted.
- `salvage/kits/exposure.gd`: sites strip in storms and rebury in calm, from storm strength only, with **no dune or lee term**.
- Dunes in `world/terrain_shape.gd` are static (no migration). Collectors are specced and awaiting implementation.

### Changes

- **Dune term in exposure:** scale stripping by position: more on the windward face and crest, more burial in the lee. Stays stateless.
- **Dune ruins:** a seeded generic ruin per big dune, uncovered only past an intense-storm threshold, so nearly every big dune yields something in a big storm. Seeded, not spawned on player detection, to keep the world stateless and save-safe.
- **Loot over the crest:** in storms, light loot should also fall out in the lee of crests near camp, not only at staked lines.

### Three ways to play a storm by a dune

1. Hike or board up to the windward crest mid-storm for medium loot.
2. Stay in the lee and let light loot blow to you.
3. Wait it out and dig the exposed ruin afterwards.

### Storm chasing (the hover punk)

Same high-tier path as braving storms, but metered: chasers hit many freshly exposed sites in the window before reburial, so it's volume over depth. No new loot table.

### Lazy loading (performance)

The fast player must never stutter on features they ignore. Buried sites cost nothing at chunk load: just a seed, no geometry or loot. Exposure checks run on a low-priority background queue sorted by distance, so a fast mover's queue never reaches them. A site builds only once uncovered and the player has slowed down nearby. Check first whether `structure.gd` builds buried sites today.

## Open questions and agent split

### Open questions

- [ ] Does a hover tray on a vertical lift sideways, or only work facing down?
- [ ] Rotation snapping during placement: free or stepped?
- [ ] Power box era designs: confirm or revise the first riff.
- [ ] Varran settler: do the chassis and computer outside his bubble wear down in long storms? Can a solar panel go on top?
- [ ] Does the surveyor keep the hoverboard?
- [ ] Exact archaeology setup parts and how "digging a ruin out" is detected.
- [ ] Save format for freeform placement (agent's call).

### Suggested agent split

The chassis rework touches nearly everything, so land it first; the rest can run alongside or after.

1. **Chassis core:** remove crate and slots, sticky surfaces, frames and verticals, plugs only, hooks on chassis and planters only.
2. **Placement:** real-item preview, non-solid while held, clip tint and hints.
3. **Saves:** new format for freeform placement.
4. **Power:** shared deck pool, power box with bays, Console page, era models.
5. **Wind faces:** plate forces, occlusion, scoops, fabric ripple shader.
6. **Starts and kits:** surveyor rework, archaeologist, Varran settler, deeds.
7. **Nomad gear and sails:** wreck sites, second-age sail loot, streamer, mast mounts, crow's nest, rare camps.
8. **Dune archaeology:** exposure dune term, dune ruins, lee loot, lazy buried-site loading.
