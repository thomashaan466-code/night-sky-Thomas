# GitHub-coördinatie voor coding agents

Deze repository gebruikt GitHub als goedkope, controleerbare coördinatielaag voor
Claude, ChatGPT/Copilot en menselijke bijdragers. GitHub Issues zijn de bron van
waarheid; branches en pull requests bevatten het werk. Er is geen betaalde
backend en er staan geen API-sleutels in de iOS-app.

## Eenmalige handmatige setup

De repository gebruikt het GitHub Project **NightSkyThomas Coordination** en
de labels hieronder. Controleer na een fork of nieuwe repository dat deze
resources bestaan; gebruik geen hardcoded numeric Project-ID in code.

1. Koppel **NightSkyThomas Coordination** aan deze repository. Gebruik voor
   een nieuwe repository een Board met kolommen `Backlog`, `Ready`,
   `In progress`, `Review`, `Done` en `Blocked`.
2. Controleer de labels `coordination`, `agent:claude`, `agent:chatgpt`,
   `status:claimed`, `status:blocked`, `status:review` en `scope:docs`.
   Bestaande labels mogen dezelfde betekenis houden; dupliceer ze niet.
3. Voeg nieuwe issues handmatig of via
   de Project-automation toe. Gebruik geen hardcoded numeric Project-ID in code.
4. Geef iedere agent alleen de GitHub/MCP-rechten die nodig zijn: issues lezen
   en bijwerken, branches maken, en pull requests openen. Gebruik liever een
   persoonlijke of GitHub App-token buiten de app dan een token in deze repo.

De bestaande projectstatus gebruikt de standaard GitHub-opties `Todo`,
`In Progress` en `Done`. De canonieke detailstatus blijft in de issuevelden;
gebruik labels en issuecomments voor `Blocked`, `Review` en heartbeat-informatie.

## Werken vanaf iPad of telefoon

De repository en taakstatus staan op GitHub, dus je hoeft niet op dezelfde wifi
te zitten en je hoeft de Mac niet als enige toegangspunt te gebruiken.

1. Open GitHub in de browser of de GitHub-app en gebruik dezelfde account.
2. Open **NightSkyThomas Coordination** voor de actuele taken en open issue #8
   of een nieuwe `Coordinator task` voor werk.
3. Gebruik de mobiele Claude-, ChatGPT- of Copilot-app alleen met de officiële
   GitHub-verbinding. Controleer vóór een schrijfactie repository,
   issue-nummer, branch en agentclaim.
4. Laat de Mac code uitvoeren, testen en commits maken. De resultaten horen in
   de issue en pull request; de Mac hoeft niet handmatig bediend te worden
   vanaf de telefoon.
5. Gebruik vanaf mobiel vooral lezen, prioriteren, claimen, blokkeren en
   reviewen. Geef codewijzigingen als een expliciete issue-opdracht.

Een werkende Mac is handig voor Xcode en iOS Simulator, maar is geen
single-point-of-failure voor de projectstatus. Als de Mac uitvalt, blijven
issues, branches, PR's, reviews en CI beschikbaar. Start geen publiek
toegankelijke SSH- of remote-desktoppoort alleen voor deze workflow; gebruik
de bestaande beveiligde externe-beheeroplossing of een private VPN en bewaar
credentials uitsluitend in de betreffende app of secret store.

### Mobiele overdracht

Gebruik bij pauzeren één issuecommentaar met:

```text
HANDOFF
Agent: claude|chatgpt|human
Status: paused|blocked|ready-for-review
Branch: agent/<issue-number>-<short-slug>
Commit: <sha of laatste commit>
Next: <één concrete volgende stap>
Heartbeat: <UTC ISO 8601>
```

De volgende agent leest eerst dit commentaar, de laatste commit en de CI-status.
Zo blijft de overdracht volledig op GitHub staan en is geen chatgeschiedenis op
de telefoon of Mac vereist.

## Werkstroom

### 1. Taak aanmaken

Gebruik **Coordinator task** en vul alle velden in. De issue is het contract:
objective, scope/files, dependencies, acceptance criteria, assigned agent,
status, branch en heartbeat moeten altijd actueel zijn. Eén issue beschrijft
één samenhangende wijziging.

### 2. Claimen

Lees eerst de issue, openstaande PR's en recente wijzigingen. Claim daarna de
taak in één update:

- zet `Assigned agent` op `claude`, `chatgpt` of een menselijke naam;
- zet `Status` op `claimed` en voeg `status:claimed` toe;
- kies een branch volgens `agent/<issue-number>-<korte-slug>`; bijvoorbeeld
  `agent/42-coordinate-docs`;
- vul `Branch` en `Heartbeat` in met een UTC-tijdstip in ISO 8601;
- verplaats het Project-item naar `In progress`.

Claim geen issue dat al door een andere agent is geclaimd. Bij twijfel wint de
oudste heartbeat; vraag een maintainer voordat je een claim overschrijft.

### 3. Heartbeat en release

Werk de heartbeat bij bij iedere betekenisvolle voortgang en minimaal iedere
30 minuten tijdens actief werk. Een heartbeat ouder dan 2 uur is stale. Een
andere agent mag een stale taak niet stilzwijgend overnemen: reageer eerst op
de issue en geef de oorspronkelijke agent een redelijke kans om de claim te
verlengen.

Bij pauzeren of afronden:

- zet `Status` op `paused`, `blocked` of `ready-for-review`;
- noteer wat nog ontbreekt en de laatste branch/commit;
- verwijder `status:claimed` wanneer je de taak vrijgeeft;
- verplaats het Project-item naar `Blocked` of `Review`.

### 4. Pull request

Open één PR per issue en link die met `Closes #<nummer>`. De PR moet bevatten:

- een korte samenvatting en expliciete scope;
- test- of validatieresultaten;
- eventuele risico's, migraties of handmatige setup;
- de exacte issue- en branchreferentie.

PR-titels beginnen met `[coord]` voor coördinatie/documentatiewerk of met een
normale, beschrijvende titel voor app-code. Houd wijzigingen klein. Voeg geen
API-sleutels, project-ID's, persoonlijke tokens of gegenereerde Xcode-bestanden
toe. Reviews en CI zijn vereist voordat de maintainer merge't.

## Conflictvermijding

- Claim eerst; werk niet rechtstreeks op `main` of `develop`.
- Raak geen bestanden buiten de issue-scope aan.
- Synchroniseer vóór een grote wijziging en los conflicten op de eigen branch op.
- Kies bij overlappende claims één eigenaar en maak afhankelijkheden expliciet
  in `Dependencies`; splits anders het werk in aparte issues.
- Gebruik GitHub/MCP voor issue-, branch- en PR-status. Gebruik lokale bestanden
  alleen voor de implementatie en tests; vertrouw niet op een tweede, verborgen
  coördinatiedatabase.

## GitHub/MCP-richtlijnen

Agents mogen via GitHub of MCP issues, labels, branches en PR's lezen en
bijwerken volgens hun toegekende rechten. Controleer altijd repository,
issue-nummer en branch voordat je schrijft. Gebruik geen aannames over een
Project-ID en maak geen remote resources aan zonder expliciete maintaineractie.
Bij tegenstrijdige statusinformatie is de issuecommentaar met de nieuwste UTC
heartbeat leidend; meld afwijkingen in de issue.

## Canonieke statuswaarden

`ready`, `claimed`, `in-progress`, `blocked`, `ready-for-review`, `paused`,
`done`.

Gebruik labels voor filtering (`coordination`, `agent:*`, `status:*`,
`scope:*`), maar bewaar de volledige waarheid in de issuevelden. Een label
alleen is geen claim.
