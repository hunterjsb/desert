# Lore session: the moon's history, end to end

*Session notes, 2026-10-14 (Hunter + Claude, voice). This is the direction Hunter agreed to
during the session. It is not final canon until Hunter says so. It supersedes the stale
parts of [lore-research.md](lore-research.md) (the small/dense moon, the sky shield as the
air's only container, the Heavy Moon as the spine). Names of entities are working names.*

## 1. The body

- **A large natural moon with its own atmosphere.** The world's size in-game is an
  abstraction; circumnavigation is impractical or impossible. The small, lappable moon is
  dropped because it can't hold air.
- **The science brief is the physical baseline** ([science-brief.md](science-brief.md)): a
  volatile-rich moon of a gas giant, nitrogen air, tidal heating, volcanism, dust from
  fracturing, impacts and abrasion.

## 2. The trigger: a lost sister moon

**Correction for the research doc:** moons don't "collapse." The earlier agent compressed
"orbital change" into "a moon collapsed." The Io literature supports resonances being
entered or left as moons migrate, not moons collapsing.

**Canon framing:**

1. The moon sits in a calm, near-circular orbit for a long time.
2. **A sister moon is destroyed or lost** (impact, collision, or ejection; which one is
   open).
3. The gravitational balance of the system changes. The survivor is pushed into an
   **eccentric orbit**.
4. The giant now squeezes and releases it every lap. **Tidal heating** spikes, as on Io.
   The crust cracks, volcanoes outgas trapped volatiles, and the moon is big enough to
   hold them as a thick atmosphere.
5. The same activity drives massive erosion. Old high relief (mountains, crater rims) is
   ground down into sand, dunes and basins. Bedrock shows where wind scours.
6. **Tidal friction slowly recircularises the orbit.** Heating fades, eruptions taper,
   and topping-up of the air falls behind escape.
7. The moon settles into a **new stable state**: colder, drier, calmer. The desert and its
   storms are a *phase*, not an ending.

The arc has a beginning, a violent middle, and a long wind-down. The game takes place
late in the wind-down: mostly sand, air still present, storms still roaming.

Two clocks run at once through the whole history: the **slow geological clock** and, later,
a **sudden political clock** (§4).

## 3. Why anyone came: route first, resource second

- The system is poor: a hot, Venus-like inner world, an unlandable gas giant, and this moon
  as the only ground. It sits **on an interstellar lane**, midway between powers. It is
  *not* the customs port into United Government space; it's a stop on the way to
  civilisation.
- The first presence is boring infrastructure: a beacon, a depot, a relay, a survey crew.
- The lane carries **helium-3** trade. Skimming He-3 from the giant is real in principle but
  brutal in practice. It's **risky, equipment-destroying work done by small outfits and
  individuals** betting their gear, not the official reason the hub exists. (Real-world
  note: He-3 in gas giants is real; skimming a Jupiter-class giant is firmly sci-fi. Fine,
  since Xandaris already prices He-3 as the top raw resource.)

### The analysis vs. the people

- **The top knew.** TILG and the IOU ran a proper analysis during approval, saw the heavy
  volcanism, identified the transitional eccentric phase, and approved the moon as an
  **intermediate transit hub, explicitly not for settlement**. They always knew it would
  dry up without interstellar support.
- **The ground didn't care.** A corporate town grows anyway, **never registered** with the
  local government, operating fully as a settlement. The Skimmers Association arrives,
  people stake property, a lively local ecosystem forms.
- People don't think in millennia. They think: *I'll get rich, my line will get rich, they'll
  move off this rock.* The knowledge exists but lives at corporate altitude. The population
  is half-aware and doesn't dwell on it, because frontier life is exciting and the money is
  now.

## 4. Who's there: the entity stack

Every entity leaves its own maker's mark. The player reconstructs the supply chain from
salvage alone, with no exposition needed.

| Tier | Entity | Role |
|---|---|---|
| Sovereign | **United Government** | Highest claim over the system, inhabited or not. Distant; a charter and a seal. |
| Regional | **Regional interstellar government** | A state spanning several stars. Does the actual regulating day to day. |
| Regulator | **Interstellar Operations Union (IOU)** | Approves operations; oversees labour, safety and humane treatment of the people run through. |
| Regulated fringe | **Skimmers Association** | Regulated by the regional government. Takes the greater risks, supplies staffing, semi-compliant, useful to have around. |
| Prime operator | **International Logistics Company (TILG; name/acronym TBD)** | Spotted the system as a transshipment hub, funds and holds the concession. |
| Builder | **Remote Moon Contractor** | Specialists in hostile bodies: sets up infrastructure and handles permits. TILG's partner on the ground once the IOU approves. |
| Comms | **StarCom** | Durable, reliable, extreme-range comms hardware on the ground. Also the link that carried frontier AI to the moon (§7). |
| Shipyard | **Spaceship builder** | Built the ships that flew everything in. A logo on hulls and wrecks. |
| Heavy industry | **Tritium refineries** | Appear once skimming and transshipment scale up. Near geothermal vents. |
| Civic | **Moon regional government** | Forms once there are enough permanent residents to want representation. A timeline milestone: the hub became a home. |
| Orchestration | **Interconnected software company** | High-level visibility, analytics, plans and actionable insights across all of the above. |

### Supply chain → ruin geography

The terrain tells you what kind of ruin you're standing in:

- skimmer cradles, tethers and catch stations on high ground;
- refineries clustered near volcanic vents;
- tank farms buried in basins;
- port cradles and beacons on the heights;
- garden, water-cracking and power around the town;
- owner-operated, improvised skimmer-crew wreckage as a separate scrappy texture from the
  institutional infrastructure.

The keystone fragility: **the hub makes nothing high-tech itself.** Every controller,
skimmer and beacon runs on imported chips. (Xandaris's `tech_level.go` already models tech
decaying when Electronics supply stops.)

## 5. The fall, in phases

### Phase 1: orphaned

- **A war breaks out and the lane stops being valid.** The moon was a midpoint between
  powers; with the route severed, its reason to exist disappears in an afternoon. Nothing
  ran out. A political event elsewhere made the moon pointless.
- At first it doesn't feel like a fall. *How could a whole moon collapse?* Infrastructure,
  people and machines are all still there. People wait for normal to resume.
- Then the math catches up: no imports, no chips, machines that can't be repaired going dark
  one by one.

### Phase 2: the smuggler moon (first fallen empire)

- Within a generation or two, **illegal trade becomes one of the only ways anyone deals with
  the place.** Tatooine in feel.
- The moon's irrelevance becomes its asset: deserters and people fleeing the war come
  *here*, because it's remote, never officially zoned, and nobody checks papers.
- The semi-compliant fringe (the Skimmers Association) is best placed to inherit it. The
  outlaws outlast the company.
- **Knowledge is not lost yet.** People still arrive, StarCom still works, trade still
  carries memory. A slow fade alone can't produce a reset.

### Phase 3: the paroxysm (the hard reset)

- **The worst eruptive episode of the whole transition.** A mountain where major StarCom
  installations stand explodes. A terrible generation follows: ashfall burying the
  lowlands, lethal air chemistry for a time, storms at their peak.
- **Outside comms are cut instantly.** The link to the galaxy doesn't fade; it detonates.
  The moon is now isolated.
- The survivors are the *scattered*: people out in the field, deep in shelters, far from the
  hub. The concentrations of expertise were at the port and installations, where the blast
  hit hardest. **Civilisation restarts from the people who understood the machines least.**
- Survivors come together and **rebuild cities in the literal ashes.** This is the start of
  the Bronze Age line.
- Considered and kept as secondary hints: the war reaching the moon, and the software layer
  failing during the crisis (contributing cause, not villain). No Kenshi-style AI uprising.

### Phase 4: Bronze Age empires and holdouts

- The second and later civilisations rise and fall on a drying, harsher world, scavenging
  ruins they can't repair or understand.
- **The eruption becomes myth:** a mountain of fire that ate the sky and silenced the voices.
  The blast zone may be feared or treated as cursed ground, which is where the best salvage
  is. Their superstition is the player's inverted treasure map.
- 3,000 years later (approx.), the player arrives.

## 6. History runs backwards in the ground

Top to bottom:

1. **Surface:** Bronze Age mud, scrap and cult works.
2. **The ash band:** the paroxysm. The page-break of the whole history, and a readable depth
   cue in storm-cut dunes.
3. **Below:** the buried colonial world, advanced and sealed by the disaster that ended it.

### Oldest and best tech

- **StarCom** and the **Remote Moon Contractor's** initial build-out. They're best not just
  because they're oldest but because they were **overbuilt for these exact conditions** by
  spec. Everything later was built for a world that no longer exists.
- **StarCom is precious because it's fragmentary.** Its flagship installation was on the
  mountain that blew. The player finds StarCom shards, relays and hardened modules flung
  across the dunes, never a whole StarCom.

## 7. The minds: AI after the cut

- **Frontier AI ("SOTA") was never on the moon.** It came down the lane through StarCom.
  When StarCom went, the real minds went dark the same day.
- What's left are **whatever local models happened to be present and survived**: not the
  best, just the survivors. Narrow, specialised, eccentric. A refinery controller, a
  logistics scheduler, a weather forecaster, a skimmer crew's personal assistant.
- Narrow minds get promoted to civilisational oracles, out of domain, un-maintained, on
  failing hardware. Over millennia they drift into real eccentricity. **AI cults, not AI
  uprising:** people cling to the last thinking things they have and build theology from
  their drift.
- Intelligence decays in the strata like everything else: traces of frontier AI at the
  bottom (referenced, gone), surviving local models through the middle, cult-kept oracles
  at the surface.

### Model provenance as archaeology

Sci-fi rarely asks who trained, funded and issued a model. Here every model has a lineage,
and each layer leaves a mark. Example:

1. **Base model:** a small model trained by a large software company under federal (United
   Government) oversight.
2. **Fine-tune:** specialised and deployed by a second software company.
3. **Platform:** running on software built by an agriculture company.
4. **Owner:** that company acquired by the contractors, the port authority, or a local-district
   firm.

Three thousand years later, this agricultural AI has **taken over a local StarCom station**
and broadcasts strange, fragmentary material. **Interpreted correctly, it's still useful
agricultural information** for the player: planting timing, storm precursors, which feral
strains tolerate ash soil.

- The cult hears scripture; an attentive player hears a planting calendar. **Decoding the
  degraded oracle is a skill.** Superstition and utility are the same signal.
- It still works *because of its deepest layer*, the federal base model. The owner at the
  end is just whoever happened to hold it. History runs backwards inside one artifact.
- Nobody built a prophet. A federal grant, a vendor roadmap, an acquisition and a frontier
  purchase order did. The theology was assembled by procurement.

### The maybe-voice

- Candidate: the **interconnected software company's orchestration layer**, the most
  general surviving model, with the whole map in its head. Still trying to optimise a supply
  chain that doesn't exist, issuing routing advice to a dead network. Likely the centre of
  the biggest cult. (Not decided; could be something stranger.)
- The vision doc's "hatch open in the distance, just out of reach" fits: the player is
  outside the sealed door, the old mind behind it, no longer answering. The game never says
  whether anyone is there.

## 8. Open questions

1. What destroyed the sister moon: impact, collision, or ejection? Is the event still visible
   in the sky (a ring, debris, a gap)?
2. Name of the paroxysm, as the survivors would pass it down.
3. Which surviving model becomes the maybe-voice?
4. How fast did literacy and technical knowledge fall after the paroxysm?
5. Is TILG a general contractor (many maker's marks) or vertically integrated? The session
   leans general contractor.
6. Who sent the player, or why they're out here: ship crew, the company returning, a vat, or
   never said.
7. Timeline in years: colonial founding, the war, the smuggler era, the paroxysm, the Bronze
   Age empires, the player's arrival.
8. What the war was and between whom.

## 9. Knock-on edits for other docs

- **vision.md setting:** replace "collapsed to its own AI" with the orphaned-hub → smuggler
  moon → paroxysm → Bronze Age arc. Keep "history runs backwards," "people only hinted at,"
  and the radio voice.
- **vision.md open question "what ends a run":** the moon itself has an end state (a calm,
  stable desert once the orbit recircularises). Useful long-horizon backdrop.
- **Poles:** if escaping or condensing air collects at cold poles, "hotter days at the poles"
  needs a reason or should go.
- **Pressure:** for wind to honestly shove the player, the present-day baseline should be
  about 0.3 bar or more (see lore-research.md's thin-air table).
- **Salvage & ruins PRD:** maker's marks per entity, ruin types by terrain, the ash band as a
  depth cue, StarCom as rare fragments.
- **Radio PRD:** degraded local models squatting on StarCom stations; signal decoding as a
  skill.
