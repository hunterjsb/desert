# Release numbering and milestones

**Proposal for review, 2026-10-21.** This clarifies Desert's existing milestone
convention. It does not change a version, publish a release, or declare an
Alpha/Beta gate accepted. Current release steps remain in [README](../README.md#releasing).

## What the version means

Use milestone numbering for the game. The numbers communicate the scope and
sequence of releases; they do not claim semantic versioning of a public API or
encode save compatibility. Development stage, release name and compatibility
information each have their own purpose.

| Part | Proposed meaning | Example |
| --- | --- | --- |
| Milestone | Advance the middle number for a new named, coherent playable outcome; reset the patch. Agree its scope and acceptance checks before release. | `0.3.0-alpha` Sanddune, then `0.4.0-alpha` Spaceport |
| Patch | Advance the final number for fixes, tuning, polish and bounded improvements within that milestone. A new defining gameplay outcome belongs in another milestone. | `0.3.1-alpha` follows Sanddune |
| Stage | Alpha, Beta or release candidate describes maturity against explicit gates. Removing the suffix marks the public full release. | `1.0.0-alpha`, `1.0.0-beta`, `1.0.0-rc.1`, `1.0.0` |
| Name | Give every milestone a base name. Patches retain that identity; an optional adjective may distinguish a patch. | Sanddune; optionally Windblown Sanddune |

The middle number is an ordinal, not a fraction of completion. `0.3` does not
mean 30% finished; `0.10` is valid, and reaching `0.9` is not a prerequisite for
the Alpha gate. Do not renumber published releases to make the sequence look tidy.

## Proposed maturity gates

- **Current development Alpha:** systems and content are still being built and
  revised; each named milestone nevertheless needs its own playable acceptance.
- **1.0.0-alpha — full playable Alpha:** satisfy the existing
  [full Alpha acceptance gate](alpha-roadmap.md#full-alpha-acceptance-gate).
  A player can learn, travel, improve and sustain a camp, progress through the
  selected equipment/regions and complete the selected conclusions. Persistent
  state and supported platforms work together. Final art and final balance may
  follow. This is not the public full release.
- **1.0.0-beta:** the chosen launch scope is implemented and feature work is
  substantially frozen. Remaining work centers on reliability, balance,
  accessibility, performance and presentation. Select concrete Beta acceptance
  checks before declaring it.
- **1.0.0:** the agreed launch scope and quality gates are accepted, including
  ordinary-player and long-run playtests, supported-platform builds and an
  explicit compatibility/support policy. It does not require every future idea.

Stages are earned through acceptance, not elapsed time or a count of commits.
No release date or percentage follows from these numbers alone.

## Compatibility is a separate contract

Keep run-save and profile-format versions independent of game milestones; the
code already has separate versions for them. Each release's notes must state
whether earlier runs/profiles load, require migration, or are unsupported. Where
migration is needed, preserve the original data. A patch is expected to preserve
existing runs; any unavoidable exception needs an explicit explanation before
publication. A milestone bump alone neither guarantees nor excuses a break.

Apply the same explicit approach to future mod or network interfaces if those
become supported. Do not infer their compatibility from the game's milestone name.

## Release discipline

- Change version and notes per release, not per commit. Include the exact scope,
  known limitations and compatibility statement.
- Publish only the accepted, verified source through the existing release flow;
  check Linux, Windows and macOS builds and playtest the milestone outcome.
- Keep published tags and artifacts immutable. Corrections get another version.
- Update the roadmap with built, in-progress and planned status. Selecting a
  release name does not approve every feature proposed for it.

If this proposal is adopted, reconcile the short summaries in README and the
roadmap with one canonical policy rather than maintaining three separate rules.
