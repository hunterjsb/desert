# Desert — Console, Sensors & Sleep (17 Oct 2026)

Oct 17, 2026 · @Hunter Boyd

## Brief for the agent

These are design decisions from a voice session. Treat them as direction, not a final spec: the Console's slot layout is explicitly due for a rework. Flag conflicts with existing code instead of guessing. Sockets save by list index, so add new ones at the end of any existing frame.

## The Console

- A new device named **Console**: the camp's computer. It handles computation and moves data between devices.
- It is a **crate variant**, not a seated device. It still takes a hover tray, batteries and power like a crate.
- **Lean on non-mod ports:** only one or two rope hooks. Don't remove battery slots.
- **Plenty of mod ports** for computer mods.
- **One side is dedicated to visual output:** a full-face screen port. Faces must be laid out so a full-face screen can't clip into other parts.
- **Top:** one regular top slot and one computer-mod top slot (antenna, radar and the like).
- **Audio:** comes from a radio on a top mount; no separate audio port for now.
- **Linking:** a chassis connects every Console mounted on it into one system.

## Smart devices

- A shield on a Console becomes "smart" for now: it reports data and can be controlled from the screen.
- What it can do depends on the Console's gear, e.g. auto-on when a regular radar is attached.
- Later: multiple OEMs and parties making and modding shields and Consoles (not designed yet).

## Weather sensing

Multifaceted: each instrument adds its own stats, and the screen shows every stat available.

| Instrument | Adds |
| --- | --- |
| Anemometer / vane | Wind speed and direction now |
| Barometer | Pressure trend: rough warning of an incoming storm |
| Hygrometer | Humidity (ties into the condenser) |
| Radar (top mod) | The storm front: distance and heading |
| Radio | Old weather-station broadcasts: forecast beyond the horizon |
| Particle sensor | Sand density: how hard the storm will hit |

- **Resolution scales with data.** Sparse gear shows numbers; with all the gear (roughly two linked Consoles) the screen is effectively a storm mini-map.
- **Ground and ruin detection is separate equipment** (looking down, not up), likely a different camp setup.

## Sleep

- Problem: storm days are about 20 minutes and storms can last several days; waiting one out early game is boring. Storm-loot mechanics will help once they're in.
- Sleep to fast-forward is the preferred fix over auto-walk, but not settled.
- **Main worry: physics stability while time skips.** Proposal under discussion: check camp stability with real physics before sleep, then only do resource arithmetic overnight against a queryable storm-intensity curve (shield draw scales with storm strength, so duration matters). Not agreed.
- **Sleep gear:** bedrolls, probably sharing the hoverboard's mount slot on a crate. Some ruins have beds. Maybe sleep on bare sand if stable.
- **Using a bed opens sleep options:** sleep X hours, sleep until a time, sleep through the storm. Gear unlocks options; a radio adds some.
- **Radio clocks:** second-era religious broadcasts still air at reliable times.

## Open questions

- Final Console face and slot layout (rework pending).
- Exact list of computer mods and which slot kinds they use.
- Whether a storm's intensity curve can be queried ahead of time (willing to modify).
- Sleep simulation approach.
- Whether religious broadcasts still have a voice or are just tones and numbers.
