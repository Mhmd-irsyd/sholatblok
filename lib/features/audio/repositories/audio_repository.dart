import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/audio_preference.dart';
import '../../../core/constants/app_constants.dart';

class AudioRepository {
  final SharedPreferences _prefs;
  AudioPlayer? _activePlayer;
  Timer? _autoStopTimer;
  double _currentVolume = 1.0;

  AudioRepository(this._prefs);

  double get currentVolume => _currentVolume;

  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    if (_activePlayer != null) {
      await _activePlayer!.setVolume(_currentVolume);
    }
  }

  // ──────────────────────────────────────────
  // Durasi Suara Adzan (Auto-Stop Setting)
  // ──────────────────────────────────────────

  int getAdhanDuration() {
    return _prefs.getInt(AppConstants.keyAdhanDuration) ?? AppConstants.durationFull;
  }

  Future<void> setAdhanDuration(int seconds) async {
    await _prefs.setInt(AppConstants.keyAdhanDuration, seconds);
  }

  // ──────────────────────────────────────────
  // Simpan & Ambil Preferensi Audio Per Sholat
  // ──────────────────────────────────────────

  Future<void> saveAudioPreference(
    String prayerKey,
    AudioPreference preference,
  ) async {
    final map = preference.toMap();
    final fullKey = '${AppConstants.keyAudioPrefsPrefix}$prayerKey';
    for (final entry in map.entries) {
      await _prefs.setString('${fullKey}_${entry.key}', entry.value);
    }
  }

  AudioPreference getAudioPreference(String prayerKey) {
    final fullKey = '${AppConstants.keyAudioPrefsPrefix}$prayerKey';
    final mode = _prefs.getString('${fullKey}_mode');
    if (mode == null) return AudioPreference.defaultMode();

    return AudioPreference.fromMap({
      'mode': mode,
      if (_prefs.getString('${fullKey}_custom_path') != null)
        'custom_path': _prefs.getString('${fullKey}_custom_path')!,
      if (_prefs.getString('${fullKey}_custom_name') != null)
        'custom_name': _prefs.getString('${fullKey}_custom_name')!,
    });
  }

  Map<String, AudioPreference> getAllAudioPreferences() {
    const prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return {
      for (final prayer in prayers) prayer: getAudioPreference(prayer),
    };
  }

  // ──────────────────────────────────────────
  // File Picker & Penyimpanan MP3 Kustom
  // ──────────────────────────────────────────

  Future<({String filePath, String fileName})?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    final savedPath = await _copyToAppStorage(file.path!, file.name);
    return (filePath: savedPath, fileName: file.name);
  }

  Future<String> _copyToAppStorage(String sourcePath, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final customAudioDir = Directory('${appDir.path}/custom_audio');
    if (!await customAudioDir.exists()) {
      await customAudioDir.create(recursive: true);
    }

    final destination = File('${customAudioDir.path}/$fileName');
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  // ──────────────────────────────────────────
  // Pemutar Audio & Auto-Stop
  // ──────────────────────────────────────────

  Future<void> playAudio(
    AudioPreference preference, {
    int? maxDurationSeconds,
  }) async {
    await stopAudio();
    _activePlayer = AudioPlayer();

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      if (preference.isCustom && preference.customFilePath != null) {
        debugPrint('[AudioRepository] Playing custom file: ${preference.customFilePath}');
        await _activePlayer!.setFilePath(preference.customFilePath!);
      } else if (preference.isDefault) {
        debugPrint('[AudioRepository] Playing asset: ${AppConstants.defaultAzanAsset}');
        try {
          await AudioPlayer.clearAssetCache();
        } catch (_) {}
        await _activePlayer!.setAsset(AppConstants.defaultAzanAsset);
      } else {
        debugPrint('[AudioRepository] Mode is silent/vibrate, no sound.');
        return;
      }

      await _activePlayer!.setVolume(1.0);
      await _activePlayer!.play();
      debugPrint('[AudioRepository] Playback started.');

      // Pengaturan Auto-Stop Timer jika user memilih durasi tertentu
      final duration = maxDurationSeconds ?? getAdhanDuration();
      if (duration > 0) {
        debugPrint('[AudioRepository] Auto-stop timer set to $duration seconds.');
        _autoStopTimer = Timer(Duration(seconds: duration), () {
          debugPrint('[AudioRepository] Auto-stopping audio after $duration seconds.');
          stopAudio();
        });
      }
    } catch (e, stack) {
      debugPrint('[AudioRepository] Error playing audio: $e');
      debugPrint('[AudioRepository] StackTrace: $stack');
      await stopAudio();
    }
  }

  Future<void> stopAudio() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    try {
      await _activePlayer?.stop();
      await _activePlayer?.dispose();
    } catch (_) {}
    _activePlayer = null;
    debugPrint('[AudioRepository] Audio stopped.');
  }

  bool get isPlaying => _activePlayer?.playing ?? false;

  void dispose() {
    _autoStopTimer?.cancel();
    _activePlayer?.dispose();
  }
}
