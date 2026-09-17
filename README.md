# Night Sky Thomas 🌌

Een persoonlijke iPhone-app die automatisch interessante gebeurtenissen aan de hemel boven Middelburg ontdekt, beoordeelt en helpt vinden.

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

Native iOS-app in Swift + SwiftUI.

Belangrijkste lagen:

- `App` — lifecycle en navigatie
- `Models` — uniforme SkyEvent- en observatiemodellen
- `Services` — weer, satellieten, astronomie, ruimteweer en locatie
- `Scoring` — Sky Score en zichtbaarheid
- `Features/Tonight` — dashboard
- `Features/Calendar` — kalender
- `Features/EventDetail` — eventinformatie
- `Features/ARFinder` — camera/AR-richtingzoeker
- `Features/Settings` — voorkeuren en notificatiedrempels

## Ontwikkeling en validatie

Deze repo bevat nu ook een Swift Package voor de core-logica (`NightSkyThomasCore`) zodat build en tests in CI reproduceerbaar draaien.

- Build: `swift build`
- Tests: `swift test`

## Databronnen

Geplande bronnen zijn onder meer CelesTrak voor satellietbaangegevens, NOAA SWPC voor ruimteweer/aurora en Open-Meteo voor lokaal weer. Astronomische posities worden waar mogelijk lokaal berekend zodat de app niet afhankelijk is van één externe dienst.

## Roadmap

### V1 — bruikbare kern
Tonight, kalender, uniform eventmodel, locatie, weer, demo/live providers en Sky Score.

### V2 — live sky intelligence
Satellietpassages, ruimteweer, betere astronomische berekeningen, slimme filters en lokale notificaties.

### V3 — AR
Camera-overlay, kompas/heading, elevatie-indicator, live countdown en voorspelde baan over de hemel.

### V4 — polish
Widgets, Live Activities, favorieten, historie, observatielog en verdere personalisatie.

## Privacy

De app is personal-first. Locatie wordt alleen gebruikt om lokale zichtbaarheid te berekenen. Waar mogelijk blijven berekeningen en voorkeuren op het toestel.
