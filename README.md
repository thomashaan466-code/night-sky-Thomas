# Night Sky Thomas 🌌

Night Sky Thomas is een persoonlijke, mobile-first PWA met één hoofdvraag:

> **Is er nu of binnenkort iets bijzonders aan de hemel waarvoor ik naar buiten moet?**

## Huidige productrichting

De PWA in `pwa/` is het primaire product. Het eerste doel is een betrouwbare HTTPS-webapp die op iPhone, iPad en desktop werkt zonder account, betaalde backend, App Store-publicatie of Xcode.

De bestaande Swift/SwiftUI-code blijft behouden als experimentele/reference-lijn. Daarin zit waardevol werk voor onder andere satellietberekeningen en databronnen, maar native iOS is tijdens de huidige recovery niet de primaire delivery-route.

**Actieve herstelbranch:** `recovery/clean-pwa-baseline`. Start tijdens de recovery geen nieuw werk vanaf `pwa-hobby` of de oude agent/coördinatiebranches.

Zie `docs/PROJECT_STATE.md` voor de actuele technische source of truth, `docs/RECOVERY_INVENTORY.md` voor wat uit eerdere lijnen wordt behouden en issue #15 voor het recovery-plan.

## Wat de huidige PWA doet

- runtime locatie met transparante fallback wanneer locatie niet beschikbaar is;
- lokaal weer en forecastcontext via Open-Meteo;
- ISS/satellietkandidaten op basis van actuele/cached brondata;
- onderscheid tussen satellietgeometrie, duisternis en satellietbelichting;
- maan- en auroracontext;
- expliciete loading-, stale-, offline- en bronfoutstates;
- installable PWA-shell met service worker en offline laatst bekende controle;
- deterministische kerntests in `pwa/tests/`.

Een satelliet wordt niet alleen omdat hij boven de horizon staat als praktisch zichtbaar beschouwd. Helderheid/magnitude wordt niet verzonnen wanneer die niet betrouwbaar berekend wordt. Aurora blijft een probabilistisch signaal.

## Techniek

De primaire webimplementatie is statisch en privacy-first:

- `pwa/index.html` — mobile-first Tonight-interface;
- `pwa/app.js` — runtime locatie, live databronnen en event-assembly;
- `pwa/core.js` — deterministische kernlogica voor weer/schaduw;
- `pwa/sw.js` — offline shell en navigatiefallback;
- `.github/workflows/pwa.yml` — automatische PWA-validatie;
- `.github/workflows/pages.yml` — GitHub Pages-deployment;
- `.github/workflows/ios.yml` — alleen handmatige validatie van de optionele native lijn.

Belangrijke bronnen zijn CelesTrak voor satellietdata, NOAA/SWPC voor ruimteweer en Open-Meteo voor weer. Exacte privé-thuiscoördinaten horen niet in de repository; runtime locatie is leidend.

## Roadmap

### Nu — betrouwbare baseline

Eén stabiele PWA, live bronnen, duidelijke bron/freshness-status, betrouwbare ISS-kandidaten, weer op relevant tijdstip, conservatieve foutafhandeling, goede mobiele UI en één deploymentpad.

### Daarna — sky intelligence

Sky Score, betere eventselectie, meer gevalideerde hemelverschijnselen, kalender/tijdlijn en slimme aanbevelingen. Toekomstige gebeurtenissen worden beoordeeld met forecastcondities op het gebeurtenistijdstip.

### Later — geavanceerde ervaring

Notificaties, uitgebreidere finderfuncties en eventueel native iOS/AR. AR wordt pas serieus gebouwd wanneer eventcoördinaten betrouwbaar zijn en heading/attitude/camera fysiek op een iPhone kunnen worden gevalideerd.

## Werkwijze

GitHub is de gedeelde source of truth voor Thomas, ChatGPT, Claude en Copilot. Normaal werk volgt: **issue → korte branch → implementatie + tests → PR → CI → review → merge**. Bouw geen aparte coördinatiebackend of parallelle verborgen projectstatus.

Betrouwbaarheid gaat vóór hoeveelheid features. Een groene compiler of workflow bewijst niet automatisch dat een astronomische uitkomst inhoudelijk correct is.
