# Night Sky Thomas — Data & accuracy notes

## Principles

1. Never label demo or stale data as live.
2. Every generated event should retain its source and fetch/calculation time.
3. Visibility is separate from astronomical possibility: an event can exist but be hidden by cloud, daylight or geometry.
4. Prefer on-device calculations after downloading the minimum source data needed.
5. Cache orbital data instead of repeatedly querying upstream providers.

## Sources

### CelesTrak
Use General Perturbations data for satellites. Prefer JSON/OMM rather than building new code around legacy fixed-width TLE only. Cache a catalog object's GP response for up to two hours because CelesTrak's published usage policy states GP updates occur every two hours.

ISS NORAD catalog number: 25544.

A validated SGP4 implementation is required before satellite passes are advertised as accurate. `CelesTrakService` currently downloads/parses orbital elements; it does **not** yet claim to propagate them.

### NOAA SWPC
Use official SWPC JSON products for geomagnetic conditions and OVATION aurora data. Kp alone is not sufficient to promise visible aurora from Middelburg. The eventual aurora score must combine current/forecast space weather, OVATION geography, darkness and cloud cover.

### Open-Meteo
Use hourly forecast variables, not only current conditions, when scoring future events. Desired fields include total/low/mid/high cloud cover, visibility, precipitation probability and weather code.

### Apple frameworks
Core Location supplies geographic position and true/magnetic heading. Heading needs a physical iPhone with a magnetometer and cannot be validated in Simulator. AR overlays should treat compass accuracy explicitly and offer calibration guidance rather than pretending the overlay is pixel-perfect.

## Next engineering milestones

- Integrate a verified SGP4 implementation and verification vectors.
- Generate rise/max/set passes for ISS and selected bright satellites for the observer location.
- Upgrade weather service to hourly time-aligned forecasts.
- Build OVATION sampling for the observer's geomagnetic location.
- Add notification policy and deduplication.
- Implement camera preview + heading/elevation HUD, then AR trajectory overlays.
- Add unit tests for astronomy math, scoring and parsers.
