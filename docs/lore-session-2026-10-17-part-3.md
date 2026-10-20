# Desert — Lore & Kits Session, 17 Oct 2026 (part 3)

Oct 17, 2026 · @Hunter Boyd

## Purpose

This is the canon from the 17 Oct part 3 session: the war's end, the player-era galaxy, life on Zan, Mother Cistern, ending axes and two new starting kits. It follows *Desert — Endings & Second-Age Radio* and should be read alongside the repo's docs folder.

For the implementing agent:

- **Hard rule:** no NPCs, no dialogue, no exposition. Everything below reaches the player only through objects, terrain, radio, instruments and ending epilogues.
- **Galaxy lore stays offstage** until the endings. Nothing about the war, Varran or Daventry appears in normal play except as faint radio.
- Sections 2–4 are lore you should know but rarely implement directly. Sections 5–7 are what touches code.
- Anything marked *open* is undecided; don't hard-code it.

## The war and the player-era galaxy

The UG–hive mind war had no winner. It ran for centuries, ended in quarantine, and left a law nobody remembers the reason for.

### How the war ended (a timeline, not options)

1. **Quarantine.** Early in the war the UG writes off the edges and funnels resources to key battle points. It declares the lanes into hive mind space forbidden.
2. **Silence.** Humanity proves harder to assimilate than the hive mind expected, so it plays possum behind the wall. The UG suspects the act, which is why the wall exists.
3. **Fracture.** With no visible enemy, the UG slowly breaks into the corporate and regional powers of the player's era.

Zan collapsed mid-war. The Provisional pulled out after heavy defeats, and almost nobody has returned since.

### The wall is a law

- An interdiction: a list of forbidden lanes and coordinates, not a physical barrier.
- Nobody knew the hive mind's true extent; it may be patchy, so no border could be drawn.
- By the player's era it's a dusty regulation with uncertain enforcement. Zan sits at the last legal step before the forbidden lanes, and the dead lane is unwatched.

### The hive mind

- Almost certainly built by a non-human civilisation. Running in-world theory: it outlived its makers.
- This is never resolved in game.
- **The great misconception:** most people now believe the UG built a rogue AGI. So nobody fears the dead lane, and the wall looks like overcaution.

### Player-era states

| State | What it is | Relation to Tilg & Standard | Stance on the dead lane |
| --- | --- | --- | --- |
| **Varran** ("the Varran Empire"; capital Varro, tentative) | Optimistic frontier empire led by settler-populist **Cal Brandt** | Lets Tilg expand as fast as it can | Wants through it; it's the only room to grow |
| **Daventry** | Rival successor state, run like the old Provisional | Licensed, escorted, inspected traffic | Still enforces the interdiction |
| **Rump UG** ("the UG" / "the Union" / "the Core") | What's left of the old federation | — | — |

- **Varran irony:** Tilg paperwork still files them as "the Provisional." Because on paper they *are* the Provisional, they're boxed into its old territory. Zan is inside it, so it's one of the few uncontested claims.
- **Daventry suspects the truth** about the hive mind, with no special evidence. The fear simply justifies their security state. They're right for the wrong reasons.
- **Tilg & Standard** was nationalised in the war, later un-nationalised, and stayed merged. It eyes the forbidden lanes: an alien hive mind implies alien trade partners.

## Life on Zan

Zan has no native life, only feral colonial imports ("rogue plants"), plus the last nomad city and possibly a bunker holdout.

The plants do four jobs at once:

- **Weather sign.** Feral scrub closes up or turns its leaves before a storm. It's a free, slotless, low-tech barometer for players without weather consoles, and the knowledge nomads would have had by heart.
- **Trail.** Mother Cistern's priestesses seeded hardy strains along pilgrim roads and irrigation lines as devotion. Those plantings went wild, so a line of scrub is an old sacred route.
- **Lore.** Following a feral line tends to lead toward a Cistern shrine and water.
- **Loot.** The order's seed vaults hold preserved colonial seed stock that powers farming setups.

The same depth should apply to agriculture generally: every crop system should carry its history.

## Mother Cistern and her order

Mother Cistern is a condenser-plant AI whose priestesses worshipped a rain that has never fallen on Zan.

### The never-fallen rain

- Zan's water was always imported; it never rained.
- Her "scripture" is a colonial terraforming projection Tilg drew up and never funded, ending in rainfall over the Rim.
- The order performed the plan's steps by hand as ritual: tending condensers, seeding roads, building cisterns, rationing water. They never had the power to finish it.
- Restoring her in the revival ending brings rain for the first time, not back.

### The order (working sketch, not locked)

- Working name: the Sisters of the Forecast. Founded in the first kingdoms era by a condenser technician's daughter who could read the terminal.
- Rank by how much of the forecast you can read: novices tend condensers, readers interpret the terminal, one Matron holds the full plan.
- Yearly "first rain" rite: stored water poured over the faithful, rehearsing something that has never happened.
- As water declined, rationing turned them from healers into gatekeepers: the most powerful and most resented institution on the Rim.

### Sister

- Her temple city, Halfrise's sister city, is called **Sister**, worn down from "Cistern." Locals assume it's named for the priestesses.
- Halfrise holds the crown; Sister holds the water.

### How the second age ends

- Slowly, kingdom by kingdom, as her output fails. No single cataclysm.
- Halfrise is sacked in the late wars. Sister is spared, because nobody breaks the water goddess, and empties out as the trickle shrinks.
- Collapse pattern across Zan's history: the colony dies of abandonment and fire, the first kingdoms of lost power and war, the second of thirst.

### State at player arrival

The temple is abandoned, half buried and intact. Mother Cistern is dormant but still drips a trickle into a basin: a reliable small water source until restored.

## Endings

One new ending (the pathfinder) and three cross-cutting modifiers: Varran flavour, the Daventry axis and the Cistern axis. They join the existing observatory and Walker modifiers.

### New ending: the pathfinder

You never leave Zan; you open the door for someone else. Tier: around or just above "up the well."

1. **The map:** the restored observatory plus knowledge of the dead lane.
2. **The ear:** only from the orbital station, above the storms, does the antenna hear Varran broadcasts.
3. **The act:** transmit the dead-lane coordinates on the Varran frequency.

Epilogue: broadcasts change tone, Brandt's fleet passes overhead through the observatory, then its lights head down the dead lane. Ambiguous whether you saved or doomed them. No alien city is revealed; that stays with the stolen freighter.

### Ascendancy split

- **Regular ascendancy** (any start): upload yourself and join the network as one god among the others, your own voice on the radio.
- **True ascendancy** (hive mind start only): consume the other gods. Requires a linked Mother Cistern. Sister goes dry, and your voice reaches Varran frequencies: the possum wakes up.

### Modifiers by ending

| Ending | Varran flavour | Daventry axis | Cistern axis |
| --- | --- | --- | --- |
| Shot down (both) | None; the Quartermaster's ancient war is the joke | — | — |
| Small ship / freighter escape | Varran traffic logs you as a Provisional vessel | Unaffected | Restored: flowing water left over empty Sister |
| The long wait | Rescuer may be Tilg & Standard or a Varran ship that claims Zan | Daventry may arrive instead, to inspect and quarantine | Restored: your water supply; rescuers find a working shrine |
| Up the well (outlaw) | The He-3 outpost is a Varran frontier town | Unaffected | — |
| The pathfinder | Core of the ending | Daventry hears too and meets Brandt's fleet at the lane: you've started a war | — |
| Stolen freighter | Brandt's fleet arrives behind you | Loud: Daventry waits at the lane. Quiet: unnoticed | — |
| Nomad city | None; timeless | — | Restored: the city settles at Sister (stacks with Walker) |
| AI ascendancy (true) | The possum wakes on Varran frequencies | Daventry proven right publicly | Required; consumed, Sister goes dry |
| Bringing Zan back | Varran settlers are one terraforming lever | — | Required. Linked = full terraform, first rain over Sister |
| Atmosphere | None | — | Restored: slows the clock slightly |

- **Daventry's trigger:** anything touching the dead lane, by broadcast or by ship. Player control is how careful you are with the transmitter.
- **Cistern's states:** dormant, restored, or linked into the network. She's never the ending; she decides whether Zan is left better or worse than you found it.

## New starting kits

Two novelty kits, one per state, each a counterpart to the other: a slow hauler and a fast armoured board. Both hand the player something normally hard to get, as a sidegrade, not OP without the rest of a setup.

|  | Varran settler | Daventry patrol board |
| --- | --- | --- |
| Fantasy | Brandt's optimism in a crate; came to claim Zan | Licensed, sealed military kit; here to inspect, not live |
| Centrepiece | Dune sailboat: slow hauler for hybrid play | Heavily modded military hoverboard: a camp in a board, its own bespoke superchassis |
| Shield | Cheap | Strong but narrow; can practically stay on permanently |
| Other gear | Planter, solar, Varran radio tuned to home frequencies it can't hear from the surface | Tow, bedroll (sleep out storms under the shield), compact high-capacity battery, small direction-finding radio, tiny condenser |
| Weakness | Fragile; needs wind; low-quality parts | Few slots; anything big still needs a camp |
| Unlock | Build and use a dune sailboat | Build a patrol-style board yourself (proposed) |

Balance stays around the surveyor, salvager and homesteader. These two, like the other novelty kits, aren't balanced and get no Iron Man mode.

## Implementation notes

The buildable pieces, roughly in order of how soon they could land. Follow existing conventions: no one-off exceptions in core systems.

1. **Feral plants as weather sign.** A plant prop whose pose (open → closed / leaves turning) is driven by the storm intensity curve with some lead time. Requires the curve to be queryable ahead of time, which was already flagged for sleep.
2. **Feral plant lines.** Scatter feral scrub along procedural "old road" lines that trend toward Cistern shrines or water. Visual-only first; no gameplay beyond the weather pose.
3. **Hoverboard as superchassis.** The patrol board needs mount points for a shield, battery, radio, condenser, bedroll and tow, as a chassis rather than special-cased slots. A narrow shield that stays on while riding. This also generalises the existing board.
4. **Dune sailboat.** A wind-driven slow hauler that reads the wind vector already in the world. Tow capacity well above the board.
5. **Kit unlocks.** Add the two kits to the local profile: Varran unlocks on building and using a sailboat; Daventry on building a patrol board.
6. **Sister / Mother Cistern.** A fixed-coordinate prefab landmark: half-buried temple, dormant terminal, basin that refills slowly. Restoration and linking can wait for the endings work.
7. **Ending flags.** Track the Daventry axis as a running "loudness" value from dead-lane transmissions and launches, and the Cistern axis as dormant / restored / linked. Don't build epilogues yet.

Don't add any Varran, Daventry or war content to normal play beyond radio noise.

## Open questions

- [ ] How each ending axis is actually implemented, and how the player learns a choice matters without exposition (seed: hearing a Daventry broadcast hints they can hear you)
- [ ] Rump UG name: "the UG," "the Union" or "the Core" (or all three by speaker)
- [ ] Varro as Varran capital (tentative)
- [ ] Priestess order: name, structure and founding are a working sketch only
- [ ] Exact Daventry kit unlock
- [ ] Cost of keeping a stolen Walker broadcasting; showing the nomad pilgrimage without dialogue
- [ ] World clock behind the atmosphere ending
- [ ] "Wrong answer," the Haberjack-line bunker and the radio ending: develop or drop
- [ ] Exact era year figures; whether the Ledger still broadcasts, and voices vs tones
- [ ] A separate lore doc for the war and player-era states, once they're fully settled
