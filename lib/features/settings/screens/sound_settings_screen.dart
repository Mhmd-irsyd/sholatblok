import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/prayer_time_utils.dart';
import '../../alarm/screens/adhan_alarm_screen.dart';
import '../../alarm/services/notification_service.dart';
import '../../prayer_times/providers/prayer_schedule_provider.dart';
import '../../audio/domain/audio_preference.dart';
import '../../audio/providers/audio_provider.dart';

class SoundSettingsScreen extends ConsumerStatefulWidget {
  final String? initialPrayerKey;

  const SoundSettingsScreen({super.key, this.initialPrayerKey});

  @override
  ConsumerState<SoundSettingsScreen> createState() =>
      _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends ConsumerState<SoundSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() {
    super.initState();
    final initialIndex =
        prayers.indexOf(widget.initialPrayerKey ?? 'fajr').clamp(0, prayers.length - 1);
    _tabController = TabController(
      length: prayers.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    ref.read(audioPreferencesProvider.notifier).stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPrefsAsync = ref.watch(audioPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Suara Adzan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.lightRose,
          labelColor: AppTheme.lightRose,
          unselectedLabelColor: Colors.white38,
          tabs: prayers.map((key) {
            return Tab(
              text: AppConstants.prayerNameId[key] ?? key,
              icon: Icon(PrayerTimeUtils.getPrayerIcon(key), size: 18),
            );
          }).toList(),
        ),
      ),
      body: audioPrefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prefs) => TabBarView(
          controller: _tabController,
          children: prayers.map((prayerKey) {
            final pref = prefs[prayerKey] ?? AudioPreference.defaultMode();
            return _SoundOptionPanel(
              prayerKey: prayerKey,
              preference: pref,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SoundOptionPanel extends ConsumerWidget {
  final String prayerKey;
  final AudioPreference preference;

  const _SoundOptionPanel({
    required this.prayerKey,
    required this.preference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationAsync = ref.watch(adhanDurationProvider);
    final currentDuration = durationAsync.valueOrNull ?? AppConstants.durationFull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Pilihan Mode Audio ──
        _SectionTitle('Pilih Mode Suara (${AppConstants.prayerNameId[prayerKey] ?? prayerKey})'),
        const SizedBox(height: 8),

        _ModeOption(
          icon: Icons.volume_up_rounded,
          title: 'Adzan Bawaan',
          subtitle: 'Gunakan suara adzan default aplikasi',
          selected: preference.isDefault,
          onTap: () => _updateMode(ref, AudioPreference.defaultMode()),
        ),
        _ModeOption(
          icon: Icons.audiotrack_rounded,
          title: 'File MP3 Kustom',
          subtitle: preference.isCustom && preference.customFileName != null
              ? '📂 ${preference.customFileName}'
              : 'Pilih file audio dari memori HP Anda',
          selected: preference.isCustom,
          onTap: () => _pickCustomFile(context, ref),
          trailing: preference.isCustom
              ? TextButton.icon(
                  onPressed: () => _pickCustomFile(context, ref),
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text('Ganti'),
                )
              : null,
        ),
        _ModeOption(
          icon: Icons.vibration_rounded,
          title: 'Hanya Getar',
          subtitle: 'Tanpa suara, hanya getaran',
          selected: preference.isVibrate,
          onTap: () => _updateMode(ref, AudioPreference.vibrate()),
        ),
        _ModeOption(
          icon: Icons.volume_off_rounded,
          title: 'Hening (Silent)',
          subtitle: 'Tanpa suara dan getaran',
          selected: preference.isSilent,
          onTap: () => _updateMode(ref, AudioPreference.silent()),
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),

        // ── Pengaturan Durasi Adzan (Auto-Stop) ──
        _SectionTitle('Batas Durasi Adzan (Auto-Stop)'),
        const SizedBox(height: 6),
        const Text(
          'Tentukan berapa lama adzan akan berbunyi sebelum otomatis berhenti:',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _durationChip(ref, '30 Detik', AppConstants.duration30Sec, currentDuration),
            _durationChip(ref, '1 Menit', AppConstants.duration1Min, currentDuration),
            _durationChip(ref, '2 Menit', AppConstants.duration2Min, currentDuration),
            _durationChip(ref, 'Sampai Selesai (Full)', AppConstants.durationFull, currentDuration),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),

        // ── Uji Coba Layar Alarm & Tombol Stop ──
        _SectionTitle('Layar Alarm & Tombol Stop Cepat'),
        const SizedBox(height: 6),
        const Text(
          'Simulasikan tampilan layar saat adzan berbunyi lengkap dengan tombol stop cepat:',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(audioPreferencesProvider.notifier).stopPreview();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdhanAlarmScreen(
                  prayerKey: prayerKey,
                  prayerTimeStr: 'Sekarang',
                ),
              ),
            );
          },
          icon: const Icon(Icons.alarm_rounded, color: Colors.white),
          label: const Text(
            'Uji Coba Layar Adzan & Tombol Stop',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRose,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            ref.read(audioPreferencesProvider.notifier).stopPreview();
            await NotificationService().scheduleTestAlarm(secondsFromNow: 5, prayerKey: prayerKey);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.timer_rounded, color: AppTheme.lightRose),
                    SizedBox(width: 8),
                    Text('Alarm 5 Detik Siap!', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                content: const Text(
                  'Alarm adzan akan berdering dalam 5 detik.\n\nSilakan KUNCI layar HP Anda sekarang untuk menguji apakah suara adzan berbunyi dan alarm menyala saat layar mati!',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK, Siap Kunci HP', style: TextStyle(color: AppTheme.lightRose, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.screen_lock_portrait_rounded, color: AppTheme.lightRose),
          label: const Text(
            'Uji Alarm di Layar Kunci (5 Detik Lagi)',
            style: TextStyle(color: AppTheme.lightRose, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.lightRose),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryRose.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.lightRose, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pengguna Xiaomi / Poco / HyperOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Agar layar alarm langsung menyala otomatis saat layar terkunci (bukan cuma banner notifikasi): pastikan izin "Tampilkan di Layar Kunci" diaktifkan.',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      const platform = MethodChannel('com.sholatblok/alarm_helper');
                      await platform.invokeMethod('openXiaomiPermissions');
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                  label: const Text('Buka Pengaturan Izin Layar Kunci'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.lightRose,
                    backgroundColor: AppTheme.primaryRose.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),

        // ── Preview Audio Biasa ──
        if (preference.hasAudio && !preference.isVibrate) ...[
          _SectionTitle('Preview Suara'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memutar audio... Pastikan volume media HP aktif.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    ref.read(audioPreferencesProvider.notifier).playPreview(prayerKey);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Putar Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightRose,
                    side: const BorderSide(color: AppTheme.lightRose),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(audioPreferencesProvider.notifier).stopPreview(),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white38,
                  side: const BorderSide(color: Colors.white12),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _durationChip(WidgetRef ref, String label, int value, int selectedValue) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryRose,
      backgroundColor: AppTheme.cardBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white60,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) {
        ref.read(adhanDurationProvider.notifier).setDuration(value);
      },
    );
  }

  void _updateMode(WidgetRef ref, AudioPreference newPref) {
    ref.read(audioPreferencesProvider.notifier).updatePreference(prayerKey, newPref);
    final schedule = ref.read(prayerScheduleProvider).valueOrNull;
    if (schedule != null) {
      NotificationService().scheduleExactAdhanAlarms(schedule);
    }
  }

  Future<void> _pickCustomFile(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(audioPreferencesProvider.notifier).pickCustomFile();
    if (result != null) {
      _updateMode(
        ref,
        AudioPreference.custom(
          filePath: result.filePath,
          fileName: result.fileName,
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryRose.withValues(alpha: 0.25)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.lightRose : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.lightRose : Colors.white38,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.lightRose,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
