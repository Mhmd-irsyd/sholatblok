// lib/core/utils/prayer_time_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerTimeUtils {
  PrayerTimeUtils._();

  /// Format DateTime ke string jam:menit (HH:mm)
  static String formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  /// Format countdown hh:mm:ss dari Duration
  static String formatCountdown(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Icon tiap waktu sholat
  static IconData getPrayerIcon(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return Icons.nights_stay_rounded; // subuh
      case 'sunrise':
        return Icons.wb_twilight_rounded; // terbit
      case 'dhuhr':
        return Icons.wb_sunny_rounded;    // dzuhur
      case 'asr':
        return Icons.light_mode_rounded;  // ashar
      case 'maghrib':
        return Icons.wb_twilight_rounded; // maghrib
      case 'isha':
        return Icons.dark_mode_rounded;   // isya
      default:
        return Icons.access_time_rounded;
    }
  }

  /// Warna gradient tiap waktu sholat bernuansa Rose Aesthetic
  static List<Color> getPrayerGradient(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return [const Color(0xFF281E3B), const Color(0xFF6B3050)];
      case 'sunrise':
        return [const Color(0xFFD46A6A), const Color(0xFFF3A683)];
      case 'dhuhr':
        return [const Color(0xFFC44569), const Color(0xFFE66767)];
      case 'asr':
        return [const Color(0xFFB33951), const Color(0xFFE07A5F)];
      case 'maghrib':
        return [const Color(0xFF4A154B), const Color(0xFFB83B5E)];
      case 'isha':
        return [const Color(0xFF160D14), const Color(0xFF421E36)];
      default:
        return [const Color(0xFF8E2A49), const Color(0xFFC74B6A)];
    }
  }
}
