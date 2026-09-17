const $ = id => document.getElementById(id);
const FALLBACK = { lat: 51.4988, lon: 3.6136, name: 'Middelburg (fallback)' };
const TLE_CACHE_KEY = 'nst-iss-tle-v1';
const SNAPSHOT_KEY = 'nst-last-sky-check-v1';
const TLE_FRESH_MS = 2 * 3600e3;
const TLE_MAX_STALE_MS = 24 * 3600e3;
const { bestForecastPoint, illumination, weatherAt } = NightSkyCore;

let state = {
  loc: null,
  weather: null,
  iss: [],
  issStatus: 'loading',
  issTleSource: null,
  aurora: null,
  moon: null,
  isSnapshot: false,
};

const fmt = date => new Intl.DateTimeFormat('nl-NL', {
  hour: '2-digit',
  minute: '2-digit',
}).format(date);

const deg = radians => radians * 180 / Math.PI;

function direction(degrees) {
  const directions = ['N', 'NO', 'O', 'ZO', 'Z', 'ZW', 'W', 'NW'];
  return directions[Math.round(((degrees % 360) + 360) % 360 / 45) % 8];
}

async function json(url) {
  const response = await fetch(url, { cache: 'no-store' });
  if (!response.ok) throw new Error(`${response.status}`);
  return response.json();
}

function getLocation() {
  return new Promise(resolve => {
    if (!navigator.geolocation) return resolve(FALLBACK);
    navigator.geolocation.getCurrentPosition(
      position => resolve({
        lat: position.coords.latitude,
        lon: position.coords.longitude,
        name: 'Jouw locatie',
      }),
      () => resolve(FALLBACK),
      { enableHighAccuracy: true, timeout: 7000, maximumAge: 300000 }
    );
  });
}

async function loadWeather(location) {
  const variables = 'cloud_cover,precipitation_probability,visibility,temperature_2m,is_day';
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${location.lat}&longitude=${location.lon}&current=temperature_2m,is_day,cloud_cover&hourly=${variables}&forecast_days=2&timeformat=unixtime&timezone=GMT`;
  return json(url);
}

function sunAltitude(location, date) {
  const observer = new Astronomy.Observer(location.lat, location.lon, 0);
  const equatorial = Astronomy.Equator(Astronomy.Body.Sun, date, observer, true, true);
  return Astronomy.Horizon(date, observer, equatorial.ra, equatorial.dec, 'normal').altitude;
}

function loadMoon(location) {
  const now = new Date();
  const observer = new Astronomy.Observer(location.lat, location.lon, 0);
  const equatorial = Astronomy.Equator(Astronomy.Body.Moon, now, observer, true, true);
  const horizontal = Astronomy.Horizon(now, observer, equatorial.ra, equatorial.dec, 'normal');
  const phase = Astronomy.Illumination(Astronomy.Body.Moon, now);
  return {
    altitude: horizontal.altitude,
    azimuth: horizontal.azimuth,
    illuminatedPercent: phase.phase_fraction * 100,
  };
}

function asDate(astroTime) {
  if (!astroTime) return null;
  if (astroTime.date instanceof Date) return astroTime.date;
  return new Date(astroTime.date || astroTime);
}

function nextDarkWindow(location, weather, now = new Date()) {
  const observer = new Astronomy.Observer(location.lat, location.lon, 0);
  const currentAltitude = sunAltitude(location, now);
  const dusk = currentAltitude < -6
    ? now
    : asDate(Astronomy.SearchAltitude(Astronomy.Body.Sun, observer, -1, now, 2, -6));

  if (!dusk) return null;
  const dawnSearchStart = new Date(dusk.getTime() + 60000);
  const dawn = asDate(Astronomy.SearchAltitude(
    Astronomy.Body.Sun,
    observer,
    1,
    dawnSearchStart,
    2,
    -6
  ));
  if (!dawn || dawn <= dusk) return null;

  const best = bestForecastPoint(weather, dusk, dawn);
  return best ? { dusk, dawn, best } : null;
}

function readTLECache() {
  try {
    const cached = JSON.parse(localStorage.getItem(TLE_CACHE_KEY));
    if (cached && Array.isArray(cached.lines) && cached.lines.length === 2 && Number.isFinite(cached.savedAt)) {
      return cached;
    }
  } catch {}
  return null;
}

function saveTLECache(lines) {
  try {
    localStorage.setItem(TLE_CACHE_KEY, JSON.stringify({ lines, savedAt: Date.now() }));
  } catch {}
}

function saveSnapshot() {
  try {
    localStorage.setItem(SNAPSHOT_KEY, JSON.stringify({
      savedAt: Date.now(),
      state: { ...state, isSnapshot: false },
    }));
  } catch {}
}

function readSnapshot() {
  try {
    const snapshot = JSON.parse(localStorage.getItem(SNAPSHOT_KEY));
    if (!snapshot?.state?.loc || !snapshot.state.weather || !Number.isFinite(snapshot.savedAt)) return null;
    const cachedState = snapshot.state;
    cachedState.iss = (cachedState.iss || []).map(pass => ({
      ...pass,
      start: new Date(pass.start),
      end: pass.end ? new Date(pass.end) : undefined,
    }));
    cachedState.moon = cachedState.moon || null;
    cachedState.isSnapshot = true;
    return { savedAt: snapshot.savedAt, state: cachedState };
  } catch {
    return null;
  }
}

function renderConnectionStatus({ offline = !navigator.onLine, savedAt = null } = {}) {
  const element = $('connectionStatus');
  if (offline) {
    element.hidden = false;
    element.className = 'connection-status offline';
    element.textContent = savedAt
      ? `Offline · laatste controle ${fmt(new Date(savedAt))}. Dit is opgeslagen informatie, geen live advies.`
      : 'Offline · er is nog geen opgeslagen hemelcheck. Maak verbinding om gegevens te laden.';
    return;
  }
  if (savedAt) {
    element.hidden = false;
    element.className = 'connection-status';
    element.textContent = `Opgeslagen controle van ${fmt(new Date(savedAt))} · vernieuw voor actuele gegevens.`;
    return;
  }
  element.hidden = true;
}

async function loadTLE() {
  const cached = readTLECache();
  const age = cached ? Date.now() - cached.savedAt : Infinity;
  if (age < TLE_FRESH_MS) return { lines: cached.lines, source: 'cache' };

  try {
    const response = await fetch(
      'https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=TLE',
      { cache: 'no-store' }
    );
    if (!response.ok) throw new Error(`CelesTrak ${response.status}`);
    const rows = (await response.text()).trim().split(/\r?\n/);
    const lines = [rows[rows.length - 2], rows[rows.length - 1]];
    if (!lines[0]?.startsWith('1 ') || !lines[1]?.startsWith('2 ')) throw new Error('Ongeldige TLE');
    saveTLECache(lines);
    return { lines, source: 'live' };
  } catch (error) {
    if (cached && age < TLE_MAX_STALE_MS) return { lines: cached.lines, source: 'stale-cache' };
    throw error;
  }
}

function satelliteLook(satrec, location, date) {
  const positionVelocity = satellite.propagate(satrec, date);
  if (!positionVelocity.position) return null;

  const siderealTime = satellite.gstime(date);
  const observer = {
    longitude: location.lon * Math.PI / 180,
    latitude: location.lat * Math.PI / 180,
    height: 0,
  };
  const ecf = satellite.eciToEcf(positionVelocity.position, siderealTime);
  const look = satellite.ecfToLookAngles(observer, ecf);
  return {
    altitude: deg(look.elevation),
    azimuth: (deg(look.azimuth) + 360) % 360,
    ecf,
  };
}

async function loadISS(location) {
  const tle = await loadTLE();
  const satrec = satellite.twoline2satrec(...tle.lines);
  const start = Date.now();
  const end = start + 24 * 3600e3;
  const step = 20e3;
  const passes = [];
  let active = null;

  for (let time = start; time <= end; time += step) {
    const date = new Date(time);
    const look = satelliteLook(satrec, location, date);
    if (!look) continue;

    const aboveMinimum = look.altitude >= 10;
    if (aboveMinimum && !active) {
      active = {
        start: date,
        maxAltitude: look.altitude,
        maxAzimuth: look.azimuth,
        viewingCandidate: false,
      };
    }

    if (aboveMinimum && active) {
      if (look.altitude > active.maxAltitude) {
        active.maxAltitude = look.altitude;
        active.maxAzimuth = look.azimuth;
      }
      if (sunAltitude(location, date) < -6 && illumination(look.ecf, date) === 'sunlit') {
        active.viewingCandidate = true;
      }
    }

    if (!aboveMinimum && active) {
      active.end = date;
      if (active.viewingCandidate) passes.push(active);
      active = null;
    }
  }

  return { passes, tleSource: tle.source };
}

async function loadAurora(location) {
  try {
    const data = await json('https://services.swpc.noaa.gov/json/ovation_aurora_latest.json');
    const coordinates = data.coordinates || [];
    let best = 0;
    for (const point of coordinates) {
      const longitude = point[0] > 180 ? point[0] - 360 : point[0];
      const latitude = point[1];
      const value = point[2];
      const distance = Math.hypot(
        (latitude - location.lat) * 1.2,
        (longitude - location.lon) * Math.cos(location.lat * Math.PI / 180)
      );
      if (distance < 4 && value > best) best = value;
    }
    return { value: best, time: data['Forecast Time'] || data['Observation Time'] || null };
  } catch {
    return null;
  }
}

function setSourceState(id, label, status) {
  const element = $(id);
  element.textContent = `${label} ${status === 'ok' ? '✓' : '—'}`;
  element.className = `source ${status}`;
}

function renderNightWindow(location, weather, now) {
  const window = nextDarkWindow(location, weather, now);
  if (!window) {
    $('window').textContent = 'Nog niet berekend';
    $('windowSub').textContent = 'Er is geen passend donker venster binnen de actuele weersverwachting.';
    return;
  }

  const { dusk, dawn, best } = window;
  const forecast = best.forecast;
  const poor = forecast.cloud >= 85 || forecast.rain >= 70;
  $('window').textContent = poor ? `Minste bewolking rond ${fmt(best.date)}` : `Beste kans rond ${fmt(best.date)}`;
  $('window').className = poor ? '' : 'good';
  $('windowSub').textContent = `Donkere periode ${fmt(dusk)}–${fmt(dawn)} · ${Math.round(forecast.cloud)}% bewolking · ${Math.round(forecast.rain)}% regenkans.`;
}

function render() {
  const location = state.loc;
  const weather = state.weather;
  const now = new Date();
  const currentWeather = weatherAt(weather, now);
  if (!currentWeather) throw new Error('Actuele weersverwachting ontbreekt');

  const solarAltitude = sunAltitude(location, now);
  $('location').textContent = location.name;
  $('darkness').textContent = solarAltitude < -18
    ? 'Astronomisch donker'
    : solarAltitude < -6
      ? 'Schemering'
      : solarAltitude < 0
        ? 'Lichte schemering'
        : 'Daglicht';
  $('weather').textContent = `${Math.round(currentWeather.cloud)}% bewolking · ${Math.round(currentWeather.temperature)}°C`;

  const moon = state.moon;
  $('moon').textContent = `${Math.round(moon.illuminatedPercent)}% verlicht`;
  $('moonSub').textContent = moon.altitude > 0
    ? `${Math.round(moon.altitude)}° hoog richting ${direction(moon.azimuth)}`
    : 'Onder de horizon';

  if (state.isSnapshot) {
    $('iss').textContent = state.iss.length ? 'Opgeslagen ISS-kandidaat' : 'Geen opgeslagen ISS-kandidaat';
    $('issSub').textContent = state.iss.length
      ? `Laatste controle bevatte een kandidaat rond ${fmt(state.iss[0].start)}. Dit is opgeslagen informatie en geen actueel passageadvies.`
      : 'Dit is een opgeslagen controle en geen actuele ISS-voorspelling.';
    $('iss').className = '';
  } else if (state.issStatus === 'error') {
    $('iss').textContent = 'ISS-bron niet beschikbaar';
    $('issSub').textContent = 'CelesTrak-data kon niet betrouwbaar worden geladen. Er wordt daarom geen passageadvies gegeven.';
    $('iss').className = '';
  } else if (state.iss.length) {
    const pass = state.iss[0];
    const passWeather = weatherAt(weather, pass.start);
    const sourceNote = state.issTleSource === 'stale-cache' ? ' · oudere cachedata' : '';
    $('iss').textContent = `${fmt(pass.start)} · max ${Math.round(pass.maxAltitude)}°`;
    $('issSub').textContent = passWeather
      ? `Kijkkandidaat richting ${direction(pass.maxAzimuth)} · zonverlicht volgens schaduwmodel · ${Math.round(passWeather.cloud)}% bewolking verwacht${sourceNote}. Helderheid is niet berekend.`
      : `Kijkkandidaat richting ${direction(pass.maxAzimuth)} · zonverlicht volgens schaduwmodel${sourceNote}. Geen passend weermoment beschikbaar; helderheid is niet berekend.`;
    $('iss').className = 'good';
  } else {
    $('iss').textContent = 'Geen ISS-kijkkandidaat';
    $('issSub').textContent = 'Geen passage ≥10° gevonden die tegelijk zonverlicht is bij voldoende donkere hemel.';
    $('iss').className = '';
  }

  if (state.isSnapshot) {
    $('aurora').textContent = 'Opgeslagen auroracontext';
    $('auroraSub').textContent = 'Offline/opgeslagen NOAA-informatie wordt niet gebruikt voor een actueel aurora-advies.';
  } else if (state.aurora) {
    const value = state.aurora.value;
    $('aurora').textContent = value >= 20 ? 'Verhoogd signaal' : value >= 8 ? 'Zwak signaal' : 'Geen lokaal signaal';
    $('auroraSub').textContent = `OVATION nabij jouw locatie: ${Math.round(value)}%. Indicatief, geen zichtbaarheidsgarantie.`;
  } else {
    $('aurora').textContent = 'Auroradata niet beschikbaar';
    $('auroraSub').textContent = 'Zonder actuele NOAA-data wordt geen aurora-advies gegeven.';
  }

  renderNightWindow(location, weather, now);

  const firstPass = state.iss[0];
  let verdict = state.isSnapshot ? 'Opgeslagen hemelcheck — geen live advies' : 'Geen sterke reden om nu naar buiten te gaan';
  let reason = state.isSnapshot
    ? 'De getoonde gegevens zijn eerder opgeslagen. Maak verbinding en vernieuw voordat je een kijkbeslissing neemt.'
    : 'Ik zie nu geen combinatie van een bijzonder event en goede omstandigheden.';
  let verdictClass = '';

  if (!state.isSnapshot && firstPass && firstPass.start - now < 45 * 60000) {
    const passWeather = weatherAt(weather, firstPass.start);
    if (passWeather && passWeather.cloud < 55 && passWeather.rain < 35 && state.issTleSource !== 'stale-cache') {
      verdict = 'ISS-kans binnenkort';
      reason = `Rond ${fmt(firstPass.start)} is er een ISS-kijkkandidaat. Verwacht: ${Math.round(passWeather.cloud)}% bewolking en ${Math.round(passWeather.rain)}% regenkans. Helderheid is niet berekend, dus dit is geen zichtbaarheidsgarantie.`;
      verdictClass = 'good';
    }
  } else if (!state.isSnapshot && state.aurora && state.aurora.value >= 20 && solarAltitude < -6 && currentWeather.cloud < 45) {
    verdict = 'Aurorasignaal — kijkcondities controleren';
    reason = 'NOAA toont een verhoogd lokaal OVATION-signaal en de hemel is voldoende donker. Dit blijft probabilistisch.';
    verdictClass = 'warn';
  }

  $('verdict').textContent = verdict;
  $('verdict').className = verdictClass;
  $('reason').textContent = reason;
  $('updated').textContent = state.isSnapshot
    ? 'Opgeslagen gegevens · positieve live adviezen zijn uitgeschakeld.'
    : `Bijgewerkt ${fmt(now)} · bronfouten worden nooit als positief advies geïnterpreteerd.`;

  const rows = [];
  for (let hour = 0; hour < 6; hour += 1) {
    const date = new Date(now.getTime() + hour * 3600e3);
    const forecast = weatherAt(weather, date);
    if (!forecast) continue;
    rows.push(`<div class="timeline-row"><span>${fmt(date)}</span><span>${Math.round(forecast.cloud)}% ☁︎ · ${Math.round(forecast.rain)}% regen</span></div>`);
  }
  $('timeline').innerHTML = rows.length ? rows.join('') : '<p>Geen passende uurverwachting beschikbaar.</p>';

  setSourceState('sourceWeather', 'OPEN-METEO', state.isSnapshot ? 'error' : 'ok');
  setSourceState('sourceISS', 'CELESTRAK', !state.isSnapshot && state.issStatus === 'ok' ? 'ok' : 'error');
  setSourceState('sourceAurora', 'NOAA', !state.isSnapshot && state.aurora ? 'ok' : 'error');
}

function setLoading(isLoading) {
  $('locate').disabled = isLoading;
  $('locate').setAttribute('aria-busy', String(isLoading));
  $('locate').classList.toggle('loading', isLoading);
  if (isLoading) {
    $('verdict').textContent = 'Hemel wordt gecontroleerd';
    $('reason').textContent = 'Live bronnen en het eerstvolgende donkere kijkvenster worden bijgewerkt.';
  }
}

async function refresh() {
  setLoading(true);
  renderConnectionStatus();
  try {
    state.loc = await getLocation();
    const [weather, issResult, aurora] = await Promise.all([
      loadWeather(state.loc),
      loadISS(state.loc)
        .then(result => ({ ok: true, ...result }))
        .catch(error => ({ ok: false, error })),
      loadAurora(state.loc),
    ]);

    state.weather = weather;
    state.isSnapshot = false;
    if (issResult.ok) {
      state.iss = issResult.passes;
      state.issStatus = 'ok';
      state.issTleSource = issResult.tleSource;
    } else {
      state.iss = [];
      state.issStatus = 'error';
      state.issTleSource = null;
      console.error(issResult.error);
    }
    state.aurora = aurora;
    state.moon = loadMoon(state.loc);
    saveSnapshot();
    render();
  } catch (error) {
    const snapshot = readSnapshot();
    if (snapshot) {
      state = snapshot.state;
      renderConnectionStatus({ offline: !navigator.onLine, savedAt: snapshot.savedAt });
      try {
        render();
        $('updated').textContent = `Opgeslagen controle ${fmt(new Date(snapshot.savedAt))} · live vernieuwing mislukt; geen live advies.`;
      } catch {
        $('verdict').textContent = 'Opgeslagen controle is te oud voor actuele weergave';
        $('reason').textContent = 'Maak verbinding en vernieuw. Oude forecastdata wordt niet als actuele hemelcheck getoond.';
      }
    } else {
      $('verdict').textContent = 'Live controle niet gelukt';
      $('reason').textContent = 'Maak verbinding en vernieuw. Zonder actuele brondata geeft Night Sky Thomas geen positief kijkadvies.';
      renderConnectionStatus();
      setSourceState('sourceWeather', 'OPEN-METEO', 'error');
      setSourceState('sourceISS', 'CELESTRAK', 'error');
      setSourceState('sourceAurora', 'NOAA', 'error');
    }
    console.error(error);
  } finally {
    setLoading(false);
  }
}

$('locate').addEventListener('click', refresh);
window.addEventListener('online', refresh);
window.addEventListener('offline', () => {
  const snapshot = readSnapshot();
  renderConnectionStatus({ offline: true, savedAt: snapshot?.savedAt });
});
if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
if (!navigator.onLine) {
  const snapshot = readSnapshot();
  if (snapshot) {
    state = snapshot.state;
    renderConnectionStatus({ offline: true, savedAt: snapshot.savedAt });
    try {
      render();
    } catch {
      $('verdict').textContent = 'Opgeslagen controle is te oud voor actuele weergave';
      $('reason').textContent = 'Maak verbinding en vernieuw. Oude forecastdata wordt niet als actuele hemelcheck getoond.';
    }
  }
}
refresh();
