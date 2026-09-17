# Recovery inventory — 2026-09-17

This document records what is intentionally preserved while Night Sky Thomas is consolidated. It prevents future agents from interpreting closed PRs or old branches as lost work.

## Branches and their role

- `main`: historical stable/default branch. It also contains old Pages/Jekyll commits that must not be treated as the desired PWA deployment architecture.
- `develop`: substantial native Swift/astronomy implementation. Preserve as reference until a later deliberate branch reconciliation.
- `pwa-hobby`: original PWA development branch built on top of `develop`. Superseded for active work by the recovery branch.
- `thomashaan466-code-pwa-hobby-improvements`: one-commit improvement branch used as the recovery starting point. Its changes are already contained in recovery.
- `recovery/clean-pwa-baseline`: current consolidation branch and only active recovery implementation line.
- `copilot/coordination-*` and `docs/8-github-agent-coordination`: process experiments. Do not use as implementation bases.

## Valuable native work to preserve

The native line contains implementations/tests for Core Location, CelesTrak GP/TLE access, SwiftSGP4-based propagation, rise/culmination/set detection, astronomy coordinate math, solar position/shadow logic, satellite illumination, Open-Meteo current/event-time forecast handling, NOAA SWPC space-weather access, notification foundations, models and XcodeGen/CI.

These are not automatically production-valid for the PWA. They are valuable for requirements, regression ideas and independent cross-checking. Reuse deliberately, not by copy/paste assumption.

## Valuable PWA work preserved in recovery

The recovery branch contains the installable static PWA, mobile UI, runtime geolocation/fallback, live weather, ISS/TLE handling, moon and aurora context, deterministic core helpers/tests, service worker, offline last-known snapshot, stale/error messaging, Pages workflow and PWA CI.

## Open historical work

Native issues about SGP4, visibility/scoring, AR, build reproducibility and live-event assembly contain useful requirements. They should be classified as reference/later or rewritten for the PWA rather than blindly executed as native tasks.

The multiple coordination PRs were experiments toward GitHub-based multi-agent collaboration. The useful principle is retained: GitHub is shared source of truth. The heavy heartbeat/parallel coordinator machinery is not required for routine work on this personal project.

## Recovery decision

Do not create another clean repository and do not reset history. Consolidate on the recovery branch, validate it, then promote through reviewed GitHub integration. This keeps scientific work auditable while giving day-to-day development a clean operational starting point.
