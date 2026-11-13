import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../../../main.dart';
import '../../prayer_times/domain/models/prayer_schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String ongoingChannelId = 'sholatblok_ongoing_v2';
  static const String reminderChannelId = 'sholatblok_reminder_channel';
  static const String adhanChannelId = 'sholatblok_adhan_alarm_v3';
  static const String adhanSilentChannelId = 'sholatblok_adhan_silent_v3';
  static const String adhanVibrateChannelId = 'sholatblok_adhan_vibrate_v3';

  static const int ongoingNotificationId = 999;
  static const int testNotificationId = 777;

  /// Mengubah angka jam (misal 04:03) menjadi karakter tebal Unicode (𝟬𝟰:𝟬𝟯)
  /// agar selalu tercetak BOLD di panel notifikasi, lockscreen, dan status bar Android.
  static String toBoldDigits(String input) {
    const normalDigits = '0123456789';
    const boldDigits = ['𝟬', '𝟭', '𝟮', '𝟯', '𝟰', '𝟱', '𝟲', '𝟳', '𝟴', '𝟵'];
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final index = normalDigits.indexOf(char);
      if (index != -1) {
        buffer.write(boldDigits[index]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  void Function(String prayerKey)? _onAdhanNotificationClicked;

  Future<void> initialize({void Function(String prayerKey)? onAdhanAction}) async {
    _onAdhanNotificationClicked = onAdhanAction;
    tz.initializeTimeZones();

    // Atur timezone lokal perangkat secara tepat (Asia/Jakarta, Asia/Makassar, Asia/Jayapura)
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    String locationName = 'Asia/Jakarta';
    if (offsetHours == 8) {
      locationName = 'Asia/Makassar';
    } else if (offsetHours == 9) {
      locationName = 'Asia/Jayapura';
    }
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('adhan:')) {
          final parts = payload.split(':');
          final prayerKey = parts.length > 1 ? parts[1] : 'dhuhr';
          _onAdhanNotificationClicked?.call(prayerKey);
        }
      },
    );

    // Buat Notification Channels untuk Android
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Channel Ongoing (tampil di lockscreen & notification shade)
      const ongoingChannel = AndroidNotificationChannel(
        ongoingChannelId,
        'Jadwal Sholat Berjalan',
        description: 'Menampilkan jadwal sholat berikutnya di panel notifikasi & layar kunci',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      // 2. Channel Reminder Menjelang Adzan (10 menit sebelum waktu sholat)
      const reminderChannel = AndroidNotificationChannel(
        reminderChannelId,
        'Pengingat Menjelang Waktu Sholat',
        description: 'Notifikasi pengingat 10 menit sebelum adzan tiba',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // 3. Channel Utama Adzan (Suara Adzan Berdering Penuh + Layar Penuh Alarm)
      const adhanChannel = AndroidNotificationChannel(
        adhanChannelId,
        'Alarm Suara Adzan Waktu Sholat',
        description: 'Alarm dan lantunan suara adzan saat waktu sholat tiba',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan_default'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
      );

      // 4. Channel Adzan Hening (Silent)
      const adhanSilentChannel = AndroidNotificationChannel(
        adhanSilentChannelId,
        'Alarm Sholat Hening (Tanpa Suara)',
        description: 'Notifikasi waktu sholat tanpa suara adzan',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      );

      // 5. Channel Adzan Hanya Getar
      const adhanVibrateChannel = AndroidNotificationChannel(
        adhanVibrateChannelId,
        'Alarm Sholat Hanya Getar',
        description: 'Notifikasi waktu sholat dengan getaran tanpa suara',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      );

      await androidPlugin.createNotificationChannel(ongoingChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
      await androidPlugin.createNotificationChannel(adhanChannel);
      await androidPlugin.createNotificationChannel(adhanSilentChannel);
      await androidPlugin.createNotificationChannel(adhanVibrateChannel);

      await androidPlugin.requestNotificationsPermission();
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('[NotificationService] Exact alarm permission request: $e');
      }
      try {
        await androidPlugin.requestFullScreenIntentPermission();
      } catch (e) {
        debugPrint('[NotificationService] Full screen intent permission request: $e');
      }
    }
  }

  void setAdhanActionCallback(void Function(String prayerKey) callback) {
    _onAdhanNotificationClicked = callback;
  }

  Future<String?> checkLaunchPayload() async {
    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      return details.notificationResponse?.payload;
    }
    return null;
  }

  /// 1. Tampilkan notifikasi persis seperti di screenshot pengguna:
  /// Menampilkan sholat berikutnya, jam, dan sisa waktu hitung mundur.
  Future<void> updateOngoingPrayerNotification(PrayerSchedule schedule) async {
    final next = schedule.nextPrayer;
    if (next == null) return;

    final prayerName = AppConstants.prayerNameId[next.key] ?? next.key;
    final isTomorrow = schedule.isNextPrayerTomorrow;
    final titleSuffix = isTomorrow ? ' (Besok)' : '';
    final timeStr = PrayerTimeUtils.formatTime(next.value);
    final boldTime = toBoldDigits(timeStr);
    
    final remaining = next.value!.difference(DateTime.now());
    final countdownStr = PrayerTimeUtils.formatCountdown(remaining);

    final androidDetails = AndroidNotificationDetails(
      ongoingChannelId,
      'Jadwal Sholat Berjalan',
      channelDescription: 'Menampilkan jadwal sholat berikutnya di panel notifikasi & layar kunci',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      visibility: NotificationVisibility.public,
      color: const Color(0xFFC74B6A),
      subText: schedule.cityName,
      styleInformation: BigTextStyleInformation(
        '<b><big><big><big><font color="#FFFFFF">$boldTime</font></big></big></big></b>   <font color="#E87A90"><b>-$countdownStr</b></font><br/>Lokasi: ${schedule.cityName}',
        htmlFormatBigText: true,
        contentTitle: '<b><big>$boldTime</big> • Next $prayerName$titleSuffix</b>',
        htmlFormatContentTitle: true,
        summaryText: 'Jadwal Sholat',
        htmlFormatSummaryText: true,
      ),
    );

    final notifDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      ongoingNotificationId,
      '$boldTime • Next $prayerName$titleSuffix',
      '⏳ Sisa -$countdownStr • ${schedule.cityName}',
      notifDetails,
    );

    debugPrint('[NotificationService] Ongoing notification updated for $prayerName');
  }

  /// 2. Jadwalkan notifikasi menjelang adzan (10 menit sebelum sholat)
  Future<void> scheduleApproachingPrayerReminders(PrayerSchedule schedule) async {
    final now = DateTime.now();

    for (final entry in schedule.prayerList) {
      final key = entry.key;
      final prayerTime = entry.value;

      if (prayerTime == null || key == 'sunrise') continue;

      final reminderTime = prayerTime.subtract(const Duration(minutes: 10));

      if (reminderTime.isAfter(now)) {
        final prayerName = AppConstants.prayerNameId[key] ?? key;
        final timeStr = PrayerTimeUtils.formatTime(prayerTime);
        final boldTime = toBoldDigits(timeStr);
        final notifId = 100 + (AppConstants.prayerNameId.keys.toList().indexOf(key));

        final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

        final androidDetails = AndroidNotificationDetails(
          reminderChannelId,
          'Pengingat Menjelang Waktu Sholat',
          channelDescription: 'Notifikasi pengingat 10 menit sebelum adzan tiba',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFC74B6A),
        );

        await _notificationsPlugin.zonedSchedule(
          notifId,
          'Sebentar Lagi Waktu $prayerName',
          'Pukul $boldTime (10 menit lagi). Mari bersiap mengambil air wudhu.',
          scheduledDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        debugPrint('[NotificationService] Scheduled 10m reminder for $prayerName at $reminderTime');
      }
    }
  }

  /// 3. Jadwalkan Alarm & Suara Adzan TEPAT Waktu Sholat Tiba (Murni Pop-Up Langsung Tanpa Notifikasi)
  Future<void> scheduleExactAdhanAlarms(PrayerSchedule schedule) async {
    final now = DateTime.now();

    for (final entry in schedule.prayerList) {
      final key = entry.key;
      final prayerTime = entry.value;

      if (prayerTime == null || key == 'sunrise') continue;

      if (prayerTime.isAfter(now)) {
        final prayerName = AppConstants.prayerNameId[key] ?? key;
        final notifId = 200 + (AppConstants.prayerNameId.keys.toList().indexOf(key));

        // Pastikan tidak ada banner notifikasi tersisa untuk adzan ini
        await _notificationsPlugin.cancel(notifId);

        // Jadwalkan Native AlarmClock (otomatis membuka layar pop-up alarm sholat baik saat layar menyala maupun terkunci)
        try {
          const platform = MethodChannel('com.sholatblok/alarm_helper');
          await platform.invokeMethod('scheduleNativeAlarm', {
            'id': notifId,
            'triggerAtMillis': prayerTime.millisecondsSinceEpoch,
            'prayerKey': key,
            'prayerName': prayerName,
          });
        } catch (e) {
          debugPrint('[NotificationService] Native alarm schedule error: $e');
        }

        debugPrint('[NotificationService] Scheduled EXACT Native Adhan Pop-up for $prayerName at $prayerTime');
      }
    }
  }

  /// 4. Fitur Pengujian: Jadwalkan Alarm Adzan [secondsFromNow] detik dari sekarang
  /// Murni memicu pop-up layar alarm secara langsung tanpa banner notifikasi!
  Future<void> scheduleTestAlarm({
    int secondsFromNow = 5,
    String prayerKey = 'dhuhr',
  }) async {
    final prayerName = AppConstants.prayerNameId[prayerKey] ?? 'Dzuhur';

    // Bersihkan notifikasi uji coba lama jika ada
    await _notificationsPlugin.cancel(testNotificationId);

    // 1. Jadwalkan lewat sistem AlarmManager Android (menembus layar kunci & saat layar menyala)
    try {
      final triggerAtMillis = DateTime.now().add(Duration(seconds: secondsFromNow)).millisecondsSinceEpoch;
      const platform = MethodChannel('com.sholatblok/alarm_helper');
      await platform.invokeMethod('scheduleNativeAlarm', {
        'id': testNotificationId,
        'triggerAtMillis': triggerAtMillis,
        'prayerKey': prayerKey,
        'prayerName': prayerName,
      });
    } catch (e) {
      debugPrint('[NotificationService] Native test alarm schedule error: $e');
    }

    // 2. Dual-redundancy: Timer internal untuk memastikan berdering tepat di detik ke-5 saat HP sedang menyala atau baru saja dikunci
    Future.delayed(Duration(seconds: secondsFromNow), () async {
      // 1. Bangunkan layar dan aktifkan FLAG_SHOW_WHEN_LOCKED secara native
      try {
        const platform = MethodChannel('com.sholatblok/alarm_helper');
        await platform.invokeMethod('wakeScreen');
      } catch (_) {}

      // 2. Tampilkan AdhanAlarmScreen melalui openAdhanScreen (dengan debounce & singleton lock)
      // Murni pop-up layar penuh langsung tanpa notifikasi banner!
      try {
        openAdhanScreen(prayerKey);
      } catch (_) {}
    });

    debugPrint('[NotificationService] Test Adhan alarm scheduled in $secondsFromNow seconds (Pure Pop-up)');
  }

  Future<void> cancelAllAdhanNotifications() async {
    for (int i = 0; i < 6; i++) {
      await _notificationsPlugin.cancel(200 + i);
      try {
        const platform = MethodChannel('com.sholatblok/alarm_helper');
        await platform.invokeMethod('cancelNativeAlarm', {'id': 200 + i});
      } catch (_) {}
    }
    await _notificationsPlugin.cancel(testNotificationId);
    try {
      const platform = MethodChannel('com.sholatblok/alarm_helper');
      await platform.invokeMethod('cancelNativeAlarm', {'id': testNotificationId});
    } catch (_) {}
  }
}
