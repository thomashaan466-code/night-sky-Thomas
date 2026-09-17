# Night Sky Thomas — PWA baseline acceptance plan

## Doel

De PWA moet betrouwbaar antwoord geven op: **moet ik nu of tijdens een komende relevante periode naar buiten?** De native iOS-code blijft behouden als aparte experimentele/reference-lijn totdat daar opnieuw bewust voor wordt gekozen en fysieke iPhone-validatie beschikbaar is.

## Baseline-eisen

1. De app laadt live weer, maancontext, ISS-kandidaten en auroracontext zonder een bronfout als positief advies te interpreteren.
2. Runtime locatie is leidend. Bij geweigerde/onbeschikbare browserlocatie wordt een algemene Middelburg-fallback transparant getoond; exacte privé-thuiscoördinaten worden niet gecommit.
3. Een geometrische ISS-passage wordt alleen als kijkkandidaat behandeld wanneer de waarnemershemel voldoende donker is en de satelliet volgens het geïmplementeerde schaduwmodel zonverlicht is.
4. TLE/GP-data heeft een expliciete freshness-status. Verouderde of ontbrekende data mag geen schijnbaar actueel advies produceren.
5. Weer voor een toekomstig observatiemoment wordt gekoppeld aan het relevante forecasttijdstip. Buiten het beschikbare forecastvenster wordt geen schijnprecisie getoond.
6. Bron-, loading-, offline-, stale- en no-data-states zijn zichtbaar en conservatief.
7. De interface werkt op een iPhone-breedte van ongeveer 390 px zonder horizontale overflow of afgesneden hoofdinhoud.
8. De PWA bevat manifest, herkenbare iconen, service worker, navigatiefallback en HTTPS-publicatie via één Pages-workflow.
9. Syntaxcontrole en deterministische kerntests draaien automatisch op de actieve recovery/integratiebranches en pull requests.
10. Productietekst maakt geen niet-gevalideerde claims over magnitude, zichtbaarheid, auroragarantie of andere meetwaarden.

## Astronomische grenzen

- Een ISS-kijkkandidaat is geen helderheidsgarantie zolang magnitude niet betrouwbaar wordt berekend.
- Boven de horizon betekent niet automatisch zichtbaar.
- NOAA/SWPC-auroradata is probabilistisch en geen lokale zichtbaarheidsgarantie.
- Random meteoren/vuurballen worden niet als voorspelbare gebeurtenissen gepresenteerd.
- Een toekomstige Sky Score moet belang, hoogte, duur, helderheid waar beschikbaar, twilight, event-time weer, satellietbelichting en betrouwbaarheid scheiden.

## Recovery-acceptatie

De recovery mag pas naar de normale ontwikkelroute wanneer:

- PWA Actions groen zijn op de actuele recovery HEAD;
- de live HTTPS-PWA handmatig is gecontroleerd op een echte mobiele browser;
- loading/no-data/offline/stale-gedrag begrijpelijk is;
- er één deploymentpad is;
- README, `docs/PROJECT_STATE.md` en dit document dezelfde productrichting beschrijven;
- de belangrijkste astronomische logica niet alleen compileert/test maar waar mogelijk met onafhankelijke referentiecases is gecontroleerd;
- openstaande bekende betrouwbaarheidsproblemen expliciet als issue zijn vastgelegd.

## Na recovery

Gebruik één normale flow: issue → korte featurebranch → tests → PR → CI → review → merge. Eerst de betrouwbare Tonight-baseline verbeteren; pas daarna kalender, scoring, notificaties, brede eventcatalogus of AR/native uitbreiden.
