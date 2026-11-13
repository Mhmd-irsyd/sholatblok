// lib/features/audio/providers/audio_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/audio_repository.dart';
import '../domain/audio_preference.dart';
import '../../prayer_times/providers/prayer_schedule_provider.dart';

final audioRepositoryProvider = FutureProvider<AudioRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AudioRepository(prefs);
});

// ──────────────────────────────────────────
// State untuk Durasi Suara Adzan
// ──────────────────────────────────────────

class AdhanDurationNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final repo = await ref.read(audioRepositoryProvider.future);
    return repo.getAdhanDuration();
  }

  Future<void> setDuration(int seconds) async {
    final repo = await ref.read(audioRepositoryProvider.future);
    await repo.setAdhanDuration(seconds);
    state = AsyncData(seconds);
  }
}

final adhanDurationProvider =
    AsyncNotifierProvider<AdhanDurationNotifier, int>(
  AdhanDurationNotifier.new,
);

// ──────────────────────────────────────────
// State untuk semua preferensi audio
// ──────────────────────────────────────────

class AudioPreferencesNotifier
    extends AsyncNotifier<Map<String, AudioPreference>> {
  @override
  Future<Map<String, AudioPreference>> build() async {
    final repo = await ref.read(audioRepositoryProvider.future);
    return repo.getAllAudioPreferences();
  }

  Future<void> updatePreference(
    String prayerKey,
    AudioPreference preference,
  ) async {
    final repo = await ref.read(audioRepositoryProvider.future);
    await repo.saveAudioPreference(prayerKey, preference);

    // Update state lokal
    final current = state.valueOrNull ?? {};
    state = AsyncData({...current, prayerKey: preference});
  }

  Future<({String filePath, String fileName})?> pickCustomFile() async {
    final repo = await ref.read(audioRepositoryProvider.future);
    return await repo.pickAudioFile();
  }

  Future<void> playPreview(String prayerKey) async {
    final repo = await ref.read(audioRepositoryProvider.future);
    final pref = state.valueOrNull?[prayerKey] ?? AudioPreference.defaultMode();
    await repo.playAudio(pref);
  }

  Future<void> stopPreview() async {
    final repo = await ref.read(audioRepositoryProvider.future);
    await repo.stopAudio();
  }

  Future<void> playAdhan(String prayerKey, {int? maxDuration}) async {
    final repo = await ref.read(audioRepositoryProvider.future);
    final pref = state.valueOrNull?[prayerKey] ?? AudioPreference.defaultMode();
    await repo.playAudio(pref, maxDurationSeconds: maxDuration);
  }

  Future<void> stopAdhan() async {
    final repo = await ref.read(audioRepositoryProvider.future);
    await repo.stopAudio();
  }

  Future<void> setVolume(double volume) async {
    final repo = await ref.read(audioRepositoryProvider.future);
    await repo.setVolume(volume);
  }
}

final audioPreferencesProvider =
    AsyncNotifierProvider<AudioPreferencesNotifier, Map<String, AudioPreference>>(
  AudioPreferencesNotifier.new,
);
