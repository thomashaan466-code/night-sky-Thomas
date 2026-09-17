# Night Sky Thomas 🌌

Een persoonlijke, mobile-first PWA die automatisch interessante gebeurtenissen aan de hemel boven Middelburg ontdekt, beoordeelt en helpt vinden.

De PWA is het primaire product voor dit hobbyproject: statisch, privacy-first en bruikbaar op telefoon en desktop zonder account, backend of betaalde dienst. De bestaande Swift-code blijft beschikbaar als legacy/optionele experimentele lijn; Xcode, signing en een Apple Developer-account zijn niet nodig om de PWA te gebruiken of te publiceren.

## Missie

Night Sky Thomas beantwoordt één vraag: **is er iets aan de hemel waarvoor ik nu of binnenkort naar buiten moet?**

De app combineert astronomische gebeurtenissen, satellietpassages, ruimteweer en lokaal weer. Alleen interessante gebeurtenissen krijgen prioriteit. De uiteindelijke ervaring bevat een Tonight-dashboard, kalender, eventdetails, slimme alerts en een AR Finder die laat zien waar de gebruiker moet kijken.

## Kernfuncties

- Tonight-dashboard met de beste komende gebeurtenissen
- Persoonlijke Sky Score per gebeurtenis
- Kalender voor ISS, satellieten, aurora, meteoren, planeten, maan, kometen en verduisteringen
- Lokale weers- en bewolkingscorrectie
- Countdown en kijkrichting (azimut/elevatie)
- Slimme notificaties zonder onnodige meldingen
- AR Finder met camera, kompas en bewegingssensoren
- Middelburg als persoonlijke thuislocatie, met ondersteuning voor andere locaties later

## Techniek

Statische PWA in `pwa/` met vanilla JavaScript, een service worker en GitHub Pages.

Belangrijkste PWA-lagen:

- `pwa/index.html` — Tonight-scherm en bronstatus
- `pwa/app.js` — locatie, weer, ISS, maan, aurora en offline snapshot
- `pwa/core.js` — deterministische weers- en schaduwberekeningen
- `pwa/sw.js` — offline shell en navigatiefallback

De Swift/SwiftUI-map is legacy en optioneel. De iOS-workflow draait niet automatisch; alleen de PWA-checks en Pages-deployment zijn onderdeel van de normale hobby-ontwikkelroute.

## Databronnen

Geplande bronnen zijn onder meer CelesTrak voor satellietbaangegevens, NOAA SWPC voor ruimteweer/aurora en Open-Meteo voor lokaal weer. Astronomische posities worden waar mogelijk lokaal berekend zodat de app niet afhankelijk is van één externe dienst.

## Roadmap

### V1 — bruikbare PWA-kern
Tonight, locatie, weer, live/demo-bronnen, Sky Score, installatie en offline laatst bekende controle.

### V2 — live sky intelligence
Satellietpassages, ruimteweer, betere astronomische berekeningen, slimme filters en lokale notificaties.

### V3 — AR
Camera-overlay, kompas/heading, elevatie-indicator, live countdown en voorspelde baan over de hemel.

### V4 — polish
Widgets, Live Activities, favorieten, historie, observatielog en verdere personalisatie.

## Privacy

De app is personal-first. Locatie wordt alleen gebruikt om lokale zichtbaarheid te berekenen. Waar mogelijk blijven berekeningen en voorkeuren op het toestel.
