import 'dart:math';

/// Magnetic declination from the World Magnetic Model 2025 (WMM2025).
///
/// Phone compasses report MAGNETIC north (Android always; the rotation
/// sensor on iOS too), while the qibla bearing is from TRUE north — the
/// difference is the declination of the place: ~2° in Addis Ababa, ~3° in
/// Makkah, ~5° in Cairo, 10–20° in parts of the Americas and Europe's north.
/// true heading = magnetic heading + declination (east positive).
///
/// Coefficients: NOAA NCEI / BGS, WMM2025 (valid 2025.0–2030.0), US
/// government work — public domain. Taken verbatim from `WMM_2025.COF`.
/// Algorithm: the WMM2025 technical report (spherical-harmonic expansion to
/// degree 12, WGS-84 geodetic → geocentric, secular variation per year).
/// Checked against the reference implementation in
/// `test/magnetic_declination_test.dart`.
abstract final class MagneticDeclination {
  static const _epoch = 2025.0;

  /// n, m, g, h, ġ, ḣ (nT, nT/yr).
  static const _cof = <List<num>>[
    [1, 0, -29351.8, 0.0, 12.0, 0.0],
    [1, 1, -1410.8, 4545.4, 9.7, -21.5],
    [2, 0, -2556.6, 0.0, -11.6, 0.0],
    [2, 1, 2951.1, -3133.6, -5.2, -27.7],
    [2, 2, 1649.3, -815.1, -8.0, -12.1],
    [3, 0, 1361.0, 0.0, -1.3, 0.0],
    [3, 1, -2404.1, -56.6, -4.2, 4.0],
    [3, 2, 1243.8, 237.5, 0.4, -0.3],
    [3, 3, 453.6, -549.5, -15.6, -4.1],
    [4, 0, 895.0, 0.0, -1.6, 0.0],
    [4, 1, 799.5, 278.6, -2.4, -1.1],
    [4, 2, 55.7, -133.9, -6.0, 4.1],
    [4, 3, -281.1, 212.0, 5.6, 1.6],
    [4, 4, 12.1, -375.6, -7.0, -4.4],
    [5, 0, -233.2, 0.0, 0.6, 0.0],
    [5, 1, 368.9, 45.4, 1.4, -0.5],
    [5, 2, 187.2, 220.2, 0.0, 2.2],
    [5, 3, -138.7, -122.9, 0.6, 0.4],
    [5, 4, -142.0, 43.0, 2.2, 1.7],
    [5, 5, 20.9, 106.1, 0.9, 1.9],
    [6, 0, 64.4, 0.0, -0.2, 0.0],
    [6, 1, 63.8, -18.4, -0.4, 0.3],
    [6, 2, 76.9, 16.8, 0.9, -1.6],
    [6, 3, -115.7, 48.8, 1.2, -0.4],
    [6, 4, -40.9, -59.8, -0.9, 0.9],
    [6, 5, 14.9, 10.9, 0.3, 0.7],
    [6, 6, -60.7, 72.7, 0.9, 0.9],
    [7, 0, 79.5, 0.0, -0.0, 0.0],
    [7, 1, -77.0, -48.9, -0.1, 0.6],
    [7, 2, -8.8, -14.4, -0.1, 0.5],
    [7, 3, 59.3, -1.0, 0.5, -0.8],
    [7, 4, 15.8, 23.4, -0.1, 0.0],
    [7, 5, 2.5, -7.4, -0.8, -1.0],
    [7, 6, -11.1, -25.1, -0.8, 0.6],
    [7, 7, 14.2, -2.3, 0.8, -0.2],
    [8, 0, 23.2, 0.0, -0.1, 0.0],
    [8, 1, 10.8, 7.1, 0.2, -0.2],
    [8, 2, -17.5, -12.6, 0.0, 0.5],
    [8, 3, 2.0, 11.4, 0.5, -0.4],
    [8, 4, -21.7, -9.7, -0.1, 0.4],
    [8, 5, 16.9, 12.7, 0.3, -0.5],
    [8, 6, 15.0, 0.7, 0.2, -0.6],
    [8, 7, -16.8, -5.2, -0.0, 0.3],
    [8, 8, 0.9, 3.9, 0.2, 0.2],
    [9, 0, 4.6, 0.0, -0.0, 0.0],
    [9, 1, 7.8, -24.8, -0.1, -0.3],
    [9, 2, 3.0, 12.2, 0.1, 0.3],
    [9, 3, -0.2, 8.3, 0.3, -0.3],
    [9, 4, -2.5, -3.3, -0.3, 0.3],
    [9, 5, -13.1, -5.2, 0.0, 0.2],
    [9, 6, 2.4, 7.2, 0.3, -0.1],
    [9, 7, 8.6, -0.6, -0.1, -0.2],
    [9, 8, -8.7, 0.8, 0.1, 0.4],
    [9, 9, -12.9, 10.0, -0.1, 0.1],
    [10, 0, -1.3, 0.0, 0.1, 0.0],
    [10, 1, -6.4, 3.3, 0.0, 0.0],
    [10, 2, 0.2, 0.0, 0.1, -0.0],
    [10, 3, 2.0, 2.4, 0.1, -0.2],
    [10, 4, -1.0, 5.3, -0.0, 0.1],
    [10, 5, -0.6, -9.1, -0.3, -0.1],
    [10, 6, -0.9, 0.4, 0.0, 0.1],
    [10, 7, 1.5, -4.2, -0.1, 0.0],
    [10, 8, 0.9, -3.8, -0.1, -0.1],
    [10, 9, -2.7, 0.9, -0.0, 0.2],
    [10, 10, -3.9, -9.1, -0.0, -0.0],
    [11, 0, 2.9, 0.0, 0.0, 0.0],
    [11, 1, -1.5, 0.0, -0.0, -0.0],
    [11, 2, -2.5, 2.9, 0.0, 0.1],
    [11, 3, 2.4, -0.6, 0.0, -0.0],
    [11, 4, -0.6, 0.2, 0.0, 0.1],
    [11, 5, -0.1, 0.5, -0.1, -0.0],
    [11, 6, -0.6, -0.3, 0.0, -0.0],
    [11, 7, -0.1, -1.2, -0.0, 0.1],
    [11, 8, 1.1, -1.7, -0.1, -0.0],
    [11, 9, -1.0, -2.9, -0.1, 0.0],
    [11, 10, -0.2, -1.8, -0.1, 0.0],
    [11, 11, 2.6, -2.3, -0.1, 0.0],
    [12, 0, -2.0, 0.0, 0.0, 0.0],
    [12, 1, -0.2, -1.3, 0.0, -0.0],
    [12, 2, 0.3, 0.7, -0.0, 0.0],
    [12, 3, 1.2, 1.0, -0.0, -0.1],
    [12, 4, -1.3, -1.4, -0.0, 0.1],
    [12, 5, 0.6, -0.0, -0.0, -0.0],
    [12, 6, 0.6, 0.6, 0.1, -0.0],
    [12, 7, 0.5, -0.1, -0.0, -0.0],
    [12, 8, -0.1, 0.8, 0.0, 0.0],
    [12, 9, -0.4, 0.1, 0.0, -0.0],
    [12, 10, -0.2, -1.0, -0.1, -0.0],
    [12, 11, -1.3, 0.1, -0.0, 0.0],
    [12, 12, -0.7, 0.2, -0.1, -0.1],
  ];

  /// Declination in degrees (east positive) at [latitude]/[longitude]
  /// (degrees, WGS-84), sea level, at [when] (defaults to now).
  static double degrees(double latitude, double longitude, {DateTime? when}) {
    final t = when ?? DateTime.now();
    final year =
        t.year +
        (t.difference(DateTime(t.year)).inHours / 24) /
            (DateTime(t.year + 1).difference(DateTime(t.year)).inDays);
    final dt = year - _epoch;

    const a = 6371.2; // geomagnetic reference radius, km
    const wgsA = 6378.137;
    const f = 1 / 298.257223563;
    const e2 = f * (2 - f);
    final phi = latitude * pi / 180;
    final lam = longitude * pi / 180;
    final rc = wgsA / sqrt(1 - e2 * sin(phi) * sin(phi));
    final p = rc * cos(phi);
    final z = rc * (1 - e2) * sin(phi);
    final r = sqrt(p * p + z * z);
    final phiC = asin(z / r); // geocentric latitude

    const nMax = 12;
    final cosT = sin(phiC); // colatitude θ: cos θ = sin φ'
    final sinT = cos(phiC);
    final pnm = List.generate(nMax + 1, (_) => List.filled(nMax + 1, 0.0));
    final dp = List.generate(nMax + 1, (_) => List.filled(nMax + 1, 0.0));
    pnm[0][0] = 1;
    for (var n = 1; n <= nMax; n++) {
      for (var m = 0; m <= n; m++) {
        if (n == m) {
          final k = n == 1 ? 1.0 : sqrt((2 * n - 1) / (2 * n));
          pnm[n][n] = k * sinT * pnm[n - 1][n - 1];
          dp[n][n] = k * (cosT * pnm[n - 1][n - 1] + sinT * dp[n - 1][n - 1]);
        } else {
          final k1 = (2 * n - 1).toDouble();
          final k2 = n >= 2
              ? sqrt(((n - 1) * (n - 1) - m * m).toDouble())
              : 0.0;
          final k3 = sqrt((n * n - m * m).toDouble());
          final p2 = n >= 2 ? pnm[n - 2][m] : 0.0;
          final d2 = n >= 2 ? dp[n - 2][m] : 0.0;
          pnm[n][m] = (k1 * cosT * pnm[n - 1][m] - k2 * p2) / k3;
          dp[n][m] =
              (k1 * (cosT * dp[n - 1][m] - sinT * pnm[n - 1][m]) - k2 * d2) /
              k3;
        }
      }
    }

    var x = 0.0, y = 0.0, zz = 0.0;
    for (final c in _cof) {
      final n = c[0].toInt(), m = c[1].toInt();
      final g = c[2] + dt * c[4];
      final h = c[3] + dt * c[5];
      final ar = pow(a / r, n + 2).toDouble();
      final cm = cos(m * lam), sm = sin(m * lam);
      x += ar * (g * cm + h * sm) * dp[n][m];
      if (sinT.abs() > 1e-10) {
        y += ar * m * (g * sm - h * cm) * pnm[n][m] / sinT;
      }
      zz -= ar * (n + 1) * (g * cm + h * sm) * pnm[n][m];
    }
    // Geocentric → geodetic components (Z is not needed for D).
    final psi = phiC - phi;
    final xg = x * cos(psi) - zz * sin(psi);
    return atan2(y, xg) * 180 / pi;
  }
}
