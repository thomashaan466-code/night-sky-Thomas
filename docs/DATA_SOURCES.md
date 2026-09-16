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

The current implementation downloads TLE data and propagates it with SwiftSGP4 pinned to revision `ab0fdc88e9799ae0435c1426a697838d0efdd261`. That revision identifies propagated position and velocity as TEME and includes Vallado-family verification vectors. Night Sky Thomas independently tests its own pass-window and observer-geometry layer; the upstream test claim is not treated as validation of our full pipeline.

`SatellitePassService` currently returns only passes whose rise, culmination and set all occur inside the requested window. A pass already in progress is omitted instead of fabricating `rise = queryStart`. A separate live-pass representation is still needed before Live Sky can show an ongoing pass correctly.

### Coordinate frames and satellite illumination

SwiftSGP4 propagation returns TEME kilometers. Night Sky Thomas converts satellite positions through SwiftSGP4's date-aware TEME-to-ECEF/PEF path before comparing them with the Sun. The solar vector is generated directly in the same Earth-fixed frame, and `EarthFixedPosition` makes accidental TEME/J2000/ECEF mixing harder at compile time.

The conversion follows Vallado's recommended TEME-to-PEF rotation using GMST. As in the pinned library, UTC is used as a practical approximation for UT1; this is acceptable at current TLE/SGP4 accuracy but remains a documented limitation.

The shadow model distinguishes `sunlit`, `penumbra` and `umbra` using apparent Earth/Sun disk overlap. It has:

- analytic synthetic geometry tests;
- a JPL Horizons reference check for solar direction;
- real Vanguard 1 propagation cases independently checked with Skyfield and JPL DE421.

The current Sun model uses NOAA's fractional-year declination/equation-of-time approximation and a constant astronomical-unit distance. The pinned JPL direction case differs by about 0.1°, which is suitable for this checkpoint but not yet enough to claim high-precision eclipse-transition timing. Illumination is also not yet combined with observer darkness, elevation, brightness and weather. A geometric pass must therefore still **not** be labelled visible.

Primary references:

- [CelesTrak/Vallado, Revisiting Spacetrack Report #3](https://celestrak.org/publications/AIAA/2006-6753/AIAA-2006-6753-Rev2.pdf)
- [NOAA general solar-position equations](https://gml.noaa.gov/grad/solcalc/solareqns.PDF)
- [JPL Horizons](https://ssd.jpl.nasa.gov/horizons/)
- [SwiftSGP4 upstream](https://github.com/hjoliveira/swift-sgp4)

### NOAA SWPC
Use official SWPC JSON products for geomagnetic conditions and OVATION aurora data. Kp alone is not sufficient to promise visible aurora from Middelburg. The eventual aurora score must combine current/forecast space weather, OVATION geography, darkness and cloud cover.

### Open-Meteo
Use hourly forecast variables, not only current conditions, when scoring future events. Desired fields include total/low/mid/high cloud cover, visibility, precipitation probability and weather code.

### Apple frameworks
Core Location supplies geographic position and true/magnetic heading. Heading needs a physical iPhone with a magnetometer and cannot be validated in Simulator. AR overlays should treat compass accuracy explicitly and offer calibration guidance rather than pretending the overlay is pixel-perfect.

## Next engineering milestones

- Validate pass azimuth/elevation and rise/max/set times against an independent external reference dataset.
- Quantify solar-vector error over seasons/years and refine eclipse-transition timing if needed.
- Represent an already-running pass without inventing a rise time.
- Combine geometric passes with illumination and observer twilight without calling that a final visibility guarantee.
- Feed hourly weather into visibility only when the event timestamp is inside the fetched forecast window.
- Build OVATION sampling for the observer's geomagnetic location.
- Add notification policy and deduplication.
- Implement camera preview + heading/elevation HUD, then AR trajectory overlays.
- Add unit tests for astronomy math, scoring and parsers.
