// lib/features/prayer_times/presentation/widgets/countdown_banner.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/prayer_time_utils.dart';

class CountdownBanner extends StatefulWidget {
  final String? nextPrayerKey;
  final DateTime? nextPrayerTime;

  const CountdownBanner({
    super.key,
    required this.nextPrayerKey,
    required this.nextPrayerTime,
  });

  @override
  State<CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<CountdownBanner> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTicker();
  }

  void _updateRemaining() {
    if (widget.nextPrayerTime != null) {
      _remaining = widget.nextPrayerTime!.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    } else {
      _remaining = Duration.zero;
    }
  }

  void _startTicker() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(_updateRemaining);
      _startTicker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayerName = AppConstants.prayerNameId[widget.nextPrayerKey] ??
        widget.nextPrayerKey ??
        '---';
    final countdownStr = PrayerTimeUtils.formatCountdown(_remaining);
    final timeStr = PrayerTimeUtils.formatTime(widget.nextPrayerTime);

    final isTomorrow = widget.nextPrayerTime != null && widget.nextPrayerTime!.day != DateTime.now().day;
    final headerTitle = isTomorrow ? 'MENUJU $prayerName (BESOK)' : 'MENUJU $prayerName';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2A49), Color(0xFF4A0E23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC74B6A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countdownStr,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pukul $timeStr',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

