// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // Prayer Names (ID)
  static const Map<String, String> prayerNameId = {
    'fajr': 'Subuh',
    'sunrise': 'Terbit',
    'dhuhr': 'Dzuhur',
    'asr': 'Ashar',
    'maghrib': 'Maghrib',
    'isha': 'Isya',
  };

  // Default Audio Assets (dalam folder assets/audio/)
  static const String defaultAzanAsset = 'assets/audio/azan_default.mp3';
  static const String shortBeepAsset = 'assets/audio/beep_short.mp3';

  // SharedPreferences Keys
  static const String keyLatitude = 'cached_latitude';
  static const String keyLongitude = 'cached_longitude';
  static const String keyCityName = 'cached_city_name';
  static const String keyAudioPrefsPrefix = 'audio_pref_'; // e.g. audio_pref_fajr
  static const String keyAdhanDuration = 'adhan_duration_seconds'; // 0 = Full, 30, 60, 120

  // Durasi Pilihan Adzan (detik)
  static const int durationFull = 0;
  static const int duration30Sec = 30;
  static const int duration1Min = 60;
  static const int duration2Min = 120;

  // Audio mode constants
  static const String audioModeDefault = 'default';
  static const String audioModeCustom = 'custom';
  static const String audioModeSilent = 'silent';
  static const String audioModeVibrate = 'vibrate';

  // Notification IDs (satu per waktu sholat)
  static const int notifIdFajr = 1;
  static const int notifIdSunrise = 2;
  static const int notifIdDhuhr = 3;
  static const int notifIdAsr = 4;
  static const int notifIdMaghrib = 5;
  static const int notifIdIsha = 6;

  // Snooze duration
  static const int snoozeDurationMinutes = 10;
}

