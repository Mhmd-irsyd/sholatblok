package com.sholatblok.sholatblok

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerKey = intent.getStringExtra("adhan_prayer_key") ?: "dhuhr"

        // 1. Nyalakan CPU & Layar secara fisik dengan WakeLock selama 10 detik
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "sholatblok:alarm_popup_wake"
            )
            wakeLock?.acquire(10000)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Siapkan Intent untuk membuka MainActivity langsung di atas layar kunci atau saat layar menyala
        // TIDAK MENAMPILKAN BANNER NOTIFIKASI LAGI (MURNI POP-UP SESUAI INSTRUKSI PENGGUNA)
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.sholatblok.ALARM_TRIGGER"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("payload", "adhan:$prayerKey")
            putExtra("adhan_prayer_key", prayerKey)
            putExtra("is_auto_popup", true)
        }

        // Buka Activity langsung ke depan
        try {
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
