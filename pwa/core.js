(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.NightSkyCore = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const EARTH_RADIUS_KM = 6378.137;
  const SUN_RADIUS_KM = 695700;
  const AU_KM = 149597870.7;

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function weatherAt(weather, date, maxDistanceMs = 90 * 60 * 1000) {
    if (!weather?.hourly?.time?.length) return null;

    const timestamp = date.getTime();
    let bestIndex = -1;
    let bestDistance = Infinity;

    weather.hourly.time.forEach((value, index) => {
      const distance = Math.abs(value * 1000 - timestamp);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    });

    if (bestIndex < 0 || bestDistance > maxDistanceMs) return null;

    return {
      cloud: weather.hourly.cloud_cover[bestIndex],
      rain: weather.hourly.precipitation_probability[bestIndex],
      visibility: weather.hourly.visibility[bestIndex],
      temperature: weather.hourly.temperature_2m[bestIndex],
      isDay: weather.hourly.is_day[bestIndex],
      forecastTime: new Date(weather.hourly.time[bestIndex] * 1000),
    };
  }

  function solarPositionEcf(date) {
    const year = date.getUTCFullYear();
    const yearStart = Date.UTC(year, 0, 0);
    const dayOfYear = (date.getTime() - yearStart) / 86400000;
    const utcHours = date.getUTCHours() + date.getUTCMinutes() / 60 + date.getUTCSeconds() / 3600;
    const daysInYear = ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0) ? 366 : 365;
    const gamma = 2 * Math.PI / daysInYear * (dayOfYear - 1 + (utcHours - 12) / 24);
    const equationOfTime = 229.18 * (
      0.000075 +
      0.001868 * Math.cos(gamma) -
      0.032077 * Math.sin(gamma) -
      0.014615 * Math.cos(2 * gamma) -
      0.040849 * Math.sin(2 * gamma)
    );
    const declination =
      0.006918 -
      0.399912 * Math.cos(gamma) +
      0.070257 * Math.sin(gamma) -
      0.006758 * Math.cos(2 * gamma) +
      0.000907 * Math.sin(2 * gamma) -
      0.002697 * Math.cos(3 * gamma) +
      0.00148 * Math.sin(3 * gamma);
    const greenwichHourAngle = (utcHours * 60 + equationOfTime) / 4 - 180;
    const subsolarLongitude = -greenwichHourAngle * Math.PI / 180;
    const equatorialDistance = AU_KM * Math.cos(declination);

    return {
      x: equatorialDistance * Math.cos(subsolarLongitude),
      y: equatorialDistance * Math.sin(subsolarLongitude),
      z: AU_KM * Math.sin(declination),
    };
  }

  function illuminationFromVectors(satelliteEcf, sunEcf) {
    const toEarth = { x: -satelliteEcf.x, y: -satelliteEcf.y, z: -satelliteEcf.z };
    const toSun = {
      x: sunEcf.x - satelliteEcf.x,
      y: sunEcf.y - satelliteEcf.y,
      z: sunEcf.z - satelliteEcf.z,
    };
    const length = vector => Math.hypot(vector.x, vector.y, vector.z);
    const earthDistance = length(toEarth);
    const sunDistance = length(toSun);

    if (earthDistance <= EARTH_RADIUS_KM || sunDistance <= SUN_RADIUS_KM) return 'unknown';

    const earthRadius = Math.asin(clamp(EARTH_RADIUS_KM / earthDistance, -1, 1));
    const sunRadius = Math.asin(clamp(SUN_RADIUS_KM / sunDistance, -1, 1));
    const separation = Math.acos(clamp(
      (toEarth.x * toSun.x + toEarth.y * toSun.y + toEarth.z * toSun.z) /
      (earthDistance * sunDistance),
      -1,
      1
    ));

    if (earthRadius > sunRadius && separation < earthRadius - sunRadius) return 'umbra';
    if (separation < earthRadius + sunRadius) return 'penumbra';
    return 'sunlit';
  }

  function illumination(satelliteEcf, date) {
    return illuminationFromVectors(satelliteEcf, solarPositionEcf(date));
  }

  function bestForecastPoint(weather, start, end, stepMs = 30 * 60 * 1000) {
    if (!(start instanceof Date) || !(end instanceof Date) || end <= start) return null;

    let best = null;
    for (let time = start.getTime(); time <= end.getTime(); time += stepMs) {
      const forecast = weatherAt(weather, new Date(time));
      if (!forecast) continue;
      const score = clamp(forecast.cloud, 0, 100) * 0.75 + clamp(forecast.rain, 0, 100) * 0.25;
      if (!best || score < best.score) best = { date: forecast.forecastTime, forecast, score };
    }
    return best;
  }

  return {
    AU_KM,
    bestForecastPoint,
    illumination,
    illuminationFromVectors,
    solarPositionEcf,
    weatherAt,
  };
});
