// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/alarm/screens/adhan_alarm_screen.dart';
import 'features/alarm/services/notification_service.dart';
import 'features/prayer_times/presentation/screens/home_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isAdhanScreenShowing = false;
DateTime? _lastAdhanScreenOpenedAt;

void openAdhanScreen(String prayerKey) {
  final now = DateTime.now();
  // Cegah pembukaan bertumpuk ganda (debounce 4 detik & guard active)
  if (_isAdhanScreenShowing) return;
  if (_lastAdhanScreenOpenedAt != null &&
      now.difference(_lastAdhanScreenOpenedAt!) < const Duration(seconds: 4)) {
    return;
  }

  // Batalkan / heningkan suara notifikasi bawaan agar suara adzan terpusat di audio player
  // sehingga volume bisa dibesarkan dan dikecilkan secara penuh oleh tombol HP!
  NotificationService().cancelAllAdhanNotifications();

  _isAdhanScreenShowing = true;
  _lastAdhanScreenOpenedAt = now;

  rootNavigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => AdhanAlarmScreen(
        prayerKey: prayerKey,
        onDismissed: () {
          _isAdhanScreenShowing = false;
        },
      ),
    ),
  ).then((_) {
    _isAdhanScreenShowing = false;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Bahasa Indonesia untuk intl (format tanggal)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi service notifikasi dengan handler klik notifikasi
  await NotificationService().initialize(
    onAdhanAction: (prayerKey) {
      openAdhanScreen(prayerKey);
    },
  );

  // Pasang MethodChannel listener untuk tanggapan dari Android Native (onNewIntent / wakeScreen / volume)
  const platform = MethodChannel('com.sholatblok/alarm_helper');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onAdhanTriggered') {
      final payload = call.arguments as String?;
      if (payload != null && payload.startsWith('adhan:')) {
        final prayerKey = payload.split(':')[1];
        openAdhanScreen(prayerKey);
      }
    }
  });

  runApp(
    const ProviderScope(
      child: SholatBlokApp(),
    ),
  );
}

class SholatBlokApp extends StatefulWidget {
  const SholatBlokApp({super.key});

  @override
  State<SholatBlokApp> createState() => _SholatBlokAppState();
}

class _SholatBlokAppState extends State<SholatBlokApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        const platform = MethodChannel('com.sholatblok/alarm_helper');
        final initialPayload = await platform.invokeMethod<String>('getInitialAdhanPayload');
        if (initialPayload != null && initialPayload.startsWith('adhan:')) {
          final prayerKey = initialPayload.split(':')[1];
          openAdhanScreen(prayerKey);
          return;
        }
      } catch (_) {}

      final payload = await NotificationService().checkLaunchPayload();
      if (payload != null && payload.startsWith('adhan:')) {
        final prayerKey = payload.split(':')[1];
        openAdhanScreen(prayerKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SholatBlok',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
