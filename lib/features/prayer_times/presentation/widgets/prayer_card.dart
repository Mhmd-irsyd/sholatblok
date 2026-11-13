// lib/features/prayer_times/presentation/widgets/prayer_card.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../audio/domain/audio_preference.dart';

class PrayerCard extends StatelessWidget {
  final String prayerKey;
  final DateTime? prayerTime;
  final bool isNext;
  final AudioPreference audioPreference;
  final VoidCallback onAudioTap;

  const PrayerCard({
    super.key,
    required this.prayerKey,
    required this.prayerTime,
    required this.isNext,
    required this.audioPreference,
    required this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    final prayerName = AppConstants.prayerNameId[prayerKey] ?? prayerKey;
    final timeStr = PrayerTimeUtils.formatTime(prayerTime);
    final icon = PrayerTimeUtils.getPrayerIcon(prayerKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isNext
            ? AppTheme.primaryRose.withValues(alpha: 0.25)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isNext
            ? Border.all(color: AppTheme.lightRose, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Ikon Waktu Sholat
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: PrayerTimeUtils.getPrayerGradient(prayerKey),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Nama & Waktu Sholat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (isNext)
                    const Text(
                      'Waktu Berikutnya',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.lightRose,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),

            // Waktu
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isNext ? AppTheme.lightRose : Colors.white70,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),

            // Tombol Audio
            GestureDetector(
              onTap: onAudioTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _audioIcon(audioPreference),
                  size: 18,
                  color: audioPreference.isSilent
                      ? Colors.grey
                      : AppTheme.roseGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _audioIcon(AudioPreference pref) {
    if (pref.isSilent) return Icons.volume_off_rounded;
    if (pref.isVibrate) return Icons.vibration_rounded;
    if (pref.isCustom) return Icons.audiotrack_rounded;
    return Icons.volume_up_rounded;
  }
}

