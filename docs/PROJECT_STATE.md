# Night Sky Thomas — canonical project state

Last updated: 2026-09-17

## Product direction

Night Sky Thomas is currently a personal, mobile-first PWA. Its primary question is:

> Is er nu of binnenkort iets bijzonders aan de hemel waarvoor ik naar buiten moet?

The first delivery target is a trustworthy HTTPS web app that works on iPhone, iPad and desktop without an account, paid backend, App Store distribution or Xcode requirement.

The existing Swift/SwiftUI implementation is preserved as an experimental/reference line. It contains useful astronomy and service work and must not be deleted casually, but it is not the primary delivery route during the recovery phase.

## Current integration state

Temporary recovery branch: `recovery/clean-pwa-baseline`

Recovery tracking issue: #15

The recovery branch was created from the tested PWA improvement head. During recovery it is the only branch on which consolidation work should be performed. Do not start new work from the older `pwa-hobby` or agent coordination branches.

`main` remains the stable historical branch until recovery is validated and deliberately promoted. `develop` contains substantial native/astronomy work and remains an important reference; it must not be force-reset or discarded.

## Reliability rules

A satellite being geometrically above the horizon is not sufficient to call it visible. Visibility decisions must distinguish at least geometry, observer darkness/twilight, satellite illumination/Earth shadow, event-time weather and practical visibility. Use current TLE/GP data and validated propagation. Use UTC internally where practical and local time for presentation. Do not fabricate source data, brightness or events when a source is unavailable.

Aurora information is probabilistic and must be presented as such. Random meteors/fireballs are not predictable events. Future-event scoring must use forecast conditions for the event timestamp rather than current weather alone.

## Development workflow

Use GitHub as the shared source of truth for ChatGPT, Claude, Copilot and human work.

Normal flow after recovery:

1. One focused GitHub issue defines objective, scope and acceptance criteria.
2. One active owner/agent works on one short-lived branch.
3. Add deterministic tests where silent wrong answers are possible.
4. Open a focused pull request linked to the issue.
5. Relevant GitHub Actions must pass.
6. Review scientific/astronomical correctness separately from compilation.
7. Merge only after the change actually meets its acceptance criteria.

No routine heartbeat protocol is required. When handing work to another agent, leave one concise GitHub comment containing branch, latest commit, validation status and next concrete step.

## CI and deployment during recovery

`PWA checks` runs on the recovery branch and is prepared for future `develop`/`main` integration. The iOS workflow is manual-only. The Pages workflow temporarily deploys the recovery branch so the recovery baseline can be checked as a real HTTPS PWA before promotion.

After recovery is accepted, change the Pages deployment source to the final stable branch and remove obsolete deployment workflows from the stable history through a reviewed integration PR.

## Preserved native assets

The native line includes work around Core Location, CelesTrak TLE/GP, SGP4 pass prediction, satellite illumination, astronomy math, NOAA SWPC, Open-Meteo event-time weather, notifications and deterministic tests. Treat these as reference implementations and possible sources for cross-validation or later native development; do not assume browser JavaScript and Swift implementations are automatically equivalent.

## Near-term product scope

Prioritize: live runtime location with privacy-safe fallback; weather at observation/event time; trustworthy ISS/satellite candidates; observer darkness; Earth-shadow/satellite illumination; source freshness; conservative no-data/error states; moon context; probabilistic aurora context; clear Tonight UI; installable/offline-safe PWA behavior.

Defer until the baseline is trustworthy: AR camera overlay, native widgets/Live Activities, App Store work, accounts, paid backend, complex multi-agent infrastructure and broad feature expansion.

## Definition of a trustworthy baseline

The app loads over HTTPS on a real phone, uses live sources without treating source failure as positive advice, clearly exposes stale/no-data states, passes deterministic PWA tests, has one unambiguous deployment path, contains no committed exact private home location, and does not describe an astronomical event as practically visible unless the implemented evidence supports that claim.
