// lib/features/audio/domain/audio_preference.dart

/// Model preferensi audio untuk satu waktu sholat
class AudioPreference {
  /// 'default' | 'custom' | 'silent' | 'vibrate'
  final String mode;

  /// Path file MP3 kustom (hanya jika mode == 'custom')
  final String? customFilePath;

  /// Nama tampilan file kustom
  final String? customFileName;

  const AudioPreference({
    required this.mode,
    this.customFilePath,
    this.customFileName,
  });

  factory AudioPreference.defaultMode() =>
      const AudioPreference(mode: 'default');

  factory AudioPreference.silent() =>
      const AudioPreference(mode: 'silent');

  factory AudioPreference.vibrate() =>
      const AudioPreference(mode: 'vibrate');

  factory AudioPreference.custom({
    required String filePath,
    required String fileName,
  }) =>
      AudioPreference(
        mode: 'custom',
        customFilePath: filePath,
        customFileName: fileName,
      );

  /// Serialisasi ke Map untuk SharedPreferences
  Map<String, String> toMap() => {
    'mode': mode,
    if (customFilePath case final p?) 'custom_path': p,
    if (customFileName case final n?) 'custom_name': n,
  };

  /// Deserialisasi dari Map
  factory AudioPreference.fromMap(Map<String, String> map) {
    return AudioPreference(
      mode: map['mode'] ?? 'default',
      customFilePath: map['custom_path'],
      customFileName: map['custom_name'],
    );
  }

  bool get isDefault => mode == 'default';
  bool get isCustom => mode == 'custom';
  bool get isSilent => mode == 'silent';
  bool get isVibrate => mode == 'vibrate';
  bool get hasAudio => mode != 'silent';
}
