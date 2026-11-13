package com.sholatblok.sholatblok

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sholatblok/alarm_helper"
    private var methodChannel: MethodChannel? = null
    private var pendingAdhanPayload: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Hubungkan tombol volume fisik HP langsung ke volume Media/Video (STREAM_MUSIC)
        volumeControlStream = AudioManager.STREAM_MUSIC
        wakeAndShowOverLockscreen()
        handleAdhanIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        volumeControlStream = AudioManager.STREAM_MUSIC
        wakeAndShowOverLockscreen()
        handleAdhanIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        volumeControlStream = AudioManager.STREAM_MUSIC
        wakeAndShowOverLockscreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAdhanPayload" -> {
                    result.success(pendingAdhanPayload)
                    pendingAdhanPayload = null
                }
                "wakeScreen" -> {
                    wakeAndShowOverLockscreen()
                    result.success(true)
                }
                "scheduleNativeAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val prayerKey = call.argument<String>("prayerKey") ?: "dhuhr"
                    val prayerName = call.argument<String>("prayerName") ?: "Waktu Sholat"

                    scheduleNativeAlarm(id, triggerAtMillis, prayerKey, prayerName)
                    result.success(true)
                }
                "cancelNativeAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelNativeAlarm(id)
                    result.success(true)
                }
                "openXiaomiPermissions" -> {
                    openXiaomiPermissions()
                    result.success(true)
                }
                "openFullScreenIntentSettings" -> {
                    openFullScreenIntentSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Jika ada payload alarm yang menunggu saat cold-start, kirimkan setelah UI Flutter siap
        if (pendingAdhanPayload != null) {
            val payloadToSend = pendingAdhanPayload
            window.decorView.postDelayed({
                methodChannel?.invokeMethod("onAdhanTriggered", payloadToSend)
                pendingAdhanPayload = null
            }, 600)
        }
    }

    private fun scheduleNativeAlarm(id: Int, triggerAtMillis: Long, prayerKey: String, prayerName: String) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // 1. PendingIntent untuk memicu Activity langsung (Pop-up Layar Alarm Sholat)
            val showIntent = Intent(this, MainActivity::class.java).apply {
                action = "com.sholatblok.ALARM_TRIGGER"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("payload", "adhan:$prayerKey")
                putExtra("adhan_prayer_key", prayerKey)
                putExtra("is_auto_popup", true)
            }

            val activityPendingIntent = PendingIntent.getActivity(
                this,
                id,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Gunakan setAlarmClock langsung dengan Activity PendingIntent!
            // Sistem Android akan otomatis membangunkan layar & meluncurkan MainActivity ke depan saat waktu tiba
            val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, activityPendingIntent)
            alarmManager.setAlarmClock(alarmClockInfo, activityPendingIntent)

            // 2. Cadangan tambahan: Jadwalkan juga AdhanAlarmReceiver untuk mengamankan WakeLock fisik CPU & Layar
            val receiverIntent = Intent(this, AdhanAlarmReceiver::class.java).apply {
                putExtra("adhan_prayer_key", prayerKey)
                putExtra("prayer_name", prayerName)
            }
            val receiverPendingIntent = PendingIntent.getBroadcast(
                this,
                id + 500,
                receiverIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                receiverPendingIntent
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun cancelNativeAlarm(id: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // Batalkan Activity PendingIntent
            val showIntent = Intent(this, MainActivity::class.java)
            val activityPendingIntent = PendingIntent.getActivity(
                this,
                id,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(activityPendingIntent)

            // Batalkan Broadcast PendingIntent
            val receiverIntent = Intent(this, AdhanAlarmReceiver::class.java)
            val receiverPendingIntent = PendingIntent.getBroadcast(
                this,
                id + 500,
                receiverIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(receiverPendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun handleAdhanIntent(intent: Intent?) {
        if (intent == null) return
        val rawPayload = intent.getStringExtra("payload")
            ?: intent.getStringExtra("notification_payload")
            ?: intent.getStringExtra("adhan_prayer_key")
            ?: intent.dataString

        val payload = if (rawPayload != null && !rawPayload.startsWith("adhan:") && !rawPayload.contains(":")) {
            "adhan:$rawPayload"
        } else {
            rawPayload
        }

        if (payload != null && payload.startsWith("adhan:")) {
            intent.removeExtra("payload")
            intent.removeExtra("notification_payload")
            intent.removeExtra("adhan_prayer_key")
            pendingAdhanPayload = payload
            methodChannel?.invokeMethod("onAdhanTriggered", payload)
        }
    }

    private fun wakeAndShowOverLockscreen() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                keyguardManager?.requestDismissKeyguard(this, null)
            }

            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )

            // Nyalakan layar secara fisik menggunakan WakeLock saat alarm tiba
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "sholatblok:adhan_alarm_wake"
            )
            wakeLock?.acquire(10000) // 10 detik
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun openXiaomiPermissions() {
        try {
            val intent = Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")
                putExtra("extra_pkgname", packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e1: Exception) {
            try {
                val intent = Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                    putExtra("extra_pkgname", packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (e2: Exception) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            }
        }
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                    data = Uri.fromParts("package", packageName, null)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (e: Exception) {
                openXiaomiPermissions()
            }
        } else {
            openXiaomiPermissions()
        }
    }
}
