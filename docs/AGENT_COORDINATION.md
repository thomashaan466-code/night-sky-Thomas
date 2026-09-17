# Agent coordination (GitHub)

Dit project gebruikt GitHub als gedeelde coördinatielaag voor Claude, ChatGPT/Copilot en menselijke bijdragers.

## Project en labels

- GitHub Project: `NightSkyThomas Coordination`
- Coordinator-labels:
  - `coord`
  - `coord:claimed`
  - `coord:blocked`
  - `coord:ready-for-review`

## Claim- en heartbeat-regels

1. Claim een issue door jezelf toe te wijzen en label `coord:claimed` te zetten.
2. Post een heartbeat in UTC in het issue bij actieve werkzaamheden (richtlijn: elke 24 uur).
3. Als je blokkeert, update de status direct en zet label `coord:blocked`.
4. Als werk klaar is voor controle, zet label `coord:ready-for-review`.
5. Laat een claim los als je niet meer actief bent, zodat anderen kunnen overnemen.

## PR-conventies

- Gebruik voor coördinatie-werk een titel met prefix `[coord]`.
- Link het issue in de PR-beschrijving met `Closes owner/repo#nummer`.
- Neem in de PR-beschrijving een `Heartbeat (UTC)` regel op.
- Houd wijzigingen klein en beperkt tot coördinatiebestanden waar mogelijk.

## Actieve issue-koppelingen

- Gebruik issue references (`Closes ...`) in elke coordinator-PR.
- Bewaak actieve technische issues via het `NightSkyThomas Coordination` project.
