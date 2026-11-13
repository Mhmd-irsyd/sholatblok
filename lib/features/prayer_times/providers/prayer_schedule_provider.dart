// lib/features/prayer_times/providers/prayer_schedule_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alarm/services/notification_service.dart';
import '../data/repositories/prayer_time_repository.dart';
import '../domain/models/prayer_schedule.dart';

// ──────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final prayerTimeRepositoryProvider = FutureProvider<PrayerTimeRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PrayerTimeRepository(prefs);
});

/// Menyimpan status apakah GPS saat ini mati atau tidak dapat dijangkau
final isGpsDisabledProvider = StateProvider<bool>((ref) => false);

// ──────────────────────────────────────────
// State Notifier untuk Jadwal Sholat
// ──────────────────────────────────────────

class PrayerScheduleNotifier extends AsyncNotifier<PrayerSchedule?> {
  @override
  Future<PrayerSchedule?> build() async {
    return await _loadSchedule();
  }

  Future<PrayerSchedule?> _loadSchedule() async {
    final repo = await ref.read(prayerTimeRepositoryProvider.future);

    // 1. Coba dari cache dulu agar tampil instan
    if (repo.hasCachedCoordinates) {
      final cached = repo.getCachedCoordinates();
      final schedule = repo.calculateTodaySchedule(
        lat: cached.lat!,
        lon: cached.lon!,
        cityName: cached.city ?? 'Lokasi Terakhir',
      );
      NotificationService().updateOngoingPrayerNotification(schedule);
      NotificationService().scheduleApproachingPrayerReminders(schedule);
      NotificationService().scheduleExactAdhanAlarms(schedule);

      // Coba perbarui GPS di background secara halus
      Future.microtask(() => refreshFromGps(silent: true));
      return schedule;
    }

    // 2. Jika belum ada cache sama sekali, coba ambil GPS
    return await refreshFromGps(silent: false);
  }

  Future<PrayerSchedule?> refreshFromGps({bool silent = false}) async {
    if (!silent) {
      state = const AsyncLoading();
    }
    final repo = await ref.read(prayerTimeRepositoryProvider.future);

    try {
      final position = await repo.getCurrentPosition();
      final city = await repo.getCityName(
        position.latitude,
        position.longitude,
      );

      repo.saveCoordinates(position.latitude, position.longitude, city);
      ref.read(isGpsDisabledProvider.notifier).state = false;

      final schedule = repo.calculateTodaySchedule(
        lat: position.latitude,
        lon: position.longitude,
        cityName: city,
      );

      NotificationService().updateOngoingPrayerNotification(schedule);
      NotificationService().scheduleApproachingPrayerReminders(schedule);
      NotificationService().scheduleExactAdhanAlarms(schedule);

      state = AsyncData(schedule);
      return schedule;
    } catch (e) {
      debugPrint('[PrayerScheduleNotifier] GPS tidak aktif atau gagal: $e. Menggunakan lokasi tersimpan sebelumnya.');
      ref.read(isGpsDisabledProvider.notifier).state = true;

      // Ambil lokasi terbaik yang tersedia (cache sebelumnya, atau default Jakarta)
      final best = repo.getBestAvailableCoordinates();
      final schedule = repo.calculateTodaySchedule(
        lat: best.lat,
        lon: best.lon,
        cityName: best.city,
      );

      NotificationService().updateOngoingPrayerNotification(schedule);
      NotificationService().scheduleApproachingPrayerReminders(schedule);
      NotificationService().scheduleExactAdhanAlarms(schedule);

      state = AsyncData(schedule);
      return schedule;
    }
  }
}

final prayerScheduleProvider =
    AsyncNotifierProvider<PrayerScheduleNotifier, PrayerSchedule?>(
  PrayerScheduleNotifier.new,
);

// ──────────────────────────────────────────
// Countdown Provider (update tiap detik)
// ──────────────────────────────────────────

final countdownProvider = StreamProvider<Duration>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return const Duration(seconds: 1); // ticker
  });
});
