const test = require('node:test');
const assert = require('node:assert/strict');
const {
  AU_KM,
  bestForecastPoint,
  illuminationFromVectors,
  solarPositionEcf,
  weatherAt,
} = require('../core.js');

function forecast(hours) {
  return {
    hourly: {
      time: hours.map(item => item.time.getTime() / 1000),
      cloud_cover: hours.map(item => item.cloud),
      precipitation_probability: hours.map(item => item.rain),
      visibility: hours.map(item => item.visibility ?? 10000),
      temperature_2m: hours.map(item => item.temperature ?? 10),
      is_day: hours.map(item => item.isDay ?? 0),
    },
  };
}

test('weatherAt selects the nearest forecast hour', () => {
  const base = new Date('2026-09-17T18:00:00Z');
  const weather = forecast([
    { time: base, cloud: 80, rain: 20 },
    { time: new Date(base.getTime() + 3600000), cloud: 25, rain: 5 },
  ]);

  const result = weatherAt(weather, new Date(base.getTime() + 50 * 60000));
  assert.equal(result.cloud, 25);
  assert.equal(result.rain, 5);
});

test('weatherAt refuses forecasts outside the available time window', () => {
  const weather = forecast([{ time: new Date('2026-09-17T18:00:00Z'), cloud: 20, rain: 0 }]);
  assert.equal(weatherAt(weather, new Date('2026-09-18T02:00:00Z')), null);
});

test('bestForecastPoint prefers the clearest dry slot', () => {
  const start = new Date('2026-09-17T20:00:00Z');
  const weather = forecast([
    { time: start, cloud: 70, rain: 10 },
    { time: new Date(start.getTime() + 3600000), cloud: 15, rain: 5 },
    { time: new Date(start.getTime() + 7200000), cloud: 40, rain: 0 },
  ]);

  const result = bestForecastPoint(weather, start, new Date(start.getTime() + 7200000), 3600000);
  assert.equal(result.date.toISOString(), '2026-09-17T21:00:00.000Z');
});

test('solar ECF vector stays at approximately one astronomical unit', () => {
  const sun = solarPositionEcf(new Date('2026-03-20T12:00:00Z'));
  const distance = Math.hypot(sun.x, sun.y, sun.z);
  assert.ok(Math.abs(distance - AU_KM) < 0.001);
});

test('shadow geometry distinguishes umbra and sunlight', () => {
  const sun = { x: AU_KM, y: 0, z: 0 };
  assert.equal(illuminationFromVectors({ x: -7000, y: 0, z: 0 }, sun), 'umbra');
  assert.equal(illuminationFromVectors({ x: 7000, y: 0, z: 0 }, sun), 'sunlit');
  assert.equal(illuminationFromVectors({ x: 1000, y: 0, z: 0 }, sun), 'unknown');
});
