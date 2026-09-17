# Night Sky Thomas — afrondingsplan

## Doel

De PWA beantwoordt betrouwbaar één vraag: **moet ik nu of tijdens de eerstvolgende donkere periode naar buiten?** De statische PWA is de primaire productrichting voor privégebruik. De native iOS-code blijft legacy/optioneel; een volledige Xcode-omgeving, signing of fysieke iPhone-validatie is geen voorwaarde voor de PWA.

## Testbare eisen

1. Wanneer de app opent, zal zij live weer, maancontext, ISS-kandidaten en auroradata laden zonder een bronfout als positief advies te interpreteren.
2. Wanneer de gebruiker locatietoegang weigert of de browserlocatie niet beschikbaar is, zal de app transparant terugvallen op Middelburg op plaatsniveau.
3. Wanneer een ISS geometrisch boven de minimumhoogte komt, zal de app deze alleen als kijkkandidaat tonen als de waarnemershemel voldoende donker en de satelliet volgens het schaduwmodel zonverlicht is.
4. Als actuele TLE-data niet beschikbaar zijn, zal de app alleen cachedata jonger dan 24 uur gebruiken en dit zichtbaar melden.
5. Wanneer een donker venster binnen de weershorizon valt, zal de app het gunstigste halfuur bepalen op basis van bewolking en neerslag.
6. Als een gevraagd weermoment meer dan 90 minuten buiten de beschikbare uurverwachting ligt, zal de app weigeren een schijnbaar nauwkeurige weerswaarde te tonen.
7. Wanneer de bronbranch `pwa-hobby` wijzigt, zullen syntaxcontrole, deterministische kerntests en GitHub Pages-deployment automatisch draaien.
8. De interface zal op een iPhone-breedte van 390 pixels zonder horizontale overflow of afgesneden hoofdinhoud werken.
9. De app zal een manifest, herkenbaar pictogram, service worker, offline navigatiefallback en veilige HTTPS-publicatie bevatten.
10. Wanneer live bronnen tijdelijk niet beschikbaar zijn, zal een eerder opgeslagen controle zichtbaar als oud en niet-live worden gemarkeerd; zonder snapshot blijft het advies expliciet onbeschikbaar.

## Bewuste grenzen

- Een ISS-kijkkandidaat is geen helderheidsgarantie; de PWA berekent nog geen magnitude.
- NOAA OVATION is een probabilistisch signaal en geen lokale zichtbaarheidsgarantie.
- De PWA geeft geen pushnotificaties, accounts, backend of AR-overlay.
- AR wordt pas gebouwd als heading, attitude, camera en kalibratie fysiek op een iPhone kunnen worden getest.
- Offline modus toont alleen de laatst bekende controle; hij claimt geen actuele zichtbaarheid.

## Acceptatie

- Lokale Node-tests groen.
- PWA GitHub Actions groen.
- Pages-deployment groen.
- Live HTTPS-pagina laadt actuele gegevens en heeft geen consolefouten.
- Loading-, geladen en bronfoutgedrag zijn conservatief en begrijpelijk.
