# Lore research: why anyone lives on this moon

*Research memo, rewritten 2026-10-14 after the two lore sessions: [part 1](lore-session-2026-10-14.md)
(the moon, the stack, the fall, the minds) and [part 2](lore-session-2026-10-14-part-2.md)
(makers, freighters, the port, names, the far end). Both hold direction Hunter agreed to.
Loose: none of it is canon until he says so, and every name is a working name. It joins [the
body research](body-research.md), [the science brief](science-brief.md) and the vision's lore
into one history.*

**Tags.** **Agreed** is from the sessions, which have the full detail. **Proposal** is a Claude
suggestion in the sessions that Hunter hasn't picked. **Leaning** is a research option this
memo favours, not decided. **Open** is unresolved. Where older research disagrees with the
sessions, the sessions win, and where part 2 refines part 1, part 2 wins;
[section 12](#12-what-the-sessions-replaced) lists what changed.

## 1. The shape of it

- **A big natural moon with its own air,** in a poor system on an interstellar lane. No
  shield holds the sky up and no terraforming machine made it.
- **Two clocks.** A slow geological one: a lost sister moon leaves the survivor eccentric,
  tides heat it, and the orbit later recircularises. A sudden political one: a transit hub, a
  war that severs the lane, a smuggler moon, a paroxysm, then Bronze Age empires in the ash.
- **A supply chain under both.** The moon never made anything high-tech, and every part's
  maker's stamp tells the story.
- **We arrive about 3,000 years on,** late in the wind-down. The desert is a phase, not an
  ending, and history runs backwards in the ground, with the ash band as its page break.
- **No AI uprising,** only local models that cults treat as oracles. **The lane has two
  ends,** and the far one isn't human.

## 2. The body

**Agreed: large, natural, with its own atmosphere.** The in-game size is an abstraction and
circumnavigation is impractical or impossible; the small, lappable moon can't hold air. [The
science brief](science-brief.md) is the physical baseline: a volatile-rich moon of a gas giant
with nitrogen air, tidal heating, volcanism and dust, and no terraforming machines.

**Agreed: the air is about 0.3 bar or more,** so wind can honestly shove the player. At 0.3
bar the strongest gusts (30-36 m/s) shove at any gravity from 0.38 to 0.88 g ([the
table](body-research.md#gravity-and-the-pressure-window)), and `loose_wind_catch` already
implies it. **Open: how far "or more" goes.** Water boils at about 69 °C at 0.3 bar and clear
ground runs 60-90 °C in the afternoon, so much more air and the daily boil-off fades.

**Leaning: 0.4-0.5 g, a radius of roughly 3,500-3,900 km.** The sessions say only "large";
gravity is Hunter's call, and the F6 toggle lets him feel it. Caveat: 0.52 g implies a density
near 4,800 kg/m³, denser than Mars, while "volatile-rich" suggests lighter. At 3,000 kg/m³,
0.45 g needs a radius near 5,000 km and a giant of 9-10 Jupiter masses. Arability is
unchanged: natural regolith isn't soil, and you farm in planters with your own soil.

## 3. The geological clock: a lost sister moon

**Agreed correction:** moons don't "collapse"; resonances are entered or left as moons
migrate. The framing: a calm, near-circular orbit for a long time; **a sister moon is
destroyed or lost**; the survivor is pushed into an **eccentric orbit**; the giant squeezes it
every lap and **tidal heating spikes** as on Io, cracking the crust and outgassing the thick
atmosphere the moon is big enough to hold; the same activity grinds mountains into sand, dunes
and basins; then **tidal friction recircularises the orbit**, heating fades, topping-up of the
air falls behind escape, and the moon settles **colder, drier and calmer**.

**Leaning: two physics checks.** *The trigger:* losing a resonant partner usually removes
forced eccentricity (Io would circularise without Europa), so plain destruction doesn't pump
the survivor. An ejection after a close encounter can, which favours "ejection" for question
1. *The clocks:* recircularisation takes millions of years against a human story of a few
thousand, so the paroxysm should read as an episodic eruption (Io's are), not the peak of
heating.

## 4. The system, the lane and the harbor

**Agreed: the system and the route.** A poor system: a hot, Venus-like inner world, an
unlandable gas giant, and this moon as the only ground. It sits on an interstellar lane midway
between powers, a stop on the way to civilisation and not the customs port into United
Government space. The first presence is boring infrastructure: a beacon, a depot, a relay. The
lane carries **helium-3**; skimming it from the giant is risky, equipment-destroying work for
small outfits, not the official reason the hub exists.

**Agreed: the analysis versus the people.** The top knew. TILG and the IOU saw the heavy
volcanism and approved an **intermediate transit hub, explicitly not for settlement.** The
ground didn't care: a corporate town grew anyway, **never registered** with the local
government, and the Skimmers Association arrived. Nobody thinks in millennia, and the
knowledge lives at corporate altitude.

**Agreed (part 2): no FTL** in Xandaris (or this history predates it), so lane crossings take
years. **Freighters are moving towns,** each about the size of a spaceport town, with
districts, a hierarchy and a population living aboard for years. A freighter wreck is the ruin
of a small mobile city: the biggest, most dangerous, most rewarding dig site in the game, with
its He-3 core at the bottom.

**Agreed (part 2): the moon is a harbor for mobile cities,** not a gas station. After years in
transit a freighter-town needs somewhere to resupply, repair and let its people off, which is
why the hub grew. The rhythm is tidal: when a freighter-town docks, crews pour out and the
place swells with money and chaos, and when the lane is quiet a skeleton crew tends the garden
and the vents. So far: one big port city and refinery settlements near the vents (agreed),
possibly a minor secondary port (**Open**). **Open: the port at its peak** is the next
session and the most surfaced lore left, since the player walks through its corpse
(question 8).

**Leaning: two He-3 streams.** Part 1 has outfits skimming the giant, part 2 has the far end
exporting He-3. Both hold if the bulk arrives by freighter and skimming is the risky local
trade.

## 5. Who's there: operators, makers and rarity

**Agreed (working names; part 1 §4 has the table).** Eleven entities, sovereign to software:
the **United Government**, a regional interstellar government, the **IOU**, the **Skimmers
Association**, **TILG**, the **Remote Moon Contractor**, **StarCom**, a spaceship builder,
tritium refineries, a moon regional government, and an interconnected software company. Every
one leaves its maker's mark, so the player reconstructs the supply chain from salvage. The
keystone fragility is that **the hub makes nothing high-tech itself.** Every controller,
skimmer and beacon runs on imported chips (Xandaris's `tech_level.go` already decays tech when
Electronics supply stops).

**Agreed (part 2): an OEM tier sits underneath.** The stack is operators, regulators and
integrators, who deploy things. The Remote Moon Contractor sets up and maintains
infrastructure until steady state, then TILG runs it until the town stands alone. Neither
fabricates the core technology; they buy it from the **OEMs**, the hardware makers back in
civilisation whose components everyone resells, integrates and rebrands.
- **Issuer versus maker.** The integrator's mark is on the assembly and the OEM's is on the
  component. A shield housing says Remote Moon Contractor, but the emitter core inside names a
  maker most settlers never heard of.
- **The box.** A crate is addressed to an operator, and each part inside carries its own
  maker's stamp. The label says who ordered it; the contents say who made it.
- **Hardware rhymes with the minds.** Gear has the layered provenance of the models in
  [section 9](#9-the-minds-ai-after-the-cut): OEM core, integrator housing, operator, owner.
- **Why the colony couldn't recover.** It was an assembly-and-operations economy at the far
  end of a chain it couldn't reproduce. After the cut it can integrate and repair, never
  fabricate; the fabs were never here. That fits the vision's parts that are found and never
  crafted.

**Agreed (part 2): TILG buys its core technology,** so it is a general contractor, not
vertically integrated, which settles part 1's question 5. **Leaning: one wrinkle.** Part 2
says nobody in part 1's table manufactures anything, yet the table has a spaceship builder and
StarCom's hardware, and part 2 stamps the freighter core with the shipwright. Read it as:
operators and integrators buy, while the shipwright and StarCom are makers inside the stack.

**Agreed (part 2): three kinds of rarity.** A reusable rule for salvage, set by *why* an item
is on the moon:

| Category | Why it's here | Why it's rare (or not) | Examples |
|---|---|---|---|
| **Commercial OEM** | Normal procurement | Common: mass-made, deployed everywhere | Starting shield, solar, wind |
| **Industrial** | The hub ran on it | Rare by fleet size: only ever a few | Freighter He-3 cores, port machinery |
| **Off-supply-chain** | It shouldn't be here | Rare by contraband: someone brought it | Deserters' military gear, smuggled goods |

Off-supply-chain gear is rare, powerful and narrative at once: military tech had no business
on a civilian transit hub, so deserters fleeing the war must have carried it.

## 6. Makers' goods: shields and power

**Agreed (part 2): shields are a commercial product.** The sky shield is gone, but camp-sized
generators are ordinary OEM goods. The ladder is built from provenance, not tier numbers: the
power curve *is* the economy.
- **Main shield OEM:** the common shield and the player's starting one, found all over.
- **Competing OEM:** same tier, a different design philosophy, so it's a real tradeoff, not a
  reskin. **Proposal:** the tradeoff, such as lighter versus tougher.
- **Off-meta specialists:** a couple of small makers with niche builds.
- **The military shield:** government-issue, off the supply chain, brought by one of the
  handful of deserters who lived among generations of colonists. It blocks **heat and dust
  together,** which commercial shields can't. Very rare, very strong.

No shield maker is named; "Acme Shield Corporation" is a placeholder.

**Agreed (part 2): power follows the same logic.**
- **Batteries are anonymous:** commodity infrastructure like screws or rope, with no logo, so
  marks stay meaningful by appearing only where they carry signal.
- **Solar** is a big commodity OEM: everywhere, cheap, useless in storms, the common starting
  power. **Wind** is a different maker: planted, strong in storms, and it ties you down.
- **Proposal: a mid-tier,** a better cell or a deserter's compact field reactor, the power
  twin of the military shield.
- **Apex: the freighter He-3 core.** A solo player can't operate a facility, so the top of the
  curve is a compact reactor pulled from a wrecked freighter's dead core: a component you
  carry, not a plant you tend. It's industrial, and only a few thousand freighters ever ran
  the lane network, so cores are scarce by fleet size. He-3 is fuel and wealth in one
  substance ("gaseous gold"), and the engine that made the colony possible becomes the
  player's endgame battery.
- **Proposal:** the shipwright stamps the core, not a power company, so the player has walked
  past that logo on hull wreckage all game.
- **Leaning: a scale check.** A town-sized ship's engine isn't hand-carried, but one cell of a
  multi-cell core could be.

## 7. The political clock: the fall

**Agreed.** Four phases:
1. **Orphaned.** A war breaks out and the lane stops being valid. Nothing ran out; a political
   event elsewhere made the moon pointless, and the harbor's tide stopped. Then the chips stop
   and machines go dark one by one.
2. **The smuggler moon** (the first fallen empire). Illegal trade becomes one of the only ways
   anyone deals with the place. Deserters and refugees come because it's remote and unchecked,
   bringing the off-supply-chain gear of section 5, and the Skimmers Association inherits it.
   Knowledge isn't lost yet.
3. **The paroxysm.** The worst eruptive episode of the transition: a mountain with major
   StarCom installations explodes. Ashfall buries the lowlands, the air is lethal for a time,
   and **outside comms are cut instantly.** The expertise was at the port, where the blast hit
   hardest, so the survivors are the scattered, and civilisation restarts in the ashes from
   the people who understood the machines least. The war reaching the moon and the software
   layer failing are secondary hints.
4. **Bronze Age empires and holdouts.** The second and later civilisations rise and fall on a
   drying, harsher world, scavenging ruins they can't repair. **The eruption becomes myth:** a
   mountain of fire that ate the sky and silenced the voices. The blast zone is cursed ground
   with the best salvage, so their superstition is the player's inverted treasure map.

**Agreed (part 2): the fall was purely human.** Geology plus a lack of foresight: people were
warned the moon was transitional, lived season to season, and planned to get rich and get
out. The far end of the lane (section 10) had no hand in it.

## 8. The ground: strata, the oldest tech and names

**Agreed: history runs backwards in the ground.** Top to bottom: the **surface** (Bronze Age
mud, scrap and cult works); **the ash band** (the paroxysm, the page break of the whole
history, and a readable depth cue in storm-cut dunes); and **below**, the buried colonial
world, sealed by the disaster that ended it. The Salvage PRD's four layers fit, with the
smuggler moon below the ash.

**Agreed: the oldest tech is StarCom and the Remote Moon Contractor's build-out,** overbuilt
for these exact conditions while everything later was built for a world that no longer
exists. **StarCom is precious because it's fragmentary:** its flagship stood on the mountain
that blew, so the player finds shards, relays and hardened modules, never a whole one.

**Leaning (kept):**
- Harder storms strip down to deeper layers.
- The colonial layer holds sealed fresh water, helium-3 fusion cells (the Power PRD's colonial
  cells, with the freighter core of section 6 at the apex) and sealed seed stores, where the
  oldest seed is the best seed. Seed as Bronze Age money stays lore in item text.
- Ruins last: halls stand about 5,000 years (the Forge's rule).
- "Simulation" and "purgatory" can live in the world as belief, never as answer.

### Names: the UG catalog and the moon

**Agreed (part 2): the United Government names bodies by coordinate.** Designations are
hierarchical (sector, system, body), so a designation is a location and scales forever.
**XN** is the sector prefix for Xandar/Xandaris, non-negotiable. The UG is sprawling and thin,
so a designation reads as one line in an enormous ledger, and nobody named the moon with care.
Its people made up their own name.

The moon has three human names and one older alien one. Each surfaces maybe once in the game,
and the player does the linking.

| Name | Layer | Where it appears |
|---|---|---|
| **XN-118-7** | Official UG designation: sector XN, system 118, body 7 | Planning documents, colonial records |
| **Xanathivin** | The weird middle form, and the name of the fallen middle age | Middle-era remains; nonsense until lined up against both ends |
| **Zan** | The worn local name everyone says | Late, colloquial |
| *(alien name)* | Older than the designation; should sound nothing like the human system | Unminted |

**The erosion path** is modelled on *Eboracum → Eoforwic → York*: XN-118-7
("ex-en-eighteen-seven") → spoken fast as *zenateen-sev* → fused into **Xanathivin** once
nobody remembers it was a coordinate → clipped to *Zanoth* → **Zan**.

**X versus Z is a depth cue.** Spelling lags pronunciation: speech softened the X to a Z
early, but writing kept the X for centuries. So an X-spelling is old and official and a
Z-spelling late and colloquial, and like the ash band, the letter tells you the stratum.

**The Xanathivin age.** The middle form names the fallen age between the colonial world and
the present, the ash-and-scrap centuries of the Bronze Age. Its people named their era with a
worn-down database entry they took to be ancient and sacred: myth built from forgotten
logistics. That gives ruins, strata and artifacts a three-part tag, **colonial / Xanathivin /
surface (Zan)**. **Leaning: how it meets the four layers.** Colonial and the smuggler era sit
below the ash, Xanathivin is the Bronze Age above it, and Zan is the surface. Part 2 doesn't
place the smuggler era, and X marks colonial and Xanathivin alike, so only the form separates
them: a coordinate versus a fused word.

## 9. The minds: AI after the cut

**Agreed.** Frontier AI was never on the moon. It came down the lane through StarCom and went
dark the day StarCom did. What's left are whatever **local models** survived: a refinery
controller, a logistics scheduler, a weather forecaster, a skimmer crew's assistant. Promoted
to oracles out of domain, on failing hardware, they drift into eccentricity. **AI cults, not
an uprising.**

**Agreed: model provenance as archaeology.** Each model has a lineage and each layer leaves a
mark, as the hardware does. One example: a base model trained under United Government
oversight, fine-tuned by a second company, running on an agriculture company's platform, owned
at the end by whoever acquired that company. Three thousand years on, it has taken over a
local StarCom station and broadcasts fragments that, read correctly, are still useful:
planting timing, storm precursors, which feral strains tolerate ash soil. The cult hears
scripture and an attentive player hears a planting calendar, so **decoding the oracle is a
skill.** Nobody built a prophet; procurement did.

**Open: the maybe-voice.** The leading candidate is the software company's orchestration
layer, the most general surviving model, still optimising a supply chain that doesn't exist.
The game never says whether anyone is there.

## 10. The far end of the lane

**Agreed (part 2).** A lane has two ends, and the other isn't human.
- **Who.** An ancient civilisation, far older and larger than human space, that succumbed to
  or merged into its own collective intelligence and may no longer be corporeal. (Hunter chose
  this over a human faction that broke off into a hive mind.)
- **Trade runs the other way.** The far end **exports** He-3 and more. It has no need for
  anything and doesn't operate the way humans do, so humanity is the junior partner, the
  customer.
- **It imports novel human artifacts:** a child's scribbles, 1800s handwriting, a Monet. It
  guesses a language from two characters at 80% accuracy, and the last 20% is the point: it
  can model everything except the irreducible novelty of a separate mind.
- **It eats intelligence.** Importing novel thought *is* the conquest, and every transaction
  is a slow bite. It has laid claim to this moon and has a name for it, but it will never
  confront anyone. It plans across eons.

**Rules for agents (Agreed, part 2).**
1. **The far end's purpose is never stated in-game.** At most it surfaces as a very rare,
   coherent, unanswering radio frequency, unlike the drifting local oracles. A player may
   assemble it from the alien name, odd import manifests and that signal, but can never
   confirm it.
2. **Never retcon the paroxysm or the sister moon as arranged.** The human tragedy is the
   story.
3. **A minor echo, never stated:** the player, salvaging intelligence from the dead by hand,
   is a tiny biologic mirror of the thing at the end of the lane.

## 11. What it gives the game

*Kept from the body research, re-checked against the sessions. The numbers are estimates and
live there.*

- **The dials.** The equator is stormy and mild under its dust blanket, choppy and
  salvage-rich, while the poles are calm, clear and sparse, with the widest swings. "Hotter
  days at the poles" needs a reason, since with near-zero tilt the poles get less sun
  (question 15). The near side has the giant fixed in the sky and a noon eclipse, and the far side has
  truly dark nights. The old near-industrial, far-biological split came from a biotech tenant
  the stack lacks, and ruins now follow the terrain.
- **Weather, water and the suit.** Colliding sand charges up, so radio static is a storm
  precursor. Frost forms in the cold hours, open water boils off by afternoon, and sealed
  colonial stores keep you going early on. No ozone means unfiltered UV, but the fast killer is
  the air.
- **Radio and wear.** The radio has StarCom stations squatted by local models, beacons left
  running, and the maybe-voice, never answered; the far end is at most one more hint (section
  10, rule 1). Wear is sandblasting and the daily freeze-and-boil, and the old rust is red.
- **Why you're out here (FICSIT).** Your kit reads like company issue: a common-make shield, a
  light solar panel, a suit with free air. Who sent you is open.

## 12. What the sessions replaced

- **The sky shield and the shield era,** with the 0.4-0.5 bar it bought and the "kind of nice"
  garden cities. Part 2 answers whether a lesser shield survives: ordinary shield generators
  are commercial goods (section 6), which gives the game's camp bubbles an origin.
- **The collapse and the long fade,** **0.15-0.2 bar sinking to 0.1-0.15,** **the AI collapse
  as the trigger,** **two empires fading to weather,** **a biotech tenant on the far side**
  and **dead gardens as the dust source:** the wind-down, about 0.3 bar or more, the
  paroxysm, local models and cults, the hub-to-Bronze-Age arc and the entity stack replace them.
- **Part 1's maker's marks as the whole provenance story:** part 2 adds the OEM tier beneath
  them and exempts commodity parts such as batteries. Part 1's leaning that TILG is a general
  contractor is now agreed.

## 13. Open questions for Hunter

*From both sessions, merged with the earlier list and de-duplicated.*

**History**
1. **The sister moon:** impact, collision or ejection (the physics favours ejection)? Is it
   still visible as a ring, debris or a gap? It was not arranged (rule 2).
2. **The paroxysm:** its name, as the survivors pass it down, and how fast literacy and
   technical knowledge fell after it.
3. **The maybe-voice:** which model, and does it stay distinct from the far end's signal?
4. **The timeline and the war:** dates from founding to arrival (does the 3,000 years run from
   the paroxysm or the last empire's fall?), and what the war was, between whom.
5. **Who sent the player:** ship crew, the company, a colonial vat that grows workers
   (permadeath as lore), or never said. Still deferred.

**Makers, names and the harbor**

6. **The OEM naming register:** grounded-corporate, mythic, or a split (dull names for
   commodity makers, legendary ones for deep OEMs). **Proposal** candidates, none chosen:
   solar, Heliostat Industries, Sunward, Meridian Power Systems; wind, Gyre, Vane Dynamics;
   shipwright, Keel & Core, Drayard, Orbital Foundries.
7. **Names** for the shield OEMs, the port city, the secondary port, the refinery settlements
   and the moon's alien name.
8. **The port at its peak:** do docked crews mix into town or stay aboard, what was the peak
   population, and what was daily life in the good window?
9. **Do the shipwright and StarCom count as OEMs,** and where does the smuggler era sit in the
   colonial / Xanathivin / Zan tag?
10. **How much of the UG to flesh out** beyond its catalog.
11. **Movement gear through the OEM lens.** Leaning, from part 1's chat (not in its notes): the
    hover planter as ag-tech issue, the hoverboard as skimmer-culture gear.

**Checks the sessions leave open**

12. **A town-sized freighter as a ground wreck.** It is unlikely to land in 0.4-0.5 g. Leaning:
    freighters stranded when the lane died were finished by the paroxysm.
13. **No FTL against StarCom.** Live frontier AI over a link with years of lag doesn't work, and
    part 1 has the minds going dark "the same day". Streamed weights and updates would fit.
14. **Where the moon sits on the lane,** now the far end is a destination: is "midway between
    powers" the human core and the far end?

**Carried over**

15. **Seasons and the poles:** near-zero tilt (the body research's leaning) or a tilt? Without
    one, "hotter days at the poles" needs a reason or goes.
16. **Gravity and density:** 0.4-0.5 g via F6, and a bigger moon or a heavier giant.
17. **The lap:** the sessions call circumnavigation impractical or impossible, but the vision
    and [the moon](the-moon.md) have a walkable 150 km lap with reachable poles. Which holds?
18. **The air over time:** how far above 0.3 bar, how thick at the eruptive peak, the
    end-state floor, and whether near and far sides differ in ruins.

**Sources:** [dust charging](https://public.websites.umich.edu/~atreya/Articles/2003_Electrical_Discharges.pdf),
[Europa's dose](https://europa.nasa.gov/news/17/radiation-maps-of-europa-key-to-future-missions),
[ruins uncovered by dunes](https://en.wikipedia.org/wiki/Dandan_Oilik). The rest are in
[the body research](body-research.md).
