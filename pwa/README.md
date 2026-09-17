# Night Sky Thomas — persoonlijke PWA

Dit is de bewust kleine hobbyversie van Night Sky Thomas. De bestaande native iOS-code blijft onaangetast.

## Live versie

[Open Night Sky Thomas](https://thomashaan466-code.github.io/night-sky-Thomas/)

## Wat deze versie doet
- vraagt browserlocatie; valt bij weigering terug op Middelburg (alleen plaatsniveau)
- haalt actueel/verwacht weer op via Open-Meteo
- berekent zonshoogte en maancontext met Astronomy Engine
- haalt actuele ISS GP/TLE-data op bij CelesTrak en propageert die met satellite.js
- telt een ISS-pass niet automatisch als zichtbaar: minimale hoogte, donkere/schemerige waarnemershemel en een eenvoudige Earth-shadow-test worden gecombineerd
- toont NOAA SWPC OVATION als indicatieve aurorasignalering
- geeft een conservatief 'naar buiten'-advies en een knop naar Stellarium Web

## Lokaal testen
Een service worker en geolocatie vereisen een secure context. `localhost` is toegestaan. Start vanuit de repository bijvoorbeeld:

```sh
cd pwa
python3 -m http.server 8080
```

Open daarna `http://localhost:8080`.

## Publiceren
Een push naar `pwa-hobby` publiceert de map `pwa/` automatisch via GitHub Pages. De map is volledig statisch en kan ook op iedere andere HTTPS static host worden geplaatst.

Voor iPhone: open de live HTTPS-url in Safari en kies **Zet op beginscherm**.

## Bewuste grenzen
Dit is geen professionele astronomische alertingdienst. Aurora is probabilistisch. De ISS-schaduwtest is bewust conservatief maar eenvoudiger dan de gevalideerde native illumination-laag. Externe browserrequests kunnen door CORS/providerbeleid uitvallen; in dat geval wordt geen positief advies geforceerd. Geen accounts, backend, pushnotificaties of AR.
