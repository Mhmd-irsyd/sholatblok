// lib/features/prayer_times/presentation/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../alarm/screens/adhan_alarm_screen.dart';
import '../../../alarm/services/notification_service.dart';
import '../../providers/prayer_schedule_provider.dart';
import '../widgets/prayer_card.dart';
import '../widgets/countdown_banner.dart';
import '../../../audio/providers/audio_provider.dart';
import '../../../audio/domain/audio_preference.dart';
import '../../../settings/screens/sound_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _prayerCheckTimer;
  final Set<String> _triggeredPrayersToday = {};

  @override
  void initState() {
    super.initState();
    _startPrayerCheckTimer();
  }

  void _startPrayerCheckTimer() {
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkPrayerArrival();
    });
  }

  void _checkPrayerArrival() {
    final schedule = ref.read(prayerScheduleProvider).valueOrNull;
    if (schedule == null || !mounted) return;

    final now = DateTime.now();

    // Perbarui hitung mundur notifikasi di lockscreen setiap menit
    if (now.second == 0) {
      NotificationService().updateOngoingPrayerNotification(schedule);
    }

    for (final entry in schedule.prayerList) {
      final key = entry.key;
      final time = entry.value;

      if (time == null || key == 'sunrise') continue;

      // Hitung selisih waktu saat ini dengan waktu sholat
      final diff = now.difference(time);

      // Jika waktu sholat baru saja tiba (antara 0 detik s/d 45 detik yang lalu)
      if (diff >= Duration.zero && diff <= const Duration(seconds: 45)) {
        final triggerId = '${now.year}-${now.month}-${now.day}_$key';

        if (!_triggeredPrayersToday.contains(triggerId)) {
          _triggeredPrayersToday.add(triggerId);

          debugPrint('[HomeScreen] WAKTU ADZAN TIBA! Membuka pop-up alarm untuk $key');

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdhanAlarmScreen(
                prayerKey: key,
                prayerTimeStr: PrayerTimeUtils.formatTime(time),
              ),
            ),
          );
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _prayerCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final audioPrefsAsync = ref.watch(audioPreferencesProvider);
    final isGpsDisabled = ref.watch(isGpsDisabledProvider);

    return Scaffold(
      body: SafeArea(
        child: scheduleAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.lightRose),
                SizedBox(height: 16),
                Text(
                  'Memuat jadwal sholat...',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          error: (error, _) {
            // Jika ada kendala GPS, otomatis pulihkan dengan lokasi tersimpan
            Future.microtask(() =>
                ref.read(prayerScheduleProvider.notifier).refreshFromGps(silent: true));
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.lightRose),
            );
          },
          data: (schedule) {
            if (schedule == null) {
              return const Center(child: Text('Tidak ada data jadwal.'));
            }

            final now = DateTime.now();
            final hijri = HijriCalendar.now();
            final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
            final hijriStr =
                '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';
            final nextPrayer = schedule.nextPrayer;
            final audioPrefs = audioPrefsAsync.valueOrNull ?? {};

            return RefreshIndicator(
              color: AppTheme.lightRose,
              onRefresh: () =>
                  ref.read(prayerScheduleProvider.notifier).refreshFromGps(),
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isGpsDisabled
                                          ? Icons.location_off_rounded
                                          : Icons.location_on_rounded,
                                      color: isGpsDisabled
                                          ? AppTheme.roseGold
                                          : AppTheme.lightRose,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      schedule.cityName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  hijriStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.roseGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Settings
                          IconButton(
                            icon: const Icon(Icons.settings_rounded,
                                color: Colors.white54),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SoundSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Alert Bar Jika Lokasi / GPS Mati (Tidak Merusak Tampilan) ──
                  if (isGpsDisabled)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.lightRose.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              color: AppTheme.roseGold,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GPS Tidak Aktif',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Menggunakan lokasi terakhir (${schedule.cityName}). Aktifkan GPS untuk mendeteksi posisi baru Anda.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRose,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Aktifkan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Countdown Banner ──
                  SliverToBoxAdapter(
                    child: CountdownBanner(
                      nextPrayerKey: nextPrayer?.key,
                      nextPrayerTime: nextPrayer?.value,
                    ),
                  ),

                  // ── Header Daftar Sholat ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(
                        'JADWAL SHOLAT HARI INI',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),

                  // ── Daftar Kartu Waktu Sholat ──
                  SliverList(
                    delegate: SliverChildListDelegate(
                      schedule.prayerList.map((entry) {
                        final key = entry.key;
                        final time = entry.value;
                        final isNext = nextPrayer?.key == key;
                        final audioPref = audioPrefs[key] ??
                            AudioPreference.defaultMode();

                        return PrayerCard(
                          prayerKey: key,
                          prayerTime: time,
                          isNext: isNext,
                          audioPreference: audioPref,
                          onAudioTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SoundSettingsScreen(
                                  initialPrayerKey: key,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
