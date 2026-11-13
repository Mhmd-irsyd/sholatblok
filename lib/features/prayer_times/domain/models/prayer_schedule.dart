// lib/features/prayer_times/domain/models/prayer_schedule.dart
import 'package:adhan/adhan.dart';

/// Model untuk satu set jadwal sholat harian
class PrayerSchedule {
  final DateTime date;
  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;
  final DateTime? nextDayFajr;
  final String cityName;

  const PrayerSchedule({
    required this.date,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
    this.nextDayFajr,
    required this.cityName,
  });

  factory PrayerSchedule.fromPrayerTimes({
    required PrayerTimes prayerTimes,
    required SunnahTimes sunnahTimes,
    required String cityName,
    DateTime? nextDayFajr,
  }) {
    final dc = prayerTimes.dateComponents;
    return PrayerSchedule(
      date: DateTime(dc.year, dc.month, dc.day),
      fajr: prayerTimes.fajr.toLocal(),
      sunrise: prayerTimes.sunrise.toLocal(),
      dhuhr: prayerTimes.dhuhr.toLocal(),
      asr: prayerTimes.asr.toLocal(),
      maghrib: prayerTimes.maghrib.toLocal(),
      isha: prayerTimes.isha.toLocal(),
      nextDayFajr: nextDayFajr?.toLocal(),
      cityName: cityName,
    );
  }

  /// Daftar waktu sholat yang disortir
  List<MapEntry<String, DateTime?>> get prayerList => [
    MapEntry('fajr', fajr),
    MapEntry('sunrise', sunrise),
    MapEntry('dhuhr', dhuhr),
    MapEntry('asr', asr),
    MapEntry('maghrib', maghrib),
    MapEntry('isha', isha),
  ];

  /// Waktu sholat berikutnya dari waktu saat ini.
  /// Jika seluruh sholat hari ini sudah lewat (misal malam hari setelah Isya),
  /// otomatis menunjuk ke waktu Subuh besok hari!
  MapEntry<String, DateTime?>? get nextPrayer {
    final now = DateTime.now();
    for (final entry in prayerList) {
      if (entry.value != null && entry.value!.isAfter(now)) {
        return entry;
      }
    }
    // Jika semua sholat hari ini sudah lewat, sholat berikutnya adalah Subuh besok
    if (nextDayFajr != null) {
      return MapEntry('fajr', nextDayFajr);
    } else if (fajr != null) {
      return MapEntry('fajr', fajr!.add(const Duration(days: 1)));
    }
    return null;
  }

  bool get isNextPrayerTomorrow {
    final next = nextPrayer;
    if (next == null || next.value == null) return false;
    final now = DateTime.now();
    return next.value!.day != now.day;
  }
}
