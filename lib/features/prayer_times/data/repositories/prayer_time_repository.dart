// lib/features/prayer_times/data/repositories/prayer_time_repository.dart
import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/prayer_schedule.dart';
import '../../../../core/constants/app_constants.dart';

class PrayerTimeRepository {
  final SharedPreferences _prefs;

  PrayerTimeRepository(this._prefs);

  // ──────────────────────────────────────────
  // GPS & Lokasi
  // ──────────────────────────────────────────

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<String> getCityName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return p.subAdministrativeArea ??
               p.administrativeArea ??
               p.locality ??
               'Lokasi Tidak Diketahui';
      }
    } catch (_) {}
    return 'Lokasi Tidak Diketahui';
  }

  // ──────────────────────────────────────────
  // Cache Koordinat
  // ──────────────────────────────────────────

  void saveCoordinates(double lat, double lon, String city) {
    _prefs.setDouble(AppConstants.keyLatitude, lat);
    _prefs.setDouble(AppConstants.keyLongitude, lon);
    _prefs.setString(AppConstants.keyCityName, city);
  }

  ({double? lat, double? lon, String? city}) getCachedCoordinates() {
    return (
      lat: _prefs.getDouble(AppConstants.keyLatitude),
      lon: _prefs.getDouble(AppConstants.keyLongitude),
      city: _prefs.getString(AppConstants.keyCityName),
    );
  }

  bool get hasCachedCoordinates {
    final cached = getCachedCoordinates();
    return cached.lat != null && cached.lon != null;
  }

  static const double defaultLat = -6.2088;
  static const double defaultLon = 106.8456;
  static const String defaultCity = 'DKI Jakarta';

  ({double lat, double lon, String city}) getBestAvailableCoordinates() {
    final cached = getCachedCoordinates();
    if (cached.lat != null && cached.lon != null) {
      return (
        lat: cached.lat!,
        lon: cached.lon!,
        city: cached.city ?? 'Lokasi Terakhir',
      );
    }
    return (
      lat: defaultLat,
      lon: defaultLon,
      city: defaultCity,
    );
  }

  // ──────────────────────────────────────────
  // Kalkulasi Jadwal Sholat (Offline)
  // ──────────────────────────────────────────

  PrayerSchedule calculateTodaySchedule({
    required double lat,
    required double lon,
    required String cityName,
  }) {
    final coordinates = Coordinates(lat, lon);

    // Menggunakan metode Kemenag RI
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi;
    params.fajrAngle = 20;
    params.ishaAngle = 18;

    final components = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(coordinates, components, params);
    final sunnahTimes = SunnahTimes(prayerTimes);

    // Hitung Subuh besok untuk antisipasi waktu malam hari setelah Isya
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowComponents = DateComponents.from(tomorrow);
    final tomorrowPrayerTimes = PrayerTimes(coordinates, tomorrowComponents, params);

    return PrayerSchedule.fromPrayerTimes(
      prayerTimes: prayerTimes,
      sunnahTimes: sunnahTimes,
      cityName: cityName,
      nextDayFajr: tomorrowPrayerTimes.fajr,
    );
  }

  /// Hitung jadwal untuk 7 hari ke depan (untuk penjadwalan notifikasi)
  List<PrayerSchedule> calculateWeekSchedule({
    required double lat,
    required double lon,
    required String cityName,
  }) {
    final coordinates = Coordinates(lat, lon);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.shafi;
    params.fajrAngle = 20;
    params.ishaAngle = 18;

    final schedules = <PrayerSchedule>[];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final components = DateComponents.from(date);
      final prayerTimes = PrayerTimes(coordinates, components, params);
      final sunnahTimes = SunnahTimes(prayerTimes);
      schedules.add(PrayerSchedule.fromPrayerTimes(
        prayerTimes: prayerTimes,
        sunnahTimes: sunnahTimes,
        cityName: cityName,
      ));
    }

    return schedules;
  }
}
