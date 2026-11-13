import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../audio/providers/audio_provider.dart';
import '../services/notification_service.dart';

class AdhanAlarmScreen extends ConsumerStatefulWidget {
  final String prayerKey;
  final String? prayerTimeStr;
  final VoidCallback? onDismissed;

  const AdhanAlarmScreen({
    super.key,
    required this.prayerKey,
    this.prayerTimeStr,
    this.onDismissed,
  });

  @override
  ConsumerState<AdhanAlarmScreen> createState() => _AdhanAlarmScreenState();
}

class _AdhanAlarmScreenState extends ConsumerState<AdhanAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Pastikan notifikasi suara bawaan sistem dibersihkan agar suara terpusat di audio player media
    NotificationService().cancelAllAdhanNotifications();

    // Mulai adzan saat layar ini terbuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAdhanPlayback();
    });
  }

  void _startAdhanPlayback() async {
    final duration = ref.read(adhanDurationProvider).valueOrNull ?? AppConstants.durationFull;
    ref.read(audioPreferencesProvider.notifier).playAdhan(widget.prayerKey);

    if (duration > 0) {
      setState(() {
        _remainingSeconds = duration;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 1) {
          timer.cancel();
          widget.onDismissed?.call();
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    }
  }

  void _stopAdhanAndClose() async {
    _countdownTimer?.cancel();
    NotificationService().cancelAllAdhanNotifications();
    await ref.read(audioPreferencesProvider.notifier).stopAdhan();
    widget.onDismissed?.call();
    if (mounted) {
      // 1 kali pencet langsung kembali ke layar utama, menutup semua duplikat bila ada
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    ref.read(audioPreferencesProvider.notifier).stopAdhan();
    widget.onDismissed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerName = AppConstants.prayerNameId[widget.prayerKey] ?? widget.prayerKey;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Header Status ──
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightRose.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mosque_rounded, color: AppTheme.lightRose, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'ADZAN SEDANG BERKUMANDANG',
                          style: TextStyle(
                            color: AppTheme.lightRose,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waktunya Sholat',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prayerName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  if (widget.prayerTimeStr != null)
                    Text(
                      'Pukul ${widget.prayerTimeStr}',
                      style: const TextStyle(
                        color: Color(0xFFD4A843),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              // ── Logo Tengah dengan Animasi Pulsa ──
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(12 + _animController.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryRose.withValues(alpha: 0.2 + _animController.value * 0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),

              // ── Bagian Kontrol Bawah ──
              Column(
                children: [
                  // Auto-Stop Counter (Jika diatur durasi tertentu)
                  if (_remainingSeconds > 0) ...[
                    Text(
                      'Auto-stop dalam $_remainingSeconds detik',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tombol Stop Otomatis & Cepat
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _stopAdhanAndClose,
                      icon: const Icon(Icons.stop_circle_rounded, size: 28),
                      label: const Text(
                        'HENTIKAN SUARA SEKARANG',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      _stopAdhanAndClose();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi ditunda 10 menit.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.snooze_rounded, color: Colors.white54, size: 18),
                    label: const Text(
                      'Tunda 10 Menit (Snooze)',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
